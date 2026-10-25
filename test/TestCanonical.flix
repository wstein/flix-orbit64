//
// `Orbit64.Canonical`: one token per pattern.
//
// The vectors in `test/TestCanonicalVectors.flix` come from the reference
// implementation. The properties below hold at every size from the 2x2x2 to
// the 7x7x7, for the scrambled states of `roundTrippable` in
// `test/TestFromFacelets.flix`.
//

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
    List#{Vector#{0, 1, 2, 3, 4, 5}, Vector#{3, 0, 5, 1, 2, 4}, Vector#{5, 4, 3, 2, 1, 0}}

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
            List.range(0, 6) |> List.map(f -> Orbit64.Symmetry.centerFacelet(n, f))
        else
            Orbit64.Symmetry.cornerStickers(n) |> List.head |> Option.map(Vector.toList)
                |> Option.getWithDefault(Nil);
        let expected = if (Int32.modulo(n, 2) == 1) List.range(0, 6) else List#{0, 1, 2};
        Assert.assertEq(expected = expected, List.map(i -> Vector.get(i, fs), anchors))
    })

@Test
def allFortyEightSymmetriesAndRenamingsGiveOneToken(): Unit \ Assert =
    roundTrippable() |> List.forEach(match (n, token) -> {
        let canonical = canonOf(n, token);
        let fs = canonFaceletsOf(n, token);
        List.range(0, Orbit64.Symmetry.count()) |> List.forEach(g ->
            canonRenamings() |> List.forEach(names -> {
                let moved = Orbit64.Symmetry.image(n, g, fs)
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
    // The last two 3x3x3 facelet vectors are slice scrambles: the centers are
    // not home, so the cube is recolored before it is encoded.
    let slices = canonicalFaceletVectors() |> List.filter(match (n, _, _) -> n == 3)
        |> List.drop(3);
    Assert.assertEq(expected = 2, List.length(slices));
    slices |> List.forEach(match (n, faces, expected) -> {
        let fs = canonStickers(faces);
        Assert.assertTrue(Vector.get(Orbit64.Symmetry.centerFacelet(n, 0), fs) != 0);
        Assert.assertEq(expected = Ok(expected), Orbit64.Canonical.fromFacelets(n, fs))
    })

@Test
def unreachableCubesAreErrorsNotTokens(): Unit \ Assert =
    let solved = canonFaceletsOf(3, "AAAAAAAAAAAA");
    let swap = (i, j) -> Vector.init(k ->
        if (k == i) Vector.get(j, solved) else if (k == j) Vector.get(i, solved)
        else Vector.get(k, solved), 54);
    // Two stickers of different colors exchanged: a twisted corner.
    Assert.assertTrue(Result.isErr(Orbit64.Canonical.fromFacelets(3, swap(8, 9))));
    // Two centers exchanged: a recoloring, whose corners then disagree.
    Assert.assertTrue(Result.isErr(Orbit64.Canonical.fromFacelets(3, swap(4, 13))))

@Test
def malformedFaceletsAreErrors(): Unit \ Assert =
    Assert.assertTrue(Result.isErr(Orbit64.Canonical.fromFacelets(3, Vector.repeat(53, 0))));
    Assert.assertTrue(Result.isErr(Orbit64.Canonical.fromFacelets(3, Vector.repeat(54, 0))));
    Assert.assertTrue(Result.isErr(Orbit64.Canonical.fromFacelets(8, Vector.repeat(384, 0))));
    Assert.assertTrue(Result.isErr(Orbit64.Canonical.fromToken(3, "AAAA")))
