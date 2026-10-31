# Orbit64 V2 state token format

**Status: draft.** This document specifies the second Orbit64 state format. It
is not a revision of [FORMAT.md](FORMAT.md): V2 drops V1's class bits and
replaces them with a registry of puzzle types, so the two formats are separate.
Nothing here changes what V1 tokens mean or what this library currently
implements. The reference implementation will follow in a separate change.

The format's claims about state counts are proved by
[`tools/format-v2/proof_obligations.jl`](tools/format-v2/proof_obligations.jl);
its committed output is
[`tools/format-v2/proof-obligations.md`](tools/format-v2/proof-obligations.md).

## Goals

1. **Short tokens for small puzzles.** A token for a small puzzle costs at most
   one character more than the information it carries. For puzzles that need
   more than about 20 characters, one character more or less matters little.
2. **No wasted values.** Nothing in V2 is a bit field. Every piece of
   information is a mixed-radix digit with exactly as many values as it has
   possibilities, and parity-coupled information is not stored at all.
3. **Self-identifying.** A token alone names its puzzle type and its state.
   No side channel is needed beyond knowing that it is a V2 state token.
4. **Readable solved states.** A solved puzzle of a type that starts its
   length is `A` repeated to that length.
5. **Long-lived.** The token rules in this document are meant to stay frozen.
   New puzzle types are added through the registry. Adding one never changes
   the meaning of an existing token.

## Token text and value

A token is a string of length `L >= 1` over the base64url alphabet, without
padding, in this index order:

```text
ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_
```

Its **value** `V` is the string read as a big-endian base-64 numeral, so
`0 <= V < 64^L`. Leading `A` characters are significant. A token's length is
part of the token. `A` and `AA` are different tokens, and every string of
length `L` is a distinct token.

## Registry and allocation

The **registry** is an ordered list of entries. Entry `i` has the ID `i` and
describes one puzzle type. It specifies:

- a **state count** `N_i`, an exact positive integer;
- a **rank function**, a bijection from the type's states onto `[0, N_i)`
  that ranks the type's distinguished zero state, normally the solved state,
  as `0`.

**Allocation rule.** The entries are placed in registry order. Entry `i` takes
the shortest length `L_i` whose unallocated values can still hold all its
states, and starts its range directly after the entries already placed at that
length:

```text
used(L)  = sum of N_j over the entries j < i with L_j = L    (0 if there are none)
L_i      = the least L >= 1 with used(L) + N_i <= 64^L
offset_i = used(L_i)
```

A state of entry `i` with rank `r` is the token of length `L_i` whose value is
`offset_i + r`.

**Decoding.** Given a token of length `L` and value `V`, find the entry with
`L_i = L` and `offset_i <= V < offset_i + N_i`. Its rank is `V - offset_i`.
If no entry matches, the token is rejected: it is malformed, or it belongs to
an entry added by a newer registry. A decoder should report the two cases the
same way, for example as "not a known V2 state token".

**Growth rules.** These rules make adding an entry safe:

- Entries are only appended. An entry is never removed, reordered, or changed,
  and its ID is never reused. A retired type keeps its range.
- Appending entry `i` changes no earlier entry's length or offset, because the
  rule places `i` from what earlier entries left. So no existing token ever
  changes meaning.
- The first entry placed at a length has offset `0`, so its zero state is
  `A` repeated `L` times. Entries placed later at the same length start with
  other leading characters and end in `A` characters.

The registry is part of this specification. Implementations may compute the
lengths and offsets with the rule or hard-code the table below. Both give the
same result.

## Initial registry

| ID | Type | States | Bits | Length | Offset | Solved token |
| -: | ---- | -----: | ---: | -----: | -----: | ------------ |
| 0 | 2x2x2 color canonical | 3.674e+06 | 21.81 | 4 | 0 | `AAAA` |
| 1 | 2x2x2 color framed | 8.818e+07 | 26.39 | 5 | 0 | `AAAAA` |
| 2 | 3x3x3 color canonical | 4.325e+19 | 65.23 | 11 | 0 | `A` x 11 |
| 3 | 3x3x3 color framed | 1.038e+21 | 69.81 | 12 | 0 | `A` x 12 |
| 4 | 3x3x3 picture canonical | 8.858e+22 | 76.23 | 13 | 0 | `A` x 13 |
| 5 | 3x3x3 picture framed | 2.126e+24 | 80.81 | 14 | 0 | `A` x 14 |
| 6 | 4x4x4 color canonical | 7.401e+45 | 152.37 | 26 | 0 | `A` x 26 |
| 7 | 4x4x4 color framed | 1.776e+47 | 156.96 | 27 | 0 | `A` x 27 |
| 8 | 4x4x4 picture canonical | 7.072e+53 | 178.88 | 30 | 0 | `A` x 30 |
| 9 | 4x4x4 picture framed | 1.697e+55 | 183.47 | 31 | 0 | `A` x 31 |
| 10 | 5x5x5 color canonical | 2.829e+74 | 247.32 | 42 | 0 | `A` x 42 |
| 11 | 5x5x5 color framed | 6.789e+75 | 251.91 | 42 | `N_10` | `CgGWpjtIh4vYo4b_KxcD7DG7DGuzTmUAIAAAAAAAAA` |
| 12 | 5x5x5 picture canonical | 5.289e+93 | 311.34 | 52 | 0 | `A` x 52 |
| 13 | 5x5x5 picture framed | 1.269e+95 | 315.93 | 53 | 0 | `A` x 53 |
| 14 | 6x6x6 color canonical | 1.572e+116 | 386.00 | 65 | 0 | `A` x 65 |
| 15 | 6x6x6 color framed | 3.772e+117 | 390.58 | 66 | 0 | `A` x 66 |
| 16 | 6x6x6 picture canonical | 1.310e+148 | 492.03 | 83 | 0 | `A` x 83 |
| 17 | 6x6x6 picture framed | 3.144e+149 | 496.62 | 83 | `N_16` | see the report |
| 18 | 7x7x7 color canonical | 1.950e+160 | 532.47 | 89 | 0 | `A` x 89 |
| 19 | 7x7x7 color framed | 4.680e+161 | 537.06 | 90 | 0 | `A` x 90 |
| 20 | 7x7x7 picture canonical | 3.039e+211 | 702.53 | 118 | 0 | `A` x 118 |
| 21 | 7x7x7 picture framed | 7.295e+212 | 707.12 | 118 | `N_20` | see the report |

The exact state counts, the full solved tokens and the free space left at each
length are in [the proof report](tools/format-v2/proof-obligations.md). The
smallest puzzles keep plenty of room. The 4-character length is 22% used and
the 5-character length 8%, so many more small types fit before any of them
needs a longer token.

## The n x n x n cube types

Entries 0 to 21 are members of one family: the `n x n x n` cube for `n = 2..7`,
in two **sticker models** and two **pose variants**. A 2x2x2 has no centers,
so its picture model equals its color model and is not registered separately.

### Pieces and orbits

A cube with `m = n - 1` has these cubie orbits. Moves permute pieces only
within an orbit.

| Orbit | Pieces | Exists when | Orientation |
| ----- | -----: | ----------- | ----------- |
| corners `C` | 8 | always | twist in `0..2` |
| midges `M` | 12 | `n` odd | flip in `0..1` |
| wings `W1..Ww` | 24 each | `w = floor((n - 2) / 2)` orbits | fixed by position |
| centers `Z` | 24 each | `floor((n - 2)^2 / 4)` orbits | fixed by position |
| fixed centers | 6 | `n` odd | rotation in `0..3` |

Wings are numbered by depth, with `W1` the outermost. A center orbit is named
`Z[r,c]` after the lowest facelet it occupies on `U`, at row `r` and column
`c`. Center orbits are ordered by that facelet's index. This is V1's orbit
order, `Orbit.layout(n)`.

A wing or center piece has no orientation of its own. A cubie's orientation is
the rotation that takes it from its home position to its current one. For a
cubie that no nontrivial cube rotation keeps in place, which is every wing and
every non-fixed center, that rotation is determined by the position alone.
Only corners (3 orientations), midges (2) and fixed centers (4) have a point
stabilizer.

### Sticker models

- **Color.** Stickers carry one of six colors. Corners, midges and wings are
  still distinguishable by their colors. The four centers of one color in a
  center orbit are not, and a fixed center's rotation is invisible. A center
  orbit is therefore a multiset with four copies of each color, and fixed
  centers carry no rotation.
- **Picture.** Every sticker is distinguishable and its rotation is visible.
  Center pieces are numbered by their home slot, and each fixed center records
  its rotation.

The picture model covers any cube whose stickers all differ, such as labeled,
printed or photo cubes. A cube with only some distinguishable stickers is a
future registry entry, see [Extensions](#extensions).

### Pose variants

- **Canonical.** The whole-cube orientation is not part of the state. On odd
  cubes the state is read after turning the cube so that the six fixed centers
  are home: by color in the color model, by piece in the picture model. On
  even cubes it is read after turning the cube so that the DBL corner is in
  slot DBL with twist 0. Exactly one of the 24 rotations does this, see
  obligation P3.
- **Framed.** The whole-cube orientation is part of the state, and the token
  carries 24 times as many states. On odd cubes the frame is stored as a final
  digit. On even cubes it is carried by all eight corners, as in V1.

Canonical is the default. Use framed only when the use case needs the cube's
orientation in space, for example a display or a camera-relative scan.
Converting framed to canonical is total and loses only the frame. Converting
canonical to framed gives the frame rank `0`.

### Conventions

V2 uses V1's slot convention `orbit64-Nxn-draft@1` unchanged: the corner and
midge slot orders, the twist and flip conventions, and the wing and center slot
tables. These are defined in [FORMAT.md](FORMAT.md) and `Orbit64.Net`. The six
colors are the face indexes `U R F D L B` = `0..5`. Frames use V1's `Frame`
order of the 24 right-handed whole-cube frames.

The new conventions for the picture model are:

- **Center identity.** The piece whose home is slot `j` of an orbit is piece
  `j`. An orbit's state is the permutation `p`, where `p[i]` is the piece in
  slot `i`.
- **Fixed-center rotation.** Each face's reference direction points toward
  row 0 of that face in FORMAT.md's facelet geometry: toward `B` on `U`,
  toward `F` on `D`, and up on the four side faces. A fixed center's rotation
  `r_f` is the number of clockwise quarter turns, seen from outside, that take
  face `f`'s reference direction to the piece's own reference direction (the
  direction that pointed to row 0 when the cube was solved).

### Rank primitives

`par(p)` is the parity of permutation `p`: 0 if even, 1 if odd. The
primitives are V1's, defined in `Orbit64.Rank`:

- **Permutation rank** of `p` over `0..k-1`:
  `sum_{i=0}^{k-1} c_i * (k - 1 - i)!`, where
  `c_i = #{ j > i : p[j] < p[i] }`. Radix `k!`.
- **Parity-reduced rank** of `p` with known parity: the same sum over
  `i = 0..k-3` only, with each term divided by 2. The order of the last two
  entries follows from the parity. Radix `k!/2`.
- **Multiset rank** of a 24-slot center orbit with four copies of each color:
  for colors `t = 0..4` in turn, take the slots still unassigned, numbered
  `0, 1, ...` in ascending slot order, and rank the positions of color `t`
  among them by the combinatorial number system, `sum_i C(s_i, i + 1)` over
  the ascending positions `s_0 < s_1 < s_2 < s_3`. Combine these with
  radixes `C(24, 4), C(20, 4), C(16, 4), C(12, 4), C(8, 4)`, most significant
  first. Color 5 fills the rest. Radix `24! / (4!)^6`.
- **Orientation digits**: the first `k - 1` orientations in slot order, read
  little-endian, so the first slot is the units digit. The last orientation
  follows from the orientation law.

### Digit layout

A state's rank is the Horner combination of these digits, most significant
first. Digits that do not exist for a size or model are skipped.

| # | Digit | Radix |
| -: | ----- | ----: |
| 1 | corner permutation, permutation rank | `8!`, or `7!` (even, canonical) |
| 2 | corner twists, orientation digits | `3^7`, or `3^6` (even, canonical) |
| 3 | midge permutation, parity-reduced rank | `12!/2` |
| 4 | midge flips, orientation digits | `2^11` |
| 5 | each wing orbit `W1..Ww`, permutation rank | `24!` |
| 6 | each center orbit, in orbit order: multiset rank (color) or parity-reduced rank (picture) | `24!/(4!)^6` or `24!/2` |
| 7 | fixed-center rotations (picture, odd) | `2^11` |
| 8 | frame (framed, odd) | `24` |

In the even canonical variant, the DBL corner (slot 6) is home with twist 0. It
is left out, and the seven other corners are numbered `0..6` in slot order. In
the even framed variant, all eight corners are stored as in V1. The cube's
orientation is then implicit in them, so there is no frame digit.

Digit 7 combines the six fixed-center rotations:
`r_U + 4 r_R + 16 r_F + 64 r_D + 256 r_L + 1024 * floor(r_B / 2)`. The parity
of `r_B` follows from the relation `par(R) = par(C)` below, where
`R = r_U + r_R + r_F + r_D + r_L + r_B`.

### Parity relations

Reachable states satisfy the orientation laws (corner twists sum to 0 mod 3,
midge flips to 0 mod 2) and the following parity relations. These are all of
them (obligation P2). In each relation, the left side is a **forced**
component. It is stored with the parity-reduced rank (or, for `R`, without the
low bit of `r_B`), and its parity is computed from the free components on the
right. A component written `C`, `M`, `W1` or `Z[r,c]` stands for that orbit's
permutation parity.

| Size | Picture model | Color model |
| ---- | ------------- | ----------- |
| 2x2x2 | none | none |
| 3x3x3 | `M = C`, `R = C` | `M = C` |
| 4x4x4 | `Z[1,1] = C` | none |
| 5x5x5 | `M = C`, `Z[1,1] = C`, `Z[1,2] = C + W1`, `R = C` | `M = C` |
| 6x6x6 | `Z[1,1] = C`, `Z[1,2] = C + W1 + W2`, `Z[1,3] = C + W1 + W2`, `Z[2,2] = C` | none |
| 7x7x7 | `M = C`, `Z[1,1] = C`, `Z[1,2] = C + W1 + W2`, `Z[1,3] = C + W1`, `Z[1,4] = C + W1 + W2`, `Z[2,2] = C`, `Z[2,3] = C + W2`, `R = C` | `M = C` |

The sums are mod 2. Corners, wings and the color model's center multisets are
never forced. In the picture model, every center orbit and the fixed-center
rotation parity are forced. These relations hold in both pose variants. On
even cubes, `C` is the parity of all eight corners, which equals the parity of
the seven stored ones when DBL is home.

### Encoding and decoding

To **encode** a state of entry `i`:

1. For a canonical entry, normalize the pose. For a framed odd entry, record
   the frame and normalize.
2. Validate: the permutations are permutations, the orientation laws hold, the
   parity relations hold, and each color multiset has four of each color. An
   invalid state is an error, never a token.
3. Compute the digits, combine them, add `offset_i`, and write the result at
   length `L_i`.

To **decode**, find the entry and its rank (see
[Registry and allocation](#registry-and-allocation)). Split the rank into its
digits from the least significant end. Unrank the free components, compute the
forced parities, then unrank the forced components and complete the
orientations. Every rank below `N_i` decodes to a valid state, and every valid
state encodes to exactly one rank.

## Proof obligations

Each claim the format relies on is proved here: as a short argument or by
`proof_obligations.jl`, which needs only Julia's standard library.

- **P1. Ranks are bijections.** Each digit is a bijection onto its radix:
  Lehmer codes, the combinatorial number system, positional orientation digits,
  and the parity-reduced rank for a fixed parity. A mixed-radix Horner
  combination of bijections is a bijection onto the product of the radixes.
  This product equals `N_i` by P2.
- **P2. The counts are exact.** Let `H` be the group of reachable states with
  the reference home: generated by every layer turn except the middle layers
  (odd) or the three layers holding DBL (even). The script computes
  - an **upper bound** on `|H|` from invariants. The twist and flip laws hold
    for every generator. The GF(2) parity relations are all the linear forms
    that vanish on every generator of the full group, restricted to fixed
    centers at home. Each piece in the picture model has exactly the
    orientations in the table above.
  - a **lower bound** on `|H|`, as the product of the orbit lengths of a
    Schreier-Sims chain built from elements of `H`. Every element in the chain
    lies in the group, so the product never overstates `|H|`. Random elements
    only decide how fast the bound grows, never whether it holds.

  The bounds are equal for every `n = 2..7`, so the picture counts and the
  parity relations above are exact. The color model's reachable states are the
  picture model's states with center identities and rotations forgotten. Two
  same-colored centers of one orbit can always be swapped, and a fixed center
  can always be turned, without changing the colors, so the color relations are
  exactly the picture relations that involve no center or `R`. Then
  `24 * N(color canonical) = V1 State.stateCount(n)` for every `n`.
- **P3. The pose normalization is well defined.** The reference (fixed centers
  on odd cubes, DBL with its twist on even cubes) has exactly 24 poses. The 24
  whole-cube rotations reach all of them, and only the identity keeps the
  reference home. So every state has exactly one canonical form and framed
  counts are 24 times canonical counts. On odd cubes, moves move fixed centers
  only rigidly, as a rotation. On even cubes, a corner has `8 * 3 = 24` poses.
- **P4. Ranges are disjoint and stable.** This follows from the allocation
  rule, see [Growth rules](#registry-and-allocation).
- **P5. Lengths are exact.** The lengths and offsets above are computed with
  exact integer arithmetic. No length sits at a rounding boundary.
- **P6. Solved is all `A`.** The solved state has identity permutations, zero
  orientations and frame rank 0, so every digit is 0 and its rank is 0. Its
  token is `A` repeated `L_i` when `offset_i = 0`.

Every future entry must come with the same obligations: an exact count with a
proof, a bijective rank with zero for its zero state, and reference vectors.

## Relation to V1

V2 drops V1's class bits. It also drops V1's move-sequence and
structured-algorithm classes and the extension envelope from the state token
space. Those formats are not state tokens, and a V2 token is only a state
token. V1's canonical form, the pattern class under rotation, mirror and
recoloring, is a separate function and not a V2 pose variant.

The digit layouts of the color framed entries are V1's coordinate order. In
the initial registry, entries 1, 3, 7, 15 and 19 start at offset 0 at V1's
token widths 5, 12, 27, 66 and 90. A V1 state token for the 2x2x2, 3x3x3,
4x4x4, 6x6x6 or 7x7x7 is therefore the V2 token of the same state. A V1 5x5x5
token has 43 characters, a length where the initial registry has no entries,
so a V2 decoder rejects it rather than misreading it. This is a property of
the initial registry, not a promise: label V2 tokens where they could be
confused with V1 tokens or other strings, for example by a field name or a
`orbit64v2:` prefix.

## Extensions

New types are appended to the registry. Directions already anticipated:

- **Larger cubes** (`n > 7`) and **cuboids** `a x b x c`, appended member by
  member when needed. A family is a naming convention, not a token feature.
- **Unconstrained variants**: physically assembled states that ignore the
  orientation laws and parity relations. A scanner needs them to report a
  misassembled cube, and the count is the product of the free radixes.
- **Partial distinguishability**: cubes where only some stickers differ, for
  example a logo on one center. Such an entry declares which pieces are
  equivalent. The color and picture models are the two extremes.
- **Masks**: states with unknown pieces, for partial scans and learning
  goals such as "only the cross matters".
- **Other puzzles and shape changers**: pyramids, megaminxes, Square-1,
  bandaged cubes. Each needs its own rank function and count proof.

Symmetries of a sticker's design, such as a `0` that looks the same after a
half turn, belong in a goal or target definition, not in the token. The token
records the physical state.

## Open items before V2 leaves draft

1. Inline the V1 slot tables (`orbit64-Nxn-draft@1`) here, so that V2 no longer
   depends on another document.
2. Implement V2 in this library. Commit reference vectors for every entry: the
   solved state, single turns, a frame, and random states checked against an
   independent facelet simulation.
3. Port the other implementations (cubacle, cube-assembler, cubelab) only
   after that.
