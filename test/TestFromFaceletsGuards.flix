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
    match Orbit64.Net.toFacelets(n, Orbit64.solved(n)) {
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
    List#{1, 6, 7} |> List.forEach(n ->
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
/// A facelet names one of six faces. Anything else indexes no colour table.
///
@Test
def fromFaceletsDeclinesAFaceletThatIsNoFace(): Unit \ Assert =
    readable() |> List.forEach(n -> {
        let fs = stickersOf(n);
        refuses(said = "must name a face", "a facelet numbered 6", n, withFacelet(0, 6, fs));
        refuses(said = "must name a face", "a facelet numbered -1", n, withFacelet(0, -1, fs))
    })

///
/// The fixed centres of an odd cube are the frame, and a state whose frame has
/// moved has nowhere in a token to say so.
///
/// Only the centres are disturbed here -- every corner, midge, wing and movable
/// centre still reads back as the solved cube -- so nothing but the frame check
/// can be what refuses it.
///
@Test
def fromFaceletsDeclinesADisplacedFrame(): Unit \ Assert =
    // The U and R centres, at both odd sizes this module reads.
    refuses(said = "the frame this format is written in",
            "a 3x3x3 with its U and R centres exchanged", 3, swapFacelets(4, 13, stickersOf(3)));
    refuses(said = "the frame this format is written in",
            "a 5x5x5 with its U and R centres exchanged", 5, swapFacelets(12, 37, stickersOf(5)))

///
/// An even cube has no fixed centre, so nothing about its centres is a frame
/// and exchanging two of them is an ordinary state rather than a refusal.
///
@Test
def fromFaceletsAcceptsAnEvenCubeWithItsCentresMoved(): Unit \ Assert =
    // Two centre facelets of a 4x4x4, on the U and R faces.
    let moved = swapFacelets(5, 21, stickersOf(4));
    Assert.assertTrueWithMsg(
        Result.isOk(Orbit64.Net.fromFacelets(4, moved)),
        "refused a 4x4x4 whose centres are merely permuted")

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
    // Corner slot 1 of a 3x3x3 reads U F L. Recolouring its other two stickers
    // makes it U R F, which corner slot 0 already is.
    let doubled = stickersOf(3) |> withFacelet(18, 1) |> withFacelet(38, 2);
    refuses(said = "not a permutation of 0..7",
            "two corner slots holding one corner", 3, doubled)

///
/// A colour on more centres than a cube has of it.
///
@Test
def fromFaceletsDeclinesAnImpossibleCentreCount(): Unit \ Assert =
    // Repainting one U centre of a 4x4x4 red leaves five reds and three whites,
    // where every colour must appear on exactly four.
    refuses(said = "exactly four times",
            "five centres of one colour", 4, withFacelet(5, 1, stickersOf(4)))
