///
/// A compact, URL-safe interchange format for framed `n x n x n` cube state.
///
/// The whole state is one integer. Each orbit contributes a coordinate in a
/// range of exactly its own size (see `Orbit.radix`), and odd cubes add one of
/// the 24 fixed-centre frames. The values are combined by mixed radix and
/// written in base64url at a fixed width. Nothing is spent on separators or
/// field alignment; the two leading zero bits identify this member of the
/// Orbit64 token family as state.
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
/// | 3x3x3 |  69.82 |    12 |
/// | 4x4x4 | 156.96 |    27 |
/// | 5x5x5 | 251.90 |    43 |
/// | 6x6x6 | 390.58 |    66 |
/// | 7x7x7 | 537.05 |    90 |
///
/// Widths are distinct and grow as `n^2`, so a token's length identifies the
/// puzzle it belongs to.
///
mod Orbit64.State {

    use Orbit64.Coord.Coord
    use Orbit64.Coord.Coord.{CornerCoord, MidgeCoord}
    use Orbit64.Orbit.Orbit
    use Orbit64.Orbit.Orbit.{Corners, Midges}

    /// A coordinate state together with its whole-cube reference frame.
    pub enum FramedState with Eq, ToString {
        case FramedState(Orbit64.Frame.Frame, List[Coord])
    }

    /// Construct a state in the canonical reference frame.
    pub def canonical(orbits: List[Coord]): FramedState =
        FramedState.FramedState(Orbit64.Frame.canonical(), orbits)

    /// The reference frame recorded by `state`.
    pub def frame(state: FramedState): Orbit64.Frame.Frame = match state {
        case FramedState.FramedState(value, _) => value
    }

    /// The orbit coordinates recorded by `state`.
    pub def orbits(state: FramedState): List[Coord] = match state {
        case FramedState.FramedState(_, value) => value
    }

    /// Whether `n` has fixed centres whose physical frame must be carried.
    pub def carriesFrame(n: Int32): Bool = Int32.modulo(n, 2) == 1 and n >= 3

    /// The number of legal coordinate states before the optional frame factor.
    pub def coordinateCount(n: Int32): BigInt =
        let all = Orbit.layout(n) |> List.foldLeft((acc, o) -> acc * Orbit.radix(o), 1ii);
        if (carriesFrame(n)) all / 2ii else all

    /// The number of frame-aware states the state format addresses.
    pub def stateCount(n: Int32): BigInt =
        coordinateCount(n) * Int32.toBigInt(frameCount(n))

    def frameCount(n: Int32): Int32 = if (carriesFrame(n)) Orbit64.Frame.count() else 1

    ///
    /// Encode a frame-aware state.
    ///
    /// On even cubes the frame must be canonical: movable centre coordinates
    /// already determine the pose, so recording another 24-way choice would
    /// duplicate every state. Odd cubes carry one of the 24 fixed-centre
    /// frames explicitly.
    ///
    pub def encode(n: Int32, state: FramedState): Result[String, String] =
        match stateFault(n, state) {
            case Some(why) => Err(why)
            case None => Ok(Orbit64.Internal.Encoding.toBase64(encodedValue(n, state), width(n)))
        }

    def stateFault(n: Int32, state: FramedState): Option[String] =
        List#{
            frameFault(n, frame(state)),
            layoutFault(n, orbits(state)),
            firstFault(orbits(state)),
            parityFault(n, orbits(state))
        } |> List.filterMap(x -> x) |> List.head

    def frameFault(n: Int32, value: Orbit64.Frame.Frame): Option[String] =
        if (not (Orbit64.Frame.faultOf(value) |> Option.isEmpty))
            Some("the state frame is not a right-handed cube frame")
        else if (not carriesFrame(n) and value != Orbit64.Frame.canonical())
            Some("an even cube carries its frame in its movable centres")
        else None

    def layoutFault(n: Int32, actual: List[Coord]): Option[String] =
        let expected = Orbit.layout(n);
        let kinds = List.map(Coord.kind, actual);
        if (kinds == expected) None
        else Some("expected orbits ${expected} for ${n}x${n}x${n}, got ${kinds}")

    def encodedValue(n: Int32, state: FramedState): BigInt =
        rankCoordinates(n, orbits(state)) * Int32.toBigInt(frameCount(n))
            + Int32.toBigInt(Orbit64.Frame.rank(frame(state)))

    /// Decode a frame-aware state.
    pub def decode(n: Int32, token: String): Result[String, FramedState] =
        let total = stateCount(n);
        let width = width(n);
        if (String.length(token) != width)
            Err("expected ${width} characters for the ${n}x${n}x${n}, got ${String.length(token)}")
        else match Orbit64.Internal.Encoding.fromBase64(token) {
            case None => Err("token contains a character outside the base64url alphabet")
            case Some(value) =>
                if (value >= total) Err("token is out of range for the ${n}x${n}x${n}")
                else
                    let count = Int32.toBigInt(frameCount(n));
                    let coordinate = value / count;
                    let frame = BigInt.modulo(value, count)
                        |> BigInt.tryToInt32 |> Option.getWithDefault(0)
                        |> Orbit64.Frame.unrank;
                    Ok(FramedState.FramedState(frame, unrankCoordinates(n, coordinate)))
        }

    /// The width for `stateCount`, keeping the leading state class bits.
    pub def width(n: Int32): Int32 = widthLoop(stateCount(n), 16ii, 1)

    def firstFault(orbits: List[Coord]): Option[String] =
        orbits |> List.filterMap(c -> Coord.faultOf(c)
            |> Option.map(why -> "the ${Coord.kind(c)} coordinate is not a cube: ${why}"))
            |> List.head

    def parityFault(n: Int32, orbits: List[Coord]): Option[String] =
        if (not carriesFrame(n)) None
        else match orbits {
            case CornerCoord(corners, _) :: MidgeCoord(midges, _) :: _ =>
                parityMismatch(corners, midges)
            case _ => Some("odd cubes require corner and midge coordinates")
        }

    def parityMismatch(corners: Vector[Int32], midges: Vector[Int32]): Option[String] =
        if (Orbit64.Rank.permParity(corners) == Orbit64.Rank.permParity(midges)) None
        else Some("corner and midge permutation parity must match")

    def rankCoordinates(n: Int32, orbits: List[Coord]): BigInt =
        if (n == 3) rankOddCoordinates(orbits)
        else if (carriesFrame(n)) rankLegacyOddCoordinates(orbits)
        else rankAll(orbits, 0ii)

    def rankAll(orbits: List[Coord], initial: BigInt): BigInt =
        let appendRank = (acc, c) -> acc * Orbit.radix(Coord.kind(c)) + Coord.rank(c);
        List.foldLeft(appendRank, initial, orbits)

    def rankOddCoordinates(orbits: List[Coord]): BigInt =
        match orbits {
            case corner :: midge :: tail => rankOddHead(corner, midge, tail)
            case _ => 0ii
        }

    /// The wider odd-cube drafts retain their original coordinate ordering.
    def rankLegacyOddCoordinates(orbits: List[Coord]): BigInt =
        match orbits {
            case corner :: midge :: tail => match (corner, midge) {
                case (CornerCoord(corners, _), MidgeCoord(midges, _)) =>
                    let parity = Orbit64.Rank.permParity(corners);
                    let initial = Coord.rank(corner) * midgeRadix()
                        + rankMidgeLegacy(midges, midge, parity);
                    rankAll(tail, initial)
                case _ => 0ii
            }
            case _ => 0ii
        }

    def rankOddHead(corner: Coord, midge: Coord, tail: List[Coord]): BigInt = match (corner, midge) {
        case (CornerCoord(corners, twists), MidgeCoord(midges, _)) =>
            let cornerParity = Orbit64.Rank.permParity(corners);
            let initial = cornerRank(corners, twists) * midgeRadix()
                + rankMidge(midges, midge, cornerParity);
            rankAll(tail, initial)
        case _ => 0ii
    }

    /// Orbit64's 3x3x3 contract ranks the seven stored corner orientations
    /// little-endian: the first orientation is the units digit.
    def cornerRank(permutation: Vector[Int32], twists: Vector[Int32]): BigInt =
        Orbit64.Rank.permRank(permutation) * 2187ii + orientationRank(twists, 7, 3)

    def rankMidge(permutation: Vector[Int32], coordinate: Coord, parity: Int32): BigInt =
        match coordinate {
            case MidgeCoord(_, flips) =>
                Orbit64.Rank.permRankWithParity(permutation, parity) * 2048ii
                    + orientationRank(flips, 11, 2)
            case _ => 0ii
        }

    def rankMidgeLegacy(permutation: Vector[Int32], coordinate: Coord, parity: Int32): BigInt =
        match coordinate {
            case MidgeCoord(_, flips) =>
                Orbit64.Rank.permRankWithParity(permutation, parity) * 2048ii
                    + BigInt.modulo(Coord.rank(MidgeCoord(Vector.range(0, 12), flips)), 2048ii)
            case _ => 0ii
        }

    /// Rank the first `count` orientation digits with the first at units.
    def orientationRank(values: Vector[Int32], count: Int32, radix: Int32): BigInt =
        orientationRankLoop(values, count, radix, 0, 1ii, 0ii)

    def orientationRankLoop(values: Vector[Int32], count: Int32, radix: Int32,
                            index: Int32, place: BigInt, out: BigInt): BigInt =
        if (index == count) out
        else orientationRankLoop(values, count, radix, index + 1,
                place * Int32.toBigInt(radix),
                out + Int32.toBigInt(Vector.get(index, values)) * place)

    def midgeRadix(): BigInt = Orbit.radix(Midges) / 2ii

    def unrankCoordinates(n: Int32, value: BigInt): List[Coord] =
        if (n == 3) unrankOddCoordinates(n, value)
        else if (carriesFrame(n)) unrankLegacyOddCoordinates(n, value)
        else split(value, List.reverse(Orbit.layout(n)), Nil)

    def unrankOddCoordinates(n: Int32, value: BigInt): List[Coord] =
        let tail = List.drop(2, Orbit.layout(n));
        let tailRadix = tail |> List.foldLeft((acc, o) -> acc * Orbit.radix(o), 1ii);
        let header = value / tailRadix;
        let tailValue = BigInt.modulo(value, tailRadix);
        let cornerRank = header / midgeRadix();
        let midgeValue = BigInt.modulo(header, midgeRadix());
        let corner = unrankCorner(cornerRank);
        let midge = unrankMidge(midgeValue, corner);
        corner :: midge :: split(tailValue, List.reverse(tail), Nil)

    def unrankCorner(value: BigInt): Coord =
        let permutation = value / 2187ii;
        let twists = unrankOrientations(BigInt.modulo(value, 2187ii), 7, 3);
        CornerCoord(Orbit64.Rank.permUnrank(permutation, 8), twists)

    def unrankMidge(value: BigInt, corner: Coord): Coord = match corner {
        case CornerCoord(permutation, _) =>
            let permutationRank = value / 2048ii;
            let orientations = unrankOrientations(BigInt.modulo(value, 2048ii), 11, 2);
            MidgeCoord(Orbit64.Rank.permUnrankWithParity(permutationRank, 12,
                Orbit64.Rank.permParity(permutation)), orientations)
        case _ => Coord.unrank(Midges, 0ii)
    }

    def unrankLegacyOddCoordinates(n: Int32, value: BigInt): List[Coord] =
        let tail = List.drop(2, Orbit.layout(n));
        let tailRadix = tail |> List.foldLeft((acc, o) -> acc * Orbit.radix(o), 1ii);
        let header = value / tailRadix;
        let tailValue = BigInt.modulo(value, tailRadix);
        let cornerRank = header / midgeRadix();
        let midgeValue = BigInt.modulo(header, midgeRadix());
        let corner = Coord.unrank(Corners, cornerRank);
        let midge = unrankMidgeLegacy(midgeValue, corner);
        corner :: midge :: split(tailValue, List.reverse(tail), Nil)

    def unrankMidgeLegacy(value: BigInt, corner: Coord): Coord = match corner {
        case CornerCoord(permutation, _) =>
            let flips = Coord.unrank(Midges, BigInt.modulo(value, 2048ii));
            match flips {
                case MidgeCoord(_, orientations) =>
                    MidgeCoord(Orbit64.Rank.permUnrankWithParity(value / 2048ii, 12,
                        Orbit64.Rank.permParity(permutation)), orientations)
                case _ => Coord.unrank(Midges, 0ii)
            }
        case _ => Coord.unrank(Midges, 0ii)
    }

    /// Inverse of `orientationRank`, restoring the forced final orientation.
    def unrankOrientations(value: BigInt, count: Int32, radix: Int32): Vector[Int32] =
        let digits = unrankOrientationDigits(value, count, radix, 0, Vector#{});
        let sum = Vector.foldLeft((acc, digit) -> acc + digit, 0, digits);
        Vector.append(digits, Vector#{Int32.modulo(radix - Int32.modulo(sum, radix), radix)})

    def unrankOrientationDigits(value: BigInt, count: Int32, radix: Int32,
                                index: Int32, out: Vector[Int32]): Vector[Int32] =
        if (index == count) out
        else
            let divisor = Int32.toBigInt(radix);
            let digit = BigInt.modulo(value, divisor) |> BigInt.tryToInt32
                |> Option.getWithDefault(0);
            unrankOrientationDigits(value / divisor, count, radix, index + 1,
                Vector.append(out, Vector#{digit}))

    def widthLoop(total: BigInt, capacity: BigInt, w: Int32): Int32 =
        if (capacity >= total) w else widthLoop(total, capacity * 64ii, w + 1)

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
    /// The framed state of a solved `n x n x n` cube.
    ///
    /// Every coordinate is zero, so this always encodes to a run of `A`s.
    ///
    pub def solved(n: Int32): FramedState =
        Orbit.layout(n) |> List.map(o -> Coord.unrank(o, 0ii)) |> canonical

}
