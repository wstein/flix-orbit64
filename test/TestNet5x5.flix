//
// The 5x5x5 display convention, checked against an independent model.
//
// `orbit64-5x5-draft@1` keeps Kociemba's corner and midge numbering, so a
// 5x5x5 reads as a 3x3x3 with more orbits, and derives its wings and both
// centre orbits from the twsearch 5x5x5 move model.
//
// The fourth entry of the list is the X-centres and the fifth the plus-centres.
// Nothing in the type says so -- both are `CenterCoord` -- which is why the
// wide-turn case below matters: after `Uw` the two vectors differ from each
// other, so swapping them fails rather than passing quietly.
//
// The states are produced by applying moves in a separate geometric model, and
// the nets are that model's output, not this one's.
//

use Orbit64.Coord.Coord.{CornerCoord, MidgeCoord, WingCoord, CenterCoord}

///
/// `(solved)`
///
@Test
def fiveByFiveSolvedDrawsSixSolidFaces(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        MidgeCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
        WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})
    };
    let expected = "                U  U  U  U  U \n                U  U  U  U  U \n                U  U  U  U  U \n                U  U  U  U  U \n                U  U  U  U  U \n L  L  L  L  L  F  F  F  F  F  R  R  R  R  R  B  B  B  B  B \n L  L  L  L  L  F  F  F  F  F  R  R  R  R  R  B  B  B  B  B \n L  L  L  L  L  F  F  F  F  F  R  R  R  R  R  B  B  B  B  B \n L  L  L  L  L  F  F  F  F  F  R  R  R  R  R  B  B  B  B  B \n L  L  L  L  L  F  F  F  F  F  R  R  R  R  R  B  B  B  B  B \n                D  D  D  D  D \n                D  D  D  D  D \n                D  D  D  D  D \n                D  D  D  D  D \n                D  D  D  D  D ";
    Assert.assertEq(expected = Some(expected), Orbit64.Net.draw(5, orbits, false));
    match Orbit64.encode(5, orbits) {
        case Err(e) => Assert.assertEq(expected = "encodes", e)
        case Ok(t)  => Assert.assertEq(expected = Ok(orbits), Orbit64.decode(5, t))
    }

///
/// `Uw`
///
@Test
def fiveByFiveAWideTurnTellsTheCentreOrbitsApart(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        MidgeCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
        WingCoord(Vector#{1, 2, 3, 0, 16, 17, 6, 7, 4, 5, 10, 11, 8, 9, 14, 15, 12, 13, 18, 19, 20, 21, 22, 23}),
        CenterCoord(Vector#{0, 0, 0, 0, 4, 4, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 4, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 5, 5, 5, 5})
    };
    let expected = "                U  U  U  U  U \n                U  U  U  U  U \n                U  U  U  U  U \n                U  U  U  U  U \n                U  U  U  U  U \n F  F  F  F  F  R  R  R  R  R  B  B  B  B  B  L  L  L  L  L \n F  F  F  F  F  R  R  R  R  R  B  B  B  B  B  L  L  L  L  L \n L  L  L  L  L  F  F  F  F  F  R  R  R  R  R  B  B  B  B  B \n L  L  L  L  L  F  F  F  F  F  R  R  R  R  R  B  B  B  B  B \n L  L  L  L  L  F  F  F  F  F  R  R  R  R  R  B  B  B  B  B \n                D  D  D  D  D \n                D  D  D  D  D \n                D  D  D  D  D \n                D  D  D  D  D \n                D  D  D  D  D ";
    Assert.assertEq(expected = Some(expected), Orbit64.Net.draw(5, orbits, false));
    match Orbit64.encode(5, orbits) {
        case Err(e) => Assert.assertEq(expected = "encodes", e)
        case Ok(t)  => Assert.assertEq(expected = Ok(orbits), Orbit64.decode(5, t))
    }

///
/// `2R Uw F F F`
///
@Test
def fiveByFiveAShortScramble(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{4, 3, 1, 2, 5, 0, 6, 7}, Vector#{1, 2, 0, 0, 2, 1, 0, 0}),
        MidgeCoord(Vector#{3, 8, 1, 2, 4, 9, 6, 7, 5, 0, 10, 11}, Vector#{0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0}),
        WingCoord(Vector#{1, 2, 11, 6, 16, 3, 21, 7, 23, 4, 5, 10, 0, 9, 14, 15, 12, 13, 18, 19, 20, 8, 22, 17}),
        CenterCoord(Vector#{0, 0, 2, 2, 4, 0, 1, 1, 5, 1, 1, 2, 5, 2, 3, 3, 3, 3, 0, 4, 4, 5, 5, 4}),
        CenterCoord(Vector#{0, 0, 2, 0, 4, 1, 1, 1, 5, 1, 2, 2, 2, 3, 3, 3, 3, 0, 4, 4, 5, 5, 5, 4})
    };
    let expected = "                U  U  U  U  U \n                U  U  U  U  U \n                U  U  U  U  U \n                F  F  F  F  F \n                B  B  R  R  R \n F  F  F  D  U  R  R  F  F  F  D  U  B  B  B  L  L  L  L  L \n F  F  F  D  U  R  R  D  D  D  B  U  B  B  B  L  L  L  L  L \n L  L  L  L  U  R  R  F  F  F  D  R  R  R  R  B  U  B  B  B \n L  L  L  L  U  R  R  F  F  F  D  R  R  R  R  B  U  B  B  B \n L  L  L  L  U  R  R  F  F  F  D  R  R  R  R  B  U  B  B  B \n                F  F  L  L  L \n                D  D  D  B  D \n                D  D  D  B  D \n                D  D  D  B  D \n                D  D  D  B  D ";
    Assert.assertEq(expected = Some(expected), Orbit64.Net.draw(5, orbits, false));
    match Orbit64.encode(5, orbits) {
        case Err(e) => Assert.assertEq(expected = "encodes", e)
        case Ok(t)  => Assert.assertEq(expected = Ok(orbits), Orbit64.decode(5, t))
    }

///
/// `R Uw 2R F Lw D 2F U Bw R 2U F`
///
@Test
def fiveByFiveALongerScramble(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{4, 7, 6, 2, 5, 3, 1, 0}, Vector#{1, 2, 0, 1, 2, 2, 0, 1}),
        MidgeCoord(Vector#{8, 1, 9, 0, 11, 4, 7, 6, 3, 5, 10, 2}, Vector#{1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0}),
        WingCoord(Vector#{6, 16, 20, 17, 14, 11, 1, 18, 12, 3, 21, 8, 23, 19, 7, 10, 9, 0, 5, 22, 4, 13, 2, 15}),
        CenterCoord(Vector#{1, 4, 2, 1, 0, 0, 3, 4, 2, 0, 5, 3, 1, 0, 2, 2, 5, 4, 5, 5, 4, 1, 3, 3}),
        CenterCoord(Vector#{1, 2, 2, 0, 0, 1, 4, 4, 0, 5, 1, 0, 2, 4, 3, 2, 3, 4, 5, 3, 1, 5, 3, 5})
    };
    let expected = "                D  B  R  R  B \n                D  B  R  R  R \n                L  F  U  U  R \n                D  F  F  R  D \n                R  F  F  B  R \n B  B  F  R  D  B  U  U  U  F  D  F  F  F  L  U  U  U  L  L \n U  U  F  R  D  B  U  U  F  L  F  U  U  U  L  B  B  L  D  F \n B  B  L  F  F  D  D  F  U  B  U  R  R  B  L  U  B  B  L  L \n R  F  L  F  F  D  D  R  L  B  U  L  B  B  U  R  D  D  D  D \n L  L  B  F  R  U  U  R  F  F  D  B  B  B  U  R  D  D  D  F \n                B  L  D  R  L \n                L  R  R  B  R \n                D  D  D  D  R \n                U  L  L  L  R \n                U  L  L  L  F ";
    Assert.assertEq(expected = Some(expected), Orbit64.Net.draw(5, orbits, false));
    match Orbit64.encode(5, orbits) {
        case Err(e) => Assert.assertEq(expected = "encodes", e)
        case Ok(t)  => Assert.assertEq(expected = Ok(orbits), Orbit64.decode(5, t))
    }
