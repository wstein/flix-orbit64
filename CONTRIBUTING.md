# Contributing to flix-orbit64

Bug reports, compatibility vectors, documentation fixes, and focused code
changes are welcome. Search the existing issues before opening a new one.

## Before changing the format

[FORMAT.md](FORMAT.md) defines the token and facelet interchange contract.
Existing tokens must keep their meaning. Open an issue before changing a wire
encoding, orbit order, facelet convention, or frame order so the compatibility
impact can be discussed.

This is a library: keep source under the `Orbit64` root module and do not add
a top-level `main`. The CLI examples are separate packages under `examples/`.

## Work locally

Install a JDK 21 or newer. Use the repository's `./flixw` wrapper, which runs
the compiler pinned in `.flixw/lock.toml`:

```console
./flixw check
./flixw test
./flixw build-pkg
```

For state or facelet changes, add tests that check both directions of
conversion and, where possible, a facelet reference derived independently of
the codec. For wrapper or workflow changes, run `./flixw validate`.

Before committing, run `./flixw metrics --format md` and address findings
introduced by your change. [AGENTS.md](AGENTS.md) explains the one-time metrics
plugin setup and its safety considerations. The wrapper files are generated;
upgrade them through `./flixw wrapper --upgrade` rather than editing them.

## Pull requests

Keep each commit focused and describe what changed, how it was checked, and
whether existing tokens or facelets are affected. Link the relevant issue if
there is one. The [pull request template](.github/PULL_REQUEST_TEMPLATE.md)
lists the information reviewers need.
