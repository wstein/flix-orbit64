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
# The convention is V1's `orbit64-Nxn-draft@1`. Corners, midges and wings are
# the reference tables of the 4x4x4 (even n) and 5x5x5 (odd n) with each axis
# coordinate expanded to size n; centers follow from the facelet geometry
# alone. The reference tables below are the ones in `Orbit64.Net`
# (`src/Orbit64/Net.flix`); the expansion is the one `Net` applies for n <= 7,
# used unchanged for n >= 8. A facelet is `face * n^2 + row * n + col` over the
# faces U R F D L B.
#
# Checked on every run: each facelet of the cube, except the six fixed centers
# of an odd cube, belongs to exactly one slot.

# ---- reference slots: each row lists the facelets of one slot ---------------
# A corner lists its three stickers in order, the one that measures twist first,
# then clockwise. A midge lists the sticker that measures flip first. A wing
# lists its reference sticker first.

const CORNER4 = [
    [15, 16, 35],
    [12, 32, 67],
    [0, 64, 83],
    [3, 80, 19],
    [51, 47, 28],
    [48, 79, 44],
    [60, 95, 76],
    [63, 31, 92],
]
const WING4 = [
    [1, 82],
    [7, 18],
    [8, 66],
    [14, 34],
    [17, 11],
    [23, 84],
    [24, 43],
    [30, 59],
    [33, 13],
    [39, 20],
    [40, 75],
    [46, 50],
    [49, 45],
    [55, 29],
    [56, 77],
    [62, 93],
    [65, 4],
    [71, 36],
    [72, 91],
    [78, 52],
    [81, 2],
    [87, 68],
    [88, 27],
    [94, 61],
]
const CORNER5 = [
    [24, 25, 54],
    [20, 50, 104],
    [0, 100, 129],
    [4, 125, 29],
    [79, 74, 45],
    [75, 124, 70],
    [95, 149, 120],
    [99, 49, 145],
]
const MIDGE5 = [
    [14, 27],
    [22, 52],
    [10, 102],
    [2, 127],
    [89, 47],
    [77, 72],
    [85, 122],
    [97, 147],
    [64, 35],
    [60, 114],
    [139, 110],
    [135, 39],
]
const WING5 = [
    [1, 128],
    [9, 28],
    [15, 103],
    [23, 53],
    [26, 19],
    [34, 130],
    [40, 69],
    [48, 94],
    [51, 21],
    [59, 30],
    [65, 119],
    [73, 78],
    [76, 71],
    [84, 46],
    [90, 121],
    [98, 146],
    [101, 5],
    [109, 55],
    [115, 144],
    [123, 80],
    [126, 3],
    [134, 105],
    [140, 44],
    [148, 96],
]

# ---- expansion to size n ----------------------------------------------------

"Maps a reference coordinate (0..b-1) to an axis coordinate of an n-cube."
function axis(b::Int, n::Int, d::Int, v::Int)
    mapped = b == 4 ? (0, d, n - 1 - d, n - 1) : (0, d, n ÷ 2, n - 1 - d, n - 1)
    mapped[v + 1]
end

"Moves a reference facelet to the same slot of an n-cube at wing depth `d`."
function expand(n::Int, d::Int, f::Int)
    b = iseven(n) ? 4 : 5
    face, row, col = f ÷ (b * b), (f ÷ b) % b, f % b
    face * n * n + axis(b, n, d, row) * n + axis(b, n, d, col)
end

expand_table(n, d, table) = [[expand(n, d, f) for f in row] for row in table]

corners(n) = expand_table(n, 1, iseven(n) ? CORNER4 : CORNER5)
midges(n) = expand_table(n, 1, MIDGE5)
wing_orbits(n) = (n - 2) ÷ 2
wings(n, d) = expand_table(n, d, iseven(n) ? WING4 : WING5)

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
    println()
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
    println("slot, reference sticker first; a center slot is one facelet. For `n <= 7`")
    println("the tables are those of `Orbit64.Net`; for `n >= 8` they extend the reference")
    println("slots of the 4x4x4 (even `n`) or 5x5x5 (odd `n`) as FORMAT-V2.md describes.")
    println()
    for n in 2:15
        emit(n)
    end
end

main()
