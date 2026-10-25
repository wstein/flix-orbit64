///
/// One token for every cube that looks the same up to turning, mirroring and
/// recoloring.
///
/// A pattern is a color state: its identity does not depend on how the cube is
/// held, mirrored or colored. `fromFacelets` maps all such cubes to a single
/// ordinary state token, so string equality is pattern equality.
///
/// The definition, in three steps:
///
///   1. Take the least sticker string of the cube over the 48 symmetries
///      (rotations and mirrors), each with its colors renamed in order of first
///      appearance. Strings are compared sticker by sticker in facelet order
///      `U R F D L B`, colors as the numbers 0 to 5. This orders sticker
///      strings, not tokens, so it needs 48 images and one encoding.
///   2. Rename the colors to the standard scheme. On an odd cube the color in
///      the center of face `f` becomes `f`, so the six fixed centers are home
///      and the stored frame is 0. An even cube has no centers: the colors of
///      the corner in the URF slot become `U R F` in turning order, and the
///      three colors that share no corner with them become `D L B`.
///   3. Encode it with `Orbit64.State.encode`. A state that is no cube is an
///      error.
///
/// No mirroring step is needed after step 2. The renaming depends only on
/// which stickers share a color, and the reachable states are closed under
/// mirroring, so the mirror image of a cube renames to a cube as well.
///
/// The token depends only on the string of step 1, so it is invariant, and
/// distinct color states of different classes get distinct tokens. Mirror images get the
/// same token: the 48 symmetries include the mirrors. The solved cube of every
/// size is the token of `A` repeated.
///
/// From the 4x4x4 up, equal-colored pieces need no representative: Orbit64
/// reads colors, a wing by the ordered pair of colors in its slot and a center
/// orbit as a multiset of colors, so swapping equal-colored pieces changes no
/// color and no token.
///
/// The token also depends on the slot convention `Orbit64.Net.convention(n)`
/// names (`orbit64-Nxn-draft@1`), on the sticker order `U R F D L B` and its
/// geometry (see FORMAT.md), and on the URF corner. Changing any of them
/// renames every canonical token, so a stored token should carry the
/// convention name. This is an addition to the format: tokens that
/// `Orbit64.State.encode` writes are unchanged, and the output here is one
/// of them.
///
mod Orbit64.Canonical {

    use Orbit64.Internal.Symmetry

    ///
    /// The canonical token of the cube whose stickers are `facelets`.
    ///
    /// `facelets` are `6 * n * n` face indices in the layout of
    /// `Orbit64.Net.toFacelets`. The names of the colors do not matter, only
    /// which stickers share one. Each color must occur `n * n` times.
    ///
    pub def fromFacelets(n: Int32, facelets: Vector[Int32]): Result[String, String] =
        match checkFacelets(n, facelets) {
            case Some(why) => Err(why)
            case None =>
                Symmetry.leastImage(n, facelets)
                    |> Result.flatMap(least -> standardToken(n, least))
        }

    ///
    /// The canonical token of the cube a state token of size `n` describes.
    ///
    pub def fromToken(n: Int32, token: String): Result[String, String] =
        Orbit64.State.decode(n, token)
            |> Result.flatMap(state -> fromState(n, state))

    ///
    /// The canonical token of a decoded state.
    ///
    pub def fromState(n: Int32, state: Orbit64.State.FramedState): Result[String, String] =
        Orbit64.Net.toFacelets(n, state)
            |> Result.flatMap(facelets -> fromFacelets(n, facelets))

    ///
    /// Why `facelets` cannot be a cube of size `n`, if it cannot.
    ///
    def checkFacelets(n: Int32, facelets: Vector[Int32]): Option[String] =
        if (not Orbit64.Net.canDraw(n))
            Some("no slot convention for the ${n}x${n}x${n}: this module has one "
                + "only up to the 7x7x7")
        else if (Vector.length(facelets) != 6 * n * n)
            Some("expected ${6 * n * n} facelets for the ${n}x${n}x${n}, "
                + "got ${Vector.length(facelets)}")
        else if (not Vector.forAll(f -> f >= 0 and f < 6, facelets))
            Some("every facelet must name a face, 0 to 5")
        else if (List.exists(c -> countOf(c, facelets) != n * n, List.range(0, 6)))
            Some("every color must appear ${n * n} times")
        else None

    def countOf(color: Int32, facelets: Vector[Int32]): Int32 =
        Vector.foldLeft((acc, c) -> if (c == color) acc + 1 else acc, 0, facelets)

    ///
    /// The token of `colors` renamed to the standard scheme, or why not.
    ///
    def standardToken(n: Int32, colors: Vector[Int32]): Result[String, String] =
        match standardNames(n, colors) {
            case Err(why)   => Err(why)
            case Ok(names)  =>
                let renamed = Vector.map(c -> Map.getWithDefault(c, 0, names), colors);
                Orbit64.Net.fromFacelets(n, renamed)
                    |> Result.flatMap(state -> Orbit64.State.encode(n, state))
        }

    ///
    /// The standard name of every color: on an odd cube the face whose center
    /// it fills, on an even cube by the URF corner and its opposite colors.
    ///
    def standardNames(n: Int32, colors: Vector[Int32]): Result[String, Map[Int32, Int32]] =
        if (Int32.modulo(n, 2) == 1) namesByCenters(n, colors) else namesByCorner(n, colors)

    def namesByCenters(n: Int32, colors: Vector[Int32]): Result[String, Map[Int32, Int32]] =
        let pairs = List.range(0, 6) |> List.filterMap(face ->
            Symmetry.centerFacelet(n, face)
                |> Option.map(at -> (Vector.get(at, colors), face)));
        nameMap(pairs, "the fixed centers of an odd cube must show six different colors")

    ///
    /// Even cubes: the URF corner becomes `U R F` and the colors sharing no
    /// corner with them, found as the opposites, become `D L B`.
    ///
    def namesByCorner(n: Int32, colors: Vector[Int32]): Result[String, Map[Int32, Int32]] =
        let corners = Symmetry.cornerStickers(n)
            |> List.map(slot -> Vector.map(i -> Vector.get(i, colors), slot));
        let shared = corners |> List.foldLeft((acc, corner) ->
            Vector.foldLeft((set, a) ->
                Vector.foldLeft((inner, b) -> Set.insert((a, b), inner), set, corner),
                acc, corner), Set.empty());
        let opposite = c -> List.filter(o -> not Set.memberOf((c, o), shared), List.range(0, 6));
        match List.head(corners) {
            case None         => Err("the cube has no corners")
            case Some(urf)    =>
                let top = Vector.toList(urf);
                let pairs = List.append(
                    List.mapWithIndex(i -> c -> (c, i), top),
                    List.mapWithIndex(i -> c -> (oppositeOf(opposite(c)), i + 3), top));
                nameMap(pairs, "the corner colors of an even cube are not three pairs of opposites")
        }

    /// The single opposite color in `candidates`, or -1 when there is not exactly one.
    def oppositeOf(candidates: List[Int32]): Int32 = match candidates {
        case o :: Nil => o
        case _        => -1
    }

    ///
    /// The map of the `(color, name)` pairs, or `why` unless they name six
    /// different colors.
    ///
    def nameMap(pairs: List[(Int32, Int32)], why: String): Result[String, Map[Int32, Int32]] =
        let names = List.toMap(pairs);
        if (Map.size(names) == 6 and List.forAll(match (c, _) -> c >= 0, pairs)) Ok(names)
        else Err(why)

}
