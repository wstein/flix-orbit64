@Test
def theSuperflipEncodesToItsKnownToken(): Unit \ Assert =
    Assert.assertEq(expected = Ok("AAAAAAAAAL_o"), Orbit64.State.encode(3, superflip()))

@Test
def theSuperflipDecodesBackIdentically(): Unit \ Assert =
    Assert.assertEq(expected = Ok(superflip()), Orbit64.State.decode(3, "AAAAAAAAAL_o"))

@Test
def theNetOfTheSuperflipShowsItsUFace(): Unit \ Assert =
    Assert.assertEq(expected = Ok(true),
                    Orbit64.Net.draw(3, superflip(), false)
                        |> Result.map(net -> String.contains(substr = " U  B  U ", net)))

@Test
def theSizeTableAbbreviatesLargeNumbers(): Unit \ Assert =
    Assert.assertEq(expected = "   8.817e7", sci(88179840ii));
    Assert.assertEq(expected = "      1234", sci(1234ii))
