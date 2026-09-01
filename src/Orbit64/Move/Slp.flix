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
        case Slp.Slp(rules) =>
            if (n < 2) Err("cube size must be at least 2")
            else match firstFault(n, rules, 0) {
                case Some(why) => Err("move SLP is invalid: ${why}")
                case None =>
                    let alphabet = Orbit64.Move.alphabetSize(n);
                    let count = List.length(rules);
                    let wireRank = grammarOffset(alphabet, count)
                        + assemble(n, rules, 0, 0ii);
                    Orbit64.Internal.Encoding.encodeDelimitedRank(2, n / 2, wireRank)
            }
    }

    /// Decode a move SLP without expanding its root, returning its layer class.
    pub def decode(token: String): Result[String, (Orbit64.Move.LayerClass, Slp)] =
        Orbit64.Internal.Encoding.decodeDelimitedRank(2, token)
            |> Result.flatMap(match (layers, wireRank) ->
                decodeGrammar(layers, wireRank))

    def decodeGrammar(layers: Int32, wireRank: BigInt):
            Result[String, (Orbit64.Move.LayerClass, Slp)] =
        if (layers > 1073741823) Err("layer count exceeds the Int32 cube-size range")
        else
            let n = layers * 2;
            let alphabet = Orbit64.Move.alphabetSize(n);
            let (count, ordinary) = grammarRange(alphabet, wireRank, 0, 0ii, 1ii);
            let layerClass = Orbit64.Move.LayerClass.LayerClass(layers);
            Ok((layerClass, Slp.Slp(splitRules(n, count - 1, ordinary, Nil))))

    def grammarOffset(alphabet: BigInt, count: Int32): BigInt =
        grammarOffsetLoop(alphabet, count, 0, 0ii, 1ii)

    def grammarOffsetLoop(alphabet: BigInt, count: Int32, index: Int32,
                          offset: BigInt, block: BigInt): BigInt =
        if (index == count) offset
        else
            let i = Int32.toBigInt(index);
            grammarOffsetLoop(alphabet, count, index + 1,
                offset + block, block * (alphabet + i * i))

    def grammarRange(alphabet: BigInt, wireRank: BigInt, count: Int32,
                     offset: BigInt, block: BigInt): (Int32, BigInt) =
        if (wireRank < offset + block) (count, wireRank - offset)
        else
            let i = Int32.toBigInt(count);
            grammarRange(alphabet, wireRank, count + 1,
                offset + block, block * (alphabet + i * i))

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
