# Working on this project

A Flix project that carries its own compiler. `./flixw` downloads the exact
`flix.jar` pinned in `.flixw/lock.toml`, verifies it against a committed
SHA-256, and runs it. Building and testing need nothing but a JDK — 21 or
newer. The format check also needs Node.js 22 and `npm ci`.

## Commands

Run everything through the wrapper: `flix` is not expected to be on `PATH`, and
a `flix` that is may be a different version than this project pins. On Windows
use `.\flixw.cmd` wherever these say `./flixw`.

- `./flixw check` — type-check without generating code; the fast feedback loop
- `./flixw test` — run every `@Test` function under `test/`
- `./flixw build` — compile to `build/class`
- `./flixw build-pkg` — build the distributable `artifact/*.fpkg`
- `npm ci`, then `npm run format:check` (or `./flixw task fmt-check`) — check
  the formatting of the Flix files under `src/`, `test/` and `examples/*/`.
  Prettier with prettier-plugin-flix does the formatting, pinned in
  `package-lock.json`; the Format workflow gates on it
- `./flixw task fmt` — rewrite those files with Prettier. Not `./flixw format`:
  that is the compiler's own formatter, which this project does not use
- `./flixw doc` — write this project's API documentation to `build/doc/`,
  for `src/` and `test/` alike. Standard library pages are not generated, so
  links into it dangle locally; the docs workflow publishes only the `src/`
  pages and rewrites those links to <https://api.flix.dev>
- `./flixw metrics --format md` — code-smell report: over-long and crammed
  lines, complexity, nesting, coupling, doc coverage. **Run it before every
  commit and fix what it finds.** It needs the project to compile first, and
  the `metrics` plugin installed once per machine:

  ```console
  ./flixw plugin install metrics 0.5.0 \
    https://github.com/wstein/flixw-metrics/releases/download/v0.5.0/plugin.jar \
    --sha256 d806e21d463ee569621257b89938bc4846c1aaa3041d79bfbd6da9fba97d51bb
  ```

  Installing also writes a `[plugins.metrics]` entry to this repository's
  `.flixw/lock.toml`. Do not commit that change: it is the machine's install
  record, not part of the project. The install is per machine, not per
  repository, and it is third-party, unaffiliated code that runs as you; see
  [flixw-metrics' own Safety section](https://github.com/wstein/flixw-metrics#safety)
  before installing anything. Metrics 0.6.0, the latest release, does not
  support the pinned Flix 0.80.0: it prints "the pinned compiler has no
  supported engine API" and exits without a report. Until a release does, say in the commit or pull
  request that no metrics report could be produced instead of treating the
  empty run as a clean result

The demo command line is not here: a package with a top-level `main` cannot be
depended on, so it lives in [`examples/cli-tool`](examples/cli-tool), a
separate package that depends on this one exactly the way any other consumer
would. `./flixw examples` runs an `examples/<name>` package with this
project's pinned compiler, and `./flixw examples local` runs it against this
checkout instead of the released dependency. Use `local` for now: release
0.9.0 was built for Flix 0.75 and cannot be resolved by Flix 0.80.

    ./flixw examples local run cli-tool               # size table, round-trip
    ./flixw examples local run cli-tool -- <token>    # decode; length picks the cube size
    ./flixw examples local test cli-tool

`local` copies only `src/`, `test/` and `flix.toml` into a scratch directory,
so the algorithm-tool test that reads `2x2x2-devils-alg.orbit64` from the
working directory fails there; the other eight pass.

The wrapper adds verbs of its own, ahead of the compiler's:

- `./flixw validate` — the wrapper's own consistency checks, for CI
- `./flixw doctor` — those checks plus the full picture, for bug reports
- `./flixw pin <version>` — move to another compiler and rewrite the lock
- `./flixw examples <verb> <name>` — run, check, build, or test a package in
  `examples/<name>`; `./flixw examples local <verb> <name>` does so against
  this checkout
- `./flixw task <name>` — run a task from `.flixw/tasks.toml`: `fmt` and
  `fmt-check`

Releasing is a tag and nothing else. `flix.toml` states the version, a
`v<version>` tag is pushed, and `release.yaml` builds the package from that tag
and attaches it to a GitHub release as `package.fpkg` and `flix.toml`, the
names Flix 0.80 resolves. A `github:` dependency resolves through
those release assets, so a tag without a release is a version nobody can depend
on, and a tag whose name disagrees with `flix.toml` is refused before anything
is published.

## Layout

- `src/Orbit64/State.flix` — state counting and state `encode`/`decode`
- `src/Orbit64/Move.flix` — primitive moves and literal sequences
- `src/Orbit64/Algorithm.flix`, `src/Orbit64/Algorithm/Encoding.flix` — typed
  algorithm DAGs, validation, streaming, and class-`10` encoding
- `src/Orbit64/Canonical.flix`, `src/Orbit64/Internal/Symmetry.flix` — the
  canonical token of a pattern, and the 48 cube symmetries as facelet
  permutations it is built on
- `src/Orbit64/Token.flix` — tagged decoding across the Orbit64 token family
- `src/Orbit64/Internal/Encoding.flix` — shared base64url and delimited-bitstream arithmetic
- `src/Orbit64/` — the rest of the library, all nested under the `Orbit64`
  module so that a consumer's own `Coord`, `Orbit`, or `Rank` cannot collide
  with ours. `Orbit64/Net.flix` owns state-to-facelet geometry;
  `Orbit64/Move.flix` owns the deliberately smaller face/layer/amount vocabulary
  needed to describe turns. State ranking remains pure arithmetic in `n`
- `src/Orbit64/V2/` — the V2 reference implementation of [FORMAT-V2.md](FORMAT-V2.md):
  `Registry` allocates lengths and offsets, `State` ranks cube states,
  `Codec` writes and reads tokens
- `test/` — `@Test` functions. `TestV2VectorData.flix` is generated by
  `julia tools/format-v2/vectors.jl`, an independent Julia encoder; do not edit it
- `tools/format-v2/` — the Julia program (standard library only) that checks
  the proof obligations of [FORMAT-V2.md](FORMAT-V2.md), and its
  committed report. Regenerate the report with
  `julia tools/format-v2/proof_obligations.jl > tools/format-v2/proof-obligations.md`
  after changing either. `vectors.jl` writes `test/TestV2VectorData.flix`
  (`julia tools/format-v2/vectors.jl`), whose tokens the Flix tests must reproduce
- `src/Orbit64/V2/Facelets.flix` — the facelet bridge: cube state to facelet
  string and back, `n = 2..15` (picture model `n = 3..15`), canonical and framed.
  `tools/format-v2/facelet_vectors.jl` is its independent check; it writes
  `test/TestV2FaceletData.flix` (do not edit it)
- `tools/format-v2/facelet_picture_vectors.jl` — the independent check of the
  picture-model facelets (one base64url symbol per sticker, "Picture facelets"
  in `FORMAT-V2.md`): it tracks every sticker and fixed-center rotation through
  random turns and writes `test/TestV2FaceletPictureData.flix` (do not edit it)
- `FORMAT-V2-SLOTS.md` — the V2 slot tables, generated by
  `julia tools/format-v2/slots.jl > FORMAT-V2-SLOTS.md`; do not edit it.
  `.github/workflows/format-v2.yaml` regenerates it, the proof report and the
  test vectors on every push and fails when a committed copy is stale
- `examples/cli-tool/` — the demo command line, a separate Flix package that
  depends on this one the same way any other consumer would
- `flix.toml` — the package version, repository, dependencies, and the
  *lowest* Flix version this project accepts. Flix 0.80 allows no other keys
  in `[package]`: the description and authors are in `README.md`, the license
  in `LICENSE`
- `packages.lock` — written by every Flix 0.80 build; committed. It is an
  empty `[lock]` table, since the library has no dependencies
- `package.json`, `package-lock.json`, `.prettierrc.json`, `.prettierignore`
  — the Prettier format check; `.flixw/tasks.toml` holds the `fmt` and
  `fmt-check` tasks
- `.flixw/lock.toml` — the exact compiler and its digest. `flix.toml` states a
  floor; this states the pin. Both are committed, and `validate` fails when
  they disagree
- `flixw`, `flixw.cmd`, `.flixw/flixw.java` — the wrapper itself. Generated;
  change it with `./flixw wrapper --upgrade`, never by hand
- `.github/workflows/` — `build-and-test.yaml` on three platforms,
  `update-flix.yaml` weekly, `docs.yaml` for the API documentation, and
  `release.yaml` on a `v*.*.*` tag. All four drive the wrapper; none of them
  install Flix. Only `release.yaml` and `update-flix.yaml` ask for write
  access, and only in the one job that needs it. `format.yaml` runs the
  Prettier check, and `format-v2.yaml` the Orbit64 token-format checks
- `build/`, `artifact/`, `lib/` — generated; do not edit and do not commit

`CLAUDE.md` and `.github/copilot-instructions.md` both point at this file
rather than repeating it, so that each tool finds the same instructions under
the name it looks for.

## This is a library

The package is meant to be depended on, which constrains it in two ways that
are easy to undo by accident:

- **No top-level `main`.** `build-pkg` ships everything under `src/`, so a
  top-level `main` becomes a duplicate definition in any consumer that has one
  of its own. The demo needs a top-level `main` to run as a CLI, which is why
  it lives in its own package, [`examples/cli-tool`](examples/cli-tool),
  rather than here.
- **No top-level modules but `Orbit64`.** Everything nests under it. Names as
  common as `Coord` or `Rank` would otherwise collide with the consumer's.

Flix 0.80 makes modules private by default, so every module here is declared
`pub mod`, `Orbit64.Internal` included: the library's other modules and the
tests reach it, which a private module would not allow. `Internal` marks what
is not API by name only. A consumer reaches the package through the mount its
`flix.toml` gives the dependency, e.g. `use orbit64::Orbit64.State`.

## Writing Flix

Your training data is probably older than this compiler. Read
<https://doc.flix.dev/for-llms.html> before writing Flix: it lists what changed.
For the standard library use <https://api.flix.dev>. `./flixw doc` documents
this project only, so it is no help there.

The mistakes that show up most often:

- `def main(): Unit \ IO = ...` — arguments come from `Env.getArgs()`, not from
  parameters
- effects are written with `\`, not `&`
- effect operations are called like ordinary functions; there is no `do` keyword
- handlers are `run { ... } with handler E { ... }`; chain them rather than
  nesting `run`
- annotations are uppercase: `@Test`, `@Lazy`, `@Parallel`, `@MustUse`
- Java types need a top-level `import`, and all Java interop carries `IO`
- modules are private unless declared `pub mod`, and a module's parent must be
  declared too (`src/Orbit64/V2.flix` declares `Orbit64.V2`)
- a dependency is reached through its mount: `use orbit64::Orbit64`

Prefer effects and handlers to callbacks or hand-written CPS, and standard
library effects to Java interop.

## Naming modules

A module has one declaration site in the whole program, dependencies included,
so never take a common top-level name.

- one root namespace per package, named after it: `flix-orbit64` roots at
  `Orbit64`
- directories mirror module paths: `Orbit64.Rank` lives in
  `src/Orbit64/Rank.flix`
- two or three levels; `Internal` for what is not API
- name a module for what is done there: `Orbit64.Rank` holds the
  permutation and combination ranking primitives
- spell names out; tests flat, one `TestX` per subject

## Language

Write American English everywhere: texts, docs, comments, identifiers, test
names and output strings (color, center, neighbor, optimize, license, labeled).
British spellings are mistakes. Rename without alias or fallback; existing
token and facelet formats are unaffected, since the wire format has no words.
