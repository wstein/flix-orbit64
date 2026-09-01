//
// Straight-line programs over primitive moves.
//

use Orbit64.Move.Move.{LayerTurn}
use Orbit64.Move.Face.{U, R}
use Orbit64.Move.Amount.{Clockwise, Half}
use Orbit64.Move.Slp.Slp.{Slp}
use Orbit64.Move.Slp.Rule.{Terminal, Concat}

@Test
def emptySlpHasNoGrammarRankPayload(): Unit \ Assert =
    let slp = Slp(Nil);
    Assert.assertEq(expected = Ok("hA"), Orbit64.Move.Slp.encode(3, slp));
    Assert.assertEq(expected = Ok((3, slp)), Orbit64.Move.Slp.decode("hA"))

@Test
def oneTerminalSlpHasAStableToken(): Unit \ Assert =
    let slp = Slp(List#{Terminal(LayerTurn(U, 0, Clockwise))});
    Assert.assertEq(expected = Ok("hBA"), Orbit64.Move.Slp.encode(3, slp));
    Assert.assertEq(expected = Ok((3, slp)), Orbit64.Move.Slp.decode("hBA"))

@Test
def concatenatingSlpHasAStableToken(): Unit \ Assert =
    let slp = Slp(List#{
        Terminal(LayerTurn(U, 0, Clockwise)),
        Terminal(LayerTurn(R, 0, Half)),
        Concat(0, 1)
    });
    Assert.assertEq(expected = Ok("hDABr"), Orbit64.Move.Slp.encode(3, slp));
    Assert.assertEq(expected = Ok((3, slp)), Orbit64.Move.Slp.decode("hDABr"))

@Test
def slpIdentityIsStructural(): Unit \ Assert =
    let direct = Slp(List#{
        Terminal(LayerTurn(U, 0, Clockwise)),
        Terminal(LayerTurn(R, 0, Half)),
        Concat(0, 1)
    });
    let duplicated = Slp(List#{
        Terminal(LayerTurn(U, 0, Clockwise)),
        Terminal(LayerTurn(R, 0, Half)),
        Concat(0, 1),
        Concat(0, 1)
    });
    Assert.assertTrue(Orbit64.Move.Slp.encode(3, direct) !=
        Orbit64.Move.Slp.encode(3, duplicated))

@Test
def slpRejectsForwardReferencesAndMalformedPayloads(): Unit \ Assert =
    let forward = Slp(List#{Concat(0, 0)});
    Assert.assertTrue(Orbit64.Move.Slp.encode(3, forward) |> Result.isErr);
    Assert.assertTrue(Orbit64.Move.Slp.decode("h") |> Result.isErr);
    Assert.assertTrue(Orbit64.Move.Slp.decode("hB_") |> Result.isErr);
    Assert.assertTrue(Orbit64.Move.Slp.decode("RB") |> Result.isErr)
