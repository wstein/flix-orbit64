/// Whole-cube reference frames in canonical `U R F D L B` slot order.
///
/// A frame says which physical face occupies each Orbit64 reference slot. The
/// ranks are Orbit64's wire order: `x` turns, then `z` turns, then `y` turns.
mod Orbit64.Frame {

    use Orbit64.Move.Face

    /// A rank in the 24-element group of right-handed whole-cube frames.
    pub enum Frame with Eq, ToString {
        case Frame(Int32)
    }

    /// The number of distinguishable whole-cube frames.
    pub def count(): Int32 = 24

    /// The reference frame with the familiar `U R F D L B` face list.
    pub def canonical(): Frame = Frame.Frame(0)

    /// Explain why a frame rank is outside the 24-element orientation group.
    pub def faultOf(frame: Frame): Option[String] = match frame {
        case Frame.Frame(rank) =>
            if (rank < 0 or rank >= count()) Some("frame rank must be in 0..23") else None
    }

    /// Recover a frame from its canonical rank. Values outside `0..23` map to
    /// the canonical frame; decoders validate their rank before calling this.
    pub def unrank(rank: Int32): Frame =
        if (rank < 0 or rank >= count()) canonical() else Frame.Frame(rank)

    /// Return the canonical rank of `frame`.
    pub def rank(frame: Frame): Int32 = match frame {
        case Frame.Frame(value) => value
    }

    /// The number of clockwise `x` rotations in the wire transform.
    pub def xTurns(frame: Frame): Int32 = match frame {
        case Frame.Frame(value) => if (value < 16) value / 4 else 0
    }

    /// The number of clockwise `z` rotations in the wire transform.
    pub def zTurns(frame: Frame): Int32 = match frame {
        case Frame.Frame(value) => if (value >= 16 and value < 20) 1
                                    else if (value >= 20) 3 else 0
    }

    /// The number of clockwise `y` rotations in the wire transform.
    pub def yTurns(frame: Frame): Int32 = match frame {
        case Frame.Frame(value) => Int32.modulo(value, 4)
    }

    /// The physical faces occupying the reference slots `U R F D L B` after
    /// applying the frame's `x`, `z`, then `y` rotations.
    pub def faces(frame: Frame): List[Face] = match frame {
        case Frame.Frame(value) => facesAt(value)
    }

    /// Render `faces(frame)` in compact spaced WCA notation.
    pub def notation(frame: Frame): String =
        faces(frame) |> List.map(Orbit64.Move.notation) |> List.join(" ")

    def facesAt(value: Int32): List[Face] = match value {
        case 0  => Face.U :: Face.R :: Face.F :: Face.D :: Face.L :: Face.B :: Nil
        case 1  => Face.U :: Face.B :: Face.R :: Face.D :: Face.F :: Face.L :: Nil
        case 2  => Face.U :: Face.L :: Face.B :: Face.D :: Face.R :: Face.F :: Nil
        case 3  => Face.U :: Face.F :: Face.L :: Face.D :: Face.B :: Face.R :: Nil
        case 4  => Face.F :: Face.R :: Face.D :: Face.B :: Face.L :: Face.U :: Nil
        case 5  => Face.F :: Face.U :: Face.R :: Face.B :: Face.D :: Face.L :: Nil
        case 6  => Face.F :: Face.L :: Face.U :: Face.B :: Face.R :: Face.D :: Nil
        case 7  => Face.F :: Face.D :: Face.L :: Face.B :: Face.U :: Face.R :: Nil
        case 8  => Face.D :: Face.R :: Face.B :: Face.U :: Face.L :: Face.F :: Nil
        case 9  => Face.D :: Face.F :: Face.R :: Face.U :: Face.B :: Face.L :: Nil
        case 10 => Face.D :: Face.L :: Face.F :: Face.U :: Face.R :: Face.B :: Nil
        case 11 => Face.D :: Face.B :: Face.L :: Face.U :: Face.F :: Face.R :: Nil
        case 12 => Face.B :: Face.R :: Face.U :: Face.F :: Face.L :: Face.D :: Nil
        case 13 => Face.B :: Face.D :: Face.R :: Face.F :: Face.U :: Face.L :: Nil
        case 14 => Face.B :: Face.L :: Face.D :: Face.F :: Face.R :: Face.U :: Nil
        case 15 => Face.B :: Face.U :: Face.L :: Face.F :: Face.D :: Face.R :: Nil
        case 16 => Face.L :: Face.U :: Face.F :: Face.R :: Face.D :: Face.B :: Nil
        case 17 => Face.L :: Face.B :: Face.U :: Face.R :: Face.F :: Face.D :: Nil
        case 18 => Face.L :: Face.D :: Face.B :: Face.R :: Face.U :: Face.F :: Nil
        case 19 => Face.L :: Face.F :: Face.D :: Face.R :: Face.B :: Face.U :: Nil
        case 20 => Face.R :: Face.D :: Face.F :: Face.L :: Face.U :: Face.B :: Nil
        case 21 => Face.R :: Face.B :: Face.D :: Face.L :: Face.F :: Face.U :: Nil
        case 22 => Face.R :: Face.U :: Face.B :: Face.L :: Face.D :: Face.F :: Nil
        case _  => Face.R :: Face.F :: Face.U :: Face.L :: Face.B :: Face.D :: Nil
    }

}
