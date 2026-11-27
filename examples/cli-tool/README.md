# orbit64-cli

The demo command line for [`orbit64`](https://github.com/wstein/flix-orbit64):
a V2 registry table, a solved 3×3×3 round trip, and a V2 state-token decoder.
Kept as a separate package so the library itself never defines a top-level `main`.

It depends on `orbit64` 1.0.0, mounted as `orbit64`. Until that release is
published, `local` builds this checkout's library instead:

```
./flixw examples local run cli-tool               # registry table, then a solved 3x3x3 round trip
./flixw examples local run cli-tool -- <token>    # decode a V2 state token
./flixw examples local test cli-tool
```
