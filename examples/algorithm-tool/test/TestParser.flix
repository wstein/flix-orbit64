use AlgorithmTool.Ast.Program.{Program}
use AlgorithmTool.Ast.Definition.{Definition}
use AlgorithmTool.Ast.Expr.{Move, Reference, Concat, Repeat, Inverse, Conjugate, Commutator, Slice}
use Orbit64.Move.Move.{LayerTurn}
use Orbit64.Move.Face.{U, R, D, L, B}
use Orbit64.Move.Amount.{Clockwise}

@Test
def parserUnderstandsTheNativeOperatorGrammar(): Unit \ Assert =
    let source = "def a = (U R)33\ndef b = [L: U] [D, B] a'\nexport b";
    let expected = Program(List#{
        Definition("a", Repeat(Concat(List#{
            Move(LayerTurn(U, 0, Clockwise)), Move(LayerTurn(R, 0, Clockwise))
        }), 33ii)),
        Definition("b", Concat(List#{
            Conjugate(Move(LayerTurn(L, 0, Clockwise)), Move(LayerTurn(U, 0, Clockwise))),
            Commutator(Move(LayerTurn(D, 0, Clockwise)), Move(LayerTurn(B, 0, Clockwise))),
            Inverse(Reference("a"))
        }))
    }, "b");
    Assert.assertEq(expected = Ok(expected), AlgorithmTool.Parser.parse(source))

@Test
def parserRecognizesPrimesSlicesCommentsAndMultilineDefinitions(): Unit \ Assert =
    let source = "# comment\ndef stream = (U R')2\ndef pick = stream[1:]\nexport pick";
    let expected = Program(List#{
        Definition("stream", Repeat(Concat(List#{
            Move(LayerTurn(U, 0, Clockwise)),
            Inverse(Move(LayerTurn(R, 0, Clockwise)))
        }), 2ii)),
        Definition("pick", Slice("stream", 1, 2147483647))
    }, "pick");
    Assert.assertEq(expected = Ok(expected), AlgorithmTool.Parser.parse(source))
