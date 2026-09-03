/// Render a decoded Orbit64 algorithm DAG as canonical native source.
mod AlgorithmTool.Reconstruction {

    enum RenderContext {
        case RenderContext(List[Orbit64.Algorithm.Node], Int32, List[Int32], Set[Int32])
    }

    /// Reconstruct readable, earlier-reference-only source with generated names.
    pub def source(algorithm: Orbit64.Algorithm.Algorithm): String = match algorithm {
        case Orbit64.Algorithm.Algorithm.Algorithm(nodes, root) =>
            let refCounts = referenceCounts(nodes);
            let anchors = anchoredReferences(nodes);
            let context = RenderContext.RenderContext(nodes, root, refCounts, anchors);
            String.concat(definitions(context, nodes, 0),
                "export ${nameOf(root)}\n")
    }

    /// A node is worth naming only when doing so pays for itself: either it is
    /// referenced from more than one place (so the name avoids duplicating its
    /// text), or its text is cheap regardless of reuse (a bare terminal, or an
    /// inverse of one). Anything else is inlined at its one use site instead.
    def definitions(context: RenderContext, nodes: List[Orbit64.Algorithm.Node], index: Int32):
            String = match (context, nodes) {
        case (_, Nil) => ""
        case (RenderContext.RenderContext(all, root, refCounts, anchors), node :: rest) =>
            if (index != root and isInlinable(index, node, all, refCounts, anchors))
                definitions(context, rest, index + 1)
            else String.concat("def ${nameOf(index)} = ${expression(node, all, refCounts)}\n",
                definitions(context, rest, index + 1))
    }

    def isInlinable(index: Int32, node: Orbit64.Algorithm.Node,
                    all: List[Orbit64.Algorithm.Node], refCounts: List[Int32],
                    anchors: Set[Int32]): Bool =
        not Set.memberOf(index, anchors)
            and (isAlwaysInlinable(node, all) or countAt(index, refCounts) == 1)

    /// Cheap regardless of how often it recurs: a bare terminal, or an inverse
    /// chain that bottoms out in one.
    def isAlwaysInlinable(node: Orbit64.Algorithm.Node, all: List[Orbit64.Algorithm.Node]): Bool =
        match node {
            case Orbit64.Algorithm.Node.Terminal(_) => true
            case Orbit64.Algorithm.Node.Inverse(child) => match nodeAt(child, all) {
                case Some(childNode) => isAlwaysInlinable(childNode, all)
                case None => false
            }
            case _ => false
        }

    def expression(node: Orbit64.Algorithm.Node, all: List[Orbit64.Algorithm.Node],
                   refCounts: List[Int32]): String = match node {
        case Orbit64.Algorithm.Node.Terminal(move) => moveText(move)
        case Orbit64.Algorithm.Node.Concat(children) => references(children, all, refCounts)
        case Orbit64.Algorithm.Node.Repeat(child, count) =>
            "(${renderChild(child, all, refCounts)})${count}"
        case Orbit64.Algorithm.Node.Inverse(child) => invertedText(child, all, refCounts)
        case Orbit64.Algorithm.Node.Block(children) => references(children, all, refCounts)
        case Orbit64.Algorithm.Node.PackedBlock(alphabet, symbols) =>
            packedReferences(alphabet, symbols, all, refCounts)
        case Orbit64.Algorithm.Node.Partition(sequence, _) => nameOf(sequence)
        case Orbit64.Algorithm.Node.SliceParts(sequence, start, end) =>
            "${nameOf(sequence)}[${start}:${end}]"
    }

    def references(values: List[Int32], all: List[Orbit64.Algorithm.Node],
                   refCounts: List[Int32]): String =
        values |> List.map(index -> renderChild(index, all, refCounts)) |> List.join(" ")

    /// The text for a reference: inlined in place when the target is never
    /// named (see `isInlinable`), otherwise just its name.
    def renderChild(index: Int32, all: List[Orbit64.Algorithm.Node],
                    refCounts: List[Int32]): String =
        match nodeAt(index, all) {
            case Some(node) if isInlinable(index, node, all, refCounts, Set.empty()) =>
                expression(node, all, refCounts)
            case _ => nameOf(index)
        }

    /// `U'` needs no parens; anything else inlined or named still does, so a
    /// nested inverse (however unlikely) never leaves a dangling reference to
    /// a node `definitions` decided not to name.
    def invertedText(child: Int32, all: List[Orbit64.Algorithm.Node],
                     refCounts: List[Int32]): String =
        match nodeAt(child, all) {
            case Some(Orbit64.Algorithm.Node.Terminal(move)) => "${moveText(move)}'"
            case Some(node) if isInlinable(child, node, all, refCounts, Set.empty()) =>
                "(${expression(node, all, refCounts)})'"
            case _ => "(${nameOf(child)})'"
        }

    def packedReferences(alphabet: List[Int32], symbols: List[Int32],
                         all: List[Orbit64.Algorithm.Node], refCounts: List[Int32]): String =
        match symbols {
            case Nil => ""
            case symbol :: rest => String.concat(referenceAt(alphabet, symbol, all, refCounts),
                packedTail(alphabet, rest, all, refCounts))
        }

    def packedTail(alphabet: List[Int32], symbols: List[Int32],
                   all: List[Orbit64.Algorithm.Node], refCounts: List[Int32]): String =
        match symbols {
            case Nil => ""
            case symbol :: rest =>
                String.concat(" ${referenceAt(alphabet, symbol, all, refCounts)}",
                    packedTail(alphabet, rest, all, refCounts))
        }

    def referenceAt(alphabet: List[Int32], symbol: Int32, all: List[Orbit64.Algorithm.Node],
                    refCounts: List[Int32]): String =
        renderChild(alphabetAt(alphabet, symbol, 0), all, refCounts)

    def alphabetAt(alphabet: List[Int32], wanted: Int32, index: Int32): Int32 = match alphabet {
        case value :: _ if wanted == index => value
        case _ :: rest => alphabetAt(rest, wanted, index + 1)
        case Nil => 0
    }

    /// How many times each node index is referenced by another node's
    /// children, independent of naming choices: a static property of the DAG.
    def referenceCounts(nodes: List[Orbit64.Algorithm.Node]): List[Int32] =
        let zeros = nodes |> List.map(_ -> 0);
        nodes |> List.foldLeft((counts, node) -> tallyNode(node, counts), zeros)

    /// Native slices and partitions address their source by definition name.
    /// Their source must therefore remain named even if it has one ordinary
    /// reference and would otherwise be inlined.
    def anchoredReferences(nodes: List[Orbit64.Algorithm.Node]): Set[Int32] =
        nodes |> List.foldLeft((anchors, node) -> match node {
            case Orbit64.Algorithm.Node.Partition(sequence, _) => Set.insert(sequence, anchors)
            case Orbit64.Algorithm.Node.SliceParts(sequence, _, _) => Set.insert(sequence, anchors)
            case _ => anchors
        }, Set.empty())

    def tallyNode(node: Orbit64.Algorithm.Node, counts: List[Int32]): List[Int32] = match node {
        case Orbit64.Algorithm.Node.Terminal(_) => counts
        case Orbit64.Algorithm.Node.Concat(children) => tallyRefs(children, counts)
        case Orbit64.Algorithm.Node.Repeat(child, _) => incrementAt(child, counts)
        case Orbit64.Algorithm.Node.Inverse(child) => incrementAt(child, counts)
        case Orbit64.Algorithm.Node.Block(children) => tallyRefs(children, counts)
        case Orbit64.Algorithm.Node.PackedBlock(alphabet, symbols) =>
            symbols |> List.foldLeft((acc, symbol) ->
                incrementAt(alphabetAt(alphabet, symbol, 0), acc), counts)
        case Orbit64.Algorithm.Node.Partition(sequence, _) => incrementAt(sequence, counts)
        case Orbit64.Algorithm.Node.SliceParts(sequence, _, _) => incrementAt(sequence, counts)
    }

    def tallyRefs(refs: List[Int32], counts: List[Int32]): List[Int32] =
        refs |> List.foldLeft((acc, r) -> incrementAt(r, acc), counts)

    def incrementAt(index: Int32, counts: List[Int32]): List[Int32] = match counts {
        case Nil => Nil
        case c :: rest if index == 0 => (c + 1) :: rest
        case c :: rest if index > 0 => c :: incrementAt(index - 1, rest)
        case _ => counts
    }

    def countAt(index: Int32, counts: List[Int32]): Int32 = match counts {
        case Nil => 0
        case c :: _ if index == 0 => c
        case _ :: rest if index > 0 => countAt(index - 1, rest)
        case _ => 0
    }

    def nodeAt(index: Int32, nodes: List[Orbit64.Algorithm.Node]): Option[Orbit64.Algorithm.Node] =
        match nodes {
            case Nil => None
            case node :: _ if index == 0 => Some(node)
            case _ :: rest if index > 0 => nodeAt(index - 1, rest)
            case _ => None
        }

    def nameOf(index: Int32): String = "n${index}"

    def moveText(move: Orbit64.Move.Move): String = match move {
        case Orbit64.Move.Move.LayerTurn(face, depth, amount) =>
            String.concat(depthText(depth), String.concat(faceText(face), amountText(amount)))
    }

    def depthText(depth: Int32): String = if (depth == 0) "" else "${depth + 1}"

    def faceText(face: Orbit64.Move.Face): String = match face {
        case Orbit64.Move.Face.U => "U"
        case Orbit64.Move.Face.R => "R"
        case Orbit64.Move.Face.F => "F"
        case Orbit64.Move.Face.D => "D"
        case Orbit64.Move.Face.L => "L"
        case Orbit64.Move.Face.B => "B"
    }

    def amountText(amount: Orbit64.Move.Amount): String = match amount {
        case Orbit64.Move.Amount.Clockwise => ""
        case Orbit64.Move.Amount.Half => "2"
        case Orbit64.Move.Amount.CounterClockwise => "'"
    }

}
