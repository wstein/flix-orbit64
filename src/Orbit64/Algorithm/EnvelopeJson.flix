// SPDX-License-Identifier: Apache-2.0
/// Internal JSON shape adapter for the independent algorithm envelope.
mod Orbit64.Algorithm.EnvelopeJson {
    use Orbit64.Algorithm.Algorithm.Algorithm
    use Orbit64.Algorithm.Node
    use Orbit64.Move.Move.LayerTurn
    use Util.Json.Json
    use Util.Json.Json.{JArray, JObject, JString}

    /// Render the complete typed graph without changing node order or sharing.
    pub def write(n: Int32, graph: Orbit64.Algorithm.Algorithm): String =
        let Algorithm(nodes, root) = graph;
        JObject(List.toMap(
            ("format", JString("cube-algorithm-dag@1")) ::
            ("moveProfile", JString("cube-layer-turns@1")) ::
            ("n", integer(n)) ::
            ("nodes", array(List.map(nodeJson, nodes))) ::
            ("root", integer(root)) :: Nil)) |> Util.Json.toCompactString

    def integer(i: Int32): Json = Util.Json.ToJson.toJson(i)
    def array(items: List[Json]): Json = JArray(List.toVector(items))
    def integers(items: List[Int32]): Json = array(List.map(integer, items))

    def nodeJson(node: Node): Json = array(match node {
        case Node.Terminal(LayerTurn(face, depth, amount)) =>
            JString("terminal") :: JString(Orbit64.Move.notation(face)) ::
                integer(depth) :: integer(amountNumber(amount)) :: Nil
        case Node.Concat(refs) => JString("concat") :: integers(refs) :: Nil
        case Node.Repeat(child, count) =>
            JString("repeat") :: integer(child) :: JString("${count}") :: Nil
        case Node.Inverse(child) => JString("inverse") :: integer(child) :: Nil
        case Node.Block(refs) => JString("block") :: integers(refs) :: Nil
        case Node.PackedBlock(alphabet, symbols) =>
            JString("packedBlock") :: integers(alphabet) :: integers(symbols) :: Nil
        case Node.Partition(child, boundaries) =>
            JString("partition") :: integer(child) :: integers(boundaries) :: Nil
        case Node.SliceParts(child, start, end) =>
            JString("sliceParts") :: integer(child) :: integer(start) :: integer(end) :: Nil
    })

    def amountNumber(amount: Orbit64.Move.Amount): Int32 = match amount {
        case Orbit64.Move.Amount.Clockwise => 1
        case Orbit64.Move.Amount.Half => 2
        case Orbit64.Move.Amount.CounterClockwise => 3
    }

    /// Read only the specified envelope and exact node arities.
    pub def read(maxDigits: Int32, maxNodes: Int32, maxItems: Int32, value: Json):
            Result[String, (Int32, Orbit64.Algorithm.Algorithm)] = match value {
        case JObject(fields) => readObject(maxDigits, maxNodes, maxItems, fields)
        case _ => Err("expected an envelope object")
    }

    def readObject(maxDigits: Int32, maxNodes: Int32, maxItems: Int32,
                   fields: Map[String, Json]):
            Result[String, (Int32, Orbit64.Algorithm.Algorithm)] =
        versions(fields) |> Result.flatMap(_ ->
            let n = field("n", fields) |> Result.flatMap(readInt);
            let root = field("root", fields) |> Result.flatMap(readInt);
            let nodes = field("nodes", fields) |> Result.flatMap(readNodes(maxNodes))
                |> Result.flatMap(Result.traverse(nodeRead(maxDigits, maxItems)));
            Result.map3(n1 -> root1 -> nodes1 -> (n1, Algorithm(nodes1, root1)), n, root, nodes))

    def readNodes(maxNodes: Int32, value: Json): Result[String, List[Json]] = match value {
        case JArray(nodes) if Vector.length(nodes) > maxNodes => Err("node budget exceeded")
        case JArray(nodes) => Ok(Vector.toList(nodes))
        case _ => Err("expected a node array")
    }

    def versions(fields: Map[String, Json]): Result[String, Unit] =
        field("format", fields)
            |> Result.flatMap(expectString("cube-algorithm-dag@1"))
            |> Result.flatMap(_ -> field("moveProfile", fields))
            |> Result.flatMap(expectString("cube-layer-turns@1"))

    def field(key: String, fields: Map[String, Json]): Result[String, Json] =
        match Map.get(key, fields) {
            case None => Err("missing field ${key}")
            case Some(value) => Ok(value)
        }

    def expectString(expected: String, value: Json): Result[String, Unit] =
        if (value == JString(expected)) Ok(()) else Err("unknown format or move profile")

    def readInt(value: Json): Result[String, Int32] =
        Util.Json.FromJson.fromJson(value) |> Result.mapErr(_ -> "expected an Int32 integer")

    def readArray(value: Json): Result[String, List[Json]] = match value {
        case JArray(items) => Ok(Vector.toList(items))
        case _ => Err("expected an array")
    }

    def readInts(maxItems: Int32, value: Json): Result[String, List[Int32]] = match value {
        case JArray(items) if Vector.length(items) > maxItems =>
            Err("stored index-list budget exceeded")
        case _ => readArray(value) |> Result.flatMap(Result.traverse(readInt))
    }

    def nodeRead(maxDigits: Int32, maxItems: Int32, value: Json): Result[String, Node] =
        readArray(value) |> Result.flatMap(items -> match items {
            case JString("terminal") :: JString(face) :: depth :: amount :: Nil =>
                readTerminal(face, depth, amount)
            case JString("concat") :: refs :: Nil =>
                readInts(maxItems, refs) |> Result.map(Node.Concat)
            case JString("block") :: refs :: Nil =>
                readInts(maxItems, refs) |> Result.map(Node.Block)
            case JString("inverse") :: child :: Nil => readInt(child) |> Result.map(Node.Inverse)
            case JString("repeat") :: child :: JString(count) :: Nil =>
                readRepeat(maxDigits, child, count)
            case JString("packedBlock") :: alphabet :: symbols :: Nil =>
                Result.map2(a -> symbols1 -> Node.PackedBlock(a, symbols1),
                    readInts(maxItems, alphabet), readInts(maxItems, symbols))
            case JString("partition") :: child :: boundaries :: Nil =>
                Result.map2(c -> b -> Node.Partition(c, b),
                    readInt(child), readInts(maxItems, boundaries))
            case JString("sliceParts") :: child :: start :: end :: Nil =>
                Result.map3(c -> start1 -> end1 -> Node.SliceParts(c, start1, end1),
                    readInt(child), readInt(start), readInt(end))
            case _ => Err("unknown node or incorrect node arity")
        })

    def readTerminal(face: String, depth: Json, amount: Json): Result[String, Node] =
        Result.map3(f -> d -> q -> Node.Terminal(LayerTurn(f, d, q)),
            readFace(face), readInt(depth), readInt(amount) |> Result.flatMap(readAmount))

    def readRepeat(maxDigits: Int32, child: Json, count: String): Result[String, Node] =
        Result.map2(c -> k -> Node.Repeat(c, k), readInt(child), readCount(maxDigits, count))

    def readFace(face: String): Result[String, Orbit64.Move.Face] = match face {
        case "U" => Ok(Orbit64.Move.Face.U)
        case "R" => Ok(Orbit64.Move.Face.R)
        case "F" => Ok(Orbit64.Move.Face.F)
        case "D" => Ok(Orbit64.Move.Face.D)
        case "L" => Ok(Orbit64.Move.Face.L)
        case "B" => Ok(Orbit64.Move.Face.B)
        case _ => Err("unknown face")
    }

    def readAmount(amount: Int32): Result[String, Orbit64.Move.Amount] = match amount {
        case 1 => Ok(Orbit64.Move.Amount.Clockwise)
        case 2 => Ok(Orbit64.Move.Amount.Half)
        case 3 => Ok(Orbit64.Move.Amount.CounterClockwise)
        case _ => Err("turn amount must be 1, 2, or 3")
    }

    def readCount(maxDigits: Int32, count: String): Result[String, BigInt] =
        if (String.length(count) > maxDigits) Err("repeat count digit budget exceeded")
        else if (String.isEmpty(count) or String.startsWith(prefix = "0", count)
            or not List.forAll(c -> c >= '0' and c <= '9', String.toList(count)))
            Err("repeat count must be a positive canonical decimal string")
        else Ok(String.toList(count) |> List.foldLeft((acc, c) ->
            acc * 10ii + Int32.toBigInt(Char.getNumericValue(c) |> Option.getWithDefault(0)), 0ii))
}
