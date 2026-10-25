//
// `Orbit64.Canonical`: one token per pattern.
//
// The vectors in `test/TestCanonicalVectors.flix` come from the reference
// implementation. The properties below hold at every size from the 2x2x2 to
// the 7x7x7, for the scrambled states of `roundTrippable` in
// `test/TestFromFacelets.flix`.
//

use Orbit64.Internal.Symmetry

def canonFace(letter: Char): Int32 = match letter {
    case 'U' => 0
    case 'R' => 1
    case 'F' => 2
    case 'D' => 3
    case 'L' => 4
    case _   => 5
}

def canonStickers(faces: List[String]): Vector[Int32] =
    faces |> List.flatMap(String.toList) |> List.map(canonFace) |> List.toVector

def canonFaceletsOf(n: Int32, token: String): Vector[Int32] =
    match Orbit64.State.decode(n, token) |> Result.flatMap(s -> Orbit64.Net.toFacelets(n, s)) {
        case Ok(fs) => fs
        case Err(_) => Vector.empty()
    }

def canonOf(n: Int32, token: String): String =
    match Orbit64.Canonical.fromToken(n, token) {
        case Ok(t)  => t
        case Err(e) => "error: ${e}"
    }

/// Two color renamings besides the identity.
def canonRenamings(): List[Vector[Int32]] =
    List#{
        Vector#{0, 1, 2, 3, 4, 5},
        Vector#{3, 0, 5, 1, 2, 4},
        Vector#{5, 4, 3, 2, 1, 0}
    }

@Test
def tokenVectorsMatchTheReference(): Unit \ Assert =
    canonicalTokenVectors() |> List.forEach(match (n, token, expected) ->
        Assert.assertEq(expected = expected, canonOf(n, token)))

@Test
def faceletVectorsMatchTheReference(): Unit \ Assert =
    canonicalFaceletVectors() |> List.forEach(match (n, faces, expected) ->
        Assert.assertEq(expected = Ok(expected),
                        Orbit64.Canonical.fromFacelets(n, canonStickers(faces))))

@Test
def theSolvedCubeIsTheTokenOfAllA(): Unit \ Assert =
    List.range(2, 8) |> List.forEach(n -> {
        let expected = String.repeat(Orbit64.State.width(n), "A");
        Assert.assertEq(expected = Ok(expected),
                        Orbit64.State.encode(n, Orbit64.State.solved(n))
                            |> Result.flatMap(t -> Orbit64.Canonical.fromToken(n, t)))
    })

@Test
def aCanonicalTokenIsItsOwnCanonicalForm(): Unit \ Assert =
    roundTrippable() |> List.forEach(match (n, token) -> {
        let canonical = canonOf(n, token);
        Assert.assertEq(expected = canonical, canonOf(n, canonical))
    })

///
/// Both directions: the canonical token decodes to a cube that draws as
/// facelets, which read back to the same state and re-encode to the token.
///
@Test
def aCanonicalTokenRoundTripsThroughFacelets(): Unit \ Assert =
    roundTrippable() |> List.forEach(match (n, token) -> {
        let canonical = canonOf(n, token);
        let state = Orbit64.State.decode(n, canonical);
        let back = state
            |> Result.flatMap(s -> Orbit64.Net.toFacelets(n, s))
            |> Result.flatMap(fs -> Orbit64.Net.fromFacelets(n, fs))
            |> Result.flatMap(s -> Orbit64.State.encode(n, s));
        Assert.assertEq(expected = Ok(canonical), back);
        Assert.assertEq(expected = Ok(canonical),
                        Orbit64.Canonical.fromFacelets(n, canonFaceletsOf(n, canonical)))
    })

///
/// The state a canonical token stands for is in the standard scheme: an odd
/// cube has its centers home and the frame 0, an even cube shows `U R F` in
/// the URF corner.
///
@Test
def aCanonicalTokenIsInTheStandardScheme(): Unit \ Assert =
    roundTrippable() |> List.forEach(match (n, token) -> {
        let fs = canonFaceletsOf(n, canonOf(n, token));
        let anchors = if (Int32.modulo(n, 2) == 1)
            List.range(0, 6) |> List.filterMap(f -> Symmetry.centerFacelet(n, f))
        else
            Symmetry.cornerStickers(n) |> List.head
                |> Option.map(Vector.toList) |> Option.getWithDefault(Nil);
        let expected = if (Int32.modulo(n, 2) == 1) List.range(0, 6) else List#{0, 1, 2};
        Assert.assertEq(expected = expected, List.map(i -> Vector.get(i, fs), anchors))
    })

@Test
def allFortyEightSymmetriesAndRenamingsGiveOneToken(): Unit \ Assert =
    roundTrippable() |> List.forEach(match (n, token) -> {
        let canonical = canonOf(n, token);
        let fs = canonFaceletsOf(n, token);
        List.range(0, Symmetry.count()) |> List.forEach(g ->
            canonRenamings() |> List.forEach(names -> {
                let moved = symmetryImage(n, g, fs)
                    |> Vector.map(c -> Vector.get(c, names));
                Assert.assertEq(expected = Ok(canonical),
                                Orbit64.Canonical.fromFacelets(n, moved))
            }))
    })

///
/// The 24 whole-cube frames of an odd cube are rotations written by the
/// existing frame code, independent of the symmetry tables.
///
@Test
def everyFrameOfAnOddCubeHasTheSameToken(): Unit \ Assert =
    roundTrippable() |> List.filter(match (n, _) -> Int32.modulo(n, 2) == 1)
        |> List.forEach(match (n, token) -> {
            let canonical = canonOf(n, token);
            match Orbit64.State.decode(n, token) {
                case Err(e)    => Assert.assertTrueWithMsg(false, e)
                case Ok(state) =>
                    List.range(0, Orbit64.Frame.count()) |> List.forEach(rank -> {
                        let turned = Orbit64.State.FramedState.FramedState(
                            Orbit64.Frame.unrank(rank), Orbit64.State.orbits(state));
                        Assert.assertEq(expected = Ok(canonical),
                                        Orbit64.Canonical.fromState(n, turned))
                    })
            }
        })

@Test
def differentColorStatesGetDifferentTokens(): Unit \ Assert =
    List.range(2, 8) |> List.forEach(n -> {
        let tokens = roundTrippable() |> List.filter(match (m, _) -> m == n)
            |> List.map(match (_, t) -> canonOf(n, t));
        Assert.assertEq(expected = List.length(tokens), Set.size(List.toSet(tokens)))
    })

@Test
def aSliceTurnThatMovesTheCentersHasAToken(): Unit \ Assert =
    // The fourth and fifth 3x3x3 facelet vectors are slice scrambles: the
    // centers are not home, so the cube is recolored before it is encoded.
    let slices = faceletVectors3a() |> List.drop(3) |> List.take(2);
    Assert.assertEq(expected = 2, List.length(slices));
    slices |> List.forEach(match (n, faces, expected) -> {
        let fs = canonStickers(faces);
        let centerColor = Symmetry.centerFacelet(n, 0)
            |> Option.map(at -> Vector.get(at, fs));
        Assert.assertTrue(centerColor != Some(0));
        Assert.assertEq(expected = Ok(expected), Orbit64.Canonical.fromFacelets(n, fs))
    })

/// The physically mirrored cube: stickers across the R/L plane, with the R
/// and L colors exchanged, so it is a cube in the standard scheme again.
def canonMirrorImage(n: Int32, fs: Vector[Int32]): Vector[Int32] =
    symmetryImage(n, Symmetry.mirrorAcrossRL(), fs) |> Vector.map(c ->
        if (c == 1) 4 else if (c == 4) 1 else c)

def canonStateToken(n: Int32, fs: Vector[Int32]): String =
    match Orbit64.Net.fromFacelets(n, fs)
            |> Result.flatMap(state -> Orbit64.State.encode(n, state)) {
        case Ok(t)  => t
        case Err(e) => "error: ${e}"
    }

///
/// A chiral pattern and its mirror image are different states with one
/// canonical token: the 48 symmetries include the mirrors.
///
@Test
def aChiralPatternAndItsMirrorImageShareAToken(): Unit \ Assert =
    roundTrippable() |> List.forEach(match (n, token) -> {
        let fs = canonFaceletsOf(n, token);
        let mirror = canonMirrorImage(n, fs);
        Assert.assertEq(expected = canonOf(n, token),
                        Orbit64.Canonical.fromFacelets(n, mirror) |> Result.getWithDefault(""))
    })

@Test
def theMirrorImagesOfScramblesAreOtherStates(): Unit \ Assert =
    List#{(3, "AP7AYhnwDQbA"), (3, "EKYDgqvYC5rw"), (4, "BJStkD4cayBhsWj6eHgDZLTP1th"),
          (5, "AQshP-X3WpOUAtv878ZKcZyT5P3So75Lb-WOh2gDJ2w")}
        |> List.forEach(match (n, token) -> {
            let mirror = canonMirrorImage(n, canonFaceletsOf(n, token));
            Assert.assertTrue(canonStateToken(n, mirror) != token);
            Assert.assertEq(expected = canonOf(n, token),
                            Orbit64.Canonical.fromFacelets(n, mirror) |> Result.getWithDefault(""))
        })

def canonSwap(i: Int32, j: Int32, fs: Vector[Int32]): Vector[Int32] =
    Vector.init(k -> if (k == i) Vector.get(j, fs) else if (k == j) Vector.get(i, fs)
                     else Vector.get(k, fs), Vector.length(fs))

@Test
def aTwistedCornerIsAnErrorAtEverySize(): Unit \ Assert =
    List.range(2, 8) |> List.forEach(n -> {
        let solved = Vector.range(0, 6 * n * n) |> Vector.map(i -> i / (n * n));
        let swapped = match Symmetry.cornerStickers(n) |> List.head {
            case Some(corner) => canonSwap(Vector.get(0, corner), Vector.get(1, corner), solved)
            case None         => solved
        };
        Assert.assertTrue(Result.isErr(Orbit64.Canonical.fromFacelets(n, swapped)))
    })

@Test
def aFlippedEdgeAndASwappedEdgePairAreErrors(): Unit \ Assert =
    let solved = canonFaceletsOf(3, "AAAAAAAAAAAA");
    // UR edge: U facelet 5 and R facelet 10; UF edge: U 7 and F 19.
    let flipped = canonSwap(5, 10, solved);
    let twoEdges = canonSwap(5, 7, canonSwap(10, 19, solved));
    Assert.assertTrue(Result.isErr(Orbit64.Canonical.fromFacelets(3, flipped)));
    Assert.assertTrue(Result.isErr(Orbit64.Canonical.fromFacelets(3, twoEdges)))

@Test
def swappedCentersAreAnErrorBecauseTheCornersDisagree(): Unit \ Assert =
    let solved = canonFaceletsOf(3, "AAAAAAAAAAAA");
    Assert.assertTrue(Result.isErr(Orbit64.Canonical.fromFacelets(3, canonSwap(4, 13, solved))))

@Test
def malformedFaceletsAreErrorsWithAReason(): Unit \ Assert =
    Assert.assertEq(expected = Err("expected 54 facelets for the 3x3x3, got 53"),
                    Orbit64.Canonical.fromFacelets(3, Vector.repeat(53, 0)));
    Assert.assertEq(expected = Err("every color must appear 9 times"),
                    Orbit64.Canonical.fromFacelets(3, Vector.repeat(54, 0)));
    Assert.assertEq(expected = Err("every facelet must name a face, 0 to 5"),
                    Orbit64.Canonical.fromFacelets(2, Vector.repeat(24, 6)));
    Assert.assertEq(expected = Err("every facelet must name a face, 0 to 5"),
                    Orbit64.Canonical.fromFacelets(2, Vector.repeat(24, -1)));
    Assert.assertEq(expected = Err("no slot convention for the 8x8x8: this module has one "
                                   + "only up to the 7x7x7"),
                    Orbit64.Canonical.fromFacelets(8, Vector.repeat(384, 0)));
    Assert.assertTrue(Result.isErr(Orbit64.Canonical.fromFacelets(1, Vector.repeat(6, 0))))

@Test
def malformedTokensAreErrors(): Unit \ Assert =
    Assert.assertTrue(Result.isErr(Orbit64.Canonical.fromToken(3, "AAAA")));
    Assert.assertTrue(Result.isErr(Orbit64.Canonical.fromToken(3, "AAAAAAAAAAA!")));
    Assert.assertTrue(Result.isErr(Orbit64.Canonical.fromToken(3, "__________")));
    Assert.assertTrue(Result.isErr(Orbit64.Canonical.fromToken(3, "____________")));
    Assert.assertTrue(Result.isErr(Orbit64.Canonical.fromToken(9, "AAAAA")))
