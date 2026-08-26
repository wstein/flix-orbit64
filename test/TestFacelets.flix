//
// Cross-project fixtures: the facelet layer, against `flix-cube`.
//
// `Orbit64.Net` and `flix-cube`'s `BigCube` use the same facelet
// layout -- `face * n * n + row * n + col`, faces `U R F D L B` -- which makes
// facelets the one place two projects with different slot orders can be
// compared directly.
//
// The expected strings were produced by `BigCube.showFacelets` after applying
// the named turn to a solved cube, in that project, by an engine sharing no
// code with this one. They pass only if this project's slot tables and that
// project's turn arithmetic describe the same cube. Because facelets cannot see
// slot numbering, these survived Orbit64 renumbering its own orbits -- which is
// the property that makes them worth having.
//
// Every fixture is checked in both directions, which is the whole of what an
// adapter needs: `toFacelets` to draw a token that project can show, and
// `fromFacelets` to turn a cube that project turned into a token.
//

use Orbit64.Coord.Coord
use Orbit64.Coord.Coord.{CornerCoord, MidgeCoord, WingCoord, CenterCoord}

def faceSymbols(): Vector[String] = Vector#{"U", "R", "F", "D", "L", "B"}

def asString(r: Result[String, Vector[Int32]]): Result[String, String] =
    Result.map(fs -> fs |> Vector.map(f -> Vector.get(f, faceSymbols())) |> Vector.join(""), r)

///
/// Face symbols back to face indices, the way `BigCube.parseFacelets` reads
/// them. A symbol that is no face becomes `-1`, which `fromFacelets` refuses
/// rather than silently taking for a colour.
///
def asFacelets(s: String): Vector[Int32] =
    let table = String.toList(faceSymbols() |> Vector.join(""));
    String.toList(s) |> List.map(c -> List.indexOf(c, table) |> Option.getWithDefault(-1))
        |> List.toVector

///
/// Both directions of one fixture.
///
/// Drawing the state must give that project's stickers, and reading that
/// project's stickers must give the state back. Two claims rather than one: a
/// reader and a writer that agreed with each other about a table they had both
/// got wrong would still pass only the first.
///
def bothWays(n: Int32, orbits: List[Coord], drawn: String): Unit \ Assert =
    Assert.assertEq(expected = Ok(drawn), asString(Orbit64.Net.toFacelets(n, orbits)));
    Assert.assertEq(expected = Ok(orbits), Orbit64.Net.fromFacelets(n, asFacelets(drawn)))

@Test
def faceletsOfFourByFourSolved(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}),
                       CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    bothWays(4, orbits, "UUUUUUUUUUUUUUUURRRRRRRRRRRRRRRRFFFFFFFFFFFFFFFFDDDDDDDDDDDDDDDDLLLLLLLLLLLLLLLLBBBBBBBBBBBBBBBB")

@Test
def faceletsOfFourByFourU(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), WingCoord(Vector#{2, 0, 3, 1, 20, 5, 6, 7, 4, 9, 10, 11, 12, 13, 14, 15, 8, 17, 18, 19, 16, 21, 22, 23}),
                       CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    bothWays(4, orbits, "UUUUUUUUUUUUUUUUBBBBRRRRRRRRRRRRRRRRFFFFFFFFFFFFDDDDDDDDDDDDDDDDFFFFLLLLLLLLLLLLLLLLBBBBBBBBBBBB")

@Test
def faceletsOfFourByFourR(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{4, 1, 2, 0, 7, 5, 6, 3}, Vector#{2, 0, 0, 1, 1, 0, 0, 2}), WingCoord(Vector#{0, 9, 2, 3, 6, 4, 7, 5, 8, 13, 10, 11, 12, 22, 14, 15, 16, 17, 18, 19, 20, 21, 1, 23}),
                       CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    bothWays(4, orbits, "UUUFUUUFUUUFUUUFRRRRRRRRRRRRRRRRFFFDFFFDFFFDFFFDDDDBDDDBDDDBDDDBLLLLLLLLLLLLLLLLUBBBUBBBUBBBUBBB")

@Test
def faceletsOfFourByFourF(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{1, 5, 2, 3, 0, 4, 6, 7}, Vector#{1, 2, 0, 0, 2, 1, 0, 0}), WingCoord(Vector#{0, 1, 2, 17, 4, 5, 3, 7, 10, 8, 11, 9, 6, 13, 14, 15, 16, 12, 18, 19, 20, 21, 22, 23}),
                       CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    bothWays(4, orbits, "UUUUUUUUUUUULLLLURRRURRRURRRURRRFFFFFFFFFFFFFFFFRRRRDDDDDDDDDDDDLLLDLLLDLLLDLLLDBBBBBBBBBBBBBBBB")

@Test
def faceletsOfFourByFourUw(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), WingCoord(Vector#{2, 0, 3, 1, 20, 21, 6, 7, 4, 5, 10, 11, 12, 13, 14, 15, 8, 9, 18, 19, 16, 17, 22, 23}),
                       CenterCoord(Vector#{0, 0, 0, 0, 5, 5, 1, 1, 1, 1, 2, 2, 3, 3, 3, 3, 2, 2, 4, 4, 4, 4, 5, 5})};
    bothWays(4, orbits, "UUUUUUUUUUUUUUUUBBBBBBBBRRRRRRRRRRRRRRRRFFFFFFFFDDDDDDDDDDDDDDDDFFFFFFFFLLLLLLLLLLLLLLLLBBBBBBBB")

@Test
def faceletsOfFourByFourRw(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{4, 1, 2, 0, 7, 5, 6, 3}, Vector#{2, 0, 0, 1, 1, 0, 0, 2}), WingCoord(Vector#{0, 9, 2, 11, 6, 4, 7, 5, 8, 13, 10, 15, 12, 22, 14, 20, 16, 17, 18, 19, 3, 21, 1, 23}),
                       CenterCoord(Vector#{0, 2, 0, 2, 1, 1, 1, 1, 2, 3, 2, 3, 3, 5, 3, 5, 4, 4, 4, 4, 0, 5, 0, 5})};
    bothWays(4, orbits, "UUFFUUFFUUFFUUFFRRRRRRRRRRRRRRRRFFDDFFDDFFDDFFDDDDBBDDBBDDBBDDBBLLLLLLLLLLLLLLLLUUBBUUBBUUBBUUBB")

@Test
def faceletsOfFourByFour2R(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), WingCoord(Vector#{0, 1, 2, 11, 4, 5, 6, 7, 8, 9, 10, 15, 12, 13, 14, 20, 16, 17, 18, 19, 3, 21, 22, 23}),
                       CenterCoord(Vector#{0, 2, 0, 2, 1, 1, 1, 1, 2, 3, 2, 3, 3, 5, 3, 5, 4, 4, 4, 4, 0, 5, 0, 5})};
    bothWays(4, orbits, "UUFUUUFUUUFUUUFURRRRRRRRRRRRRRRRFFDFFFDFFFDFFFDFDDBDDDBDDDBDDDBDLLLLLLLLLLLLLLLLBUBBBUBBBUBBBUBB")

@Test
def faceletsOfFiveByFiveSolved(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), MidgeCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
                       WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    bothWays(5, orbits, "UUUUUUUUUUUUUUUUUUUUUUUUURRRRRRRRRRRRRRRRRRRRRRRRRFFFFFFFFFFFFFFFFFFFFFFFFFDDDDDDDDDDDDDDDDDDDDDDDDDLLLLLLLLLLLLLLLLLLLLLLLLLBBBBBBBBBBBBBBBBBBBBBBBBB")

@Test
def faceletsOfFiveByFiveU(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), MidgeCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
                       WingCoord(Vector#{2, 0, 3, 1, 20, 5, 6, 7, 4, 9, 10, 11, 12, 13, 14, 15, 8, 17, 18, 19, 16, 21, 22, 23}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    bothWays(5, orbits, "UUUUUUUUUUUUUUUUUUUUUUUUUBBBBBRRRRRRRRRRRRRRRRRRRRRRRRRFFFFFFFFFFFFFFFFFFFFDDDDDDDDDDDDDDDDDDDDDDDDDFFFFFLLLLLLLLLLLLLLLLLLLLLLLLLBBBBBBBBBBBBBBBBBBBB")

@Test
def faceletsOfFiveByFiveR(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{4, 1, 2, 0, 7, 5, 6, 3}, Vector#{2, 0, 0, 1, 1, 0, 0, 2}), MidgeCoord(Vector#{8, 1, 2, 3, 11, 5, 6, 7, 4, 9, 10, 0}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
                       WingCoord(Vector#{0, 9, 2, 3, 6, 4, 7, 5, 8, 13, 10, 11, 12, 22, 14, 15, 16, 17, 18, 19, 20, 21, 1, 23}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    bothWays(5, orbits, "UUUUFUUUUFUUUUFUUUUFUUUUFRRRRRRRRRRRRRRRRRRRRRRRRRFFFFDFFFFDFFFFDFFFFDFFFFDDDDDBDDDDBDDDDBDDDDBDDDDBLLLLLLLLLLLLLLLLLLLLLLLLLUBBBBUBBBBUBBBBUBBBBUBBBB")

@Test
def faceletsOfFiveByFiveF(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{1, 5, 2, 3, 0, 4, 6, 7}, Vector#{1, 2, 0, 0, 2, 1, 0, 0}), MidgeCoord(Vector#{0, 9, 2, 3, 4, 8, 6, 7, 1, 5, 10, 11}, Vector#{0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0}),
                       WingCoord(Vector#{0, 1, 2, 17, 4, 5, 3, 7, 10, 8, 11, 9, 6, 13, 14, 15, 16, 12, 18, 19, 20, 21, 22, 23}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    bothWays(5, orbits, "UUUUUUUUUUUUUUUUUUUULLLLLURRRRURRRRURRRRURRRRURRRRFFFFFFFFFFFFFFFFFFFFFFFFFRRRRRDDDDDDDDDDDDDDDDDDDDLLLLDLLLLDLLLLDLLLLDLLLLDBBBBBBBBBBBBBBBBBBBBBBBBB")

@Test
def faceletsOfFiveByFiveUw(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), MidgeCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
                       WingCoord(Vector#{2, 0, 3, 1, 20, 21, 6, 7, 4, 5, 10, 11, 12, 13, 14, 15, 8, 9, 18, 19, 16, 17, 22, 23}), CenterCoord(Vector#{0, 0, 0, 0, 5, 5, 1, 1, 1, 1, 2, 2, 3, 3, 3, 3, 2, 2, 4, 4, 4, 4, 5, 5}), CenterCoord(Vector#{0, 0, 0, 0, 5, 1, 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 2, 4, 4, 4, 4, 5, 5, 5})};
    bothWays(5, orbits, "UUUUUUUUUUUUUUUUUUUUUUUUUBBBBBBBBBBRRRRRRRRRRRRRRRRRRRRRRRRRFFFFFFFFFFFFFFFDDDDDDDDDDDDDDDDDDDDDDDDDFFFFFFFFFFLLLLLLLLLLLLLLLLLLLLLLLLLBBBBBBBBBBBBBBB")

@Test
def faceletsOfFiveByFiveRw(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{4, 1, 2, 0, 7, 5, 6, 3}, Vector#{2, 0, 0, 1, 1, 0, 0, 2}), MidgeCoord(Vector#{8, 1, 2, 3, 11, 5, 6, 7, 4, 9, 10, 0}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
                       WingCoord(Vector#{0, 9, 2, 11, 6, 4, 7, 5, 8, 13, 10, 15, 12, 22, 14, 20, 16, 17, 18, 19, 3, 21, 1, 23}), CenterCoord(Vector#{0, 2, 0, 2, 1, 1, 1, 1, 2, 3, 2, 3, 3, 5, 3, 5, 4, 4, 4, 4, 0, 5, 0, 5}), CenterCoord(Vector#{0, 0, 2, 0, 1, 1, 1, 1, 2, 2, 3, 2, 3, 3, 5, 3, 4, 4, 4, 4, 5, 0, 5, 5})};
    bothWays(5, orbits, "UUUFFUUUFFUUUFFUUUFFUUUFFRRRRRRRRRRRRRRRRRRRRRRRRRFFFDDFFFDDFFFDDFFFDDFFFDDDDDBBDDDBBDDDBBDDDBBDDDBBLLLLLLLLLLLLLLLLLLLLLLLLLUUBBBUUBBBUUBBBUUBBBUUBBB")

@Test
def faceletsOfFiveByFive2R(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), MidgeCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
                       WingCoord(Vector#{0, 1, 2, 11, 4, 5, 6, 7, 8, 9, 10, 15, 12, 13, 14, 20, 16, 17, 18, 19, 3, 21, 22, 23}), CenterCoord(Vector#{0, 2, 0, 2, 1, 1, 1, 1, 2, 3, 2, 3, 3, 5, 3, 5, 4, 4, 4, 4, 0, 5, 0, 5}), CenterCoord(Vector#{0, 0, 2, 0, 1, 1, 1, 1, 2, 2, 3, 2, 3, 3, 5, 3, 4, 4, 4, 4, 5, 0, 5, 5})};
    bothWays(5, orbits, "UUUFUUUUFUUUUFUUUUFUUUUFURRRRRRRRRRRRRRRRRRRRRRRRRFFFDFFFFDFFFFDFFFFDFFFFDFDDDBDDDDBDDDDBDDDDBDDDDBDLLLLLLLLLLLLLLLLLLLLLLLLLBUBBBBUBBBBUBBBBUBBBBUBBB")
