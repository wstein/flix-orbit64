///
/// The orbit decomposition of an NxNxN cube.
///
/// Every twisty cube factors into independent families of pieces that turns
/// permute among themselves and never mix. The whole format follows from this
/// decomposition: one coordinate per orbit, packed in a fixed order.
///
mod Orbit64.Orbit {

    use Orbit64.Rank

    ///
    /// The four kinds of orbit.
    ///
    /// Fixed centres -- the single stickers at the middle of each face on an
    /// odd cube -- are deliberately absent. They never move relative to one
    /// another, so they define the reference frame rather than carrying any
    /// information of their own.
    ///
    pub enum Orbit with Eq, Order, ToString {
        /// The eight corners: `8!` arrangements, `3^7` free twists.
        case Corners,
        /// The twelve middle edges of an odd cube: `12!` arrangements, `2^11` free flips.
        case Midges,
        /// Twenty-four distinguishable wings. Orientation is fixed by position.
        case Wings,
        /// Twenty-four centres, four of each colour and indistinguishable within a face.
        case Centers
    }

    ///
    /// The orbits of an `n x n x n` cube, in the order the codec packs them.
    ///
    /// The counts are pure arithmetic in `n`: a cube has `(n-2)/2` wing orbits
    /// and `(n-2)^2/4` centre orbits, both truncating. Midges exist only when
    /// `n` is odd. So `layout` needs no geometry -- which is why this module
    /// carries no notion of a face, an axis, or a turn.
    ///
    pub def layout(n: Int32): List[Orbit] =
        let midges = if (Int32.modulo(n, 2) == 1 and n >= 3) Corners :: Midges :: Nil else Corners :: Nil;
        let wings = List.repeat((n - 2) / 2, Wings);
        let centers = List.repeat(((n - 2) * (n - 2)) / 4, Centers);
        List.append(midges, List.append(wings, centers))

    ///
    /// The number of distinct states of a single orbit of kind `o`.
    ///
    /// Each is the exact size of the corresponding coordinate's range, so the
    /// mixed-radix product over `layout(n)` is the state count of the puzzle
    /// with nothing wasted.
    ///
    pub def radix(o: Orbit): BigInt = match o {
        // 8! arrangements; the eighth twist is forced by the sum-mod-3 rule.
        case Corners => factorial(8) * BigInt.pow(base = 3ii, 7)
        // 12! arrangements; the twelfth flip is forced by parity.
        case Midges  => factorial(12) * BigInt.pow(base = 2ii, 11)
        // Wings carry no orientation, so this is a bare permutation.
        case Wings   => factorial(24)
        // Four indistinguishable copies of each of six colours.
        case Centers =>
            List.range(0, 5)
                |> List.foldLeft((acc, t) -> acc * Int32.toBigInt(Rank.binomial(24 - 4 * t, 4)), 1ii)
    }

    ///
    /// The number of slots in an orbit of kind `o`.
    ///
    pub def size(o: Orbit): Int32 = match o {
        case Corners => 8
        case Midges  => 12
        case Wings   => 24
        case Centers => 24
    }

    ///
    /// `n!` as a `BigInt`.
    ///
    def factorial(n: Int32): BigInt =
        List.range(1, n + 1) |> List.foldLeft((acc, i) -> acc * Int32.toBigInt(i), 1ii)

}
