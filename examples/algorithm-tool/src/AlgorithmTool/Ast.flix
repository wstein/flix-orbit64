/// Source-level, notation-aware algorithm syntax.
mod AlgorithmTool.Ast {

    /// A program with ordered definitions and one exported name.
    pub enum Program with Eq, ToString {
        case Program(List[Definition], String)
    }

    /// One earlier-reference-only source definition.
    pub enum Definition with Eq, ToString {
        case Definition(String, Expr)
    }

    /// A native algorithm expression before it is lowered to an Orbit64 DAG.
    pub enum Expr with Eq, ToString {
        case Move(Orbit64.Move.Move)
        case Reference(String)
        case Concat(List[Expr])
        case Repeat(Expr, BigInt)
        case Inverse(Expr)
        case Conjugate(Expr, Expr)
        case Commutator(Expr, Expr)
        case Slice(String, Int32, Int32)
    }

}
