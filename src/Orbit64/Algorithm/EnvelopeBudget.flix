// SPDX-License-Identifier: Apache-2.0
/// Internal resource checks, performed before JSON parsing and DAG metadata.
mod Orbit64.Algorithm.EnvelopeBudget {
    use Orbit64.Algorithm.Envelope.{Fault, Limits}
    use Orbit64.Algorithm.Node

    /// Limits are positive and cannot exceed this reference implementation's ceilings.
    pub def settings(limits: Limits): Result[Fault, Unit] =
        let ceiling = Orbit64.Algorithm.Envelope.defaultLimits();
        let pairs = (limits#maxInputChars, ceiling#maxInputChars) ::
            (limits#maxNodes, ceiling#maxNodes) ::
            (limits#maxReferences, ceiling#maxReferences) ::
            (limits#maxSymbols, ceiling#maxSymbols) ::
            (limits#maxCountDigits, ceiling#maxCountDigits) ::
            (limits#maxDepth, ceiling#maxDepth) ::
            (limits#maxJsonDepth, ceiling#maxJsonDepth) ::
            (limits#maxMetadataWork, ceiling#maxMetadataWork) :: Nil;
        if (List.forAll(match (value, cap) -> value > 0 and value <= cap, pairs)) Ok(())
        else Err(Fault.InvalidLimits("limits must be positive and within reference ceilings"))

    /// Scan ASCII, nesting, and number lexemes before the recursive JSON parser.
    pub def input(limits: Limits, text: String): Result[Fault, Unit] =
        if (String.length(text) > limits#maxInputChars)
            Err(Fault.ResourceLimit("input character budget exceeded"))
        else String.toList(text) |> List.foldLeft((out, c) ->
            out |> Result.flatMap(state -> scan(limits#maxJsonDepth, state, c)),
            Ok((0, false, false, 0))) |> Result.map(_ -> ())

    def scan(maxDepth: Int32, state: (Int32, Bool, Bool, Int32), c: Char):
            Result[Fault, (Int32, Bool, Bool, Int32)] =
        if (Char.isAscii(c)) scanAscii(maxDepth, state, c)
        else Err(Fault.Malformed("only ASCII input is accepted"))

    def scanAscii(maxDepth: Int32, state: (Int32, Bool, Bool, Int32), c: Char):
            Result[Fault, (Int32, Bool, Bool, Int32)] =
        let (depth, quoted, escaped, digits) = state;
        if (quoted) quotedChar(depth, escaped, c)
        else outside(maxDepth, depth, digits, c)

    def quotedChar(depth: Int32, escaped: Bool, c: Char):
            Result[Fault, (Int32, Bool, Bool, Int32)] =
        let closes = not escaped and c == '"';
        let nextEscape = not escaped and c == '\\';
        Ok((depth, not closes, nextEscape, 0))

    def outside(maxDepth: Int32, depth: Int32, digits: Int32, c: Char):
            Result[Fault, (Int32, Bool, Bool, Int32)] = match c {
        case '"' => Ok((depth, true, false, 0))
        case '[' => open(maxDepth, depth)
        case '{' => open(maxDepth, depth)
        case ']' => Ok((depth - 1, false, false, 0))
        case '}' => Ok((depth - 1, false, false, 0))
        case '.' => numberFault()
        case '-' => numberFault()
        case '+' => numberFault()
        case 'e' => numberFault()
        case 'E' => numberFault()
        case _ => scanDigit(depth, digits, c)
    }

    def open(maxDepth: Int32, depth: Int32): Result[Fault, (Int32, Bool, Bool, Int32)] =
        bound(depth + 1, maxDepth, "JSON nesting budget exceeded")
            |> Result.map(_ -> (depth + 1, false, false, 0))

    def numberFault(): Result[Fault, (Int32, Bool, Bool, Int32)] =
        Err(Fault.Malformed("JSON numbers must be nonnegative decimal integers"))

    def scanDigit(depth: Int32, digits: Int32, c: Char):
            Result[Fault, (Int32, Bool, Bool, Int32)] = match Char.isAsciiDigit(c) {
        case false => Ok((depth, false, false, 0))
        case true if digits >= 10 => Err(Fault.Malformed("JSON integer exceeds Int32 spelling"))
        case true => Ok((depth, false, false, digits + 1))
    }

    type alias Totals = {
        refs = Int64, symbols = Int64, digits = Int64, work = Int64,
        depths = List[Int32], parts = List[Int64]
    }

    /// Bound stored structures and longest reference path before metadata arithmetic.
    pub def graph(limits: Limits, nodes: List[Node]): Result[Fault, Unit] =
        bound(List.length(nodes), limits#maxNodes, "node budget exceeded")
            |> Result.flatMap(_ -> walk(limits, nodes, {
                refs = 0i64, symbols = 0i64, digits = 0i64, work = 0i64,
                depths = Nil, parts = Nil
            }))

    def bound(value: Int32, cap: Int32, why: String): Result[Fault, Unit] =
        if (value > cap) Err(Fault.ResourceLimit(why)) else Ok(())

    def walk(limits: Limits, nodes: List[Node], totals: Totals): Result[Fault, Unit] =
        match nodes {
            case Nil => Ok(())
            case node :: rest => match advance(limits, node, totals) {
                case Err(why) => Err(why)
                case Ok(next) => walk(limits, rest, next)
            }
        }

    def advance(limits: Limits, node: Node, totals: Totals): Result[Fault, Totals] =
        let children = references(node);
        let (produced, visited) = partWork(node, totals#parts);
        let previous = Int32.toInt64(List.length(totals#depths));
        let lookup = List.foldLeft((cost, child) ->
            cost + Int64.max(0i64, previous - Int32.toInt64(child)), 0i64, children);
        let next = {
            refs = totals#refs + Int32.toInt64(List.length(children)),
            symbols = totals#symbols + symbolCount(node),
            digits = totals#digits + Int32.toInt64(countDigits(node)),
            work = totals#work + produced + visited + lookup,
            depths = totals#depths, parts = produced :: totals#parts
        };
        checkTotals(limits, next) |> Result.flatMap(_ ->
            let depth = 1 + List.foldLeft((largest, child) ->
                Int32.max(largest, depthAt(child, totals#depths)), 0, children);
            bound(depth, limits#maxDepth, "DAG depth budget exceeded")
                |> Result.map(_ -> {depths = depth :: totals#depths | next}))

    def checkTotals(limits: Limits, totals: Totals): Result[Fault, Unit] =
        let checks = (totals#refs, limits#maxReferences, "reference budget exceeded") ::
            (totals#symbols, limits#maxSymbols,
                "packed-symbol/partition-boundary budget exceeded") ::
            (totals#digits, limits#maxCountDigits, "repeat count digit budget exceeded") ::
            (totals#work, limits#maxMetadataWork, "metadata work budget exceeded") :: Nil;
        match List.find(match (value, cap, _) -> value > Int32.toInt64(cap), checks) {
            case None => Ok(())
            case Some((_, _, why)) => Err(Fault.ResourceLimit(why))
        }

    def partWork(node: Node, parts: List[Int64]): (Int64, Int64) = match node {
        case Node.Block(children) => (Int32.toInt64(List.length(children)), 0i64)
        case Node.PackedBlock(alphabet, symbols) =>
            let count = Int32.toInt64(List.length(symbols));
            (count, count * Int32.toInt64(List.length(alphabet)))
        case Node.Inverse(child) => let count = partAt(child, parts); (count, count)
        case Node.Partition(child, boundaries) =>
            let count = Int64.max(0i64, Int32.toInt64(List.length(boundaries)) - 1i64);
            (count, count * partAt(child, parts))
        case Node.SliceParts(child, start, end) =>
            (Int64.max(0i64, Int32.toInt64(end) - Int32.toInt64(start)), partAt(child, parts))
        case _ => (0i64, 0i64)
    }

    def partAt(child: Int32, parts: List[Int64]): Int64 =
        let index = List.length(parts) - child - 1;
        if (index < 0) 0i64 else partValue(index, parts)

    def partValue(index: Int32, parts: List[Int64]): Int64 = match parts {
        case Nil => 0i64
        case count :: _ if index == 0 => count
        case _ :: rest => partValue(index - 1, rest)
    }

    def references(node: Node): List[Int32] = match node {
        case Node.Terminal(_) => Nil
        case Node.Concat(children) => children
        case Node.Block(children) => children
        case Node.Repeat(child, _) => child :: Nil
        case Node.Inverse(child) => child :: Nil
        case Node.PackedBlock(alphabet, _) => alphabet
        case Node.Partition(child, _) => child :: Nil
        case Node.SliceParts(child, _, _) => child :: Nil
    }

    def symbolCount(node: Node): Int64 = match node {
        case Node.PackedBlock(_, symbols) => Int32.toInt64(List.length(symbols))
        case Node.Partition(_, boundaries) => Int32.toInt64(List.length(boundaries))
        case _ => 0i64
    }

    def countDigits(node: Node): Int32 = match node {
        case Node.Repeat(_, count) => String.length("${count}")
        case _ => 0
    }

    def depthAt(child: Int32, reversed: List[Int32]): Int32 =
        let index = List.length(reversed) - child - 1;
        if (index < 0) 0 else at(index, reversed)

    def at(index: Int32, values: List[Int32]): Int32 = match values {
        case Nil => 0
        case depth :: _ if index == 0 => depth
        case _ :: rest => at(index - 1, rest)
    }
}
