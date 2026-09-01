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
        match sizeHeader(16, n) {
            case Err(e) => Err(e)
            case Ok(header) => match firstFault(n, moves) {
                case Some(why) => Err("move sequence is invalid: ${why}")
                case None =>
                    let count = List.length(moves);
                    let total = BigInt.pow(base = alphabetSize(n), count);
                    let value = moves |> List.foldLeft((acc, move) ->
                        acc * alphabetSize(n) + rank(n, move), 0ii);
                    let prefix = Orbit64.Internal.Encoding.encodeVlq(count)
                        |> Result.getWithDefault("");
                    let payload = Orbit64.Internal.Encoding.toBase64(
                        value, Orbit64.Internal.Encoding.dataWidth(total));
                    Ok(String.concat(String.concat(header, prefix), payload))
            }
        }

    /// Decode a literal move-sequence token and return its cube size.
    pub def decode(token: String): Result[String, (Int32, List[Move])] =
        match readSizeHeader(1, token) {
            case Err(e) => Err(e)
            case Ok((n, afterSize)) =>
                match Orbit64.Internal.Encoding.decodeVlq(token, afterSize) {
                    case Err(e) => Err(e)
                    case Ok((count, afterCount)) => decodePayload(n, count, afterCount, token)
                }
        }

    def decodePayload(n: Int32, count: Int32, start: Int32,
                      token: String): Result[String, (Int32, List[Move])] =
        let payloadChars = String.length(token) - start;
        if (2ii * Int32.toBigInt(count) > 3ii * Int32.toBigInt(payloadChars) and count > 0)
            Err("move count cannot fit in the token payload")
        else
            let total = BigInt.pow(base = alphabetSize(n), count);
            let expected = Orbit64.Internal.Encoding.dataWidth(total);
            if (payloadChars != expected)
                Err("expected ${expected} move-payload characters, got ${payloadChars}")
            else
                let payload = String.slice(start = start, end = String.length(token), token);
                match Orbit64.Internal.Encoding.fromBase64(payload) {
                    case None => Err("token contains a character outside the base64url alphabet")
                    case Some(value) =>
                        if (value >= total) Err("move-sequence payload is out of range")
                        else Ok((n, splitMoves(n, count, value, Nil)))
                }

    def splitMoves(n: Int32, count: Int32, value: BigInt,
                   out: List[Move]): List[Move] =
        if (count == 0) out
        else
            let base = alphabetSize(n);
            let quotient = value / base;
            splitMoves(n, count - 1, quotient, unrank(n, value - quotient * base) :: out)

    def firstFault(n: Int32, moves: List[Move]): Option[String] =
        moves |> List.filterMap(move -> faultOf(n, move)) |> List.head

    /// Build the first sextet and optional size escape for `classBase`.
    pub def sizeHeader(classBase: Int32, n: Int32): Result[String, String] =
        if (n < 2) Err("cube size must be at least 2")
        else
            let inline = n - 2;
            let low = if (inline < 15) inline else 15;
            let c = Orbit64.Internal.Encoding.charOf(classBase + low)
                |> Option.getWithDefault('A') |> Char.toString;
            if (inline < 15) Ok(c)
            else Orbit64.Internal.Encoding.encodeVlq(n - 17)
                |> Result.map(suffix -> String.concat(c, suffix))

    /// Read and validate a move-class size header.
    pub def readSizeHeader(expectedClass: Int32, token: String):
            Result[String, (Int32, Int32)] =
        if (String.isEmpty(token)) Err("token is empty")
        else firstDigit(token) |> Result.flatMap(first ->
            readSizeDigit(expectedClass, token, first))

    def firstDigit(token: String): Result[String, Int32] =
        match Orbit64.Internal.Encoding.digitOf(String.charAt(0, token)) {
            case None => Err("token contains a character outside the base64url alphabet")
            case Some(first) => Ok(first)
        }

    def readSizeDigit(expectedClass: Int32, token: String, first: Int32):
            Result[String, (Int32, Int32)] =
        let actualClass = first / 16;
        if (actualClass != expectedClass)
            Err("token has class ${actualClass}, expected ${expectedClass}")
        else decodeSizeLow(token, Int32.modulo(first, 16))

    def decodeSizeLow(token: String, low: Int32): Result[String, (Int32, Int32)] =
        if (low < 15) Ok((low + 2, 1))
        else Orbit64.Internal.Encoding.decodeVlq(token, 1)
            |> Result.flatMap(finishEscapedSize)

    def finishEscapedSize(decoded: (Int32, Int32)):
            Result[String, (Int32, Int32)] = match decoded {
        case (extra, _) if extra > 2147483630 => Err("cube size exceeds Int32")
        case (extra, end)                     => Ok((extra + 17, end))
    }

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
