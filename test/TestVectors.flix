//
// Cross-language conformance tests.
//
// The orbit arrays and expected tokens below were produced by an independent
// reference implementation driving a geometric cube model: real turns applied
// to a 3D facelet representation, orbits discovered by connected components,
// and every state verified to round-trip at sticker level. They are checked in
// verbatim, so these tests catch any disagreement between the two codecs.
//

use Orbit64.Coord.Coord.{CornerCoord, MidgeCoord, WingCoord, CenterCoord}


@Test
def test2x2SolvedEncodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0})
    };
    Assert.assertEq(expected = Ok("AAAAA"), Orbit64.State.encode(2, orbits))

@Test
def test2x2SolvedDecodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(2, "AAAAA"))


@Test
def test2x2Scramble0Encodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{6, 2, 1, 5, 0, 3, 7, 4}, Vector#{0, 2, 1, 1, 1, 1, 2, 1})
    };
    Assert.assertEq(expected = Ok("EJ6Rr"), Orbit64.State.encode(2, orbits))

@Test
def test2x2Scramble0Decodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{6, 2, 1, 5, 0, 3, 7, 4}, Vector#{0, 2, 1, 1, 1, 1, 2, 1})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(2, "EJ6Rr"))


@Test
def test2x2Scramble1Encodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{4, 6, 3, 5, 1, 0, 7, 2}, Vector#{2, 2, 0, 0, 0, 2, 2, 1})
    };
    Assert.assertEq(expected = Ok("DJ5Lt"), Orbit64.State.encode(2, orbits))

@Test
def test2x2Scramble1Decodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{4, 6, 3, 5, 1, 0, 7, 2}, Vector#{2, 2, 0, 0, 0, 2, 2, 1})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(2, "DJ5Lt"))


@Test
def test3x3SolvedEncodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        MidgeCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
    };
    Assert.assertEq(expected = Ok("AAAAAAAAAAAA"), Orbit64.State.encode(3, orbits))

@Test
def test3x3SolvedDecodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        MidgeCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(3, "AAAAAAAAAAAA"))


@Test
def test3x3SuperflipEncodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        MidgeCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1})
    };
    Assert.assertEq(expected = Ok("AAAAAAAAAAf_"), Orbit64.State.encode(3, orbits))

@Test
def test3x3SuperflipDecodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        MidgeCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(3, "AAAAAAAAAAf_"))


@Test
def test3x3SuneEncodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 7, 6, 4, 5, 3, 2}, Vector#{0, 0, 1, 1, 0, 0, 0, 1}),
        MidgeCoord(Vector#{0, 1, 2, 6, 4, 5, 11, 7, 8, 9, 10, 3}, Vector#{0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0})
    };
    Assert.assertEq(expected = Ok("ABU68xS1q8iQ"), Orbit64.State.encode(3, orbits))

@Test
def test3x3SuneDecodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 7, 6, 4, 5, 3, 2}, Vector#{0, 0, 1, 1, 0, 0, 0, 1}),
        MidgeCoord(Vector#{0, 1, 2, 6, 4, 5, 11, 7, 8, 9, 10, 3}, Vector#{0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(3, "ABU68xS1q8iQ"))


@Test
def test3x3Scramble0Encodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{2, 3, 5, 4, 0, 1, 6, 7}, Vector#{0, 1, 2, 0, 1, 1, 2, 2}),
        MidgeCoord(Vector#{5, 11, 3, 2, 10, 7, 1, 0, 9, 8, 4, 6}, Vector#{0, 1, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0})
    };
    Assert.assertEq(expected = Ok("AWMmIry_APKe"), Orbit64.State.encode(3, orbits))

@Test
def test3x3Scramble0Decodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{2, 3, 5, 4, 0, 1, 6, 7}, Vector#{0, 1, 2, 0, 1, 1, 2, 2}),
        MidgeCoord(Vector#{5, 11, 3, 2, 10, 7, 1, 0, 9, 8, 4, 6}, Vector#{0, 1, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(3, "AWMmIry_APKe"))


@Test
def test3x3Scramble1Encodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{2, 1, 4, 0, 3, 5, 6, 7}, Vector#{0, 1, 0, 0, 0, 2, 2, 1}),
        MidgeCoord(Vector#{5, 1, 3, 2, 0, 6, 10, 7, 8, 4, 11, 9}, Vector#{1, 0, 1, 0, 1, 1, 1, 0, 0, 1, 0, 0})
    };
    Assert.assertEq(expected = Ok("AUi1GvzQin1y"), Orbit64.State.encode(3, orbits))

@Test
def test3x3Scramble1Decodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{2, 1, 4, 0, 3, 5, 6, 7}, Vector#{0, 1, 0, 0, 0, 2, 2, 1}),
        MidgeCoord(Vector#{5, 1, 3, 2, 0, 6, 10, 7, 8, 4, 11, 9}, Vector#{1, 0, 1, 0, 1, 1, 1, 0, 0, 1, 0, 0})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(3, "AUi1GvzQin1y"))


@Test
def test4x4SolvedEncodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})
    };
    Assert.assertEq(expected = Ok("AAAAAAAAAAAAAAAAAAAAAAAAAAA"), Orbit64.State.encode(4, orbits))

@Test
def test4x4SolvedDecodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(4, "AAAAAAAAAAAAAAAAAAAAAAAAAAA"))


@Test
def test4x4Scramble0Encodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{4, 5, 7, 6, 1, 2, 0, 3}, Vector#{1, 2, 0, 0, 2, 2, 1, 1}),
        WingCoord(Vector#{18, 19, 23, 20, 6, 16, 3, 13, 1, 12, 5, 7, 22, 11, 8, 9, 14, 2, 21, 17, 10, 0, 4, 15}),
        CenterCoord(Vector#{4, 3, 2, 4, 5, 1, 0, 1, 3, 2, 5, 0, 2, 3, 2, 5, 4, 0, 0, 1, 3, 1, 5, 4})
    };
    Assert.assertEq(expected = Ok("BJSsuyGPOiU06kIz-eqibqTP1th"), Orbit64.State.encode(4, orbits))

@Test
def test4x4Scramble0Decodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{4, 5, 7, 6, 1, 2, 0, 3}, Vector#{1, 2, 0, 0, 2, 2, 1, 1}),
        WingCoord(Vector#{18, 19, 23, 20, 6, 16, 3, 13, 1, 12, 5, 7, 22, 11, 8, 9, 14, 2, 21, 17, 10, 0, 4, 15}),
        CenterCoord(Vector#{4, 3, 2, 4, 5, 1, 0, 1, 3, 2, 5, 0, 2, 3, 2, 5, 4, 0, 0, 1, 3, 1, 5, 4})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(4, "BJSsuyGPOiU06kIz-eqibqTP1th"))


@Test
def test4x4Scramble1Encodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{4, 1, 0, 7, 5, 3, 6, 2}, Vector#{2, 0, 1, 1, 2, 1, 0, 2}),
        WingCoord(Vector#{0, 5, 7, 1, 14, 6, 3, 22, 15, 23, 13, 8, 21, 12, 2, 10, 19, 16, 17, 11, 9, 18, 20, 4}),
        CenterCoord(Vector#{5, 5, 2, 1, 3, 3, 2, 1, 5, 0, 2, 4, 4, 0, 2, 0, 4, 1, 0, 1, 4, 3, 5, 3})
    };
    Assert.assertEq(expected = Ok("BAy4TWgX4vSZOHnM2NdN63BRWKG"), Orbit64.State.encode(4, orbits))

@Test
def test4x4Scramble1Decodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{4, 1, 0, 7, 5, 3, 6, 2}, Vector#{2, 0, 1, 1, 2, 1, 0, 2}),
        WingCoord(Vector#{0, 5, 7, 1, 14, 6, 3, 22, 15, 23, 13, 8, 21, 12, 2, 10, 19, 16, 17, 11, 9, 18, 20, 4}),
        CenterCoord(Vector#{5, 5, 2, 1, 3, 3, 2, 1, 5, 0, 2, 4, 4, 0, 2, 0, 4, 1, 0, 1, 4, 3, 5, 3})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(4, "BAy4TWgX4vSZOHnM2NdN63BRWKG"))


@Test
def test5x5SolvedEncodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        MidgeCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
        WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})
    };
    Assert.assertEq(expected = Ok("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"), Orbit64.State.encode(5, orbits))

@Test
def test5x5SolvedDecodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        MidgeCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
        WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(5, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"))


@Test
def test5x5Scramble0Encodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{2, 1, 5, 4, 0, 7, 3, 6}, Vector#{2, 2, 0, 1, 1, 1, 1, 1}),
        MidgeCoord(Vector#{5, 2, 7, 4, 6, 3, 9, 11, 10, 8, 0, 1}, Vector#{1, 0, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1}),
        WingCoord(Vector#{20, 15, 3, 13, 19, 18, 6, 11, 8, 4, 0, 22, 14, 2, 1, 10, 12, 9, 21, 7, 17, 16, 23, 5}),
        CenterCoord(Vector#{0, 4, 1, 3, 4, 4, 1, 2, 2, 1, 5, 0, 2, 0, 4, 3, 2, 0, 1, 3, 5, 5, 3, 5}),
        CenterCoord(Vector#{5, 5, 2, 5, 0, 1, 0, 3, 0, 2, 2, 4, 1, 1, 2, 4, 3, 4, 0, 3, 5, 1, 3, 4})
    };
    Assert.assertEq(expected = Ok("BZC-qGPah6s_QRSpZqYwHRBzEXMajtc7pIOYt8AIaS"), Orbit64.State.encode(5, orbits))

@Test
def test5x5Scramble0Decodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{2, 1, 5, 4, 0, 7, 3, 6}, Vector#{2, 2, 0, 1, 1, 1, 1, 1}),
        MidgeCoord(Vector#{5, 2, 7, 4, 6, 3, 9, 11, 10, 8, 0, 1}, Vector#{1, 0, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1}),
        WingCoord(Vector#{20, 15, 3, 13, 19, 18, 6, 11, 8, 4, 0, 22, 14, 2, 1, 10, 12, 9, 21, 7, 17, 16, 23, 5}),
        CenterCoord(Vector#{0, 4, 1, 3, 4, 4, 1, 2, 2, 1, 5, 0, 2, 0, 4, 3, 2, 0, 1, 3, 5, 5, 3, 5}),
        CenterCoord(Vector#{5, 5, 2, 5, 0, 1, 0, 3, 0, 2, 2, 4, 1, 1, 2, 4, 3, 4, 0, 3, 5, 1, 3, 4})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(5, "BZC-qGPah6s_QRSpZqYwHRBzEXMajtc7pIOYt8AIaS"))


@Test
def test5x5Scramble1Encodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{3, 5, 6, 0, 4, 2, 7, 1}, Vector#{1, 0, 2, 2, 2, 1, 2, 2}),
        MidgeCoord(Vector#{10, 6, 11, 7, 0, 1, 4, 5, 2, 9, 3, 8}, Vector#{1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0}),
        WingCoord(Vector#{13, 5, 0, 1, 4, 9, 8, 20, 7, 18, 3, 2, 12, 15, 23, 11, 16, 6, 10, 17, 21, 14, 22, 19}),
        CenterCoord(Vector#{5, 5, 0, 1, 3, 0, 5, 1, 3, 2, 3, 4, 4, 0, 4, 0, 2, 5, 2, 4, 3, 1, 1, 2}),
        CenterCoord(Vector#{5, 0, 3, 3, 4, 5, 1, 5, 2, 4, 4, 0, 1, 5, 3, 1, 3, 2, 2, 2, 4, 0, 0, 1})
    };
    Assert.assertEq(expected = Ok("CS4VwsPPKZmHYvHO6XpLm43iQChcG5dsI3rgJeX8ai"), Orbit64.State.encode(5, orbits))

@Test
def test5x5Scramble1Decodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{3, 5, 6, 0, 4, 2, 7, 1}, Vector#{1, 0, 2, 2, 2, 1, 2, 2}),
        MidgeCoord(Vector#{10, 6, 11, 7, 0, 1, 4, 5, 2, 9, 3, 8}, Vector#{1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0}),
        WingCoord(Vector#{13, 5, 0, 1, 4, 9, 8, 20, 7, 18, 3, 2, 12, 15, 23, 11, 16, 6, 10, 17, 21, 14, 22, 19}),
        CenterCoord(Vector#{5, 5, 0, 1, 3, 0, 5, 1, 3, 2, 3, 4, 4, 0, 4, 0, 2, 5, 2, 4, 3, 1, 1, 2}),
        CenterCoord(Vector#{5, 0, 3, 3, 4, 5, 1, 5, 2, 4, 4, 0, 1, 5, 3, 1, 3, 2, 2, 2, 4, 0, 0, 1})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(5, "CS4VwsPPKZmHYvHO6XpLm43iQChcG5dsI3rgJeX8ai"))


@Test
def test6x6SolvedEncodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}),
        WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})
    };
    Assert.assertEq(expected = Ok("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"), Orbit64.State.encode(6, orbits))

@Test
def test6x6SolvedDecodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}),
        WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(6, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"))


@Test
def test6x6Scramble0Encodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{4, 5, 2, 3, 6, 1, 0, 7}, Vector#{0, 1, 2, 2, 1, 1, 0, 2}),
        WingCoord(Vector#{20, 9, 17, 22, 14, 0, 11, 2, 16, 23, 12, 7, 8, 13, 4, 3, 6, 10, 21, 1, 18, 5, 19, 15}),
        WingCoord(Vector#{11, 3, 18, 15, 21, 10, 20, 14, 23, 9, 8, 7, 22, 6, 19, 12, 0, 2, 1, 13, 4, 5, 16, 17}),
        CenterCoord(Vector#{5, 5, 5, 2, 0, 2, 1, 4, 3, 2, 4, 1, 4, 0, 1, 3, 3, 0, 0, 2, 3, 4, 5, 1}),
        CenterCoord(Vector#{5, 3, 2, 3, 2, 0, 2, 2, 1, 1, 4, 0, 0, 0, 3, 4, 5, 4, 1, 4, 1, 5, 5, 3}),
        CenterCoord(Vector#{5, 0, 5, 3, 1, 5, 3, 1, 5, 3, 2, 0, 0, 3, 1, 4, 2, 2, 2, 4, 0, 4, 4, 1}),
        CenterCoord(Vector#{3, 1, 4, 2, 5, 1, 2, 3, 0, 0, 5, 3, 5, 2, 4, 4, 0, 4, 3, 1, 5, 1, 0, 2})
    };
    Assert.assertEq(expected = Ok("A3aowfv7mrY5a0fF-VLs5LqBjuY2IMc8QgkU0FS9QNkT-lFVxDYZjT5VBL5DSU0WyT"), Orbit64.State.encode(6, orbits))

@Test
def test6x6Scramble0Decodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{4, 5, 2, 3, 6, 1, 0, 7}, Vector#{0, 1, 2, 2, 1, 1, 0, 2}),
        WingCoord(Vector#{20, 9, 17, 22, 14, 0, 11, 2, 16, 23, 12, 7, 8, 13, 4, 3, 6, 10, 21, 1, 18, 5, 19, 15}),
        WingCoord(Vector#{11, 3, 18, 15, 21, 10, 20, 14, 23, 9, 8, 7, 22, 6, 19, 12, 0, 2, 1, 13, 4, 5, 16, 17}),
        CenterCoord(Vector#{5, 5, 5, 2, 0, 2, 1, 4, 3, 2, 4, 1, 4, 0, 1, 3, 3, 0, 0, 2, 3, 4, 5, 1}),
        CenterCoord(Vector#{5, 3, 2, 3, 2, 0, 2, 2, 1, 1, 4, 0, 0, 0, 3, 4, 5, 4, 1, 4, 1, 5, 5, 3}),
        CenterCoord(Vector#{5, 0, 5, 3, 1, 5, 3, 1, 5, 3, 2, 0, 0, 3, 1, 4, 2, 2, 2, 4, 0, 4, 4, 1}),
        CenterCoord(Vector#{3, 1, 4, 2, 5, 1, 2, 3, 0, 0, 5, 3, 5, 2, 4, 4, 0, 4, 3, 1, 5, 1, 0, 2})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(6, "A3aowfv7mrY5a0fF-VLs5LqBjuY2IMc8QgkU0FS9QNkT-lFVxDYZjT5VBL5DSU0WyT"))


@Test
def test6x6Scramble1Encodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{4, 7, 0, 2, 5, 3, 1, 6}, Vector#{2, 0, 1, 1, 2, 2, 2, 2}),
        WingCoord(Vector#{11, 17, 18, 19, 9, 14, 21, 15, 5, 6, 22, 7, 13, 8, 10, 20, 1, 4, 0, 12, 16, 3, 23, 2}),
        WingCoord(Vector#{5, 16, 4, 0, 3, 19, 12, 1, 23, 6, 22, 7, 21, 15, 2, 18, 14, 17, 10, 11, 8, 9, 13, 20}),
        CenterCoord(Vector#{2, 1, 3, 1, 2, 4, 3, 0, 1, 2, 0, 3, 1, 2, 4, 3, 5, 5, 4, 5, 0, 5, 4, 0}),
        CenterCoord(Vector#{0, 3, 4, 0, 1, 2, 5, 2, 4, 2, 0, 5, 3, 1, 5, 2, 1, 5, 4, 3, 1, 3, 4, 0}),
        CenterCoord(Vector#{5, 1, 3, 2, 1, 2, 1, 0, 4, 4, 4, 5, 3, 3, 2, 2, 3, 0, 4, 0, 5, 0, 1, 5}),
        CenterCoord(Vector#{4, 5, 1, 0, 5, 2, 2, 4, 3, 1, 0, 4, 0, 5, 1, 3, 0, 3, 1, 3, 2, 4, 5, 2})
    };
    Assert.assertEq(expected = Ok("A6NZa0XyMKvP7ivYNtp9IU38qGJ-qqhA1rCYBFflJ4qSkF6Vvo24jP3CEFUNrCB5-0"), Orbit64.State.encode(6, orbits))

@Test
def test6x6Scramble1Decodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{4, 7, 0, 2, 5, 3, 1, 6}, Vector#{2, 0, 1, 1, 2, 2, 2, 2}),
        WingCoord(Vector#{11, 17, 18, 19, 9, 14, 21, 15, 5, 6, 22, 7, 13, 8, 10, 20, 1, 4, 0, 12, 16, 3, 23, 2}),
        WingCoord(Vector#{5, 16, 4, 0, 3, 19, 12, 1, 23, 6, 22, 7, 21, 15, 2, 18, 14, 17, 10, 11, 8, 9, 13, 20}),
        CenterCoord(Vector#{2, 1, 3, 1, 2, 4, 3, 0, 1, 2, 0, 3, 1, 2, 4, 3, 5, 5, 4, 5, 0, 5, 4, 0}),
        CenterCoord(Vector#{0, 3, 4, 0, 1, 2, 5, 2, 4, 2, 0, 5, 3, 1, 5, 2, 1, 5, 4, 3, 1, 3, 4, 0}),
        CenterCoord(Vector#{5, 1, 3, 2, 1, 2, 1, 0, 4, 4, 4, 5, 3, 3, 2, 2, 3, 0, 4, 0, 5, 0, 1, 5}),
        CenterCoord(Vector#{4, 5, 1, 0, 5, 2, 2, 4, 3, 1, 0, 4, 0, 5, 1, 3, 0, 3, 1, 3, 2, 4, 5, 2})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(6, "A6NZa0XyMKvP7ivYNtp9IU38qGJ-qqhA1rCYBFflJ4qSkF6Vvo24jP3CEFUNrCB5-0"))


@Test
def test7x7SolvedEncodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        MidgeCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
        WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}),
        WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})
    };
    Assert.assertEq(expected = Ok("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"), Orbit64.State.encode(7, orbits))

@Test
def test7x7SolvedDecodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7}, Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        MidgeCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, Vector#{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
        WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}),
        WingCoord(Vector#{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5}),
        CenterCoord(Vector#{0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(7, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"))


@Test
def test7x7Scramble0Encodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{6, 5, 4, 3, 1, 0, 2, 7}, Vector#{1, 0, 1, 0, 0, 0, 1, 0}),
        MidgeCoord(Vector#{10, 6, 3, 8, 7, 9, 4, 5, 11, 2, 1, 0}, Vector#{0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0}),
        WingCoord(Vector#{13, 11, 21, 5, 10, 22, 23, 16, 9, 2, 12, 15, 4, 20, 8, 18, 6, 1, 19, 3, 14, 0, 17, 7}),
        WingCoord(Vector#{21, 11, 14, 7, 10, 16, 17, 3, 13, 12, 19, 2, 8, 23, 20, 15, 6, 1, 22, 9, 5, 4, 0, 18}),
        CenterCoord(Vector#{5, 4, 3, 5, 0, 4, 2, 0, 5, 2, 1, 2, 3, 1, 4, 3, 0, 2, 1, 4, 1, 3, 0, 5}),
        CenterCoord(Vector#{4, 1, 3, 1, 4, 4, 2, 1, 4, 5, 2, 3, 5, 1, 3, 5, 5, 0, 0, 2, 0, 0, 3, 2}),
        CenterCoord(Vector#{4, 1, 3, 1, 4, 2, 2, 2, 4, 3, 0, 5, 4, 0, 3, 5, 5, 1, 0, 2, 3, 0, 1, 5}),
        CenterCoord(Vector#{1, 0, 1, 4, 2, 1, 4, 0, 2, 2, 0, 5, 4, 3, 4, 5, 1, 3, 2, 3, 3, 0, 5, 5}),
        CenterCoord(Vector#{3, 1, 4, 5, 5, 5, 0, 1, 2, 2, 0, 4, 3, 3, 3, 1, 5, 1, 0, 0, 2, 2, 4, 4}),
        CenterCoord(Vector#{2, 2, 4, 0, 5, 1, 5, 0, 2, 3, 4, 3, 2, 3, 3, 5, 1, 4, 0, 0, 1, 5, 1, 4})
    };
    Assert.assertEq(expected = Ok("Al3dq6yUnJYFa_Rly_9F8Z3JCoEtWgs4pqrI8XEqo1_A5S15-D4DktJttxGZcC5AvUNmJpM1-vvJ5nDMavnI5Jc3cQ"), Orbit64.State.encode(7, orbits))

@Test
def test7x7Scramble0Decodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{6, 5, 4, 3, 1, 0, 2, 7}, Vector#{1, 0, 1, 0, 0, 0, 1, 0}),
        MidgeCoord(Vector#{10, 6, 3, 8, 7, 9, 4, 5, 11, 2, 1, 0}, Vector#{0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0}),
        WingCoord(Vector#{13, 11, 21, 5, 10, 22, 23, 16, 9, 2, 12, 15, 4, 20, 8, 18, 6, 1, 19, 3, 14, 0, 17, 7}),
        WingCoord(Vector#{21, 11, 14, 7, 10, 16, 17, 3, 13, 12, 19, 2, 8, 23, 20, 15, 6, 1, 22, 9, 5, 4, 0, 18}),
        CenterCoord(Vector#{5, 4, 3, 5, 0, 4, 2, 0, 5, 2, 1, 2, 3, 1, 4, 3, 0, 2, 1, 4, 1, 3, 0, 5}),
        CenterCoord(Vector#{4, 1, 3, 1, 4, 4, 2, 1, 4, 5, 2, 3, 5, 1, 3, 5, 5, 0, 0, 2, 0, 0, 3, 2}),
        CenterCoord(Vector#{4, 1, 3, 1, 4, 2, 2, 2, 4, 3, 0, 5, 4, 0, 3, 5, 5, 1, 0, 2, 3, 0, 1, 5}),
        CenterCoord(Vector#{1, 0, 1, 4, 2, 1, 4, 0, 2, 2, 0, 5, 4, 3, 4, 5, 1, 3, 2, 3, 3, 0, 5, 5}),
        CenterCoord(Vector#{3, 1, 4, 5, 5, 5, 0, 1, 2, 2, 0, 4, 3, 3, 3, 1, 5, 1, 0, 0, 2, 2, 4, 4}),
        CenterCoord(Vector#{2, 2, 4, 0, 5, 1, 5, 0, 2, 3, 4, 3, 2, 3, 3, 5, 1, 4, 0, 0, 1, 5, 1, 4})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(7, "Al3dq6yUnJYFa_Rly_9F8Z3JCoEtWgs4pqrI8XEqo1_A5S15-D4DktJttxGZcC5AvUNmJpM1-vvJ5nDMavnI5Jc3cQ"))


@Test
def test7x7Scramble1Encodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{5, 2, 6, 3, 4, 0, 1, 7}, Vector#{2, 2, 2, 0, 1, 2, 2, 1}),
        MidgeCoord(Vector#{4, 6, 2, 5, 1, 10, 9, 3, 7, 8, 0, 11}, Vector#{1, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 0}),
        WingCoord(Vector#{22, 1, 16, 3, 13, 20, 9, 10, 6, 5, 19, 21, 23, 17, 2, 18, 14, 15, 0, 12, 7, 8, 4, 11}),
        WingCoord(Vector#{13, 23, 22, 19, 5, 18, 21, 15, 4, 10, 20, 8, 17, 3, 2, 0, 6, 9, 7, 16, 14, 1, 11, 12}),
        CenterCoord(Vector#{0, 1, 4, 3, 1, 1, 0, 2, 2, 3, 5, 4, 0, 2, 5, 3, 3, 5, 5, 1, 2, 4, 4, 0}),
        CenterCoord(Vector#{4, 1, 4, 5, 1, 5, 4, 3, 0, 5, 1, 0, 3, 1, 2, 2, 3, 3, 0, 0, 5, 4, 2, 2}),
        CenterCoord(Vector#{5, 1, 4, 0, 2, 0, 5, 1, 3, 5, 2, 3, 3, 2, 2, 3, 4, 0, 4, 0, 4, 5, 1, 1}),
        CenterCoord(Vector#{1, 4, 1, 0, 2, 0, 4, 5, 5, 4, 2, 5, 1, 3, 3, 3, 5, 4, 3, 2, 2, 0, 0, 1}),
        CenterCoord(Vector#{1, 1, 0, 3, 0, 0, 4, 5, 1, 4, 2, 3, 0, 5, 3, 1, 5, 3, 4, 2, 5, 2, 4, 2}),
        CenterCoord(Vector#{5, 1, 1, 0, 3, 3, 0, 1, 4, 2, 2, 5, 0, 3, 2, 3, 5, 4, 4, 1, 5, 0, 2, 4})
    };
    Assert.assertEq(expected = Ok("Ad6-iQw7H21v8reT3J4uQAIkyVrwGwD-lrKaqfw1EFx3rVyrpYmmNl--tjCliZP5R0FEf7-os75Zk9hJgncQa3Md1E"), Orbit64.State.encode(7, orbits))

@Test
def test7x7Scramble1Decodes(): Unit \ Assert =
    let orbits = List#{
        CornerCoord(Vector#{5, 2, 6, 3, 4, 0, 1, 7}, Vector#{2, 2, 2, 0, 1, 2, 2, 1}),
        MidgeCoord(Vector#{4, 6, 2, 5, 1, 10, 9, 3, 7, 8, 0, 11}, Vector#{1, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 0}),
        WingCoord(Vector#{22, 1, 16, 3, 13, 20, 9, 10, 6, 5, 19, 21, 23, 17, 2, 18, 14, 15, 0, 12, 7, 8, 4, 11}),
        WingCoord(Vector#{13, 23, 22, 19, 5, 18, 21, 15, 4, 10, 20, 8, 17, 3, 2, 0, 6, 9, 7, 16, 14, 1, 11, 12}),
        CenterCoord(Vector#{0, 1, 4, 3, 1, 1, 0, 2, 2, 3, 5, 4, 0, 2, 5, 3, 3, 5, 5, 1, 2, 4, 4, 0}),
        CenterCoord(Vector#{4, 1, 4, 5, 1, 5, 4, 3, 0, 5, 1, 0, 3, 1, 2, 2, 3, 3, 0, 0, 5, 4, 2, 2}),
        CenterCoord(Vector#{5, 1, 4, 0, 2, 0, 5, 1, 3, 5, 2, 3, 3, 2, 2, 3, 4, 0, 4, 0, 4, 5, 1, 1}),
        CenterCoord(Vector#{1, 4, 1, 0, 2, 0, 4, 5, 5, 4, 2, 5, 1, 3, 3, 3, 5, 4, 3, 2, 2, 0, 0, 1}),
        CenterCoord(Vector#{1, 1, 0, 3, 0, 0, 4, 5, 1, 4, 2, 3, 0, 5, 3, 1, 5, 3, 4, 2, 5, 2, 4, 2}),
        CenterCoord(Vector#{5, 1, 1, 0, 3, 3, 0, 1, 4, 2, 2, 5, 0, 3, 2, 3, 5, 4, 4, 1, 5, 0, 2, 4})
    };
    Assert.assertEq(expected = Ok(orbits), Orbit64.State.decode(7, "Ad6-iQw7H21v8reT3J4uQAIkyVrwGwD-lrKaqfw1EFx3rVyrpYmmNl--tjCliZP5R0FEf7-os75Zk9hJgncQa3Md1E"))
