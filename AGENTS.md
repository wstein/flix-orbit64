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
- `./flixw run --entrypoint Orbit64.Cli.main` — run the demo command line
- `./flixw build` — compile to `build/class`
- `./flixw build-pkg` — build the distributable `artifact/*.fpkg`
- `./flixw format` — reformat sources in place; the pinned compiler has no
  check-only mode, so CI does not gate on formatting
- `./flixw doc` — write this project's API documentation to `build/doc/`.
  Standard library pages are not generated, so links into it dangle locally;
  the docs workflow rewrites them to <https://api.flix.dev>

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

- `src/Orbit64.flix` — the package's public API
- `src/Orbit64/` — the rest of the library, all nested under the `Orbit64`
  module so that a consumer's own `Coord`, `Orbit`, or `Rank` cannot collide
  with ours. `Orbit64/Cli.flix` holds the demo command line, and
  `Orbit64/Net.flix` the only geometry in the package -- the codec itself has
  none, which is what lets it cover every size
- `test/` — `@Test` functions
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
  of its own. The demo lives in `Orbit64.Cli` and is reached with
  `--entrypoint`.
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
