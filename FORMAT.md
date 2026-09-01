# Orbit64 token format

Orbit64 is a family of canonical, URL-safe token formats for `n x n x n`
twisty cubes. Every token uses the base64url alphabet, without padding, in this
index order:

```text
ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_
```

The two most significant bits of the first character identify the token class.
The remaining bits belong to that class's payload.

| First sextet | Values | Characters | Token class   |
| ------------ | -----: | ---------- | ------------- |
| `00xxxx`     |   0–15 | `A`–`P`    | state         |
| `01xxxx`     |  16–31 | `Q`–`f`    | move sequence |
| `10xxxx`     |  32–47 | `g`–`v`    | move SLP      |
| `11xxxx`     |  48–63 | `w`–`_`    | reserved      |

Decoders reject the reserved class. Assigning it a meaning requires a later
version of this specification; existing class meanings never change.

## Canonical unsigned integers

Fixed-width integers are ordinary big-endian base64url, left-padded with `A`.
A field whose range contains only one value has width zero.

## State

A state contains the coordinates in `Orbit.layout(n)` order. Each coordinate
has range `Orbit.radix(orbit)`. They are combined by mixed-radix Horner ranking,
exactly as before the token family gained move formats.

The width is the smallest positive `w` for which every state fits while the
first sextet remains in class `00`:

```text
stateCount(n) <= 16 * 64^(w - 1)
```

This keeps existing state tokens unchanged whenever their first two bits were
already zero. It deliberately makes a 7x7x7 state 90 characters rather than
89: the family tag is part of the format, not an out-of-band guess. Token
length continues to identify `n`, and the decoder still rejects values at or
above `stateCount(n)`.

## Move vocabulary

A primitive move is a face, a layer depth, and a turn amount:

```text
faces    U R F D L B
depths   0 .. floor(n / 2) - 1
amounts  clockwise, half, counter-clockwise
```

Two cubes have the same primitive vocabulary whenever they have the same
reachable layer count `l = floor(n / 2)`. A move token therefore identifies
the layer class `{2l, 2l + 1}`, not one exact cube size. The alphabet has
`A = 18l` moves, and a move's rank is:

```text
((faceRank * floor(n / 2)) + depth) * 3 + amountRank
```

`Move.faultOf` validates every move before any sequence or grammar is ranked.
Whole-cube rotations, slice names, wide-move aliases, commutator syntax, and
canonicalization are not token features. A notation layer may expand them to
primitive moves before encoding.

After the two class bits, `l` is written as an Elias gamma code. Gamma coding
is unbounded, gives the common class `l = 1` the single bit `1`, and preserves
the size information the move vocabulary actually needs.

The remainder of either move token is a minimal binary rank followed by one
reserved marker bit set to `1`, then enough zero fill to reach a base64url
sextet boundary:

```text
class | gamma(l) | minimal rank bits | 1 | 000...
```

The rank zero has no bits. Decoders remove trailing zero fill and the marker,
and reject any token whose rank has redundant leading zeroes or whose total
width is not minimal. The marker records the exact binary boundary without a
length field.

## Move sequence

For `k` moves, first compute their ordinary Horner rank `r` in base `A`. The
wire rank skips every shorter sequence:

```text
sequenceRank = (1 + A + ... + A^(k - 1)) + r
```

The empty sequence has rank zero. These ranges partition every non-negative
integer, so decoding recovers `k` with the exact-integer equivalent of
`floor(log_A((A - 1) * sequenceRank + 1))`. No move count is stored.

Tokens describe literal primitive sequences. Equality means the same expanded
sequence, not the same resulting cube transformation.

## Move SLP

A straight-line program is a topologically ordered list of rules whose last
rule is the root. An empty rule list denotes the empty sequence. Rule `i` is
one of:

```text
Terminal(move)
Concat(left, right), where left < i and right < i
```

Rule `i` has radix `A + i^2` and rank:

```text
Terminal(move)       = moveRank
Concat(left, right)  = moveAlphabetSize(n) + left * i + right
```

The rule ranks are combined by mixed-radix Horner ranking. If `G(r)` is the
number of structurally valid `r`-rule grammars, the wire rank skips every
shorter grammar:

```text
G(0) = 1
G(r) = product(i = 0 .. r - 1, A + i^2)
slpRank = (G(0) + ... + G(r - 1)) + grammarRank
```

These ranges also partition every non-negative integer, so no rule count is
stored. Decoding recovers the range, validates every reference, and never
expands the root. Grammar-token equality is structural equality; different
SLPs may expand to the same moves.

## Public API

State operations live under `Orbit64.State`; the package root is the format
family, not an alias for one member:

```text
Orbit64.State.encode / decode
Orbit64.Move.encode / decode        (decode returns a layer class)
Orbit64.Move.Slp.encode / decode    (decode returns a layer class)
Orbit64.Token.decode
```

`Orbit64.Token.decode` dispatches on the first two bits and returns a tagged
value carrying `n` and the decoded state, move sequence, or SLP.
