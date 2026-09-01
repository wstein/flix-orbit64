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
