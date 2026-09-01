///
/// A compact, URL-safe interchange format for `n x n x n` cube state.
///
/// The whole state is one integer. Each orbit contributes a coordinate in a
/// range of exactly its own size (see `Orbit.radix`), the coordinates are
/// combined by mixed radix, and the result is written in base64url at a fixed
/// width. Nothing is spent on separators or field alignment; the two leading
/// zero bits identify this member of the Orbit64 token family as state.
///
/// The encoding is canonical for a given slot convention: two coordinate states
/// produce the same token exactly when they are the same state, so string
/// equality is state equality. The qualifier matters -- a token records ordinals
/// and no geometry, so which physical piece "wing 17" is has to be agreed
/// elsewhere. `Orbit64.Net` is where this package says what it assumes.
///
/// | cube  | bits   | chars |
/// |-------|--------|-------|
/// | 2x2x2 |  26.39 |     5 |
/// | 3x3x3 |  66.23 |    12 |
/// | 4x4x4 | 156.96 |    27 |
/// | 5x5x5 | 248.32 |    42 |
/// | 6x6x6 | 390.58 |    66 |
/// | 7x7x7 | 533.47 |    90 |
///
/// Widths are distinct and grow as `n^2`, so a token's length identifies the
/// puzzle it belongs to.
///
mod Orbit64.State {

    use Orbit64.Coord.Coord
    use Orbit64.Orbit.Orbit

    ///
    /// The number of states of an `n x n x n` cube.
    ///
    pub def stateCount(n: Int32): BigInt =
        Orbit.layout(n) |> List.foldLeft((acc, o) -> acc * Orbit.radix(o), 1ii)

    ///
    /// The token width for an `n x n x n` cube: the fewest base64url characters
    /// that can address every state beneath the leading `00` class tag.
    ///
    pub def width(n: Int32): Int32 = widthLoop(stateCount(n), 16ii, 1)

    def widthLoop(total: BigInt, capacity: BigInt, w: Int32): Int32 =
        if (capacity >= total) w else widthLoop(total, capacity * 64ii, w + 1)

    ///
    /// Encode `orbits` -- given in `Orbit.layout` order -- as a token.
    ///
    /// Fails if the orbits do not match the layout for `n`, and fails if any of
    /// them is not a state a cube can be in.
    ///
    /// The second check is not politeness. A coordinate outside its own range
    /// does not merely encode itself wrongly: the assembly below is Horner, so
    /// the surplus carries into the *next* orbit and corrupts a coordinate that
    /// was correct. And a coordinate inside its range but not a cube -- a
    /// permutation with a repeat, say -- ranks as some other, legitimate state,
    /// so nothing downstream can catch it either. `decode` bounds-checks the
    /// whole token, which cannot see either case. This is the only place that
    /// can.
    ///
    pub def encode(n: Int32, orbits: List[Coord]): Result[String, String] =
        let expected = Orbit.layout(n);
        let actual = List.map(Coord.kind, orbits);
        if (actual != expected)
            Err("expected orbits ${expected} for ${n}x${n}x${n}, got ${actual}")
        else
            // Every coordinate is checked before any of them is ranked, because
            // ranking a malformed one is what would read off the end of it.
            match orbits |> List.filterMap(c ->
                    Coord.faultOf(c) |> Option.map(why -> (Coord.kind(c), why)))
                    |> List.head {
                case Some((o, why)) => Err("the ${o} coordinate is not a cube: ${why}")
                case None =>
                    let acc = orbits |> List.foldLeft((a, c) ->
                        a * Orbit.radix(Coord.kind(c)) + Coord.rank(c), 0ii);
                    Ok(Orbit64.Internal.Encoding.toBase64(acc, width(n)))
            }

    ///
    /// Decode a token back into the orbits of an `n x n x n` cube.
    ///
    /// Round-trips exactly: `decode(n, encode(n, s))` returns `s` for any state
    /// reachable on a real cube.
    ///
    pub def decode(n: Int32, token: String): Result[String, List[Coord]] =
        let total = stateCount(n);
        let w = widthLoop(total, 16ii, 1);
        if (String.length(token) != w)
            Err("expected ${w} characters for ${n}x${n}x${n}, got ${String.length(token)}")
        else
            match Orbit64.Internal.Encoding.fromBase64(token) {
                case None => Err("token contains a character outside the base64url alphabet")
                case Some(acc) =>
                    if (acc >= total)
                        Err("token is out of range for ${n}x${n}x${n}")
                    else
                        Ok(split(acc, List.reverse(Orbit.layout(n)), Nil))
            }

    ///
    /// Peel coordinates off `acc`, least significant orbit first.
    ///
    /// `pending` arrives reversed and the accumulator is built by prepending,
    /// so the result comes back in layout order.
    ///
    def split(acc: BigInt, pending: List[Orbit], out: List[Coord]): List[Coord] =
        match pending {
            case Nil     => out
            case o :: os =>
                let r = Orbit.radix(o);
                let q = acc / r;
                split(q, os, Coord.unrank(o, acc - q * r) :: out)
        }

    ///
    /// The state of a solved `n x n x n` cube.
    ///
    /// Every coordinate is zero, so this always encodes to a run of `A`s.
    ///
    pub def solved(n: Int32): List[Coord] =
        Orbit.layout(n) |> List.map(o -> Coord.unrank(o, 0ii))

}
