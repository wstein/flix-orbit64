# Orbit64 algorithm DAG proposal

Status: design proposal. None of the source language or DAG described here is
implemented in Orbit64 0.6.0. The released `Orbit64.Move.Slp` API supports only
`Terminal` and binary `Concat` rules; [FORMAT.md](FORMAT.md) remains the
normative description of released tokens.

This proposal defines an Orbit64 representation for finite algorithms that are
too large to expand into literal move sequences. Its motivating test case is
Bruce Norskog's Hamiltonian circuit for the quarter-turn Cayley graph of the
3x3x3 cube, commonly called a devil's algorithm. The construction visits all
43,252,003,274,489,856,000 positions and returns to its start. Norskog describes
the subgroup construction on his
[explanation page](https://bruce.cubing.net/ham333/rubikhamiltonexplanation.html)
and publishes the exact sequence in a
[specification archive](https://bruce.cubing.net/rubikhamilton.zip).

The representation has two layers:

1. A source language for WCA moves, familiar algorithm operators, named
   definitions, and stable slices.
2. A finite, typed DAG that preserves sharing and can stream the expanded moves
   without constructing the complete sequence in memory.

The DAG represents an exact sequence. Equality of final cube transformations
is not enough: every intermediate position is significant in a Hamiltonian
circuit.

## Design requirements

The format must:

- accept WCA face moves, outer block moves, and rotations;
- support grouping, repetition, inverse, conjugate, and commutator notation;
- share named definitions without copying their expansions;
- preserve stable element boundaries for indexed slices;
- represent large symbol streams as packed blocks rather than one node per
  symbol;
- stream expanded primitive moves with bounded memory;
- distinguish exact sequences from effect-only verification shortcuts;
- reject cyclic definitions and every operation that would create an infinite
  expansion; and
- leave the existing state, literal-move, and SLP token classes decodable.

The first implementation targets finite `n x n x n` algorithms. The node model
does not assume that all future puzzle families use the same move vocabulary.

## Source language

### Grammar

```ebnf
program       := NEWLINE* statement (NEWLINE+ statement)* NEWLINE* EOF
statement     := definition | export
definition    := "def" NAME "=" expression
export        := "export" NAME

expression    := concatenation ("\\" move)?
concatenation := postfix+
postfix       := primary "'"*

primary       := move
               | reference
               | "(" expression ")" INTEGER?
               | "[" expression ":" expression "]" INTEGER?
               | "[" expression "," expression "]" INTEGER?

reference     := NAME ("[" sliceRange "]")?
sliceRange    := INTEGER
               | INTEGER? ":" INTEGER?
```

Newlines terminate top-level statements but are permitted inside parentheses
and brackets. Whitespace separates adjacent names and moves but is otherwise
insignificant. `#` or `;` introduces a comment through the end of the line.
Definitions may reference only earlier definitions. Exactly one exported name
selects the root. Requiring an explicit export avoids making file order part of
the program's meaning.

Move tokens and language keywords are reserved and cannot be definition names.
In particular, lower-case `x`, `y`, and `z` always mean WCA rotations. An
importer must rename a legacy definition that uses one of those names rather
than making parsing depend on the current symbol table.

Repetition uses cubing notation and is accepted only immediately after `)` or
`]`; this prevents `R33` or `name33` from acquiring surprising meanings. Write
`(name)33` to repeat a named definition. Repetition counts are positive integers
of arbitrary encoded size. Zero and negative repetitions are invalid.

### Move tokens

The lexer recognizes a complete move before considering a following repetition
operator. Consequently:

```text
R2       one half turn
(R)2     two quarter turns
Rw2      one outer-block half turn
(Rw)2    two outer-block quarter turns
(R B)33  thirty-three repetitions of R B
```

The WCA terminal profile contains:

```text
face moves         U D L R F B, with optional 2 or '
outer block moves  Rw or nRw, and corresponding U D L F B forms
rotations          x y z, with optional 2 or '
```

For an `N x N x N` cube, an explicit outer-block depth `n` must satisfy
`1 < n < N`; omitting it means two layers. `Rw` and `2Rw` therefore denote the
same physical move. This follows Article 12 of the
[WCA Regulations](https://www.worldcubeassociation.org/regulations/).

`M`, `E`, and `S` are conventional slice aliases rather than WCA `N x N x N`
terminals. A later notation profile may accept them and lower them to the
puzzle's primitive layer turns. Lower-case wide-move aliases are likewise not
part of the canonical source language.

### Operators

The following expansions define source semantics:

| Source operation | Meaning |
| ---------------- | ------- |
| `a b` | concatenate `a`, then `b` |
| `(a)33` | repeat `a` 33 times |
| `a'` | reverse `a` and invert each terminal |
| `[a: b]` | `a b a'` |
| `[a, b]` | `a b a' b'` |
| `a \ R` | remove a final expanded `R`, after validating it |
| `x[i:j]` | elements `i` through `j - 1` of block `x` |
| `x[i:]` | elements of `x` from `i` onward |
| `x[:j]` | the first `j` elements of `x` |
| `x[i]` | the single element at index `i` |

Conjugation follows the blindsolving convention used by `[L: U]`; a commutator
such as `[D, B]` expands to `D B D' B'`. Operators may be nested and inverted:

```text
(R B)33
[L: U]
[D, B]
[L: [D, B]]'
([R, U] [F: D])6
```

The chop operator is an Orbit64 construction aid, not established cube
notation. It examines expanded terminals, so `a \ R` is valid only when the
last move produced by `a` is exactly `R`. It must not remove an entire macro
element merely because that element ends in `R`.

### Stable slices

Slices use zero-based, half-open ranges and count a definition's immediate
elements, not its fully expanded moves. For example, if `p` expands to ten
moves, it still occupies one element in this block:

```text
def stream = U p R
```

Thus `stream[1]` is `p`, while a hypothetical move-level slice would count inside
`p`. Orbit64 does not spell both operations with the same syntax. If move-level
slicing is added, it should be explicit, for example `moves(stream)[i:j]`.

Stable element boundaries are required by Norskog's published notation. Its
`t(134,201)` selects source symbols 134 through 200; some selected symbols name
multi-move definitions. The compatibility importer accepts these legacy forms:

```text
x(i)       -> bruce_x[i:]
x(i,j)     -> bruce_x[i:j]
```

Here the importer has renamed Bruce's `x` definition because `x` is a reserved
rotation in native Orbit64 source. Legacy call syntax is not emitted as
canonical Orbit64 source.

## Typed DAG

Parsing and name resolution produce a topologically ordered DAG. A node may
refer only to earlier nodes.

```text
Move(move)
Block(children)
PackedBlock(alphabet, symbols)
SliceParts(block, start, end)
Concat(children)
Repeat(child, count)
Inverse(child)
```

### Move

`Move` is one atomic move in the declared notation profile. WCA outer block
moves and rotations remain atomic: expanding `Rw` into separately observable
layer turns would introduce intermediate positions that are absent from the
source algorithm. Evaluation applies the simultaneous permutation associated
with the terminal and its puzzle profile.

The released `Orbit64.Move.Move` type represents one individual layer turn and
is consequently not the terminal type of this richer DAG. Converting a DAG to
the released literal-move format requires an explicit lowering policy and does
not preserve WCA terminal identity.

### Block

`Block` is an ordered vector of node references with stable element boundaries.
Its segmentation is observable through `SliceParts`, so a canonicalizer may not
flatten or rebalance it. `Concat` has identical expanded sequence semantics but
does not promise observable child boundaries.

### PackedBlock

`PackedBlock` represents a large `Block` using a local alphabet of node
references and a packed stream of alphabet indices. It is semantically a
`Block`, including stable element boundaries. Chunk indexes permit slicing and
streaming without decoding the complete block.

An implementation should store for each chunk:

- the number of block elements;
- the number of expanded atomic terminals;
- compressed symbol bytes; and
- a digest of its canonical uncompressed symbol stream.

Compression is a transport detail and does not affect DAG equality.

### SliceParts

`SliceParts(block, start, end)` requires `0 <= start <= end <= partCount(block)`.
It preserves the selected child boundaries. Slicing an inverse block operates
on the already reversed element view, matching Norskog's `X`, `T`, and `Q`
notation for inverse sequences.

### Inverse

`Inverse` reverses element order and recursively inverts every move. It should
remain lazy. Useful normalization identities include:

```text
Inverse(Inverse(a)) = a
Inverse(Concat(a, b)) = Concat(Inverse(b), Inverse(a))
Inverse(Repeat(a, n)) = Repeat(Inverse(a), n)
```

Normalization must preserve `Block` boundaries wherever a slice can observe
them.

### Source lowering

| Source operation | DAG lowering |
| ---------------- | ------------ |
| `a b` | `Concat([a, b])` |
| `(a)n` | `Repeat(a, n)` |
| `a'` | `Inverse(a)` |
| `[a: b]` | `Concat([a, b, Inverse(a)])` |
| `[a, b]` | `Concat([a, b, Inverse(a), Inverse(b)])` |
| `a \ R` | validated terminal-level truncation |
| `x[i:j]` | `SliceParts(x, i, j)` |

Conjugates, commutators, and chop need no permanent wire opcode. The compiler
lowers them into the smaller core after validation.

## Devil's-algorithm case study

Norskog's archive is the acceptance fixture for this design. It contains large
definitions `x` and `q`, a smaller definition `t`, several definitions in
`misc.txt`, and a roughly 38 KB top-level composition. The archive's source
language uses:

- the quarter turns `U`, `D`, `L`, `R`, and `F`, but no `B`;
- `V`, `E`, `M`, `S`, and `G` as aliases for their inverses;
- lower-case names for definitions and upper-case names for inverse views; and
- indexed portions such as `x(0, 850394)` and `Q(70433)`.

An importer should translate aliases and inverse views into ordinary Orbit64
nodes, preserve the archive's symbol-level indices, and produce one exported
root. A successful implementation must be able to stream its expanded moves
without retaining either the expanded circuit or all visited cube states.

The archive also contains `q_shortcut.txt`. Its lower-case `u` stands for a
large sequence with the same final effect as `U`, allowing faster endpoint and
index checks. It does not preserve the intervening positions and therefore
must not inhabit the exact-sequence DAG. Effect summaries belong in validation
metadata:

```text
ExactSequence(root)
EffectSummary(root, resultingTransformation)
```

An effect summary can help verify a node but cannot replace it during exact
expansion.

The explanation's `weave` and assembly steps describe how the large streams
were found. They are not required to replay the published specification. If
Orbit64 later preserves construction provenance, it may add typed splice plans
and coverage certificates above the exact DAG; decoders must not require those
proof objects merely to stream moves.

## Validation

Validation proceeds without fully expanding the root.

### Structural validation

- every reference points backward to an existing node;
- exactly one root is exported;
- repetitions are positive;
- slice bounds are ordered and within the referenced block;
- packed symbols belong to their declared alphabet; and
- decoded integers and encodings are canonical.

### Cached metadata

Each node computes or stores checked metadata:

```text
part count
expanded atomic-terminal count
first expanded move
last expanded move
resulting cube transformation, when available
canonical digest
```

Counts require arbitrary-precision integers. First and last moves make chop
validation constant-time after metadata calculation. Digests permit streaming
verification of large packed blocks.

### Exactness and Hamiltonicity

Structural validity proves that a finite move sequence can be streamed. It does
not prove that the sequence is Hamiltonian. Such a claim requires separate
coverage certificates or an exhaustive verifier appropriate to the
construction. Orbit64 must describe a token as a devil's algorithm only after
that stronger verification; equal endpoints alone are insufficient.

## Wire-format evolution

The released `10` class is a complete enumerative code for `Terminal`/`Concat`
SLPs. Every non-negative grammar rank is already meaningful, so it has no
unused escape rank in which to add DAG opcodes compatibly.

The expanded DAG must therefore use the reserved `11` extension class if old
SLP tokens remain decodable. The proposed extension envelope is:

```text
11iiii | extension payload
```

The low four bits `iiii` select extension IDs 0 through 14. ID 15 introduces a
following extended ID and is never assigned directly. The first proposed ID is:

```text
0  algorithm DAG
```

The algorithm-DAG payload contains, in order:

```text
schema version
puzzle and notation profile
move alphabet
topologically ordered node table
packed-block chunk table
root node reference
delimiter bit and zero fill
```

This assignment is provisional until an implementation and canonical test
vectors land. State (`00`), literal move (`01`), and released SLP (`10`) tokens
remain byte-for-byte unchanged.

Node references should use backward distances, making nearby references cheap.
Counts, slice bounds, arities, and uncommon backward distances use canonical
unsigned bit-varints. Node opcodes reserve an escape opcode for later node
families. A canonical encoding must specify chunk boundaries and compression;
otherwise one DAG could acquire many byte representations.

## Implementation phases

1. Implement the parser, formatter, name resolution, and ordinary algebra
   operators with unit and round-trip tests.
2. Implement the typed in-memory DAG, metadata calculation, lazy expansion,
   and structural validation.
3. Add stable blocks, packed blocks, slices, and a Norskog compatibility
   importer tested against small extracted fixtures.
4. Specify the extension-class binary layout with canonical vectors, then add
   encoding, decoding, corruption tests, and streaming tests.
5. Import the complete published archive and independently verify its root
   digest, expanded length, final transformation, and available construction
   claims.

No phase should describe the algorithm-DAG token as supported until its public
API, canonical wire vectors, and decoder limits are all implemented.
