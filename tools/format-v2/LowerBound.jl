"""
A rigorous lower bound on the order of a permutation group.

This is the randomized Schreier-Sims construction, used only for what it
can prove. Each level `i` holds a base point `b_i`, a list `S_i` of group
elements fixing `b_1 .. b_(i-1)`, and the orbit `D_i` of `b_i` under `<S_i>`.
Every element ever stored is a product of the generators, and
`S_(i+1)` is contained in `S_i`, so

    |<S_i>| = |D_i| * |Stab_<S_i>(b_i)| >= |D_i| * |<S_(i+1)>|

and the product of the orbit lengths is at most the order of the group.
The random elements only decide how fast the bound grows, never whether it
holds. Paired with an upper bound from invariants, equality proves the order.
"""
module LowerBound

using Random

export lower_bound

const Perm = Vector{Int32}

"`compose(a, b)` applies `b` first, then `a`."
compose(a::Perm, b::Perm)::Perm = a[b]

function inverse(a::Perm)::Perm
    out = similar(a)
    @inbounds for i in eachindex(a)
        out[a[i]] = i
    end
    out
end

isidentity(a::Perm) = all(i -> a[i] == i, eachindex(a))

mutable struct Level
    base::Int32
    gens::Vector{Perm}
    transversal::Dict{Int32,Perm}
end

"Recompute the orbit of a level's base point, with a transversal element per point."
function rebuild!(level::Level, degree::Int)
    id = Int32.(1:degree)
    u = Dict{Int32,Perm}(level.base => id)
    queue = [level.base]
    while !isempty(queue)
        p = popfirst!(queue)
        for s in level.gens
            q = s[p]
            if !haskey(u, q)
                u[q] = compose(s, u[p])
                push!(queue, q)
            end
        end
    end
    level.transversal = u
end

"Sift `g` through the chain; return the residue and the level where it stopped."
function sift(levels::Vector{Level}, g::Perm)
    h = g
    for (i, level) in enumerate(levels)
        p = h[level.base]
        haskey(level.transversal, p) || return (h, i)
        h = compose(inverse(level.transversal[p]), h)
    end
    (h, length(levels) + 1)
end

function add!(levels::Vector{Level}, h::Perm, j::Int, degree::Int)
    if j > length(levels)
        moved = Int32(findfirst(i -> h[i] != i, eachindex(h)))
        push!(levels, Level(moved, Perm[], Dict{Int32,Perm}()))
    end
    for k in 1:j
        push!(levels[k].gens, h)
        rebuild!(levels[k], degree)
    end
end

bound(levels) = prod(BigInt(length(l.transversal)) for l in levels; init=BigInt(1))

"""
Grow a lower bound on `|<gens>|` until it reaches `target` or `patience`
random elements in a row sift to the identity. Returns the bound reached.
"""
function lower_bound(gens::Vector{Perm}, target::BigInt; seed::Int=1, patience::Int=200)
    degree = length(gens[1])
    levels = Level[]
    for g in gens
        isidentity(g) && continue
        h, j = sift(levels, g)
        isidentity(h) || add!(levels, h, j, degree)
    end
    rng = MersenneTwister(seed)
    # Product replacement: a pool of products of the generators.
    pool = [copy(g) for g in gens]
    while length(pool) < 12
        push!(pool, copy(gens[rand(rng, 1:length(gens))]))
    end
    acc = Int32.(1:degree)
    function next!()
        i, j = rand(rng, 1:length(pool)), rand(rng, 1:length(pool))
        while j == i
            j = rand(rng, 1:length(pool))
        end
        pool[i] = compose(pool[i], rand(rng, Bool) ? pool[j] : inverse(pool[j]))
        acc = compose(acc, pool[i])
        acc
    end
    for _ in 1:60
        next!()
    end
    quiet = 0
    while bound(levels) < target && quiet < patience
        h, j = sift(levels, next!())
        if isidentity(h)
            quiet += 1
        else
            add!(levels, h, j, degree)
            quiet = 0
        end
    end
    bound(levels)
end

end
