//
// `Orbit64.Symmetry`: the 48 cube symmetries as facelet permutations.
//

def symmetrySolved(n: Int32): Vector[Int32] =
    Vector.range(0, 6 * n * n) |> Vector.map(i -> i / (n * n))

def symmetryStickers(n: Int32, token: String): Vector[Int32] =
    match Orbit64.State.decode(n, token) |> Result.flatMap(s -> Orbit64.Net.toFacelets(n, s)) {
        case Ok(fs)  => fs
        case Err(_)  => Vector.empty()
    }

@Test
def everySymmetryIsAPermutationAtEverySize(): Unit \ Assert =
    List.range(2, 8) |> List.forEach(n ->
        List.range(0, Orbit64.Symmetry.count()) |> List.forEach(g -> {
            let sorted = Orbit64.Symmetry.destinations(n, g)
                |> Vector.toList |> List.sort;
            Assert.assertEq(expected = List.range(0, 6 * n * n), sorted)
        }))

@Test
def symmetryZeroIsTheIdentity(): Unit \ Assert =
    List.range(2, 8) |> List.forEach(n ->
        Assert.assertEq(expected = Vector.range(0, 6 * n * n),
                        Orbit64.Symmetry.destinations(n, 0)))

@Test
def theMirrorSwapsTheRightAndLeftFaces(): Unit \ Assert =
    let mirrored = Orbit64.Symmetry.image(3, Orbit64.Symmetry.mirrorAcrossRL(), symmetrySolved(3));
    let face = f -> Vector.range(f * 9, f * 9 + 9) |> Vector.map(i -> Vector.get(i, mirrored));
    Assert.assertEq(expected = Vector.repeat(9, 0), face(0));
    Assert.assertEq(expected = Vector.repeat(9, 4), face(1));
    Assert.assertEq(expected = Vector.repeat(9, 1), face(4));
    Assert.assertEq(expected = Vector.repeat(9, 5), face(5))

@Test
def theMirrorIsItsOwnInverse(): Unit \ Assert =
    let g = Orbit64.Symmetry.mirrorAcrossRL();
    roundTrippable() |> List.forEach(match (n, token) -> {
        let fs = symmetryStickers(n, token);
        Assert.assertEq(expected = fs,
                        Orbit64.Symmetry.image(n, g, Orbit64.Symmetry.image(n, g, fs)))
    })

@Test
def relabelNamesColorsInOrderOfFirstAppearance(): Unit \ Assert =
    Assert.assertEq(expected = Vector#{0, 1, 0, 2, 1, 3},
                    Orbit64.Symmetry.relabel(Vector#{4, 2, 4, 0, 2, 5}))

@Test
def leastImageIgnoresTurnsMirrorsAndColors(): Unit \ Assert =
    let fs = symmetryStickers(3, "AP7AYhnwDQbA");
    let least = Orbit64.Symmetry.leastImage(3, fs);
    List.range(0, Orbit64.Symmetry.count()) |> List.forEach(g -> {
        let moved = Orbit64.Symmetry.image(3, g, fs);
        let renamed = Vector.map(c -> Int32.modulo(c + 2, 6), moved);
        Assert.assertEq(expected = least, Orbit64.Symmetry.leastImage(3, moved));
        Assert.assertEq(expected = least, Orbit64.Symmetry.leastImage(3, renamed))
    });
    Assert.assertEq(expected = least, Orbit64.Symmetry.leastImage(3, least))

@Test
def theFirstCornerIsUrf(): Unit \ Assert =
    List.range(2, 8) |> List.forEach(n ->
        Assert.assertEq(expected = Some(Vector#{n * n - 1, n * n, 2 * n * n + n - 1}),
                        Orbit64.Symmetry.cornerStickers(n) |> List.head))

@Test
def eightCornersWithThreeDistinctStickersEach(): Unit \ Assert =
    List.range(2, 8) |> List.forEach(n -> {
        let all = Orbit64.Symmetry.cornerStickers(n) |> List.flatMap(Vector.toList);
        Assert.assertEq(expected = 24, List.length(all));
        Assert.assertEq(expected = 24, Set.size(List.toSet(all)))
    })
