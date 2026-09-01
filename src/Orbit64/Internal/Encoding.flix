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

    /// Return the character for a sextet, or `None` outside `0..63`.
    pub def charOf(d: Int32): Option[Char] =
        if (d < 0 or d >= 64) None else Some(String.charAt(d, alphabet()))

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

    /// The fewest base64url characters that hold every value below `total`.
    pub def dataWidth(total: BigInt): Int32 =
        if (total <= 1ii) 0 else widthLoop(total, 64ii, 1)

    def widthLoop(total: BigInt, capacity: BigInt, width: Int32): Int32 =
        if (capacity >= total) width
        else widthLoop(total, capacity * 64ii, width + 1)

    /// Encode a non-negative `Int32` as canonical little-endian base64 VLQ.
    pub def encodeVlq(value: Int32): Result[String, String] =
        if (value < 0) Err("a VLQ value cannot be negative")
        else Ok(emitVlq(value, ""))

    def emitVlq(value: Int32, out: String): String =
        let quotient = value / 32;
        let payload = Int32.modulo(value, 32);
        let digit = if (quotient == 0) payload else payload + 32;
        let c = charOf(digit) |> Option.getWithDefault('A');
        let next = String.concat(out, Char.toString(c));
        if (quotient == 0) next else emitVlq(quotient, next)

    /// Decode one canonical VLQ at `start`, returning its value and end index.
    pub def decodeVlq(s: String, start: Int32): Result[String, (Int32, Int32)] =
        decodeVlqLoop(s, (start, start, 1ii, 0ii))

    def decodeVlqLoop(s: String, state: (Int32, Int32, BigInt, BigInt)):
            Result[String, (Int32, Int32)] =
        let (_start, index, _place, _acc) = state;
        vlqDigitAt(s, index) |> Result.flatMap(digit ->
            consumeVlqDigit(s, state, digit))

    def vlqDigitAt(s: String, index: Int32): Result[String, Int32] =
        if (index >= String.length(s)) Err("token ends inside a VLQ")
        else decodeVlqChar(String.charAt(index, s))

    def decodeVlqChar(c: Char): Result[String, Int32] =
        match digitOf(c) {
            case None => Err("token contains a character outside the base64url alphabet")
            case Some(digit) => Ok(digit)
        }

    def consumeVlqDigit(s: String, state: (Int32, Int32, BigInt, BigInt),
                        digit: Int32): Result[String, (Int32, Int32)] =
        let (start, index, place, acc) = state;
        let payload = Int32.modulo(digit, 32);
        let value = acc + Int32.toBigInt(payload) * place;
        if (digit >= 32)
            decodeVlqLoop(s, (start, index + 1, place * 32ii, value))
        else if (index > start and payload == 0)
            Err("VLQ has a redundant final zero group")
        else finishVlq(value, index + 1)

    def finishVlq(value: BigInt, end: Int32): Result[String, (Int32, Int32)] =
        match BigInt.tryToInt32(value) {
            case None    => Err("VLQ value exceeds Int32")
            case Some(v) => Ok((v, end))
        }

}
