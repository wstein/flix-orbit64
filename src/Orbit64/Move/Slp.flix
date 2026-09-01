///
/// Canonical straight-line programs over `Orbit64.Move.Move` terminals.
///
/// Rules are topologically ordered and the last rule is the root. Decoding
/// never expands the generated sequence, so a compact grammar cannot become a
/// decompression bomb merely by being inspected.
///
mod Orbit64.Move.Slp {

    /// A complete straight-line program; `Nil` denotes the empty sequence.
    pub enum Slp with Eq, ToString {
        case Slp(List[Rule])
    }

    /// One terminal or concatenation rule.
    pub enum Rule with Eq, ToString {
        case Terminal(Orbit64.Move.Move),
        case Concat(Int32, Int32)
    }

    /// Encode a structurally exact move SLP.
    pub def encode(n: Int32, slp: Slp): Result[String, String] = match slp {
        case Slp.Slp(rules) => match Orbit64.Move.sizeHeader(32, n) {
            case Err(e) => Err(e)
            case Ok(header) => match firstFault(n, rules, 0) {
                case Some(why) => Err("move SLP is invalid: ${why}")
                case None =>
                    let count = List.length(rules);
                    let total = grammarTotal(Orbit64.Move.alphabetSize(n), count);
                    let value = assemble(n, rules, 0, 0ii);
                    let prefix = Orbit64.Internal.Encoding.encodeVlq(count)
                        |> Result.getWithDefault("");
                    let payload = Orbit64.Internal.Encoding.toBase64(
                        value, Orbit64.Internal.Encoding.dataWidth(total));
                    Ok(String.concat(String.concat(header, prefix), payload))
            }
        }
    }

    /// Decode a move-SLP token without expanding its root.
    pub def decode(token: String): Result[String, (Int32, Slp)] =
        match Orbit64.Move.readSizeHeader(2, token) {
            case Err(e) => Err(e)
            case Ok((n, afterSize)) =>
                match Orbit64.Internal.Encoding.decodeVlq(token, afterSize) {
                    case Err(e) => Err(e)
                    case Ok((count, afterCount)) => decodePayload(n, count, afterCount, token)
                }
        }

    def decodePayload(n: Int32, count: Int32, start: Int32,
                      token: String): Result[String, (Int32, Slp)] =
        let payloadChars = String.length(token) - start;
        if (2ii * Int32.toBigInt(count) > 3ii * Int32.toBigInt(payloadChars) and count > 0)
            Err("SLP rule count cannot fit in the token payload")
        else
            let alphabet = Orbit64.Move.alphabetSize(n);
            let total = grammarTotal(alphabet, count);
            let expected = Orbit64.Internal.Encoding.dataWidth(total);
            if (payloadChars != expected)
                Err("expected ${expected} SLP-payload characters, got ${payloadChars}")
            else
                let payload = String.slice(start = start, end = String.length(token), token);
                match Orbit64.Internal.Encoding.fromBase64(payload) {
                    case None => Err("token contains a character outside the base64url alphabet")
                    case Some(value) =>
                        if (value >= total) Err("move-SLP payload is out of range")
                        else Ok((n, Slp.Slp(splitRules(n, count - 1, value, Nil))))
                }

    def grammarTotal(alphabet: BigInt, count: Int32): BigInt =
        totalLoop(alphabet, count, 0, 1ii)

    def totalLoop(alphabet: BigInt, count: Int32,
                  index: Int32, acc: BigInt): BigInt =
        if (index == count) acc
        else
            let i = Int32.toBigInt(index);
            totalLoop(alphabet, count, index + 1, acc * (alphabet + i * i))

    def assemble(n: Int32, rules: List[Rule],
                 index: Int32, acc: BigInt): BigInt = match rules {
        case Nil => acc
        case rule :: rest =>
            let i = Int32.toBigInt(index);
            let radix = Orbit64.Move.alphabetSize(n) + i * i;
            assemble(n, rest, index + 1, acc * radix + ruleRank(n, index, rule))
    }

    def ruleRank(n: Int32, index: Int32, rule: Rule): BigInt = match rule {
        case Rule.Terminal(move) => Orbit64.Move.rank(n, move)
        case Rule.Concat(left, right) =>
            Orbit64.Move.alphabetSize(n)
                + Int32.toBigInt(left) * Int32.toBigInt(index)
                + Int32.toBigInt(right)
    }

    def splitRules(n: Int32, index: Int32, value: BigInt,
                   out: List[Rule]): List[Rule] =
        if (index < 0) out
        else
            let i = Int32.toBigInt(index);
            let alphabet = Orbit64.Move.alphabetSize(n);
            let radix = alphabet + i * i;
            let quotient = value / radix;
            let digit = value - quotient * radix;
            let rule = if (digit < alphabet) {
                Rule.Terminal(Orbit64.Move.unrank(n, digit))
            } else {
                let pair = digit - alphabet;
                let left = BigInt.tryToInt32(pair / i) |> Option.getWithDefault(0);
                let right = BigInt.tryToInt32(pair - Int32.toBigInt(left) * i)
                    |> Option.getWithDefault(0);
                Rule.Concat(left, right)
            };
            splitRules(n, index - 1, quotient, rule :: out)

    def firstFault(n: Int32, rules: List[Rule], index: Int32): Option[String] =
        match rules {
            case Nil => None
            case rule :: rest => match ruleFault(n, index, rule) {
                case Some(why) => Some("rule ${index}: ${why}")
                case None      => firstFault(n, rest, index + 1)
            }
        }

    def ruleFault(n: Int32, index: Int32, rule: Rule): Option[String] = match rule {
        case Rule.Terminal(move) => Orbit64.Move.faultOf(n, move)
        case Rule.Concat(left, right) => referenceFault(index, left, right)
    }

    def referenceFault(index: Int32, left: Int32, right: Int32): Option[String] =
        if (left < 0 or right < 0) Some("a rule reference cannot be negative")
        else if (left >= index or right >= index)
            Some("Concat references must point to earlier rules")
        else None

}
