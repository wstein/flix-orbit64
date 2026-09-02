//
// Universal first-sextet dispatch across the Orbit64 token family.
//

use Orbit64.Move.Move.{LayerTurn}
use Orbit64.Move.Face.U
use Orbit64.Move.Amount.Clockwise
use Orbit64.Move.LayerClass.LayerClass
use Orbit64.Token.Token.{StateToken, MoveSequenceToken, AlgorithmToken, ExtensionToken}

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
            expected = Ok(MoveSequenceToken(LayerClass(1), moves)),
            Orbit64.Token.decode(t))
    }

@Test
def tokenDecoderDispatchesAnAlgorithm(): Unit \ Assert =
    let algorithm = Orbit64.Algorithm.Algorithm.Algorithm(List#{
        Orbit64.Algorithm.Node.Terminal(LayerTurn(U, 0, Clockwise))
    }, 0);
    match Orbit64.Algorithm.Encoding.encode(3, algorithm) {
        case Err(e) => Assert.assertTrueWithMsg(false, "encode failed: ${e}")
        case Ok(t)  => Assert.assertEq(
            expected = Ok(AlgorithmToken(LayerClass(1), algorithm)), Orbit64.Token.decode(t))
    }

@Test
def tokenDecoderRejectsEmptyAndReadsExtensionTokens(): Unit \ Assert =
    Assert.assertTrue(Orbit64.Token.decode("") |> Result.isErr);
    Assert.assertEq(expected = Ok(ExtensionToken(0, "")), Orbit64.Token.decode("w"));
    Assert.assertEq(expected = Ok(ExtensionToken(15, "")), Orbit64.Token.decode("_A"));
    Assert.assertTrue(Orbit64.Token.decode("_") |> Result.isErr)
