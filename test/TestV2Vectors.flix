/// Parse the `key=v,v,...;key=...` state text of `TestV2VectorData`.
def parseCube(text: String): Orbit64.V2.State.Cube =
    let fields = String.splitOn({substr = ";"}, text)
        |> List.filterMap(f -> match String.splitOn({substr = "="}, f) {
            case key :: value :: Nil =>
                let ints = if (value == "") Nil
                    else String.splitOn({substr = ","}, value) |> List.filterMap(Int32.fromString);
                Some((key, List.toVector(ints)))
            case _ => None
        });
    let get = key -> fields |> List.find(match (k, _) -> k == key) |> Option.map(match (_, v) -> v)
        |> Option.getWithDefault(Vector.empty());
    let numbered = prefix -> fields |> List.filter(match (k, _) -> String.startsWith({prefix = prefix}, k)
            and String.length(k) > String.length(prefix)
            and not (k == "cp" or k == "ct" or k == "mp" or k == "mf" or k == "fr" or k == "fm"))
        |> List.map(match (_, v) -> v) |> List.toVector;
    { cornerPieces = get("cp"), cornerTwists = get("ct"), midgePieces = get("mp"), midgeFlips = get("mf"),
      wings = numbered("w"), centers = numbered("z"), rotations = get("fr"),
      frame = Vector.get(0, Vector.append(get("fm"), Vector#{0})) }

@Test
def referenceVectorsEncodeToTheirTokens(): Unit \ Assert =
    TestV2VectorData.rows() |> List.forEach(match (id, text, token) ->
        Assert.assertEq(expected = Ok(token), Orbit64.V2.Codec.encode(id, parseCube(text))))

@Test
def referenceVectorsDecodeToTheirStates(): Unit \ Assert =
    TestV2VectorData.rows() |> List.forEach(match (id, text, token) ->
        match Orbit64.V2.Codec.decode(token) {
            case Ok((e, cube)) =>
                Assert.assertEq(expected = id, e#id);
                Assert.assertEq(expected = show(parseCube(text)), show(cube))
            case Err(why) => Assert.fail("${id}: ${why}")
        })

/// Records have no `Eq`, so states are compared through their fields.
def show(c: Orbit64.V2.State.Cube): String =
    "${c#cornerPieces} ${c#cornerTwists} ${c#midgePieces} ${c#midgeFlips} ${c#wings} ${c#centers} ${c#rotations} ${c#frame}"
