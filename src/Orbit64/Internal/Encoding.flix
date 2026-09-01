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

}
