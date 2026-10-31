use Orbit64.Coord.Coord
use Orbit64.V2.Registry.{Model, Pose}
use Orbit64.V2.State.Cube

/// V1 tokens of `TestFromFacelets`, read by V1 `Net` as the oracle for sizes 2 to 7.
def faceletV1Vectors(): List[(Int32, String)] = List#{
    (2, "AAAAA"), (2, "EJ6kr"), (2, "DJ5Lt"),
    (3, "AAAAAAAAAAAA"), (3, "AAAAAAAAAL_o"), (3, "AP7AYhnwDQbA"),
    (3, "EKYDgqvYC5rw"), (3, "D2jEMhvWfXr4"), (3, "AAAAAAAAAAAE"),
    (4, "AAAAAAAAAAAAAAAAAAAAAAAAAAA"),
    (4, "BJStkD4cayBhsWj6eHgDZLTP1th"),
    (4, "BAyxsFqZwWIK0XBrB-XoD7hRWKG"),
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
    let wings = orbits |> List.filterMap(c -> match c {
        case Coord.WingCoord(w) => Some(w)
        case _ => None
    });
    let centers = orbits |> List.filterMap(c -> match c {
        case Coord.CenterCoord(z) => Some(z)
        case _ => None
    });
    let corners = orbits |> List.findMap(c -> match c {
        case Coord.CornerCoord(p, t) => Some((p, t))
        case _ => None
    });
    let midges = orbits |> List.findMap(c -> match c {
        case Coord.MidgeCoord(p, f) => Some((p, f))
        case _ => None
    });
    let none = (Vector.empty(), Vector.empty());
    let (cp, ct) = Option.getWithDefault(none, corners);
    let (mp, mf) = Option.getWithDefault(none, midges);
    { cornerPieces = cp, cornerTwists = ct, midgePieces = mp, midgeFlips = mf,
      wings = List.toVector(wings), centers = List.toVector(centers), rotations = Vector.empty(),
      frame = Orbit64.Frame.rank(Orbit64.State.frame(state)) }

def faceletLetters(n: Int32, fs: Vector[Int32]): String =
    let l = Vector#{"U", "R", "F", "D", "L", "B"};
    let letter = i -> Vector.get(Vector.get(i, fs), l);
    Vector.range(0, 6) |> Vector.map(face ->
        Vector.range(0, n * n) |> Vector.map(i -> letter(face * n * n + i)) |> Vector.join(""))
        |> Vector.join(" ")

def faceletShow(c: Cube): String =
    "${c#cornerPieces} ${c#cornerTwists} ${c#midgePieces} ${c#midgeFlips} "
    + "${c#wings} ${c#centers} ${c#rotations} ${c#frame}"

/// The same orbits with the whole-cube frame `rank`.
def faceletFramed(state: Orbit64.State.FramedState, rank: Int32): Orbit64.State.FramedState =
    Orbit64.State.FramedState.FramedState(Orbit64.Frame.unrank(rank), Orbit64.State.orbits(state))

/// What V1 `Net` writes for a state.
def faceletNet(n: Int32, state: Orbit64.State.FramedState): Result[String, String] =
    Orbit64.Net.toFacelets(n, state) |> Result.map(fs -> faceletLetters(n, fs))

def faceletWrite(n: Int32, state: Orbit64.State.FramedState): Result[String, String] =
    Orbit64.V2.Facelets.toFacelets(n, Model.Color, Pose.Framed, faceletCubeOf(state))

def faceletRead(n: Int32, pose: Pose, text: String): Result[String, String] =
    Orbit64.V2.Facelets.fromFacelets(n, Model.Color, pose, text) |> Result.map(faceletShow)

/// The state `state` has the same facelets in V2 as in V1 `Net`, and V2 reads them back.
def faceletAgreesWithNet(n: Int32, state: Orbit64.State.FramedState): Unit \ Assert =
    match faceletNet(n, state) {
        case Err(why) => Assert.fail("${n}: ${why}")
        case Ok(expected) =>
            Assert.assertEq(expected = Ok(expected), faceletWrite(n, state));
            Assert.assertEq(expected = Ok(faceletShow(faceletCubeOf(state))),
                            faceletRead(n, Pose.Framed, expected))
    }

/// A rotated odd cube: V2 writes what `Net` writes, reads the same frame and
/// state, and a canonical read rotates it back to frame 0.
def faceletAgreesWithNetRotated(n: Int32, state: Orbit64.State.FramedState, rank: Int32): Unit \ Assert =
    let turned = faceletFramed(state, rank);
    match faceletNet(n, turned) {
        case Err(why) => Assert.fail("${n} frame ${rank}: ${why}")
        case Ok(expected) =>
            Assert.assertEq(expected = Ok(expected), faceletWrite(n, turned));
            Assert.assertEq(expected = Ok(faceletShow(faceletCubeOf(turned))),
                            faceletRead(n, Pose.Framed, expected));
            Assert.assertEq(expected = Ok(faceletShow(faceletCubeOf(faceletFramed(state, 0)))),
                            faceletRead(n, Pose.Canonical, expected))
    }

@Test
def facelets2Through7AgreeWithV1Net(): Unit \ Assert =
    faceletV1Vectors() |> List.forEach(match (n, token) ->
        match Orbit64.State.decode(n, token) {
            case Err(why) => Assert.fail("${token}: ${why}")
            case Ok(state) => faceletAgreesWithNet(n, state)
        })

@Test
def rotatedOddCubesAgreeWithV1NetAndFrame(): Unit \ Assert =
    faceletV1Vectors() |> List.filter(match (n, _) -> n >= 3 and Int32.modulo(n, 2) == 1)
        |> List.forEach(match (n, token) ->
            match Orbit64.State.decode(n, token) {
                case Err(why) => Assert.fail("${token}: ${why}")
                case Ok(state) => List.range(1, Orbit64.Frame.count()) |> List.forEach(rank ->
                    faceletAgreesWithNetRotated(n, state, rank))
            })

@Test
def aV1TokenWithAFrameIsTheSolvedCubeAfterX(): Unit \ Assert =
    // FORMAT.md: AAAAAAAAAAAE is the solved 3x3x3 after `x`, frame F R D B L U.
    let shown = "FFFFFFFFF RRRRRRRRR DDDDDDDDD BBBBBBBBB LLLLLLLLL UUUUUUUUU";
    match Orbit64.State.decode(3, "AAAAAAAAAAAE") {
        case Err(why) => Assert.fail(why)
        case Ok(state) =>
            Assert.assertEq(expected = 4, Orbit64.Frame.rank(Orbit64.State.frame(state)));
            Assert.assertEq(expected = Ok(shown), faceletNet(3, state));
            Assert.assertEq(expected = Ok(shown), faceletWrite(3, state));
            Assert.assertEq(expected = Ok(faceletShow(faceletCubeOf(state))),
                            faceletRead(3, Pose.Framed, shown))
    }

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

def faceletError(text: String): Result[String, Cube] =
    Orbit64.V2.Facelets.fromFacelets(3, Model.Color, Pose.Framed, text)

/// A 3x3x3 string is rejected, and the message names the reason.
def assertRejected(reason: String, text: String): Unit \ Assert =
    match faceletError(text) {
        case Ok(_) => Assert.fail("accepted: ${text}")
        case Err(why) => Assert.assertTrue(String.contains(substr = reason, why))
    }

@Test
def malformedFaceletsAreErrors(): Unit \ Assert =
    let solved3 = "UUUUUUUUU RRRRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB";
    Assert.assertTrue(Result.isOk(faceletError(solved3)));
    assertRejected("expected 54 facelets", "UUU");
    assertRejected("'X' is not one of", "XUUUUUUUU RRRRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB");
    assertRejected("is not one of", "UUUUUUUUU\tRRRRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB");
    assertRejected("is not one of", "UUUUUUUUU RRRRRRRRR\nFFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB");
    // One U sticker swapped for an R sticker: the color counts break.
    assertRejected("color U occurs 8 times", "UUUUUUUUR RRRRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB");
    // Two fixed centers exchanged: not a right-handed frame.
    assertRejected("right-handed", "UUUUUUUUU RRRRFRRRR FFFFRFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB");
    // The U and R stickers of the UR edge swapped: a single flipped edge.
    assertRejected("midge flips must sum to 0 mod 2",
                   "UUUUURUUU RURRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB");
    // The URF corner turned in place: a single twisted corner.
    assertRejected("corner twists must sum to 0 mod 3",
                   "UUUUUUUUF URRRRRRRR FFRFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB")

@Test
def aPieceThatIsNoPieceOfTheCubeIsAnError(): Unit \ Assert =
    // The U and R stickers of the URF corner exchanged: a mirrored corner, counts intact.
    assertRejected("is no corner of this cube",
                   "UUUUUUUUR URRRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB")

@Test
def unsupportedTypesAreErrors(): Unit \ Assert =
    let solved3 = "UUUUUUUUU RRRRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB";
    let reason = (n, model) -> match Orbit64.V2.Facelets.fromFacelets(n, model, Pose.Framed, solved3) {
        case Ok(_) => ""
        case Err(why) => why
    };
    Assert.assertTrue(String.contains(substr = "picture model", reason(3, Model.Picture)));
    Assert.assertTrue(String.contains(substr = "no V2 type", reason(16, Model.Color)))
