///
/// One orbit's worth of cube state, and its mapping onto an integer.
///
/// A `Coord` holds the state in the form you would read off a physical cube --
/// which piece sits in which slot, and how it is turned. `rank` collapses that
/// into a single integer below `Orbit.radix`, and `unrank` recovers it exactly.
///
mod Orbit64.Coord {

    use Orbit64.Rank
    use Orbit64.Orbit.Orbit
    use Orbit64.Orbit.Orbit.{Corners, Midges, Wings, Centers}

    ///
    /// The state of a single orbit.
    ///
    /// Permutations are given slot-wise: entry `i` names the piece sitting in
    /// slot `i`, with the solved cube being the identity. Orientations are
    /// given in the same slot order, and the redundant final entry is carried
    /// here even though `rank` drops it -- it is cheap to keep, and it lets
    /// `faultOf` check the constraint the format relies on.
    ///
    pub enum Coord with Eq, ToString {
        /// Corner permutation and per-corner twist in `0..2`, summing to `0 mod 3`.
        case CornerCoord(Vector[Int32], Vector[Int32]),
        /// Midge permutation and per-edge flip in `0..1`, summing to `0 mod 2`.
        case MidgeCoord(Vector[Int32], Vector[Int32]),
        /// Wing permutation of twenty-four distinguishable pieces.
        case WingCoord(Vector[Int32]),
        /// Centre colours in `0..5`, four slots of each colour.
        case CenterCoord(Vector[Int32])
    }

    ///
    /// The kind of orbit `c` describes.
    ///
    pub def kind(c: Coord): Orbit = match c {
        case CornerCoord(_, _) => Corners
        case MidgeCoord(_, _)  => Midges
        case WingCoord(_)      => Wings
        case CenterCoord(_)    => Centers
    }

    ///
    /// Why `c` is not a state a cube can be in, or nothing when it is one.
    ///
    /// The constraints are stated once, here, and used twice: as the predicate
    /// `isValid`, and as the reason `Orbit64.encode` gives when it refuses. A
    /// caller building coordinates from its own model gets told which rule it
    /// broke rather than that something, somewhere, was wrong.
    ///
    /// Every check is total on any vector it is handed, including one of the
    /// wrong length -- which matters, because this runs *before* `rank`, and
    /// `rank` would read off the end of a short orientation vector.
    ///
    pub def faultOf(c: Coord): Option[String] =
        let checks = match c {
            case CornerCoord(p, t) =>
                (isPermutation(p, 8), "the corner permutation is not a permutation of 0..7") ::
                (Vector.length(t) == 8, "there must be exactly 8 corner twists, one per slot") ::
                (Vector.forAll(x -> x >= 0 and x < 3, t), "every corner twist must be 0, 1 or 2") ::
                (Int32.modulo(Vector.sum(t), 3) == 0, "the corner twists must sum to 0 mod 3") :: Nil
            case MidgeCoord(p, f) =>
                (isPermutation(p, 12), "the midge permutation is not a permutation of 0..11") ::
                (Vector.length(f) == 12, "there must be exactly 12 midge flips, one per slot") ::
                (Vector.forAll(x -> x >= 0 and x < 2, f), "every midge flip must be 0 or 1") ::
                (Int32.modulo(Vector.sum(f), 2) == 0, "the midge flips must sum to 0 mod 2") :: Nil
            case WingCoord(p) =>
                (isPermutation(p, 24), "the wing permutation is not a permutation of 0..23") :: Nil
            case CenterCoord(cols) =>
                (Vector.length(cols) == 24, "there must be exactly 24 centre slots") ::
                (Vector.forAll(x -> x >= 0 and x < 6, cols), "every centre colour must be 0..5") ::
                (List.range(0, 6) |> List.forAll(col -> Vector.count(x -> x == col, cols) == 4),
                 "each of the six centre colours must appear exactly four times") :: Nil
        };
        List.filterMap(match (ok, why) -> if (ok) None else Some(why), checks) |> List.head

    ///
    /// Whether `c` satisfies the constraints every reachable cube obeys.
    ///
    pub def isValid(c: Coord): Bool = Option.isEmpty(faultOf(c))

    def isPermutation(p: Vector[Int32], n: Int32): Bool =
        Vector.length(p) == n and
        List.range(0, n) |> List.forAll(i -> Vector.memberOf(i, p))

    ///
    /// The integer coordinate of `c`, in `[0, Orbit.radix(kind(c)))`.
    ///
    /// Permutation and orientation are combined by mixed radix rather than
    /// stored in separate fields, so no bits are lost between them.
    ///
    pub def rank(c: Coord): BigInt = match c {
        case CornerCoord(p, t) =>
            Rank.permRank(p) * 2187ii + Int32.toBigInt(baseN(3, 7, t))
        case MidgeCoord(p, f) =>
            Rank.permRank(p) * 2048ii + Int32.toBigInt(baseN(2, 11, f))
        case WingCoord(p) =>
            Rank.permRank(p)
        case CenterCoord(cols) =>
            Rank.multisetRank(cols, 4, 6)
    }

    ///
    /// The inverse of `rank`: the state of an orbit of kind `o` with coordinate `v`.
    ///
    pub def unrank(o: Orbit, v: BigInt): Coord = match o {
        case Corners =>
            let (r, tv) = (v / 2187ii, BigInt.modulo(v, 2187ii));
            let t = unBaseN(3, 7, toI32(tv));
            CornerCoord(Rank.permUnrank(r, 8), closeOver(3, t))
        case Midges =>
            let (r, fv) = (v / 2048ii, BigInt.modulo(v, 2048ii));
            let f = unBaseN(2, 11, toI32(fv));
            MidgeCoord(Rank.permUnrank(r, 12), closeOver(2, f))
        case Wings =>
            WingCoord(Rank.permUnrank(v, 24))
        case Centers =>
            CenterCoord(Rank.multisetUnrank(v, 24, 4, 6))
    }

    ///
    /// The first `k` entries of `xs` read as a base-`b` numeral, most
    /// significant first. The dropped tail is exactly the redundant entry.
    ///
    def baseN(b: Int32, k: Int32, xs: Vector[Int32]): Int32 =
        Vector.range(0, k) |> Vector.foldLeft((acc, i) -> acc * b + Vector.get(i, xs), 0)

    ///
    /// The inverse of `baseN`: `k` base-`b` digits of `v`, most significant first.
    ///
    def unBaseN(b: Int32, k: Int32, v: Int32): Vector[Int32] =
        Vector.range(0, k) |> Vector.map(i -> Int32.modulo(v / Int32.pow(base = b, k - 1 - i), b))

    ///
    /// Append the entry that the orientation-sum constraint forces.
    ///
    def closeOver(b: Int32, xs: Vector[Int32]): Vector[Int32] =
        Vector.append(xs, Vector#{Int32.modulo(b - Int32.modulo(Vector.sum(xs), b), b)})

    def toI32(v: BigInt): Int32 =
        BigInt.tryToInt32(v) |> Option.getWithDefault(0)

}
