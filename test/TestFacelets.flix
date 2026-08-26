//
// Cross-project fixtures: the facelet layer, against `flix-cube`.
//
// `Orbit64.Net.toFacelets` and `flix-cube`'s `BigCube` use the same facelet
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

use Orbit64.Coord.Coord.{CornerCoord, MidgeCoord, WingCoord, CenterCoord}

def asString(r: Result[String, Vector[Int32]]): Result[String, String] =
    Result.map(fs -> fs |> Vector.map(f ->
        Vector.get(f, Vector#{"U", "R", "F", "D", "L", "B"})) |> Vector.join(""), r)

@Test
def faceletsOfFourByFourSolved(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}),
                       CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUUUUUUUUUUUUUURRRRRRRRRRRRRRRRFFFFFFFFFFFFFFFFDDDDDDDDDDDDDDDDLLLLLLLLLLLLLLLLBBBBBBBBBBBBBBBB"), asString(Orbit64.Net.toFacelets(4, orbits)))

@Test
def faceletsOfFourByFourU(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), WingCoord(Vector#{2, 0, 3, 1, 20, 5, 6, 7, 4, 9, 10, 11, 12, 13, 14, 15, 8, 17, 18, 19, 16, 21, 22, 23}),
                       CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUUUUUUUUUUUUUUBBBBRRRRRRRRRRRRRRRRFFFFFFFFFFFFDDDDDDDDDDDDDDDDFFFFLLLLLLLLLLLLLLLLBBBBBBBBBBBB"), asString(Orbit64.Net.toFacelets(4, orbits)))

@Test
def faceletsOfFourByFourR(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{4, 1, 2, 0, 7, 5, 6, 3}, Vector#{2, 0, 0, 1, 1, 0, 0, 2}), WingCoord(Vector#{0, 9, 2, 3, 6, 4, 7, 5, 8, 13, 10, 11, 12, 22, 14, 15, 16, 17, 18, 19, 20, 21, 1, 23}),
                       CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUFUUUFUUUFUUUFRRRRRRRRRRRRRRRRFFFDFFFDFFFDFFFDDDDBDDDBDDDBDDDBLLLLLLLLLLLLLLLLUBBBUBBBUBBBUBBB"), asString(Orbit64.Net.toFacelets(4, orbits)))

@Test
def faceletsOfFourByFourF(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{1, 5, 2, 3, 0, 4, 6, 7}, Vector#{1, 2, 0, 0, 2, 1, 0, 0}), WingCoord(Vector#{0, 1, 2, 17, 4, 5, 3, 7, 10, 8, 11, 9, 6, 13, 14, 15, 16, 12, 18, 19, 20, 21, 22, 23}),
                       CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUUUUUUUUUULLLLURRRURRRURRRURRRFFFFFFFFFFFFFFFFRRRRDDDDDDDDDDDDLLLDLLLDLLLDLLLDBBBBBBBBBBBBBBBB"), asString(Orbit64.Net.toFacelets(4, orbits)))

@Test
def faceletsOfFourByFourUw(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), WingCoord(Vector#{2, 0, 3, 1, 20, 21, 6, 7, 4, 5, 10, 11, 12, 13, 14, 15, 8, 9, 18, 19, 16, 17, 22, 23}),
                       CenterCoord(Vector#{0, 0, 0, 0, 5, 5, 1, 1, 1, 1, 2, 2, 3, 3, 3, 3, 2, 2, 4, 4, 4, 4, 5, 5})};
    Assert.assertEq(expected = Ok("UUUUUUUUUUUUUUUUBBBBBBBBRRRRRRRRRRRRRRRRFFFFFFFFDDDDDDDDDDDDDDDDFFFFFFFFLLLLLLLLLLLLLLLLBBBBBBBB"), asString(Orbit64.Net.toFacelets(4, orbits)))

@Test
def faceletsOfFourByFourRw(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{4, 1, 2, 0, 7, 5, 6, 3}, Vector#{2, 0, 0, 1, 1, 0, 0, 2}), WingCoord(Vector#{0, 9, 2, 11, 6, 4, 7, 5, 8, 13, 10, 15, 12, 22, 14, 20, 16, 17, 18, 19, 3, 21, 1, 23}),
                       CenterCoord(Vector#{0, 2, 0, 2, 1, 1, 1, 1, 2, 3, 2, 3, 3, 5, 3, 5, 4, 4, 4, 4, 0, 5, 0, 5})};
    Assert.assertEq(expected = Ok("UUFFUUFFUUFFUUFFRRRRRRRRRRRRRRRRFFDDFFDDFFDDFFDDDDBBDDBBDDBBDDBBLLLLLLLLLLLLLLLLUUBBUUBBUUBBUUBB"), asString(Orbit64.Net.toFacelets(4, orbits)))

@Test
def faceletsOfFourByFour2R(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), WingCoord(Vector#{0, 1, 2, 11, 4, 5, 6, 7, 8, 9, 10, 15, 12, 13, 14, 20, 16, 17, 18, 19, 3, 21, 22, 23}),
                       CenterCoord(Vector#{0, 2, 0, 2, 1, 1, 1, 1, 2, 3, 2, 3, 3, 5, 3, 5, 4, 4, 4, 4, 0, 5, 0, 5})};
    Assert.assertEq(expected = Ok("UUFUUUFUUUFUUUFURRRRRRRRRRRRRRRRFFDFFFDFFFDFFFDFDDBDDDBDDDBDDDBDLLLLLLLLLLLLLLLLBUBBBUBBBUBBBUBB"), asString(Orbit64.Net.toFacelets(4, orbits)))

@Test
def faceletsOfFiveByFiveSolved(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), MidgeCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
                       WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUUUUUUUUUUUUUUUUUUUUUUURRRRRRRRRRRRRRRRRRRRRRRRRFFFFFFFFFFFFFFFFFFFFFFFFFDDDDDDDDDDDDDDDDDDDDDDDDDLLLLLLLLLLLLLLLLLLLLLLLLLBBBBBBBBBBBBBBBBBBBBBBBBB"), asString(Orbit64.Net.toFacelets(5, orbits)))

@Test
def faceletsOfFiveByFiveU(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), MidgeCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
                       WingCoord(Vector#{2, 0, 3, 1, 20, 5, 6, 7, 4, 9, 10, 11, 12, 13, 14, 15, 8, 17, 18, 19, 16, 21, 22, 23}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUUUUUUUUUUUUUUUUUUUUUUUBBBBBRRRRRRRRRRRRRRRRRRRRRRRRRFFFFFFFFFFFFFFFFFFFFDDDDDDDDDDDDDDDDDDDDDDDDDFFFFFLLLLLLLLLLLLLLLLLLLLLLLLLBBBBBBBBBBBBBBBBBBBB"), asString(Orbit64.Net.toFacelets(5, orbits)))

@Test
def faceletsOfFiveByFiveR(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{4, 1, 2, 0, 7, 5, 6, 3}, Vector#{2, 0, 0, 1, 1, 0, 0, 2}), MidgeCoord(Vector#{8, 1, 2, 3, 11, 5, 6, 7, 4, 9, 10, 0}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
                       WingCoord(Vector#{0, 9, 2, 3, 6, 4, 7, 5, 8, 13, 10, 11, 12, 22, 14, 15, 16, 17, 18, 19, 20, 21, 1, 23}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUUFUUUUFUUUUFUUUUFUUUUFRRRRRRRRRRRRRRRRRRRRRRRRRFFFFDFFFFDFFFFDFFFFDFFFFDDDDDBDDDDBDDDDBDDDDBDDDDBLLLLLLLLLLLLLLLLLLLLLLLLLUBBBBUBBBBUBBBBUBBBBUBBBB"), asString(Orbit64.Net.toFacelets(5, orbits)))

@Test
def faceletsOfFiveByFiveF(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{1, 5, 2, 3, 0, 4, 6, 7}, Vector#{1, 2, 0, 0, 2, 1, 0, 0}), MidgeCoord(Vector#{0, 9, 2, 3, 4, 8, 6, 7, 1, 5, 10, 11}, Vector#{0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0}),
                       WingCoord(Vector#{0, 1, 2, 17, 4, 5, 3, 7, 10, 8, 11, 9, 6, 13, 14, 15, 16, 12, 18, 19, 20, 21, 22, 23}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUUUUUUUUUUUUUUUUUULLLLLURRRRURRRRURRRRURRRRURRRRFFFFFFFFFFFFFFFFFFFFFFFFFRRRRRDDDDDDDDDDDDDDDDDDDDLLLLDLLLLDLLLLDLLLLDLLLLDBBBBBBBBBBBBBBBBBBBBBBBBB"), asString(Orbit64.Net.toFacelets(5, orbits)))

@Test
def faceletsOfFiveByFiveUw(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), MidgeCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
                       WingCoord(Vector#{2, 0, 3, 1, 20, 21, 6, 7, 4, 5, 10, 11, 12, 13, 14, 15, 8, 9, 18, 19, 16, 17, 22, 23}), CenterCoord(Vector#{0, 0, 0, 0, 5, 5, 1, 1, 1, 1, 2, 2, 3, 3, 3, 3, 2, 2, 4, 4, 4, 4, 5, 5}), CenterCoord(Vector#{0, 0, 0, 0, 5, 1, 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 2, 4, 4, 4, 4, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUUUUUUUUUUUUUUUUUUUUUUUBBBBBBBBBBRRRRRRRRRRRRRRRRRRRRRRRRRFFFFFFFFFFFFFFFDDDDDDDDDDDDDDDDDDDDDDDDDFFFFFFFFFFLLLLLLLLLLLLLLLLLLLLLLLLLBBBBBBBBBBBBBBB"), asString(Orbit64.Net.toFacelets(5, orbits)))

@Test
def faceletsOfFiveByFiveRw(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{4, 1, 2, 0, 7, 5, 6, 3}, Vector#{2, 0, 0, 1, 1, 0, 0, 2}), MidgeCoord(Vector#{8, 1, 2, 3, 11, 5, 6, 7, 4, 9, 10, 0}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
                       WingCoord(Vector#{0, 9, 2, 11, 6, 4, 7, 5, 8, 13, 10, 15, 12, 22, 14, 20, 16, 17, 18, 19, 3, 21, 1, 23}), CenterCoord(Vector#{0, 2, 0, 2, 1, 1, 1, 1, 2, 3, 2, 3, 3, 5, 3, 5, 4, 4, 4, 4, 0, 5, 0, 5}), CenterCoord(Vector#{0, 0, 2, 0, 1, 1, 1, 1, 2, 2, 3, 2, 3, 3, 5, 3, 4, 4, 4, 4, 5, 0, 5, 5})};
    Assert.assertEq(expected = Ok("UUUFFUUUFFUUUFFUUUFFUUUFFRRRRRRRRRRRRRRRRRRRRRRRRRFFFDDFFFDDFFFDDFFFDDFFFDDDDDBBDDDBBDDDBBDDDBBDDDBBLLLLLLLLLLLLLLLLLLLLLLLLLUUBBBUUBBBUUBBBUUBBBUUBBB"), asString(Orbit64.Net.toFacelets(5, orbits)))

@Test
def faceletsOfFiveByFive2R(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), MidgeCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
                       WingCoord(Vector#{0, 1, 2, 11, 4, 5, 6, 7, 8, 9, 10, 15, 12, 13, 14, 20, 16, 17, 18, 19, 3, 21, 22, 23}), CenterCoord(Vector#{0, 2, 0, 2, 1, 1, 1, 1, 2, 3, 2, 3, 3, 5, 3, 5, 4, 4, 4, 4, 0, 5, 0, 5}), CenterCoord(Vector#{0, 0, 2, 0, 1, 1, 1, 1, 2, 2, 3, 2, 3, 3, 5, 3, 4, 4, 4, 4, 5, 0, 5, 5})};
    Assert.assertEq(expected = Ok("UUUFUUUUFUUUUFUUUUFUUUUFURRRRRRRRRRRRRRRRRRRRRRRRRFFFDFFFFDFFFFDFFFFDFFFFDFDDDBDDDDBDDDDBDDDDBDDDDBDLLLLLLLLLLLLLLLLLLLLLLLLLBUBBBBUBBBBUBBBBUBBBBUBBB"), asString(Orbit64.Net.toFacelets(5, orbits)))
