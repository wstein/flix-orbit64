//
// First-sextet dispatch for the tokens this library still decodes.
// V1 state tokens (class 00) are rejected.
//

use Orbit64.Move.Move.{LayerTurn}
use Orbit64.Move.Face.U
use Orbit64.Move.Amount.Clockwise
use Orbit64.Move.LayerClass.LayerClass
use Orbit64.Token.Token.{MoveSequenceToken, AlgorithmToken, ExtensionToken}

@Test
def tokenDecoderRejectsV1StateTokens(): Unit \ Assert =
    match Orbit64.Token.decode("AAAAA") {
        case Ok(_)    => Assert.fail("accepted a V1 state token")
        case Err(why) =>
            Assert.assertTrue(String.contains(substr = "V1 state tokens are retired", why))
    }

@Test
def tokenDecoderDispatchesAMoveSequence(): Unit \ Assert =
    let moves = List#{LayerTurn(U, 0, Clockwise)};
    match Orbit64.Move.encode(3, moves) {
        case Err(e) => Assert.assertTrueWithMsg(false, "encode failed: ${e}")
        case Ok(t)  =>
            Assert.assertEq(
                expected = Ok(MoveSequenceToken(LayerClass(1), moves)),
                Orbit64.Token.decode(t)
            )
    }

@Test
def tokenDecoderDispatchesAnAlgorithm(): Unit \ Assert =
    let algorithm =
        Orbit64.Algorithm.Algorithm.Algorithm(
            List#{Orbit64.Algorithm.Node.Terminal(LayerTurn(U, 0, Clockwise))},
            0
        );
    match Orbit64.Algorithm.Encoding.encode(3, algorithm) {
        case Err(e) => Assert.assertTrueWithMsg(false, "encode failed: ${e}")
        case Ok(t)  =>
            Assert.assertEq(
                expected = Ok(AlgorithmToken(LayerClass(1), algorithm)),
                Orbit64.Token.decode(t)
            )
    }

@Test
def tokenDecoderRejectsEmptyAndReadsExtensionTokens(): Unit \ Assert =
    Assert.assertTrue(Orbit64.Token.decode("") |> Result.isErr);
    Assert.assertEq(expected = Ok(ExtensionToken(0, "")), Orbit64.Token.decode("w"));
    Assert.assertEq(expected = Ok(ExtensionToken(15, "")), Orbit64.Token.decode("_A"));
    Assert.assertTrue(Orbit64.Token.decode("_") |> Result.isErr)
