# orbit64-cli

The demo command line for [`orbit64`](https://github.com/wstein/flix-orbit64):
a size table, a round-trip demo, and a state-token decoder. Kept as a separate
package so the library itself never defines a top-level `main`.

This is what a consuming project's `flix.toml` and `src/Main.flix` look like
-- it depends on the published `orbit64` package exactly the way any other
project would. It carries no wrapper of its own and is not driven by this
repository's `flixw`; run it with your own Flix install:

```
cd examples/cli-tool
flix run                 # size table, then a 3x3x3 round-trip demo
flix run -- <token>      # decode a state token; its length picks the cube size
```

```
$ flix run -- AEtgYICyPB1X
3x3x3, 2 orbits:
  Corners: CornerCoord(Vector#{0, 4, 5, 1, 3, 7, 6, 2}, ...)
  Midges: MidgeCoord(Vector#{1, 8, 5, 9, 3, 11, 7, 10, 0, 4, 6, 2}, ...)
...
```

`NO_COLOR=1` prints the net in plain letters instead of terminal colour.
