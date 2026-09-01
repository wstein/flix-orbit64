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

Headers use a base64 VLQ. Each sextet contributes five payload bits. Values
`32` through `63` mean that another sextet follows; values `0` through `31`
end the integer. Payload groups are least-significant first. The last group
must be non-zero unless it is the only group, so every integer has one spelling.

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

The alphabet therefore has `18 * floor(n / 2)` moves. Its rank is:

```text
((faceRank * floor(n / 2)) + depth) * 3 + amountRank
```

`Move.faultOf` validates every move before any sequence or grammar is ranked.
Whole-cube rotations, slice names, wide-move aliases, commutator syntax, and
canonicalization are not token features. A notation layer may expand them to
primitive moves before encoding.

Both move classes encode `n` in the low four bits of the first sextet. Values
`0` through `14` mean `n = value + 2`. Value `15` is an escape and is followed
by a canonical VLQ containing `n - 17`. Thus the format has no size cliff.

## Move sequence

After the size header, a canonical VLQ gives the number `k` of moves. The moves
are Horner-ranked in base `18 * floor(n / 2)` and written at the exact width
needed for all sequences of length `k`. The count makes the token
self-terminating and preserves leading moves whose rank is zero.

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

After the size header, a canonical VLQ gives the rule count `r`. Rule `i` has
radix `moveAlphabetSize(n) + i^2` and rank:

```text
Terminal(move)       = moveRank
Concat(left, right)  = moveAlphabetSize(n) + left * i + right
```

The rule ranks are combined by mixed-radix Horner ranking and written at the
exact width needed for every grammar with `r` rules. Decoding validates every
reference without expanding the generated sequence. Grammar-token equality is
structural equality; different SLPs may expand to the same moves.

## Public API

State operations live under `Orbit64.State`; the package root is the format
family, not an alias for one member:

```text
Orbit64.State.encode / decode
Orbit64.Move.encode / decode
Orbit64.Move.Slp.encode / decode
Orbit64.Token.decode
```

`Orbit64.Token.decode` dispatches on the first two bits and returns a tagged
value carrying `n` and the decoded state, move sequence, or SLP.
