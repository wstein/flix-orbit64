///
/// Canonical class-`10` encoding for typed algorithm DAGs.
///
/// The payload is a self-delimiting operation grammar: a leading sentinel,
/// operation count, tagged operations, and a final `export` back-reference.
/// References are backward distances, never internal table indices.
///
mod Orbit64.Algorithm.Encoding {

    /// Encode a valid algorithm DAG as an Orbit64 class-`10` token.
    pub def encode(n: Int32, algorithm: Orbit64.Algorithm.Algorithm):
            Result[String, String] =
        match Orbit64.Algorithm.faultOf(n, algorithm) {
            case Some(why) => Err("algorithm DAG is invalid: ${why}")
            case None =>
                let payload = bitsToNatural(true :: algorithmBits(n, algorithm));
                Orbit64.Internal.Encoding.encodeDelimitedRank(2, n / 2, payload)
        }

    /// Decode a class-`10` token without expanding its terminal sequence.
    pub def decode(token: String):
            Result[String, (Orbit64.Move.LayerClass, Orbit64.Algorithm.Algorithm)] =
        Orbit64.Internal.Encoding.decodeDelimitedRank(2, token)
            |> Result.flatMap(match (layers, payload) -> decodePayload(layers, payload))

    def decodePayload(layers: Int32, payload: BigInt):
            Result[String, (Orbit64.Move.LayerClass, Orbit64.Algorithm.Algorithm)] =
        if (layers > 1073741823) Err("layer count exceeds the Int32 cube-size range")
        else match naturalToBits(payload) {
            case Nil => Err("algorithm payload has no sentinel")
            case false :: _ => Err("algorithm payload is missing its sentinel")
            case true :: bits =>
                let n = layers * 2;
                parseAlgorithm(n, bits) |> Result.flatMap(algorithm ->
                    match Orbit64.Algorithm.faultOf(n, algorithm) {
                        case Some(why) => Err("algorithm payload is invalid: ${why}")
                        case None => Ok((Orbit64.Move.LayerClass.LayerClass(layers), algorithm))
                    })
        }

    def algorithmBits(n: Int32, algorithm: Orbit64.Algorithm.Algorithm): List[Bool] =
        match algorithm {
            case Orbit64.Algorithm.Algorithm.Algorithm(nodes, root) =>
                append(naturalBits(Int32.toBigInt(List.length(nodes))),
                    append(nodeBits(n, nodes, 0), exportBits(List.length(nodes), root)))
        }

    def nodeBits(n: Int32, nodes: List[Orbit64.Algorithm.Node], index: Int32):
            List[Bool] = match nodes {
        case Nil => Nil
        case node :: rest => append(oneNodeBits(n, index, node), nodeBits(n, rest, index + 1))
    }

    def exportBits(count: Int32, root: Int32): List[Bool] =
        append(tagBits(15), naturalBits(Int32.toBigInt(count - root - 1)))

    def oneNodeBits(n: Int32, index: Int32, node: Orbit64.Algorithm.Node): List[Bool] = match node {
        case Orbit64.Algorithm.Node.Terminal(move) =>
            append(tagBits(0), naturalBits(Orbit64.Move.rank(n, move)))
        case Orbit64.Algorithm.Node.Concat(children) =>
            append(tagBits(1), referenceListBits(children, index))
        case Orbit64.Algorithm.Node.Repeat(child, count) =>
            append(tagBits(2), append(referenceBits(child, index), naturalBits(count)))
        case Orbit64.Algorithm.Node.Inverse(child) =>
            append(tagBits(3), referenceBits(child, index))
        case Orbit64.Algorithm.Node.Block(children) =>
            append(tagBits(4), referenceListBits(children, index))
        case Orbit64.Algorithm.Node.PackedBlock(alphabet, symbols) =>
            append(tagBits(5), append(referenceListBits(alphabet, index), intListBits(symbols)))
        case Orbit64.Algorithm.Node.Partition(sequence, boundaries) =>
            append(tagBits(6), append(referenceBits(sequence, index), intListBits(boundaries)))
        case Orbit64.Algorithm.Node.SliceParts(sequence, start, end) =>
            append(tagBits(7), append(referenceBits(sequence, index),
                append(naturalBits(Int32.toBigInt(start)), naturalBits(Int32.toBigInt(end)))))
    }

    def tagBits(tag: Int32): List[Bool] =
        binaryBits(Int32.toBigInt(tag), 4, Nil)

    def referenceListBits(values: List[Int32], index: Int32): List[Bool] =
        append(naturalBits(Int32.toBigInt(List.length(values))),
            referenceBitsList(values, index))

    def referenceBitsList(values: List[Int32], index: Int32): List[Bool] = match values {
        case Nil => Nil
        case value :: rest =>
            append(referenceBits(value, index), referenceBitsList(rest, index))
    }

    def referenceBits(reference: Int32, index: Int32): List[Bool] =
        naturalBits(Int32.toBigInt(index - reference - 1))

    def intBits(values: List[Int32]): List[Bool] = match values {
        case Nil => Nil
        case value :: rest => append(naturalBits(Int32.toBigInt(value)), intBits(rest))
    }

    def intListBits(values: List[Int32]): List[Bool] =
        append(naturalBits(Int32.toBigInt(List.length(values))), intBits(values))

    def naturalBits(value: BigInt): List[Bool] =
        let binary = positiveBits(value + 1ii);
        append(falseBits(List.length(binary) - 1), binary)

    def positiveBits(value: BigInt): List[Bool] =
        positiveBitsLoop(value, Nil)

    def positiveBitsLoop(value: BigInt, out: List[Bool]): List[Bool] =
        if (value == 0ii) out
        else positiveBitsLoop(value / 2ii, (BigInt.modulo(value, 2ii) == 1ii) :: out)

    def falseBits(count: Int32): List[Bool] =
        if (count == 0) Nil else false :: falseBits(count - 1)

    def binaryBits(value: BigInt, width: Int32, out: List[Bool]): List[Bool] =
        if (width == 0) out
        else binaryBits(value / 2ii, width - 1,
            (BigInt.modulo(value, 2ii) == 1ii) :: out)

    def bitsToNatural(bits: List[Bool]): BigInt =
        bits |> List.foldLeft((acc, bit) -> acc * 2ii + if (bit) 1ii else 0ii, 0ii)

    def naturalToBits(value: BigInt): List[Bool] =
        if (value == 0ii) Nil else positiveBits(value)

    def parseAlgorithm(n: Int32, bits: List[Bool]): Result[String, Orbit64.Algorithm.Algorithm] =
        parseNatural(bits) |> Result.flatMap(match (count, afterCount) ->
            intValue(count, "node count") |> Result.flatMap(nodeCount ->
                parseNodes(n, nodeCount, afterCount, Nil, 0) |> Result.flatMap(
                    match (nodes, remaining) ->
                        parseExport(List.length(nodes), remaining) |> Result.map(root ->
                            Orbit64.Algorithm.Algorithm.Algorithm(nodes, root)))))

    def parseNodes(n: Int32, remaining: Int32, bits: List[Bool],
                   out: List[Orbit64.Algorithm.Node], index: Int32):
            Result[String, (List[Orbit64.Algorithm.Node], List[Bool])] =
        if (remaining == 0) Ok((List.reverse(out), bits))
        else parseNode(n, index, bits) |> Result.flatMap(match (node, rest) ->
            parseNodes(n, remaining - 1, rest, node :: out, index + 1))

    def parseNode(n: Int32, index: Int32, bits: List[Bool]):
            Result[String, (Orbit64.Algorithm.Node, List[Bool])] =
        parseTag(bits) |> Result.flatMap(match (tag, afterTag) ->
            match parseTaggedNode(n, tag, afterTag) {
                case Ok((node, rest)) => Ok((absolutize(node, index), rest))
                case Err(message) => Err("node ${index}: ${message}")
            })

    def parseExport(count: Int32, bits: List[Bool]): Result[String, Int32] =
        parseTag(bits) |> Result.flatMap(match (tag, afterTag) ->
            parseExportTag(count, tag, afterTag))

    def parseExportTag(count: Int32, tag: Int32, bits: List[Bool]): Result[String, Int32] =
        if (tag != 15) Err("algorithm payload has no export operation (found tag ${tag})")
        else parseNatural(bits) |> Result.flatMap(match (distance, rest) ->
            parseExportDistance(count, distance, rest))

    def parseExportDistance(count: Int32, distance: BigInt, rest: List[Bool]):
            Result[String, Int32] =
        if (not List.isEmpty(rest)) Err("algorithm payload has trailing bits")
        else intValue(distance, "export reference") |> Result.flatMap(d ->
            let root = count - d - 1;
            if (root < 0) Err("export reference is outside the grammar") else Ok(root))

    def absolutize(node: Orbit64.Algorithm.Node, index: Int32):
            Orbit64.Algorithm.Node = match node {
        case Orbit64.Algorithm.Node.Terminal(move) =>
            Orbit64.Algorithm.Node.Terminal(move)
        case Orbit64.Algorithm.Node.Concat(children) =>
            Orbit64.Algorithm.Node.Concat(absoluteList(children, index))
        case Orbit64.Algorithm.Node.Repeat(child, count) =>
            Orbit64.Algorithm.Node.Repeat(absolute(child, index), count)
        case Orbit64.Algorithm.Node.Inverse(child) =>
            Orbit64.Algorithm.Node.Inverse(absolute(child, index))
        case Orbit64.Algorithm.Node.Block(children) =>
            Orbit64.Algorithm.Node.Block(absoluteList(children, index))
        case Orbit64.Algorithm.Node.PackedBlock(alphabet, symbols) =>
            Orbit64.Algorithm.Node.PackedBlock(absoluteList(alphabet, index), symbols)
        case Orbit64.Algorithm.Node.Partition(sequence, boundaries) =>
            Orbit64.Algorithm.Node.Partition(absolute(sequence, index), boundaries)
        case Orbit64.Algorithm.Node.SliceParts(sequence, start, end) =>
            Orbit64.Algorithm.Node.SliceParts(absolute(sequence, index), start, end)
    }

    def absoluteList(values: List[Int32], index: Int32): List[Int32] = match values {
        case Nil => Nil
        case value :: rest => absolute(value, index) :: absoluteList(rest, index)
    }

    def absolute(distance: Int32, index: Int32): Int32 = index - distance - 1

    def parseTaggedNode(n: Int32, tag: Int32, bits: List[Bool]):
            Result[String, (Orbit64.Algorithm.Node, List[Bool])] = match tag {
        case 0 => parseTerminal(n, bits)
        case 1 => parseConcat(bits)
        case 2 => parseRepeat(bits)
        case 3 => parseInverse(bits)
        case 4 => parseBlock(bits)
        case 5 => parsePackedBlock(bits)
        case 6 => parsePartition(bits)
        case 7 => parseSliceParts(bits)
        case _ => Err("algorithm node tag ${tag} is reserved")
    }

    def parseConcat(bits: List[Bool]): Result[String, (Orbit64.Algorithm.Node, List[Bool])] =
        parseReferenceList(bits) |> Result.map(match (children, rest) ->
            (Orbit64.Algorithm.Node.Concat(children), rest))

    def parseRepeat(bits: List[Bool]): Result[String, (Orbit64.Algorithm.Node, List[Bool])] =
        parsePair(bits) |> Result.map(match (child, count, rest) ->
            (Orbit64.Algorithm.Node.Repeat(child, count), rest))

    def parseInverse(bits: List[Bool]): Result[String, (Orbit64.Algorithm.Node, List[Bool])] =
        parseInt(bits, "inverse child") |> Result.map(match (child, rest) ->
            (Orbit64.Algorithm.Node.Inverse(child), rest))

    def parseBlock(bits: List[Bool]): Result[String, (Orbit64.Algorithm.Node, List[Bool])] =
        parseReferenceList(bits) |> Result.map(match (children, rest) ->
            (Orbit64.Algorithm.Node.Block(children), rest))

    def parsePackedBlock(bits: List[Bool]): Result[String, (Orbit64.Algorithm.Node, List[Bool])] =
        parseTwoLists(bits) |> Result.map(match (alphabet, symbols, rest) ->
            (Orbit64.Algorithm.Node.PackedBlock(alphabet, symbols), rest))

    def parsePartition(bits: List[Bool]): Result[String, (Orbit64.Algorithm.Node, List[Bool])] =
        parseInt(bits, "partition sequence") |> Result.flatMap(match (sequence, afterSequence) ->
            parseReferenceList(afterSequence) |> Result.map(match (boundaries, rest) ->
                (Orbit64.Algorithm.Node.Partition(sequence, boundaries), rest)))

    def parseSliceParts(bits: List[Bool]): Result[String, (Orbit64.Algorithm.Node, List[Bool])] =
        parseTriple(bits) |> Result.map(match (sequence, start, end, rest) ->
            (Orbit64.Algorithm.Node.SliceParts(sequence, start, end), rest))

    def parseTerminal(n: Int32, bits: List[Bool]):
            Result[String, (Orbit64.Algorithm.Node, List[Bool])] =
        parseNatural(bits) |> Result.flatMap(match (rank, rest) ->
            if (rank >= Orbit64.Move.alphabetSize(n))
                Err("terminal rank is outside the move alphabet")
            else Ok((Orbit64.Algorithm.Node.Terminal(Orbit64.Move.unrank(n, rank)), rest)))

    def parseTag(bits: List[Bool]): Result[String, (Int32, List[Bool])] =
        takeBits(bits, 4) |> Result.map(match (tagBits, rest) ->
            (bitsToNatural(tagBits) |> BigInt.tryToInt32 |> Option.getWithDefault(-1), rest))

    def parsePair(bits: List[Bool]): Result[String, (Int32, BigInt, List[Bool])] =
        parseInt(bits, "repeat child") |> Result.flatMap(match (child, afterChild) ->
            parseNatural(afterChild) |> Result.map(match (count, rest) -> (child, count, rest)))

    def parseTriple(bits: List[Bool]): Result[String, (Int32, Int32, Int32, List[Bool])] =
        parseInt(bits, "slice sequence") |> Result.flatMap(match (sequence, afterSequence) ->
            parseSliceStart(sequence, afterSequence))

    def parseSliceStart(sequence: Int32, bits: List[Bool]):
            Result[String, (Int32, Int32, Int32, List[Bool])] =
        parseInt(bits, "slice start") |> Result.flatMap(match (start, afterStart) ->
            parseInt(afterStart, "slice end") |> Result.map(match (end, rest) ->
                (sequence, start, end, rest)))

    def parseTwoLists(bits: List[Bool]):
            Result[String, (List[Int32], List[Int32], List[Bool])] =
        parseReferenceList(bits) |> Result.flatMap(match (first, afterFirst) ->
            parseReferenceList(afterFirst) |> Result.map(match (second, rest) ->
                (first, second, rest)))

    def parseReferenceList(bits: List[Bool]): Result[String, (List[Int32], List[Bool])] =
        parseNatural(bits) |> Result.flatMap(match (count, afterCount) ->
            intValue(count, "list length") |> Result.flatMap(length ->
                parseInts(length, afterCount, Nil)))

    def parseInts(remaining: Int32, bits: List[Bool], out: List[Int32]):
            Result[String, (List[Int32], List[Bool])] =
        if (remaining == 0) Ok((List.reverse(out), bits))
        else parseInt(bits, "list item") |> Result.flatMap(match (value, rest) ->
            parseInts(remaining - 1, rest, value :: out))

    def parseInt(bits: List[Bool], name: String): Result[String, (Int32, List[Bool])] =
        parseNatural(bits) |> Result.flatMap(match (value, rest) ->
            intValue(value, name) |> Result.map(intValue -> (intValue, rest)))

    def intValue(value: BigInt, name: String): Result[String, Int32] =
        match BigInt.tryToInt32(value) {
            case Some(intValue) => Ok(intValue)
            case None => Err("${name} exceeds Int32")
        }

    def parseNatural(bits: List[Bool]): Result[String, (BigInt, List[Bool])] =
        gammaZeroes(bits, 0) |> Result.flatMap(match (zeroes, afterZeroes) ->
            takeBits(afterZeroes, zeroes + 1) |> Result.map(match (binary, rest) ->
                (bitsToNatural(binary) - 1ii, rest)))

    def gammaZeroes(bits: List[Bool], count: Int32): Result[String, (Int32, List[Bool])] =
        match bits {
            case Nil => Err("algorithm payload ends inside a natural number")
            case false :: rest => gammaZeroes(rest, count + 1)
            case true :: _ => Ok((count, bits))
        }

    def takeBits(bits: List[Bool], count: Int32):
            Result[String, (List[Bool], List[Bool])] =
        takeBitsLoop(bits, count, Nil)

    def takeBitsLoop(bits: List[Bool], count: Int32, out: List[Bool]):
            Result[String, (List[Bool], List[Bool])] =
        if (count == 0) Ok((List.reverse(out), bits))
        else match bits {
            case Nil => Err("algorithm payload ends inside a field")
            case bit :: rest => takeBitsLoop(rest, count - 1, bit :: out)
        }

    def append(left: List[a], right: List[a]): List[a] = match left {
        case Nil => right
        case value :: rest => value :: append(rest, right)
    }

}
