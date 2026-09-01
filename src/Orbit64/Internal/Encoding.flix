///
/// Shared base64url arithmetic for every Orbit64 token class.
///
/// This module knows about characters and integers, not cubes. Keeping it
/// below `Internal` prevents transport details from becoming a second public
/// codec API beside `Orbit64.State`, `Orbit64.Move`, and `Orbit64.Token`.
///
mod Orbit64.Internal.Encoding {

    ///
    /// The base64url alphabet, in index order.
    ///
    /// Index `0` is `A`, so a zero written at fixed width is a run of `A`s.
    ///
    pub def alphabet(): String =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

    /// Return the sextet represented by `c`.
    pub def digitOf(c: Char): Option[Int32] =
        List.indexOf(c, String.toList(alphabet()))

    ///
    /// Write `acc` as exactly `w` base64url characters, most significant first.
    ///
    pub def toBase64(acc: BigInt, w: Int32): String =
        emit(acc, w, alphabet(), "")

    def emit(acc: BigInt, remaining: Int32, table: String, out: String): String =
        if (remaining == 0) out
        else
            let q = acc / 64ii;
            let d = BigInt.tryToInt32(acc - q * 64ii) |> Option.getWithDefault(0);
            let c = String.charAt(d, table);
            emit(q, remaining - 1, table, String.concat(Char.toString(c), out))

    ///
    /// Read a base64url string as an integer. Returns `None` for a foreign
    /// character.
    ///
    pub def fromBase64(s: String): Option[BigInt] =
        let table = String.toList(alphabet());
        String.toList(s) |> List.foldLeft((acc, c) -> {
            let digit = List.indexOf(c, table);
            Option.flatMap(a ->
                Option.map(d -> a * 64ii + Int32.toBigInt(d), digit), acc)
        }, Some(0ii))

    /// Pack a class, gamma-coded layer count, rank, marker, and zero fill.
    pub def encodeDelimitedRank(tokenClass: Int32, layers: Int32,
                                rank: BigInt): Result[String, String] =
        if (tokenClass < 0 or tokenClass > 3) Err("token class must be in 0..3")
        else if (layers < 1) Err("reachable layer count must be positive")
        else if (rank < 0ii) Err("payload rank cannot be negative")
        else
            let gammaDigits = floorLog2(Int32.toBigInt(layers));
            let gammaWidth = 2 * gammaDigits + 1;
            let rankWidth = bitWidth(rank);
            let used = 2 + gammaWidth + rankWidth + 1;
            let width = (used + 5) / 6;
            let fill = 6 * width - used;
            let tailWidth = rankWidth + 1 + fill;
            let classPart = Int32.toBigInt(tokenClass) * pow2(6 * width - 2);
            let gammaPart = Int32.toBigInt(layers) * pow2(tailWidth);
            let rankPart = rank * pow2(fill + 1);
            Ok(toBase64(classPart + gammaPart + rankPart + pow2(fill), width))

    /// Unpack and canonically validate a delimiter-padded rank token.
    pub def decodeDelimitedRank(expectedClass: Int32, token: String):
            Result[String, (Int32, BigInt)] =
        if (String.isEmpty(token)) Err("token is empty")
        else match fromBase64(token) {
            case None => Err("token contains a character outside the base64url alphabet")
            case Some(value) => decodeDelimitedValue(expectedClass, token, value)
        }

    def decodeDelimitedValue(expectedClass: Int32, token: String,
                             value: BigInt): Result[String, (Int32, BigInt)] =
        let payloadWidth = 6 * String.length(token) - 2;
        let classCapacity = pow2(payloadWidth);
        let actualClass = (value / classCapacity) |> BigInt.tryToInt32
            |> Option.getWithDefault(-1);
        if (actualClass != expectedClass)
            Err("token has class ${actualClass}, expected ${expectedClass}")
        else
            let body = value - Int32.toBigInt(actualClass) * classCapacity;
            locateGamma(body, pow2(payloadWidth - 1), 0)
                |> Result.flatMap(zeros -> decodeGammaTail(
                    expectedClass, token, body, payloadWidth, zeros))

    def locateGamma(body: BigInt, place: BigInt,
                    zeros: Int32): Result[String, Int32] =
        if (place == 0ii) Err("token has no layer-count gamma code")
        else if (body >= place) Ok(zeros)
        else locateGamma(body, place / 2ii, zeros + 1)

    def decodeGammaTail(expectedClass: Int32, token: String, body: BigInt,
                        payloadWidth: Int32, zeros: Int32):
            Result[String, (Int32, BigInt)] =
        let gammaWidth = 2 * zeros + 1;
        if (gammaWidth > payloadWidth) Err("token ends inside its layer-count gamma code")
        else
            let tailWidth = payloadWidth - gammaWidth;
            let scale = pow2(tailWidth);
            match (body / scale) |> BigInt.tryToInt32 {
                case None => Err("layer count exceeds Int32")
                case Some(layers) =>
                    let tail = body - Int32.toBigInt(layers) * scale;
                    stripFill(tail, 0) |> Result.flatMap(match (marked, _fill) ->
                        finishDelimitedRank(expectedClass, token, layers, marked / 2ii))
            }

    def stripFill(tail: BigInt, fill: Int32): Result[String, (BigInt, Int32)] =
        if (tail == 0ii) Err("token has no end-of-payload marker")
        else if (BigInt.modulo(tail, 2ii) == 0ii) stripFill(tail / 2ii, fill + 1)
        else Ok((tail, fill))

    def finishDelimitedRank(expectedClass: Int32, token: String, layers: Int32,
                            rank: BigInt): Result[String, (Int32, BigInt)] =
        match encodeDelimitedRank(expectedClass, layers, rank) {
            case Ok(canonical) if canonical == token => Ok((layers, rank))
            case Ok(_) => Err("token has non-canonical rank padding")
            case Err(e) => Err(e)
        }

    def bitWidth(value: BigInt): Int32 =
        if (value == 0ii) 0 else floorLog2(value) + 1

    def floorLog2(value: BigInt): Int32 = logLoop(value, -1)

    def logLoop(value: BigInt, acc: Int32): Int32 =
        if (value == 0ii) acc else logLoop(value / 2ii, acc + 1)

    def pow2(exponent: Int32): BigInt = BigInt.pow(base = 2ii, exponent)

}
