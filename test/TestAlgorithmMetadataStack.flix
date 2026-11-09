// SPDX-License-Identifier: Apache-2.0
/// Metadata must handle stored lists without recursive result continuations.
mod TestAlgorithmMetadataStack {
    use Orbit64.Algorithm.Algorithm.Algorithm
    use Orbit64.Algorithm.Node
    use Orbit64.Move.Move.LayerTurn
    use Orbit64.Move.Face.{U, R}
    use Orbit64.Move.Amount.{Clockwise, CounterClockwise}

    def terminal(): Node = Node.Terminal(LayerTurn(U, 0, Clockwise))

    @Test
    def largePackedSymbolListsKeepAllPartsInOrder(): Unit \ Assert =
        let symbols = List.append(0 :: 1 :: Nil, List.repeat(65534, 0));
        let nodes = terminal() :: Node.Repeat(0, 2ii) ::
            Node.PackedBlock(0 :: 1 :: Nil, symbols) :: Node.SliceParts(2, 1, 2) :: Nil;
        Assert.assertEq(expected = Ok(65537ii),
            Orbit64.Algorithm.expandedCount(3, Algorithm(nodes, 2)));
        Assert.assertEq(expected = Ok(65536ii),
            Orbit64.Algorithm.partCount(3, Algorithm(nodes, 2)));
        Assert.assertEq(expected = Ok(2ii),
            Orbit64.Algorithm.expandedCount(3, Algorithm(nodes, 3)))

    @Test
    def largeReferenceListsKeepAllParts(): Unit \ Assert =
        let refs = List.append(0 :: 1 :: Nil, List.repeat(65534, 0));
        let nodes = terminal() :: Node.Repeat(0, 2ii) :: Node.Block(refs) ::
            Node.SliceParts(2, 1, 2) :: Nil;
        Assert.assertEq(expected = Ok(65537ii),
            Orbit64.Algorithm.expandedCount(3, Algorithm(nodes, 2)));
        Assert.assertEq(expected = Ok(65536ii),
            Orbit64.Algorithm.partCount(3, Algorithm(nodes, 2)));
        Assert.assertEq(expected = Ok(2ii),
            Orbit64.Algorithm.expandedCount(3, Algorithm(nodes, 3)))

    @Test
    def largePackedAlphabetsPreserveUnusedAndDuplicateReferences(): Unit \ Assert =
        let graph = Algorithm(terminal() ::
            Node.PackedBlock(List.repeat(65536, 0), 0 :: Nil) :: Nil, 1);
        Assert.assertEq(expected = Ok(1ii), Orbit64.Algorithm.expandedCount(3, graph))

    @Test
    def largePartitionBoundaryListsRetainEmptyParts(): Unit \ Assert =
        let boundaries = List.append(List.repeat(65535, 0), 1 :: Nil);
        let nodes = terminal() :: Node.Block(0 :: Nil) ::
            Node.Partition(1, boundaries) :: Node.SliceParts(2, 0, 1) :: Nil;
        Assert.assertEq(expected = Ok(1ii),
            Orbit64.Algorithm.expandedCount(3, Algorithm(nodes, 2)));
        Assert.assertEq(expected = Ok(65535ii),
            Orbit64.Algorithm.partCount(3, Algorithm(nodes, 2)));
        Assert.assertEq(expected = Ok(0ii),
            Orbit64.Algorithm.expandedCount(3, Algorithm(nodes, 3)))

    @Test
    def metadataErrorsStillChooseTheFirstBadPackedSymbol(): Unit \ Assert =
        let graph = symbols -> Algorithm(terminal() ::
            Node.PackedBlock(0 :: Nil, symbols) :: Nil, 1);
        Assert.assertEq(expected = Some("node 1: packed symbol cannot be negative"),
            Orbit64.Algorithm.faultOf(3, graph(-1 :: 2 :: Nil)));
        Assert.assertEq(expected = Some("node 1: packed symbol is outside its alphabet"),
            Orbit64.Algorithm.faultOf(3, graph(2 :: -1 :: Nil)));
        Assert.assertEq(expected = Some("node 1: a reference must point to an earlier node"),
            Orbit64.Algorithm.faultOf(3, Algorithm(terminal() ::
                Node.PackedBlock(-1 :: Nil, -1 :: Nil) :: Nil, 1)));
        Assert.assertEq(expected = Some("node 1: repeat count must be positive"),
            Orbit64.Algorithm.faultOf(3, Algorithm(terminal() ::
                Node.Repeat(99, 0ii) :: Nil, 1)))

    @Test
    def longPartitionStreamsKeepTheNonemptyPartAndInverseOrder(): Unit \ Assert =
        let boundaries = List.append(List.repeat(65535, 0), 1 :: Nil);
        let graph = Algorithm(terminal() :: Node.Block(0 :: Nil) ::
            Node.Partition(1, boundaries) :: Node.Inverse(2) :: Nil, 3);
        Assert.assertEq(expected = Ok(LayerTurn(U, 0, CounterClockwise) :: Nil),
            Orbit64.Algorithm.foldTerminals(3, graph, Nil, (out, move) -> move :: out))

    @Test
    def partitionAndInverseStreamsKeepAsymmetricOrder(): Unit \ Assert =
        let graph = Algorithm(terminal() ::
            Node.Terminal(LayerTurn(R, 0, Clockwise)) :: Node.Block(0 :: 1 :: Nil) ::
            Node.Partition(2, 0 :: 1 :: 1 :: 2 :: Nil) :: Node.Inverse(3) :: Nil, 4);
        let actual = Orbit64.Algorithm.foldTerminals(3, graph, Nil,
            (out, move) -> move :: out) |> Result.map(List.reverse);
        Assert.assertEq(expected = Ok(LayerTurn(R, 0, CounterClockwise) ::
            LayerTurn(U, 0, CounterClockwise) :: Nil), actual)

    @Test
    def inverseStablePartSizesKeepZeroAndUnequalChildren(): Unit \ Assert =
        let nodes = terminal() :: Node.Repeat(0, 2ii) :: Node.Concat(Nil) ::
            Node.Block(0 :: 1 :: 2 :: Nil) :: Node.Inverse(3) :: Nil;
        let counts = List.range(0, 3) |> List.map(i ->
            Orbit64.Algorithm.expandedCount(3, Algorithm(List.append(nodes,
                Node.SliceParts(4, i, i + 1) :: Nil), 5)));
        Assert.assertEq(expected = Ok(0ii) :: Ok(2ii) :: Ok(1ii) :: Nil, counts)
}
