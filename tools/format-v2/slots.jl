#!/usr/bin/env julia
#
# Generates FORMAT-V2-SLOTS.md: the facelet index of every slot of every orbit
# of the n x n x n cube, n = 2..15, in the V2 slot convention (FORMAT-V2.md,
# "Conventions").
#
#     julia tools/format-v2/slots.jl > FORMAT-V2-SLOTS.md
#
# Needs only Julia's standard library and writes the document to standard
# output. The output is deterministic, and CI regenerates it and compares.
#
# The convention is the one in FORMAT-V2.md. Corners and midges expand the
# 5x5x5 reference, and wings expand the 4x4x4 reference, with each axis
# coordinate carried to size n; centers follow from the facelet geometry
# alone. The reference tables are read from `Orbit64.V2.Facelets`
# (`src/Orbit64/V2/Facelets.flix`), which is the same expansion for every
# n from 2 to 15. A facelet is `face * n^2 + row * n + col` over the faces
# U R F D L B.
#
# Checked on every run: each facelet of the cube, except the six fixed centers
# of an odd cube, belongs to exactly one slot.

# ---- reference slots: read from Facelets.flix --------------------------------
# Each row lists the facelets of one slot. A corner lists its three stickers in
# order: the one that measures twist first (on U or D), then the other two
# clockwise seen from outside the cube. A midge lists the sticker that measures
# flip first. A wing lists its reference sticker first.
#
# The tables are not copied here: they are read from the literal vectors in
# `Orbit64.V2.Facelets`, so a change there changes this program's output and CI
# fails until the generated document is regenerated.

const FACELETS_SOURCE = joinpath(@__DIR__, "..", "..", "src", "Orbit64", "V2", "Facelets.flix")

"The rows of `def name(): Vector[Vector[Int32]] = Vector#{ Vector#{..}, .. }`."
function reference_table(source::String, name::String)
    head = raw"\(\): Vector\[Vector\[Int32\]\] = Vector#\{(.*?)\n\s*\}"
    def = match(Regex("def " * name * head, "s"), source)
    def === nothing && error("Facelets.flix: no table named $name")
    rows = [parse.(Int, split(m.captures[1], ",")) for m in eachmatch(r"Vector#\{([\d,\s]+)\}", def.captures[1])]
    isempty(rows) && error("Facelets.flix: table $name is empty")
    rows
end

const FACELETS = read(FACELETS_SOURCE, String)
const CORNERS = reference_table(FACELETS, "cornerReference")
const MIDGES = reference_table(FACELETS, "midgeReference")
const WING_REF = reference_table(FACELETS, "wingReference")

# ---- expansion to size n ----------------------------------------------------

"Maps a reference coordinate (0..b-1) to an axis coordinate of an n-cube."
function axis(b::Int, n::Int, d::Int, v::Int)
    mapped = b == 4 ? (0, d, n - 1 - d, n - 1) : (0, d, n ÷ 2, n - 1 - d, n - 1)
    mapped[v + 1]
end

"Moves a reference facelet of a `b x b` cube to the same slot of an n-cube at wing depth `d`."
function expand(n::Int, b::Int, d::Int, f::Int)
    face, row, col = f ÷ (b * b), (f ÷ b) % b, f % b
    face * n * n + axis(b, n, d, row) * n + axis(b, n, d, col)
end

expand_table(n, b, d, table) = [[expand(n, b, d, f) for f in row] for row in table]

corners(n) = expand_table(n, 5, 1, CORNERS)
midges(n) = expand_table(n, 5, 1, MIDGES)
wing_orbits(n) = (n - 2) ÷ 2
wings(n, d) = expand_table(n, 4, d, WING_REF)

"The center orbits as (r, c): r = 1..n-2, then c = r while c < n-1-r."
center_names(n) = [(r, c) for r in 1:n-2 for c in r:n-2-r]

"The 24 facelets of orbit Z[r,c], ascending: the four rotations of (r, c) on every face."
function center_slots(n::Int, r::Int, c::Int)
    m = n - 1
    cells = Set([r * n + c, c * n + (m - r), (m - r) * n + (m - c), (m - c) * n + r])
    sort!([face * n * n + cell for face in 0:5 for cell in cells])
end

# ---- document ---------------------------------------------------------------

function check_cover(n::Int)
    seen = Int[]
    for slot in corners(n); append!(seen, slot); end
    isodd(n) && for slot in midges(n); append!(seen, slot); end
    for d in 1:wing_orbits(n), slot in wings(n, d); append!(seen, slot); end
    for (r, c) in center_names(n); append!(seen, center_slots(n, r, c)); end
    fixed = isodd(n) ? [face * n * n + (n * n - 1) ÷ 2 for face in 0:5] : Int[]
    sort!(seen) == setdiff(0:6n * n - 1, fixed) ||
        error("n = $n: the slots do not cover each facelet exactly once")
    length(center_names(n)) == ((n - 2)^2) ÷ 4 || error("n = $n: center orbit count")
end

join_facelets(slot) = join(slot, " ")

function emit(n::Int)
    check_cover(n)
    println()
    println("## $(n)x$(n)x$(n)")
    println()
    println("Facelets `0..$(6n * n - 1)`.",
            isodd(n) ? " The fixed centers are `face * $(n * n) + $((n * n - 1) ÷ 2)`." : "")
    println()
    println("```text")
    println("corners   slot: facelets")
    for (i, slot) in enumerate(corners(n))
        println("  C ", i - 1, ": ", join_facelets(slot))
    end
    if isodd(n)
        println("midges")
        for (i, slot) in enumerate(midges(n))
            println("  M ", i - 1, ": ", join_facelets(slot))
        end
    end
    for d in 1:wing_orbits(n)
        println("wings, depth ", d)
        for (i, slot) in enumerate(wings(n, d))
            println("  W", d, " ", i - 1, ": ", join_facelets(slot))
        end
    end
    isempty(center_names(n)) || println("centers, 24 slots each, ascending")
    for (r, c) in center_names(n)
        println("  Z[", r, ",", c, "]: ", join_facelets(center_slots(n, r, c)))
    end
    println("```")
end

function main()
    println("<!-- Generated by tools/format-v2/slots.jl. Do not edit. -->")
    println()
    println("# Orbit64 V2 slot tables")
    println()
    println("**Generated, do not edit.** Regenerate with")
    println("`julia tools/format-v2/slots.jl > FORMAT-V2-SLOTS.md`. CI checks that this file")
    println("is that program's output.")
    println()
    println("This is the slot convention of [FORMAT-V2.md](FORMAT-V2.md) written out: the")
    println("facelet index of every slot of every orbit, for `n = 2..15`. A facelet is")
    println("`face * n^2 + row * n + col` over the faces `U R F D L B`. Slots are numbered")
    println("from 0 in the order listed. A corner, midge or wing lists the facelets of its")
    println("slot, reference sticker first; a center slot is one facelet. The tables")
    println("are read from `Orbit64.V2.Facelets`: corners and midges expand the 5x5x5")
    println("reference and wings expand the 4x4x4 reference, for every `n`.")
    println()
    println("Corner stickers are listed in one fixed order: the first is on the U or D")
    println("face, and the other two follow clockwise as seen from outside the cube.")
    for n in 2:15
        emit(n)
    end
end

main()
