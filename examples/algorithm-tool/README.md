# Algorithm-tool design examples

This directory holds source examples for the proposed algorithm frontend in
[`ALGORITHM-DAG.md`](../../ALGORITHM-DAG.md). The parser and the richer DAG are
not implemented in Orbit64 0.6.0, so these files are reference and acceptance
fixtures rather than runnable examples today.

`2x2x2-devils-alg.orbit64` is a lossless recursive transcription of Bruce
Norskog's 2x2x2 devil's algorithm. It was derived from the recursive
[cubing.js stress-test definition][stress] and checked against
`Hamilton222.txt` from Norskog's [published archive][archive]. Expanding `z`
produces 3,674,160 moves; after mapping `U'`, `R'`, and `F'` to the archive's
`V`, `S`, and `G`, the byte stream is identical.

`2x2x2-devils-alg.repair.orbit64` takes the opposite route: it starts with the
archive's extracted terminal stream and infers a DAG bottom-up with a fully
specified RePair pass. It creates `g000 = R U`, repeatedly replaces the most
frequent adjacent pair from left to right, and uses descending terminal/rule
order to break ties. It then inlines every single-use rule, every trivial
`(node)n` alias, and every `node move`, `move node`, or `move move` alias. The
result has 185 generated rules and a 141-symbol root. This last readability
pass duplicates frequently used move pairs, so it has 962 immediate references
rather than the 864 of the more shared intermediate DAG. It is exact and
reproducible, but deliberately mechanical; it is a useful optimizer fixture,
not the more readable presentation.

The fixture deliberately uses the agreed native grammar:

- WCA terminal moves, including prime suffixes;
- concatenation by adjacency;
- cubing-style repetition after a parenthesized expression;
- named definitions and inverse references; and
- one explicit exported root.

It does not use an external packed block. This makes the recursive structure
visible to humans and lowers directly to shared `Concat`, `Repeat`, and
`Inverse` DAG nodes.

[archive]: https://bruce.cubing.net/hamilton222.zip
[stress]: https://experiments.cubing.net/cubing.js/stress-tests/2x2x2-devils-alg.html
