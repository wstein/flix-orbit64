/// Lower native source expressions into the notation-independent Orbit64 DAG.
mod AlgorithmTool.Lowering {

    use AlgorithmTool.Ast.Program.{Program}
    use AlgorithmTool.Ast.Definition.{Definition}
    use AlgorithmTool.Ast.Expr.{Move, Reference, Concat, Repeat, Inverse}
    use AlgorithmTool.Ast.Expr.{Conjugate, Commutator, Slice}
    use Orbit64.Algorithm.Algorithm.{Algorithm}

    /// Lower an earlier-reference-only source program without expanding moves.
    pub def lower(program: AlgorithmTool.Ast.Program):
            Result[String, Orbit64.Algorithm.Algorithm] = match program {
        case Program(definitions, export) =>
            lowerDefinitions(definitions, Nil, Nil) |> Result.flatMap(
                match (nodes, bindings) -> lookup(export, bindings) |> Result.map(root ->
                    Algorithm(nodes, root)))
    }

    def lowerDefinitions(definitions: List[AlgorithmTool.Ast.Definition],
                         bindings: List[(String, Int32)],
                         reversedNodes: List[Orbit64.Algorithm.Node]):
            Result[String, (List[Orbit64.Algorithm.Node], List[(String, Int32)])] =
        match definitions {
            case Nil => Ok((List.reverse(reversedNodes), bindings))
            case Definition(name, body) :: rest =>
                if (hasBinding(name, bindings)) Err("definition '${name}' is repeated")
                else lowerDefinition(body, bindings, reversedNodes) |> Result.flatMap(
                    match (root, afterBody) ->
                        lowerDefinitions(rest, (name, root) :: bindings, afterBody))
        }

    /// Every definition is a stable block, so source slices select its terms.
    def lowerDefinition(body: AlgorithmTool.Ast.Expr, bindings: List[(String, Int32)],
                        reversedNodes: List[Orbit64.Algorithm.Node]):
            Result[String, (Int32, List[Orbit64.Algorithm.Node])] =
        match body {
            case Concat(children) =>
                lowerExpressions(children, bindings, reversedNodes, Nil) |> Result.map(
                    match (parts, afterChildren) -> appendNode(
                        Orbit64.Algorithm.Node.Block(parts), afterChildren))
            case _ => lowerExpression(body, bindings, reversedNodes) |> Result.map(
                match (child, afterChild) -> appendNode(
                    Orbit64.Algorithm.Node.Block(child :: Nil), afterChild))
        }

    def lowerExpression(expr: AlgorithmTool.Ast.Expr, bindings: List[(String, Int32)],
                        reversedNodes: List[Orbit64.Algorithm.Node]):
            Result[String, (Int32, List[Orbit64.Algorithm.Node])] = match expr {
        case Move(move) => Ok(appendNode(Orbit64.Algorithm.Node.Terminal(move), reversedNodes))
        case Reference(name) =>
            lookup(name, bindings) |> Result.map(reference -> (reference, reversedNodes))
        case Concat(children) =>
            lowerExpressions(children, bindings, reversedNodes, Nil) |> Result.map(
                match (references, afterChildren) -> appendNode(
                    Orbit64.Algorithm.Node.Concat(references), afterChildren))
        case Repeat(child, count) =>
            lowerExpression(child, bindings, reversedNodes) |> Result.map(
                match (reference, afterChild) -> appendNode(
                    Orbit64.Algorithm.Node.Repeat(reference, count), afterChild))
        case Inverse(child) =>
            lowerExpression(child, bindings, reversedNodes) |> Result.map(
                match (reference, afterChild) -> appendNode(
                    Orbit64.Algorithm.Node.Inverse(reference), afterChild))
        case Conjugate(left, right) => lowerConjugate(left, right, bindings, reversedNodes)
        case Commutator(left, right) => lowerCommutator(left, right, bindings, reversedNodes)
        case Slice(name, start, end) =>
            lookup(name, bindings) |> Result.map(reference ->
                appendNode(Orbit64.Algorithm.Node.SliceParts(reference, start, end), reversedNodes))
    }

    def lowerExpressions(expressions: List[AlgorithmTool.Ast.Expr],
                         bindings: List[(String, Int32)],
                         reversedNodes: List[Orbit64.Algorithm.Node],
                         reversedReferences: List[Int32]):
            Result[String, (List[Int32], List[Orbit64.Algorithm.Node])] = match expressions {
        case Nil => Ok((List.reverse(reversedReferences), reversedNodes))
        case expression :: rest =>
            lowerExpression(expression, bindings, reversedNodes) |> Result.flatMap(
                match (reference, afterExpression) ->
                    lowerExpressions(rest, bindings, afterExpression,
                        reference :: reversedReferences))
    }

    def lowerConjugate(left: AlgorithmTool.Ast.Expr, right: AlgorithmTool.Ast.Expr,
                       bindings: List[(String, Int32)],
                       reversedNodes: List[Orbit64.Algorithm.Node]):
            Result[String, (Int32, List[Orbit64.Algorithm.Node])] =
        lowerExpression(left, bindings, reversedNodes) |> Result.flatMap(
            match (leftRef, afterLeft) -> lowerExpression(right, bindings, afterLeft)
                |> Result.map(match (rightRef, afterRight) ->
                    let (inverseRef, afterInverse) = appendNode(
                        Orbit64.Algorithm.Node.Inverse(leftRef), afterRight);
                    appendNode(Orbit64.Algorithm.Node.Concat(
                        leftRef :: rightRef :: inverseRef :: Nil), afterInverse)))

    def lowerCommutator(left: AlgorithmTool.Ast.Expr, right: AlgorithmTool.Ast.Expr,
                        bindings: List[(String, Int32)],
                        reversedNodes: List[Orbit64.Algorithm.Node]):
            Result[String, (Int32, List[Orbit64.Algorithm.Node])] =
        lowerExpression(left, bindings, reversedNodes) |> Result.flatMap(
            match (leftRef, afterLeft) -> lowerExpression(right, bindings, afterLeft)
                |> Result.map(match (rightRef, afterRight) ->
                    let (leftInverse, afterLeftInverse) = appendNode(
                        Orbit64.Algorithm.Node.Inverse(leftRef), afterRight);
                    let (rightInverse, afterRightInverse) = appendNode(
                        Orbit64.Algorithm.Node.Inverse(rightRef), afterLeftInverse);
                    appendNode(Orbit64.Algorithm.Node.Concat(
                        leftRef :: rightRef :: leftInverse :: rightInverse :: Nil),
                        afterRightInverse)))

    def appendNode(node: Orbit64.Algorithm.Node,
                   reversedNodes: List[Orbit64.Algorithm.Node]):
            (Int32, List[Orbit64.Algorithm.Node]) =
        (List.length(reversedNodes), node :: reversedNodes)

    def lookup(name: String, bindings: List[(String, Int32)]): Result[String, Int32] =
        match bindings {
            case Nil => Err("definition '${name}' is unknown or declared too late")
            case (boundName, reference) :: rest =>
                if (name == boundName) Ok(reference) else lookup(name, rest)
        }

    def hasBinding(name: String, bindings: List[(String, Int32)]): Bool =
        lookup(name, bindings) |> Result.isOk

}
