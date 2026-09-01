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

    /// Fold the exact terminal stream without materializing its expansion.
    pub def foldTerminals(n: Int32, algorithm: Algorithm, initial: a,
                          visit: (a, Orbit64.Move.Move) -> a): Result[String, a] =
        match algorithm {
            case Algorithm.Algorithm(nodes, root) =>
                if (n < 2) Err("cube size must be at least 2")
                else buildMetadata(n, nodes, 0, Nil) |> Result.flatMap(metas ->
                    rootMetadata(root, List.length(nodes), metas)
                        |> Result.flatMap(_ ->
                            foldNode(nodes, metas, root, false, initial, visit)))
        }

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

    def sliceUnchecked(parts: List[a], start: Int32, end: Int32): List[a] =
        sliceLoop(parts, 0, start, end, Nil) |> List.reverse

    def sliceLoop(parts: List[a], index: Int32, start: Int32, end: Int32,
                  out: List[a]): List[a] = match parts {
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

    def foldNode(nodes: List[Node], metas: List[Metadata], reference: Int32,
                 backwards: Bool, acc: a,
                 visit: (a, Orbit64.Move.Move) -> a): Result[String, a] =
        match nodeAt(reference, nodes) {
            case None => Err("internal error: validated node is missing")
            case Some(node) => foldKnownNode(nodes, metas, reference, node,
                backwards, acc, visit)
        }

    def foldKnownNode(nodes: List[Node], metas: List[Metadata], reference: Int32,
                      node: Node, backwards: Bool, acc: a,
                      visit: (a, Orbit64.Move.Move) -> a): Result[String, a] =
        match node {
            case Node.Terminal(move) =>
                if (backwards) Ok(visit(acc, inverseMove(move)))
                else Ok(visit(acc, move))
            case Node.Concat(children) =>
                foldReferences(nodes, metas, children, backwards, acc, visit)
            case Node.Repeat(child, count) =>
                foldRepeated(nodes, metas, child, count, backwards, acc, visit)
            case Node.Inverse(child) =>
                foldNode(nodes, metas, child, not backwards, acc, visit)
            case Node.Block(_) => foldAllParts(nodes, metas, reference, backwards, acc, visit)
            case Node.PackedBlock(_, _) =>
                foldAllParts(nodes, metas, reference, backwards, acc, visit)
            case Node.Partition(_, _) =>
                foldAllParts(nodes, metas, reference, backwards, acc, visit)
            case Node.SliceParts(_, _, _) =>
                foldAllParts(nodes, metas, reference, backwards, acc, visit)
        }

    def foldReferences(nodes: List[Node], metas: List[Metadata], references: List[Int32],
                       backwards: Bool, acc: a,
                       visit: (a, Orbit64.Move.Move) -> a): Result[String, a] =
        let ordered = if (backwards) List.reverse(references) else references;
        foldReferenceList(nodes, metas, ordered, backwards, acc, visit)

    def foldReferenceList(nodes: List[Node], metas: List[Metadata], references: List[Int32],
                          backwards: Bool, acc: a,
                          visit: (a, Orbit64.Move.Move) -> a): Result[String, a] =
        match references {
            case Nil => Ok(acc)
            case reference :: rest =>
                foldNode(nodes, metas, reference, backwards, acc, visit)
                    |> Result.flatMap(next ->
                        foldReferenceList(nodes, metas, rest, backwards, next, visit))
        }

    def foldRepeated(nodes: List[Node], metas: List[Metadata], child: Int32, count: BigInt,
                     backwards: Bool, acc: a,
                     visit: (a, Orbit64.Move.Move) -> a): Result[String, a] =
        if (count == 0ii) Ok(acc)
        else foldNode(nodes, metas, child, backwards, acc, visit)
            |> Result.flatMap(next ->
                foldRepeated(nodes, metas, child, count - 1ii, backwards, next, visit))

    def foldAllParts(nodes: List[Node], metas: List[Metadata], reference: Int32,
                     backwards: Bool, acc: a,
                     visit: (a, Orbit64.Move.Move) -> a): Result[String, a] =
        partTotal(reference, nodes, metas) |> Result.flatMap(total ->
            foldParts(nodes, metas, reference, 0, total, backwards, acc, visit))

    def foldParts(nodes: List[Node], metas: List[Metadata], reference: Int32,
                  start: Int32, end: Int32, backwards: Bool, acc: a,
                  visit: (a, Orbit64.Move.Move) -> a): Result[String, a] =
        match nodeAt(reference, nodes) {
            case None => Err("internal error: validated part node is missing")
            case Some(node) => foldKnownParts(nodes, metas, node, start, end,
                backwards, acc, visit)
        }

    def foldKnownParts(nodes: List[Node], metas: List[Metadata], node: Node,
                       start: Int32, end: Int32, backwards: Bool, acc: a,
                       visit: (a, Orbit64.Move.Move) -> a): Result[String, a] =
        match node {
            case Node.Block(children) =>
                foldPartReferences(nodes, metas, children, start, end, backwards, acc, visit)
            case Node.PackedBlock(alphabet, symbols) =>
                foldPartReferences(nodes, metas, packedReferences(alphabet, symbols),
                    start, end, backwards, acc, visit)
            case Node.Partition(sequence, boundaries) =>
                foldPartitionParts(nodes, metas, sequence, boundaries, start, end,
                    backwards, acc, visit)
            case Node.SliceParts(sequence, offset, _) =>
                foldParts(nodes, metas, sequence, offset + start, offset + end,
                    backwards, acc, visit)
            case Node.Inverse(child) =>
                partTotal(child, nodes, metas) |> Result.flatMap(total ->
                    foldParts(nodes, metas, child, total - end, total - start,
                        not backwards, acc, visit))
            case _ => Err("internal error: validated node lost its stable boundaries")
        }

    def foldPartReferences(nodes: List[Node], metas: List[Metadata], references: List[Int32],
                           start: Int32, end: Int32, backwards: Bool, acc: a,
                           visit: (a, Orbit64.Move.Move) -> a): Result[String, a] =
        let selected = sliceUnchecked(references, start, end);
        foldReferences(nodes, metas, selected, backwards, acc, visit)

    def foldPartitionParts(nodes: List[Node], metas: List[Metadata], sequence: Int32,
                           boundaries: List[Int32], start: Int32, end: Int32,
                           backwards: Bool, acc: a,
                           visit: (a, Orbit64.Move.Move) -> a): Result[String, a] =
        let groups = partitionRanges(boundaries);
        let selected = sliceUnchecked(groups, start, end);
        foldRanges(nodes, metas, sequence, selected, backwards, acc, visit)

    def foldRanges(nodes: List[Node], metas: List[Metadata], sequence: Int32,
                   ranges: List[(Int32, Int32)], backwards: Bool, acc: a,
                   visit: (a, Orbit64.Move.Move) -> a): Result[String, a] =
        let ordered = if (backwards) List.reverse(ranges) else ranges;
        foldRangeList(nodes, metas, sequence, ordered, backwards, acc, visit)

    def foldRangeList(nodes: List[Node], metas: List[Metadata], sequence: Int32,
                      ranges: List[(Int32, Int32)], backwards: Bool, acc: a,
                      visit: (a, Orbit64.Move.Move) -> a): Result[String, a] =
        match ranges {
            case Nil => Ok(acc)
            case (start, end) :: rest =>
                foldParts(nodes, metas, sequence, start, end, backwards, acc, visit)
                    |> Result.flatMap(next ->
                        foldRangeList(nodes, metas, sequence, rest, backwards, next, visit))
        }

    def partitionRanges(boundaries: List[Int32]): List[(Int32, Int32)] = match boundaries {
        case start :: end :: rest => (start, end) :: partitionRanges(end :: rest)
        case _ => Nil
    }

    def packedReferences(alphabet: List[Int32], symbols: List[Int32]): List[Int32] =
        packedReferenceLoop(alphabet, symbols, Nil) |> List.reverse

    def packedReferenceLoop(alphabet: List[Int32], symbols: List[Int32],
                            out: List[Int32]): List[Int32] = match symbols {
        case Nil => out
        case symbol :: rest => match listAt(symbol, alphabet) {
            case None => out
            case Some(reference) => packedReferenceLoop(alphabet, rest, reference :: out)
        }
    }

    def partTotal(reference: Int32, nodes: List[Node], metas: List[Metadata]):
            Result[String, Int32] =
        match nodeAt(reference, nodes) {
            case None => Err("internal error: validated part node is missing")
            case Some(_) => match metadataAt(reference, List.length(nodes), metas) {
                case Some(Metadata.Metadata(_, parts, true)) => Ok(List.length(parts))
                case _ => Err("internal error: validated node lost its stable boundaries")
            }
        }

    def nodeAt(reference: Int32, nodes: List[Node]): Option[Node] =
        listAt(reference, nodes)

    def inverseMove(move: Orbit64.Move.Move): Orbit64.Move.Move = match move {
        case Orbit64.Move.Move.LayerTurn(face, depth, amount) =>
            Orbit64.Move.Move.LayerTurn(face, depth, inverseAmount(amount))
    }

    def inverseAmount(amount: Orbit64.Move.Amount): Orbit64.Move.Amount = match amount {
        case Orbit64.Move.Amount.Clockwise => Orbit64.Move.Amount.CounterClockwise
        case Orbit64.Move.Amount.Half => Orbit64.Move.Amount.Half
        case Orbit64.Move.Amount.CounterClockwise => Orbit64.Move.Amount.Clockwise
    }

}
