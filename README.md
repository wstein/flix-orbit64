# flix-orbit64

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
./flixw test                                          # 67 tests
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
numbering and orbit64 uses its own layout order. For these two states that makes
no difference -- both are the same under any consistent labelling -- but for a
general state the convention has to be agreed before the arrays can be compared
entry by entry.

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
- `test/TestVectors.flix` -- conformance vectors generated by an independent
  reference implementation that drives a geometric cube model: real turns on a
  3D facelet representation, orbits found by connected components, every state
  verified to round-trip at sticker level.
- `test/TestOrbit64.flix` -- sizes, round-trips, and error handling.

See `AGENTS.md` for the toolchain.
