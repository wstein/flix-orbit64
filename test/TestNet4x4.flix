//
// The 4x4x4 display convention, checked against an independent model.
//
// `Orbit64.Net` draws a 4x4x4 under `orbit64-4x4-draft@1`: corners in the
// standard URF UFL ULB UBR DFR DLF DBL DRB order, wings and centres ordered by
// the facelet index of each piece's reference sticker. Every table below is
// derived from cube geometry -- no external puzzle definition is read -- and
// the states here were produced by applying moves in a separate model.
//

use Orbit64.Coord.Coord.{CornerCoord, WingCoord, CenterCoord}

///
/// `solved`
///
@Test
def fourByFourSolved(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})
    };
    Assert.assertEq(expected = Ok("                U  U  U  U \n                U  U  U  U \n                U  U  U  U \n                U  U  U  U \n\n L  L  L  L     F  F  F  F     R  R  R  R     B  B  B  B \n L  L  L  L     F  F  F  F     R  R  R  R     B  B  B  B \n L  L  L  L     F  F  F  F     R  R  R  R     B  B  B  B \n L  L  L  L     F  F  F  F     R  R  R  R     B  B  B  B \n\n                D  D  D  D \n                D  D  D  D \n                D  D  D  D \n                D  D  D  D "), Orbit64.Net.draw(4, orbits, false));
    match Orbit64.State.encode(4, orbits) {
        case Err(e) => Assert.assertEq(expected = "encodes", e)
        case Ok(t)  => Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(4, t))
    }

///
/// `Rw U2`
///
@Test
def fourByFourRwU2(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{2, 0, 4, 1, 7, 5, 6, 3}, Vector#{0, 1, 2, 0, 1, 0, 0, 2}),
        WingCoord(Vector#{11, 2, 9, 0, 16, 4, 7, 5, 3, 13, 10, 15, 12, 22, 14, 20, 6, 17, 18, 19, 8, 21, 1, 23}),
        CenterCoord(Vector#{2, 0, 2, 0, 1, 1, 1, 1, 2, 3, 2, 3, 3, 5, 3, 5, 4, 4, 4, 4, 0, 5, 0, 5})
    };
    Assert.assertEq(expected = Ok("                F  F  U  U \n                F  F  U  U \n                F  F  U  U \n                F  F  U  U \n\n R  R  R  R     U  U  B  B     L  L  L  L     F  F  D  D \n L  L  L  L     F  F  D  D     R  R  R  R     U  U  B  B \n L  L  L  L     F  F  D  D     R  R  R  R     U  U  B  B \n L  L  L  L     F  F  D  D     R  R  R  R     U  U  B  B \n\n                D  D  B  B \n                D  D  B  B \n                D  D  B  B \n                D  D  B  B "), Orbit64.Net.draw(4, orbits, false));
    match Orbit64.State.encode(4, orbits) {
        case Err(e) => Assert.assertEq(expected = "encodes", e)
        case Ok(t)  => Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(4, t))
    }

///
/// `R U 2R F D 2F U 3R`
///
@Test
def fourByFourRU2RFD2FU3R(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{2, 4, 5, 1, 7, 6, 3, 0}, Vector#{0, 0, 2, 0, 2, 0, 2, 0}),
        WingCoord(Vector#{3, 2, 17, 0, 9, 4, 11, 13, 14, 6, 15, 19, 5, 20, 16, 22, 10, 12, 18, 7, 8, 21, 1, 23}),
        CenterCoord(Vector#{2, 0, 3, 2, 0, 1, 2, 1, 1, 2, 5, 3, 5, 1, 5, 5, 4, 3, 4, 3, 0, 4, 0, 4})
    };
    Assert.assertEq(expected = Ok("                L  U  U  U \n                L  F  U  U \n                L  D  F  R \n                D  L  U  U \n\n F  F  F  R     F  D  B  B     L  F  L  L     F  F  F  D \n L  L  D  D     F  R  F  R     F  U  R  R     U  U  L  B \n L  L  D  B     D  B  D  D     F  F  R  R     U  U  L  B \n U  U  R  B     L  B  L  B     D  U  D  R     F  R  B  R \n\n                D  R  D  R \n                D  B  R  B \n                L  B  B  R \n                B  D  B  U "), Orbit64.Net.draw(4, orbits, false));
    match Orbit64.State.encode(4, orbits) {
        case Err(e) => Assert.assertEq(expected = "encodes", e)
        case Ok(t)  => Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(4, t))
    }
