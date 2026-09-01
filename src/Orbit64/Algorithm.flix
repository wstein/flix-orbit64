///
/// Exact, finite algorithm DAGs over primitive Orbit64 moves.
///
/// Nodes are topologically ordered: every reference points to an earlier node.
/// `Block`, `PackedBlock`, and `Partition` retain stable part boundaries for
/// `SliceParts`; ordinary `Concat` deliberately does not.
///
mod Orbit64.Algorithm {

    /// A topologically ordered DAG and its exported root node.
    pub enum Algorithm with Eq, ToString {
        case Algorithm(List[Node], Int32)
    }

    /// One exact algorithm node.
    pub enum Node with Eq, ToString {
        case Terminal(Orbit64.Move.Move)
        case Concat(List[Int32])
        case Repeat(Int32, BigInt)
        case Inverse(Int32)
        case Block(List[Int32])
        case PackedBlock(List[Int32], List[Int32])
        case Partition(Int32, List[Int32])
        case SliceParts(Int32, Int32, Int32)
    }

    /// Explain why `algorithm` is not a valid finite DAG for cube size `n`.
    pub def faultOf(n: Int32, algorithm: Algorithm): Option[String] =
        match metadata(n, algorithm) {
            case Ok(_)   => None
            case Err(why) => Some(why)
        }

    /// Return the number of primitive terminals expanded by the exported root.
    pub def expandedCount(n: Int32, algorithm: Algorithm): Result[String, BigInt] =
        metadata(n, algorithm) |> Result.map(match Metadata.Metadata(count, _, _) -> count)

    /// Return the root's stable part count when it has stable boundaries.
    pub def partCount(n: Int32, algorithm: Algorithm): Result[String, BigInt] =
        metadata(n, algorithm) |> Result.flatMap(match Metadata.Metadata(_, parts, stable) ->
            if (stable) Ok(Int32.toBigInt(List.length(parts)))
            else Err("algorithm root has no stable part boundaries"))

    enum Metadata {
        case Metadata(BigInt, List[BigInt], Bool)
    }

    def metadata(n: Int32, algorithm: Algorithm): Result[String, Metadata] = match algorithm {
        case Algorithm.Algorithm(nodes, root) =>
            if (n < 2) Err("cube size must be at least 2")
            else buildMetadata(n, nodes, 0, Nil)
                |> Result.flatMap(metas -> rootMetadata(root, List.length(nodes), metas))
    }

    def buildMetadata(n: Int32, nodes: List[Node], index: Int32,
                      previousMetas: List[Metadata]):
            Result[String, List[Metadata]] = match nodes {
        case Nil => Ok(previousMetas)
        case node :: rest =>
            nodeMetadata(n, node, index, previousMetas)
                |> Result.flatMap(meta ->
                    buildMetadata(n, rest, index + 1, meta :: previousMetas))
    }

    def rootMetadata(root: Int32, count: Int32,
                     metas: List[Metadata]): Result[String, Metadata] =
        if (root < 0 or root >= count) Err("algorithm root must reference an existing node")
        else match metadataAt(root, count, metas) {
            case Some(meta) => Ok(meta)
            case None => Err("algorithm root must reference an existing node")
        }

    def nodeMetadata(n: Int32, node: Node, index: Int32,
                     previousMetas: List[Metadata]):
            Result[String, Metadata] = match node {
        case Node.Terminal(move) => match Orbit64.Move.faultOf(n, move) {
            case None      => Ok(Metadata.Metadata(1ii, Nil, false))
            case Some(why) => Err("node ${index}: ${why}")
        }
        case Node.Concat(children) =>
            countsForReferences(children, index, previousMetas)
                |> Result.map(counts -> Metadata.Metadata(sum(counts), Nil, false))
        case Node.Repeat(child, count) =>
            if (count <= 0ii) Err("node ${index}: repeat count must be positive")
            else expandedForReference(child, index, previousMetas)
                |> Result.map(size -> Metadata.Metadata(size * count, Nil, false))
        case Node.Inverse(child) =>
            metadataForReference(child, index, previousMetas)
                |> Result.map(match Metadata.Metadata(size, parts, stable) ->
                    Metadata.Metadata(size, List.reverse(parts), stable))
        case Node.Block(children) =>
            countsForReferences(children, index, previousMetas)
                |> Result.map(counts -> Metadata.Metadata(sum(counts), counts, true))
        case Node.PackedBlock(alphabet, symbols) =>
            countsForReferences(alphabet, index, previousMetas)
                |> Result.flatMap(alphabetCounts ->
                    packedCounts(symbols, alphabetCounts, index)
                        |> Result.map(counts ->
                            Metadata.Metadata(sum(counts), counts, true)))
        case Node.Partition(sequence, boundaries) =>
            stablePartsForReference(sequence, index, previousMetas)
                |> Result.flatMap(parts ->
                    partitionCounts(parts, boundaries, index)
                        |> Result.map(counts ->
                            Metadata.Metadata(sum(counts), counts, true)))
        case Node.SliceParts(sequence, start, end) =>
            stablePartsForReference(sequence, index, previousMetas)
                |> Result.flatMap(parts ->
                    sliceCounts(parts, start, end, index)
                        |> Result.map(counts ->
                            Metadata.Metadata(sum(counts), counts, true)))
    }

    def metadataForReference(reference: Int32, index: Int32,
                             previousMetas: List[Metadata]): Result[String, Metadata] =
        if (reference < 0 or reference >= index)
            Err("node ${index}: a reference must point to an earlier node")
        else match metadataAt(reference, index, previousMetas) {
            case Some(meta) => Ok(meta)
            case None => Err("node ${index}: a reference must point to an earlier node")
        }

    def expandedForReference(reference: Int32, index: Int32,
                             previousMetas: List[Metadata]): Result[String, BigInt] =
        metadataForReference(reference, index, previousMetas)
            |> Result.map(match Metadata.Metadata(size, _, _) -> size)

    def stablePartsForReference(reference: Int32, index: Int32,
                                previousMetas: List[Metadata]): Result[String, List[BigInt]] =
        metadataForReference(reference, index, previousMetas)
            |> Result.flatMap(match Metadata.Metadata(_, parts, stable) ->
                if (stable) Ok(parts)
                else Err("node ${index}: SliceParts and Partition need stable part boundaries"))

    def countsForReferences(references: List[Int32], index: Int32,
                            previousMetas: List[Metadata]): Result[String, List[BigInt]] =
        match references {
            case Nil => Ok(Nil)
            case reference :: rest =>
                expandedForReference(reference, index, previousMetas)
                    |> Result.flatMap(size ->
                        countsForReferences(rest, index, previousMetas)
                            |> Result.map(sizes -> size :: sizes))
        }

    def packedCounts(symbols: List[Int32], alphabetCounts: List[BigInt],
                     index: Int32): Result[String, List[BigInt]] = match symbols {
        case Nil => Ok(Nil)
        case symbol :: rest =>
            if (symbol < 0) Err("node ${index}: packed symbol cannot be negative")
            else match listAt(symbol, alphabetCounts) {
                case None => Err("node ${index}: packed symbol is outside its alphabet")
                case Some(size) => packedCounts(rest, alphabetCounts, index)
                    |> Result.map(sizes -> size :: sizes)
            }
    }

    def partitionCounts(parts: List[BigInt], boundaries: List[Int32],
                        index: Int32): Result[String, List[BigInt]] =
        match boundaryFault(boundaries, List.length(parts)) {
            case Some(why) => Err("node ${index}: ${why}")
            case None      => Ok(partitionCountsUnchecked(parts, boundaries))
        }

    def boundaryFault(boundaries: List[Int32], partCount: Int32): Option[String] =
        match boundaries {
            case Nil => Some("partition boundaries cannot be empty")
            case first :: rest =>
                if (first != 0) Some("partition boundaries must start at zero")
                else boundaryTailFault(rest, first, partCount)
        }

    def boundaryTailFault(boundaries: List[Int32], previous: Int32,
                          partCount: Int32): Option[String] = match boundaries {
        case Nil =>
            if (previous == partCount) None
            else Some("partition boundaries must end at the source part count")
        case boundary :: rest =>
            match boundaryStepFault(boundary, previous, partCount) {
                case Some(why) => Some(why)
                case None      => boundaryTailFault(rest, boundary, partCount)
            }
    }

    def boundaryStepFault(boundary: Int32, previous: Int32,
                          partCount: Int32): Option[String] =
        if (boundary < previous) Some("partition boundaries must be monotonic")
        else if (boundary > partCount) Some("partition boundary is outside the source")
        else None

    def partitionCountsUnchecked(parts: List[BigInt], boundaries: List[Int32]): List[BigInt] =
        match boundaries {
            case _ :: Nil => Nil
            case start :: end :: rest =>
                sum(sliceUnchecked(parts, start, end))
                    :: partitionCountsUnchecked(parts, end :: rest)
            case Nil => Nil
        }

    def sliceCounts(parts: List[BigInt], start: Int32, end: Int32,
                    index: Int32): Result[String, List[BigInt]] =
        if (start < 0 or end < start or end > List.length(parts))
            Err("node ${index}: slice is outside the source part range")
        else Ok(sliceUnchecked(parts, start, end))

    def sliceUnchecked(parts: List[BigInt], start: Int32, end: Int32): List[BigInt] =
        sliceLoop(parts, 0, start, end, Nil) |> List.reverse

    def sliceLoop(parts: List[BigInt], index: Int32, start: Int32, end: Int32,
                  out: List[BigInt]): List[BigInt] = match parts {
        case Nil => out
        case part :: rest =>
            if (index >= start and index < end)
                sliceLoop(rest, index + 1, start, end, part :: out)
            else sliceLoop(rest, index + 1, start, end, out)
    }

    def metadataAt(reference: Int32, count: Int32,
                   previousMetas: List[Metadata]): Option[Metadata] =
        listAt(count - reference - 1, previousMetas)

    def listAt(index: Int32, values: List[a]): Option[a] = match values {
        case Nil => None
        case value :: rest =>
            if (index == 0) Some(value)
            else listAtTail(index, rest)
    }

    def listAtTail(index: Int32, values: List[a]): Option[a] =
        if (index < 0) None
        else listAt(index - 1, values)

    def sum(values: List[BigInt]): BigInt =
        values |> List.foldLeft((acc, value) -> acc + value, 0ii)

}
