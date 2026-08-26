//
// Cross-project fixtures: the facelet layer, against `flix-cube`.
//
// `Orbit64.Net.toFacelets` and `flix-cube`'s `BigCube` use the same facelet
// layout -- `face * n * n + row * n + col`, faces `U R F D L B` -- which makes
// facelets the one place two projects with different slot orders can be
// compared directly.
//
// The expected strings below were produced by `BigCube.showFacelets` after
// applying the named turn to a solved cube, in that project, by an engine that
// shares no code with this one. They pass only if this project's hand-derived
// slot tables and that project's turn arithmetic describe the same cube.
//
// Note what this does and does not establish. It shows the tables are right
// about geometry. It says nothing about whether some third implementation
// numbers its slots the way `Orbit64.Net.convention(n)` does -- that is not a
// fact facelets can carry.
//

use Orbit64.Coord.Coord.{CornerCoord, MidgeCoord, WingCoord, CenterCoord}

def asString(r: Result[String, Vector[Int32]]): Result[String, String] =
    Result.map(fs -> fs |> Vector.map(f ->
        Vector.get(f, Vector#{"U", "R", "F", "D", "L", "B"})) |> Vector.join(""), r)

@Test
def faceletsOfFourByFourSolved(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUUUUUUUUUUUUUURRRRRRRRRRRRRRRRFFFFFFFFFFFFFFFFDDDDDDDDDDDDDDDDLLLLLLLLLLLLLLLLBBBBBBBBBBBBBBBB"), asString(Orbit64.Net.toFacelets(4, orbits)))

@Test
def faceletsOfFourByFourU(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), WingCoord(Vector#{1, 2, 3, 0, 16, 5, 6, 7, 4, 9, 10, 11, 8, 13, 14, 15, 12, 17, 18, 19, 20, 21, 22, 23}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUUUUUUUUUUUUUUBBBBRRRRRRRRRRRRRRRRFFFFFFFFFFFFDDDDDDDDDDDDDDDDFFFFLLLLLLLLLLLLLLLLBBBBBBBBBBBB"), asString(Orbit64.Net.toFacelets(4, orbits)))

@Test
def faceletsOfFourByFourR(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{1, 7, 2, 3, 0, 5, 6, 4}, Vector#{1, 2, 0, 0, 2, 0, 0, 1}), WingCoord(Vector#{0, 19, 2, 3, 4, 5, 6, 7, 8, 1, 10, 11, 13, 14, 15, 12, 16, 17, 18, 21, 20, 9, 22, 23}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUFUUUFUUUFUUUFRRRRRRRRRRRRRRRRFFFDFFFDFFFDFFFDDDDBDDDBDDDBDDDBLLLLLLLLLLLLLLLLUBBBUBBBUBBBUBBB"), asString(Orbit64.Net.toFacelets(4, orbits)))

@Test
def faceletsOfFourByFourF(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{0, 2, 6, 3, 4, 5, 7, 1}, Vector#{0, 1, 2, 0, 0, 0, 1, 2}), WingCoord(Vector#{7, 1, 2, 3, 4, 5, 6, 22, 8, 9, 10, 11, 12, 0, 14, 15, 17, 18, 19, 16, 20, 21, 13, 23}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUUUUUUUUUULLLLURRRURRRURRRURRRFFFFFFFFFFFFFFFFRRRRDDDDDDDDDDDDLLLDLLLDLLLDLLLDBBBBBBBBBBBBBBBB"), asString(Orbit64.Net.toFacelets(4, orbits)))

@Test
def faceletsOfFourByFourUw(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), WingCoord(Vector#{1, 2, 3, 0, 16, 17, 6, 7, 4, 5, 10, 11, 8, 9, 14, 15, 12, 13, 18, 19, 20, 21, 22, 23}), CenterCoord(Vector#{0, 0, 0, 0, 4, 4, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 5, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUUUUUUUUUUUUUUBBBBBBBBRRRRRRRRRRRRRRRRFFFFFFFFDDDDDDDDDDDDDDDDFFFFFFFFLLLLLLLLLLLLLLLLBBBBBBBB"), asString(Orbit64.Net.toFacelets(4, orbits)))

@Test
def faceletsOfFourByFourRw(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{1, 7, 2, 3, 0, 5, 6, 4}, Vector#{1, 2, 0, 0, 2, 0, 0, 1}), WingCoord(Vector#{0, 19, 16, 3, 4, 5, 6, 7, 8, 1, 2, 11, 13, 14, 15, 12, 22, 17, 18, 21, 20, 9, 10, 23}), CenterCoord(Vector#{0, 4, 4, 0, 1, 1, 1, 1, 2, 0, 0, 2, 3, 3, 3, 3, 5, 4, 4, 5, 5, 2, 2, 5})};
    Assert.assertEq(expected = Ok("UUFFUUFFUUFFUUFFRRRRRRRRRRRRRRRRFFDDFFDDFFDDFFDDDDBBDDBBDDBBDDBBLLLLLLLLLLLLLLLLUUBBUUBBUUBBUUBB"), asString(Orbit64.Net.toFacelets(4, orbits)))

@Test
def faceletsOfFourByFourTwor(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), WingCoord(Vector#{0, 1, 16, 3, 4, 5, 6, 7, 8, 9, 2, 11, 12, 13, 14, 15, 22, 17, 18, 19, 20, 21, 10, 23}), CenterCoord(Vector#{0, 4, 4, 0, 1, 1, 1, 1, 2, 0, 0, 2, 3, 3, 3, 3, 5, 4, 4, 5, 5, 2, 2, 5})};
    Assert.assertEq(expected = Ok("UUFUUUFUUUFUUUFURRRRRRRRRRRRRRRRFFDFFFDFFFDFFFDFDDBDDDBDDDBDDDBDLLLLLLLLLLLLLLLLBUBBBUBBBUBBBUBB"), asString(Orbit64.Net.toFacelets(4, orbits)))

@Test
def faceletsOfFiveByFiveSolved(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), MidgeCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
                       WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUUUUUUUUUUUUUUUUUUUUUUURRRRRRRRRRRRRRRRRRRRRRRRRFFFFFFFFFFFFFFFFFFFFFFFFFDDDDDDDDDDDDDDDDDDDDDDDDDLLLLLLLLLLLLLLLLLLLLLLLLLBBBBBBBBBBBBBBBBBBBBBBBBB"), asString(Orbit64.Net.toFacelets(5, orbits)))

@Test
def faceletsOfFiveByFiveU(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), MidgeCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
                       WingCoord(Vector#{1, 2, 3, 0, 4, 17, 6, 7, 8, 5, 10, 11, 12, 9, 14, 15, 16, 13, 18, 19, 20, 21, 22, 23}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUUUUUUUUUUUUUUUUUUUUUUUBBBBBRRRRRRRRRRRRRRRRRRRRRRRRRFFFFFFFFFFFFFFFFFFFFDDDDDDDDDDDDDDDDDDDDDDDDDFFFFFLLLLLLLLLLLLLLLLLLLLLLLLLBBBBBBBBBBBBBBBBBBBB"), asString(Orbit64.Net.toFacelets(5, orbits)))

@Test
def faceletsOfFiveByFiveR(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{4, 1, 2, 0, 7, 5, 6, 3}, Vector#{2, 0, 0, 1, 1, 0, 0, 2}), MidgeCoord(Vector#{8, 1, 2, 3, 11, 5, 6, 7, 4, 9, 10, 0}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
                       WingCoord(Vector#{8, 1, 2, 3, 5, 6, 7, 4, 20, 9, 10, 11, 12, 13, 14, 15, 16, 17, 0, 19, 18, 21, 22, 23}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUUFUUUUFUUUUFUUUUFUUUUFRRRRRRRRRRRRRRRRRRRRRRRRRFFFFDFFFFDFFFFDFFFFDFFFFDDDDDBDDDDBDDDDBDDDDBDDDDBLLLLLLLLLLLLLLLLLLLLLLLLLUBBBBUBBBBUBBBBUBBBBUBBBB"), asString(Orbit64.Net.toFacelets(5, orbits)))

@Test
def faceletsOfFiveByFiveF(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{1, 5, 2, 3, 0, 4, 6, 7}, Vector#{1, 2, 0, 0, 2, 1, 0, 0}), MidgeCoord(Vector#{0, 9, 2, 3, 4, 8, 6, 7, 1, 5, 10, 11}, Vector#{0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0}),
                       WingCoord(Vector#{0, 1, 2, 12, 4, 5, 3, 7, 9, 10, 11, 8, 21, 13, 14, 15, 16, 17, 18, 19, 20, 6, 22, 23}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}), CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUUUUUUUUUUUUUUUUUULLLLLURRRRURRRRURRRRURRRRURRRRFFFFFFFFFFFFFFFFFFFFFFFFFRRRRRDDDDDDDDDDDDDDDDDDDDLLLLDLLLLDLLLLDLLLLDLLLLDBBBBBBBBBBBBBBBBBBBBBBBBB"), asString(Orbit64.Net.toFacelets(5, orbits)))

@Test
def faceletsOfFiveByFiveUw(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), MidgeCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
                       WingCoord(Vector#{1, 2, 3, 0, 16, 17, 6, 7, 4, 5, 10, 11, 8, 9, 14, 15, 12, 13, 18, 19, 20, 21, 22, 23}), CenterCoord(Vector#{0, 0, 0, 0, 4, 4, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 5, 5, 5, 5}), CenterCoord(Vector#{0, 0, 0, 0, 4, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 5, 5, 5, 5})};
    Assert.assertEq(expected = Ok("UUUUUUUUUUUUUUUUUUUUUUUUUBBBBBBBBBBRRRRRRRRRRRRRRRRRRRRRRRRRFFFFFFFFFFFFFFFDDDDDDDDDDDDDDDDDDDDDDDDDFFFFFFFFFFLLLLLLLLLLLLLLLLLLLLLLLLLBBBBBBBBBBBBBBB"), asString(Orbit64.Net.toFacelets(5, orbits)))

@Test
def faceletsOfFiveByFiveRw(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{4, 1, 2, 0, 7, 5, 6, 3}, Vector#{2, 0, 0, 1, 1, 0, 0, 2}), MidgeCoord(Vector#{8, 1, 2, 3, 11, 5, 6, 7, 4, 9, 10, 0}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
                       WingCoord(Vector#{8, 1, 2, 11, 5, 6, 7, 4, 20, 9, 10, 23, 12, 13, 14, 15, 16, 3, 0, 19, 18, 21, 22, 17}), CenterCoord(Vector#{2, 0, 0, 2, 1, 1, 1, 1, 5, 2, 2, 5, 3, 3, 3, 3, 4, 0, 0, 4, 4, 5, 5, 4}), CenterCoord(Vector#{0, 0, 0, 2, 1, 1, 1, 1, 2, 2, 2, 5, 3, 3, 3, 3, 4, 0, 4, 4, 5, 5, 5, 4})};
    Assert.assertEq(expected = Ok("UUUFFUUUFFUUUFFUUUFFUUUFFRRRRRRRRRRRRRRRRRRRRRRRRRFFFDDFFFDDFFFDDFFFDDFFFDDDDDBBDDDBBDDDBBDDDBBDDDBBLLLLLLLLLLLLLLLLLLLLLLLLLUUBBBUUBBBUUBBBUUBBBUUBBB"), asString(Orbit64.Net.toFacelets(5, orbits)))

@Test
def faceletsOfFiveByFiveTwor(): Unit \ Assert =
    let orbits = List#{CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}), MidgeCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
                       WingCoord(Vector#{0, 1, 2, 11, 4, 5, 6, 7, 8, 9, 10, 23, 12, 13, 14, 15, 16, 3, 18, 19, 20, 21, 22, 17}), CenterCoord(Vector#{2, 0, 0, 2, 1, 1, 1, 1, 5, 2, 2, 5, 3, 3, 3, 3, 4, 0, 0, 4, 4, 5, 5, 4}), CenterCoord(Vector#{0, 0, 0, 2, 1, 1, 1, 1, 2, 2, 2, 5, 3, 3, 3, 3, 4, 0, 4, 4, 5, 5, 5, 4})};
    Assert.assertEq(expected = Ok("UUUFUUUUFUUUUFUUUUFUUUUFURRRRRRRRRRRRRRRRRRRRRRRRRFFFDFFFFDFFFFDFFFFDFFFFDFDDDBDDDDBDDDDBDDDDBDDDDBDLLLLLLLLLLLLLLLLLLLLLLLLLBUBBBBUBBBBUBBBBUBBBBUBBB"), asString(Orbit64.Net.toFacelets(5, orbits)))
