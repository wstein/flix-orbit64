//
// What `Orbit64.Net.draw` must refuse, and what its tables must satisfy.
//
// A coordinate being individually valid says nothing about the list it arrives
// in. A short, reordered or padded list can be made entirely of valid orbits
// and still describe no cube, and the renderer's tables are indexed by slot --
// so anything the list does not supply is simply never written, and the result
// is a tidy picture of something that does not exist. These are the tests that
// say so.
//

use Orbit64.Coord.Coord.{CornerCoord, MidgeCoord, WingCoord, CenterCoord}

def drawable(): List[Int32] = List#{2, 3, 4, 5}

def aMidge(): Orbit64.Coord.Coord =
    MidgeCoord(Vector.range(0, 12), Vector.repeat(12, 0))

@Test
def netAcceptsExactlyTheLayout(): Unit \ Assert =
    drawable() |> List.forEach(n ->
        Assert.assertTrueWithMsg(
            Result.isOk(Orbit64.Net.draw(n, Orbit64.solved(n), false)),
            "declined the solved ${n}x${n}x${n}"))

@Test
def netDeclinesAnEmptyOrbitList(): Unit \ Assert =
    drawable() |> List.forEach(n ->
        Assert.assertTrueWithMsg(
            Result.isErr(Orbit64.Net.draw(n, Nil, false)),
            "drew a ${n}x${n}x${n} from no orbits at all"))

@Test
def netDeclinesAnIncompleteOrbitList(): Unit \ Assert =
    drawable() |> List.forEach(n -> {
        let full = Orbit64.solved(n);
        // every proper prefix, so "one orbit short" and "corners only" both count
        List.range(0, List.length(full)) |> List.forEach(k ->
            Assert.assertTrueWithMsg(
                Result.isErr(Orbit64.Net.draw(n, List.take(k, full), false)),
                "drew a ${n}x${n}x${n} from only ${k} of its ${List.length(full)} orbits"))
    })

@Test
def netDeclinesADuplicatedOrbit(): Unit \ Assert =
    drawable() |> List.forEach(n -> {
        let full = Orbit64.solved(n);
        match full {
            case first :: _ =>
                Assert.assertTrueWithMsg(
                    Result.isErr(Orbit64.Net.draw(n, first :: full, false)),
                    "drew a ${n}x${n}x${n} with an orbit repeated")
            case Nil => ()
        }
    })

@Test
def netDeclinesAnOrbitThatSizeDoesNotHave(): Unit \ Assert =
    // A 2x2x2 and a 4x4x4 have no midges; appending one is valid on its own
    // terms and still not a cube of that size.
    List#{2, 4} |> List.forEach(n ->
        Assert.assertTrueWithMsg(
            Result.isErr(Orbit64.Net.draw(n, List.append(Orbit64.solved(n), List#{aMidge()}), false)),
            "drew a ${n}x${n}x${n} carrying a midge orbit"))

@Test
def netDeclinesAReorderedOrbitList(): Unit \ Assert =
    // Reversal only changes the layout where the orbits are not all alike.
    List#{3, 4, 5} |> List.forEach(n ->
        Assert.assertTrueWithMsg(
            Result.isErr(Orbit64.Net.draw(n, List.reverse(Orbit64.solved(n)), false)),
            "drew a ${n}x${n}x${n} with its orbits back to front"))

///
/// The tables are hand-derived, so the invariant is checked directly rather
/// than left to the scramble fixtures: a doubly-written facelet still holds a
/// plausible colour, and a fixture can pass while a table is wrong.
///
@Test
def everyFaceletIsWrittenExactlyOnce(): Unit \ Assert =
    List#{3, 4, 5} |> List.forEach(n ->
        match Orbit64.Net.writtenFacelets(n) {
            case None     => Assert.assertEq(expected = "tables for ${n}", "none")
            case Some(fs) =>
                Assert.assertEq(expected = 6 * n * n, Vector.length(fs));
                Assert.assertEq(expected = 6 * n * n, Vector.toSet(fs) |> Set.size);
                Assert.assertTrueWithMsg(
                    Vector.forAll(f -> f >= 0 and f < 6 * n * n, fs),
                    "a ${n}x${n}x${n} table indexes outside the cube")
        })
