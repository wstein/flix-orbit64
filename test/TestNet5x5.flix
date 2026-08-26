//
// The 5x5x5 display convention, checked against an independent model.
//
// `orbit64-5x5-draft@1`: corners and midges in the standard orders, wings and
// both centre orbits ordered by the facelet index of each piece's reference
// sticker. The fourth entry of the list is the X-centres and the fifth the
// plus-centres -- nothing in the type says so, which is why the `Uw` case
// matters: after it the two vectors differ, so swapping them fails.
//

use Orbit64.Coord.Coord.{CornerCoord, MidgeCoord, WingCoord, CenterCoord}

///
/// `solved`
///
@Test
def fiveByFiveSolved(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        MidgeCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
        WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})
    };
    Assert.assertEq(expected = Ok("                   U  U  U  U  U \n                   U  U  U  U  U \n                   U  U  U  U  U \n                   U  U  U  U  U \n                   U  U  U  U  U \n\n L  L  L  L  L     F  F  F  F  F     R  R  R  R  R     B  B  B  B  B \n L  L  L  L  L     F  F  F  F  F     R  R  R  R  R     B  B  B  B  B \n L  L  L  L  L     F  F  F  F  F     R  R  R  R  R     B  B  B  B  B \n L  L  L  L  L     F  F  F  F  F     R  R  R  R  R     B  B  B  B  B \n L  L  L  L  L     F  F  F  F  F     R  R  R  R  R     B  B  B  B  B \n\n                   D  D  D  D  D \n                   D  D  D  D  D \n                   D  D  D  D  D \n                   D  D  D  D  D \n                   D  D  D  D  D "), Orbit64.Net.draw(5, orbits, false));
    match Orbit64.encode(5, orbits) {
        case Err(e) => Assert.assertEq(expected = "encodes", e)
        case Ok(t)  => Assert.assertEq(expected = Ok(orbits), Orbit64.decode(5, t))
    }

///
/// `Uw`
///
@Test
def fiveByFiveUw(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        MidgeCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
        WingCoord(Vector#{2, 0, 3, 1, 20, 21, 6, 7, 4, 5, 10, 11, 12, 13, 14, 15, 8, 9, 18, 19, 16, 17, 22, 23}),
        CenterCoord(Vector#{0, 0, 0, 0, 5, 5, 1, 1, 1, 1, 2, 2, 3, 3, 3, 3, 2, 2, 4, 4, 4, 4, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 5, 1, 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 2, 4, 4, 4, 4, 5, 5, 5})
    };
    Assert.assertEq(expected = Ok("                   U  U  U  U  U \n                   U  U  U  U  U \n                   U  U  U  U  U \n                   U  U  U  U  U \n                   U  U  U  U  U \n\n F  F  F  F  F     R  R  R  R  R     B  B  B  B  B     L  L  L  L  L \n F  F  F  F  F     R  R  R  R  R     B  B  B  B  B     L  L  L  L  L \n L  L  L  L  L     F  F  F  F  F     R  R  R  R  R     B  B  B  B  B \n L  L  L  L  L     F  F  F  F  F     R  R  R  R  R     B  B  B  B  B \n L  L  L  L  L     F  F  F  F  F     R  R  R  R  R     B  B  B  B  B \n\n                   D  D  D  D  D \n                   D  D  D  D  D \n                   D  D  D  D  D \n                   D  D  D  D  D \n                   D  D  D  D  D "), Orbit64.Net.draw(5, orbits, false));
    match Orbit64.encode(5, orbits) {
        case Err(e) => Assert.assertEq(expected = "encodes", e)
        case Ok(t)  => Assert.assertEq(expected = Ok(orbits), Orbit64.decode(5, t))
    }

///
/// `2R Uw F2`
///
@Test
def fiveByFive2Ruwf2(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{5, 4, 1, 2, 0, 3, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        MidgeCoord(Vector#{3, 5, 1, 2, 4, 0, 6, 7, 9, 8, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
        WingCoord(Vector#{2, 0, 11, 12, 3, 21, 9, 7, 15, 10, 5, 4, 1, 13, 14, 20, 8, 6, 18, 19, 16, 17, 22, 23}),
        CenterCoord(Vector#{0, 0, 2, 2, 0, 5, 1, 1, 3, 2, 1, 1, 3, 5, 3, 5, 2, 3, 4, 4, 4, 4, 0, 5}),
        CenterCoord(Vector#{0, 0, 0, 2, 5, 1, 1, 1, 2, 3, 2, 1, 3, 3, 5, 3, 2, 4, 4, 4, 4, 0, 5, 5})
    };
    Assert.assertEq(expected = Ok("                   U  U  U  U  U \n                   U  U  U  U  U \n                   U  U  U  U  U \n                   F  F  F  F  F \n                   D  B  D  D  D \n\n F  F  F  D  R     F  D  F  F  F     L  U  B  B  B     L  L  L  L  L \n F  F  F  D  R     F  D  F  F  F     L  U  B  B  B     L  L  L  L  L \n L  L  L  L  R     F  D  F  F  F     L  R  R  R  R     B  U  B  B  B \n L  L  L  L  B     R  R  R  R  R     F  R  R  R  R     B  U  B  B  B \n L  L  L  L  B     R  R  R  R  R     F  R  R  R  R     B  U  B  B  B \n\n                   U  U  U  U  U \n                   D  D  D  B  D \n                   D  D  D  B  D \n                   D  D  D  B  D \n                   D  D  D  B  D "), Orbit64.Net.draw(5, orbits, false));
    match Orbit64.encode(5, orbits) {
        case Err(e) => Assert.assertEq(expected = "encodes", e)
        case Ok(t)  => Assert.assertEq(expected = Ok(orbits), Orbit64.decode(5, t))
    }

///
/// `R Uw 2R F D 2F U 4R`
///
@Test
def fiveByFiveRuw2Rfd2Fu4R(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{2, 4, 5, 1, 7, 6, 3, 0}, Vector#{0, 0, 2, 0, 2, 0, 2, 0}),
        MidgeCoord(Vector#{2, 3, 9, 1, 4, 6, 7, 11, 8, 5, 10, 0}, Vector#{0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0}),
        WingCoord(Vector#{3, 2, 13, 0, 9, 21, 11, 4, 14, 6, 15, 19, 5, 20, 16, 22, 10, 12, 18, 7, 8, 17, 1, 23}),
        CenterCoord(Vector#{2, 0, 3, 1, 0, 5, 2, 1, 1, 1, 4, 3, 5, 5, 4, 5, 2, 3, 4, 3, 0, 2, 0, 4}),
        CenterCoord(Vector#{0, 2, 0, 2, 5, 0, 1, 1, 2, 3, 1, 3, 1, 5, 3, 5, 2, 4, 3, 4, 4, 0, 4, 5})
    };
    Assert.assertEq(expected = Ok("                   L  U  U  U  U \n                   L  F  U  U  U \n                   L  F  U  U  U \n                   D  D  F  R  R \n                   D  L  U  U  U \n\n F  F  F  R  R     F  D  B  B  B     L  F  L  L  L     F  F  F  F  D \n F  F  F  D  D     F  R  F  R  R     F  U  B  B  B     L  U  L  F  L \n L  L  L  D  D     F  D  F  R  R     F  U  R  R  R     U  U  B  L  B \n L  L  L  D  B     D  L  D  D  D     F  F  R  R  R     U  U  B  L  B \n U  U  B  R  B     L  B  L  L  B     D  U  D  R  R     F  R  R  B  R \n\n                   D  R  D  D  R \n                   D  B  R  B  B \n                   D  B  D  D  R \n                   L  L  B  B  U \n                   B  D  B  B  U "), Orbit64.Net.draw(5, orbits, false));
    match Orbit64.encode(5, orbits) {
        case Err(e) => Assert.assertEq(expected = "encodes", e)
        case Ok(t)  => Assert.assertEq(expected = Ok(orbits), Orbit64.decode(5, t))
    }
