//
// Typed algorithm DAG validation and exact size metadata.
//

use Orbit64.Algorithm.Algorithm.{Algorithm}
use Orbit64.Algorithm.Node.{Terminal, Concat, Repeat, Inverse, Block, PackedBlock, Partition, SliceParts}
use Orbit64.Move.Move.{LayerTurn}
use Orbit64.Move.Face.{U, R}
use Orbit64.Move.Amount.{Clockwise, CounterClockwise, Half}

@Test
def algorithmCountsConcatsRepeatsAndInversesWithoutExpansion(): Unit \ Assert =
    let dag = Algorithm(List#{
        Terminal(LayerTurn(U, 0, Clockwise)),
        Terminal(LayerTurn(R, 0, CounterClockwise)),
        Concat(List#{0, 1}),
        Repeat(2, 5ii),
        Inverse(3)
    }, 4);
    Assert.assertEq(expected = Ok(10ii), Orbit64.Algorithm.expandedCount(3, dag));
    Assert.assertTrue(Orbit64.Algorithm.faultOf(3, dag) |> Option.isEmpty)

@Test
def algorithmPreservesPartCountsForBlocksPackedBlocksAndSlices(): Unit \ Assert =
    let dag = Algorithm(List#{
        Terminal(LayerTurn(U, 0, Clockwise)),
        Terminal(LayerTurn(R, 0, Clockwise)),
        Block(List#{0, 1}),
        PackedBlock(List#{0, 1}, List#{1, 0, 1}),
        Partition(2, List#{0, 1, 2}),
        SliceParts(4, 0, 1)
    }, 5);
    Assert.assertEq(expected = Ok(1ii), Orbit64.Algorithm.expandedCount(3, dag));
    Assert.assertEq(expected = Ok(1ii), Orbit64.Algorithm.partCount(3, dag))

@Test
def algorithmRejectsInvalidReferencesCountsAndBoundaries(): Unit \ Assert =
    let forward = Algorithm(List#{Concat(List#{0})}, 0);
    let zeroRepeat = Algorithm(List#{
        Terminal(LayerTurn(U, 0, Clockwise)),
        Repeat(0, 0ii)
    }, 1);
    let badPartition = Algorithm(List#{
        Terminal(LayerTurn(U, 0, Clockwise)),
        Block(List#{0}),
        Partition(1, List#{0, 2})
    }, 2);
    Assert.assertFalse(Orbit64.Algorithm.faultOf(3, forward) |> Option.isEmpty);
    Assert.assertFalse(Orbit64.Algorithm.faultOf(3, zeroRepeat) |> Option.isEmpty);
    Assert.assertFalse(Orbit64.Algorithm.faultOf(3, badPartition) |> Option.isEmpty)

@Test
def algorithmStreamsSlicesAndInversesWithoutMaterializingThem(): Unit \ Assert =
    let u = LayerTurn(U, 0, Clockwise);
    let r = LayerTurn(R, 0, Half);
    let dag = Algorithm(List#{
        Terminal(u),
        Terminal(r),
        Block(List#{0, 1, 0}),
        SliceParts(2, 1, 3),
        Inverse(3),
        Repeat(4, 2ii)
    }, 5);
    let streamed = Orbit64.Algorithm.foldTerminals(3, dag, Nil,
        (out, move) -> move :: out) |> Result.map(List.reverse);
    Assert.assertEq(expected = Ok(List#{
        LayerTurn(U, 0, CounterClockwise), r,
        LayerTurn(U, 0, CounterClockwise), r
    }), streamed)

@Test
def algorithmTokenRoundTripsEveryNodeKindAndDispatches(): Unit \ Assert =
    let dag = Algorithm(List#{
        Terminal(LayerTurn(U, 0, Clockwise)),
        Terminal(LayerTurn(R, 0, Half)),
        Concat(List#{0, 1}),
        Repeat(2, 3ii),
        Inverse(3),
        Block(List#{0, 4}),
        PackedBlock(List#{0, 1}, List#{1, 0, 1}),
        Partition(5, List#{0, 1, 2}),
        SliceParts(7, 0, 1)
    }, 8);
    let token = Orbit64.Algorithm.Encoding.encode(3, dag);
    Assert.assertEq(expected = Ok(dag), token |> Result.flatMap(encoded ->
        Orbit64.Algorithm.Encoding.decode(encoded) |> Result.map(match (_, decoded) -> decoded)));
    Assert.assertTrue(token |> Result.map(encoded ->
        Orbit64.Token.decode(encoded) |> Result.map(value -> match value {
            case Orbit64.Token.Token.AlgorithmToken(_, decoded) => decoded == dag
            case _ => false
        })) == Ok(Ok(true)))

@Test
def algorithmTokenExportsAnEarlierOperation(): Unit \ Assert =
    let dag = Algorithm(List#{
        Terminal(LayerTurn(U, 0, Clockwise)),
        Terminal(LayerTurn(R, 0, Half)),
        Concat(List#{0, 1})
    }, 1);
    Assert.assertEq(expected = Ok(dag), Orbit64.Algorithm.Encoding.encode(3, dag)
        |> Result.flatMap(token -> Orbit64.Algorithm.Encoding.decode(token)
            |> Result.map(match (_, decoded) -> decoded)))
