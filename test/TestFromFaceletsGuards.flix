//
// What `Orbit64.Net.fromFacelets` must refuse, and for which reason.
//
// Facelets arrive from outside -- a scanner, a UI, another project's engine --
// so every way of not being a cube has to come back as a reason rather than as
// a plausible state. Each case below breaks exactly one thing, and each asserts
// the wording of the refusal rather than only that there was one: a guard that
// fires for the wrong reason is a guard that will stop firing when the reason
// it actually depended on changes.
//

def readable(): List[Int32] = List#{2, 3, 4, 5}

def stickersOf(n: Int32): Vector[Int32] =
    match Orbit64.Net.toFacelets(n, Orbit64.State.solved(n)) {
        case Ok(fs) => fs
        case Err(_) => Vector#{}
    }

def withFacelet(at: Int32, to: Int32, fs: Vector[Int32]): Vector[Int32] =
    Vector.init(i -> if (i == at) to else Vector.get(i, fs), Vector.length(fs))

def swapFacelets(a: Int32, b: Int32, fs: Vector[Int32]): Vector[Int32] =
    Vector.init(i ->
        if (i == a) Vector.get(b, fs)
        else if (i == b) Vector.get(a, fs)
        else Vector.get(i, fs), Vector.length(fs))

def refuses(said: {said = String}, what: String, n: Int32, fs: Vector[Int32]): Unit \ Assert =
    match Orbit64.Net.fromFacelets(n, fs) {
        case Ok(_)    => Assert.assertTrueWithMsg(false, "read a ${n}x${n}x${n} from ${what}")
        case Err(why) => Assert.assertTrueWithMsg(
            String.contains(substr = said#said, why),
            "refused ${what} on a ${n}x${n}x${n}, but not for the expected reason: ${why}")
    }

///
/// A size this module has no convention for is declined rather than guessed at,
/// exactly as `toFacelets` declines it.
///
@Test
def fromFaceletsDeclinesASizeWithNoConvention(): Unit \ Assert =
    List#{1, 8} |> List.forEach(n ->
        refuses(said = "no slot convention",
                "a size with no slot convention", n, Vector.repeat(6 * n * n, 0)))

///
/// A short or long array cannot be indexed by the tables, and a reader that
/// tried would run off the end of one.
///
@Test
def fromFaceletsDeclinesTheWrongNumberOfFacelets(): Unit \ Assert =
    readable() |> List.forEach(n -> {
        let fs = stickersOf(n);
        let short = Vector.init(i -> Vector.get(i, fs), Vector.length(fs) - 1);
        refuses(said = "facelets for the", "one facelet too few", n, short);
        refuses(said = "facelets for the", "one facelet too many", n,
                Vector.append(fs, Vector#{0}))
    })

///
/// A facelet names one of six faces. Anything else indexes no color table.
///
@Test
def fromFaceletsDeclinesAFaceletThatIsNoFace(): Unit \ Assert =
    readable() |> List.forEach(n -> {
        let fs = stickersOf(n);
        refuses(said = "must name a face", "a facelet numbered 6", n, withFacelet(0, 6, fs));
        refuses(said = "must name a face", "a facelet numbered -1", n, withFacelet(0, -1, fs))
    })

///
/// Fixed centers select one of 24 whole-cube frames. A swap of two centers is
/// not one of those right-handed orientations, so it remains invalid.
///
@Test
def fromFaceletsDeclinesAnImpossibleFixedCenterFrame(): Unit \ Assert =
    // The U and R centers, at both odd sizes this module reads.
    refuses(said = "not a right-handed whole-cube frame",
            "a 3x3x3 with its U and R centers exchanged", 3, swapFacelets(4, 13, stickersOf(3)));
    refuses(said = "not a right-handed whole-cube frame",
            "a 5x5x5 with its U and R centers exchanged", 5, swapFacelets(12, 37, stickersOf(5)))

///
/// An even cube has no fixed center, so nothing about its centers is a frame
/// and exchanging two of them is an ordinary state rather than a refusal.
///
@Test
def fromFaceletsAcceptsAnEvenCubeWithItsCentersMoved(): Unit \ Assert =
    // Two center facelets of a 4x4x4, on the U and R faces.
    let moved = swapFacelets(5, 21, stickersOf(4));
    Assert.assertTrueWithMsg(
        Result.isOk(Orbit64.Net.fromFacelets(4, moved)),
        "refused a 4x4x4 whose centers are merely permuted")

///
/// Stickers in an order no piece of that orbit carries.
///
@Test
def fromFaceletsDeclinesStickersNoPieceCarries(): Unit \ Assert =
    // Corner slot 0 of a 3x3x3 reads U R F; making its first sticker D leaves
    // D R F, which is no corner.
    refuses(said = "which is no corner of this cube",
            "a corner showing DRF", 3, withFacelet(8, 3, stickersOf(3)));
    // Wing slot 0 of a 4x4x4 reads U B, and F alongside B is no wing.
    refuses(said = "which is no wing of this cube",
            "a wing showing FB", 4, withFacelet(1, 2, stickersOf(4)))

///
/// Two slots showing the same piece. Each reads fine on its own; the
/// permutation they add up to is not one.
///
@Test
def fromFaceletsDeclinesTwoSlotsShowingOnePiece(): Unit \ Assert =
    // Corner slot 1 of a 3x3x3 reads U F L. Recoloring its other two stickers
    // makes it U R F, which corner slot 0 already is.
    let doubled = stickersOf(3) |> withFacelet(18, 1) |> withFacelet(38, 2);
    refuses(said = "not a permutation of 0..7",
            "two corner slots holding one corner", 3, doubled)

///
/// A color on more centers than a cube has of it.
///
@Test
def fromFaceletsDeclinesAnImpossibleCenterCount(): Unit \ Assert =
    // Repainting one U center of a 4x4x4 red leaves five reds and three whites,
    // where every color must appear on exactly four.
    refuses(said = "exactly four times",
            "five centers of one color", 4, withFacelet(5, 1, stickersOf(4)))

//
// The parity law. On an odd cube the corner and midge permutations must agree
// in parity; facelets that show only two swapped corners, or only two swapped
// midges, are no cube, and `State.encode` refuses the same state. The even
// cubes have no such law, so the same swaps are ordinary states there.
//

def exchange(a: Int32, b: Int32, v: Vector[Int32]): Vector[Int32] =
    Vector.init(i ->
        if (i == a) Vector.get(b, v)
        else if (i == b) Vector.get(a, v)
        else Vector.get(i, v), Vector.length(v))

def exchangeCorners(cs: List[Orbit64.Coord.Coord]): List[Orbit64.Coord.Coord] =
    cs |> List.map(c -> match c {
        case Orbit64.Coord.Coord.CornerCoord(p, t) =>
            Orbit64.Coord.Coord.CornerCoord(exchange(0, 1, p), t)
        case _ => c
    })

def exchangeMidges(cs: List[Orbit64.Coord.Coord]): List[Orbit64.Coord.Coord] =
    cs |> List.map(c -> match c {
        case Orbit64.Coord.Coord.MidgeCoord(p, f) =>
            Orbit64.Coord.Coord.MidgeCoord(exchange(0, 1, p), f)
        case _ => c
    })

def drawn(n: Int32, cs: List[Orbit64.Coord.Coord]): Vector[Int32] =
    match Orbit64.Net.toFacelets(n, Orbit64.State.canonical(cs)) {
        case Ok(fs) => fs
        case Err(_) => Vector#{}
    }

def solvedOrbitsOf(n: Int32): List[Orbit64.Coord.Coord] =
    Orbit64.State.orbits(Orbit64.State.solved(n))

///
/// The reported case: a solved cube with two corners exchanged.
///
@Test
def fromFaceletsDeclinesTwoSwappedCornersOnAnOddCube(): Unit \ Assert =
    List#{3, 5, 7} |> List.forEach(n ->
        refuses(said = "corner and midge permutation parity must match",
                "two swapped corners", n, drawn(n, exchangeCorners(solvedOrbitsOf(n)))))

///
/// The same law from the other side: two swapped midges.
///
@Test
def fromFaceletsDeclinesTwoSwappedMidgesOnAnOddCube(): Unit \ Assert =
    List#{3, 5, 7} |> List.forEach(n ->
        refuses(said = "corner and midge permutation parity must match",
                "two swapped midges", n, drawn(n, exchangeMidges(solvedOrbitsOf(n)))))

///
/// A swap in each orbit is a legal parity and reads back, and encodes.
///
@Test
def fromFaceletsAcceptsMatchingParityOnAnOddCube(): Unit \ Assert =
    List#{3, 5, 7} |> List.forEach(n -> {
        let both = exchangeMidges(exchangeCorners(solvedOrbitsOf(n)));
        Assert.assertEq(
            expected = Ok(Orbit64.State.canonical(both)),
            Orbit64.Net.fromFacelets(n, drawn(n, both)));
        Assert.assertTrueWithMsg(
            Result.isOk(Orbit64.Net.fromFacelets(n, drawn(n, both))
                |> Result.flatMap(s -> Orbit64.State.encode(n, s))),
            "a matching-parity ${n}x${n}x${n} did not encode")
    })

///
/// Even cubes carry no corner/midge law: centers and wings absorb parity.
///
@Test
def fromFaceletsAcceptsSwappedCornersOnAnEvenCube(): Unit \ Assert =
    List#{2, 4, 6} |> List.forEach(n -> {
        let swapped = exchangeCorners(solvedOrbitsOf(n));
        Assert.assertEq(
            expected = Ok(Orbit64.State.canonical(swapped)),
            Orbit64.Net.fromFacelets(n, drawn(n, swapped)))
    })

///
/// What the reader refuses, `encode` refuses too, so no facelet route yields a
/// token that a coordinate route would not.
///
@Test
def encodeRefusesWhatTheReaderRefusesForParity(): Unit \ Assert =
    Assert.assertEq(
        expected = Err("corner and midge permutation parity must match"),
        Orbit64.State.encode(3, Orbit64.State.canonical(exchangeCorners(solvedOrbitsOf(3)))))
