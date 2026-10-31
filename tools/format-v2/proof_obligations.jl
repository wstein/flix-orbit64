#!/usr/bin/env julia
#
# Machine-checked proof obligations of Orbit64 V2 (FORMAT-V2.md).
#
#     julia proof_obligations.jl [max_n]
#
# Needs only Julia's standard library. Writes a Markdown report to stdout;
# `proof-obligations.md` beside this file is that report, committed. The
# 7x7x7 is the slowest size; pass a smaller `max_n` for a quick run.
#
# For every size n = 2..7 the script proves, for the canonical picture group
# H (the reachable states with the reference home), that
#
#     lower bound  <=  |H|  <=  upper bound
#
# with the two bounds equal. The upper bound comes from invariants: corner
# twists sum to 0 mod 3, midge flips to 0 mod 2 (checked on every
# generator), and every GF(2) relation between permutation parities that the
# generators of the full group G satisfy. The lower bound is a Schreier-Sims
# chain of elements of H (LowerBound.jl). From |H| it derives the color count
# by projection and checks it against V1's `State.stateCount(n)`. Last, it
# allocates the initial registry with the V2 rule and prints the range table.

include("CubeModel.jl")
include("LowerBound.jl")
using .CubeModel
using .LowerBound
using Printf

const ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
const F24 = factorial(big(24))
const MULTISET = F24 ÷ factorial(big(4))^6

# ---- parity relations ------------------------------------------------------

"""
Parity components of the full group G. Every cubie orbit contributes its
permutation parity; the fixed centers contribute their position parity `P`
and the parity `R` of their total rotation.
"""
function components(c::Cube)
    names = String[]
    for (k, g) in orbits(c)
        if k == :fixed
            append!(names, ["P", "R"])
        else
            push!(names, describe(c, k, g))
        end
    end
    names
end

function generator_vector(c::Cube, axis::Int, layer::Int)
    move = cubie_turn(c, axis, layer)
    row = Int[]
    for (k, g) in orbits(c)
        members = Set(g)
        sub = Dict(p => q for (p, q) in move if p in members)
        push!(row, parity(sub))
        k == :fixed && push!(row, mod(fixed_rotation_change(c, axis, layer), 2))
    end
    row
end

"Row-echelon GF(2) basis of the span of `rows`."
function echelon(rows::Vector{Vector{Int}})
    basis = Vector{Int}[]
    for r in rows
        v = copy(r)
        for b in basis
            p = findfirst(==(1), b)
            v[p] == 1 && (v .⊻= b)
        end
        if any(==(1), v)
            push!(basis, v)
            sort!(basis, by=b -> findfirst(==(1), b))
        end
    end
    basis
end

"Every linear form that vanishes on the span of `basis`, as a basis."
function annihilator(basis::Vector{Vector{Int}}, k::Int)
    forms = Vector{Int}[]
    for bits in 0:(1 << k) - 1
        lam = [(bits >> i) & 1 for i in 0:k-1]
        all(v -> isodd(sum(lam .& v)) == false, basis) && push!(forms, lam)
    end
    echelon(forms)
end

"""
Reduced echelon form with pivots on the LAST components, so every pivot is
a function of components that are not pivots.
"""
function reduce_last(forms::Vector{Vector{Int}})
    isempty(forms) && return forms
    rows = echelon([reverse(f) for f in forms])
    for i in eachindex(rows)
        p = findfirst(==(1), rows[i])
        for j in eachindex(rows)
            j != i && rows[j][p] == 1 && (rows[j] .⊻= rows[i])
        end
    end
    [reverse(r) for r in rows if any(==(1), r)]
end

"""
Restrict forms to the coordinates in `keep`, keeping only the relations that
do not involve the dropped ones.
"""
function eliminate(forms::Vector{Vector{Int}}, drop::Vector{Int}, k::Int)
    order = vcat(drop, setdiff(1:k, drop))
    rows = echelon([f[order] for f in forms])
    dropped = length(drop)
    kept = [r[dropped+1:end] for r in rows if all(==(0), r[1:dropped])]
    reduce_last(echelon(kept))
end

"Restriction to states where the dropped components are zero."
restrict(forms, keep) = reduce_last(echelon([f[keep] for f in forms if any(==(1), f[keep])]))

function show_relations(names, rows)
    isempty(rows) && return "none"
    parts = String[]
    for r in rows
        terms = names[findall(==(1), r)]
        rhs = length(terms) == 1 ? "0" : join(("par($t)" for t in terms[1:end-1]), " + ")
        push!(parts, "par($(terms[end])) = $rhs")
    end
    join(parts, "; ")
end

# ---- counts ----------------------------------------------------------------

wings(n) = (n - 2) ÷ 2
centers(n) = ((n - 2) * (n - 2)) ÷ 4

"Canonical state count before parity relations."
function free_count(n::Int, picture::Bool)::BigInt
    t = isodd(n) ? factorial(big(8)) * big(3)^7 * factorial(big(12)) * big(2)^11 :
                   factorial(big(7)) * big(3)^6
    t *= F24^wings(n)
    t *= (picture ? F24 : MULTISET)^centers(n)
    picture && isodd(n) && (t *= big(4)^6)
    t
end

"V1 `State.stateCount(n)`, transcribed from src/Orbit64/State.flix and Orbit.flix."
function v1_state_count(n::Int)::BigInt
    t = factorial(big(8)) * big(3)^7
    isodd(n) && (t *= factorial(big(12)) * big(2)^11)
    t *= F24^wings(n) * MULTISET^centers(n)
    isodd(n) ? t ÷ 2 * 24 : t
end

# ---- registry --------------------------------------------------------------

mutable struct Entry
    id::Int
    name::String
    count::BigInt
    length::Int
    offset::BigInt
end

"""
The V2 allocation rule: entries are placed in registry order, each at the
shortest length whose unallocated tail still holds all its states.
"""
function allocate!(entries::Vector{Entry})
    used = Dict{Int,BigInt}()
    for e in entries
        L = 1
        while get(used, L, big(0)) + e.count > big(64)^L
            L += 1
        end
        e.length = L
        e.offset = get(used, L, big(0))
        used[L] = e.offset + e.count
    end
end

function token(v::BigInt, L::Int)
    chars = Char[]
    for _ in 1:L
        v, d = divrem(v, 64)
        push!(chars, ALPHABET[d+1])
    end
    v == 0 || error("value does not fit")
    String(reverse(chars))
end

bits(x::BigInt) = @sprintf("%.2f", log2(BigFloat(x)))
sci(x::BigInt) = @sprintf("%.3e", BigFloat(x))

# ---- main ------------------------------------------------------------------

function main(maxn::Int)
    println("# Orbit64 V2 proof obligations\n")
    println("Generated by `julia tools/format-v2/proof_obligations.jl`. Do not edit.\n")
    counts = Dict{Tuple{Int,Symbol},BigInt}()
    for n in 2:maxn
        c = Cube(n)
        turns = all_turns(c)
        @assert all(t -> corner_twist_sum(c, t...) == 0, turns) "twist law fails"
        @assert all(t -> midge_flip_sum(c, t...) == 0, turns) "flip law fails"
        names = components(c)
        k = length(names)
        rels = annihilator(echelon([generator_vector(c, t...) for t in turns]), k)
        # Canonical states keep the fixed centers home, so P = 0 there.
        keep = findall(!=("P"), names)
        cnames = names[keep]
        picture_rels = restrict(rels, keep)
        drop = findall(nm -> startswith(nm, "Z") || nm == "R", cnames)
        color_rels = eliminate(picture_rels, drop, length(cnames))
        upper = free_count(n, true) ÷ big(2)^length(picture_rels)
        color = free_count(n, false) ÷ big(2)^length(color_rels)
        gens = [point_turn(c, t...) for t in canonical_turns(c)]
        lower = lower_bound(gens, upper; seed=n, patience=400)
        @assert lower <= upper "lower bound exceeds upper bound: invariant missing"
        @assert lower == upper "bounds differ for n = $n: $lower < $upper"
        @assert 24 * color == v1_state_count(n) "color count disagrees with V1 for n = $n"
        n == 2 && @assert upper == color "a 2x2x2 has no centers"
        counts[(n, :color)] = color
        counts[(n, :picture)] = upper
        println("## $(n)x$(n)x$(n)\n")
        println("- parity components of G: ", join(names, ", "))
        println("- picture relations (canonical): ", show_relations(cnames, picture_rels))
        println("- color relations (canonical): ",
                show_relations(cnames[setdiff(1:length(cnames), drop)], color_rels))
        println("- upper bound (invariants) = lower bound (Schreier-Sims) = |H| = ", upper)
        println("- picture canonical: ", sci(upper), " (", bits(upper), " bits)")
        println("- color canonical: ", sci(color), " (", bits(color), " bits); ",
                "24 x color = V1 stateCount(", n, ")")
        println()
        flush(stdout)
    end

    entries = Entry[]
    for n in 2:maxn, kind in (n == 2 ? (:color,) : (:color, :picture)), variant in (:canonical, :framed)
        count = counts[(n, kind)] * (variant == :framed ? 24 : 1)
        name = "$(n)x$(n)x$(n) $(kind) $(variant)"
        push!(entries, Entry(length(entries), name, count, 0, big(0)))
    end
    allocate!(entries)
    println("## Initial registry\n")
    println("| ID | Type | States | Bits | Length | Offset | Share | Solved token |")
    println("| -: | ---- | -----: | ---: | -----: | -----: | ----: | ------------ |")
    for e in entries
        share = @sprintf("%.2f%%", 100 * BigFloat(e.count) / big(64)^e.length)
        println("| $(e.id) | $(e.name) | $(sci(e.count)) | $(bits(e.count)) | $(e.length) | ",
                "$(sci(e.offset)) | $share | `$(token(e.offset, e.length))` |")
    end
    println("\n## Free space per length\n")
    println("| Length | Allocated | Free bits |")
    println("| -----: | --------: | --------: |")
    for L in sort(unique(e.length for e in entries))
        used = sum(e.count for e in entries if e.length == L)
        @printf("| %d | %.2f%% | %.2f |\n", L, 100 * BigFloat(used) / big(64)^L,
                log2(BigFloat(big(64)^L - used)))
    end
end

main(isempty(ARGS) ? 7 : parse(Int, ARGS[1]))
