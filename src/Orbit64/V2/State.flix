///
/// Ranking of Orbit64 V2 cube states: the digit layout of `FORMAT-V2.md`.
///
/// A state is a `Cube` of orbit coordinates in the slot convention of V1.
/// Its rank is the mixed-radix combination of one digit per component. Parity
/// coupled components are not stored: they are recomputed on decoding.
///
mod Orbit64.V2.State {

    use Orbit64.V2.Registry.{Model, Pose}

    /// Orbit coordinates of one cube. Components a type lacks are left empty.
    /// `rotations` holds `r_U r_R r_F r_D r_L r_B` and `frame` a frame rank.
    pub type alias Cube = {
        cornerPieces = Vector[Int32], cornerTwists = Vector[Int32],
        midgePieces = Vector[Int32], midgeFlips = Vector[Int32],
        wings = Vector[Vector[Int32]], centers = Vector[Vector[Int32]],
        rotations = Vector[Int32], frame = Int32
    }

    /// One digit of the layout; wing and center digits are numbered from 1.
    enum Part with Eq, Order {
        case CornerPerm
        case CornerTwist
        case MidgePerm
        case MidgeFlip
        case Wing(Int32)
        case Center(Int32)
        case FixedRot
        case FrameDigit
    }

    def isOdd(n: Int32): Bool = Int32.modulo(n, 2) == 1

    /// Even canonical cubes leave the DBL corner out: it is home by definition.
    def dropsCorner(n: Int32, pose: Pose): Bool = not isOdd(n) and pose == Pose.Canonical

    /// The number of wing orbits.
    pub def wingOrbits(n: Int32): Int32 = (n - 2) / 2

    /// The `(row, column)` names of the center orbits, ordered by lowest facelet.
    pub def centerOrbits(n: Int32): List[(Int32, Int32)] =
        List.range(1, n - 1) |> List.flatMap(r ->
            List.range(r, n - 1 - r) |> List.map(c -> (r, c)))

    def parts(n: Int32, model: Model, pose: Pose): List[Part] =
        let odd = isOdd(n);
        let head = Part.CornerPerm :: Part.CornerTwist :: Nil;
        let midges = if (odd) Part.MidgePerm :: Part.MidgeFlip :: Nil else Nil;
        let wings = List.range(1, wingOrbits(n) + 1) |> List.map(Part.Wing);
        let centers = List.range(1, List.length(centerOrbits(n)) + 1) |> List.map(Part.Center);
        let rotations = if (odd and model == Model.Picture) Part.FixedRot :: Nil else Nil;
        let frame = if (odd and pose == Pose.Framed) Part.FrameDigit :: Nil else Nil;
        List.flatten(head :: midges :: wings :: centers :: rotations :: frame :: Nil)

    def factorial(k: Int32): BigInt =
        List.range(1, k + 1) |> List.foldLeft((acc, i) -> acc * Int32.toBigInt(i), 1ii)

    def power(base: BigInt, exponent: Int32): BigInt =
        List.range(0, exponent) |> List.foldLeft((acc, _) -> acc * base, 1ii)

    def radix(n: Int32, model: Model, pose: Pose, part: Part): BigInt = match part {
        case Part.CornerPerm   => factorial(List.length(cornerSlots(n, pose)))
        case Part.CornerTwist  => power(3ii, List.length(cornerSlots(n, pose)) - 1)
        case Part.MidgePerm    => factorial(12) / 2ii
        case Part.MidgeFlip    => power(2ii, 11)
        case Part.Wing(_)      => factorial(24)
        case Part.Center(_)    => centerRadix(model)
        case Part.FixedRot     => power(2ii, 11)
        case Part.FrameDigit   => 24ii
    }

    def centerRadix(model: Model): BigInt =
        if (model == Model.Color) factorial(24) / power(factorial(4), 6) else factorial(24) / 2ii

    /// The number of states of a type.
    pub def count(n: Int32, model: Model, pose: Pose): BigInt =
        parts(n, model, pose) |> List.foldLeft((acc, p) -> acc * radix(n, model, pose, p), 1ii)

    /// The solved state of a type: every digit is zero.
    pub def solved(n: Int32, model: Model): Cube =
        let identity = k -> Vector.range(0, k);
        let color = Vector.range(0, 24) |> Vector.map(i -> i / 4);
        let odd = isOdd(n);
        { cornerPieces = identity(8), cornerTwists = Vector.repeat(8, 0),
          midgePieces = if (odd) identity(12) else Vector.empty(),
          midgeFlips = if (odd) Vector.repeat(12, 0) else Vector.empty(),
          wings = Vector.repeat(wingOrbits(n), identity(24)),
          centers = Vector.repeat(List.length(centerOrbits(n)),
                        if (model == Model.Color) color else identity(24)),
          rotations = if (odd and model == Model.Picture) Vector.repeat(6, 0) else Vector.empty(),
          frame = 0 }

    // ---------------------------------------------------------------- validation

    def isPermutation(v: Vector[Int32], k: Int32): Bool =
        Vector.length(v) == k and
            Vector.range(0, k) |> Vector.forAll(i -> Vector.exists(x -> x == i, v))

    def inRange(v: Vector[Int32], size: Int32, bound: Int32): Bool =
        Vector.length(v) == size and Vector.forAll(x -> x >= 0 and x < bound, v)

    def sumOf(v: Vector[Int32]): Int32 = Vector.foldLeft((a, x) -> a + x, 0, v)

    def parityOf(v: Vector[Int32]): Int32 = Orbit64.Rank.permParity(v)

    def firstFault(faults: List[Option[String]]): Option[String] =
        faults |> List.filterMap(f -> f) |> List.head

    def check(ok: Bool, why: String): Option[String] = if (ok) None else Some(why)

    /// The wing orbit parity `W_k`, zero when the cube has no wing orbit at depth `k`.
    def wingParity(n: Int32, cube: Cube, k: Int32): Int32 =
        if (k >= 1 and k <= wingOrbits(n)) parityOf(Vector.get(k - 1, cube#wings)) else 0

    /// The parity the `index`-th (from 1) center orbit must have, in the picture model.
    def requiredCenterParity(n: Int32, cornerParity: Int32, wing: Int32 -> Int32, index: Int32): Int32 =
        match List.drop(index - 1, centerOrbits(n)) {
            case (r, c) :: _ =>
                let d = Int32.min(c, n - 1 - c);
                Int32.modulo(cornerParity + wing(r) + wing(d), 2)
            case Nil => 0
        }

    def colorsBalanced(v: Vector[Int32]): Bool =
        inRange(v, 24, 6) and List.range(0, 6) |> List.forAll(t -> copies(v, t) == 4)

    def copies(v: Vector[Int32], color: Int32): Int32 = Vector.count(x -> x == color, v)

    def centerValid(model: Model, v: Vector[Int32]): Bool =
        if (model == Model.Color) colorsBalanced(v) else isPermutation(v, 24)

    def frameValid(framed: Bool, frame: Int32): Bool =
        if (framed) frame >= 0 and frame < 24 else frame == 0

    def layoutFault(n: Int32, model: Model, pose: Pose, cube: Cube): Option[String] =
        let odd = isOdd(n);
        let w = wingOrbits(n);
        let m = List.length(centerOrbits(n));
        firstFault(
            check(isPermutation(cube#cornerPieces, 8), "corner pieces are not a permutation of 8") ::
            check(inRange(cube#cornerTwists, 8, 3), "corner twists must be 8 values in 0..2") ::
            check(if (odd) isPermutation(cube#midgePieces, 12)
                  else Vector.length(cube#midgePieces) == 0,
                  "midge pieces must be a permutation of 12 on odd cubes and empty otherwise") ::
            check(if (odd) inRange(cube#midgeFlips, 12, 2) else Vector.length(cube#midgeFlips) == 0,
                  "midge flips must be 12 values in 0..1 on odd cubes and empty otherwise") ::
            check(Vector.length(cube#wings) == w and
                      Vector.forAll(v -> isPermutation(v, 24), cube#wings),
                  "expected ${w} wing permutations of 24") ::
            check(Vector.length(cube#centers) == m, "expected ${m} center orbits") ::
            check(Vector.forAll(v -> centerValid(model, v), cube#centers),
                  "a center orbit is not a valid color multiset or permutation of 24") ::
            check(if (odd and model == Model.Picture) inRange(cube#rotations, 6, 4)
                  else Vector.length(cube#rotations) == 0,
                  "rotations must be 6 values in 0..3 on odd picture cubes and empty otherwise") ::
            check(frameValid(odd and pose == Pose.Framed, cube#frame),
                  "frame must be 0..23 on odd framed cubes and 0 otherwise") ::
            Nil)

    def lawFault(n: Int32, model: Model, pose: Pose, cube: Cube): Option[String] =
        let odd = isOdd(n);
        let c = parityOf(cube#cornerPieces);
        let wing = k -> wingParity(n, cube, k);
        let rotationParity = Int32.modulo(sumOf(cube#rotations), 2);
        firstFault(
            check(Int32.modulo(sumOf(cube#cornerTwists), 3) == 0, "corner twists must sum to 0 mod 3") ::
            check(not odd or Int32.modulo(sumOf(cube#midgeFlips), 2) == 0,
                  "midge flips must sum to 0 mod 2") ::
            check(not dropsCorner(n, pose) or
                      (Vector.get(6, cube#cornerPieces) == 6 and Vector.get(6, cube#cornerTwists) == 0),
                  "a canonical even cube has its DBL corner home with twist 0") ::
            check(not odd or parityOf(cube#midgePieces) == c, "midge parity must equal corner parity") ::
            check(not (odd and model == Model.Picture) or rotationParity == c,
                  "fixed-center rotation parity must equal corner parity") ::
            check(model == Model.Color or
                      Vector.range(0, Vector.length(cube#centers)) |> Vector.forAll(i ->
                          parityOf(Vector.get(i, cube#centers))
                              == requiredCenterParity(n, c, wing, i + 1)),
                  "a center orbit parity breaks the picture relation") ::
            Nil)

    // ------------------------------------------------------------------- ranking

    /// Little-endian: the first value is the units digit.
    def orientationRank(values: Vector[Int32], count: Int32, base: Int32): BigInt =
        List.range(0, count) |> List.reverse
            |> List.foldLeft((acc, i) -> acc * big(base) + big(Vector.get(i, values)), 0ii)

    def big(x: Int32): BigInt = Int32.toBigInt(x)

    def small(x: BigInt): Int32 = BigInt.tryToInt32(x) |> Option.getWithDefault(0)

    /// The inverse, restoring the forced last orientation.
    def orientationUnrank(value: BigInt, count: Int32, base: Int32): Vector[Int32] =
        let b = Int32.toBigInt(base);
        let digits = List.range(0, count) |> List.foldLeft((acc, _) -> {
            let (v, out) = acc;
            let d = BigInt.modulo(v, b) |> BigInt.tryToInt32 |> Option.getWithDefault(0);
            (v / b, d :: out)
        }, (value, Nil)) |> snd |> List.reverse;
        let forced = Int32.modulo(base - Int32.modulo(List.sum(digits), base), base);
        List.append(digits, forced :: Nil) |> List.toVector

    /// The corner slots that are stored: all eight, or all but DBL.
    def cornerSlots(n: Int32, pose: Pose): List[Int32] =
        if (dropsCorner(n, pose)) List#{0, 1, 2, 3, 4, 5, 7} else List.range(0, 8)

    def storedPieces(n: Int32, pose: Pose, cube: Cube): Vector[Int32] =
        let shift = p -> if (dropsCorner(n, pose) and p > 6) p - 1 else p;
        cornerSlots(n, pose) |> List.map(s -> shift(Vector.get(s, cube#cornerPieces))) |> List.toVector

    def storedTwists(n: Int32, pose: Pose, cube: Cube): Vector[Int32] =
        cornerSlots(n, pose) |> List.map(s -> Vector.get(s, cube#cornerTwists)) |> List.toVector

    def divisor(i: Int32): BigInt = if (i == 5) 2ii else 1ii

    def rotationDigit(r: Vector[Int32]): BigInt =
        let weights = List#{1ii, 4ii, 16ii, 64ii, 256ii, 1024ii};
        let values = List.range(0, 6) |> List.map(i -> big(Vector.get(i, r)) / divisor(i));
        List.zip(weights, values) |> List.foldLeft((acc, wv) -> acc + fst(wv) * snd(wv), 0ii)

    def midgeDigit(m: Vector[Int32]): BigInt = Orbit64.Rank.permRankWithParity(m, parityOf(m))

    def digitOf(n: Int32, model: Model, pose: Pose, cube: Cube, part: Part): BigInt = match part {
        case Part.CornerPerm  => Orbit64.Rank.permRank(storedPieces(n, pose, cube))
        case Part.CornerTwist =>
            let twists = storedTwists(n, pose, cube);
            orientationRank(twists, Vector.length(twists) - 1, 3)
        case Part.MidgePerm   => midgeDigit(cube#midgePieces)
        case Part.MidgeFlip   => orientationRank(cube#midgeFlips, 11, 2)
        case Part.Wing(i)     => Orbit64.Rank.permRank(Vector.get(i - 1, cube#wings))
        case Part.Center(i)   =>
            let v = Vector.get(i - 1, cube#centers);
            if (model == Model.Color) Orbit64.Rank.multisetRank(v, 4, 6)
            else Orbit64.Rank.permRankWithParity(v, parityOf(v))
        case Part.FixedRot    => rotationDigit(cube#rotations)
        case Part.FrameDigit  => Int32.toBigInt(cube#frame)
    }

    /// The rank of a valid state of the type, or the reason it is invalid.
    pub def rank(n: Int32, model: Model, pose: Pose, cube: Cube): Result[String, BigInt] =
        match firstFault(layoutFault(n, model, pose, cube) :: lawFault(n, model, pose, cube) :: Nil) {
            case Some(why) => Err(why)
            case None =>
                Ok(parts(n, model, pose) |> List.foldLeft((acc, p) ->
                    acc * radix(n, model, pose, p) + digitOf(n, model, pose, cube, p), 0ii))
        }

    // ----------------------------------------------------------------- unranking

    /// The digits of `value`, one per part, as a map.
    def splitDigits(n: Int32, model: Model, pose: Pose, value: BigInt): Map[Part, BigInt] =
        let all = parts(n, model, pose);
        let (_, out) = List.foldLeft((acc, p) -> {
            let (v, m) = acc;
            let r = radix(n, model, pose, p);
            let q = v / r;
            (q, Map.insert(p, v - q * r, m))
        }, (value, Map.empty()), List.reverse(all));
        out

    /// Re-insert the left-out DBL corner (slot 6) and undo the piece renumbering.
    def restoreDbl(stored: Vector[Int32], dbl: Int32, renumber: Bool): Vector[Int32] =
        let unshift = p -> if (renumber and p >= 6) p + 1 else p;
        let at = i -> unshift(Vector.get(i, stored));
        let slot = i -> if (i < 6) at(i) else if (i == 6) dbl else at(6);
        List.range(0, 8) |> List.map(slot) |> List.toVector

    /// The state with the given rank. `value` must be below `count(n, model, pose)`.
    pub def unrank(n: Int32, model: Model, pose: Pose, value: BigInt): Cube =
        let digits = splitDigits(n, model, pose, value);
        let d = p -> Map.getWithDefault(p, 0ii, digits);
        let odd = isOdd(n);
        let storedCount = List.length(cornerSlots(n, pose));
        let pieces = Orbit64.Rank.permUnrank(d(Part.CornerPerm), storedCount);
        let twists = orientationUnrank(d(Part.CornerTwist), storedCount - 1, 3);
        let cornerPieces = if (dropsCorner(n, pose)) restoreDbl(pieces, 6, true) else pieces;
        let cornerTwists = if (dropsCorner(n, pose)) restoreDbl(twists, 0, false) else twists;
        let c = parityOf(cornerPieces);
        let wings = Vector.range(0, wingOrbits(n)) |> Vector.map(i ->
            Orbit64.Rank.permUnrank(d(Part.Wing(i + 1)), 24));
        let partial = { cornerPieces = cornerPieces, cornerTwists = cornerTwists,
                        midgePieces = Vector.empty(), midgeFlips = Vector.empty(), wings = wings,
                        centers = Vector.empty(), rotations = Vector.empty(), frame = 0 };
        let wing = k -> wingParity(n, partial, k);
        let centers = Vector.range(0, List.length(centerOrbits(n))) |> Vector.map(i ->
            if (model == Model.Color) Orbit64.Rank.multisetUnrank(d(Part.Center(i + 1)), 24, 4, 6)
            else Orbit64.Rank.permUnrankWithParity(d(Part.Center(i + 1)), 24,
                     requiredCenterParity(n, c, wing, i + 1)));
        let rotations = if (odd and model == Model.Picture) unrankRotations(d(Part.FixedRot), c)
                        else Vector.empty();
        { cornerPieces = cornerPieces, cornerTwists = cornerTwists,
          midgePieces = if (odd) Orbit64.Rank.permUnrankWithParity(d(Part.MidgePerm), 12, c)
                        else Vector.empty(),
          midgeFlips = if (odd) orientationUnrank(d(Part.MidgeFlip), 11, 2) else Vector.empty(),
          wings = wings, centers = centers, rotations = rotations,
          frame = if (odd and pose == Pose.Framed) d(Part.FrameDigit) |> BigInt.tryToInt32
                      |> Option.getWithDefault(0) else 0 }

    /// Split the rotation digit; the low bit of `r_B` follows from `R = C`.
    def unrankRotations(digit: BigInt, cornerParity: Int32): Vector[Int32] =
        let part = i -> small(BigInt.modulo(digit / power(4ii, i), 4ii));
        let high = small(digit / 1024ii);
        let five = List.range(0, 5) |> List.map(part);
        let low = Int32.modulo(cornerParity - List.sum(five), 2);
        List.append(five, (2 * high + low) :: Nil) |> List.toVector

}
