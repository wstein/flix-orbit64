/// Whole-cube reference frames in canonical `U R F D L B` slot order.
///
/// A frame says which physical face occupies each Orbit64 reference slot. The
/// 24 right-handed cube orientations are ranked by their `U` face, then a
/// deterministic adjacent `F` face order. Geometry that applies a frame to cubie
/// coordinates belongs in a later layer; this module only defines its compact,
/// deterministic vocabulary.
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

    /// The physical faces occupying the reference slots `U R F D L B`.
    pub def faces(frame: Frame): List[Face] = match frame {
        case Frame.Frame(value) =>
            let up = faceAt(value / 4);
            let offset = value - (value / 4) * 4;
            let front = frontAt(up, offset);
            let right = rightAt(up, offset);
            up :: right :: front :: opposite(up) :: opposite(right) :: opposite(front) :: Nil
    }

    /// Render `faces(frame)` in compact spaced WCA notation.
    pub def notation(frame: Frame): String =
        faces(frame) |> List.map(Orbit64.Move.notation) |> List.join(" ")

    /// The four faces adjacent to `up`. The first choice makes frame zero the
    /// canonical `U R F D L B` reference list.
    def fronts(up: Face): List[Face] = match up {
        case Face.U => Face.F :: Face.R :: Face.B :: Face.L :: Nil
        case Face.R => Face.U :: Face.F :: Face.D :: Face.B :: Nil
        case Face.F => Face.U :: Face.R :: Face.D :: Face.L :: Nil
        case Face.D => Face.F :: Face.R :: Face.B :: Face.L :: Nil
        case Face.L => Face.U :: Face.F :: Face.D :: Face.B :: Nil
        case Face.B => Face.U :: Face.R :: Face.D :: Face.L :: Nil
    }

    def faceAt(index: Int32): Face =
        Orbit64.Move.faces() |> List.drop(index) |> List.head |> Option.getWithDefault(Face.U)

    def frontAt(up: Face, index: Int32): Face =
        fronts(up) |> List.drop(index) |> List.head |> Option.getWithDefault(Face.F)

    /// The physical `R` face paired with each choice in `fronts(up)`. The
    /// aligned tables embody `right = up × front` without a 24-case branch.
    def rights(up: Face): List[Face] = match up {
        case Face.U => Face.R :: Face.B :: Face.L :: Face.F :: Nil
        case Face.R => Face.F :: Face.D :: Face.B :: Face.U :: Nil
        case Face.F => Face.L :: Face.U :: Face.R :: Face.D :: Nil
        case Face.D => Face.L :: Face.F :: Face.R :: Face.B :: Nil
        case Face.L => Face.B :: Face.U :: Face.F :: Face.D :: Nil
        case Face.B => Face.R :: Face.D :: Face.L :: Face.U :: Nil
    }

    def rightAt(up: Face, index: Int32): Face =
        rights(up) |> List.drop(index) |> List.head |> Option.getWithDefault(Face.R)

    def opposite(face: Face): Face = match face {
        case Face.U => Face.D
        case Face.R => Face.L
        case Face.F => Face.B
        case Face.D => Face.U
        case Face.L => Face.R
        case Face.B => Face.F
    }

}
