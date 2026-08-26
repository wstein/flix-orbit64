//
// The 4x4x4 display convention, checked against an independent model.
//
// `Orbit64.Net` draws a 4x4x4 by declaring that its vectors are ordered the way
// the twsearch 4x4x4 KPuzzle definition orders them. These fixtures are the
// evidence that the declaration is implemented faithfully: the states below are
// produced by applying move sequences to a solved cube in a separate geometric
// model, and the nets are that model's own output, not this one's.
//
// The mapping itself was not transcribed. It is the unique correspondence that
// reproduces the twsearch definition's move permutations, and it was checked
// against moves that were not used to find it.
//

use Orbit64.Coord.Coord.{CornerCoord, WingCoord, CenterCoord}


///
/// `(solved)` applied to a solved cube.
///
@Test
def fourByFourSolvedDrawsSixSolidFaces(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})
    };
    let expected = "                U  U  U  U \n                U  U  U  U \n                U  U  U  U \n                U  U  U  U \n\n L  L  L  L     F  F  F  F     R  R  R  R     B  B  B  B \n L  L  L  L     F  F  F  F     R  R  R  R     B  B  B  B \n L  L  L  L     F  F  F  F     R  R  R  R     B  B  B  B \n L  L  L  L     F  F  F  F     R  R  R  R     B  B  B  B \n\n                D  D  D  D \n                D  D  D  D \n                D  D  D  D \n                D  D  D  D ";
    Assert.assertEq(expected = Some(expected), Orbit64.Net.draw(4, orbits, false));
    // and the same state must survive a round trip through the codec
    match Orbit64.encode(4, orbits) {
        case Err(e) => Assert.assertEq(expected = "encodes", e)
        case Ok(t)  => Assert.assertEq(expected = Ok(orbits), Orbit64.decode(4, t))
    }

///
/// `R 2R U U L L L` applied to a solved cube.
///
@Test
def fourByFourWideTurnAndRotation(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{2, 3, 6, 1, 0, 7, 5, 4}, Vector#{0, 0, 1, 0, 2, 0, 2, 1}),
        WingCoord(Vector#{16, 3, 0, 17, 7, 13, 5, 6, 22, 1, 2, 19, 4, 14, 15, 12, 8, 23, 18, 21, 20, 9, 10, 11}),
        CenterCoord(Vector#{4, 0, 0, 4, 1, 1, 1, 1, 2, 0, 0, 2, 3, 3, 3, 3, 5, 4, 4, 5, 5, 2, 2, 5})
    };
    let expected = "                U  F  U  U \n                F  F  U  U \n                F  F  U  U \n                F  F  U  U \n\n R  L  L  L     D  U  B  B     L  L  L  L     F  F  D  F \n R  L  L  L     D  F  D  D     R  R  R  R     U  U  B  F \n R  L  L  L     D  F  D  D     R  R  R  R     U  U  B  F \n R  L  L  L     D  F  D  D     R  R  R  R     U  U  B  F \n\n                B  D  B  B \n                B  D  B  B \n                B  D  B  B \n                D  D  B  B ";
    Assert.assertEq(expected = Some(expected), Orbit64.Net.draw(4, orbits, false));
    // and the same state must survive a round trip through the codec
    match Orbit64.encode(4, orbits) {
        case Err(e) => Assert.assertEq(expected = "encodes", e)
        case Ok(t)  => Assert.assertEq(expected = Ok(orbits), Orbit64.decode(4, t))
    }

///
/// `R U 2R F L D B U R 2R F U` applied to a solved cube.
///
@Test
def fourByFourATwelveMoveScramble(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{2, 1, 7, 4, 3, 5, 0, 6}, Vector#{1, 0, 1, 2, 0, 1, 2, 2}),
        WingCoord(Vector#{22, 8, 7, 16, 0, 13, 3, 23, 17, 12, 11, 4, 5, 2, 9, 1, 19, 10, 14, 18, 6, 15, 21, 20}),
        CenterCoord(Vector#{5, 4, 0, 4, 1, 1, 1, 1, 0, 4, 0, 2, 3, 3, 3, 3, 4, 5, 2, 5, 2, 0, 2, 5})
    };
    let expected = "                R  L  L  L \n                F  F  U  B \n                F  D  F  B \n                R  D  R  U \n\n B  U  U  F     D  F  F  F     R  U  L  F     U  F  F  D \n R  L  L  D     B  D  F  B     U  R  R  U     R  F  U  F \n U  L  L  D     L  B  D  F     D  R  R  U     R  U  B  L \n B  U  B  R     U  R  R  F     D  B  B  L     B  B  D  D \n\n                B  D  D  L \n                D  D  B  R \n                L  B  U  R \n                L  L  L  U ";
    Assert.assertEq(expected = Some(expected), Orbit64.Net.draw(4, orbits, false));
    // and the same state must survive a round trip through the codec
    match Orbit64.encode(4, orbits) {
        case Err(e) => Assert.assertEq(expected = "encodes", e)
        case Ok(t)  => Assert.assertEq(expected = Ok(orbits), Orbit64.decode(4, t))
    }
