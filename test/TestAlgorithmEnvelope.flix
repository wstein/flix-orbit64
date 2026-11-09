// SPDX-License-Identifier: Apache-2.0
mod TestAlgorithmEnvelope {
    use Orbit64.Algorithm.Algorithm.Algorithm
    use Orbit64.Algorithm.Node
    use Orbit64.Algorithm.Envelope
    use Orbit64.Move.Move.LayerTurn
    use Orbit64.Move.Face.{U, R}
    use Orbit64.Move.Amount.{Clockwise, Half, CounterClockwise}

    def replace(src: String, dst: String, text: String): String =
        String.replace(src = src, dst = dst, text)

    def example(): Orbit64.Algorithm.Algorithm = Algorithm(
        Node.Terminal(LayerTurn(U, 0, Clockwise)) ::
        Node.Terminal(LayerTurn(R, 0, Half)) ::
        Node.Concat(0 :: 1 :: Nil) ::
        Node.Repeat(2, 1000000000000000000000000000000ii) ::
        Node.Inverse(2) ::
        Node.Block(0 :: 1 :: 2 :: Nil) ::
        Node.PackedBlock(0 :: 2 :: Nil, 1 :: 0 :: 1 :: Nil) ::
        Node.Partition(6, 0 :: 2 :: 3 :: Nil) ::
        Node.SliceParts(7, 0, 1) ::
        Node.Concat(8 :: 4 :: Nil) :: Nil, 9)

    @Test
    def allNodeKindsRoundTripWithoutChangingTopologyOrBoundaries(): Unit \ Assert =
        let encoded = Envelope.encode(3, example());
        Assert.assertEq(expected = Ok((3, example())),
            encoded |> Result.flatMap(Envelope.decode))

    @Test
    def canonicalEncodingIsAnExplicitIndependentEnvelope(): Unit \ Assert =
        let graph = Algorithm(Node.Terminal(LayerTurn(U, 0, Clockwise)) :: Nil, 0);
        let expected = "{\"format\":\"cube-algorithm-dag@1\"," +
            "\"moveProfile\":\"cube-layer-turns@1\",\"n\":3," +
            "\"nodes\":[[\"terminal\",\"U\",0,1]],\"root\":0}";
        Assert.assertEq(expected = Ok(expected), Envelope.encode(3, graph))

    @Test
    def partitionAndSlicePreserveTheExactTerminalStream(): Unit \ Assert =
        let recovered = Envelope.encode(3, example()) |> Result.flatMap(Envelope.decode);
        let actual = recovered |> Result.flatMap(match (n, graph) ->
            Orbit64.Algorithm.foldTerminals(n, graph, Nil, (out, move) -> move :: out)
                |> Result.mapErr(Envelope.Fault.InvalidGraph));
        Assert.assertEq(expected = Ok(List.reverse(
            LayerTurn(U, 0, Clockwise) :: LayerTurn(R, 0, Half) ::
            LayerTurn(U, 0, Clockwise) :: LayerTurn(R, 0, Half) ::
            LayerTurn(U, 0, CounterClockwise) :: Nil)), actual)

    @Test
    def hugeRepeatStaysSymbolicAndUnreachableNodesRemainPresent(): Unit \ Assert =
        let Algorithm(nodes, _) = example();
        let graph = Algorithm(nodes, 3);
        let actual = Envelope.encode(3, graph) |> Result.flatMap(Envelope.decode)
            |> Result.flatMap(match (n, decoded) -> Orbit64.Algorithm.expandedCount(n, decoded)
                |> Result.mapErr(Envelope.Fault.InvalidGraph));
        Assert.assertEq(expected = Ok(2000000000000000000000000000000ii), actual)

    @Test
    def invalidGraphsAreRejectedBeforeEncoding(): Unit \ Assert =
        let invalid = Algorithm(Node.Concat(0 :: Nil) :: Nil, 0);
        Assert.assertTrue(Result.isErr(Envelope.encode(3, invalid)));
        Assert.assertTrue(Result.isErr(Envelope.encode(1, example())));
        Assert.assertTrue(Result.isErr(Envelope.encode(3,
            Algorithm(Node.Terminal(LayerTurn(U, 1, Clockwise)) :: Nil, 0))))

    @Test
    def decodingRejectsAmbiguityUnknownFieldsAndNoncanonicalNumbers(): Unit \ Assert =
        let text = Envelope.encode(3, example()) |> Result.getWithDefault("");
        let variants = (" " + text) :: replace("\"n\":3", "\"n\":3.0", text) ::
            replace("\"format\":", "\"extra\":0,\"format\":", text) ::
            replace("\"n\":3", "\"n\":3,\"n\":3", text) ::
            replace("cube-algorithm-dag@1", "cube-algorithm-dag@2", text) ::
            replace("cube-layer-turns@1", "other", text) ::
            replace("\"root\":9", "\"root\":99", text) :: Nil;
        List.forEach(s -> Assert.assertTrue(Result.isErr(Envelope.decode(s))), variants)

    @Test
    def decimalCountsAndPackedSymbolsAreValidated(): Unit \ Assert =
        let text = Envelope.encode(3, example()) |> Result.getWithDefault("");
        Assert.assertTrue(Result.isErr(Envelope.decode(replace(
            "\"1000000000000000000000000000000\"", "\"01\"", text))));
        Assert.assertTrue(Result.isErr(Envelope.encode(3,
            Algorithm(Node.Terminal(LayerTurn(U, 0, Clockwise)) ::
                Node.PackedBlock(0 :: Nil, 1 :: Nil) :: Nil, 1))))

    @Test
    def eachResourceBudgetIsEnforcedOnEncodeAndDecode(): Unit \ Assert =
        let limits = Envelope.defaultLimits();
        let text = Envelope.encode(3, example()) |> Result.getWithDefault("");
        let restricted = {maxInputChars = 1 | limits} :: {maxNodes = 1 | limits} ::
            {maxReferences = 1 | limits} :: {maxSymbols = 1 | limits} ::
            {maxCountDigits = 1 | limits} :: {maxDepth = 1 | limits} ::
            {maxJsonDepth = 1 | limits} :: {maxMetadataWork = 1 | limits} :: Nil;
        List.forEach(bound -> {
            Assert.assertTrue(Result.isErr(Envelope.encodeWith(bound, 3, example())));
            Assert.assertTrue(Result.isErr(Envelope.decodeWith(bound, text)))
        }, restricted)

    @Test
    def preflightRejectsDeepUnknownJsonBeforeRecursiveParsing(): Unit \ Assert =
        let attack = List.repeat(5000, "[") |> List.join("");
        Assert.assertEq(
            expected = Err(Envelope.Fault.ResourceLimit("JSON nesting budget exceeded")),
            Envelope.decode(attack));
        Assert.assertEq(expected = Err(Envelope.Fault.Malformed("unknown format or move profile")),
            Envelope.decode("{\"format\":\"[[[[[[[[[[[[\"}"))

    @Test
    def labelsEscapesAndNumericSpellingsCannotSelectAnotherContract(): Unit \ Assert =
        let text = Envelope.encode(3, example()) |> Result.getWithDefault("");
        let variants = replace("cube-algorithm-dag@1", "cube-algorithm-dag@\\u0031", text) ::
            replace("\"n\":3", "\"n\":2147483648", text) ::
            replace("\"n\":3", "\"n\":1e999999999", text) ::
            replace("cube-layer-turns@1", "cübé", text) :: Nil;
        List.forEach(value -> Assert.assertTrue(Result.isErr(Envelope.decode(value))), variants);
        Assert.assertEq(expected = Err(Envelope.Fault.Malformed("only ASCII input is accepted")),
            Envelope.decode("é"));
        Assert.assertEq(
            expected = Err(Envelope.Fault.Malformed("JSON integer exceeds Int32 spelling")),
            Envelope.decode("9007199254740993"))

    @Test
    def invalidLimitsAreNotReportedAsInvalidGraphs(): Unit \ Assert =
        let bounds = {maxNodes = 0 | Envelope.defaultLimits()};
        let expected = Envelope.Fault.InvalidLimits(
            "limits must be positive and within reference ceilings");
        Assert.assertEq(expected = Err(expected), Envelope.decodeWith(bounds, "[]"));
        let high = {maxSymbols = 65537 | Envelope.defaultLimits()} ::
            {maxReferences = 65537 | Envelope.defaultLimits()} ::
            {maxNodes = 4097 | Envelope.defaultLimits()} :: Nil;
        List.forEach(value -> Assert.assertEq(expected = Err(expected),
            Envelope.decodeWith(value, "[]")), high)

    @Test
    def emptyNodesAndSizesOutsideStateRegistryKeepExistingAlgorithmSemantics(): Unit \ Assert =
        let graph = Algorithm(Node.Concat(Nil) :: Nil, 0);
        let golden = "{\"format\":\"cube-algorithm-dag@1\"," +
            "\"moveProfile\":\"cube-layer-turns@1\",\"n\":16," +
            "\"nodes\":[[\"concat\",[]]],\"root\":0}";
        Assert.assertEq(expected = Ok(golden), Envelope.encode(16, graph));
        Assert.assertEq(expected = Ok((16, graph)), Envelope.decode(golden));
        let inner = Algorithm(Node.Terminal(LayerTurn(U, 1, Half)) :: Nil, 0);
        Assert.assertEq(expected = Ok((4, inner)),
            Envelope.encode(4, inner) |> Result.flatMap(Envelope.decode))

    @Test
    def emptyPartsDuplicateAlphabetsAndEarlyRootsRemainLossless(): Unit \ Assert =
        let nodes = Node.Concat(Nil) :: Node.Block(Nil) ::
            Node.PackedBlock(Nil, Nil) :: Node.Partition(1, 0 :: Nil) ::
            Node.Partition(1, 0 :: 0 :: Nil) :: Node.SliceParts(4, 0, 0) ::
            Node.Inverse(4) :: Node.Terminal(LayerTurn(U, 0, Half)) ::
            Node.PackedBlock(7 :: 7 :: 0 :: Nil, 1 :: 1 :: Nil) ::
            Node.Partition(8, 0 :: 0 :: 2 :: Nil) ::
            Node.SliceParts(9, 0, 1) :: Nil;
        List.forEach(root -> {
            let graph = Algorithm(nodes, root);
            Assert.assertEq(expected = Ok((3, graph)),
                Envelope.encode(3, graph) |> Result.flatMap(Envelope.decode))
        }, List.range(0, List.length(nodes)))

    @Test
    def metadataCopiesAndRepeatedPartitionScansAreBoundedBeforeValidation(): Unit \ Assert =
        let base = Node.Terminal(LayerTurn(U, 0, Clockwise)) ::
            Node.PackedBlock(0 :: Nil, List.repeat(100, 0)) :: Nil;
        let limits = {maxMetadataWork = 1000 | Envelope.defaultLimits()};
        let copies = Algorithm(List.append(base, List.repeat(12, Node.Inverse(1))), 2);
        let scans = Algorithm(List.append(base, Node.Partition(1,
            List.append(List.repeat(100, 0), 100 :: Nil)) :: Nil), 2);
        List.forEach(graph -> Assert.assertEq(
            expected = Err(Envelope.Fault.ResourceLimit("metadata work budget exceeded")),
            Envelope.encodeWith(limits, 3, graph)), copies :: scans :: Nil)

    @Test
    def repeatDigitBudgetAggregatesAcrossStoredNodes(): Unit \ Assert =
        let graph = Algorithm(Node.Terminal(LayerTurn(U, 0, Half)) ::
            Node.Repeat(0, 1000000000000000000000000000000ii) ::
            Node.Repeat(1, 1000000000000000000000000000000ii) :: Nil, 2);
        let limits = {maxCountDigits = 50 | Envelope.defaultLimits()};
        Assert.assertEq(
            expected = Err(Envelope.Fault.ResourceLimit("repeat count digit budget exceeded")),
            Envelope.encodeWith(limits, 3, graph))

    @Test
    def largeStoredPackedWordsRoundTripWithoutExpandingRepeats(): Unit \ Assert =
        let graph = Algorithm(Node.Terminal(LayerTurn(U, 0, Clockwise)) ::
            Node.PackedBlock(0 :: Nil, List.repeat(65536, 0)) :: Nil, 1);
        Assert.assertEq(expected = Ok((3, graph)),
            Envelope.encode(3, graph) |> Result.flatMap(Envelope.decode))

    @Test
    def oversizedStoredListsFailBeforeRecursiveMetadata(): Unit \ Assert =
        let graph = Algorithm(Node.Terminal(LayerTurn(U, 0, Clockwise)) ::
            Node.PackedBlock(0 :: Nil, List.repeat(65537, 0)) :: Nil, 1);
        Assert.assertEq(expected = Err(Envelope.Fault.ResourceLimit(
            "packed-symbol/partition-boundary budget exceeded")), Envelope.encode(3, graph));
        let many = Algorithm(List.repeat(4096, Node.Terminal(LayerTurn(U, 0, Half))), 0);
        Assert.assertEq(expected = Ok((3, many)),
            Envelope.encode(3, many) |> Result.flatMap(Envelope.decode));
        let symbols = List.repeat(65537, "0") |> List.join(",");
        let wire = "{\"format\":\"cube-algorithm-dag@1\"," +
            "\"moveProfile\":\"cube-layer-turns@1\",\"n\":3," +
            "\"nodes\":[[\"terminal\",\"U\",0,1],[\"packedBlock\",[0],[" +
            symbols + "]]],\"root\":1}";
        Assert.assertEq(expected = Err(Envelope.Fault.ResourceLimit(
            "stored index-list budget exceeded")), Envelope.decode(wire))

    @Test
    def zeroNegativeCountsAndOversizedInt32OffsetsAreRejected(): Unit \ Assert =
        let base = Node.Terminal(LayerTurn(U, 0, Clockwise)) :: Nil;
        List.forEach(count -> Assert.assertTrue(Result.isErr(Envelope.encode(3,
            Algorithm(List.append(base, Node.Repeat(0, count) :: Nil), 1)))), 0ii :: -1ii :: Nil);
        let text = Envelope.encode(3, example()) |> Result.getWithDefault("");
        let invalid = replace("[\"sliceParts\",7,0,1]",
            "[\"sliceParts\",7,0,9007199254740993]", text);
        Assert.assertTrue(invalid != text);
        Assert.assertTrue(Result.isErr(Envelope.decode(invalid)))
}
