//
// `Orbit64.Internal.Symmetry`: the 48 cube symmetries as facelet permutations.
//

use Orbit64.Internal.Symmetry

def symmetrySolved(n: Int32): Vector[Int32] =
    Vector.range(0, 6 * n * n) |> Vector.map(i -> i / (n * n))

def symmetryStickers(n: Int32, token: String): Vector[Int32] =
    match Orbit64.State.decode(n, token)
            |> Result.flatMap(s -> Orbit64.Net.toFacelets(n, s)) {
        case Ok(fs) => fs
        case Err(_) => Vector.empty()
    }

def symmetryImage(n: Int32, g: Int32, fs: Vector[Int32]): Vector[Int32] =
    Symmetry.image(n, g, fs) |> Result.getWithDefault(Vector.empty())

def symmetryLeast(n: Int32, fs: Vector[Int32]): Vector[Int32] =
    Symmetry.leastImage(n, fs) |> Result.getWithDefault(Vector.empty())

@Test
def everySymmetryIsAPermutationAtEverySize(): Unit \ Assert =
    List.range(2, 8) |> List.forEach(n ->
        List.range(0, Symmetry.count()) |> List.forEach(g -> {
            let sorted = Symmetry.destinations(n, g) |> Vector.toList |> List.sort;
            Assert.assertEq(expected = List.range(0, 6 * n * n), sorted)
        }))

@Test
def symmetryZeroIsTheIdentity(): Unit \ Assert =
    List.range(2, 8) |> List.forEach(n ->
        Assert.assertEq(expected = Vector.range(0, 6 * n * n), Symmetry.destinations(n, 0)))

@Test
def theMirrorSwapsTheRightAndLeftFaces(): Unit \ Assert =
    let mirror = Symmetry.mirrorAcrossRL();
    let mirrored = symmetryImage(3, mirror, symmetrySolved(3));
    let face = f ->
        Vector.range(f * 9, f * 9 + 9) |> Vector.map(i -> Vector.get(i, mirrored));
    Assert.assertEq(expected = Vector.repeat(9, 0), face(0));
    Assert.assertEq(expected = Vector.repeat(9, 4), face(1));
    Assert.assertEq(expected = Vector.repeat(9, 1), face(4));
    Assert.assertEq(expected = Vector.repeat(9, 5), face(5))

@Test
def theMirrorIsItsOwnInverse(): Unit \ Assert =
    let g = Symmetry.mirrorAcrossRL();
    roundTrippable() |> List.forEach(match (n, token) -> {
        let fs = symmetryStickers(n, token);
        Assert.assertEq(expected = fs, symmetryImage(n, g, symmetryImage(n, g, fs)))
    })

@Test
def imageRejectsWhatIsNotACubeOrASymmetry(): Unit \ Assert =
    Assert.assertTrue(Result.isErr(Symmetry.image(3, 0, Vector.repeat(53, 0))));
    Assert.assertTrue(Result.isErr(Symmetry.image(3, 48, Vector.repeat(54, 0))));
    Assert.assertTrue(Result.isErr(Symmetry.image(3, -1, Vector.repeat(54, 0))));
    Assert.assertTrue(Result.isErr(Symmetry.image(8, 0, Vector.repeat(384, 0))));
    Assert.assertTrue(Result.isErr(Symmetry.leastImage(3, Vector.repeat(53, 0))))

@Test
def relabelNamesColorsInOrderOfFirstAppearance(): Unit \ Assert =
    Assert.assertEq(expected = Vector#{0, 1, 0, 2, 1, 3},
                    Symmetry.relabel(Vector#{4, 2, 4, 0, 2, 5}))

@Test
def leastImageIgnoresTurnsMirrorsAndColors(): Unit \ Assert =
    let fs = symmetryStickers(3, "AP7AYhnwDQbA");
    let least = symmetryLeast(3, fs);
    List.range(0, Symmetry.count()) |> List.forEach(g -> {
        let moved = symmetryImage(3, g, fs);
        let renamed = Vector.map(c -> Int32.modulo(c + 2, 6), moved);
        Assert.assertEq(expected = least, symmetryLeast(3, moved));
        Assert.assertEq(expected = least, symmetryLeast(3, renamed))
    });
    Assert.assertEq(expected = least, symmetryLeast(3, least))

@Test
def theFirstCornerIsUrf(): Unit \ Assert =
    List.range(2, 8) |> List.forEach(n ->
        Assert.assertEq(expected = Some(Vector#{n * n - 1, n * n, 2 * n * n + n - 1}),
                        Symmetry.cornerStickers(n) |> List.head))

@Test
def eightCornersWithThreeDistinctStickersEach(): Unit \ Assert =
    List.range(2, 8) |> List.forEach(n -> {
        let all = Symmetry.cornerStickers(n) |> List.flatMap(Vector.toList);
        Assert.assertEq(expected = 24, List.length(all));
        Assert.assertEq(expected = 24, Set.size(List.toSet(all)))
    })

@Test
def onlyOddCubesHaveCenterFacelets(): Unit \ Assert =
    Assert.assertEq(expected = Some(4), Symmetry.centerFacelet(3, 0));
    Assert.assertEq(expected = Some(24 + 49), Symmetry.centerFacelet(7, 1));
    Assert.assertEq(expected = None, Symmetry.centerFacelet(2, 0));
    Assert.assertEq(expected = None, Symmetry.centerFacelet(4, 0));
    Assert.assertEq(expected = None, Symmetry.centerFacelet(3, 6))
