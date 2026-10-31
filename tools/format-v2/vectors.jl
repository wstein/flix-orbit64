#!/usr/bin/env julia
#
# Independent reference encoder for the Orbit64 V2 state token format
# (FORMAT-V2.md). It is written from the specification text alone and shares no
# code with the Flix library, so that the vectors it emits can check the library.
#
#     julia tools/format-v2/vectors.jl [output.flix]
#
# Needs only Julia's standard library. Writes `test/TestV2VectorData.flix`
# (or the path given) and one summary line per registry entry to stderr. The
# output is deterministic: a fixed-seed MersenneTwister, no clocks.
#
# What it does:
#   1. Builds the 54-entry registry, computing every state count, length and
#      offset with exact BigInt arithmetic from its own digit layout, and checks
#      them against the table in FORMAT-V2.md.
#   2. Draws valid states directly in coordinates (no cube moves are simulated):
#      random permutations with the required parities, random orientations that
#      obey the laws, random center multisets, fixed-center rotations with R = C.
#   3. Encodes each state with its own mixed-radix Horner implementation, decodes
#      the token with its own decoder, and asserts that the state comes back.
#
# Solved state of a color-model center orbit: FORMAT-V2.md states it normatively
# (colors ascending by slot, in the slot order of FORMAT-V2-SLOTS.md), so the
# all-zero multiset ranks the solved state. That is, slots 0-3 have color 0,
# slots 4-7 color 1, ..., slots 20-23 color 5. Picture-model orbits and all
# permutations are solved at the identity.

using Random
using Printf

const ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
const FACT = [factorial(big(i)) for i in 0:24]
const MULTISET_RADIXES = [binomial(big(24 - 4t), 4) for t in 0:4]

wing_orbits(n) = (n - 2) ÷ 2
center_orbit_count(n) = ((n - 2)^2) ÷ 4

"Center orbits as (r, c): the lowest U facelet of each, ordered by facelet index."
function center_orbits(n::Int)
    m = n - 1
    reps = Set{Tuple{Int,Int}}()
    for r in 1:n-2, c in 1:n-2
        (2r == m && 2c == m) && continue # the fixed center of an odd cube
        orbit = [(r, c), (c, m - r), (m - r, m - c), (m - c, r)]
        push!(reps, minimum(orbit))
    end
    result = sort!(collect(reps))
    length(result) == center_orbit_count(n) || error("center orbit count is wrong for n = $n")
    result
end

# ---- registry ---------------------------------------------------------------

struct Entry
    id::Int
    n::Int
    picture::Bool
    framed::Bool
    name::String
    layout::Vector{Tuple{String,BigInt}} # digit name and radix, most significant first
    count::BigInt
    len::Int
    offset::BigInt
end

"The digits of an entry in the order of the digit layout table, with radixes."
function digit_layout(n::Int, picture::Bool, framed::Bool)
    odd = isodd(n)
    list = Tuple{String,BigInt}[]
    canonical_even = !odd && !framed
    push!(list, ("cp", canonical_even ? FACT[8] : FACT[9]))
    push!(list, ("ct", canonical_even ? big(3)^6 : big(3)^7))
    if odd
        push!(list, ("mp", FACT[13] ÷ 2))
        push!(list, ("mf", big(2)^11))
    end
    for k in 1:wing_orbits(n)
        push!(list, ("w$k", FACT[25]))
    end
    for j in 1:center_orbit_count(n)
        push!(list, ("z$j", picture ? FACT[25] ÷ 2 : FACT[25] ÷ FACT[5]^6))
    end
    picture && odd && push!(list, ("fr", big(2)^11))
    framed && odd && push!(list, ("fm", big(24)))
    list
end

function build_registry()
    specs = Tuple{Int,Bool,Bool}[]
    for n in 2:15, picture in (n == 2 ? (false,) : (false, true)), framed in (false, true)
        push!(specs, (n, picture, framed))
    end
    entries = Entry[]
    used = Dict{Int,BigInt}()
    for (id, (n, picture, framed)) in enumerate(specs)
        layout = digit_layout(n, picture, framed)
        count = prod(r for (_, r) in layout)
        len = 1
        while get(used, len, big(0)) + count > big(64)^len
            len += 1
        end
        offset = get(used, len, big(0))
        used[len] = offset + count
        name = "$(n)x$(n)x$(n) $(picture ? "picture" : "color") $(framed ? "framed" : "canonical")"
        push!(entries, Entry(id - 1, n, picture, framed, name, layout, count, len, offset))
    end
    entries
end

"Compares the computed registry with the table in FORMAT-V2.md."
function check_against_spec(entries::Vector{Entry}, path::String)
    rows = 0
    for line in eachline(path)
        m = match(r"^\| (\d+) \| (.+?) \| ([0-9.e+]+) \| ([0-9.]+) \| (\d+) \| (.+?) \|$", line)
        m === nothing && continue
        e = entries[parse(Int, m[1]) + 1]
        e.name == m[2] || error("entry $(e.id): name $(e.name) vs table $(m[2])")
        @sprintf("%.3e", BigFloat(e.count)) == m[3] || error("entry $(e.id): states differ")
        @sprintf("%.2f", log2(BigFloat(e.count))) == m[4] || error("entry $(e.id): bits differ")
        e.len == parse(Int, m[5]) || error("entry $(e.id): length $(e.len) vs table $(m[5])")
        if m[6] == "0"
            e.offset == 0 || error("entry $(e.id): offset should be 0")
        else
            j = parse(Int, match(r"N_(\d+)", m[6])[1])
            e.offset == entries[j + 1].count || error("entry $(e.id): offset should be N_$j")
        end
        rows += 1
    end
    rows == length(entries) || error("table has $rows rows, registry has $(length(entries))")
end

# ---- tokens -----------------------------------------------------------------

function token_text(v::BigInt, len::Int)
    chars = Char[]
    for _ in 1:len
        v, d = divrem(v, 64)
        push!(chars, ALPHABET[d + 1])
    end
    v == 0 || error("value does not fit in $len characters")
    String(reverse(chars))
end

function token_value(text::String)
    v = big(0)
    for ch in text
        i = findfirst(==(ch), ALPHABET)
        i === nothing && error("not a base64url character: $ch")
        v = v * 64 + (i - 1)
    end
    v
end

# ---- rank primitives --------------------------------------------------------

function lehmer(p::Vector{Int})
    k = length(p)
    [count(j -> p[j] < p[i], i+1:k) for i in 1:k]
end

parity(p::Vector{Int}) = sum(lehmer(p)) % 2

is_permutation(p::Vector{Int}, k::Int) = length(p) == k && sort(p) == collect(0:k-1)

function perm_rank(p::Vector{Int})
    k = length(p)
    c = lehmer(p)
    sum(big(c[i]) * FACT[k - i + 1] for i in 1:k)
end

function perm_rank_reduced(p::Vector{Int})
    k = length(p)
    c = lehmer(p)
    sum(big(c[i]) * FACT[k - i + 1] ÷ 2 for i in 1:k-2)
end

function lehmer_to_perm(c::Vector{Int})
    avail = collect(0:length(c)-1)
    [popat!(avail, ci + 1) for ci in c]
end

function perm_unrank(r::BigInt, k::Int)
    c = zeros(Int, k)
    for i in 1:k
        q, r = divrem(r, FACT[k - i + 1])
        c[i] = Int(q)
    end
    r == 0 || error("rank out of range")
    lehmer_to_perm(c)
end

function perm_unrank_reduced(r::BigInt, k::Int, par::Int)
    c = zeros(Int, k)
    for i in 1:k-2
        q, r = divrem(r, FACT[k - i + 1] ÷ 2)
        c[i] = Int(q)
    end
    r == 0 || error("rank out of range")
    c[k-1] = mod(par - sum(c[1:k-2]), 2)
    lehmer_to_perm(c)
end

"Orientation digits: all but the last entry, first slot is the units digit."
orient_digit(o::Vector{Int}, base::Int) =
    sum(big(o[i]) * big(base)^(i - 1) for i in 1:length(o)-1)

function orient_unrank(d::BigInt, k::Int, base::Int)
    o = zeros(Int, k)
    for i in 1:k-1
        d, x = divrem(d, base)
        o[i] = Int(x)
    end
    d == 0 || error("orientation digit out of range")
    o[k] = mod(-sum(o[1:k-1]), base)
    o
end

function multiset_rank(col::Vector{Int})
    unassigned = collect(1:24)
    acc = big(0)
    for t in 0:4
        pos = [j - 1 for (j, s) in enumerate(unassigned) if col[s] == t]
        length(pos) == 4 || error("color $t does not occur four times")
        sub = sum(binomial(big(pos[i]), i) for i in 1:4)
        acc = acc * binomial(big(length(unassigned)), 4) + sub
        unassigned = [s for s in unassigned if col[s] != t]
    end
    acc
end

function multiset_unrank(r::BigInt)
    digits = Vector{BigInt}(undef, 5)
    for t in 5:-1:1
        r, digits[t] = divrem(r, MULTISET_RADIXES[t])
    end
    r == 0 || error("multiset rank out of range")
    col = fill(5, 24)
    unassigned = collect(1:24)
    for t in 0:4
        d = digits[t + 1]
        pos = zeros(Int, 4)
        for i in 4:-1:1
            s = i - 1
            while binomial(big(s + 1), i) <= d
                s += 1
            end
            pos[i] = s
            d -= binomial(big(s), i)
        end
        d == 0 || error("combination unrank failed")
        for s in pos
            col[unassigned[s + 1]] = t
        end
        unassigned = [s for s in unassigned if col[s] == 5]
    end
    col
end

# ---- states -----------------------------------------------------------------

const State = Dict{String,Vector{Int}}

"State keys of an entry in text order."
function state_keys(e::Entry)
    keys = ["cp", "ct"]
    isodd(e.n) && append!(keys, ["mp", "mf"])
    append!(keys, ["w$k" for k in 1:wing_orbits(e.n)])
    append!(keys, ["z$j" for j in 1:center_orbit_count(e.n)])
    e.picture && isodd(e.n) && push!(keys, "fr")
    e.framed && isodd(e.n) && push!(keys, "fm")
    keys
end

state_text(e::Entry, st::State) =
    join(("$k=" * join(st[k], ",") for k in state_keys(e)), ";")

function parse_state(text::String)
    st = State()
    for part in split(text, ";")
        k, v = split(part, "=")
        st[k] = parse.(Int, split(v, ","))
    end
    st
end

"Slots of the seven corners that are stored in an even canonical state."
const EVEN_SLOTS = [0, 1, 2, 3, 4, 5, 7]
renumber(s) = s - (s > 6 ? 1 : 0)
unnumber(s) = s + (s >= 6 ? 1 : 0)

"Parity of wing orbit `k`, zero when the cube has no such orbit (odd middle depth)."
wing_parity(e::Entry, st::State, k::Int) = k <= wing_orbits(e.n) ? parity(st["w$k"]) : 0

function expected_center_parity(e::Entry, st::State, j::Int, cpar::Int)
    r, c = center_orbits(e.n)[j]
    d = min(c, e.n - 1 - c)
    (cpar + wing_parity(e, st, r) + wing_parity(e, st, d)) % 2
end

function solved_state(e::Entry)
    st = State()
    st["cp"] = collect(0:7)
    st["ct"] = zeros(Int, 8)
    if isodd(e.n)
        st["mp"] = collect(0:11)
        st["mf"] = zeros(Int, 12)
    end
    for k in 1:wing_orbits(e.n)
        st["w$k"] = collect(0:23)
    end
    for j in 1:center_orbit_count(e.n)
        st["z$j"] = e.picture ? collect(0:23) : [i ÷ 4 for i in 0:23]
    end
    e.picture && isodd(e.n) && (st["fr"] = zeros(Int, 6))
    e.framed && isodd(e.n) && (st["fm"] = [0])
    st
end

function validate(e::Entry, st::State)
    check(ok, why) = ok || error("invalid state for entry $(e.id): $why")
    odd = isodd(e.n)
    check(sort(collect(keys(st))) == sort(state_keys(e)), "wrong set of fields")
    check(is_permutation(st["cp"], 8), "cp is not a permutation")
    check(length(st["ct"]) == 8 && all(t -> 0 <= t <= 2, st["ct"]), "twist range")
    check(sum(st["ct"]) % 3 == 0, "twist law")
    cpar = parity(st["cp"])
    if !odd && !e.framed
        check(st["cp"][7] == 6 && st["ct"][7] == 0, "DBL is not home")
    end
    if odd
        check(is_permutation(st["mp"], 12), "mp is not a permutation")
        check(length(st["mf"]) == 12 && all(f -> 0 <= f <= 1, st["mf"]), "flip range")
        check(sum(st["mf"]) % 2 == 0, "flip law")
        check(parity(st["mp"]) == cpar, "M = C")
    end
    for k in 1:wing_orbits(e.n)
        check(is_permutation(st["w$k"], 24), "w$k is not a permutation")
    end
    for j in 1:center_orbit_count(e.n)
        z = st["z$j"]
        if e.picture
            check(is_permutation(z, 24), "z$j is not a permutation")
            check(parity(z) == expected_center_parity(e, st, j, cpar), "parity of z$j")
        else
            check(length(z) == 24 && all(x -> 0 <= x <= 5, z) &&
                  all(t -> count(==(t), z) == 4, 0:5), "z$j is not a color multiset")
        end
    end
    if e.picture && odd
        fr = st["fr"]
        check(length(fr) == 6 && all(r -> 0 <= r <= 3, fr), "rotation range")
        check(sum(fr) % 2 == cpar, "R = C")
    end
    if e.framed && odd
        check(length(st["fm"]) == 1 && 0 <= st["fm"][1] <= 23, "frame range")
    end
end

# ---- encoder ----------------------------------------------------------------

"The digit named `name` of a valid state."
function digit_of(e::Entry, st::State, name::String)
    even_canonical = !isodd(e.n) && !e.framed
    if name == "cp"
        even_canonical ? perm_rank([renumber(st["cp"][s + 1]) for s in EVEN_SLOTS]) :
                         perm_rank(st["cp"])
    elseif name == "ct"
        even_canonical ? orient_digit([st["ct"][s + 1] for s in EVEN_SLOTS], 3) :
                         orient_digit(st["ct"], 3)
    elseif name == "mp"
        perm_rank_reduced(st["mp"])
    elseif name == "mf"
        orient_digit(st["mf"], 2)
    elseif startswith(name, "w")
        perm_rank(st[name])
    elseif startswith(name, "z")
        e.picture ? perm_rank_reduced(st[name]) : multiset_rank(st[name])
    elseif name == "fr"
        r = st["fr"]
        big(r[1] + 4r[2] + 16r[3] + 64r[4] + 256r[5] + 1024 * (r[6] ÷ 2))
    elseif name == "fm"
        big(st["fm"][1])
    else
        error("unknown digit $name")
    end
end

function encode(e::Entry, st::State)::String
    validate(e, st)
    acc = big(0)
    for (name, radix) in e.layout
        d = digit_of(e, st, name)
        0 <= d < radix || error("digit $name out of range for entry $(e.id)")
        acc = acc * radix + d
    end
    acc < e.count || error("rank out of range")
    token_text(e.offset + acc, e.len)
end

# ---- decoder ----------------------------------------------------------------

function decode(entries::Vector{Entry}, text::String)
    len = length(text)
    v = token_value(text)
    hits = [e for e in entries if e.len == len && e.offset <= v < e.offset + e.count]
    length(hits) == 1 || error("not a known V2 state token")
    e = hits[1]
    r = v - e.offset
    # Split from the least significant end.
    digits = Dict{String,BigInt}()
    for (name, radix) in reverse(e.layout)
        r, digits[name] = divrem(r, radix)
    end
    r == 0 || error("rank left over")
    odd = isodd(e.n)
    even_canonical = !odd && !e.framed
    st = State()
    # Free components first.
    if even_canonical
        q = perm_unrank(digits["cp"], 7)
        cp = fill(6, 8)
        for (i, s) in enumerate(EVEN_SLOTS)
            cp[s + 1] = unnumber(q[i])
        end
        cpar = parity(q)
        t = orient_unrank(digits["ct"], 7, 3) # six stored digits, seventh forced
        ct = zeros(Int, 8)
        for (i, s) in enumerate(EVEN_SLOTS)
            ct[s + 1] = t[i]
        end
    else
        cp = perm_unrank(digits["cp"], 8)
        cpar = parity(cp)
        ct = orient_unrank(digits["ct"], 8, 3)
    end
    st["cp"] = cp
    st["ct"] = ct
    if odd
        st["mp"] = perm_unrank_reduced(digits["mp"], 12, cpar) # forced parity M = C
        st["mf"] = orient_unrank(digits["mf"], 12, 2)
    end
    for k in 1:wing_orbits(e.n)
        st["w$k"] = perm_unrank(digits["w$k"], 24)
    end
    for j in 1:center_orbit_count(e.n)
        st["z$j"] = e.picture ?
            perm_unrank_reduced(digits["z$j"], 24, expected_center_parity(e, st, j, cpar)) :
            multiset_unrank(digits["z$j"])
    end
    if e.picture && odd
        d = digits["fr"]
        r5 = Int[]
        for _ in 1:5
            d, x = divrem(d, 4)
            push!(r5, Int(x))
        end
        hi = Int(d)
        low = mod(cpar - sum(r5), 2) # R = C fixes the low bit of r_B
        st["fr"] = vcat(r5, [2hi + low])
    end
    e.framed && odd && (st["fm"] = [Int(digits["fm"])])
    validate(e, st)
    (e, st)
end

# ---- random states ----------------------------------------------------------

function random_with_parity(rng, k::Int, par::Int)
    p = randperm(rng, k) .- 1
    if parity(p) != par
        p[1], p[2] = p[2], p[1]
    end
    p
end

function random_state(rng, e::Entry)
    odd = isodd(e.n)
    st = State()
    if !odd && !e.framed
        q = randperm(rng, 7) .- 1
        cp = fill(6, 8)
        for (i, s) in enumerate(EVEN_SLOTS)
            cp[s + 1] = unnumber(q[i])
        end
        ct = zeros(Int, 8)
        for s in 0:5
            ct[s + 1] = rand(rng, 0:2)
        end
        ct[8] = mod(-sum(ct), 3) # slot 7 is the seventh stored slot, DBL (slot 6) has twist 0
    else
        cp = randperm(rng, 8) .- 1
        ct = [rand(rng, 0:2) for _ in 1:8]
        ct[8] = 0
        ct[8] = mod(-sum(ct), 3)
    end
    st["cp"] = cp
    st["ct"] = ct
    cpar = parity(cp)
    if odd
        st["mp"] = random_with_parity(rng, 12, cpar)
        mf = [rand(rng, 0:1) for _ in 1:12]
        mf[12] = 0
        mf[12] = sum(mf) % 2
        st["mf"] = mf
    end
    for k in 1:wing_orbits(e.n)
        st["w$k"] = randperm(rng, 24) .- 1
    end
    for j in 1:center_orbit_count(e.n)
        st["z$j"] = e.picture ?
            random_with_parity(rng, 24, expected_center_parity(e, st, j, cpar)) :
            shuffle(rng, [i ÷ 4 for i in 0:23])
    end
    if e.picture && odd
        r5 = [rand(rng, 0:3) for _ in 1:5]
        rb = 2 * rand(rng, 0:1) + mod(cpar - sum(r5), 2)
        st["fr"] = vcat(r5, [rb])
    end
    e.framed && odd && (st["fm"] = [rand(rng, 1:23)])
    st
end

"Solved pieces with nonzero fixed-center rotations and/or a nonzero frame."
function posed_solved(e::Entry)
    st = solved_state(e)
    e.picture && (st["fr"] = [1, 2, 3, 0, 1, 1]) # sum 8, even, and C = 0
    e.framed && (st["fm"] = [11])
    st
end

# ---- main -------------------------------------------------------------------

function main(out::String)
    here = @__DIR__
    entries = build_registry()
    check_against_spec(entries, joinpath(here, "..", "..", "FORMAT-V2.md"))
    rng = MersenneTwister(6464)
    rows = Tuple{Int,String,String}[]
    for e in entries
        states = State[solved_state(e)]
        isodd(e.n) && (e.picture || e.framed) && push!(states, posed_solved(e))
        for _ in 1:(e.n <= 7 ? 4 : 1)
            push!(states, random_state(rng, e))
        end
        solved_token = encode(e, states[1])
        solved_token == token_text(e.offset, e.len) || error("solved is not the zero rank")
        (e.offset != 0 || solved_token == "A"^e.len) || error("solved token is not A repeated")
        for st in states
            token = encode(e, st)
            text = state_text(e, st)
            parse_state(text) == st || error("state text does not round trip")
            e2, st2 = decode(entries, token)
            (e2.id == e.id && st2 == st) || error("round trip failed for entry $(e.id)")
            push!(rows, (e.id, text, token))
        end
        @printf(stderr, "%2d %-30s len %3d  offset %-8s  rows %d  ok\n", e.id, e.name, e.len,
                e.offset == 0 ? "0" : "N", length(states))
    end
    open(out, "w") do io
        println(io, "// Generated by tools/format-v2/vectors.jl. Do not edit.")
        println(io, "mod TestV2VectorData {")
        println(io, "    /// (entry id, state text, token)")
        println(io, "    pub def rows(): List[(Int32, String, String)] = List#{")
        for (i, (id, text, token)) in enumerate(rows)
            println(io, "        ($id, \"$text\", \"$token\")", i == length(rows) ? "" : ",")
        end
        println(io, "    }")
        println(io, "}")
    end
    @printf(stderr, "wrote %d rows to %s\n", length(rows), out)
end

main(isempty(ARGS) ? joinpath(@__DIR__, "..", "..", "test", "TestV2VectorData.flix") : ARGS[1])
