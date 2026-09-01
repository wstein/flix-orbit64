use AlgorithmTool.Ast.Program.{Program}
use AlgorithmTool.Ast.Definition.{Definition}
use AlgorithmTool.Ast.Expr.{Move, Reference, Concat, Repeat, Inverse}
use Orbit64.Move.Move.{LayerTurn}
use Orbit64.Move.Face.{U, R}
use Orbit64.Move.Amount.{Clockwise, CounterClockwise}

@Test
def sourceAstKeepsExactOperatorsAndNames(): Unit \ Assert =
    let program = Program(List#{
        Definition("a", Repeat(Concat(List#{
            Move(LayerTurn(U, 0, Clockwise)),
            Move(LayerTurn(R, 0, CounterClockwise))
        }), 33ii)),
        Definition("b", Inverse(Reference("a")))
    }, "b");
    Assert.assertEq(expected = "b", match program {
        case Program(_, export) => export
    })
