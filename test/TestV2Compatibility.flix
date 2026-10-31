use Orbit64.V2.Registry.{Model, Pose}

/// V1 state tokens of the vectors in `TestVectors`, with the V2 entry that reads them.
def v1Tokens(): List[(Int32, String)] = List#{
    (1, "AAAAA"), (1, "EJ6kr"), (1, "DJ5Lt"),
    (3, "AAAAAAAAAAAA"), (3, "AAAAAAAAAL_o"), (3, "AP7AYhnwDQbA"),
    (3, "EKYDgqvYC5rw"), (3, "D2jEMhvWfXr4"),
    (7, "AAAAAAAAAAAAAAAAAAAAAAAAAAA"), (7, "BJStkD4cayBhsWj6eHgDZLTP1th")
}

@Test
def v1StateTokensReadAsV2ColorFramedStates(): Unit \ Assert =
    v1Tokens() |> List.forEach(match (id, token) ->
        match Orbit64.V2.Codec.decode(token) {
            case Ok((e, cube)) =>
                Assert.assertEq(expected = id, e#id);
                Assert.assertEq(expected = Ok(token), Orbit64.V2.Codec.encode(id, cube));
                assertSameCorners(e#n, token, cube)
            case Err(why) => Assert.fail("${token}: ${why}")
        })

@Test
def v1FiveByFiveTokensAreRejected(): Unit \ Assert =
    let token = String.repeat(43, "A");
    Assert.assertTrue(Result.isErr(Orbit64.V2.Codec.decode(token)))

@Test
def v1AndV2AgreeOnTheFramedColorStateCount(): Unit \ Assert =
    List#{2, 3, 4, 6, 7} |> List.forEach(n ->
        Assert.assertEq(expected = Orbit64.State.stateCount(n),
                        Orbit64.V2.State.count(n, Model.Color, Pose.Framed)))

/// V1 and V2 must read the same corner state from the same token.
def assertSameCorners(n: Int32, token: String, cube: Orbit64.V2.State.Cube): Unit \ Assert =
    match Orbit64.State.decode(n, token) {
        case Ok(state) => match Orbit64.State.orbits(state) {
            case Orbit64.Coord.Coord.CornerCoord(pieces, twists) :: _ =>
                Assert.assertEq(expected = pieces, cube#cornerPieces);
                Assert.assertEq(expected = twists, cube#cornerTwists)
            case _ => Assert.fail("${token}: V1 state has no corner coordinate")
        }
        case Err(why) => Assert.fail("${token}: ${why}")
    }
