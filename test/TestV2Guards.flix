use Orbit64.V2.State.Cube

def solved3Picture(): Cube = Orbit64.V2.State.solved(3, Orbit64.V2.Registry.Model.Picture)

def swapFirstTwo(v: Vector[Int32]): Vector[Int32] =
    Vector.mapWithIndex((i, x) -> if (i == 0) Vector.get(1, v) else if (i == 1) Vector.get(0, v) else x, v)

@Test
def encodeRejectsAnUnknownEntry(): Unit \ Assert =
    Assert.assertTrue(Result.isErr(Orbit64.V2.Codec.encode(54, solved3Picture())))

@Test
def encodeRejectsATwistedCorner(): Unit \ Assert =
    let cube = { cornerTwists = Vector#{1, 0, 0, 0, 0, 0, 0, 0} | solved3Picture() };
    Assert.assertTrue(Result.isErr(Orbit64.V2.Codec.encode(4, cube)))

@Test
def encodeRejectsAFlippedMidge(): Unit \ Assert =
    let cube = { midgeFlips = Vector#{1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0} | solved3Picture() };
    Assert.assertTrue(Result.isErr(Orbit64.V2.Codec.encode(4, cube)))

@Test
def encodeRejectsMismatchedCornerAndMidgeParity(): Unit \ Assert =
    let cube = { cornerPieces = swapFirstTwo(Vector.range(0, 8)) | solved3Picture() };
    Assert.assertTrue(Result.isErr(Orbit64.V2.Codec.encode(4, cube)))

@Test
def encodeRejectsAnOddRotationSumWithEvenParity(): Unit \ Assert =
    let cube = { rotations = Vector#{1, 0, 0, 0, 0, 0} | solved3Picture() };
    Assert.assertTrue(Result.isErr(Orbit64.V2.Codec.encode(4, cube)))

@Test
def encodeRejectsAFrameOnACanonicalEntry(): Unit \ Assert =
    let cube = { frame = 5 | solved3Picture() };
    Assert.assertTrue(Result.isErr(Orbit64.V2.Codec.encode(4, cube)));
    Assert.assertTrue(Result.isOk(Orbit64.V2.Codec.encode(5, cube)))

@Test
def encodeRejectsAMovedDblCornerOnACanonicalEvenCube(): Unit \ Assert =
    let cube = { cornerTwists = Vector#{0, 0, 0, 0, 0, 0, 1, 2} | Orbit64.V2.State.solved(2, Orbit64.V2.Registry.Model.Color) };
    Assert.assertTrue(Result.isErr(Orbit64.V2.Codec.encode(0, cube)));
    Assert.assertTrue(Result.isOk(Orbit64.V2.Codec.encode(1, cube)))

@Test
def encodeRejectsAnUnbalancedColorOrbit(): Unit \ Assert =
    let base = Orbit64.V2.State.solved(4, Orbit64.V2.Registry.Model.Color);
    let bad = Vector.mapWithIndex((i, x) -> if (i == 0) 5 else x, Vector.get(0, base#centers));
    let cube = { centers = Vector#{bad} | base };
    Assert.assertTrue(Result.isErr(Orbit64.V2.Codec.encode(6, cube)))

@Test
def encodeRejectsAPictureCenterBreakingTheParityRelation(): Unit \ Assert =
    let base = Orbit64.V2.State.solved(4, Orbit64.V2.Registry.Model.Picture);
    let cube = { centers = Vector#{swapFirstTwo(Vector.get(0, base#centers))} | base };
    Assert.assertTrue(Result.isErr(Orbit64.V2.Codec.encode(8, cube)))

@Test
def encodeRejectsShortCornerVectorsWithoutCrashing(): Unit \ Assert =
    let cube = { cornerPieces = Vector#{0, 1, 2}, cornerTwists = Vector#{0, 0, 0}
                 | Orbit64.V2.State.solved(2, Orbit64.V2.Registry.Model.Color) };
    Assert.assertTrue(Result.isErr(Orbit64.V2.Codec.encode(0, cube)))

@Test
def encodeRejectsMissingWingOrbitsWithoutCrashing(): Unit \ Assert =
    let cube = { wings = Vector.empty()
                 | Orbit64.V2.State.solved(4, Orbit64.V2.Registry.Model.Picture) };
    Assert.assertTrue(Result.isErr(Orbit64.V2.Codec.encode(8, cube)))
