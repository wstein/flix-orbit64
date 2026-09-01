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
        match Orbit64.State.decode(n, token) {
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
        match Orbit64.State.decode(n, token)
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
            expected = Ok(Orbit64.State.solved(n)),
            Orbit64.Net.toFacelets(n, Orbit64.State.solved(n))
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
            Orbit64.State.decode(n, token)
                |> Result.flatMap(orbits -> Orbit64.Net.toFacelets(n, orbits))
                |> Result.flatMap(fs -> Orbit64.Net.fromFacelets(n, fs))
                |> Result.flatMap(orbits -> Orbit64.State.encode(n, orbits))))

//
// A seed matrix, to widen the round trip past the checked-in states.
//
// The vectors above are real scrambles, which is what makes them worth having,
// but there are only a handful of them and every one came from the same
// generator. These states come from `Coord.unrank` on spread-out coordinates
// instead: arbitrary wing permutations, arbitrary centre colourings, arbitrary
// twists, none of them reachable-looking and all of them valid, since `unrank`
// is onto exactly the coordinates the format admits.
//
// Deterministic, so a failure is reproducible and a passing run is not luck.
//

///
/// The `steps`-th term of a fixed linear congruential sequence, modulo 2^80.
///
/// Not random -- just spread out, and the same on every run and every machine.
/// The modulus is above `24!`, so reducing a term by any orbit's radix still
/// reaches the whole of it rather than a low corner.
///
def scatter(steps: Int32): BigInt =
    List.range(0, steps) |> List.foldLeft((x, _) ->
        BigInt.modulo(x * 6364136223846793005ii + 1442695040888963407ii,
                      1208925819614629174706176ii), 12345ii)

///
/// State `s` of an `n x n x n`: one coordinate per orbit, each drawn from its
/// own term of the sequence so that no two orbits move together.
///
def seededState(n: Int32, s: Int32): List[Orbit64.Coord.Coord] =
    Orbit64.Orbit.layout(n) |> List.mapWithIndex((i, o) ->
        Orbit64.Coord.unrank(o, BigInt.modulo(scatter(s * 8 + i + 1), Orbit64.Orbit.radix(o))))

def seeds(): List[Int32] = List.range(0, 8)

///
/// Drawing a seeded state and reading it back gives the state again.
///
@Test
def seededStatesReadBackFromTheirFacelets(): Unit \ Assert =
    List#{2, 3, 4, 5} |> List.forEach(n ->
        seeds() |> List.forEach(s -> {
            let orbits = seededState(n, s);
            Assert.assertTrueWithMsg(
                Orbit64.Net.toFacelets(n, orbits)
                    |> Result.flatMap(fs -> Orbit64.Net.fromFacelets(n, fs)) == Ok(orbits),
                "seed ${s} of the ${n}x${n}x${n} did not read back")
        }))

///
/// And reading a seeded state's facelets then drawing them gives the stickers
/// again.
///
@Test
def seededFaceletsSurviveBeingReadAndDrawn(): Unit \ Assert =
    List#{2, 3, 4, 5} |> List.forEach(n ->
        seeds() |> List.forEach(s ->
            match Orbit64.Net.toFacelets(n, seededState(n, s)) {
                case Err(why) => Assert.assertTrueWithMsg(false,
                    "seed ${s} of the ${n}x${n}x${n} gave no facelets: ${why}")
                case Ok(fs) => Assert.assertTrueWithMsg(
                    Orbit64.Net.fromFacelets(n, fs)
                        |> Result.flatMap(orbits -> Orbit64.Net.toFacelets(n, orbits)) == Ok(fs),
                    "seed ${s} of the ${n}x${n}x${n} did not draw the same stickers twice")
            }))

///
/// The `i`-th orbit of a state, by position in `Orbit.layout`.
///
def orbitAt(i: Int32, st: List[Orbit64.Coord.Coord]): Option[Orbit64.Coord.Coord] =
    List.drop(i, st) |> List.head

///
/// The seeds have to actually scatter, orbit by orbit.
///
/// A sequence that collapsed -- to zero, or to one value repeated -- would hand
/// the two laws above eight copies of the same cube, and they would pass on it
/// without having tested anything. Distinct *states* are not enough to rule
/// that out: a matrix that varied only the corners would still give eight
/// distinct 4x4x4s while every wing and every centre stood still, and the
/// readers for those orbits would go untested. So the claim is made where it
/// is meant -- each orbit takes eight different values of its own.
///
/// Coordinates stand in for the orbits, because a coordinate is that orbit's
/// state made comparable, and `0` is exactly its solved value.
///
@Test
def theSeedsAreActuallyScattered(): Unit \ Assert =
    List#{2, 3, 4, 5} |> List.forEach(n -> {
        let states = seeds() |> List.map(s -> seededState(n, s));
        // Every seeded state is one the format admits, or `encode` refuses it.
        let tokens = states |> List.filterMap(st -> Orbit64.State.encode(n, st) |> Result.toOption);
        Assert.assertTrueWithMsg(
            List.length(tokens) == List.length(states),
            "a seeded ${n}x${n}x${n} did not encode at all");
        List.range(0, List.length(Orbit64.Orbit.layout(n))) |> List.forEach(i -> {
            let ranks = states
                |> List.filterMap(st -> orbitAt(i, st) |> Option.map(Orbit64.Coord.rank));
            Assert.assertTrueWithMsg(
                List.toSet(ranks) |> Set.size == List.length(states),
                "orbit ${i} of the ${n}x${n}x${n} took the same value in two samples");
            Assert.assertTrueWithMsg(
                not List.memberOf(0ii, ranks),
                "orbit ${i} of the ${n}x${n}x${n} came out solved in a sample")
        })
    })
