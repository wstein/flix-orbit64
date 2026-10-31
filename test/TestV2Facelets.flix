use Orbit64.Coord.Coord
use Orbit64.V2.Registry.{Model, Pose}
use Orbit64.V2.State.Cube

/// V1 tokens of `TestFromFacelets`, read by V1 `Net` as the oracle for sizes 2 to 7.
def faceletV1Vectors(): List[(Int32, String)] = List#{
    (2, "AAAAA"), (2, "EJ6kr"), (2, "DJ5Lt"),
    (3, "AAAAAAAAAAAA"), (3, "AAAAAAAAAL_o"), (3, "AP7AYhnwDQbA"), (3, "EKYDgqvYC5rw"), (3, "D2jEMhvWfXr4"),
    (4, "AAAAAAAAAAAAAAAAAAAAAAAAAAA"), (4, "BJStkD4cayBhsWj6eHgDZLTP1th"), (4, "BAyxsFqZwWIK0XBrB-XoD7hRWKG"),
    (5, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"),
    (5, "AQshP-X3WpOUAtv878ZKcZyT5P3So75Lb-WOh2gDJ2w"),
    (5, "Abimx5h-4SZfPgXACHZ7cp7AnOpGx_9I5uksDjY-p8w"),
    (6, "A3aocAddmej0hGjOwe9lM25dHkohbB0JPB1zmbgUP6kaP6479xVsJGiNBL5DSU0WyT"),
    (6, "A6Nb35lYNtGK2C6U34A4G0BpXQ8daRZyrr8Wpwj020-30euw4zLqBg9qEFUNrCB5-0"),
    (7, "HGZiRBHyAvBeyPJYeQr8LLNmE7sB1-f4zgKgzw3fNRBFRyOB6jCsq4FgNyX5MUI_oHyctGUzsDRN98MqB2rVbi0ymA"),
    (7, "FnDspI3AJZn7ygtxjZXj40PrT5eZ0uiIM-JWMcqI744YTU_R410nHDfnXnEXg8O8wcT_eDrBVYZn_LbkOymKEsrL5g")
}

/// The V2 coordinates of a V1 state: the same orbits in the same order.
def faceletCubeOf(state: Orbit64.State.FramedState): Cube =
    let orbits = Orbit64.State.orbits(state);
    let wings = orbits |> List.filterMap(c -> match c { case Coord.WingCoord(w) => Some(w) case _ => None });
    let centers = orbits |> List.filterMap(c -> match c { case Coord.CenterCoord(z) => Some(z) case _ => None });
    let corners = orbits |> List.findMap(c -> match c { case Coord.CornerCoord(p, t) => Some((p, t)) case _ => None });
    let midges = orbits |> List.findMap(c -> match c { case Coord.MidgeCoord(p, f) => Some((p, f)) case _ => None });
    let (cp, ct) = Option.getWithDefault((Vector.empty(), Vector.empty()), corners);
    let (mp, mf) = Option.getWithDefault((Vector.empty(), Vector.empty()), midges);
    { cornerPieces = cp, cornerTwists = ct, midgePieces = mp, midgeFlips = mf,
      wings = List.toVector(wings), centers = List.toVector(centers), rotations = Vector.empty(),
      frame = Orbit64.Frame.rank(Orbit64.State.frame(state)) }

def faceletLetters(n: Int32, fs: Vector[Int32]): String =
    let l = Vector#{"U", "R", "F", "D", "L", "B"};
    Vector.range(0, 6) |> Vector.map(face ->
        Vector.range(0, n * n) |> Vector.map(i -> Vector.get(Vector.get(face * n * n + i, fs), l)) |> Vector.join(""))
        |> Vector.join(" ")

def faceletShow(c: Cube): String =
    "${c#cornerPieces} ${c#cornerTwists} ${c#midgePieces} ${c#midgeFlips} ${c#wings} ${c#centers} ${c#rotations} ${c#frame}"

@Test
def facelets2Through7AgreeWithV1Net(): Unit \ Assert =
    faceletV1Vectors() |> List.forEach(match (n, token) ->
        match Orbit64.State.decode(n, token) {
            case Err(why) => Assert.fail("${token}: ${why}")
            case Ok(state) => match Orbit64.Net.toFacelets(n, state) {
                case Err(why) => Assert.fail("${token}: ${why}")
                case Ok(fs) =>
                    let expected = faceletLetters(n, fs);
                    let cube = faceletCubeOf(state);
                    Assert.assertEq(expected = Ok(expected),
                                    Orbit64.V2.Facelets.toFacelets(n, Model.Color, Pose.Framed, cube));
                    match Orbit64.V2.Facelets.fromFacelets(n, Model.Color, Pose.Framed, expected) {
                        case Ok(back) => Assert.assertEq(expected = faceletShow(cube), faceletShow(back))
                        case Err(why) => Assert.fail("${token}: ${why}")
                    }
            }
        })

@Test
def independentFaceletRowsEncodeToTheirTokens(): Unit \ Assert =
    TestV2FaceletData.rows() |> List.forEach(match (id, _moves, facelets, token, _) ->
        Assert.assertEq(expected = Ok(token), Orbit64.V2.Facelets.encode(id, facelets)))

@Test
def independentFaceletRowsDecodeToTheirFacelets(): Unit \ Assert =
    TestV2FaceletData.rows() |> List.forEach(match (id, moves, facelets, token, canonical) ->
        match Orbit64.V2.Facelets.decode(token) {
            case Ok((e, text)) =>
                Assert.assertEq(expected = id, e#id);
                Assert.assertEq(expected = if (canonical == "") facelets else canonical, text)
            case Err(why) => Assert.fail("${moves}: ${why}")
        })

@Test
def solvedFaceletsAreTheSolvedToken(): Unit \ Assert =
    Orbit64.V2.Registry.entries() |> List.filter(e -> e#model == Model.Color) |> List.forEach(e ->
        let n = e#n;
        let side = f -> String.repeat(n * n, f);
        let solved = List#{"U", "R", "F", "D", "L", "B"} |> List.map(side) |> List.join(" ");
        Assert.assertEq(expected = Orbit64.V2.Codec.encode(e#id, Orbit64.V2.State.solved(n, Model.Color)),
                        Orbit64.V2.Facelets.encode(e#id, solved)))

@Test
def malformedFaceletsAreErrors(): Unit \ Assert =
    let solved3 = "UUUUUUUUU RRRRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB";
    let fromText = text -> Orbit64.V2.Facelets.fromFacelets(3, Model.Color, Pose.Framed, text);
    Assert.assertTrue(Result.isOk(fromText(solved3)));
    Assert.assertTrue(Result.isErr(fromText("UUU")));
    Assert.assertTrue(Result.isErr(fromText("XUUUUUUUU RRRRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB")));
    // One U sticker swapped for an R sticker: the color counts break.
    Assert.assertTrue(Result.isErr(fromText("UUUUUUUUR RRRRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB")));
    // Two edge stickers exchanged: a flipped edge alone breaks the flip law.
    Assert.assertTrue(Result.isErr(fromText("UUUUUUUUU RURRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB")));
    // Two fixed centers exchanged: not a right-handed frame.
    Assert.assertTrue(Result.isErr(fromText("UUUUUUUUU RRRRFRRRR FFFFRFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB")));
    Assert.assertTrue(Result.isErr(Orbit64.V2.Facelets.fromFacelets(3, Model.Picture, Pose.Framed, solved3)));
    Assert.assertTrue(Result.isErr(Orbit64.V2.Facelets.fromFacelets(16, Model.Color, Pose.Framed, solved3)))

@Test
def aSingleTwistedCornerIsAnError(): Unit \ Assert =
    // The URF corner twisted in place: U sticker 8, R sticker 9, F sticker 20 rotate their colors.
    let twisted = "UUUUUUUUR FRRRRRRRR UFFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB";
    Assert.assertTrue(Result.isErr(
        Orbit64.V2.Facelets.fromFacelets(3, Model.Color, Pose.Framed, twisted)))
