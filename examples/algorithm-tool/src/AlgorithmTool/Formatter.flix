/// Canonical readable rendering of the native algorithm AST.
mod AlgorithmTool.Formatter {

    use AlgorithmTool.Ast.Program.{Program}
    use AlgorithmTool.Ast.Definition.{Definition}
    use AlgorithmTool.Ast.Expr.{Move, Reference, Concat, Repeat, Inverse}
    use AlgorithmTool.Ast.Expr.{Conjugate, Commutator, Slice}

    /// Format a parsed program in canonical one-definition-per-line form.
    pub def format(program: AlgorithmTool.Ast.Program): String = match program {
        case Program(definitions, export) =>
            String.concat(formatDefinitions(definitions), "export ${export}\n")
    }

    /// Format an expression without changing its AST structure.
    pub def expression(expr: AlgorithmTool.Ast.Expr): String = match expr {
        case Move(move) => moveText(move)
        case Reference(name) => name
        case Concat(children) => children |> List.map(formatExpr) |> List.join(" ")
        case Repeat(child, count) => "(${formatExpr(child)})${count}"
        case Inverse(child) => "(${formatExpr(child)})'"
        case Conjugate(left, right) =>
            "[${formatExpr(left)}: ${formatExpr(right)}]"
        case Commutator(left, right) => "[${formatExpr(left)}, ${formatExpr(right)}]"
        case Slice(name, start, end) => "${name}[${start}:${end}]"
    }

    def formatExpr(expr: AlgorithmTool.Ast.Expr): String = expression(expr)

    def formatDefinitions(definitions: List[AlgorithmTool.Ast.Definition]): String = match definitions {
        case Nil => ""
        case Definition(name, body) :: rest =>
            String.concat("def ${name} = ${formatExpr(body)}\n", formatDefinitions(rest))
    }

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
