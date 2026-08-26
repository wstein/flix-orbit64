///
/// Draws a decoded cube as a net.
///
/// A token carries every *movable* piece and nothing besides. An odd cube's six
/// fixed centres are deliberately outside the format -- they never move
/// relative to one another, so they fix the frame of reference rather than
/// carry information -- which means this module has to supply them itself
/// before it can draw anything. They are the first thing `draw` puts down.
///
/// This is the only module in the package that knows a cube has faces. The
/// codec is pure arithmetic in `n` and defines no geometry whatsoever, which is
/// exactly what lets it cover every size from the 2x2x2 up -- but a picture
/// needs to know which slot sits where, so this module supplies a convention
/// rather than inventing one: the corner and edge numbering from Kociemba's
/// solver, the same convention the pattern tokens in the README use. A model
/// that numbers its slots differently will draw a different picture from the
/// same token, and neither picture is wrong.
///
/// Only the 2x2x2 and 3x3x3 are drawn. Corners and edges have Kociemba's
/// numbering to borrow; from the 4x4x4 up, every wing and centre orbit needs a
/// mapping of its own -- two wing and six centre orbits on a 7x7x7 -- or one
/// mapping parameterised by `n`.
///
/// Such conventions do exist: KPuzzle describes named orbits as indexed
/// permutations and orientations, and Twizzle Search publishes concrete
/// definitions whose 4x4x4 orbits (`CORNERS`, `WINGS`, `CENTERS`) match this
/// codec's structurally. What does not exist is one *guaranteed to agree with
/// the slot order these vectors already use*, and the checked-in test vectors
/// carry no geometry that could settle it either way. Adopting a convention
/// therefore means first obtaining the reference generator's mapping, or
/// writing an explicit conversion into the adopted one -- not merely picking
/// a table.
///
mod Orbit64.Net {

    use Orbit64.Coord.Coord
    use Orbit64.Coord.Coord.{CornerCoord, MidgeCoord}

    ///
    /// Face letters in `URFDLB` order, which is also the order the 54 facelet
    /// indices run in: `U1..U9` is `0..8`, `R1..R9` is `9..17`, and so on.
    ///
    def faces(): Vector[String] = Vector#{"U", "R", "F", "D", "L", "B"}

    ///
    /// xterm-256 background colours for those faces. Orange has no place in the
    /// sixteen-colour palette, which is why this uses the 256-colour one.
    ///
    def colours(): Vector[Int32] = Vector#{15, 196, 46, 226, 208, 21}

    /// Facelets of each corner slot, the first being the one orientation counts from.
    def cornerFacelet(): Vector[Vector[Int32]] = Vector#{
            Vector#{8, 9, 20},
            Vector#{6, 18, 38},
            Vector#{0, 36, 47},
            Vector#{2, 45, 11},
            Vector#{29, 26, 15},
            Vector#{27, 44, 24},
            Vector#{33, 53, 42},
            Vector#{35, 17, 51}
        }

    /// Facelets of each edge slot, likewise.
    def edgeFacelet(): Vector[Vector[Int32]] = Vector#{
            Vector#{5, 10},
            Vector#{7, 19},
            Vector#{3, 37},
            Vector#{1, 46},
            Vector#{32, 16},
            Vector#{28, 25},
            Vector#{30, 43},
            Vector#{34, 52},
            Vector#{23, 12},
            Vector#{21, 41},
            Vector#{50, 39},
            Vector#{48, 14}
        }

    /// Face colours of each corner piece, clockwise from its orientation facelet.
    def cornerColor(): Vector[Vector[Int32]] = Vector#{
            Vector#{0, 1, 2},
            Vector#{0, 2, 4},
            Vector#{0, 4, 5},
            Vector#{0, 5, 1},
            Vector#{3, 2, 1},
            Vector#{3, 4, 2},
            Vector#{3, 5, 4},
            Vector#{3, 1, 5}
        }

    /// Face colours of each edge piece.
    def edgeColor(): Vector[Vector[Int32]] = Vector#{
            Vector#{0, 1},
            Vector#{0, 2},
            Vector#{0, 4},
            Vector#{0, 5},
            Vector#{3, 1},
            Vector#{3, 2},
            Vector#{3, 4},
            Vector#{3, 5},
            Vector#{2, 1},
            Vector#{2, 4},
            Vector#{5, 4},
            Vector#{5, 1}
        }

    ///
    /// The net for `orbits`, or `None` for a size this module cannot draw.
    ///
    /// `colour` false gives plain letters, for pipes and for `NO_COLOR`.
    ///
    pub def draw(n: Int32, orbits: List[Coord], colour: Bool): Option[String] =
        if (n != 2 and n != 3) None
        else
            region rc {
                // Centres never move, so they are the frame the rest is drawn in.
                let sticker = Array.repeat(rc, 54, 0);
                Vector.range(0, 6) |> Vector.forEach(i -> Array.put(i, i * 9 + 4, sticker));
                orbits |> List.forEach(c -> match c {
                    case CornerCoord(cp, co) => placeCorners(sticker, cp, co)
                    case MidgeCoord(ep, eo)  => placeEdges(sticker, ep, eo)
                    case _                   => ()
                });
                Some(render(n, Array.toVector(sticker), colour))
            }

    def placeCorners(sticker: Array[Int32, r], cp: Vector[Int32], co: Vector[Int32]): Unit \ r =
        Vector.range(0, 8) |> Vector.forEach(slot ->
            Vector.range(0, 3) |> Vector.forEach(k -> {
                let twist = Int32.modulo(k + Vector.get(slot, co), 3);
                let at    = Vector.get(twist, Vector.get(slot, cornerFacelet()));
                let col   = Vector.get(k, Vector.get(Vector.get(slot, cp), cornerColor()));
                Array.put(col, at, sticker)
            }))

    def placeEdges(sticker: Array[Int32, r], ep: Vector[Int32], eo: Vector[Int32]): Unit \ r =
        Vector.range(0, 12) |> Vector.forEach(slot ->
            Vector.range(0, 2) |> Vector.forEach(k -> {
                let flip = Int32.modulo(k + Vector.get(slot, eo), 2);
                let at   = Vector.get(flip, Vector.get(slot, edgeFacelet()));
                let col  = Vector.get(k, Vector.get(Vector.get(slot, ep), edgeColor()));
                Array.put(col, at, sticker)
            }))

    ///
    /// Lay the six faces out flat, `U` above `L F R B` above `D`.
    ///
    /// A 2x2x2 reuses the 3x3x3 grid by taking every other cell, since its four
    /// stickers are exactly the corner cells of a 3x3x3 face.
    ///
    def render(n: Int32, sticker: Vector[Int32], colour: Bool): String =
        let step = if (n == 3) 1 else 2;
        let cell = (face, row, col) ->
            Vector.get(face * 9 + (row * step) * 3 + col * step, sticker);
        let band = (face, row) -> Vector.range(0, n)
            |> Vector.map(col -> paint(cell(face, row, col), colour))
            |> Vector.join("");
        let pad = String.repeat(n * 3, " ");
        let top = Vector.range(0, n) |> Vector.map(r -> "${pad}${band(0, r)}");
        let mid = Vector.range(0, n) |> Vector.map(r ->
            "${band(4, r)}${band(2, r)}${band(1, r)}${band(5, r)}");
        let bot = Vector.range(0, n) |> Vector.map(r -> "${pad}${band(3, r)}");
        Vector.append(top, Vector.append(mid, bot)) |> Vector.join("\n")

    def paint(face: Int32, colour: Bool): String =
        let letter = Vector.get(face, faces());
        if (not colour) " ${letter} "
        else
            let bg = Vector.get(face, colours());
            "\u001b[48;5;${bg}m\u001b[38;5;16m ${letter} \u001b[0m"

}
