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

Permutations are stored as `Int16` image vectors, which caps the degree at
32767 points, and each orbit point keeps only the inverse of its transversal
element: that is all sifting needs, and it halves the memory of a long chain.
"""
module LowerBound

using Random

export lower_bound

const Perm = Vector{Int16}

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
    base::Int16
    gens::Vector{Perm}
    invgens::Vector{Perm}
    # For each orbit point q, the inverse of an element mapping base to q.
    uinv::Dict{Int16,Perm}
end

"""
Extend a level's orbit after `gens` grew: apply every generator to every
orbit point and keep going from the points that are new. Existing transversal
elements stay valid, so a generator that adds nothing costs one pass.
"""
function extend!(level::Level, fresh::Vector{Int})
    queue = Int16[]
    # Points already in the orbit, under the new generators only.
    for gi in fresh, p in collect(keys(level.uinv))
        s, sinv = level.gens[gi], level.invgens[gi]
        q = s[p]
        if !haskey(level.uinv, q)
            level.uinv[q] = compose(level.uinv[p], sinv)
            push!(queue, q)
        end
    end
    # New points, under every generator.
    while !isempty(queue)
        p = popfirst!(queue)
        for gi in eachindex(level.gens)
            q = level.gens[gi][p]
            if !haskey(level.uinv, q)
                level.uinv[q] = compose(level.uinv[p], level.invgens[gi])
                push!(queue, q)
            end
        end
    end
end

"Sift `g` through the chain; return the residue and the level where it stopped."
function sift(levels::Vector{Level}, g::Perm)
    h = g
    for (i, level) in enumerate(levels)
        p = h[level.base]
        u = get(level.uinv, p, nothing)
        u === nothing && return (h, i)
        h = compose(u, h)
    end
    (h, length(levels) + 1)
end

function add!(levels::Vector{Level}, h::Perm, j::Int)
    degree = length(h)
    if j > length(levels)
        moved = Int16(findfirst(i -> h[i] != i, eachindex(h)))
        id = Int16.(1:degree)
        push!(levels, Level(moved, Perm[], Perm[], Dict{Int16,Perm}(moved => id)))
    end
    hinv = inverse(h)
    for k in 1:j
        push!(levels[k].gens, h)
        push!(levels[k].invgens, hinv)
        extend!(levels[k], [length(levels[k].gens)])
    end
end

bound(levels) = prod(BigInt(length(l.uinv)) for l in levels; init=BigInt(1))

"""
Grow a lower bound on `|<gens>|` until it reaches `target` or `patience`
random elements in a row sift to the identity. Returns the bound reached.
"""
function lower_bound(gens::Vector{Vector{Int32}}, target::BigInt; seed::Int=1, patience::Int=200)
    degree = length(gens[1])
    degree <= typemax(Int16) || error("degree $degree exceeds the Int16 storage")
    gens = [Perm(g) for g in gens]
    levels = Level[]
    for g in gens
        isidentity(g) && continue
        h, j = sift(levels, g)
        isidentity(h) || add!(levels, h, j)
    end
    rng = MersenneTwister(seed)
    # Product replacement: a pool of products of the generators.
    pool = [copy(g) for g in gens]
    while length(pool) < 12
        push!(pool, copy(gens[rand(rng, 1:length(gens))]))
    end
    acc = Int16.(1:degree)
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
    current = bound(levels)
    while current < target && quiet < patience
        h, j = sift(levels, next!())
        if isidentity(h)
            quiet += 1
        else
            add!(levels, h, j)
            current = bound(levels)
            quiet = 0
        end
    end
    current
end

end
