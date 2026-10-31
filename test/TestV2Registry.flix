use Orbit64.V2.Registry.{Model, Pose}

@Test
def registryHasFiftyFourEntries(): Unit \ Assert =
    Assert.assertEq(expected = 54, List.length(Orbit64.V2.Registry.entries()))

@Test
def registryLengthsMatchTheSpecification(): Unit \ Assert =
    let expected = List#{4, 5, 11, 12, 13, 14, 26, 27, 30, 31, 42, 42, 52, 53, 65, 66, 83, 83, 89, 90,
        118, 118, 121, 122, 161, 161, 154, 155, 209, 210, 194, 195, 265, 266, 236, 237, 326, 327,
        285, 285, 395, 396, 335, 336, 469, 470, 392, 393, 551, 552, 451, 452, 639, 639};
    Assert.assertEq(expected = expected, Orbit64.V2.Registry.entries() |> List.map(e -> e#length))

@Test
def registryOffsetsFollowTheAllocationRule(): Unit \ Assert =
    let entries = Orbit64.V2.Registry.entries();
    let offsetOf = id -> entries |> List.find(e -> e#id == id) |> Option.map(e -> e#offset);
    let countOf = id -> entries |> List.find(e -> e#id == id) |> Option.map(e -> e#count);
    let nonzero = entries |> List.filter(e -> e#offset != 0ii) |> List.map(e -> e#id);
    Assert.assertEq(expected = List#{11, 17, 21, 25, 39, 53}, nonzero);
    Assert.assertEq(expected = countOf(10), offsetOf(11));
    Assert.assertEq(expected = countOf(16), offsetOf(17));
    Assert.assertEq(expected = countOf(52), offsetOf(53))

@Test
def v1CountsAreV2ColorFramedCounts(): Unit \ Assert =
    List#{2, 3, 4, 5, 6, 7} |> List.forEach(n ->
        Assert.assertEq(expected = Orbit64.State.stateCount(n),
                        Orbit64.V2.State.count(n, Model.Color, Pose.Framed)))

@Test
def solvedStatesEncodeToRunsOfA(): Unit \ Assert =
    Orbit64.V2.Registry.entries() |> List.forEach(e ->
        let token = Orbit64.V2.Codec.encode(e#id, Orbit64.V2.State.solved(e#n, e#model));
        let zeros = Orbit64.Internal.Encoding.toBase64(e#offset, e#length);
        Assert.assertEq(expected = Ok(zeros), token))

@Test
def unknownTokensAreRejected(): Unit \ Assert =
    Assert.assertTrue(Result.isErr(Orbit64.V2.Codec.decode("")));
    Assert.assertTrue(Result.isErr(Orbit64.V2.Codec.decode("AAA")));
    Assert.assertTrue(Result.isErr(Orbit64.V2.Codec.decode("AAA!A")))
