# flix-orbit64

[![Build and Test](https://github.com/wstein/flix-orbit64/actions/workflows/build-and-test.yaml/badge.svg)](https://github.com/wstein/flix-orbit64/actions/workflows/build-and-test.yaml)
[![Docs](https://github.com/wstein/flix-orbit64/actions/workflows/docs.yaml/badge.svg)](https://wstein.github.io/flix-orbit64/)
[![Release](https://img.shields.io/github/v/release/wstein/flix-orbit64)](https://github.com/wstein/flix-orbit64/releases/latest)
[![Flix](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fwstein%2Fflix-orbit64%2Fmain%2F.flixw%2Flock.toml&query=%24.compiler.version&label=Flix&color=blue)](https://flix.dev)
[![License](https://img.shields.io/github/license/wstein/flix-orbit64)](LICENSE)

A canonical, URL-safe, minimal-width encoding for `n x n x n` twisty cube
state, for every size from the 2x2x2 to the 7x7x7.

Two cubes that look the same produce the same token, so string equality is
state equality -- and no token is a character wider than the state count
requires.

```
3x3x3  AAAAAAAAAAf_                                (superflip)
4x4x4  BJSsuyGPOiU06kIz-eqibqTP1th                 (scrambled)
5x5x5  BZC-qGPah6s_QRSpZqYwHRBzEXMajtc7pIOYt8AIaS  (scrambled)
```

Built on [flix-template](https://github.com/wstein/flix-template), which
carries its own compiler. Nothing to install but a JDK 21+.

[Flix](https://flix.dev) is an effect-oriented language on the JVM -- functional,
imperative and logic in one, with traits, algebraic data types, and a type and
effect system that tracks every side effect in the signature. That earns its keep
in a codec: `encode` and `decode` are pure by construction and the compiler says
so, rather than a reader having to take a comment's word for it. Region-based
local mutation lets the one routine that scatters into an array still type as
pure, and Java interop is one `import` away on the rare occasion it is wanted.

```
./flixw test                                          # 94 tests
./flixw run --entrypoint Orbit64.Cli.main             # size table, round-trip
./flixw run --entrypoint Orbit64.Cli.main -- <token>  # decode; length picks n
```

## Use it as a library

```toml
[dependencies]
"github:wstein/flix-orbit64" = "0.1.0"
```

```flix
use Orbit64.Coord.Coord.{CornerCoord, MidgeCoord}

def demo(): Unit \ IO =
    let superflip = List#{
        CornerCoord(Vector.range(0, 8), Vector.repeat(8, 0)),
        MidgeCoord(Vector.range(0, 12), Vector.repeat(12, 1))
    };
    match Orbit64.encode(3, superflip) {
        case Ok(token) => println(token)          //=> AAAAAAAAAAf_
        case Err(e)    => println("nope: ${e}")
    }
```

The API documentation is published at
<https://wstein.github.io/flix-orbit64/>, rendered by `flix doc` from the
compiler this project pins.

`Orbit64.decode(n, token)` is the exact inverse. Everything the package defines
nests under the `Orbit64` module, so nothing it ships can collide with names of
yours -- and it defines no top-level `main`, so yours still compiles.

## The format

Every twisty cube factors into orbits -- families of pieces that turns permute
among themselves and never mix. Each orbit gets one coordinate over a range of
exactly its own size, the coordinates are combined by mixed radix, and the
result is written in base64url at a fixed width. No separators, no field
alignment, no type tag.

| orbit     | count               | range         | bits  |
|-----------|---------------------|---------------|-------|
| `Corners` | always 1            | `8! * 3^7`    | 26.39 |
| `Midges`  | 1 if `n` odd, `n>=3`| `12! * 2^11`  | 39.84 |
| `Wings`   | `(n-2)/2`           | `24!`         | 79.04 |
| `Centers` | `(n-2)^2/4`         | `24!/(4!)^6`  | 51.53 |

Where a cube has more than one centre orbit, list position is the only thing
telling them apart -- they are all `CenterCoord`. On a 5x5x5 the renderer's
convention fixes the fourth entry as the **X-centres** (the four diagonal cells
of a face's centre block) and the fifth as the **plus-centres** (the four
edge-adjacent cells).

Both counts truncate, so `layout` is pure arithmetic in `n` -- this codebase has
no notion of a face, an axis, or a turn.

| cube  | bits   | chars |
|-------|--------|-------|
| 2x2x2 |  26.39 |     5 |
| 3x3x3 |  66.23 |    12 |
| 4x4x4 | 156.96 |    27 |
| 5x5x5 | 248.32 |    42 |
| 6x6x6 | 390.58 |    66 |
| 7x7x7 | 533.47 |    89 |

Widths are distinct and grow as `n^2`, so a token's length identifies its
puzzle. Tokens are fixed-width and left-padded with `A`, and index 0 is `A`, so
a solved cube of any size is a run of `A`s.

## The same cube, three ways

The two 3x3x3 states below, in the notations you are most likely to meet them in.
Facelet strings are in Kociemba's `URFDLB` order, nine stickers per face; the
piece arrays are corner permutation and orientation, then edge permutation and
orientation.

**Solved**

```
facelets  UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB
pieces    cp 0 1 2 3 4 5 6 7           co 0 0 0 0 0 0 0 0
          ep 0 1 2 3 4 5 6 7 8 9 10 11 eo 0 0 0 0 0 0 0 0 0 0 0 0
orbit64   AAAAAAAAAAAA
```

**Superflip** -- every corner solved, every edge in place but flipped

```
facelets  UBULURUFURURFRBRDRFUFLFRFDFDFDLDRDBDLULBLFLDLBUBRBLBDB
pieces    cp 0 1 2 3 4 5 6 7           co 0 0 0 0 0 0 0 0
          ep 0 1 2 3 4 5 6 7 8 9 10 11 eo 1 1 1 1 1 1 1 1 1 1 1 1
orbit64   AAAAAAAAAAf_
```

The superflip's coordinate is exactly 2047 -- the eleven free flip bits all set
and nothing else -- which is why ten `A`s are followed by `f_`. It is a fair
advertisement for what mixed-radix packing buys over fixed-width fields.

| representation | size | bits | over the floor |
|----------------|------|------|----------------|
| facelets, `URFDLB`         | 54 characters over a 6-letter alphabet | 139.6 | 2.11x |
| pieces, `cp` `co` `ep` `eo`| 40 values, packed at 3, 2, 4 and 1 bits | 100.0 | 1.51x |
| orbit64                    | 12 base64url characters | 72.0 | 1.09x |

The floor is 66.23 bits, and no base64url encoding can spend fewer than 12
characters on it. The other two are not wasteful by accident: facelets describe
stickers rather than pieces, so most 54-character strings are not cubes at all,
and the piece arrays pay index width for permutations whose ranks are much
smaller than their alphabets.

One caveat on reading the tables across: the piece arrays use Kociemba's slot
numbering, and the format itself prescribes none. For these two states that makes
no difference -- both are the same under any consistent labelling -- but for a
general state the convention has to be agreed before the arrays can be compared
entry by entry. [Slot numbering](#slot-numbering) says what follows from that.

## Patterns

Well-known 3x3x3 patterns as tokens -- each is the algorithm applied to a solved
cube, then encoded. Paste one back in and the command line draws it:

```
$ ./flixw run --entrypoint Orbit64.Cli.main -- AEtgYICyPB1X
3x3x3, 2 orbits:
  Corners: CornerCoord(Vector#{0, 4, 5, 1, 3, 7, 6, 2}, ...)
  Midges: MidgeCoord(Vector#{1, 8, 5, 9, 3, 11, 7, 10, 0, 4, 6, 2}, ...)

             F  F  F 
             F  U  F 
             F  F  F 

 D  D  D     R  R  R     U  U  U     L  L  L 
 D  L  D     R  F  R     U  R  U     L  B  L 
 D  D  D     R  R  R     U  U  U     L  L  L 

             B  B  B 
             B  D  B 
             B  B  B 

  drawn as kociemba-3x3x3
```

The faces are coloured on a terminal; `NO_COLOR=1` gives the plain letters
above. Note that the six fixed centres are not in the token at all -- the format
leaves them out because they fix the frame rather than carry information -- so
the renderer supplies them before drawing anything.

The 2x2x2 through 5x5x5 are drawn, each under a convention the command line
names beneath the net -- `kociemba-3x3x3` for the small cubes,
`twizzle-4x4x4@baa0685` for the 4x4x4, `orbit64-5x5-draft@1` for the 5x5x5:

```
$ ./flixw run --entrypoint Orbit64.Cli.main -- BJSsuyGPOiU06kIz-eqibqTP1th
...
  drawn as twizzle-4x4x4@baa0685
```

A token carries no geometry, so that name is what turns a disagreement into
something traceable rather than merely noticeable. See
[Slot numbering](#slot-numbering).

| pattern | token | algorithm |
|---------|-------|-----------|
| Solved         | `AAAAAAAAAAAA` | |
| Superflip      | `AAAAAAAAAAf_` | `U R2 F B R B2 R U2 L B2 R U' D' R2 F R' L B2 U2 F2` |
| Checkerboard   | `AAAAAH1cCIAA` | `U2 D2 F2 B2 L2 R2` |
| Four Spots     | `AVd4zWoSqIAA` | `F2 B2 U D' R2 L2 U D'` |
| Six Spots      | `AEtgYICyPB1X` | `U D' R L' F B' U D'` |
| Cube in a Cube | `AEtd1CzDOflC` | `F L F U' R U F2 L2 U' L' B D' B' L2 U` |
| Tetris         | `AW622DQhY0VX` | `L R F B U' D' L' R'` |

The two built from half turns alone, Checkerboard and Four Spots, leave every
corner twist and edge flip at zero -- a half turn applies its orientation change
twice -- so all that survives is permutation. Checkerboard's coordinate is small
enough to leave five leading `A`s, which is the mixed radix showing through: the
orientation digits sit at the bottom of the number and both are zero.

These tokens are computed with the piece indexing from Kociemba's `cornerFacelet`
and `edgeFacelet` tables, the same convention as the arrays in the previous
section and as the nets the command line draws, so all three agree with each
other. A model that numbers its slots differently will produce different tokens
for the same picture -- see [Slot numbering](#slot-numbering).

## Slot numbering

The format stores ordinals. Entry 17 of a wing vector says "wing slot 17 holds
wing piece 4", and *which physical sticker pair* slot 17 is, and *which physical
wing* piece 4 is, are not in the format and never were. That absence is the
point: it is what lets `layout` be arithmetic in `n` and cover every size. Both
halves must be agreed out of band before a token can be drawn, or compared entry
by entry against another implementation's arrays.

The pattern tokens above, the piece arrays beside them, and the nets the command
line draws all use Kociemba's corner and edge numbering, so they agree with one
another.

What is *not* established is that the reference implementation behind
`test/TestVectors.flix` used that same numbering -- and it cannot be established
from the vectors. Relabelling slots and pieces by any bijection conjugates every
permutation, and conjugation preserves everything the arrays can be asked: cycle
structure, permutation parity, the orientation sums, and so reachability.
Relabelling a checked-in 3x3x3 vector leaves every invariant identical and
changes only the token:

```
             sgn(cp)  sgn(ep)  sum(co)%3  sum(eo)%2  token
original          -1       -1          0          0  AWMmIry_APKe
relabelled        -1       -1          0          0  ARk53HQPqynD
```

So the vectors pin this codec's arithmetic exactly, which is what they are for,
and carry no geometry whatsoever. Drawing a checked-in token therefore assumes a
correspondence that nothing here verifies. Settling it needs something the
vectors do not contain -- the generator's slot table, or the move sequences that
produced them, from which the relabelling could be solved for and then checked
against every vector at once.

The 4x4x4 net does have a named source. It reads the vectors as the twsearch
4x4x4 KPuzzle definition orders them, pinned at exactly
[this file at commit `baa0685`](https://github.com/cubing/twsearch/blob/baa0685f2e3c69c708b4b94be8600691511dd57c/src/lib/scramble/puzzles/definitions/4x4x4/4x4x4.kpuzzle.json) -- but that
definition contains no facelets, because KPuzzle describes state and moves
rather than stickers. So the mapping was not copied from it; it was solved for,
as the one correspondence between its slot indices and a physical cube that
reproduces its move permutations, then checked three ways: it is unique, it
survives moves the solver never saw, and it agrees with the definition's own
default pattern. `test/TestNet4x4.flix` pins the result against nets rendered by
that separate model.

What naming a convention does *not* do is make existing tokens obey it. If the
implementation that produced a 4x4x4 token numbered its slots differently, the
net will be a correct drawing of the wrong state -- which is why the command
line prints the name it used.

The 5x5x5 is drawn under `orbit64-5x5-draft@1`, built the same way but named
ours rather than Twizzle's, because nothing upstream speaks it. It keeps
Kociemba's corner and midge numbering -- so a 5x5x5 reads as a 3x3x3 with more
orbits -- and derives its wings and both centre orbits from the twsearch 5x5x5
move model. That model's `SPEFFZ_1..5` turn out to be *sticker* orbits: 1 and 3
the two wing sticker orbits, 2 the X-centres, 4 the plus-centres, 5 the midges.
Which is also why it cannot be adopted wholesale -- it carries no midge flip and
no wing piece identity, tracks the six fixed centres this format omits, and is
named `5x5x5_temp` upstream.

`draft` means the geometry is internally verified, not that anything else speaks
it. What was checked: every one of the 150 facelets covered exactly once, a
solved cube drawing six solid faces, moves behaving under an independent model
over 18,000 stickers, fixtures from that model in `test/TestNet5x5.flix`, and
tokens round-tripping. One of those fixtures is a wide turn, chosen because it
leaves the X-centre and plus-centre vectors different from each other -- so
swapping the two orbits fails rather than passing quietly.

That same gap is why the nets stop at the 5x5x5. Conventions for larger cubes do
exist, and one of them is a close structural match (see
[References](#references)); adopting it would either reinterpret what existing
4x4x4 and 5x5x5 tokens mean, or require exactly the mapping that is missing in
order to convert into it.

## Design decisions

**Orientation is stored one entry short.** The last corner twist is forced by
the sum-mod-3 rule and the last edge flip by parity, so `rank` drops them and
`unrank` reconstructs them. Free, and it is what turns `3^8` into `3^7`.

**Permutation parity is *not* enforced.** Corner and edge permutation parity are
coupled on a 3x3x3; using that would save exactly one bit at the cost of
interleaving the two orbits' encodings. At 66.23 bits the token is 12
characters either way. Dropped. The consequence is that a few tokens decode to
states no sequence of turns can reach, which is a decoder's problem rather than
a format's -- `Orbit64.Coord.isValid` is there for callers who care.

**`encode` refuses coordinates that are not a cube.** That is a different
question from the one above, and the two are worth keeping apart. Parity says
whether a cube could have been *reached* by turning; this says whether it is a
cube at all -- eight distinct corners, twists that sum to zero mod three, four
centres of each colour. `encode` checks the second and not the first.

It has to. A coordinate above its own range does not merely encode itself
wrongly: the assembly is Horner, so the surplus carries into the next orbit and
corrupts a coordinate that was correct. And a coordinate inside its range but
not a cube -- a permutation with a repeat -- ranks as some other legitimate
state, so it encodes silently to a token for a different cube. Neither is
visible to `decode`, which can only bounds-check the token as a whole.
`Orbit64.Coord.faultOf` names the rule that was broken.

**Whole-cube rotation is not quotiented out.** Canonicalising orientation would
save log2(24) ~ 4.6 bits but needs a canonical-form search, and "canonical" is
ill-defined on an even cube with no fixed centres. So `stateCount(4)` is exactly
24 times the classic 4x4x4 figure, and `stateCount(3)` exactly twice the classic
3x3x3 figure. Both are asserted in the tests.

**base64url over base58.** Measured on a reference implementation, the
big-integer division base58 needs came to about 2% of an encode -- the cost is
in reading the cube, not in packing it. So density wins: 6 bits per character
against 5.858, which is a character off the 3x3x3 token.

**Centres are indistinguishable, wings are not.** Four centres of a colour are
interchangeable, so a centre orbit is a multiset arrangement. Two wings of a
colour pair look interchangeable but are not: the pair appears in opposite order
depending on the slot's handedness, so `24!` is right and `24!/2^12` is not.
`Orbit64.Rank.multisetRank` handles the first; a plain Lehmer rank handles the second.

## Datalog, and where it stops paying

Flix embeds Datalog, which here earns its keep in exactly one place and not in
the place next door.

`Orbit.layout(n)` is arithmetic -- one corner orbit, midges when `n` is odd,
`(n-2)/2` wing orbits, `(n-2)^2/4` centre orbits -- and nothing inside the codec
can check that, because the codec *is* that formula. So the tests derive the
same answer from geometry instead: build the cubies of an `n`-cube, turn the
layers a solver is allowed to turn, and take the connected components of the
graph that says one turn carries this piece to that one. Two pieces share an
orbit exactly when some sequence of turns connects them, which is a transitive
closure, which is three rules:

```
Same(x, y) :- Turn(x, y).
Same(x, y) :- Same(y, x).
Same(x, z) :- Same(x, y), Same(y, z).
```

The two derivations share no code -- the library has no notion of a face, an
axis or a turn -- so agreement between them means something. It is not
decorative either: an extra wing orbit fails at the 2x2x2, and midges on even
cubes fails at the 4x4x4. And it is cheap, because a 7x7x7 has only 218 surface
pieces.

The neighbouring idea does not pay. Distance-from-solved is a lattice rule of
the same shape -- `Dist(t; d+1) :- Dist(s; d), Move(s, t)` under a minimum
lattice -- and it does work: over the 2x2x2's 3,674,160 states and 11 million
move facts it terminates and reports a depth of 22 quarter turns. It also dies
of heap exhaustion at the JVM's 4 GB default after nearly five minutes, and
needs 12 GB to finish in under three. Against graphs of increasing size the
engine stays near-linear in facts to about a million and then degrades on
allocation, so this is a memory ceiling and not bad asymptotics. But a distance
table is a fact about solving cubes rather than encoding them, and neither the
subject nor the budget belongs here. It stays out of the codec and out of CI.

## Layout

- `src/Orbit64/Rank.flix` -- Lehmer codes, combination ranks in the
  combinatorial number system, multiset ranks. Every intermediate radix stays inside `Int32`; big
  integers appear only in the final assembly.
- `src/Orbit64/Orbit.flix` -- which orbits a cube has and how large each one is.
- `src/Orbit64/Coord.flix` -- one orbit's state and its rank/unrank.
- `src/Orbit64.flix` -- mixed-radix assembly, base64url, `encode`/`decode`. The
  public API; everything a caller needs is here.
- `src/Orbit64/Cli.flix` -- the demo command line, kept out of the library's
  way so that it does not define a top-level `main`.
- `src/Orbit64/Net.flix` -- draws a decoded 2x2x2 or 3x3x3 as a coloured net.
  The only module that knows a cube has faces: the codec defines no geometry,
  so a picture has to borrow a convention, and this one borrows Kociemba's.
- `test/TestVectors.flix` -- conformance vectors generated by an independent
  reference implementation that drives a geometric cube model: real turns on a
  3D facelet representation, orbits found by connected components, every state
  verified to round-trip at sticker level.
- `test/TestOrbit64.flix` -- sizes, round-trips, and error handling.
- `test/TestNet4x4.flix` -- fixtures for the 4x4x4 display convention: states
  built by a separate geometric model, with that model's own nets as the
  expected output.
- `test/TestNet5x5.flix` -- the same for the 5x5x5, including a wide turn that
  distinguishes the two centre orbits.
- `test/TestOrbitDiscovery.flix` -- derives `Orbit.layout` a second time, from
  geometry instead of arithmetic. It builds a cube, turns it, and takes the
  connected components of the "one turn maps this piece to that one" graph,
  which is three Datalog rules. The two derivations share no code, so an orbit
  count that is wrong at a size with no test vectors still fails.


## References

- [Kociemba's cube definition string](http://kociemba.org/cube.htm) -- the
  `URFDLB` facelet order, and the `cornerFacelet` and `edgeFacelet` tables this
  project borrows for its 3x3x3 pictures and its pattern tokens.
- [KPuzzle](https://standards.cubing.net/draft/3/kpuzzle/) -- a Cubing Standards
  draft describing a puzzle as named orbits of indexed permutations and
  orientations. It defines the representation rather than mandating one global
  slot order, and it is explicitly a draft.
- Twizzle Search publishes concrete KPuzzle definitions, among them
  [4x4x4](https://github.com/cubing/twsearch/blob/baa0685f2e3c69c708b4b94be8600691511dd57c/src/lib/scramble/puzzles/definitions/4x4x4/4x4x4.kpuzzle.json) -- pinned here at commit `baa0685`, which is the exact file
  `Orbit64.Net`'s 4x4x4 tables were derived from --
  whose `CORNERS`, `WINGS` and `CENTERS` orbits are a close structural match to
  this codec's, and
  [5x5x5](https://github.com/cubing/twsearch/blob/main/src/lib/scramble/puzzles/definitions/big_cubes/5x5x5.kpuzzle.json),
  whose orbit naming is more generic and would not line up with `Midges`,
  `Wings` and two `Centers` without an explicit conversion.
- [Twizzle Binary 3x3x3 Format](https://standards.cubing.net/draft/5/binary-3x3x3-encoding/)
  -- 12 bytes, lexicographic permutation ranks, and deliberately not minimal so
  that it can validate what it decodes. 3x3x3 only, by name and by design.

See `AGENTS.md` for the toolchain, and
<https://wstein.github.io/flix-orbit64/> for the generated API documentation.
