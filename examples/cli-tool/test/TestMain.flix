use orbit64::Orbit64

@Test
def solvedColorFramed3x3EncodesToTwelveAs(): Unit \ Assert =
    let solved = Orbit64.V2.State.solved(3, Orbit64.V2.Registry.Model.Color);
    Assert.assertEq(expected = Ok(String.repeat(12, "A")), Orbit64.V2.Codec.encode(3, solved))

@Test
def thatTokenDecodesBackToTheSameState(): Unit \ Assert =
    match Orbit64.V2.Codec.decode(String.repeat(12, "A")) {
        case Ok((e, cube)) =>
            Assert.assertEq(expected = 3, e#id);
            Assert.assertEq(
                expected = Ok(String.repeat(12, "A")),
                Orbit64.V2.Codec.encode(e#id, cube)
            )
        case Err(why)      => Assert.fail(why)
    }
