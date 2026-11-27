# flix-orbit64

[![Build and Test](https://github.com/wstein/flix-orbit64/actions/workflows/build-and-test.yaml/badge.svg)](https://github.com/wstein/flix-orbit64/actions/workflows/build-and-test.yaml)
[![Docs](https://github.com/wstein/flix-orbit64/actions/workflows/docs.yaml/badge.svg)](https://wstein.github.io/flix-orbit64/)
[![Release](https://img.shields.io/github/v/release/wstein/flix-orbit64)](https://github.com/wstein/flix-orbit64/releases/latest)
[![Flix](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fwstein%2Fflix-orbit64%2Fmain%2F.flixw%2Flock.toml&query=%24.compiler.version&label=Flix&color=blue)](https://flix.dev)
[![License](https://img.shields.io/github/license/wstein/flix-orbit64)](LICENSE)

Package 1.0.0 encodes cube **state** only as [Orbit64 V2](FORMAT-V2.md).
The V1 state class (class `00` in [FORMAT.md](FORMAT.md), the fixed widths
5, 12, 27, 43, 66, and 90) is not implemented. A V2 token has no class bits.
Label it, for example `orbit64v2:`, wherever a reader could still meet an
older decoder.

Move sequences, structured algorithms, and extension envelopes are unchanged
and are still specified by [FORMAT.md](FORMAT.md) (classes `01`, `10`, and
`11`). They are not state tokens.

The project carries its own compiler, so there is nothing to install but a
JDK 21+.

```
./flixw test                                      # V2 state tests, plus move and algorithm tests
./flixw examples local run cli-tool               # V2 registry table and a solved 3x3x3 round trip
./flixw examples local run cli-tool -- <token>    # decode a V2 state token
```

## Use it as a library

```toml
[dependencies]
"github:wstein/flix-orbit64" = { version = "1.0.0", mount = "orbit64" }
```

Flix 0.80 reaches a dependency through its mount, the name before `::` in a
`use`. Without an explicit `mount` it would be the repository name, which
`flix-orbit64` cannot be, so name one. Until this 1.0.0 release is published,
the examples run against this checkout with `./flixw examples local`.

```flix
use orbit64::Orbit64

def demo(): Result[String, String] =
    let solved = Orbit64.V2.State.solved(3, Orbit64.V2.Registry.Model.Color);
    Orbit64.V2.Codec.encode(3, solved)   // entry 3: 3x3x3 color, framed
```

`Orbit64.V2.Codec.decode(token)` returns the registry entry and the cube.
`Orbit64.V2.Facelets` converts between that cube and a facelet string for
`n = 2..15`. Entry ids, lengths, and the color and picture models are in
[FORMAT-V2.md](FORMAT-V2.md).

A solved state whose entry starts at offset zero is a run of `A` of that
entry's length. Entry 3, the 3×3×3 color framed state, is twelve `A`s.

Literal moves stay type-safe values rather than notation strings:

```flix
use orbit64::Orbit64
use orbit64::Orbit64.Move.Move.LayerTurn
use orbit64::Orbit64.Move.Face.{U, R}
use orbit64::Orbit64.Move.Amount.{Clockwise, Half}

def moves(): Result[String, String] =
    Orbit64.Move.encode(3, List#{
        LayerTurn(U, 0, Clockwise),
        LayerTurn(R, 0, Half)
    }) //=> Ok("d4")
```

`Orbit64.Token.decode(token)` dispatches literal sequences, structured
algorithms, and extension envelopes. It rejects class `00`.

## Layout

- `src/Orbit64/V2/` — the state codec: `Registry`, `State`, `Codec`, `Facelets`
- `src/Orbit64/Move.flix` — primitive layer turns and literal move-sequence encoding
- `src/Orbit64/Algorithm/` — structured algorithm grammar
- `src/Orbit64/Token.flix` — dispatch for the non-state classes
- `examples/cli-tool/` — the demo command line, run with `./flixw examples local run cli-tool`

API documentation is published at <https://wstein.github.io/flix-orbit64/>.

## Formatting

Formatting is done by Prettier with the Flix plugin
([`prettier-plugin-flix`](https://github.com/wstein/prettier-plugin-flix)). The
[Format workflow](.github/workflows/format.yaml) checks the Flix files under
`src/`, `test/` and `examples/*/`. The generated `test/*Data.flix` files are
left out (see `.prettierignore`). The [Format V2 workflow](.github/workflows/format-v2.yaml)
checks the Orbit64 V2 token format.

```sh
npm ci
npm run format:check
```

See `AGENTS.md` for the toolchain.

## License

flix-orbit64 is written by Werner Stein and licensed under the
[Apache License 2.0](LICENSE).
