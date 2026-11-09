# Cube algorithm DAG envelope, version 1

Status: review draft for [the V2 migration](https://github.com/wstein/flix-orbit64/issues/22).
This is an additive reference contract, not a released replacement API yet.
Its format identifier is `cube-algorithm-dag@1`. It is separate from Orbit64 V2,
which encodes states, and from V1's existing class-`10` algorithm token. Existing
V1 tokens retain their meaning and remain supported during consumer migration.

## Meaning and scope

The envelope preserves the complete implemented `Orbit64.Algorithm` value:
node order, repeated references, unused nodes, exported root, every stable part
boundary and packed symbol. It also records the exact cube size `n`. Two sizes
with the same primitive move alphabet are still different envelopes.

The primitive profile is `cube-layer-turns@1`: a terminal is the existing
`Orbit64.Move.LayerTurn(face, depth, amount)`. Faces are `U R F D L B`, depth is
zero-based from that face and satisfies `0 <= depth < n / 2`, and amount is
1 (clockwise quarter), 2 (half), or 3 (counterclockwise quarter). Size is any
Int32 `n >= 2`, not the V2 state registry's 2..15 range. There is no middle-depth
primitive, wide-turn alias or whole-cube terminal. Source notation can lower
these constructs into this profile; this contract does not preserve an earlier
WCA source token's atomic identity after lowering.

The graph denotes an exact finite terminal sequence. Equal end states or equal
expanded counts do not make different sequences interchangeable. Canonical
serialization below means canonical spelling of this particular typed graph,
not graph isomorphism, effect normalization, dead-node elimination or pattern
canonicalization. No nodes or alphabet entries are merged or discarded.

## Canonical wire representation

A document is one ASCII JSON object, with exactly these keys in this order:

```json
{"format":"cube-algorithm-dag@1","moveProfile":"cube-layer-turns@1","n":3,"nodes":[["terminal","U",0,1]],"root":0}
```

There is no BOM, whitespace, indentation or trailing newline. Object keys are
sorted by ASCII order. Labels are spelled literally without JSON escapes.
Every JSON number is a nonnegative Int32 in ordinary decimal notation, with
no leading zero except the number 0. Fractions, exponents, signs and escaped
labels are not canonical. A repeat count is a positive arbitrary-precision
integer written as a JSON **string** of ASCII decimal digits, without signs,
leading zeros, escapes or precision loss. No other field has BigInt type in
the existing AST: node references, partition boundaries and slice offsets are
Int32 values, not repeat counts.

All JSON arrays retain their order. Each node is an array with the exact tag,
arity and fields below. References are absolute zero-based node indexes and
must point to an earlier node. `root` names any existing node, including one
before other unused nodes. The envelope has no optional fields or extensions;
a future incompatible schema needs a different format identifier.

| Node | JSON array | Meaning |
| --- | --- | --- |
| Terminal | `["terminal",face,depth,amount]` | One primitive terminal |
| Concat | `["concat",children]` | Concatenate referenced sequences |
| Repeat | `["repeat",child,"count"]` | Repeat the sequence a positive BigInt number of times |
| Inverse | `["inverse",child]` | Reverse the sequence and invert each terminal |
| Block | `["block",children]` | Concatenate children, retaining one stable part per child |
| PackedBlock | `["packedBlock",alphabet,symbols]` | Alphabet entries are node references; symbols are zero-based alphabet indexes, one stable part per symbol |
| Partition | `["partition",sequence,boundaries]` | Group stable source parts by adjacent boundary pairs |
| SliceParts | `["sliceParts",sequence,start,end]` | Select stable source parts in the half-open interval |

`children`, `alphabet`, `symbols` and `boundaries` are arrays of JSON Int32
numbers. Empty Concat, Block and PackedBlock values retain the existing AST's
meaning. Packed alphabets may contain repeated and unused references. Inverse
retains stable parts in reverse order. Concat and Repeat do not gain stable
boundaries, even for a single child or count 1.

Partition requires a stable source, a nonempty boundary array beginning at 0
and ending at the source part count. Boundaries are nondecreasing: equal
neighbors create empty parts and must survive round trip. An empty source may
have `[0]` or `[0,0]`. SliceParts requires a stable source and
`0 <= start <= end <= source part count`; empty slices are valid. These are
existing `Orbit64.Algorithm.faultOf` semantics, not new restrictions.

## Reference API and failure boundaries

`Orbit64.Algorithm.Envelope` provides pure `encode(n, graph)` and `decode(text)`
and explicit-policy `encodeWith(limits, n, graph)` / `decodeWith(limits, text)`.
Decoding returns `(n, graph)`. `defaultLimits()` supplies conservative local
ceilings. Callers may lower each positive limit; zero, negative or values above
these reference ceilings return `InvalidLimits`. These implementation ceilings
are not limits of the abstract graph or the V2 state registry. Metadata list
builders use tail accumulators; the acceptance suite retains positive 65536-item
list cases. Larger documents receive ResourceLimit, not silent rewriting.

| Limit | Default ceiling | Work counted |
| --- | ---: | --- |
| maxInputChars | 1048576 | Input/output String code units; accepted documents are ASCII, so these equal UTF-8 bytes |
| maxNodes | 4096 | Every stored node, including unused nodes |
| maxReferences | 65536 | All stored child/alphabet references, with repetition |
| maxSymbols | 65536 | Packed symbol indexes plus partition boundary indexes |
| maxCountDigits | 4096 | Sum of decimal repeat-count digits over all stored Repeat nodes |
| maxDepth | 256 | Longest stored reference path, counting a terminal as depth 1 |
| maxJsonDepth | 8 | Enclosing JSON arrays/objects, ignoring brackets in quoted strings |
| maxMetadataWork | 1048576 | Conservative metadata lookup, part production and scanning work described below |

The input length, ASCII policy, quote/escape-aware JSON nesting and numeric
lexemes are checked **before** calling the recursive JSON parser. Numeric
lexemes cannot exceed 10 digits or use exponent/fraction notation. Non-ASCII
input (including raw surrogates) is rejected; escaped spellings cannot bypass
canonical comparison. The parser rejects duplicate keys, malformed JSON and
trailing content. Exact node shape/type checks precede semantic validation.
Unknown object keys, key reordering and any alternative JSON spelling are
rejected by re-encoding the validated value and comparing the complete string.
The decoder is intentionally canonical-only, not a general permissive JSON
importer.

Before `faultOf` computes metadata, the resource pass bounds every stored
reference and sequence-index list and the aggregate repeat-digit count. It
accounts for reference lookup distances, produced stable parts, Inverse part
copies, PackedBlock symbol/alphabet lookup work, each Partition interval's
full source-part scan, and SliceParts' source-part scan. This also bounds
retained metadata part lists; unused nodes are not exempt. A small encoded DAG
can otherwise allocate or scan far more metadata than its byte length suggests.
No expanded move stream is constructed or counted by iteration. Aggregate
repeat digits and bounded graph depth/references bound symbolic BigInt work
before multiplication. The local policy may reject an otherwise valid graph.

Failures distinguish `InvalidLimits`, `ResourceLimit`, `Malformed`,
`InvalidGraph`, and `NonCanonical`. Resource preflight may reject an invalid
input before its semantic fault is examined; no partial graph is returned.
The reference codec never follows files, URLs, external assets or imports.
Resource limits for later terminal streaming are the caller's separate concern:
a valid huge Repeat must not be expanded merely because decoding succeeded.

## Acceptance examples

The one-terminal document above is an exact byte vector in
[test/TestAlgorithmEnvelope.flix](test/TestAlgorithmEnvelope.flix).
A second independent byte vector fixes the valid empty sequence at size 16,
outside the V2 state registry:

```json
{"format":"cube-algorithm-dag@1","moveProfile":"cube-layer-turns@1","n":16,"nodes":[["concat",[]]],"root":0}
```

The same suite retains all eight node kinds, a shared child, an unused huge
Repeat, earlier exported roots, duplicated packed alphabets, empty parts,
non-unit Partition boundaries, slices and inverse sequence order. A Repeat of
`1000000000000000000000000000000` remains symbolic; its digits are never routed
through a floating-point value. Small examples compare the full terminal list,
not only its length or end pose.

Negative examples cover invalid references/moves, wrong versions/profile,
duplicate and unknown fields, alternative numeric/escape spellings, malformed
counts and symbols, each resource limit, deep unknown JSON, aggregated count
digits, repeated metadata copies and repeated Partition scans. These are
software acceptance tests, not new mathematical proof claims.

## Compatibility and cutover

1. Qualify this additive reference and its exact byte/structure examples.
2. Prepare independent consumer implementations against the exact reference
   source and preserve their existing app capabilities and license boundaries.
3. The owner publishes an actual qualified package release before consumers
   pin its version. This draft does not authorize a tag, release or publication.
4. Move state interchange to explicitly typed/labeled Orbit64 V2, and algorithm
   interchange to this separately versioned contract. Do not reinterpret old
   class bits or guess format from leading characters or token length.
5. Retire V1 runtime readers/writers only after all consumers have switched.
   Any approved offline legacy converter stays isolated from normal runtime
   imports. Historical fixtures and source provenance are not rewritten.

The native `.alg` tool remains useful for its implemented source subset, but
its current Reconstruction does not retain arbitrary Partition boundaries and
renders packed symbols as source references. Its token-based RoundTrip still
uses the V1 wire codec. It is not a lossless substitute for this envelope.
This phase changes neither that tool nor V1 state/move/token APIs, frozen V2
registry/slot/frame conventions, generated reference fixtures, solver models,
pattern canonicalization, or any downstream application's dependencies.
