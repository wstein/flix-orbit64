/// Render a decoded Orbit64 algorithm DAG as canonical native source.
mod AlgorithmTool.Reconstruction {

    /// Reconstruct readable, earlier-reference-only source with generated names.
    pub def source(algorithm: Orbit64.Algorithm.Algorithm): String = match algorithm {
        case Orbit64.Algorithm.Algorithm.Algorithm(nodes, root) =>
            String.concat(definitions(nodes, 0), "export ${nameOf(root)}\n")
    }

    def definitions(nodes: List[Orbit64.Algorithm.Node], index: Int32): String = match nodes {
        case Nil => ""
        case node :: rest => String.concat("def ${nameOf(index)} = ${expression(node)}\n",
            definitions(rest, index + 1))
    }

    def expression(node: Orbit64.Algorithm.Node): String = match node {
        case Orbit64.Algorithm.Node.Terminal(move) => moveText(move)
        case Orbit64.Algorithm.Node.Concat(children) => references(children)
        case Orbit64.Algorithm.Node.Repeat(child, count) => "(${nameOf(child)})${count}"
        case Orbit64.Algorithm.Node.Inverse(child) => "(${nameOf(child)})'"
        case Orbit64.Algorithm.Node.Block(children) => references(children)
        case Orbit64.Algorithm.Node.PackedBlock(alphabet, symbols) =>
            packedReferences(alphabet, symbols)
        case Orbit64.Algorithm.Node.Partition(sequence, _) => nameOf(sequence)
        case Orbit64.Algorithm.Node.SliceParts(sequence, start, end) =>
            "${nameOf(sequence)}[${start}:${end}]"
    }

    def references(values: List[Int32]): String = values |> List.map(nameOf) |> List.join(" ")

    def packedReferences(alphabet: List[Int32], symbols: List[Int32]): String = match symbols {
        case Nil => ""
        case symbol :: rest => String.concat(referenceAt(alphabet, symbol),
            packedTail(alphabet, rest))
    }

    def packedTail(alphabet: List[Int32], symbols: List[Int32]): String = match symbols {
        case Nil => ""
        case symbol :: rest => String.concat(" ${referenceAt(alphabet, symbol)}",
            packedTail(alphabet, rest))
    }

    def referenceAt(alphabet: List[Int32], symbol: Int32): String =
        alphabetAt(alphabet, symbol, 0) |> nameOf

    def alphabetAt(alphabet: List[Int32], wanted: Int32, index: Int32): Int32 = match alphabet {
        case value :: _ if wanted == index => value
        case _ :: rest => alphabetAt(rest, wanted, index + 1)
        case Nil => 0
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
