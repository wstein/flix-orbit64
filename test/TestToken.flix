//
// Universal first-sextet dispatch across the Orbit64 token family.
//

use Orbit64.Move.Move.{LayerTurn}
use Orbit64.Move.Face.U
use Orbit64.Move.Amount.Clockwise
use Orbit64.Move.Slp.Slp.Slp
use Orbit64.Move.Slp.Rule.Terminal
use Orbit64.Token.Token.{StateToken, MoveSequenceToken, MoveSlpToken}

@Test
def tokenDecoderDispatchesAState(): Unit \ Assert =
    Assert.assertEq(
        expected = Ok(StateToken(2, Orbit64.State.solved(2))),
        Orbit64.Token.decode("AAAAA"))

@Test
def tokenDecoderDefinesSixAndSevenBySevenAsStateClass(): Unit \ Assert =
    List#{6, 7} |> List.forEach(n -> {
        let state = Orbit64.State.solved(n);
        match Orbit64.State.encode(n, state) {
            case Err(e) => Assert.assertTrueWithMsg(false, "encode failed: ${e}")
            case Ok(t)  => {
                Assert.assertEq(expected = 'A', String.charAt(0, t));
                Assert.assertEq(expected = Ok(StateToken(n, state)), Orbit64.Token.decode(t))
            }
        }
    })

@Test
def tokenDecoderDispatchesAMoveSequence(): Unit \ Assert =
    let moves = List#{LayerTurn(U, 0, Clockwise)};
    match Orbit64.Move.encode(3, moves) {
        case Err(e) => Assert.assertTrueWithMsg(false, "encode failed: ${e}")
        case Ok(t)  => Assert.assertEq(
            expected = Ok(MoveSequenceToken(3, moves)), Orbit64.Token.decode(t))
    }

@Test
def tokenDecoderDispatchesAMoveSlp(): Unit \ Assert =
    let slp = Slp(List#{Terminal(LayerTurn(U, 0, Clockwise))});
    match Orbit64.Move.Slp.encode(3, slp) {
        case Err(e) => Assert.assertTrueWithMsg(false, "encode failed: ${e}")
        case Ok(t)  => Assert.assertEq(
            expected = Ok(MoveSlpToken(3, slp)), Orbit64.Token.decode(t))
    }

@Test
def tokenDecoderRejectsEmptyAndReservedTokens(): Unit \ Assert =
    Assert.assertTrue(Orbit64.Token.decode("") |> Result.isErr);
    Assert.assertTrue(Orbit64.Token.decode("wA") |> Result.isErr)
