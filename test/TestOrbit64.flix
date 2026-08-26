//
// Properties of the codec that hold independently of any reference data:
// sizes, round-trips, and the invariants the format is built on.
//

use Orbit64.Coord.Coord.{CornerCoord, MidgeCoord, WingCoord, CenterCoord}
use Orbit64.Orbit.Orbit.{Corners, Midges, Wings, Centers}

// ---------- layout ----------

@Test
def layoutOf2x2(): Unit \ Assert =
    Assert.assertEq(expected = List#{Corners}, Orbit64.Orbit.layout(2))

@Test
def layoutOf3x3(): Unit \ Assert =
    Assert.assertEq(expected = List#{Corners, Midges}, Orbit64.Orbit.layout(3))

@Test
def layoutOf4x4(): Unit \ Assert =
    Assert.assertEq(expected = List#{Corners, Wings, Centers}, Orbit64.Orbit.layout(4))

@Test
def layoutOf5x5(): Unit \ Assert =
    Assert.assertEq(expected = List#{Corners, Midges, Wings, Centers, Centers}, Orbit64.Orbit.layout(5))

@Test
def layoutOf7x7HasTwoWingAndSixCentreOrbits(): Unit \ Assert =
    let l = Orbit64.Orbit.layout(7);
    Assert.assertEq(expected = 2, List.count(o -> o == Wings, l));
    Assert.assertEq(expected = 6, List.count(o -> o == Centers, l))

// ---------- state counts ----------

///
/// The classic 3x3x3 figure is 43,252,003,274,489,856,000. This codec counts
/// exactly twice that, because it deliberately does not enforce the coupling
/// between corner and edge permutation parity.
///
/// Enforcing it would save exactly one bit and cost an interleaved encoding of
/// the two orbits. At 66.23 bits the 3x3x3 token is 12 characters either way,
/// so the constraint buys nothing and is dropped. The same holds at every size
/// measured. Relaxing means a few tokens decode to states no sequence of turns
/// can reach -- which is a decoder's problem, not a format's.
///
@Test
def stateCountOf3x3IsTwiceTheReachableCount(): Unit \ Assert =
    let reachable = 43252003274489856000ii;
    Assert.assertEq(expected = reachable * 2ii, Orbit64.stateCount(3))

///
/// The classic figure for the 4x4x4, which divides by 24 because an even cube
/// has no fixed centres to pin its orientation. This codec does not quotient by
/// whole-cube rotation, so its count is exactly 24 times larger.
///
@Test
def stateCountOf4x4IsOrientationFree(): Unit \ Assert =
    let classic = 7401196841564901869874093974498574336000000000ii;
    Assert.assertEq(expected = classic * 24ii, Orbit64.stateCount(4))

@Test
def centreRadixIsMultinomial(): Unit \ Assert =
    // 24! / (4!)^6
    Assert.assertEq(expected = 3246670537110000ii, Orbit64.Orbit.radix(Centers))

// ---------- widths ----------

@Test
def tokenWidths(): Unit \ Assert =
    Assert.assertEq(expected = 5, Orbit64.width(2));
    Assert.assertEq(expected = 12, Orbit64.width(3));
    Assert.assertEq(expected = 27, Orbit64.width(4));
    Assert.assertEq(expected = 42, Orbit64.width(5));
    Assert.assertEq(expected = 66, Orbit64.width(6));
    Assert.assertEq(expected = 89, Orbit64.width(7))

///
/// Widths are distinct across sizes, so a token's length identifies its puzzle.
///
@Test
def widthsAreDistinct(): Unit \ Assert =
    let ws = List.range(2, 8) |> List.map(Orbit64.width);
    Assert.assertEq(expected = List.length(ws), List.toSet(ws) |> Set.size)

///
/// And nothing below the smallest cube borrows a real cube's width.
///
/// The arithmetic in `layout` does not stop on its own -- `(0-2)^2/4` is 1 --
/// so a 1x1x1 used to claim a corner orbit, match the 2x2x2's state count
/// exactly, and take the same five characters. A token's length is what says
/// which puzzle it belongs to, so that had to be a coincidence nobody could
/// hit rather than one that happened to be out of range.
///
@Test
def noSizeBelowTwoBorrowsARealWidth(): Unit \ Assert =
    let real = List.range(2, 8) |> List.map(Orbit64.width) |> List.toSet;
    List.range(-1, 2) |> List.forEach(n ->
        Assert.assertFalseWithMsg(Set.memberOf(Orbit64.width(n), real),
            "a ${n}x${n}x${n} takes the same width as a real cube"))

@Test
def nothingBelowTheSmallestCubeHasAnOrbit(): Unit \ Assert =
    List.range(-1, 2) |> List.forEach(n ->
        Assert.assertEqWithMsg(expected = (Nil: List[Orbit64.Orbit.Orbit]),
            Orbit64.Orbit.layout(n), "a ${n}x${n}x${n} claims an orbit"))

///
/// A width must actually address every state, and never be wider than needed.
///
@Test
def widthIsMinimal(): Unit \ Assert =
    List.range(2, 8) |> List.forEach(n -> {
        let w = Orbit64.width(n);
        let total = Orbit64.stateCount(n);
        Assert.assertTrue(BigInt.pow(base = 64ii, w) >= total);
        Assert.assertTrue(BigInt.pow(base = 64ii, w - 1) < total)
    })

// ---------- solved ----------

@Test
def solvedIsAllPaddingCharacters(): Unit \ Assert =
    List.range(2, 8) |> List.forEach(n ->
        Assert.assertEq(
            expected = Ok(String.repeat(Orbit64.width(n), "A")),
            Orbit64.encode(n, Orbit64.solved(n))))

@Test
def solvedCornersAreIdentity(): Unit \ Assert =
    Assert.assertEq(
        expected = CornerCoord(Vector.range(0, 8), Vector#{0, 0, 0, 0, 0, 0, 0, 0}),
        Orbit64.Coord.unrank(Corners, 0ii))

// ---------- round-trips ----------

@Test
def encodeDecodeRoundTripsForEverySize(): Unit \ Assert =
    List.range(2, 8) |> List.forEach(n -> {
        let orbits = Orbit64.Orbit.layout(n)
            |> List.map(o -> Orbit64.Coord.unrank(o, BigInt.modulo(pseudo(n, o), Orbit64.Orbit.radix(o))));
        match Orbit64.encode(n, orbits) {
            case Err(e)    => Assert.assert(false, RichString.fromString("encode failed: ${e}"))
            case Ok(token) => Assert.assertEq(expected = Ok(orbits), Orbit64.decode(n, token))
        }
    })

///
/// A deterministic spread of coordinates, so the round-trip test exercises
/// something other than the solved state without needing randomness.
///
def pseudo(n: Int32, o: Orbit64.Orbit.Orbit): BigInt =
    let seed = Int32.toBigInt(n * 7919 + Orbit64.Orbit.size(o) * 104729 + 17);
    seed * 6364136223846793005ii + 1442695040888963407ii

@Test
def coordRankUnrankAreInverse(): Unit \ Assert =
    List#{Corners, Midges, Wings, Centers} |> List.forEach(o ->
        List#{0ii, 1ii, 1000003ii} |> List.forEach(v -> {
            let x = BigInt.modulo(v, Orbit64.Orbit.radix(o));
            Assert.assertEq(expected = x, Orbit64.Coord.unrank(o, x) |> Orbit64.Coord.rank)
        }))

@Test
def unrankedCoordsAreValid(): Unit \ Assert =
    List#{Corners, Midges, Wings, Centers} |> List.forEach(o ->
        Assert.assertTrue(Orbit64.Coord.unrank(o, BigInt.modulo(987654321ii, Orbit64.Orbit.radix(o))) |> Orbit64.Coord.isValid))

// ---------- rank primitives ----------

@Test
def binomialValues(): Unit \ Assert =
    Assert.assertEq(expected = 10626, Orbit64.Rank.binomial(24, 4));
    Assert.assertEq(expected = 495, Orbit64.Rank.binomial(12, 4));
    Assert.assertEq(expected = 1, Orbit64.Rank.binomial(4, 4));
    Assert.assertEq(expected = 0, Orbit64.Rank.binomial(3, 4))

///
/// `C(n, k) = C(n, n - k)`, and taking the smaller side is what keeps the
/// running product from climbing through values far larger than the answer.
/// `C(100, 99)` is 100; computed the long way round it overflows `Int32` many
/// times over on the way.
///
@Test
def binomialIsSymmetricAndSurvivesTheLongSide(): Unit \ Assert = {
    Assert.assertEq(expected = 100, Orbit64.Rank.binomial(100, 99));
    Assert.assertEq(expected = 1, Orbit64.Rank.binomial(100, 100));
    List#{(24, 4), (30, 7), (52, 5)} |> List.forEach(match (n, k) ->
        Assert.assertEqWithMsg(expected = Orbit64.Rank.binomial(n, k), Orbit64.Rank.binomial(n, n - k),
            "C(${n}, ${k}) and C(${n}, ${n - k}) disagree"))
}

///
/// A coefficient too large for the return type says so by being the largest
/// thing it can be, never by wrapping. `combUnrank` climbs until this exceeds
/// a rank, and a negative never would -- which is how an out-of-range rank
/// used to send it climbing without end.
///
@Test
def binomialSaturatesRatherThanWrapping(): Unit \ Assert = {
    Assert.assertEq(expected = Int32.maxValue(), Orbit64.Rank.binomial(1000, 500));
    List#{(1000, 500), (200, 60), (60, 30)} |> List.forEach(match (n, k) ->
        Assert.assertTrueWithMsg(Orbit64.Rank.binomial(n, k) > 0,
            "C(${n}, ${k}) came back negative"))
}

///
/// And so an out-of-range rank terminates. It names no subset the caller asked
/// about -- there is no `n` here to ask about -- but it returns, in order, and
/// promptly.
///
@Test
def combUnrankTerminatesOnARankFromNowhere(): Unit \ Assert = {
    let got = Orbit64.Rank.combUnrank(2000000000, 4);
    Assert.assertEq(expected = 4, Vector.length(got));
    Assert.assertEq(expected = Vector.toList(got), List.sort(Vector.toList(got)))
}

@Test
def permRankIsIdentityAtZero(): Unit \ Assert =
    Assert.assertEq(expected = 0ii, Orbit64.Rank.permRank(Vector.range(0, 24)))

@Test
def permRankIsMaximalWhenReversed(): Unit \ Assert =
    let reversed = Vector.range(0, 8) |> Vector.map(i -> 7 - i);
    Assert.assertEq(expected = 40319ii, Orbit64.Rank.permRank(reversed))

@Test
def permRankUnrankRoundTrip(): Unit \ Assert =
    List#{0ii, 1ii, 40319ii, 123456789ii} |> List.forEach(r -> {
        let p = Orbit64.Rank.permUnrank(r, 12);
        Assert.assertEq(expected = r, Orbit64.Rank.permRank(p))
    })

@Test
def combRankUnrankRoundTrip(): Unit \ Assert =
    List.range(0, 10626) |> List.forEach(r ->
        if (Int32.modulo(r, 997) == 0)
            Assert.assertEq(expected = r, Orbit64.Rank.combUnrank(r, 4) |> Orbit64.Rank.combRank)
        else ())

@Test
def multisetRankUnrankRoundTrip(): Unit \ Assert =
    List#{0ii, 1ii, 3246670537109999ii} |> List.forEach(v -> {
        let labels = Orbit64.Rank.multisetUnrank(v, 24, 4, 6);
        Assert.assertEq(expected = v, Orbit64.Rank.multisetRank(labels, 4, 6))
    })

// ---------- error handling ----------

@Test
def decodeRejectsWrongLength(): Unit \ Assert =
    Assert.assertTrue(Orbit64.decode(3, "AAAA") |> Result.isErr)

@Test
def decodeRejectsCharactersOutsideTheAlphabet(): Unit \ Assert =
    Assert.assertTrue(Orbit64.decode(3, "AAAAAAAAAAA*") |> Result.isErr)

@Test
def decodeRejectsOutOfRangeTokens(): Unit \ Assert =
    Assert.assertTrue(Orbit64.decode(3, "____________") |> Result.isErr)

@Test
def encodeRejectsOrbitsThatDoNotMatchTheLayout(): Unit \ Assert =
    Assert.assertTrue(Orbit64.encode(3, List#{Orbit64.Coord.unrank(Corners, 0ii)}) |> Result.isErr)

///
/// A permutation with a repeat is not a cube, and ranks *inside* the
/// coordinate's range -- `permRank` cannot exceed `n!` whatever it is handed.
/// So nothing downstream can catch it: before this was refused, it encoded to
/// `AAAAAAAAAAAA`, the token for a solved cube.
///
@Test
def encodeRejectsAPermutationWithARepeat(): Unit \ Assert = {
    let bogus = CornerCoord(Vector#{0, 0, 2, 3, 4, 5, 6, 7}, Vector.repeat(8, 0));
    Assert.assertFalse(Orbit64.Coord.isValid(bogus));
    Assert.assertTrue(
        Orbit64.encode(3, List#{bogus, Orbit64.Coord.unrank(Midges, 0ii)}) |> Result.isErr)
}

///
/// Centre colours in the wrong multiplicities rank *above* the coordinate's
/// range, and the assembly is Horner -- so the surplus used to carry into the
/// neighbouring wing coordinate and corrupt a state that was correct.
///
@Test
def encodeRejectsCentresInTheWrongMultiplicities(): Unit \ Assert = {
    // Twenty-four slots exactly, but five 0s and three 1s. The 0s sit high so
    // the surplus combination term is large.
    let cols = Vector#{2,2,2,2, 3,3,3,3, 4,4,4,4, 5,5,5,5, 1,1,1, 0,0,0,0,0};
    Assert.assertEq(expected = 24, Vector.length(cols));
    let skewed = CenterCoord(cols);
    Assert.assertTrue(Orbit64.Coord.rank(skewed) >= Orbit64.Orbit.radix(Centers));
    Assert.assertTrue(Orbit64.encode(4, List#{
        Orbit64.Coord.unrank(Corners, 0ii),
        Orbit64.Coord.unrank(Wings, 0ii),
        skewed}) |> Result.isErr)
}

///
/// An orientation vector shorter than its orbit used to reach `rank`, which
/// read off the end of it and threw out of a function that returns `Result`.
///
@Test
def encodeRejectsAShortOrientationVectorRatherThanThrowing(): Unit \ Assert =
    Assert.assertTrue(Orbit64.encode(3, List#{
        CornerCoord(Vector.range(0, 8), Vector#{0, 0, 0}),
        Orbit64.Coord.unrank(Midges, 0ii)}) |> Result.isErr)

///
/// Refusing says which rule was broken, so a caller building coordinates from
/// its own model can find the mistake rather than only learn that it made one.
///
@Test
def refusingNamesTheRuleThatWasBroken(): Unit \ Assert = {
    let twisted = CornerCoord(Vector.range(0, 8), Vector#{1, 0, 0, 0, 0, 0, 0, 0});
    match Orbit64.Coord.faultOf(twisted) {
        case None      => Assert.assert(false, RichString.fromString("accepted a bad twist sum"))
        case Some(why) => Assert.assertTrue(String.contains(substr = "sum to 0 mod 3", why))
    };
    match Orbit64.encode(3, List#{twisted, Orbit64.Coord.unrank(Midges, 0ii)}) {
        case Ok(_)  => Assert.assert(false, RichString.fromString("encoded a bad twist sum"))
        case Err(e) => Assert.assertTrue(String.contains(substr = "Corners", e))
    }
}

///
/// Every state the codec can produce is one the codec will take back, so the
/// new check cannot refuse anything `decode` emits.
///
@Test
def everyDecodedStateStillEncodes(): Unit \ Assert =
    List.range(2, 8) |> List.forEach(n ->
        List#{0ii, 1ii, 987654321ii} |> List.forEach(seed -> {
            let orbits = Orbit64.Orbit.layout(n)
                |> List.map(o -> Orbit64.Coord.unrank(o,
                    BigInt.modulo(seed, Orbit64.Orbit.radix(o))));
            List.forEach(c -> Assert.assertTrueWithMsg(Orbit64.Coord.isValid(c),
                "unrank produced a coordinate encode would now refuse"), orbits);
            Assert.assertTrue(Orbit64.encode(n, orbits) |> Result.isOk)
        }))

///
/// The facelet tables are indexed by the piece in a slot, so a permutation
/// entry outside its orbit used to read off the end of one and throw out of a
/// function that returns `Option`.
///
@Test
def netDeclinesAStateThatIsNotACube(): Unit \ Assert = {
    let outOfRange = CornerCoord(Vector#{9, 1, 2, 3, 4, 5, 6, 7}, Vector.repeat(8, 0));
    Assert.assertEq(expected = None, Orbit64.Net.draw(2, List#{outOfRange}, false));
    let repeated = CornerCoord(Vector#{0, 0, 2, 3, 4, 5, 6, 7}, Vector.repeat(8, 0));
    Assert.assertEq(expected = None, Orbit64.Net.draw(2, List#{repeated}, false))
}

///
/// And still draws everything it drew before, so declining has not become the
/// answer to a question it can answer.
///
@Test
def netStillDrawsEveryDecodableSmallCube(): Unit \ Assert =
    List#{2, 3} |> List.forEach(n ->
        List#{0ii, 1ii, 987654321ii} |> List.forEach(seed -> {
            let orbits = Orbit64.Orbit.layout(n)
                |> List.map(o -> Orbit64.Coord.unrank(o,
                    BigInt.modulo(seed, Orbit64.Orbit.radix(o))));
            Assert.assertTrueWithMsg(
                not Option.isEmpty(Orbit64.Net.draw(n, orbits, false)),
                "declined to draw a ${n}x${n} state it decoded")
        }))

@Test
def alphabetIsSixtyFourDistinctUrlSafeCharacters(): Unit \ Assert =
    let a = Orbit64.alphabet();
    Assert.assertEq(expected = 64, String.length(a));
    Assert.assertEq(expected = 64, String.toList(a) |> List.toSet |> Set.size);
    Assert.assertEq(expected = 'A', String.charAt(0, a))

// ---------- the net renderer ----------

///
/// The expected nets are produced by an independent model of the same
/// convention, so these pin `Orbit64.Net`'s facelet tables rather than merely
/// restating them.
///

@Test
def solvedCubeDrawsSixSolidFaces(): Unit \ Assert =
    let expected = "          U  U  U \n          U  U  U \n          U  U  U \n L  L  L  F  F  F  R  R  R  B  B  B \n L  L  L  F  F  F  R  R  R  B  B  B \n L  L  L  F  F  F  R  R  R  B  B  B \n          D  D  D \n          D  D  D \n          D  D  D ";
    Assert.assertEq(expected = Some(expected), Orbit64.Net.draw(3, Orbit64.solved(3), false))

@Test
def superflipDrawsSolvedCornersAndFlippedEdges(): Unit \ Assert =
    let expected = "          U  B  U \n          L  U  R \n          U  F  U \n L  U  L  F  U  F  R  U  R  B  U  B \n B  L  F  L  F  R  F  R  B  R  B  L \n L  D  L  F  D  F  R  D  R  B  D  B \n          D  F  D \n          L  D  R \n          D  B  D ";
    let orbits = List#{
        CornerCoord(Vector.range(0, 8), Vector.repeat(8, 0)),
        MidgeCoord(Vector.range(0, 12), Vector.repeat(12, 1))
    };
    Assert.assertEq(expected = Some(expected), Orbit64.Net.draw(3, orbits, false))

@Test
def solved2x2DrawsFourStickersPerFace(): Unit \ Assert =
    let expected = "       U  U \n       U  U \n L  L  F  F  R  R  B  B \n L  L  F  F  R  R  B  B \n       D  D \n       D  D ";
    Assert.assertEq(expected = Some(expected), Orbit64.Net.draw(2, Orbit64.solved(2), false))

@Test
def sizesWithoutAConventionAreNotDrawn(): Unit \ Assert =
    List.range(5, 8) |> List.forEach(n ->
        Assert.assertEq(expected = None, Orbit64.Net.draw(n, Orbit64.solved(n), false)))

@Test
def colourWrapsEveryStickerAndResetsIt(): Unit \ Assert =
    match Orbit64.Net.draw(3, Orbit64.solved(3), true) {
        case None      => Assert.assertEq(expected = "a net", "nothing")
        case Some(net) =>
            // 54 stickers, each opened with a background and closed with a reset.
            Assert.assertEq(expected = 54, String.countSubstring(substr = "[48;5;", net));
            Assert.assertEq(expected = 54, String.countSubstring(substr = "[0m", net))
    }
