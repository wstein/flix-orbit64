use Orbit64.V2.Registry.{Model, Pose}
use Orbit64.V2.State.Cube

@Test
def independentFaceletRowsEncodeToTheirTokens(): Unit \ Assert =
    TestV2FaceletData.rows()
        |> List.forEach(
            match (id, _moves, facelets, token, _) -> Assert.assertEq(
                expected = Ok(token),
                Orbit64.V2.Facelets.encode(id, facelets)
            )
        )

@Test
def independentFaceletRowsDecodeToTheirFacelets(): Unit \ Assert =
    TestV2FaceletData.rows()
        |> List.forEach(match (
            id,
            moves,
            facelets,
            token,
            canonical
        ) -> match Orbit64.V2.Facelets.decode(token) {
            case Ok((e, text)) =>
                Assert.assertEq(expected = id, e#id);
                Assert.assertEq(expected = if (canonical == "") facelets else canonical, text)
            case Err(why)      => Assert.fail("${moves}: ${why}")
        })

@Test
def solvedFaceletsAreTheSolvedToken(): Unit \ Assert =
    Orbit64.V2.Registry.entries()
        |> List.filter(e -> e#model == Model.Color)
        |> List.forEach(
            e ->
                let n = e#n;
                let side = f -> String.repeat(n * n, f);
                let solved =
                    List#{"U", "R", "F", "D", "L", "B"} |> List.map(side) |> List.join(" ");
                Assert.assertEq(
                    expected = Orbit64.V2.Codec.encode(
                        e#id,
                        Orbit64.V2.State.solved(n, Model.Color)
                    ),
                    Orbit64.V2.Facelets.encode(e#id, solved)
                )
        )

def faceletError(text: String): Result[String, Cube] =
    Orbit64.V2.Facelets.fromFacelets(3, Model.Color, Pose.Framed, text)

/// A 3x3x3 string is rejected, and the message names the reason.
def assertRejected(reason: String, text: String): Unit \ Assert =
    match faceletError(text) {
        case Ok(_)    => Assert.fail("accepted: ${text}")
        case Err(why) => Assert.assertTrue(String.contains(substr = reason, why))
    }

@Test
def malformedFaceletsAreErrors(): Unit \ Assert =
    let solved3 = "UUUUUUUUU RRRRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB";
    Assert.assertTrue(Result.isOk(faceletError(solved3)));
    assertRejected("expected 54 facelets", "UUU");
    assertRejected(
        "'X' is not one of",
        "XUUUUUUUU RRRRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB"
    );
    assertRejected("is not one of", "UUUUUUUUU\tRRRRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB");
    assertRejected("is not one of", "UUUUUUUUU RRRRRRRRR\nFFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB");
    // One U sticker swapped for an R sticker: the color counts break.
    assertRejected(
        "color U occurs 8 times",
        "UUUUUUUUR RRRRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB"
    );
    // Two fixed centers exchanged: not a right-handed frame.
    assertRejected("right-handed", "UUUUUUUUU RRRRFRRRR FFFFRFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB");
    // The U and R stickers of the UR edge swapped: a single flipped edge.
    assertRejected(
        "midge flips must sum to 0 mod 2",
        "UUUUURUUU RURRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB"
    );
    // The URF corner turned in place: a single twisted corner.
    assertRejected(
        "corner twists must sum to 0 mod 3",
        "UUUUUUUUF URRRRRRRR FFRFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB"
    )

@Test
def aPieceThatIsNoPieceOfTheCubeIsAnError(): Unit \ Assert =
    // The U and R stickers of the URF corner exchanged: a mirrored corner, counts intact.
    assertRejected(
        "is no corner of this cube",
        "UUUUUUUUR URRRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB"
    )

@Test
def unsupportedTypesAreErrors(): Unit \ Assert =
    let solved3 = "UUUUUUUUU RRRRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB";
    let reason = (n, model) -> match Orbit64.V2.Facelets.fromFacelets(
        n,
        model,
        Pose.Framed,
        solved3
    ) {
        case Ok(_)    => ""
        case Err(why) => why
    };
    Assert.assertTrue(String.contains(substr = "no picture entry", reason(2, Model.Picture)));
    let letters = Orbit64.V2.Facelets.fromFacelets(3, Model.Picture, Pose.Framed, solved3);
    Assert.assertTrue(Result.isErr(letters));
    Assert.assertTrue(String.contains(substr = "no V2 type", reason(16, Model.Color)))
