# Orbit64 algorithm DAG proposal

Status: the typed, validated `Orbit64.Algorithm` core is implemented on the
development branch. It represents primitive layer-turn terminals plus exact
`Concat`, `Repeat`, `Inverse`, `Block`, `PackedBlock`, `Partition`, and
`SliceParts` nodes. `foldTerminals` streams the exact expansion through a
caller-supplied fold without materializing it. Canonical class-`11` token
encoding and the source-language tool remain proposed work. The released
`Orbit64.Move.Slp` API supports only `Terminal` and binary `Concat` rules;
[FORMAT.md](FORMAT.md) remains the normative description of released tokens.

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

## Package boundary

The distributable library owns the notation-independent pieces:

```text
Orbit64.Algorithm             public DAG types, validation, and metadata
Orbit64.Algorithm.Encoding    canonical token encoding and decoding
Orbit64.Algorithm.Stream      bounded-memory terminal expansion
```

The parser, formatter, source diagnostics, and legacy importers belong to a
separate `examples/algorithm-tool` package. That package depends on Orbit64 and
lowers source expressions into the public DAG. Applications may instead build
the DAG directly or supply another notation frontend.

This boundary means that "algorithm notation support" describes the example
tool, while "algorithm DAG support" describes the library. The first shipped
steps test IR validity, exact non-expanding terminal/part counts, and
fold-based streaming. The wire format and example parser follow this contract.

## Source language

### Grammar

```ebnf
program       := NEWLINE* statement (NEWLINE+ statement)* NEWLINE* EOF
statement     := definition | externalBlock | export
definition    := "def" NAME "=" expression
externalBlock := "extern" "block" NAME "=" STRING
export        := "export" NAME

expression    := concatenation
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

An external block declares a source-bundle input. Its string is a logical asset
name resolved by the example tool's source lock, never a filesystem path or URL
interpreted by the library. Resolution supplies a verified `PackedBlock` before
ordinary name resolution begins.

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
Partition(sequence, boundaries)
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

The alphabet contains earlier DAG nodes, not merely terminal moves. This lets an
importer factor repeated phrases and alternating runs into `Concat` and
`Repeat` nodes, then encode millions of occurrences as compact alphabet IDs.
`PackedBlock` is therefore the result of definition optimization, not a wrapper
around an unexamined input file.

An implementation should store for each chunk:

- the number of block elements;
- the number of expanded atomic terminals;
- compressed symbol bytes; and
- a digest of its canonical uncompressed symbol stream.

Compression is a transport detail and does not affect DAG equality.

### Partition

`Partition(sequence, boundaries)` gives an optimized sequence a stable logical
part view. Boundaries are monotonically increasing offsets into the sequence's
immediate elements, start at zero, and end at its element count. Adjacent
boundaries delimit one logical part.

This separates two concerns that do not coincide in Norskog's `q` definition:
the best physical compression divides the exact stream at recurring bridge
phrases, while published slice indices count the elements of `q_shortcut`.
`Partition` retains those published indices without forcing the exact stream
back into its much larger textual segmentation.

### SliceParts

`SliceParts(block, start, end)` requires `0 <= start <= end <= partCount(block)`.
It accepts `Block`, `PackedBlock`, or `Partition` inputs and preserves the
selected logical boundaries. Slicing an inverse block operates on the already
reversed element view, matching Norskog's `X`, `T`, and `Q` notation for inverse
sequences.

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
| `x[i:j]` | `SliceParts(x, i, j)` |

Conjugates and commutators need no permanent wire opcode. The compiler lowers
them into the smaller core after validation.

There is no general chop operator. A known path is written directly; for
example, removing the final `R` from `(U R)105` gives `(U R)104 U`. Opening a
generated cycle is instead a typed construction operation that identifies and
validates the cut edge.

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

### Definition optimization

The corrected archive should be normalized by removing its definition prefix,
line endings, and formatting whitespace before optimizing it. Its line breaks
are presentation details except in `q_shortcut.txt`; they are not algorithm
elements.

Measurements of the normalized corrected archive give:

| Definition | Symbols | Physical segmentation | Segments | Distinct templates |
| ---------- | ------: | --------------------- | -------: | -----------------: |
| `x` | 73,483,059 | start a segment at every `V` | 699,714 | 59 |
| exact `q` | 156,764,385 | end a segment after every `xUwaER` | 2,177,084 | 795 |
| shortcut `q` | 70,641 | one published shortcut symbol per part | 70,641 | not applicable |

The `x` alphabet is only `U`, `R`, and `V`, where `V = U'`. It contains 699,713
`V` symbols. Human-readable generated source begins:

```text
def x = (
  (U R)2
  V R (U R)40
  V R (U R)104
  V R (U R)20
  V R (U R)104
  V R (U R)6
  # ...
)
```

After the short prefix, nearly every segment has the form:

```text
V R (U R)n
```

Only 58 segment strings occur after the prefix, with a maximum length of 210
symbols. Fifty-six have the regular form above. The corrected stream has two
named exceptions:

```text
def xBridge = V R (U R)35 U U (U R)36  # 62 occurrences
def xClose  = V R (U R)35 U             # final segment
```

The importer emits the readable repetition form first. DAG construction interns
identical `Repeat` and `Concat` nodes, then represents the segment sequence as a
`PackedBlock` over those 58 shared templates. Fixed-width template IDs require
six bits each, about 525 KB before the small dictionary and framing; the observed
template distribution has a theoretical entropy near 316 KB.

The exact `q` stream contains `xUwaER` 2,177,083 times. Cutting immediately
after that phrase produces 2,177,084 segments, but only 795 distinct strings;
the longest is 156 macro symbols. Those dictionary entries are themselves
factored into alternating `UR` repetitions, `D` interruptions, and the shared
bridge node:

```text
def bridge = bruce_x U w a E R
```

Ten-bit fixed-width dictionary IDs require about 2.72 MB before dictionary and
framing. The observed distribution's theoretical entropy is about 1.24 MB. A
canonical entropy code may approach the latter, but dictionary factoring is
required even if the first wire version uses fixed-width IDs.

`q_shortcut.txt` is already Norskog's optimized logical definition. It contains
70,641 parts, including 12,879 `u` placeholders. Each `u` summarizes a different
exact subpath whose final transformation is `U`; it is not an exact move. The
importer aligns those shortcut parts with ranges of the optimized exact `q`
stream and emits:

```text
Partition(exactQ, shortcutBoundaries)
```

Effect metadata records the shortcut symbols separately. This preserves the
published `q(i,j)` indexing, permits fast endpoint verification, and never
substitutes `u` for its intervening Hamiltonian path.

The top-level definition is already small, but two bridge phrases occur often
enough to name before parsing it:

```text
def joinForward = F j t k G K T Y F K T J G  # 400 occurrences
def joinReverse = F j t k G y t k F K T J G  # 240 occurrences
```

These optimizations are exact textual factorizations. They make no group-theory
assumption and can be verified by streaming the original and optimized macro
symbols side by side.

### Beyond dictionary factoring

Dictionary factoring is a baseline, not the intended final representation. A
compression probe over the template-ID streams shows substantial higher-order
structure:

| Stream | Uncompressed IDs | Deflate | bzip2 | LZMA |
| ------ | ---------------: | ------: | ----: | ---: |
| `x`, one byte per template | 699,714 B | 191,077 B | 64,479 B | 51,784 B |
| exact `q`, two bytes per template | 4,354,168 B | 1,226,675 B | 701,635 B | 608,872 B |

These compressor sizes are diagnostics, not proposed wire encodings. Their
large improvement over independent template IDs demonstrates correlations and
repeated subsequences that a deeper construction can expose.

The desired endpoint resembles a compact fractal definition: a small rule and
finite parameters generate an output vastly larger than the definition. For
this circuit, the rule is the published subgroup hierarchy:

```text
<UR>
  -> <U,R>
  -> <U,R,D>
  -> <U,R,D,L>
  -> <U,R,D,L,F>
```

The first seed is exactly `(U R)105`. Higher levels lift a path or cycle into
cosets and join the resulting cycles. The 3x3x3 construction uses 349,920
`<UR>` cycles at the next level, an initial 63-coset cycle at the `<U,R,D>`
level, 132 cosets at the `<U,R,D,L>` level, and 2,048 cosets at the final level.

The construction layer therefore needs mathematical combinators above the
exact sequence DAG. Candidate semantics are:

```text
SeedCycle(word)
OpenCycle(cycle, cutEdge)
Lift(baseTraversal, quotientEnumeration)
JoinCycles(liftedTraversal, joinPlan, localRewrite)
RepeatBridge(path, bridge, count)
JoinTriples(liftedTraversal, triplePlan, localRewrite)
```

These names are provisional until their edge-rewrite semantics have been
derived from the corrected corpus and tested by exact re-expansion. They must
not become opaque built-ins. Each node specifies:

- the finite group or quotient coordinate being enumerated;
- deterministic element and neighbor ordering;
- the exact local edge replacement;
- termination bounds;
- a compact plan or a deterministic plan generator; and
- a certificate sufficient to validate connectivity and endpoints.

There are three representation levels:

1. **Transcription:** packed exact symbols and slices.
2. **Construction:** subgroup lifts and joins with explicit plans.
3. **Regeneration:** deterministic search rules regenerate those plans from
   seeds, ordering, and tie-breaking rules.

Level 3 is the Mandelbrot-like goal. It is only sound if the search is fully
specified: queue order, generator order, state ranking, splice selection, and
all tie-breaking are part of the format. A statement such as "use BFS" is not
deterministic enough to identify one circuit.

The published archive contains the resulting exact streams and an explanatory
account of the hierarchy, but no generator source fixing all those choices has
been located. Orbit64 must therefore reverse-engineer and verify the join plans
before claiming a regenerative representation of this particular circuit. If
a plan has irreducible choices, those choices remain explicit compressed data;
the format must not pretend they follow from the recurrence.

Construction nodes elaborate to the exact DAG. Decoding returns the finite
construction without running its searches. Expansion and plan regeneration are
explicit, budgeted operations so an untrusted token cannot trigger an enormous
BFS merely by being decoded.

### Acceptance examples

The algorithm-tool example includes reproducible imports for both published
Norskog circuits:

| Puzzle | Exact source | Archive bytes | Expanded moves | Archive SHA-256 |
| ------ | ------------ | ------------: | -------------: | -------------- |
| 2x2x2 | `hamilton222.zip` | 265,642 | 3,674,160 | `b6cffd24c81315e3d7da21756822f1ee6398adcd5773cae6e0dfdc2b15d528d9` |
| 3x3x3 | `rubikhamilton.zip` | 7,096,554 | 43,252,003,274,489,856,000 | `77e70f68e39ebfb51b4fd74c1d07392782988c758e865e1baff17f021effe285` |

The archives remain at their author's site rather than being copied into this
repository. The example's source lock records the HTTPS URL, byte length, and
SHA-256; the importer refuses an archive that does not match. This is especially
important for the 3x3x3 source because Norskog identifies a corrected 2012
archive after an earlier `x.txt` omitted two moves.

The 2x2x2 archive contains one 3,674,160-symbol stream over `U`, `R`, `F` and
their inverses. A recursive transcription is substantially better than treating
that stream as an opaque packed block. The
[`2x2x2-devils-alg.orbit64`](examples/algorithm-tool/2x2x2-devils-alg.orbit64)
example translates the recursive definition used by the cubing.js
[stress test](https://experiments.cubing.net/cubing.js/stress-tests/2x2x2-devils-alg.html)
into native Orbit64 source.

The source has 1,173 immediate move or definition references, down from 2,069
in the stress-test definition, and expands to the archive's complete circuit.
The main savings expose exact repeated structure rather than applying a byte
compressor:

```text
def a = (U R)5
def i = (U R)7
def c = U' R (U R)14 U' R
def d = (U' R (U R)5)2
def t = (U R)2 n (tHead w tTail)2 tHead
def v = (u)8 a U' R r U' R s U R t w U U F'
def z = (v)6 (u)6 x
export z
```

The transcription normalizes the elementary `U R` chains directly rather than
preserving aliases from the source implementation. In particular, `i` is seven
copies of `U R`; the two copies in `c` make fourteen, not eleven or twenty-two.

In the original definition, `t` contains a 499-element body twice followed by
the first 290 elements of that body. The native source names that prefix as
`tHead`, recognizes the existing `w` definition in the middle, and names the
157-element suffix as `tTail`. It also interns the longest repeated 28-element
phrase in `x` as `xSplice`. These rewrites are lossless: expansion produces
3,674,160 moves and the normalized move stream has SHA-256
`cecea1fe7c13f145b1fb4999846df2d0c30beec21ef6a923c8c4ce905621ee6b`, exactly
matching `Hamilton222.txt`.

This is an exact recursive repacking, not a claim that the grammar is globally
minimal. Finding a smallest grammar requires a separately specified optimizer
and an optimality criterion; the wire format must not make decoder behavior
depend on that choice. The canonical DAG encoder may intern structurally equal
nodes regardless of how a source frontend discovered them.

The matching
[`2x2x2-devils-alg.repair.orbit64`](examples/algorithm-tool/2x2x2-devils-alg.repair.orbit64)
fixture demonstrates the other direction: extract the terminal stream first,
then infer the DAG from small rules to large rules. Its deterministic RePair
pass starts with `g000 = R U`, replaces the most frequent adjacent pair
left-to-right, breaks equal-frequency ties by descending terminal/rule order,
then inlines every single-use rule, every trivial `(node)n` alias, and every
`node move`, `move node`, or `move move` alias. It ends with 185 shared rules
and a 141-symbol root, and expands to the same checked digest. The last pass
improves direct readability but duplicates frequently used move pairs, raising
the immediate-reference count from 864 to 957. This generated grammar is an
optimizer acceptance fixture rather than the canonical human-facing example.
It gives a future encoder a precise baseline for bottom-up grammar induction
and a way to compare stronger recursive optimizers fairly.

### Optimizer priority

The RePair fixture is a fast baseline, not the final optimizer. Selecting the
most frequent adjacent pair is cheap, but it can miss a longer repeated block
whose replacement would save more of the complete grammar. Conversely, the
longest repeated block is not automatically best: a very long block that occurs
twice can lose to a shorter block that occurs thousands of times.

The production optimizer should search **maximal repeated blocks** and select
the candidate with the greatest net encoded gain:

```text
gain(block) = bytes removed from all selected occurrences
              - bytes for one block definition
              - bytes for its replacement references
```

Occurrences chosen for one block must not overlap. A suffix-array or
suffix-automaton pass finds maximal-repeat candidates without expanding a DAG;
a deterministic weighted interval pass selects their usable occurrences. After
each replacement the optimizer rescans affected neighborhoods, interns equal
subtrees, folds adjacent repetitions such as `(U' R')4 (U' R')2` into
`(U' R')6`, recognizes exact source operators such as `R U' R U` as
`R [U': R]`, and prunes rules according to the selected output profile.

There are two profiles with different legitimate costs:

- **Wire profile:** retain every shared node whose encoded reference is cheaper
  than repeating its body.
- **Source profile:** inline single-use rules and the trivial wrappers that add
  no explanatory value, including `(node)n`, `node move`, `move node`, and
  `move move`.

Both profiles must begin from the same exact terminal stream and produce the
same DAG digest after canonical interning. Candidate ties are part of the
format: resolve them by greatest gain, then leftmost source occurrence, then
lexicographic canonical block encoding. This gives the small-to-large search a
repeatable rhythm without pretending that one greedy pass proves a globally
smallest grammar.

### DAG-to-source extraction

The optimizer does not emit source definitions as it discovers nodes. It first
builds a compact exact DAG. A separate **DAG-to-source extractor**, owned by the
example tool, chooses which shared nodes deserve source names and which are
clearer inline. This is the pass that removes RePair's ugly fragments; it is
not manual editing and it is not part of token decoding.

Extraction is multipass:

```text
choose source names -> inline unchosen nodes -> flatten Concat
                    -> fold adjacent repeats -> recognize source operators
                    -> rescore names -> repeat while the source improves
```

For example, suppose the exact DAG contains:

```text
g005 = U R' (U' R')4
g007 = Concat(g005, Repeat(U' R', 4))
```

If `g005` is not selected as a source name, extraction substitutes its body,
flattens the concatenation, and applies the local identities:

```text
Concat(Repeat(p, m), Repeat(p, n)) = Repeat(p, m + n)
Concat(p, Repeat(p, n))            = Repeat(p, n + 1)
Concat(Repeat(p, n), p)            = Repeat(p, n + 1)
```

The resulting source is therefore:

```text
U R' (U' R')8
```

The extractor must perform this normalization after every inlining round,
because the useful adjacency may be hidden behind a source-name reference. It
may not erase a `Block` boundary that `SliceParts` can observe; it operates on
the source binding view and ordinary `Concat` nodes only. The library owns safe
DAG normalization and canonical interning, while the example tool owns the
source-name policy and presentation-oriented rewrites.

For comparison, an importer that does not recognize the recursive definition
can still emit a `PackedBlock` root in canonical Orbit64 source form:

```text
extern block H2 = "bruce-2x2"
export H2
```

`extern block` is an example-tool data binding, not a DAG node beyond the
ordinary `PackedBlock` it supplies. The source lock maps `bruce-2x2` to the
verified archive member. Keeping acquisition outside the expression grammar
makes the same canonical source usable with local files, an application asset
store, or a network-disabled build.

The 3x3x3 importer converts `misc.txt`, `t.txt`, `x.txt`, `q.txt`, and
`RubiksCubeHamilton.txt` into native definitions, packed blocks, inverse nodes,
and `SliceParts` references. Its canonical output uses ordinary syntax such as:

```text
def V = U'
def S = R'
extern block bruce_x = "bruce-3x3-x"
def Q = q'
def H3 = h t[0:39] Q[0:66887] bruce_x[0:73438647] F j
export H3
```

The abbreviated `H3` line illustrates the translation and is not substituted
for the archive's complete top-level definition. The example compiler consumes
that complete definition from the verified archive and can emit canonical
Orbit64 source or an algorithm-DAG token.

Acceptance requires more than successful parsing:

- the 2x2x2 imported root expands to exactly 3,674,160 quarter turns;
- the 3x3x3 imported root expands to exactly the cube-group order shown above;
- both roots return to their initial state;
- imported part counts make every published slice bound valid;
- re-importing produces the same canonical DAG digest; and
- optional exhaustive verification confirms the Hamiltonian property where
  computationally practical.

The complete 2x2x2 traversal is practical to verify in CI after a cached,
digest-checked download. Full 3x3x3 state enumeration is not. CI instead checks
the archive and member digests, structural invariants, slice bounds, expanded
length, endpoint summaries, and canonical DAG digest.

## Validation

Validation proceeds without fully expanding the root.

### Structural validation

- every reference points backward to an existing node;
- exactly one root is exported;
- repetitions are positive;
- slice bounds are ordered and within the referenced block;
- partition boundaries start at zero, are monotonic, and cover their sequence;
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

Counts require arbitrary-precision integers. First and last moves support path
and cut-edge validation without expansion. Digests permit streaming verification
of large packed blocks.

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

1. Normalize the corrected 2x2x2 and 3x3x3 corpora, derive exact template
   streams, and commit only small reproducible fixtures and their measurements.
2. Recover the subgroup lift and splice plans, test whether deterministic
   generators reproduce them, and specify the construction combinators before
   freezing the IR.
3. Implement the typed exact DAG, metadata calculation, lazy expansion,
   partitions, packed blocks, and structural validation.
4. Implement the example parser, formatter, name resolution, ordinary algebra
   operators, and Norskog importers with unit and round-trip tests.
5. Specify the extension-class binary layout with canonical vectors, then add
   encoding, decoding, corruption tests, and streaming tests.
6. Add the locked 2x2x2 and 3x3x3 imports to `examples/algorithm-tool`, then
   independently verify their root digests, expanded lengths, final
   transformations, and computationally feasible construction claims.

No phase should describe the algorithm-DAG token as supported until its public
API, canonical wire vectors, and decoder limits are all implemented.
