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
            let slicedNames = collectSlicedNames(definitions);
            lowerDefinitions(definitions, slicedNames, Nil, Nil) |> Result.flatMap(
                match (nodes, bindings) -> lookup(export, bindings) |> Result.map(root ->
                    Algorithm(nodes, root)))
    }

    /// Names that some `Slice` in the program selects terms from, and therefore
    /// need a stable block even when their own definition would not otherwise.
    def collectSlicedNames(definitions: List[AlgorithmTool.Ast.Definition]): Set[String] =
        definitions |> List.foldLeft((acc, definition) -> match definition {
            case Definition(_, body) => Set.union(acc, slicedNamesIn(body))
        }, Set.empty())

    def slicedNamesIn(expr: AlgorithmTool.Ast.Expr): Set[String] = match expr {
        case Move(_) => Set.empty()
        case Reference(_) => Set.empty()
        case Concat(children) => children |> List.foldLeft((acc, child) ->
            Set.union(acc, slicedNamesIn(child)), Set.empty())
        case Repeat(child, _) => slicedNamesIn(child)
        case Inverse(child) => slicedNamesIn(child)
        case Conjugate(left, right) => Set.union(slicedNamesIn(left), slicedNamesIn(right))
        case Commutator(left, right) => Set.union(slicedNamesIn(left), slicedNamesIn(right))
        case Slice(name, _, _) => Set.singleton(name)
    }

    def lowerDefinitions(definitions: List[AlgorithmTool.Ast.Definition],
                         slicedNames: Set[String],
                         bindings: List[(String, Int32)],
                         reversedNodes: List[Orbit64.Algorithm.Node]):
            Result[String, (List[Orbit64.Algorithm.Node], List[(String, Int32)])] =
        match definitions {
            case Nil => Ok((List.reverse(reversedNodes), bindings))
            case Definition(name, body) :: rest =>
                if (hasBinding(name, bindings)) Err("definition '${name}' is repeated")
                else lowerDefinition(body, Set.memberOf(name, slicedNames), bindings,
                        reversedNodes) |> Result.flatMap(
                    match (root, afterBody) ->
                        lowerDefinitions(rest, slicedNames, (name, root) :: bindings, afterBody))
        }

    /// A definition only needs a stable block when a later `Slice` selects its
    /// terms; otherwise its own node (or that of its underlying expression) is
    /// the binding, with no extra indirection.
    def lowerDefinition(body: AlgorithmTool.Ast.Expr, needsStableBlock: Bool,
                        bindings: List[(String, Int32)],
                        reversedNodes: List[Orbit64.Algorithm.Node]):
            Result[String, (Int32, List[Orbit64.Algorithm.Node])] =
        match body {
            case Concat(children) if needsStableBlock =>
                lowerExpressions(children, bindings, reversedNodes, Nil) |> Result.map(
                    match (parts, afterChildren) -> appendNode(
                        Orbit64.Algorithm.Node.Block(parts), afterChildren))
            case _ if needsStableBlock =>
                lowerExpression(body, bindings, reversedNodes) |> Result.map(
                    match (child, afterChild) -> appendNode(
                        Orbit64.Algorithm.Node.Block(child :: Nil), afterChild))
            case _ => lowerExpression(body, bindings, reversedNodes)
        }

    def lowerExpression(expr: AlgorithmTool.Ast.Expr, bindings: List[(String, Int32)],
                        reversedNodes: List[Orbit64.Algorithm.Node]):
            Result[String, (Int32, List[Orbit64.Algorithm.Node])] = match expr {
        case Move(move) => Ok(internNode(Orbit64.Algorithm.Node.Terminal(move), reversedNodes))
        case Reference(name) =>
            lookup(name, bindings) |> Result.map(reference -> (reference, reversedNodes))
        case Concat(children) =>
            lowerExpressions(children, bindings, reversedNodes, Nil) |> Result.map(
                match (references, afterChildren) -> internNode(
                    Orbit64.Algorithm.Node.Concat(references), afterChildren))
        case Repeat(child, count) =>
            lowerExpression(child, bindings, reversedNodes) |> Result.map(
                match (reference, afterChild) -> internNode(
                    Orbit64.Algorithm.Node.Repeat(reference, count), afterChild))
        case Inverse(child) =>
            lowerExpression(child, bindings, reversedNodes) |> Result.map(
                match (reference, afterChild) -> internNode(
                    Orbit64.Algorithm.Node.Inverse(reference), afterChild))
        case Conjugate(left, right) => lowerConjugate(left, right, bindings, reversedNodes)
        case Commutator(left, right) => lowerCommutator(left, right, bindings, reversedNodes)
        case Slice(name, start, end) =>
            lookup(name, bindings) |> Result.map(reference ->
                internNode(Orbit64.Algorithm.Node.SliceParts(reference, start, end), reversedNodes))
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
                    let (inverseRef, afterInverse) = internNode(
                        Orbit64.Algorithm.Node.Inverse(leftRef), afterRight);
                    internNode(Orbit64.Algorithm.Node.Concat(
                        leftRef :: rightRef :: inverseRef :: Nil), afterInverse)))

    def lowerCommutator(left: AlgorithmTool.Ast.Expr, right: AlgorithmTool.Ast.Expr,
                        bindings: List[(String, Int32)],
                        reversedNodes: List[Orbit64.Algorithm.Node]):
            Result[String, (Int32, List[Orbit64.Algorithm.Node])] =
        lowerExpression(left, bindings, reversedNodes) |> Result.flatMap(
            match (leftRef, afterLeft) -> lowerExpression(right, bindings, afterLeft)
                |> Result.map(match (rightRef, afterRight) ->
                    let (leftInverse, afterLeftInverse) = internNode(
                        Orbit64.Algorithm.Node.Inverse(leftRef), afterRight);
                    let (rightInverse, afterRightInverse) = internNode(
                        Orbit64.Algorithm.Node.Inverse(rightRef), afterLeftInverse);
                    internNode(Orbit64.Algorithm.Node.Concat(
                        leftRef :: rightRef :: leftInverse :: rightInverse :: Nil),
                        afterRightInverse)))

    def appendNode(node: Orbit64.Algorithm.Node,
                   reversedNodes: List[Orbit64.Algorithm.Node]):
            (Int32, List[Orbit64.Algorithm.Node]) =
        (List.length(reversedNodes), node :: reversedNodes)

    /// Reuse an earlier structurally identical node instead of appending a
    /// duplicate. A source term as common as a bare `U'` recurs constantly in
    /// real algorithms, and `Node` already derives `Eq`, so every node kind
    /// benefits from the same structural check, not just terminals.
    def internNode(node: Orbit64.Algorithm.Node,
                   reversedNodes: List[Orbit64.Algorithm.Node]):
            (Int32, List[Orbit64.Algorithm.Node]) =
        match findNode(node, reversedNodes, List.length(reversedNodes) - 1) {
            case Some(index) => (index, reversedNodes)
            case None => appendNode(node, reversedNodes)
        }

    def findNode(node: Orbit64.Algorithm.Node, nodes: List[Orbit64.Algorithm.Node],
                index: Int32): Option[Int32] = match nodes {
        case Nil => None
        case existing :: rest =>
            if (existing == node) Some(index) else findNode(node, rest, index - 1)
    }

    def lookup(name: String, bindings: List[(String, Int32)]): Result[String, Int32] =
        match bindings {
            case Nil => Err("definition '${name}' is unknown or declared too late")
            case (boundName, reference) :: rest =>
                if (name == boundName) Ok(reference) else lookup(name, rest)
        }

    def hasBinding(name: String, bindings: List[(String, Int32)]): Bool =
        lookup(name, bindings) |> Result.isOk

}
