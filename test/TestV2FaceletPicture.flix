use Orbit64.V2.Registry.{Model, Pose}
use Orbit64.V2.State.Cube

/// The solved 3x3x3 in the picture model: one symbol per facelet, see FORMAT-V2.md.
def pictureSolved3(): String =
    "GGJEAADCA BBLREXOJW EDCSIQRLN PKMMMISOV HFFVQTUNQ KHIWUUXPT"

def pictureStripped(text: String): List[Char] =
    String.toList(text) |> List.filter(c -> c != ' ')

/// The same string with the symbol at each given facelet index replaced.
def picturePut(n: Int32, text: String, edits: List[(Int32, Char)]): String =
    let chars = pictureStripped(text) |> List.mapWithIndex(i -> c ->
        List.find(e -> fst(e) == i, edits) |> Option.map(snd) |> Option.getWithDefault(c));
    List.range(0, 6) |> List.map(f ->
        chars |> List.drop(f * n * n) |> List.take(n * n)
              |> List.map(Char.toString) |> List.join(""))
        |> List.join(" ")

def pictureAt(text: String, index: Int32): Char =
    pictureStripped(text) |> List.drop(index) |> List.head |> Option.getWithDefault('?')

/// The string with the symbols at two facelets exchanged.
def pictureSwap(n: Int32, text: String, i: Int32, j: Int32): String =
    picturePut(n, text, (i, pictureAt(text, j)) :: (j, pictureAt(text, i)) :: Nil)

/// The solved picture of size `n`.
def pictureSolved(n: Int32, pose: Pose): String =
    match Orbit64.V2.Facelets.toFacelets(n, Model.Picture, pose,
                                         Orbit64.V2.State.solved(n, Model.Picture)) {
        case Ok(text) => text
        case Err(why) => why
    }

def pictureRead(n: Int32, pose: Pose, text: String): Result[String, Cube] =
    Orbit64.V2.Facelets.fromFacelets(n, Model.Picture, pose, text)

/// The string is rejected and the message names the reason.
def assertPictureRejected(n: Int32, reason: String, text: String): Unit \ Assert =
    match pictureRead(n, Pose.Framed, text) {
        case Ok(_) => Assert.fail("accepted: ${text}")
        case Err(why) =>
            if (String.contains(substr = reason, why)) ()
            else Assert.fail("wanted ${reason}, got ${why}")
    }

@Test
def pictureRowsEncodeToTheirTokens(): Unit \ Assert =
    TestV2FaceletPictureData.rows() |> List.forEach(match (id, _moves, facelets, token, _) ->
        Assert.assertEq(expected = Ok(token), Orbit64.V2.Facelets.encode(id, facelets)))

@Test
def pictureRowsDecodeToTheirFacelets(): Unit \ Assert =
    TestV2FaceletPictureData.rows() |> List.forEach(match (id, moves, facelets, token, canonical) ->
        match Orbit64.V2.Facelets.decode(token) {
            case Ok((e, text)) =>
                Assert.assertEq(expected = id, e#id);
                Assert.assertEq(expected = if (canonical == "") facelets else canonical, text)
            case Err(why) => Assert.fail("${moves}: ${why}")
        })

/// A row string read back and written again: the string itself, or the canonical one.
def pictureRoundTrip(id: Int32, facelets: String): Result[String, String] =
    match Orbit64.V2.Registry.entry(id) {
        case None => Err("no entry ${id}")
        case Some(e) => pictureRead(e#n, e#pose, facelets) |> Result.flatMap(cube ->
            Orbit64.V2.Facelets.toFacelets(e#n, Model.Picture, e#pose, cube))
    }

@Test
def pictureRowsRoundTripThroughTheCube(): Unit \ Assert =
    TestV2FaceletPictureData.rows() |> List.forEach(match (id, _moves, facelets, _, canonical) ->
        Assert.assertEq(expected = Ok(if (canonical == "") facelets else canonical),
                        pictureRoundTrip(id, facelets)))

@Test
def pictureRowsCoverEveryPictureEntryOfTheBridge(): Unit \ Assert =
    let covered = TestV2FaceletPictureData.rows() |> List.map(match (id, _, _, _, _) -> id);
    Orbit64.V2.Registry.entries() |> List.filter(e -> e#model == Model.Picture)
        |> List.forEach(e -> Assert.assertTrue(List.memberOf(e#id, covered)))

/// The solved cube of a picture entry.
def pictureSolvedCube(n: Int32): Cube = Orbit64.V2.State.solved(n, Model.Picture)

@Test
def solvedPicturesAreTheZeroTokens(): Unit \ Assert =
    Orbit64.V2.Registry.entries() |> List.filter(e -> e#model == Model.Picture)
        |> List.forEach(e ->
            let solved = pictureSolved(e#n, e#pose);
            let token = Orbit64.V2.Codec.encode(e#id, pictureSolvedCube(e#n));
            Assert.assertEq(expected = token, Orbit64.V2.Facelets.encode(e#id, solved));
            Assert.assertEq(expected = Ok(solved),
                            Result.flatMap(Orbit64.V2.Facelets.decode, token) |> Result.map(snd)))

@Test
def theSolvedThreeByThreeIsTheDocumentedString(): Unit \ Assert =
    Assert.assertEq(expected = pictureSolved3(), pictureSolved(3, Pose.Canonical))

@Test
def aSymbolIsNotAColorLetter(): Unit \ Assert =
    // The color model is unchanged: letters there, symbols here.
    Assert.assertEq(expected = Ok("UUUUUUUUU RRRRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB"),
                    Orbit64.V2.Facelets.toFacelets(3, Model.Color, Pose.Canonical,
                        Orbit64.V2.State.solved(3, Model.Color)))

@Test
def aFixedCenterRotationIsTheSymbolItself(): Unit \ Assert =
    // U and R centers each turned a quarter: symbols B (4 * 0 + 1) and F (4 * 1 + 1).
    let text = picturePut(3, pictureSolved3(), (4, 'B') :: (13, 'F') :: Nil);
    match pictureRead(3, Pose.Canonical, text) {
        case Err(why) => Assert.fail(why)
        case Ok(cube) =>
            Assert.assertEq(expected = List#{1, 1, 0, 0, 0, 0}, Vector.toList(cube#rotations));
            Assert.assertEq(expected = Ok(text),
                            Orbit64.V2.Facelets.toFacelets(3, Model.Picture, Pose.Canonical, cube))
    }

@Test
def aRotatedCubeKeepsItsStickersAndSpinsTheFixedCenters(): Unit \ Assert =
    // After `x` the cube shows F R D B L U in its slots; the stickers did not change.
    let turned = "EDCSIQRLN ORBJFBWXL PKMMMISOV TPXUWWIHK FTQFTNHVU ACDACEJGG";
    Assert.assertEq(expected = Ok("AAAAAAAAAAAAAE"), Orbit64.V2.Facelets.encode(5, turned));
    match Orbit64.V2.Facelets.encode(4, turned) {
        case Ok(token) => Assert.assertEq(expected = "AAAAAAAAAAAAA", token)
        case Err(why) => Assert.fail(why)
    }

// ------------------------------------------------------------ invalid strings

@Test
def malformedPicturesAreErrors(): Unit \ Assert =
    Assert.assertTrue(Result.isOk(pictureRead(3, Pose.Framed, pictureSolved3())));
    assertPictureRejected(3, "expected 54 facelets", "GGJ");
    assertPictureRejected(3, "is not a base64url symbol",
                          picturePut(3, pictureSolved3(), (0, '#') :: Nil));
    assertPictureRejected(3, "is not a base64url symbol",
                          String.replace(src = "GGJ", dst = "G\tJ", pictureSolved3()))

@Test
def aStickerOnTheWrongPieceTypeIsAnError(): Unit \ Assert =
    let solved = pictureSolved3();
    // Symbol Y is 24: no corner, midge or fixed center has that many stickers.
    assertPictureRejected(3, "which is no corner sticker", picturePut(3, solved, (0, 'Y') :: Nil));
    assertPictureRejected(3, "which is no midge sticker", picturePut(3, solved, (1, 'Y') :: Nil));
    assertPictureRejected(3, "which is no fixed center sticker",
                          picturePut(3, solved, (4, 'Y') :: Nil));
    assertPictureRejected(3, "which is no corner sticker", picturePut(3, solved, (0, '_') :: Nil));
    let solved5 = pictureSolved(5, Pose.Canonical);
    // Wings have 48 stickers and centers 24: `w` is 48.
    assertPictureRejected(5, "which is no wing sticker",
                          picturePut(5, solved5, (1, 'w') :: Nil));
    assertPictureRejected(5, "which is no center sticker",
                          picturePut(5, solved5, (6, 'Y') :: Nil))

@Test
def aDuplicateStickerIsAnError(): Unit \ Assert =
    let solved = pictureSolved3();
    // Facelet 0 gets the symbol of corner sticker A at facelet 8.
    assertPictureRejected(3, "corner sticker 'A' occurs more than once",
                          picturePut(3, solved, (0, 'A') :: Nil));
    assertPictureRejected(3, "midge sticker 'A' occurs more than once",
                          picturePut(3, solved, (1, 'A') :: Nil));
    // Two fixed centers that differ only in rotation are still the same piece.
    assertPictureRejected(3, "fixed center sticker 'B' occurs more than once",
                          picturePut(3, solved, (4, 'B') :: (13, 'B') :: Nil));
    let solved4 = pictureSolved(4, Pose.Canonical);
    let copy = (at, source) -> picturePut(4, solved4, (at, pictureAt(solved4, source)) :: Nil);
    assertPictureRejected(4, "center sticker", copy(5, 6));
    assertPictureRejected(4, "wing sticker", copy(1, 82))

@Test
def aPieceWithBrokenStickersIsAnError(): Unit \ Assert =
    let solved = pictureSolved3();
    // The U and R stickers of the URF corner exchanged: a mirrored corner.
    assertPictureRejected(3, "corner slot 0 shows BAC, which is no corner of this cube",
                          pictureSwap(3, solved, 8, 9));
    // The U sticker of UR and the R sticker of UF: two midges mixed.
    assertPictureRejected(3, "midge slot", pictureSwap(3, solved, 5, 19));
    // A wing with its two stickers exchanged.
    assertPictureRejected(4, "wing slot 0 shows",
                          pictureSwap(4, pictureSolved(4, Pose.Canonical), 1, 82))

@Test
def theFixedCentersMustFormAFrame(): Unit \ Assert =
    // The U and R centers exchanged: left-handed.
    assertPictureRejected(3, "right-handed", pictureSwap(3, pictureSolved3(), 4, 13))

@Test
def orientationLawsAreChecked(): Unit \ Assert =
    let solved = pictureSolved3();
    // The URF corner turned in place: stickers A B C become B C A.
    assertPictureRejected(3, "corner twists must sum to 0 mod 3",
                          picturePut(3, solved, (8, 'B') :: (9, 'C') :: (20, 'A') :: Nil));
    // The UR midge flipped: its two stickers exchanged.
    assertPictureRejected(3, "midge flips must sum to 0 mod 2", pictureSwap(3, solved, 5, 10))

@Test
def parityRelationsAreChecked(): Unit \ Assert =
    let solved = pictureSolved3();
    // The UR and UF midges exchanged with everything on them: M odd, C even.
    assertPictureRejected(3, "midge parity must equal corner parity",
                          pictureSwap(3, pictureSwap(3, solved, 5, 7), 10, 19));
    // One fixed center turned a quarter: R odd, C even.
    assertPictureRejected(3, "fixed-center rotation parity must equal corner parity",
                          picturePut(3, solved, (4, 'B') :: Nil));
    // Two center stickers of the 4x4x4 exchanged: Z odd, C even.
    let solved4 = pictureSolved(4, Pose.Canonical);
    assertPictureRejected(4, "a center orbit parity breaks the picture relation",
                          pictureSwap(4, solved4, 5, 6))

@Test
def the2x2x2HasNoPictureEntry(): Unit \ Assert =
    match Orbit64.V2.Facelets.fromFacelets(2, Model.Picture, Pose.Framed, "A") {
        case Ok(_) => Assert.fail("accepted")
        case Err(why) => Assert.assertTrue(String.contains(substr = "no picture entry", why))
    };
    match Orbit64.V2.Facelets.toFacelets(2, Model.Picture, Pose.Framed,
                                         Orbit64.V2.State.solved(2, Model.Color)) {
        case Ok(_) => Assert.fail("accepted")
        case Err(why) => Assert.assertTrue(String.contains(substr = "no picture entry", why))
    }

@Test
def aCubeThatBreaksALawHasNoPicture(): Unit \ Assert =
    let broken = { rotations = Vector#{1, 0, 0, 0, 0, 0} | pictureSolvedCube(3) };
    match Orbit64.V2.Facelets.toFacelets(3, Model.Picture, Pose.Canonical, broken) {
        case Ok(_) => Assert.fail("accepted")
        case Err(why) => Assert.assertTrue(String.contains(substr = "rotation parity", why))
    }
