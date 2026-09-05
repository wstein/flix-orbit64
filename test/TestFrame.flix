use Orbit64.Frame.Frame

@Test
def frameRanksCoverTwentyFourRightHandedFaceLists(): Unit \ Assert =
    let frames = List.range(0, Orbit64.Frame.count()) |> List.map(Orbit64.Frame.unrank);
    let names = frames |> List.map(Orbit64.Frame.notation);
    let unique = names |> List.foldLeft((seen, text) -> Set.insert(text, seen), Set.empty());
    Assert.assertEq(expected = 24, List.length(frames));
    Assert.assertEq(expected = 24, Set.size(unique))

@Test
def canonicalFrameUsesTheSharedSpacedFaceReference(): Unit \ Assert =
    Assert.assertEq(expected = "U R F D L B", Orbit64.Frame.canonical() |> Orbit64.Frame.notation);
    Assert.assertEq(expected = Frame.Frame(0), Orbit64.Frame.unrank(0));
    Assert.assertEq(expected = 23, Orbit64.Frame.unrank(23) |> Orbit64.Frame.rank)

@Test
def frameRejectsOutOfRangeRanks(): Unit \ Assert =
    Assert.assertFalse(Orbit64.Frame.faultOf(Frame.Frame(-1)) |> Option.isEmpty);
    Assert.assertFalse(Orbit64.Frame.faultOf(Frame.Frame(24)) |> Option.isEmpty)
