//
// Primitive layer moves and their literal-sequence wire format.
//

use Orbit64.Move.Move.{LayerTurn}
use Orbit64.Move.Face.{U, R, B}
use Orbit64.Move.Amount.{Clockwise, Half, CounterClockwise}

@Test
def moveAlphabetGrowsWithReachableLayers(): Unit \ Assert =
    Assert.assertEq(expected = 18ii, Orbit64.Move.alphabetSize(2));
    Assert.assertEq(expected = 18ii, Orbit64.Move.alphabetSize(3));
    Assert.assertEq(expected = 36ii, Orbit64.Move.alphabetSize(4));
    Assert.assertEq(expected = 36ii, Orbit64.Move.alphabetSize(5));
    Assert.assertEq(expected = 54ii, Orbit64.Move.alphabetSize(6));
    Assert.assertEq(expected = 54ii, Orbit64.Move.alphabetSize(7));
    Assert.assertEq(expected = 72ii, Orbit64.Move.alphabetSize(8))

@Test
def moveFaultRejectsAnUnreachableDepth(): Unit \ Assert =
    Assert.assertFalse(Orbit64.Move.faultOf(5, LayerTurn(R, 2, Half)) |> Option.isEmpty);
    Assert.assertTrue(Orbit64.Move.faultOf(6, LayerTurn(R, 2, Half)) |> Option.isEmpty)

@Test
def everyMoveRankRoundTripsAtRepresentativeSizes(): Unit \ Assert =
    List#{2, 3, 4, 5, 6, 7, 18} |> List.forEach(n ->
        List.range(0, Orbit64.Move.alphabetSize(n) |> BigInt.tryToInt32
                |> Option.getWithDefault(0))
            |> List.forEach(rank ->
                Assert.assertEq(
                    expected = Int32.toBigInt(rank),
                    Orbit64.Move.unrank(n, Int32.toBigInt(rank))
                        |> Orbit64.Move.rank(n))))

@Test
def moveRanksRemainExactAtTheLargestRepresentableSize(): Unit \ Assert =
    let n = 2147483647;
    let last = LayerTurn(B, n / 2 - 1, CounterClockwise);
    Assert.assertEq(
        expected = 18ii * Int32.toBigInt(n / 2),
        Orbit64.Move.alphabetSize(n));
    Assert.assertEq(
        expected = Orbit64.Move.alphabetSize(n) - 1ii,
        Orbit64.Move.rank(n, last));
    Assert.assertEq(expected = last,
        Orbit64.Move.unrank(n, Orbit64.Move.rank(n, last)))

@Test
def emptyMoveSequenceHasNoRankPayload(): Unit \ Assert =
    Assert.assertEq(expected = Ok("RA"), Orbit64.Move.encode(3, Nil));
    Assert.assertEq(
        expected = Ok((3, (Nil: List[Orbit64.Move.Move]))),
        Orbit64.Move.decode("RA"))

@Test
def literalMoveSequenceHasAStableToken(): Unit \ Assert =
    let moves = List#{
        LayerTurn(U, 0, Clockwise),
        LayerTurn(R, 0, Half)
    };
    Assert.assertEq(expected = Ok("RCAE"), Orbit64.Move.encode(3, moves));
    Assert.assertEq(expected = Ok((3, moves)), Orbit64.Move.decode("RCAE"))

@Test
def allSixBySixAndSevenBySevenLayersRoundTrip(): Unit \ Assert =
    let moves = List#{
        LayerTurn(U, 0, Clockwise),
        LayerTurn(R, 1, Half),
        LayerTurn(B, 2, CounterClockwise)
    };
    List#{6, 7} |> List.forEach(n ->
        match Orbit64.Move.encode(n, moves) {
            case Err(e) => Assert.assertTrueWithMsg(false, "encode failed: ${e}")
            case Ok(t)  => Assert.assertEq(expected = Ok((n, moves)), Orbit64.Move.decode(t))
        })

@Test
def sizeEscapeHasOneCanonicalSpelling(): Unit \ Assert =
    Assert.assertEq(expected = Ok("fAA"), Orbit64.Move.encode(17, Nil));
    Assert.assertEq(
        expected = Ok((17, (Nil: List[Orbit64.Move.Move]))),
        Orbit64.Move.decode("fAA"));
    Assert.assertTrue(Orbit64.Move.decode("fAgA") |> Result.isErr);
    let tooLarge = Orbit64.Internal.Encoding.encodeVlq(2147483647)
        |> Result.map(v -> String.concat("f", v))
        |> Result.getWithDefault("");
    Assert.assertTrue(Orbit64.Move.decode(tooLarge) |> Result.isErr)

@Test
def sequenceCountMaySpanMoreThanOneSextet(): Unit \ Assert =
    let moves = List.repeat(32, LayerTurn(U, 0, Clockwise));
    match Orbit64.Move.encode(3, moves) {
        case Err(e) => Assert.assertTrueWithMsg(false, "encode failed: ${e}")
        case Ok(t)  => Assert.assertEq(expected = Ok((3, moves)), Orbit64.Move.decode(t))
    }

@Test
def moveSequenceRejectsMalformedInput(): Unit \ Assert =
    Assert.assertTrue(Orbit64.Move.encode(1, Nil) |> Result.isErr);
    Assert.assertTrue(
        Orbit64.Move.encode(5, List#{LayerTurn(R, 2, Half)}) |> Result.isErr);
    Assert.assertTrue(Orbit64.Move.decode("AA") |> Result.isErr);
    Assert.assertTrue(Orbit64.Move.decode("R") |> Result.isErr);
    Assert.assertTrue(Orbit64.Move.decode("RB_") |> Result.isErr)
