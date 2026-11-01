#!/usr/bin/env julia
#
# Independent picture-model facelet vectors for the Orbit64 V2 facelet bridge
# (src/Orbit64/V2/Facelets.flix), as specified in FORMAT-V2.md, "Picture
# facelets".
#
#     julia tools/format-v2/facelet_picture_vectors.jl [output.flix]
#
# Needs only Julia's standard library. Writes
# `test/TestV2FaceletPictureData.flix`.
#
# Like facelet_vectors.jl, which this program loads for its slot tables, its
# frames and its move grammar, it starts from the solved cube and applies layer
# turns, inner layers and whole-cube rotations. Unlike it, the state it moves is
# the *point* state of CubeModel.jl: every facelet carries four tangent
# directions, so the program knows which sticker is on every facelet and, for
# a fixed center, how far it has turned. Nothing is tracked by coordinates. The
# stickers are then written as symbols, the coordinates are read off the
# symbols, and the reference encoder of vectors.jl turns the coordinates into
# the token. That encoder validates the orientation laws and the parity
# relations, so a rotation convention that disagreed with the relation `R = C`
# would stop this program.
#
# Row: (entry id, move text, facelets, token, canonical facelets), as in
# facelet_vectors.jl. The last column is empty when the canonical facelets equal
# the given ones.

include(joinpath(@__DIR__, "facelet_vectors.jl"))

const CM = CubeModel
const SYMBOLS = Vectors.ALPHABET

# ---- the point state ------------------------------------------------------------

"Point `i` of the cube is `(facelet = (i - 1) ÷ 4, tangent = (i - 1) % 4)`, 1-based."
facelet_of_point(i) = (i - 1) ÷ 4

"The turns of one move text: a list of (axis, layer) right-handed quarter turns."
function layer_turns(c, text::String)
    m = c.n - 1
    if text[1] in "xyz"
        axis = Dict('x' => 1, 'y' => 2, 'z' => 3)[text[1]]
        count = right_handed_turns(1, suffix_turns(text[2:end]))
        return [(axis, layer) for _ in 1:count for layer in layers(c)]
    end
    mt = match(r"^(\d+)([URFDLB])(2|')?$", text)
    mt === nothing && error("bad move $text")
    axis, sign = FACE_AXIS[mt[2][1]]
    layer = sign * (m - 2(parse(Int, mt[1]) - 1))
    count = right_handed_turns(sign, suffix_turns(mt[3] === nothing ? "" : mt[3]))
    [(axis, layer) for _ in 1:count]
end

mutable struct Mover
    c::CM.Cube
    images::Dict{Tuple{Int,Int},Vector{Int32}}
end
Mover(c) = Mover(c, Dict{Tuple{Int,Int},Vector{Int32}}())

image_of(mv::Mover, axis, layer) =
    get!(() -> CM.point_turn(mv.c, axis, layer), mv.images, (axis, layer))

"The point state after the moves: entry `i` is the original point now at point `i`."
function apply_points(mv::Mover, P::Vector{Int}, moves::Vector{String})
    for text in moves, (axis, layer) in layer_turns(mv.c, text)
        image = image_of(mv, axis, layer)
        Q = similar(P)
        for (j, target) in enumerate(image)
            Q[target] = P[j]
        end
        P = Q
    end
    P
end

"Carry the points through a whole-cube rotation of frame `f`; `inverse` undoes it."
function pose_points(c::CM.Cube, P::Vector{Int}, f::Int; inverse::Bool)
    fwd, bwd = frame_rotation(f)
    move = inverse ? bwd : fwd
    Q = similar(P)
    for (i, (pos, normal, t)) in enumerate(c.points)
        Q[c.point_index[(move(pos), move(normal), move(t))]] = P[i]
    end
    Q
end

# ---- the sticker symbols ----------------------------------------------------------

"""
The symbol value of the sticker whose home is each facelet, in the canonical
pose: corners `3 p + j`, midges `2 p + j`, wings `2 p + j`, center orbit stickers
the home slot, and fixed centers `4 p` (the rotation is added from the tangents).
`p` is the slot of the piece, `j` the position of the sticker in the slot.
"""
function home_values(n::Int, t::Tables)
    home = Dict{Int,Int}()
    for (s, slot) in enumerate(t.corners), (k, f) in enumerate(slot)
        home[f] = 3(s - 1) + (k - 1)
    end
    for (s, slot) in enumerate(t.midges), (k, f) in enumerate(slot)
        home[f] = 2(s - 1) + (k - 1)
    end
    for table in t.wings, (s, slot) in enumerate(table), (k, f) in enumerate(slot)
        home[f] = 2(s - 1) + (k - 1)
    end
    for table in t.centers, (s, f) in enumerate(table)
        home[f] = s - 1
    end
    for (p, f) in enumerate(t.fixed)
        home[f] = 4(p - 1)
    end
    length(home) == 6n^2 || error("n=$n: the sticker classes cover $(length(home)) of $(6n^2)")
    home
end

"""
The symbol values on every facelet for the point state `P`. A fixed center adds its
rotation: the clockwise quarter turns, seen from outside, from the reference
direction of the facelet's face to the sticker's own reference direction.
"""
function symbol_values(c::CM.Cube, home::Dict{Int,Int}, P::Vector{Int})::Vector{Int}
    out = zeros(Int, length(c.facelets))
    for f in 0:length(c.facelets)-1
        g = facelet_of_point(P[4*f + 1])
        out[f + 1] = home[g]
        pos_g, normal_g = c.facelets[g + 1]
        pos_f, normal_f = c.facelets[f + 1]
        count(==(0), pos_f) == 2 && count(v -> abs(v) == c.n - 1, pos_f) == 1 || continue
        isodd(c.n) || continue
        own = c.point_index[(pos_g, normal_g, CM.reference_tangent(normal_g))]
        i = only(i for i in 4*f+1:4*f+4 if P[i] == own)
        tangent = c.points[i][3]
        out[f + 1] += CM.quarter_turns(normal_f, CM.reference_tangent(normal_f), tangent)
    end
    out
end

spaced_symbols(n, values) =
    join((join(SYMBOLS[values[f * n * n + i] + 1] for i in 1:n*n) for f in 0:5), " ")

# ---- reading the coordinates off the symbols -------------------------------------

"Piece and twist of a slot's symbols: `seen[k] = m p + (k - o) mod m`."
function piece_of(seen::Vector{Int}, m::Int; strict = false)
    p, j = divrem(seen[1], m)
    o = mod(-j, m)
    strict && o != 0 && error("a wing is flipped")
    all(k -> seen[k + 1] == m * p + mod(k - o, m), 0:m-1) || error("a slot mixes pieces: $seen")
    (p, o)
end

function read_picture_state(n::Int, t::Tables, V::Vector{Int}; framed::Bool, frame::Int)
    st = Vectors.State()
    sees(slot) = [V[f + 1] for f in slot]
    function oriented(table, m; strict = false)
        read = [piece_of(sees(slot), m; strict) for slot in table]
        first.(read), last.(read)
    end
    st["cp"], st["ct"] = oriented(t.corners, 3)
    if isodd(n)
        st["mp"], st["mf"] = oriented(t.midges, 2)
    end
    for (k, table) in enumerate(t.wings)
        st["w$k"] = first(oriented(table, 2; strict = true))
    end
    for (j, table) in enumerate(t.centers)
        st["z$j"] = sees(table)
    end
    if isodd(n)
        for (face, f) in enumerate(t.fixed)
            V[f + 1] ÷ 4 == face - 1 || error("fixed center $(face - 1) is not home")
        end
        st["fr"] = [V[f + 1] % 4 for f in t.fixed]
        framed && (st["fm"] = [frame])
    end
    st
end

# ---- poses -------------------------------------------------------------------------

"""
The point state in the canonical pose, the frame (0 unless odd and framed) and the
symbols of both. Odd cubes: the fixed centers name the frame. Even canonical:
the unique rotation with the DBL corner home and untwisted.
"""
function posed(c, n, t, home, P; framed::Bool)
    if isodd(n)
        shown = join(FACE_LETTERS[symbol_values(c, home, P)[f + 1] ÷ 4 + 1] for f in t.fixed)
        f = findfirst(==(shown), FRAMES)
        f === nothing && error("fixed centers are no frame: $shown")
        return pose_points(c, P, f - 1; inverse = true), framed ? f - 1 : 0
    end
    framed && return P, 0
    hits = [Q for f in 0:23 for Q in (pose_points(c, P, f; inverse = true),)
            if piece_of([symbol_values(c, home, Q)[i + 1] for i in t.corners[7]], 3) == (6, 0)]
    length(hits) == 1 || error("expected one pose with DBL home, got $(length(hits))")
    hits[1], 0
end

# ---- rows --------------------------------------------------------------------------

const PICTURE_ENTRIES = Vectors.build_registry()
picture_entry(n, framed) =
    only(e for e in PICTURE_ENTRIES if e.n == n && e.picture && e.framed == framed)

"Two rows (canonical, framed) for the point state `P` reached by `moves`."
function picture_rows(c, n, t, home, moves, P)
    out = Tuple{Int,String,String,String,String}[]
    given = spaced_symbols(n, symbol_values(c, home, P))
    for framed in (false, true)
        e = picture_entry(n, framed)
        Q, frame = posed(c, n, t, home, P; framed)
        V = symbol_values(c, home, Q)
        st = read_picture_state(n, t, V; framed, frame)
        token = Vectors.encode(e, st)
        e2, st2 = Vectors.decode(PICTURE_ENTRIES, token)
        (e2.id == e.id && st2 == st) || error("round trip failed")
        canonical = framed ? given : spaced_symbols(n, V)
        push!(out, (e.id, join(moves, " "), given, token, canonical == given ? "" : canonical))
    end
    out
end

"Moves that spin the fixed centers of an odd cube: slices through the middle."
function slice_moves(n)
    mid = (n + 1) ÷ 2
    ["$(mid)R", "$(mid)U", "$(mid)F'", "$(mid)R2", "x", "$(mid)U'"]
end

function picture_sequences(rng, n)
    sequences = Vector{String}[String[]]
    n == 3 && append!(sequences, single_moves(n))
    isodd(n) && push!(sequences, slice_moves(n))
    count, length_ = n <= 7 ? (3, 12) : (2, 8)
    for k in 1:count
        moves = random_moves(rng, n, length_)
        # Large cubes: the second sequence ends in whole-cube rotations.
        n > 7 && k == 2 && append!(moves, ["x", "y'"])
        push!(sequences, moves)
    end
    sequences
end

function write_rows(io, rows)
    ids(n) = [r for r in rows if PICTURE_ENTRIES[r[1] + 1].n == n]
    println(io, "// Generated by tools/format-v2/facelet_picture_vectors.jl. Do not edit.")
    println(io, "mod TestV2FaceletPictureData {")
    println(io, "    /// (entry id, moves, facelets, token, canonical facelets or empty)")
    for n in 3:15
        # Three lines per row: 18 rows keep each definition within the metrics limit of 60.
        parts = collect(Iterators.partition(ids(n), 18))
        for (k, part) in enumerate(parts)
            println(io, "    pub def rows$(n)p$k(): List[(Int32, String, String, String, String)] = List#{")
            for (i, (id, mv, fl, tok, can)) in enumerate(part)
                println(io, "        ($id, \"$mv\", \"$fl\",\n         \"$tok\",\n         \"$can\")",
                        i == length(part) ? "" : ",")
            end
            println(io, "    }\n")
        end
        println(io, "    pub def rows$n(): List[(Int32, String, String, String, String)] =")
        println(io, "        List.flatten(List#{", join(("rows$(n)p$k()" for k in 1:length(parts)), ", "), "})\n")
    end
    println(io, "    pub def rows(): List[(Int32, String, String, String, String)] = List.flatten(List#{")
    println(io, "        ", join(("rows$n()" for n in 3:9), ", "), ",")
    println(io, "        ", join(("rows$n()" for n in 10:15), ", "))
    println(io, "    })")
    println(io, "}")
end

function main_picture(out::String)
    rng = MersenneTwister(6403)
    rows = Tuple{Int,String,String,String,String}[]
    for n in 3:15
        c = CM.Cube(n)
        t = build_tables(n)
        home = home_values(n, t)
        mv = Mover(c)
        for moves in picture_sequences(rng, n)
            P = apply_points(mv, collect(1:length(c.points)), moves)
            new = picture_rows(c, n, t, home, moves, P)
            append!(rows, new)
        end
        println(stderr, "n = $n: ", count(r -> PICTURE_ENTRIES[r[1] + 1].n == n, rows), " rows")
    end
    open(io -> write_rows(io, rows), out, "w")
    println(stderr, "wrote ", length(rows), " rows to ", out)
end

main_picture(isempty(ARGS) ? joinpath(@__DIR__, "..", "..", "test", "TestV2FaceletPictureData.flix") : ARGS[1])
