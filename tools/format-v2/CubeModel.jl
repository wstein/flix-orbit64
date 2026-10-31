"""
Geometry of the n x n x n cube for the Orbit64 V2 proof obligations.

Facelets use the geometry of FORMAT.md, section "Facelet geometry": facelet
`face * n^2 + row * n + col`, faces `U R F D L B`, positions on the odd
integer grid `-m, -m + 2, ..., m` with `m = n - 1`.

To make the orientation of a sticker's picture visible, every facelet
carries four tangent directions. A point of the permutation domain is one
(facelet, tangent) pair, so the group generated on these points is the group
of the picture cube: every sticker distinguishable, and its rotation visible.
"""
module CubeModel

export Cube, facelet_geometry, layers, all_turns, canonical_turns, point_turn,
       cubies, kind, cubie_turn, orbits, describe, parity, corner_twist_sum,
       midge_flip_sum, fixed_rotation_change, reference_tangent

const Vec = NTuple{3,Int}

"Position and normal of a facelet, exactly as tabulated in FORMAT.md."
function facelet_geometry(n::Int, face::Int, row::Int, col::Int)::Tuple{Vec,Vec}
    m = n - 1
    a = 2col - m
    b = 2row - m
    face == 0 && return ((a, m, b), (0, 1, 0))
    face == 1 && return ((m, -b, -a), (1, 0, 0))
    face == 2 && return ((a, -b, m), (0, 0, 1))
    face == 3 && return ((a, -m, -b), (0, -1, 0))
    face == 4 && return ((-m, -b, a), (-1, 0, 0))
    return ((-a, -b, -m), (0, 0, -1))
end

"A right-handed quarter turn about axis 1 (x), 2 (y) or 3 (z)."
function rotate(axis::Int, v::Vec)::Vec
    x, y, z = v
    axis == 1 && return (x, -z, y)
    axis == 2 && return (z, y, -x)
    return (-y, x, z)
end

cross(a::Vec, b::Vec)::Vec =
    (a[2]b[3] - a[3]b[2], a[3]b[1] - a[1]b[3], a[1]b[2] - a[2]b[1])
dot(a::Vec, b::Vec) = a[1]b[1] + a[2]b[2] + a[3]b[3]
det3(a::Vec, b::Vec, c::Vec) = dot(a, cross(b, c))

"The four unit vectors perpendicular to `normal`, in a fixed order."
function tangents(normal::Vec)::Vector{Vec}
    out = Vec[]
    for i in 1:3
        normal[i] == 0 || continue
        for s in (1, -1)
            push!(out, ntuple(j -> j == i ? s : 0, 3))
        end
    end
    out
end

struct Cube
    n::Int
    facelets::Vector{Tuple{Vec,Vec}}
    facelet_index::Dict{Tuple{Vec,Vec},Int}
    points::Vector{Tuple{Vec,Vec,Vec}}
    point_index::Dict{Tuple{Vec,Vec,Vec},Int}
end

function Cube(n::Int)
    facelets = Tuple{Vec,Vec}[]
    findex = Dict{Tuple{Vec,Vec},Int}()
    for face in 0:5, row in 0:n-1, col in 0:n-1
        f = facelet_geometry(n, face, row, col)
        push!(facelets, f)
        findex[f] = length(facelets)
    end
    points = Tuple{Vec,Vec,Vec}[]
    pindex = Dict{Tuple{Vec,Vec,Vec},Int}()
    for (pos, normal) in facelets, t in tangents(normal)
        push!(points, (pos, normal, t))
        pindex[(pos, normal, t)] = length(points)
    end
    Cube(n, facelets, findex, points, pindex)
end

layers(c::Cube) = collect(-(c.n - 1):2:(c.n - 1))
all_turns(c::Cube) = [(axis, layer) for axis in 1:3 for layer in layers(c)]

"""
Layer turns that generate a subgroup of the stabilizer of the reference.

Odd cubes: every layer but the three middle ones, which keeps the six fixed
centers in place (they may still spin). Even cubes: every layer but the three
holding the DBL corner, which keeps it home.
"""
function canonical_turns(c::Cube)
    m = c.n - 1
    isodd(c.n) ? [(a, l) for (a, l) in all_turns(c) if l != 0] :
                 [(a, l) for (a, l) in all_turns(c) if l != -m]
end

"Image of every picture point under a quarter turn of one layer."
function point_turn(c::Cube, axis::Int, layer::Int)::Vector{Int32}
    image = Vector{Int32}(undef, length(c.points))
    for (i, (pos, normal, t)) in enumerate(c.points)
        key = pos[axis] == layer ?
              (rotate(axis, pos), rotate(axis, normal), rotate(axis, t)) : (pos, normal, t)
        image[i] = c.point_index[key]
    end
    image
end

cubies(c::Cube) = sort!(unique([pos for (pos, _) in c.facelets]))

function kind(c::Cube, pos::Vec)::Symbol
    m = c.n - 1
    outer = count(v -> abs(v) == m, pos)
    zeros = count(==(0), pos)
    outer == 3 && return :corner
    outer == 2 && return zeros == 1 ? :midge : :wing
    outer == 1 && return zeros == 2 ? :fixed : :center
    error("interior cubie $pos")
end

cubie_turn(c::Cube, axis::Int, layer::Int) =
    Dict(p => (p[axis] == layer ? rotate(axis, p) : p) for p in cubies(c))

"""
Cubie orbits in the V1 order: corners, midges, wings by depth (outermost
first), centers by the lowest facelet index they occupy, fixed centers last.
"""
function orbits(c::Cube)
    parent = Dict(p => p for p in cubies(c))
    function find(p)
        while parent[p] != p
            p = parent[p]
        end
        p
    end
    for (axis, layer) in all_turns(c), (p, q) in cubie_turn(c, axis, layer)
        a, b = find(p), find(q)
        a != b && (parent[a] = b)
    end
    groups = Dict{Vec,Vector{Vec}}()
    for p in cubies(c)
        push!(get!(groups, find(p), Vec[]), p)
    end
    order = Dict(:corner => 0, :midge => 1, :wing => 2, :center => 3, :fixed => 4)
    lowest(g) = minimum(i for (i, (pos, _)) in enumerate(c.facelets) if pos in g)
    function sortkey(g)
        k = kind(c, g[1])
        k == :wing && return (order[k], -minimum(abs(v) for v in g[1] if abs(v) != c.n - 1))
        (order[k], lowest(Set(g)))
    end
    [(kind(c, g[1]), sort(g)) for g in sort(collect(values(groups)), by=sortkey)]
end

"A readable orbit name; centers by the (row, col) of their lowest U facelet."
function describe(c::Cube, k::Symbol, g::Vector{Vec})::String
    m = c.n - 1
    if k == :wing
        along = minimum(abs(v) for v in g[1] if abs(v) != m)
        return "W$((m - along) ÷ 2)"
    elseif k == :center
        members = Set(g)
        i = minimum(i for (i, (pos, _)) in enumerate(c.facelets) if pos in members) - 1
        return "Z[$(i ÷ c.n),$(i % c.n)]"
    end
    k == :corner ? "C" : k == :midge ? "M" : "fixed"
end

"Permutation parity of a mapping of a finite set onto itself."
function parity(mapping::Dict{Vec,Vec})::Int
    seen = Set{Vec}()
    p = 0
    for s in keys(mapping)
        s in seen && continue
        len = 0
        x = s
        while !(x in seen)
            push!(seen, x)
            x = mapping[x]
            len += 1
        end
        p ⊻= (len - 1) & 1
    end
    p
end

"The three normals at a corner, starting with the U/D one, in one rotational sense."
function cycle_normals(pos::Vec)::Vector{Vec}
    ud = (0, sign(pos[2]), 0)
    a = (sign(pos[1]), 0, 0)
    b = (0, 0, sign(pos[3]))
    det3(ud, a, b) > 0 ? [ud, a, b] : [ud, b, a]
end

inverse_rotate(axis, v) = rotate(axis, rotate(axis, rotate(axis, v)))

"""
Sum of corner twists, mod 3, after one turn of the solved cube. A slot's
reference facelet is its U/D one; a piece's twist is the number of steps,
in one fixed rotational sense, from there to the facelet holding the piece's
own U/D sticker. This is Kociemba's convention.
"""
function corner_twist_sum(c::Cube, axis::Int, layer::Int)::Int
    total = 0
    for pos in cubies(c)
        kind(c, pos) == :corner || continue
        src = pos[axis] == layer ? inverse_rotate(axis, pos) : pos
        home = (0, sign(src[2]), 0)
        moved = src[axis] == layer ? rotate(axis, home) : home
        total += findfirst(==(moved), cycle_normals(pos)) - 1
    end
    mod(total, 3)
end

"A midge slot's reference facelet: on U/D if it has one, else on F/B."
reference_normal(pos::Vec)::Vec = pos[2] != 0 ? (0, sign(pos[2]), 0) : (0, 0, sign(pos[3]))

"Sum of midge flips, mod 2, after one turn of the solved cube."
function midge_flip_sum(c::Cube, axis::Int, layer::Int)::Int
    total = 0
    for pos in cubies(c)
        kind(c, pos) == :midge || continue
        src = pos[axis] == layer ? inverse_rotate(axis, pos) : pos
        sticker = reference_normal(src)
        moved = src[axis] == layer ? rotate(axis, sticker) : sticker
        total += moved == reference_normal(pos) ? 0 : 1
    end
    mod(total, 2)
end

"""
The reference direction of a face: toward row 0 in FORMAT.md's geometry,
which is "up" in the usual unfolded net.
"""
function reference_tangent(normal::Vec)::Vec
    normal == (0, 1, 0) && return (0, 0, -1)
    normal == (0, -1, 0) && return (0, 0, 1)
    (0, 1, 0)
end

"Clockwise quarter turns, seen from outside, that take `from` to `to` on a face."
function quarter_turns(normal::Vec, from::Vec, to::Vec)::Int
    t = from
    for k in 0:3
        t == to && return k
        t = cross(t, normal)
    end
    error("tangents not on the same face")
end

"""
Sum, mod 4, of the fixed-center rotations after one turn of the solved cube.
A fixed center's rotation is the number of clockwise quarter turns from its
slot's reference direction to its own (transported) reference direction.
"""
function fixed_rotation_change(c::Cube, axis::Int, layer::Int)::Int
    total = 0
    for pos in cubies(c)
        kind(c, pos) == :fixed || continue
        src = pos[axis] == layer ? inverse_rotate(axis, pos) : pos
        src_normal = (sign(src[1]), sign(src[2]), sign(src[3]))
        marker = reference_tangent(src_normal)
        moved = src[axis] == layer ? rotate(axis, marker) : marker
        normal = (sign(pos[1]), sign(pos[2]), sign(pos[3]))
        total += quarter_turns(normal, reference_tangent(normal), moved)
    end
    mod(total, 4)
end

end
