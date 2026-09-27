// A facelet model of an inner U slice, independent of Net's orbit tables.
// Seen from above, the side bands cycle F <- R <- B <- L <- F.

def upperSlice(n: Int32, depth: Int32): Vector[Int32] =
    Vector.init(i -> {
        let face = i / (n * n);
        let row = Int32.modulo(i / n, n);
        if (row != depth) face
        else match face {
            case 1 => 5
            case 2 => 1
            case 4 => 2
            case 5 => 4
            case _ => face
        }
    }, 6 * n * n)

/// Each reachable inner U slice can be read, ranked, and drawn unchanged.
@Test
def largeCubeInnerSlicesArePhysicalStates(): Unit \ Assert =
    List#{6, 7} |> List.forEach(n ->
        List#{1, 2} |> List.forEach(depth -> {
            let facelets = upperSlice(n, depth);
            let state = Orbit64.Net.fromFacelets(n, facelets);
            Assert.assertTrueWithMsg(Result.isOk(state),
                "could not read the ${n}x${n}x${n} U slice at depth ${depth}");
            Assert.assertEq(expected = Ok(facelets),
                state |> Result.flatMap(s -> Orbit64.Net.toFacelets(n, s)));
            Assert.assertTrueWithMsg(
                Result.isOk(state |> Result.flatMap(s -> Orbit64.State.encode(n, s))),
                "could not encode the ${n}x${n}x${n} U slice at depth ${depth}")
        }))

/// The fixed centre on the 7x7x7 identifies every whole-cube frame.
@Test
def sevenBySevenFramesReadBack(): Unit \ Assert =
    List.range(0, Orbit64.Frame.count()) |> List.forEach(rank -> {
        let state = Orbit64.State.FramedState.FramedState(
            Orbit64.Frame.unrank(rank), Orbit64.State.solved(7) |> Orbit64.State.orbits);
        Assert.assertEq(expected = Ok(state),
            Orbit64.Net.toFacelets(7, state)
                |> Result.flatMap(fs -> Orbit64.Net.fromFacelets(7, fs)))
    })
