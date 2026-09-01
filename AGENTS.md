# Working on this project

A Flix project that carries its own compiler. `./flixw` downloads the exact
`flix.jar` pinned in `.flixw/lock.toml`, verifies it against a committed
SHA-256, and runs it. Nothing needs installing but a JDK — 21 or newer.

## Commands

Run everything through the wrapper: `flix` is not expected to be on `PATH`, and
a `flix` that is may be a different version than this project pins. On Windows
use `.\flixw.cmd` wherever these say `./flixw`.

- `./flixw check` — type-check without generating code; the fast feedback loop
- `./flixw test` — run every `@Test` function under `test/`
- `./flixw build` — compile to `build/class`
- `./flixw build-pkg` — build the distributable `artifact/*.fpkg`
- `./flixw format` — reformat sources in place; the pinned compiler has no
  check-only mode, so CI does not gate on formatting
- `./flixw doc` — write this project's API documentation to `build/doc/`.
  Standard library pages are not generated, so links into it dangle locally;
  the docs workflow rewrites them to <https://api.flix.dev>
- `./flixw metrics --format md` — code-smell report: over-long and crammed
  lines, complexity, nesting, coupling, doc coverage. **Run it before every
  commit and fix what it finds.** It needs the project to compile first, and
  the `metrics` plugin installed once per machine:

  ```console
  ./flixw plugin install metrics 0.1.8 \
    https://github.com/wstein/flixw-metrics/releases/download/v0.1.8/plugin.jar \
    --sha256 bd8707afb5a06a37d26f1bd9b9d3bc3b3892a73e1617b177328a4f5ff7d7c67f
  ```

  This is a per-machine install, not a per-repository one — it is third-party,
  unaffiliated code that runs as you; see
  [flixw-metrics' own Safety section](https://github.com/wstein/flixw-metrics#safety)
  before installing anything

The demo command line is not here: a package with a top-level `main` cannot be
depended on, so it lives in [`examples/cli-tool`](examples/cli-tool), a
separate package that depends on this one exactly the way any other consumer
would. It is sample source, not a project this wrapper drives — it has no
`.flixw/lock.toml` of its own, and this repository's `flixw` looks for a
project's lock relative to the caller's working directory, not relative to
the project it's pointed at, so it cannot run something outside its own tree.
Run the example with your own Flix install instead:

    cd examples/cli-tool
    flix run                 # size table, round-trip
    flix run -- <token>      # decode; length picks the cube size

The wrapper adds verbs of its own, ahead of the compiler's:

- `./flixw validate` — the wrapper's own consistency checks, for CI
- `./flixw doctor` — those checks plus the full picture, for bug reports
- `./flixw pin <version>` — move to another compiler and rewrite the lock

Releasing is a tag and nothing else. `flix.toml` states the version, a
`v<version>` tag is pushed, and `release.yaml` builds the package from that tag
and attaches it to a GitHub release. A `github:` dependency resolves through
those release assets, so a tag without a release is a version nobody can depend
on, and a tag whose name disagrees with `flix.toml` is refused before anything
is published.

## Layout

- `src/Orbit64/State.flix` — state counting and state `encode`/`decode`
- `src/Orbit64/Move.flix`, `src/Orbit64/Move/Slp.flix` — primitive moves,
  literal sequences, and straight-line programs
- `src/Orbit64/Token.flix` — tagged decoding across the Orbit64 token family
- `src/Orbit64/Internal/Encoding.flix` — shared base64url and VLQ arithmetic
- `src/Orbit64/` — the rest of the library, all nested under the `Orbit64`
  module so that a consumer's own `Coord`, `Orbit`, or `Rank` cannot collide
  with ours. `Orbit64/Net.flix` owns state-to-facelet geometry;
  `Orbit64/Move.flix` owns the deliberately smaller face/layer/amount vocabulary
  needed to describe turns. State ranking remains pure arithmetic in `n`
- `test/` — `@Test` functions
- `examples/cli-tool/` — the demo command line, a separate Flix package that
  depends on this one the same way any other consumer would
- `flix.toml` — package metadata, dependencies, and the *lowest* Flix version
  this project accepts. `name` sets the package name, but the `.fpkg` filename
  comes from the *directory* name, so the two must agree
- `.flixw/lock.toml` — the exact compiler and its digest. `flix.toml` states a
  floor; this states the pin. Both are committed, and `validate` fails when
  they disagree
- `flixw`, `flixw.cmd`, `.flixw/flixw.java` — the wrapper itself. Generated;
  change it with `./flixw wrapper --upgrade`, never by hand
- `.github/workflows/` — `build-and-test.yaml` on three platforms,
  `update-flix.yaml` weekly, `docs.yaml` for the API documentation, and
  `release.yaml` on a `v*.*.*` tag. All four drive the wrapper; none of them
  install Flix. Only `release.yaml` and `update-flix.yaml` ask for write
  access, and only in the one job that needs it
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

Note that `modules` in `flix.toml` does *not* enforce this -- a consumer can
still reach `Orbit64.Rank`. It is documentation of intent, not a boundary.

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
