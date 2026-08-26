# flix-orbit64

[![Build and Test](https://github.com/wstein/flix-orbit64/actions/workflows/build-and-test.yaml/badge.svg)](https://github.com/wstein/flix-orbit64/actions/workflows/build-and-test.yaml)
[![Docs](https://github.com/wstein/flix-orbit64/actions/workflows/docs.yaml/badge.svg)](https://wstein.github.io/flix-orbit64/)
[![Release](https://img.shields.io/github/v/release/wstein/flix-orbit64)](https://github.com/wstein/flix-orbit64/releases/latest)
[![Flix](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fwstein%2Fflix-orbit64%2Fmain%2F.flixw%2Flock.toml&query=%24.compiler.version&label=Flix&color=blue)](https://flix.dev)
[![License](https://img.shields.io/github/license/wstein/flix-orbit64)](LICENSE)

A canonical, URL-safe, minimal-width encoding for `n x n x n` twisty cube
state, for every size from the 2x2x2 to the 7x7x7.

Read under the same slot convention, two identical cubes always produce the
same token, so string equality is state equality. That qualifier is load-bearing
rather than lawyerly: a token records ordinals and carries no geometry of its
own, so two implementations that number their slots differently will describe
one physical cube with two tokens. [Slot numbering](#slot-numbering) says what
follows from that. No token is a character wider than the state count requires.

```
2x2x2  AAAAA                                       (solved)
2x2x2  AAAVW                                       (every corner twisted)
3x3x3  AAAAAAAAAAf_                                (superflip)
4x4x4  BUt6SRL-hJFWEmpUa2zYHsiSLJb                 (stripes)
5x5x5  AAAAAAAAACIfwsLb0IHy6ACA6kzedO1wdFsR5AAAAA  (superflip)
```

The project carries its own compiler, so there is nothing to install but a
JDK 21+.

[Flix](https://flix.dev) is an effect-oriented language on the JVM -- functional,
imperative and logic in one, with traits, algebraic data types, and a type and
effect system that tracks every side effect in the signature. That earns its keep
in a codec: `encode` and `decode` are pure by construction and the compiler says
so, rather than a reader having to take a comment's word for it. Region-based
local mutation lets the one routine that scatters into an array still type as
pure, and Java interop is one `import` away on the rare occasion it is wanted.

```
./flixw test                                          # 130 tests
./flixw run --entrypoint Orbit64.Cli.main             # size table, round-trip
./flixw run --entrypoint Orbit64.Cli.main -- <token>  # decode; length picks n
```

## Use it as a library

```toml
[dependencies]
"github:wstein/flix-orbit64" = "0.2.0"
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
Facelet strings are in the standard `URFDLB` order, nine stickers per face; the
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

One caveat on reading the tables across: the piece arrays use the standard slot
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

  drawn as orbit64-3x3-draft@1
```

The faces are coloured on a terminal; `NO_COLOR=1` gives the plain letters
above. Note that the six fixed centres are not in the token at all -- the format
leaves them out because they fix the frame rather than carry information -- so
the renderer supplies them before drawing anything.

The 2x2x2 through 5x5x5 are drawn, each under a convention the command line
names beneath the net -- `orbit64-3x3-draft@1`, `orbit64-4x4-draft@1`,
`orbit64-5x5-draft@1` and so on:

```
$ ./flixw run --entrypoint Orbit64.Cli.main -- BUt6SRL-hJFWEmpUa2zYHsiSLJb
4x4x4, 3 orbits:
  ...
                U  D  U  D
                U  D  U  D
                U  D  U  D
                U  D  U  D

 R  R  R  R     B  F  B  F     L  L  L  L     B  F  B  F
 L  L  L  L     B  F  B  F     R  R  R  R     B  F  B  F
 R  R  R  R     B  F  B  F     L  L  L  L     B  F  B  F
 L  L  L  L     B  F  B  F     R  R  R  R     B  F  B  F

                U  D  U  D
                U  D  U  D
                U  D  U  D
                U  D  U  D

  drawn as orbit64-4x4-draft@1
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

Two larger cubes, which the examples at the top of this file use:

| cube  | pattern              | token                                        | how |
|-------|----------------------|----------------------------------------------|-----|
| 2x2x2 | Solved               | `AAAAA`                                      | every coordinate zero, so every character is the padding one |
| 2x2x2 | Every corner twisted | `AAAVW`                                      | identity permutation, twists `1 2 1 2 1 2 1 2` |
| 4x4x4 | Stripes              | `BUt6SRL-hJFWEmpUa2zYHsiSLJb`                | `L2 2R2 U2 2D2` |
| 5x5x5 | Superflip            | `AAAAAAAAACIfwsLb0IHy6ACA6kzedO1wdFsR5AAAAA` | every midge flipped in place, everything else solved |

`L2 2R2 U2 2D2` turns alternate slices on two axes, which bands every face: the
faces perpendicular to neither axis get stripes running one way and the rest the
other, so adjacent faces disagree about which way their stripes run.

The two 2x2x2 states are given as coordinates rather than algorithms, as is the
5x5x5 superflip. A 2x2x2 has nothing but corners, so its recognisable states are
about orientation -- and its whole token is five characters. The 5x5x5 superflip
is corners, wings and both centre orbits identity with every midge flip set,
which is the 3x3x3 superflip's analogue one size up.

The two built from half turns alone, Checkerboard and Four Spots, leave every
corner twist and edge flip at zero -- a half turn applies its orientation change
twice -- so all that survives is permutation. Checkerboard's coordinate is small
enough to leave five leading `A`s, which is the mixed radix showing through: the
orientation digits sit at the bottom of the number and both are zero.

These tokens use the same slot numbering as the arrays in the previous section
and as the nets the command line draws, so all three agree with each other. A model that numbers its slots differently will produce different tokens
for the same picture -- see [Slot numbering](#slot-numbering).

## Slot numbering

The format stores ordinals. Entry 17 of a wing vector says "wing slot 17 holds
wing piece 4", and *which physical sticker pair* slot 17 is, and *which physical
wing* piece 4 is, are not in the format and never were. That absence is the
point: it is what lets `layout` be arithmetic in `n` and cover every size. Both
halves must be agreed out of band before a token can be drawn, or compared entry
by entry against another implementation's arrays.

The pattern tokens above, the piece arrays beside them, and the nets the command
line draws all use the same numbering, so they agree with one another.

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

The nets are drawn under conventions of Orbit64's own -- `orbit64-3x3-draft@1`
through `orbit64-5x5-draft@1` -- and every table behind them is derived from
cube geometry alone. Nothing is read from another project's puzzle definition,
which is deliberate: the projects that describe these same shapes are GPL, and
this package is Apache-2.0.

The derivation needs three things. A cube is `n^3` cubies. A face turn rotates a
layer. A facelet is `face * n * n + row * n + col` over `U R F D L B`. From
those, corners and midges take the standard names in their standard order, and
wings and centres are ordered by the facelet index of each piece's reference
sticker -- which makes slot order a consequence of the facelet layout rather
than a second thing to agree on, and makes a centre's colour index simply its
face index.

That the 3x3x3 tables come out as the ones in wide use is not borrowing. Given
the standard facelet numbering and the standard piece names there is exactly one
right answer, and deriving it from geometry reproduces those values bit for bit.

Naming a convention still does not make existing tokens obey it. If the
implementation that produced a 4x4x4 token numbered its slots differently, the
net will be a correct drawing of the wrong state -- which is why the command
line prints the name it used.

That same gap is why the nets stop at the 5x5x5. Conventions for larger cubes do
exist, and one of them is a close structural match (see
[References](#references)); adopting it would either reinterpret what existing
4x4x4 and 5x5x5 tokens mean, or require exactly the mapping that is missing in
order to convert into it.

## Facelets, and talking to other projects

`Orbit64.Net.toFacelets(n, orbits)` gives the state as `6 * n * n` face indices,
laid out `face * n * n + row * n + col` with faces `U R F D L B` -- the layout
[`flix-cube`](https://github.com/wstein/flix-cube)'s `BigCube` and
`cube-solvers`' `Facelets` both use. Slot orders differ between implementations
and always will; sticker colours do not, so this is the layer at which two
projects can be compared.

`Orbit64.Net.fromFacelets(n, facelets)` is its exact inverse, and the direction
a project carrying a cube engine of its own needs in order to *produce* a token
rather than merely draw one:

```flix
// a cube some other engine turned, as face indices
Orbit64.Net.fromFacelets(4, stickers)
    |> Result.flatMap(orbits -> Orbit64.encode(4, orbits))
```

Both directions read one set of tables, which is why the inverse lives here
rather than in the adapter. Those tables are private, so a project writing its
own reader would have to copy them -- and then the same geometry sits in two
places, where a correction to one silently misses the other.

`test/TestFacelets.flix` checks both directions against `flix-cube`. Its
sticker strings come from `BigCube.showFacelets` after applying a named turn in
that project, by an engine sharing no code with this one, and every fixture has
to both draw to those stickers and read back from them, at the 4x4x4 and the
5x5x5 alike.

Two things this deliberately does not do:

- It does not say whether a state is **reachable**. The format admits
  coordinates outside the physical move group, because it does not enforce
  coupled orbit parity -- see the design note below. A solver may reject a state
  `toFacelets` will happily draw, and that is the format's choice rather than a
  bug in the adapter.
- It does not put an odd cube's **fixed centres** back. `fromFacelets` refuses a
  3x3x3 or 5x5x5 whose six single centres have moved -- a slice turn, a
  whole-cube rotation -- and says that is why. Those centres are the frame this
  format is written in rather than state it carries, so a token has nowhere to
  record where they went. Turning such a state back into the frame is a decision
  about which cube was meant, and making it here would hand back a state other
  than the one that arrived, without saying so. An even cube has no fixed
  centre, so nothing about its centres is a frame and no such refusal applies.

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
- `src/Orbit64/Net.flix` -- draws a decoded cube as a coloured net, up to the
  5x5x5, and reads one back out of its facelets. The only module that knows a
  cube has faces: the codec defines no geometry, so a picture needs one, and
  this derives its own from cube geometry.
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
- `test/TestFacelets.flix` -- cross-project fixtures at the facelet layer,
  generated by `flix-cube`'s turn engine and checked in both directions.
- `test/TestFromFacelets.flix` -- `toFacelets` and `fromFacelets` as exact
  inverses, asserted each way round over the conformance vectors rather than
  over solved cubes, and again over a deterministic seed matrix of unranked
  coordinates that reaches arbitrary wing permutations and centre colourings.
- `test/TestFromFaceletsGuards.flix` -- what `fromFacelets` must refuse, each
  case asserting the wording of the refusal, so that a guard cannot go on
  passing once some earlier check is what actually catches the input.
- `test/TestNetGuards.flix` -- what the renderer must refuse (incomplete,
  reordered, duplicated and foreign orbit lists), and a direct check that each
  convention's tables cover every facelet exactly once.
- `test/TestOrbitDiscovery.flix` -- derives `Orbit.layout` a second time, from
  geometry instead of arithmetic. It builds a cube, turns it, and takes the
  connected components of the "one turn maps this piece to that one" graph,
  which is three Datalog rules. The two derivations share no code, so an orbit
  count that is wrong at a size with no test vectors still fails.


## References

- [`flix-cube`](https://github.com/wstein/flix-cube) -- the same facelet layout,
  and the independent turn engine `test/TestFacelets.flix` checks against.
- [KPuzzle](https://standards.cubing.net/draft/3/kpuzzle/) -- a Cubing Standards
  draft describing a puzzle as named orbits of indexed permutations and
  orientations. Close in spirit to this format's coordinates, and explicitly a
  draft.
- [Twizzle Binary 3x3x3 Format](https://standards.cubing.net/draft/5/binary-3x3x3-encoding/)
  -- 12 bytes, lexicographic permutation ranks, deliberately not minimal so that
  it can validate what it decodes. 3x3x3 only, by name and by design.
- Twizzle Search and `cube-solvers` both model these puzzles at the piece level,
  the latter with an oriented `mEdge`, a distinct `wEdge`, and `xCenter` and
  `tCenter` for a 5x5x5 -- this same decomposition, arrived at independently.
  Both are worth reading and neither is a source for anything here: they are
  GPL, this package is Apache-2.0, and its tables are derived from geometry for
  that reason as much as any other. Comparison happens at the facelet layer,
  where no licence question arises because nobody owns what colour a sticker is.

See `AGENTS.md` for the toolchain, and
<https://wstein.github.io/flix-orbit64/> for the generated API documentation.
