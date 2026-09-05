//
// The exact state-token-to-spaced-facelet vectors published in FORMAT.md.
//
// These make the documented face order executable. The fields are ordered
// `U R F D L B`, and each field holds n * n face letters.
//

def faceText(value: Int32): String = match value {
    case 0 => "U"
    case 1 => "R"
    case 2 => "F"
    case 3 => "D"
    case 4 => "L"
    case _ => "B"
}

def faceIndex(value: Char): Int32 = match value {
    case 'U' => 0
    case 'R' => 1
    case 'F' => 2
    case 'D' => 3
    case 'L' => 4
    case _   => 5
}

def faceletValues(text: String): Vector[Int32] =
    text |> String.toList |> List.filter(c -> c != ' ') |> List.map(faceIndex) |> List.toVector

def spacedFacelets(values: Vector[Int32], n: Int32): String =
    spacedFaceletsLoop(Vector.toList(values) |> List.map(faceText), n * n, n * n, "")

def spacedFaceletsLoop(values: List[String], fieldWidth: Int32,
                       remaining: Int32, out: String): String =
    match values {
        case Nil => out
        case value :: rest =>
            let separator = if (remaining == fieldWidth) if (out == "") "" else " " else "";
            let nextRemaining = if (remaining == 1) fieldWidth else remaining - 1;
            spacedFaceletsLoop(rest, fieldWidth, nextRemaining,
                String.concat(out, String.concat(separator, value)))
    }

///
/// Every published state token renders to its published spaced facelets.
///
@Test
def documentedStateFaceletVectors(): Unit \ Assert =
    let vectors = List#{
        (2, "EJ6Rr", "LFLD BLRD BLBU RFRR UUDU DFFB"),
        (3, "AAAAAAAAB-go",
            "UUUUURUUU RURBRLRDR FFFLFRFFF DDDLDRDDD LLLFLFLDL BBBBBRBBB"),
        (4, "BJSsuyGPOiU06kIz-eqibqTP1th",
            "DLLDLLDLBFLFLRBR DRDLFBRLUURUUDDU FUUFLDFDRBUFURRL " +
                "LBDFFFDFFFBRFBFR RDDDBLUUBURBRULB BFBBUDRURBLLBRDU"),
        (5, "AQsjv5K4-XPjKJZMNvMLvYKqohuv1x7JGUoNROgDJ2w",
            "DBRFRFUBLDDBUFFURBDDFUUDL BLDBFULULLLRRUURRDFDRLLFD " +
                "LFLRURFURRFFFFBUBLUFRLUBU BDBRFDFRUULRDFDULLDDRBRFL " +
                "LDBFUUFDUFRLLURBRDDBBRFRD DLDUFBBBBLFRBDUBDLBLBLBRU")
    };
    vectors |> List.forEach(match (n, token, reference) ->
        let actual = Orbit64.State.decode(n, token)
            |> Result.flatMap(state -> Orbit64.Net.toFacelets(n, Orbit64.State.orbits(state)))
            |> Result.map(facelets -> spacedFacelets(facelets, n))
            |> Result.getWithDefault("invalid");
        Assert.assertEq(expected = reference, actual))

/// The published facelets encode back to their documented framed-state token.
@Test
def documentedFaceletVectorsEncodeToFramedStates(): Unit \ Assert =
    let vectors = List#{
        (2, "EJ6Rr", "LFLD BLRD BLBU RFRR UUDU DFFB"),
        (3, "AAAAAAAAB-go", "UUUUURUUU RURBRLRDR FFFLFRFFF DDDLDRDDD LLLFLFLDL BBBBBRBBB"),
        (4, "BJSsuyGPOiU06kIz-eqibqTP1th",
            "DLLDLLDLBFLFLRBR DRDLFBRLUURUUDDU FUUFLDFDRBUFURRL " +
                "LBDFFFDFFFBRFBFR RDDDBLUUBURBRULB BFBBUDRURBLLBRDU"),
        (5, "AQsjv5K4-XPjKJZMNvMLvYKqohuv1x7JGUoNROgDJ2w",
            "DBRFRFUBLDDBUFFURBDDFUUDL BLDBFULULLLRRUURRDFDRLLFD " +
                "LFLRURFURRFFFFBUBLUFRLUBU BDBRFDFRUULRDFDULLDDRBRFL " +
                "LDBFUUFDUFRLLURBRDDBBRFRD DLDUFBBBBLFRBDUBDLBLBLBRU")
    };
    vectors |> List.forEach(match (n, token, facelets) ->
        Assert.assertEq(expected = Ok(token),
            Orbit64.Net.fromFacelets(n, faceletValues(facelets))
                |> Result.map(Orbit64.State.canonical)
                |> Result.flatMap(state -> Orbit64.State.encode(n, state))))
