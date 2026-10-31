#!/usr/bin/env julia
#
# Independent facelet vectors for the Orbit64 V2 facelet bridge
# (src/Orbit64/V2/Facelets.flix).
#
#     julia tools/format-v2/facelet_vectors.jl [output.flix]
#
# Needs only Julia's standard library. Writes `test/TestV2FaceletData.flix`.
#
# Unlike vectors.jl, which draws states in coordinates, this program starts from
# a solved facelet string and applies layer turns and whole-cube rotations to
# it with the geometry of CubeModel.jl. It then reads the orbit coordinates off
# the stickers with slot tables derived from geometry alone (no table is copied
# from the Flix sources), and encodes them with the reference encoder of
# vectors.jl, which is loaded here but not modified. Every state yields one row
# for the canonical entry and one for the framed entry of its size.
#
# Row: (entry id, move text, facelets, token, canonical facelets)
#
# Moves are written `<depth><face><suffix>`: the layer `depth` (1 = outermost)
# counted from `face`, turned clockwise as seen from that face; suffix empty,
# `2` or `'`. Whole-cube rotations are `x`, `y`, `z` with the same suffixes,
# turning like `R`, `U` and `F`. The last column is empty when the canonical
# facelets equal the given ones; otherwise it is the string a canonical entry
# writes (the cube in its reference pose).

using Random

include(joinpath(@__DIR__, "CubeModel.jl"))
using .CubeModel

# vectors.jl ends by running its own main, which writes TestV2VectorData.flix.
# Load everything but that last call.
module Vectors
    using Random, Printf
    src = read(joinpath(@__DIR__, "vectors.jl"), String)
    src = replace(src, r"^main\(.*$"m => "")
    include_string(Vectors, src, "vectors.jl")
end

const FACE_LETTERS = "URFDLB"
# The 24 whole-cube frames of Orbit64.Frame: the physical faces in slots U R F D L B.
const FRAMES = ["URFDLB", "UBRDFL", "ULBDRF", "UFLDBR", "FRDBLU", "FURBDL", "FLUBRD",
                "FDLBUR", "DRBULF", "DFRUBL", "DLFURB", "DBLUFR", "BRUFLD", "BDRFUL",
                "BLDFRU", "BULFDR", "LUFRDB", "LBURFD", "LDBRUF", "LFDRBU", "RDFLUB",
                "RBDLFU", "RUBLDF", "RFULBD"]
const NORMALS = [(0, 1, 0), (1, 0, 0), (0, 0, 1), (0, -1, 0), (-1, 0, 0), (0, 0, -1)]

# ---- facelet states and moves ------------------------------------------------

"A facelet state: the color (0..5) of every facelet, 1-based."
solved_facelets(n) = [(i - 1) ÷ (n * n) for i in 1:6n^2]

"Move every sticker by `image(position, normal) -> (position, normal)`."
function transform(c::CubeModel.Cube, fs::Vector{Int}, image)
    out = similar(fs)
    for (i, (pos, normal)) in enumerate(c.facelets)
        out[c.facelet_index[image(pos, normal)]] = fs[i]
    end
    out
end

"One right-handed quarter turn about `axis` of the layer at coordinate `layer`."
function layer_turn(c, fs, axis, layer)
    transform(c, fs, (p, q) -> p[axis] == layer ?
        (CubeModel.rotate(axis, p), CubeModel.rotate(axis, q)) : (p, q))
end

# A move: (kind, axis, layer, clockwise quarter turns seen from the positive side
# or negative side) is kept as text; `apply_move` parses the text.
const FACE_AXIS = Dict('R' => (1, 1), 'L' => (1, -1), 'U' => (2, 1), 'D' => (2, -1),
                       'F' => (3, 1), 'B' => (3, -1))

function suffix_turns(s)
    s == "" && return 1
    s == "2" && return 2
    s == "'" && return 3
    error("bad suffix $s")
end

"A clockwise quarter turn seen from a positive face is three right-handed ones."
right_handed_turns(sign, clockwise) = sign > 0 ? mod(-clockwise, 4) : clockwise

function apply_move(c::CubeModel.Cube, fs::Vector{Int}, text::String)
    m = c.n - 1
    if text[1] in "xyz"
        axis = Dict('x' => 1, 'y' => 2, 'z' => 3)[text[1]]
        for _ in 1:right_handed_turns(1, suffix_turns(text[2:end])), layer in layers(c)
            fs = layer_turn(c, fs, axis, layer)
        end
        return fs
    end
    mt = match(r"^(\d+)([URFDLB])(2|')?$", text)
    mt === nothing && error("bad move $text")
    depth = parse(Int, mt[1])
    axis, sign = FACE_AXIS[mt[2][1]]
    layer = sign * (m - 2(depth - 1))
    for _ in 1:right_handed_turns(sign, suffix_turns(mt[3] === nothing ? "" : mt[3]))
        fs = layer_turn(c, fs, axis, layer)
    end
    fs
end

function apply_moves(c, fs, moves::Vector{String})
    for mv in moves
        fs = apply_move(c, fs, mv)
    end
    fs
end

layers(c) = CubeModel.layers(c)

# ---- whole-cube frames --------------------------------------------------------

"The rotation of frame `f` as a function on vectors: face `FRAMES[f][i]` goes to slot `i`."
function frame_rotation(f::Int)
    faces = [findfirst(==(ch), FACE_LETTERS) - 1 for ch in FRAMES[f + 1]]
    image(face) = NORMALS[findfirst(==(face), faces)] # where the normal of `face` goes
    ex, ey, ez = image(1), image(0), image(2) # normals of R, U, F
    forward(v) = (v[1] * ex[1] + v[2] * ey[1] + v[3] * ez[1],
                  v[1] * ex[2] + v[2] * ey[2] + v[3] * ez[2],
                  v[1] * ex[3] + v[2] * ey[3] + v[3] * ez[3])
    backward(v) = (v[1] * ex[1] + v[2] * ex[2] + v[3] * ex[3],
                   v[1] * ey[1] + v[2] * ey[2] + v[3] * ey[3],
                   v[1] * ez[1] + v[2] * ez[2] + v[3] * ez[3])
    (forward, backward)
end

rotate_cube(c, fs, f) = let (fwd, _) = frame_rotation(f)
    transform(c, fs, (p, q) -> (fwd(p), fwd(q)))
end
unrotate_cube(c, fs, f) = let (_, bwd) = frame_rotation(f)
    transform(c, fs, (p, q) -> (bwd(p), bwd(q)))
end

# ---- slot tables from geometry --------------------------------------------------

struct Tables
    corners::Vector{Vector{Int}} # facelet indices (0-based) per slot
    midges::Vector{Vector{Int}}
    wings::Vector{Vector{Vector{Int}}} # per depth, per slot
    centers::Vector{Vector{Int}}
    fixed::Vector{Int}
end

const CORNER_SLOTS = [(1, 1, 1), (-1, 1, 1), (-1, 1, -1), (1, 1, -1),
                      (1, -1, 1), (-1, -1, 1), (-1, -1, -1), (1, -1, -1)] # URF UFL ULB UBR DFR DLF DBL DRB
const MIDGE_SLOTS = [(1, 1, 0), (0, 1, 1), (-1, 1, 0), (0, 1, -1), (1, -1, 0), (0, -1, 1),
                     (-1, -1, 0), (0, -1, -1), (1, 0, 1), (-1, 0, 1), (-1, 0, -1), (1, 0, -1)]
# UR UF UL UB DR DF DL DB FR FL BL BR

function facelets_at(c, pos)
    [i - 1 for (i, (p, _)) in enumerate(c.facelets) if p == pos]
end

det3(a, b, d) = CubeModel.det3(a, b, d)

function build_tables(n::Int)
    c = CubeModel.Cube(n)
    m = n - 1
    at(pos, normal) = c.facelet_index[(pos, normal)] - 1
    corners = map(CORNER_SLOTS) do s
        pos = (s[1] * m, s[2] * m, s[3] * m)
        ud = (0, s[2], 0); a = (s[1], 0, 0); b = (0, 0, s[3])
        # Clockwise seen from outside, starting at the U/D facelet.
        order = det3(ud, a, b) < 0 ? [ud, a, b] : [ud, b, a]
        [at(pos, nrm) for nrm in order]
    end
    midges = Vector{Int}[]
    if isodd(n)
        for s in MIDGE_SLOTS
            pos = (s[1] * m, s[2] * m, s[3] * m)
            normals = [(sign(s[1]), 0, 0), (0, sign(s[2]), 0), (0, 0, sign(s[3]))]
            normals = [v for v in normals if v != (0, 0, 0)]
            first_ = s[2] != 0 ? (0, s[2], 0) : (0, 0, s[3])
            other = only(v for v in normals if v != first_)
            push!(midges, [at(pos, first_), at(pos, other)])
        end
    end
    # Sticker classes of the wings: facelets joined by layer turns.
    parent = Dict(i => i for i in 0:6n^2-1)
    find(i) = (while parent[i] != i; i = parent[i]; end; i)
    wing_cubies = [p for p in CubeModel.cubies(c) if CubeModel.kind(c, p) == :wing]
    wings = Vector{Vector{Int}}[]
    for d in 1:(n - 2) ÷ 2
        cubies = [p for p in wing_cubies if (m - minimum(abs(v) for v in p if abs(v) != m)) ÷ 2 == d]
        stickers = Set(i for p in cubies for i in facelets_at(c, p))
        for (axis, layer) in CubeModel.all_turns(c), i in stickers
            pos, nrm = c.facelets[i + 1]
            pos[axis] == layer || continue
            j = at(CubeModel.rotate(axis, pos), CubeModel.rotate(axis, nrm))
            ri, rj = find(i), find(j)
            ri != rj && (parent[ri] = rj)
        end
        reference = find(minimum(stickers))
        slots = Vector{Int}[]
        for p in cubies
            two = facelets_at(c, p)
            ref = only(i for i in two if find(i) == reference)
            push!(slots, [ref, only(i for i in two if i != ref)])
        end
        sort!(slots, by = first)
        length(slots) == 24 || error("n=$n depth $d: $(length(slots)) wings")
        push!(wings, slots)
    end
    # Centers: the four quarter-turn images of a cell on six faces.
    centers = Vector{Int}[]
    seen = Set{Int}()
    for r in 1:n-2, col in 1:n-2
        (isodd(n) && 2r == m && 2col == m) && continue
        cells = Set([r * n + col, col * n + (m - r), (m - r) * n + (m - col), (m - col) * n + r])
        minimum(cells) == r * n + col || continue
        push!(centers, sort!([f * n * n + cell for f in 0:5 for cell in cells]))
    end
    sort!(centers, by = first)
    fixed = isodd(n) ? [f * n * n + (n * n - 1) ÷ 2 for f in 0:5] : Int[]
    Tables(corners, midges, wings, centers, fixed)
end

# ---- reading coordinates off the stickers ---------------------------------------

"The piece and twist of the slot's stickers `seen`, given the home colors of every slot."
function read_piece(home::Vector{Vector{Int}}, seen::Vector{Int}; twists = length(seen))
    k = length(seen)
    for p in eachindex(home), o in 0:twists-1
        all(j -> seen[j + 1] == home[p][mod(j - o, k) + 1], 0:k-1) && return (p - 1, o)
    end
    nothing
end

home_colors(n, table) = [[f ÷ (n * n) for f in slot] for slot in table]

function read_state(n::Int, t::Tables, fs::Vector{Int}; framed::Bool, frame::Int)::Vectors.State
    st = Vectors.State()
    sees(slot) = [fs[f + 1] for f in slot]
    function oriented(table; strict = false)
        home = home_colors(n, table)
        pieces = Int[]; twists = Int[]
        for slot in table
            r = read_piece(home, sees(slot); twists = strict ? 1 : length(slot))
            r === nothing && error("a slot shows no piece")
            push!(pieces, r[1]); push!(twists, r[2])
        end
        pieces, twists
    end
    st["cp"], st["ct"] = oriented(t.corners)
    if isodd(n)
        st["mp"], st["mf"] = oriented(t.midges)
    end
    for (k, table) in enumerate(t.wings)
        pieces, _ = oriented(table; strict = true)
        st["w$k"] = pieces
    end
    for (j, table) in enumerate(t.centers)
        st["z$j"] = sees(table)
    end
    framed && isodd(n) && (st["fm"] = [frame])
    st
end

"""
The state of a facelet string for a canonical or framed entry, and the string in
its reference pose. Odd cubes: the fixed centers name the frame, and the cube is
rotated back. Even canonical: the unique rotation that puts the DBL corner home.
"""
function read_cube(c, n, t, fs; framed::Bool)
    if isodd(n)
        shown = [FACE_LETTERS[fs[f + 1] + 1] for f in t.fixed]
        f = findfirst(==(join(shown)), FRAMES)
        f === nothing && error("fixed centers are no frame")
        canon = unrotate_cube(c, fs, f - 1)
        return read_state(n, t, canon; framed, frame = f - 1), canon
    elseif framed
        return read_state(n, t, fs; framed, frame = 0), fs
    end
    home = home_colors(n, t.corners)
    hits = [(unrotate_cube(c, fs, f), f) for f in 0:23]
    hits = [(g, f) for (g, f) in hits if read_piece(home, [g[i + 1] for i in t.corners[7]]) == (6, 0)]
    length(hits) == 1 || error("expected one pose with DBL home, got $(length(hits))")
    read_state(n, t, hits[1][1]; framed = false, frame = 0), hits[1][1]
end

# ---- rows -----------------------------------------------------------------------

function spaced(n, fs)
    join((join(FACE_LETTERS[fs[f * n * n + i] + 1] for i in 1:n*n) for f in 0:5), " ")
end

const ENTRIES = Vectors.build_registry()
entry_of(n, framed) = only(e for e in ENTRIES if e.n == n && !e.picture && e.framed == framed)

"Two rows (canonical, framed) for the facelet state `fs` reached by `moves`."
function rows_for(c, t, n, moves, fs)
    text = join(moves, " ")
    out = Tuple{Int,String,String,String,String}[]
    for framed in (false, true)
        e = entry_of(n, framed)
        st, canon = read_cube(c, n, t, fs; framed)
        token = Vectors.encode(e, st)
        e2, st2 = Vectors.decode(ENTRIES, token)
        (e2.id == e.id && st2 == st) || error("round trip failed")
        given = spaced(n, fs)
        reference = framed ? "" : (spaced(n, canon) == given ? "" : spaced(n, canon))
        push!(out, (e.id, text, given, token, reference))
    end
    out
end

"Every single layer turn and whole-cube rotation of an n x n x n, as move lists."
function single_moves(n)
    m = n - 1
    out = Vector{String}[]
    for face in "RUF", depth in 1:(n + 1) ÷ 2, suffix in ("", "2", "'")
        # Layers past the middle repeat the same layers seen from the other side.
        push!(out, ["$depth$face$suffix"])
    end
    for face in "LDB", depth in 1:n ÷ 2, suffix in ("", "2", "'")
        push!(out, ["$depth$face$suffix"])
    end
    for axis in "xyz", suffix in ("", "2", "'")
        push!(out, ["$axis$suffix"])
    end
    out
end

function random_moves(rng, n, count)
    out = String[]
    for _ in 1:count
        if rand(rng) < 0.1
            push!(out, string(rand(rng, "xyz"), rand(rng, ["", "2", "'"])))
        else
            push!(out, string(rand(rng, 1:n), rand(rng, "URFDLB"), rand(rng, ["", "2", "'"])))
        end
    end
    out
end

function main(out::String)
    rng = MersenneTwister(6401)
    rows = Tuple{Int,String,String,String,String}[]
    for n in 2:15
        c = CubeModel.Cube(n)
        t = build_tables(n)
        sequences = Vector{String}[String[]]
        n <= 5 && append!(sequences, single_moves(n))
        for _ in 1:(n <= 7 ? 4 : 1)
            push!(sequences, random_moves(rng, n, n <= 7 ? 14 : 10))
        end
        for moves in sequences
            fs = apply_moves(c, solved_facelets(n), moves)
            append!(rows, rows_for(c, t, n, moves, fs))
        end
        println(stderr, "n = $n: ", length(sequences), " states")
    end
    open(out, "w") do io
        println(io, "// Generated by tools/format-v2/facelet_vectors.jl. Do not edit.")
        println(io, "mod TestV2FaceletData {")
        println(io, "    /// (entry id, moves, facelets, token, canonical facelets or empty)")
        for n in 2:15
            sel = [r for r in rows if ENTRIES[r[1] + 1].n == n]
            println(io, "    pub def rows$n(): List[(Int32, String, String, String, String)] = List#{")
            for (i, (id, mv, fl, tok, can)) in enumerate(sel)
                println(io, "        ($id, \"$mv\", \"$fl\", \"$tok\", \"$can\")", i == length(sel) ? "" : ",")
            end
            println(io, "    }\n")
        end
        println(io, "    pub def rows(): List[(Int32, String, String, String, String)] = List.flatten(List#{")
        println(io, "        ", join(("rows$n()" for n in 2:15), ", "))
        println(io, "    })")
        println(io, "}")
    end
    println(stderr, "wrote ", length(rows), " rows to ", out)
end

main(isempty(ARGS) ? joinpath(@__DIR__, "..", "..", "test", "TestV2FaceletData.flix") : ARGS[1])
