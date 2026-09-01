///
/// Primitive layer turns and canonical literal-sequence tokens.
///
/// A move names a face, a zero-based depth from that face, and one of the three
/// non-identity turn amounts. It deliberately does not name rotations, slices,
/// aliases, or notation constructs: those can expand to this vocabulary.
///
mod Orbit64.Move {

    /// A primitive layer turn.
    pub enum Move with Eq, ToString {
        case LayerTurn(Face, Int32, Amount)
    }

    /// Faces in the wire order `URFDLB`.
    pub enum Face with Eq, ToString {
        case U,
        case R,
        case F,
        case D,
        case L,
        case B
    }

    /// Non-identity turn amounts in clockwise, half, inverse order.
    pub enum Amount with Eq, ToString {
        case Clockwise,
        case Half,
        case CounterClockwise
    }

    /// Cubes sharing one reachable layer count and therefore one move alphabet.
    pub enum LayerClass with Eq, ToString {
        case LayerClass(Int32)
    }

    /// Return the reachable layer count carried by `layerClass`.
    pub def layerCount(layerClass: LayerClass): Int32 = match layerClass {
        case LayerClass.LayerClass(layers) => layers
    }

    /// The number of primitive moves available at size `n`.
    pub def alphabetSize(n: Int32): BigInt =
        18ii * Int32.toBigInt(n / 2)

    /// Explain why `move` is not defined for the `n x n x n` cube.
    pub def faultOf(n: Int32, move: Move): Option[String] = match move {
        case Move.LayerTurn(_, depth, _) =>
            if (n < 2) Some("cube size must be at least 2")
            else depthFault(n, depth)
    }

    def depthFault(n: Int32, depth: Int32): Option[String] =
        if (depth < 0) Some("layer depth cannot be negative")
        else if (depth >= n / 2)
            Some("layer depth ${depth} is outside 0..${n / 2 - 1} for ${n}x${n}x${n}")
        else None

    /// Rank a move in face, depth, amount order.
    pub def rank(n: Int32, move: Move): BigInt = match move {
        case Move.LayerTurn(face, depth, amount) =>
            let layers = Int32.toBigInt(n / 2);
            let faceValue = Int32.toBigInt(faceRank(face));
            let depthValue = Int32.toBigInt(depth);
            let amountValue = Int32.toBigInt(amountRank(amount));
            (faceValue * layers + depthValue) * 3ii + amountValue
    }

    /// Recover a move from a rank below `alphabetSize(n)`.
    pub def unrank(n: Int32, value: BigInt): Move =
        let amount = BigInt.modulo(value, 3ii) |> BigInt.tryToInt32
            |> Option.getWithDefault(0) |> amountUnrank;
        let quotient = value / 3ii;
        let layers = Int32.toBigInt(n / 2);
        let depth = BigInt.modulo(quotient, layers) |> BigInt.tryToInt32
            |> Option.getWithDefault(0);
        let face = (quotient / layers) |> BigInt.tryToInt32
            |> Option.getWithDefault(0) |> faceUnrank;
        Move.LayerTurn(face, depth, amount)

    /// Encode a literal sequence of primitive moves.
    pub def encode(n: Int32, moves: List[Move]): Result[String, String] =
        if (n < 2) Err("cube size must be at least 2")
        else match firstFault(n, moves) {
            case Some(why) => Err("move sequence is invalid: ${why}")
            case None =>
                let base = alphabetSize(n);
                let count = List.length(moves);
                let ordinary = moves |> List.foldLeft((acc, move) ->
                    acc * base + rank(n, move), 0ii);
                let wireRank = sequenceOffset(base, count) + ordinary;
                Orbit64.Internal.Encoding.encodeDelimitedRank(1, n / 2, wireRank)
        }

    /// Decode a literal move sequence and return its odd/even layer class.
    pub def decode(token: String): Result[String, (LayerClass, List[Move])] =
        Orbit64.Internal.Encoding.decodeDelimitedRank(1, token)
            |> Result.flatMap(match (layers, wireRank) ->
                decodeSequence(layers, wireRank))

    def decodeSequence(layers: Int32, wireRank: BigInt):
            Result[String, (LayerClass, List[Move])] =
        if (layers > 1073741823) Err("layer count exceeds the Int32 cube-size range")
        else
            let n = layers * 2;
            let base = alphabetSize(n);
            let (count, ordinary) = sequenceRange(base, wireRank, 0, 0ii, 1ii);
            Ok((LayerClass.LayerClass(layers), splitMoves(n, count, ordinary, Nil)))

    def sequenceOffset(base: BigInt, count: Int32): BigInt =
        offsetLoop(base, count, 0, 0ii, 1ii)

    def offsetLoop(base: BigInt, count: Int32, index: Int32,
                   offset: BigInt, block: BigInt): BigInt =
        if (index == count) offset
        else offsetLoop(base, count, index + 1, offset + block, block * base)

    def sequenceRange(base: BigInt, wireRank: BigInt, count: Int32,
                      offset: BigInt, block: BigInt): (Int32, BigInt) =
        if (wireRank < offset + block) (count, wireRank - offset)
        else sequenceRange(base, wireRank, count + 1, offset + block, block * base)

    def splitMoves(n: Int32, count: Int32, value: BigInt,
                   out: List[Move]): List[Move] =
        if (count == 0) out
        else
            let base = alphabetSize(n);
            let quotient = value / base;
            splitMoves(n, count - 1, quotient, unrank(n, value - quotient * base) :: out)

    def firstFault(n: Int32, moves: List[Move]): Option[String] =
        moves |> List.filterMap(move -> faultOf(n, move)) |> List.head

    def faceRank(face: Face): Int32 = match face {
        case Face.U => 0
        case Face.R => 1
        case Face.F => 2
        case Face.D => 3
        case Face.L => 4
        case Face.B => 5
    }

    def faceUnrank(rank: Int32): Face = match rank {
        case 0 => Face.U
        case 1 => Face.R
        case 2 => Face.F
        case 3 => Face.D
        case 4 => Face.L
        case _ => Face.B
    }

    def amountRank(amount: Amount): Int32 = match amount {
        case Amount.Clockwise        => 0
        case Amount.Half             => 1
        case Amount.CounterClockwise => 2
    }

    def amountUnrank(rank: Int32): Amount = match rank {
        case 0 => Amount.Clockwise
        case 1 => Amount.Half
        case _ => Amount.CounterClockwise
    }

}
