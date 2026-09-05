// Orbit64 3x3x3 vectors are defined by cube-rosetta/docs/orbit64.md.

use Orbit64.Coord.Coord.{CornerCoord, MidgeCoord}

def uTurn(): Orbit64.State.FramedState =
    Orbit64.State.canonical(List#{
        CornerCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7}, Vector.repeat(8, 0)),
        MidgeCoord(Vector#{3, 0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11}, Vector.repeat(12, 0))
    })

@Test
def rosettaCanonicalReferenceVectorsEncode(): Unit \ Assert =
    Assert.assertEq(expected = Ok("AAAAAAAAAAAA"), Orbit64.State.encode(3, Orbit64.State.solved(3)));
    Assert.assertEq(expected = Ok("AAAAAAAAAL_o"), Orbit64.State.encode(3,
        Orbit64.State.canonical(List#{
            CornerCoord(Vector.range(0, 8), Vector.repeat(8, 0)),
            MidgeCoord(Vector.range(0, 12), Vector.repeat(12, 1))
        })));
    Assert.assertEq(expected = Ok("FRot3QyvoAAA"), Orbit64.State.encode(3, uTurn()));
    Assert.assertEq(expected = Ok(uTurn()), Orbit64.State.decode(3, "FRot3QyvoAAA"))

@Test
def rosettaXFrameRoundTripsAtTheFaceletBoundary(): Unit \ Assert =
    let state = Orbit64.State.FramedState.FramedState(Orbit64.Frame.unrank(4),
        Orbit64.State.solved(3) |> Orbit64.State.orbits);
    Assert.assertEq(expected = Ok("AAAAAAAAAAAE"), Orbit64.State.encode(3, state));
    Assert.assertEq(expected = Ok(state), Orbit64.State.decode(3, "AAAAAAAAAAAE"));
    Assert.assertEq(expected = Ok(state), Orbit64.Net.toFacelets(3, state)
        |> Result.flatMap(fs -> Orbit64.Net.fromFacelets(3, fs)))
