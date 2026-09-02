use Orbit64.Move.Move.{LayerTurn}
use Orbit64.Move.Face.{U, R}
use Orbit64.Move.Amount.{Clockwise, CounterClockwise}

@Test
def loweringPreservesNamedSharingAndAlgebraicOperators(): Unit \ Assert =
    let source = "def a = U R\ndef b = [a: U]\ndef c = [b, R']\nexport c";
    let lowered = AlgorithmTool.Parser.parse(source)
        |> Result.flatMap(AlgorithmTool.Lowering.lower);
    Assert.assertEq(expected = Ok(12ii), lowered |> Result.flatMap(
        Orbit64.Algorithm.expandedCount(2)));
    Assert.assertTrue(lowered |> Result.map(algorithm ->
        Orbit64.Algorithm.faultOf(2, algorithm) |> Option.isEmpty) == Ok(true))

@Test
def loweredSourceRoundTripsThroughTheStructuredToken(): Unit \ Assert =
    let source = "def pair = (U R)3\ndef inverse = pair'\nexport inverse";
    let lowered = AlgorithmTool.Parser.parse(source)
        |> Result.flatMap(AlgorithmTool.Lowering.lower);
    let roundTripped = lowered |> Result.flatMap(algorithm ->
        Orbit64.Algorithm.Encoding.encode(2, algorithm) |> Result.flatMap(token ->
            Orbit64.Algorithm.Encoding.decode(token) |> Result.map(match (_, decoded) -> decoded)));
    Assert.assertEq(expected = lowered, roundTripped)

@Test
def reconstructedSourcePreservesTheExpandedMoveSequence(): Unit \ Assert =
    let source = "def pair = (U R)3\ndef inverse = pair'\nexport inverse";
    let original = AlgorithmTool.Parser.parse(source)
        |> Result.flatMap(AlgorithmTool.Lowering.lower);
    let reconstructed = AlgorithmTool.RoundTrip.roundTrip(2, source) |> Result.flatMap(
        match (_, text) -> AlgorithmTool.Parser.parse(text)
            |> Result.flatMap(AlgorithmTool.Lowering.lower));
    Assert.assertEq(expected = original |> Result.flatMap(Orbit64.Algorithm.expandedCount(2)),
        reconstructed |> Result.flatMap(Orbit64.Algorithm.expandedCount(2)))
