//
// `Orbit64.Net.fromFacelets` against `Orbit64.Net.toFacelets`.
//
// The two are meant to be exact inverses, so the property is stated in both
// directions and over states that are actually mixed up rather than solved.
// The tokens below are the conformance vectors from `test/TestVectors.flix`,
// which is where they are pinned; decoding them here gives real scrambles at
// every size this module has a convention for, without a second copy of the
// orbit arrays going out of date next to the first.
//

def roundTrippable(): List[(Int32, String)] = List#{
    (2, "AAAAA"),
    (2, "EJ6Rr"),
    (2, "DJ5Lt"),
    (3, "AAAAAAAAAAAA"),
    (3, "AAAAAAAAAAf_"),
    (3, "ABU68xS1q8iQ"),
    (3, "AWMmIry_APKe"),
    (3, "AUi1GvzQin1y"),
    (4, "AAAAAAAAAAAAAAAAAAAAAAAAAAA"),
    (4, "BJSsuyGPOiU06kIz-eqibqTP1th"),
    (4, "BAy4TWgX4vSZOHnM2NdN63BRWKG"),
    (5, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"),
    (5, "BZC-qGPah6s_QRSpZqYwHRBzEXMajtc7pIOYt8AIaS"),
    (5, "CS4VwsPPKZmHYvHO6XpLm43iQChcG5dsI3rgJeX8ai")
}

///
/// Drawing a state and reading it back gives the state again.
///
/// This is the direction that matters to an adapter: whatever it renders from
/// a token, it can hand back and get the same orbits, so a token survives a
/// trip through a foreign cube engine unchanged.
///
@Test
def faceletsReadBackAsTheStateTheyWereDrawnFrom(): Unit \ Assert =
    roundTrippable() |> List.forEach(match (n, token) ->
        match Orbit64.decode(n, token) {
            case Err(e) => Assert.assertTrueWithMsg(false, "${token} did not decode: ${e}")
            case Ok(orbits) =>
                Assert.assertEq(
                    expected = Ok(orbits),
                    Orbit64.Net.toFacelets(n, orbits)
                        |> Result.flatMap(fs -> Orbit64.Net.fromFacelets(n, fs)))
        })

///
/// And reading a state then drawing it gives the stickers again.
///
/// Stated separately because it is a different claim: the first says no state
/// is lost on the way out, this says no sticker is invented on the way back.
/// A reader that quietly ignored an orbit would still pass the first.
///
@Test
def faceletsSurviveBeingReadAndDrawnAgain(): Unit \ Assert =
    roundTrippable() |> List.forEach(match (n, token) ->
        match Orbit64.decode(n, token)
                |> Result.flatMap(orbits -> Orbit64.Net.toFacelets(n, orbits)) {
            case Err(e) => Assert.assertTrueWithMsg(false, "${token} gave no facelets: ${e}")
            case Ok(fs) =>
                Assert.assertEq(
                    expected = Ok(fs),
                    Orbit64.Net.fromFacelets(n, fs)
                        |> Result.flatMap(orbits -> Orbit64.Net.toFacelets(n, orbits)))
        })

///
/// The solved cube reads back solved at every size with a convention.
///
@Test
def theSolvedCubeReadsBackSolved(): Unit \ Assert =
    List#{2, 3, 4, 5} |> List.forEach(n ->
        Assert.assertEq(
            expected = Ok(Orbit64.solved(n)),
            Orbit64.Net.toFacelets(n, Orbit64.solved(n))
                |> Result.flatMap(fs -> Orbit64.Net.fromFacelets(n, fs))))

///
/// A state that came from facelets encodes, which is the whole point of the
/// direction: a project with its own cube engine can produce a token.
///
@Test
def aStateReadFromFaceletsEncodes(): Unit \ Assert =
    roundTrippable() |> List.forEach(match (n, token) ->
        Assert.assertEq(
            expected = Ok(token),
            Orbit64.decode(n, token)
                |> Result.flatMap(orbits -> Orbit64.Net.toFacelets(n, orbits))
                |> Result.flatMap(fs -> Orbit64.Net.fromFacelets(n, fs))
                |> Result.flatMap(orbits -> Orbit64.encode(n, orbits))))
