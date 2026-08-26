//
// Properties of the codec that hold independently of any reference data:
// sizes, round-trips, and the invariants the format is built on.
//

use Orbit64.Coord.Coord.{CornerCoord, WingCoord, CenterCoord}
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

@Test
def alphabetIsSixtyFourDistinctUrlSafeCharacters(): Unit \ Assert =
    let a = Orbit64.alphabet();
    Assert.assertEq(expected = 64, String.length(a));
    Assert.assertEq(expected = 64, String.toList(a) |> List.toSet |> Set.size);
    Assert.assertEq(expected = 'A', String.charAt(0, a))
