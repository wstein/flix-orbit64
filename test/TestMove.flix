//
// Primitive layer moves and their literal-sequence wire format.
//

use Orbit64.Move.Move.{LayerTurn}
use Orbit64.Move.Face.{U, R, B}
use Orbit64.Move.Amount.{Clockwise, Half, CounterClockwise}
use Orbit64.Move.LayerClass.LayerClass

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
    Assert.assertEq(expected = Ok("c"), Orbit64.Move.encode(3, Nil));
    Assert.assertEq(
        expected = Ok((LayerClass(1), (Nil: List[Orbit64.Move.Move]))),
        Orbit64.Move.decode("c"))

@Test
def literalMoveSequenceHasAStableToken(): Unit \ Assert =
    let moves = List#{
        LayerTurn(U, 0, Clockwise),
        LayerTurn(R, 0, Half)
    };
    Assert.assertEq(expected = Ok("d4"), Orbit64.Move.encode(3, moves));
    Assert.assertEq(expected = Ok((LayerClass(1), moves)), Orbit64.Move.decode("d4"))

@Test
def allSixBySixAndSevenBySevenLayersRoundTrip(): Unit \ Assert =
    let moves = List#{
        LayerTurn(U, 0, Clockwise),
        LayerTurn(R, 1, Half),
        LayerTurn(B, 2, CounterClockwise)
    };
    let tokens = List#{6, 7} |> List.map(n ->
        match Orbit64.Move.encode(n, moves) {
            case Err(e) => {
                Assert.assertTrueWithMsg(false, "encode failed: ${e}");
                ""
            }
            case Ok(t)  => {
                Assert.assertEq(
                    expected = Ok((LayerClass(3), moves)), Orbit64.Move.decode(t));
                t
            }
        });
    let first = List.head(tokens) |> Option.getWithDefault("");
    Assert.assertEq(expected = List.repeat(2, first), tokens)

@Test
def oddAndEvenCubePairsShareOneMoveToken(): Unit \ Assert =
    let move = List#{LayerTurn(B, 0, CounterClockwise)};
    Assert.assertEq(
        expected = Orbit64.Move.encode(2, move),
        Orbit64.Move.encode(3, move));
    Assert.assertEq(
        expected = Orbit64.Move.encode(4, List#{LayerTurn(B, 1, Half)}),
        Orbit64.Move.encode(5, List#{LayerTurn(B, 1, Half)}))

@Test
def longSequenceLengthIsRecoveredWithoutACountField(): Unit \ Assert =
    let moves = List.repeat(32, LayerTurn(U, 0, Clockwise));
    match Orbit64.Move.encode(3, moves) {
        case Err(e) => Assert.assertTrueWithMsg(false, "encode failed: ${e}")
        case Ok(t)  => Assert.assertEq(
            expected = Ok((LayerClass(1), moves)), Orbit64.Move.decode(t))
    }

@Test
def suppliedTwentyFiveMoveAlgorithmHasAnExactCompactVector(): Unit \ Assert =
    let moves = List#{
        LayerTurn(Orbit64.Move.Face.L, 0, Half),
        LayerTurn(U, 0, Half), LayerTurn(B, 0, Clockwise),
        LayerTurn(U, 0, CounterClockwise), LayerTurn(Orbit64.Move.Face.F, 0, Half),
        LayerTurn(Orbit64.Move.Face.D, 0, Clockwise), LayerTurn(B, 0, Half),
        LayerTurn(R, 0, Clockwise), LayerTurn(B, 0, Clockwise),
        LayerTurn(R, 0, Clockwise), LayerTurn(Orbit64.Move.Face.D, 0, Clockwise),
        LayerTurn(Orbit64.Move.Face.L, 0, CounterClockwise), LayerTurn(B, 0, Half),
        LayerTurn(U, 0, Half), LayerTurn(B, 0, Half), LayerTurn(R, 0, Half),
        LayerTurn(U, 0, Half), LayerTurn(Orbit64.Move.Face.L, 0, Half),
        LayerTurn(Orbit64.Move.Face.F, 0, CounterClockwise), LayerTurn(R, 0, Clockwise),
        LayerTurn(Orbit64.Move.Face.F, 0, Half),
        LayerTurn(Orbit64.Move.Face.D, 0, CounterClockwise),
        LayerTurn(R, 0, CounterClockwise), LayerTurn(Orbit64.Move.Face.D, 0, Clockwise),
        LayerTurn(Orbit64.Move.Face.L, 0, Clockwise)
    };
    Assert.assertEq(expected = Ok("feZUmCMgn6C3bYGJfz"), Orbit64.Move.encode(3, moves));
    Assert.assertEq(
        expected = Ok((LayerClass(1), moves)),
        Orbit64.Move.decode("feZUmCMgn6C3bYGJfz"))

@Test
def moveSequenceRejectsMalformedInput(): Unit \ Assert =
    Assert.assertTrue(Orbit64.Move.encode(1, Nil) |> Result.isErr);
    Assert.assertTrue(
        Orbit64.Move.encode(5, List#{LayerTurn(R, 2, Half)}) |> Result.isErr);
    Assert.assertTrue(Orbit64.Move.decode("AA") |> Result.isErr);
    Assert.assertTrue(Orbit64.Move.decode("Q") |> Result.isErr);
    Assert.assertTrue(Orbit64.Move.decode("cA") |> Result.isErr);
    Assert.assertTrue(Orbit64.Move.decode("c!") |> Result.isErr)
