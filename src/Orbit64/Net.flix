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
/// One caveat applies at every size, the two drawn here included: the picture
/// assumes whoever produced the token numbered their slots the way Kociemba
/// does. A token does not say. Neither can the checked-in test vectors settle
/// it -- relabelling slots and pieces by any bijection conjugates every
/// permutation, and conjugation preserves cycle structure, permutation parity
/// and the orientation sums, so no property of the arrays tells one labelling
/// from another. The vectors pin this codec's arithmetic exactly and carry no
/// geometry at all.
///
/// The 2x2x2 through 5x5x5 are drawn, each under a convention `convention`
/// will name.
///
/// `kociemba-3x3x3` covers corners and edges. `twizzle-4x4x4@baa0685` covers
/// the 4x4x4: that definition holds no facelets -- KPuzzle describes state and
/// moves, not stickers -- so its tables were not transcribed but solved for, as
/// the one correspondence between its slot indices and a physical cube that
/// reproduces its move permutations. The answer is unique, survives moves the
/// solver never saw, and agrees with the definition's own default pattern.
///
/// `orbit64-5x5-draft@1` covers the 5x5x5. It keeps Kociemba's corner and midge
/// numbering, so a 5x5x5 reads as a 3x3x3 with more orbits, and derives its
/// wings and both centre orbits the same way from the twsearch 5x5x5 move
/// model -- whose SPEFFZ orbits turn out to be sticker orbits: 1 and 3 the two
/// wing sticker orbits, 2 the X-centres, 4 the plus-centres, 5 the midges.
///
/// `draft` says the geometry is internally verified, not that anything else
/// speaks it. Twizzle cannot: its 5x5x5 is named `5x5x5_temp`, decomposes at
/// sticker level with no orientation anywhere, and tracks the six fixed centres
/// this format omits. But it is not true that nothing does -- `cube-solvers`'
/// cube555 engine carries an oriented `mEdge[12]`, a distinct `wEdge[24]`, and
/// `xCenter[24]` and `tCenter[24]`, which is this same decomposition arrived at
/// independently. Its slot order differs from this one, and it lists the
/// plus-centres before the X-centres, so the two are not interchangeable
/// array for array. Facelets are the layer where they meet.
///
/// The 6x6x6 and up are not drawn.
///
///
mod Orbit64.Net {

    use Orbit64.Coord.Coord
    use Orbit64.Coord.Coord.{CornerCoord, MidgeCoord, WingCoord, CenterCoord}

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

    // ---------- the 4x4x4 tables, derived rather than transcribed ----------
    //
    // Generated by solving for the correspondence between the twsearch
    // 4x4x4 KPuzzle definition and a physical model: the mapping is the
    // unique one reproducing that definition's own move permutations, and
    // it was checked against moves the solver never saw.

    def cornerFacelet4(): Vector[Vector[Int32]] = Vector#{
            Vector#{3, 80, 19},
            Vector#{15, 16, 35},
            Vector#{12, 32, 67},
            Vector#{0, 64, 83},
            Vector#{63, 31, 92},
            Vector#{60, 95, 76},
            Vector#{48, 79, 44},
            Vector#{51, 47, 28}
        }

    def wingFacelet4(): Vector[Vector[Int32]] = Vector#{
            Vector#{33, 13},
            Vector#{17, 11},
            Vector#{81, 2},
            Vector#{65, 4},
            Vector#{8, 66},
            Vector#{87, 68},
            Vector#{56, 77},
            Vector#{40, 75},
            Vector#{1, 82},
            Vector#{23, 84},
            Vector#{62, 93},
            Vector#{72, 91},
            Vector#{7, 18},
            Vector#{39, 20},
            Vector#{55, 29},
            Vector#{88, 27},
            Vector#{14, 34},
            Vector#{71, 36},
            Vector#{49, 45},
            Vector#{24, 43},
            Vector#{94, 61},
            Vector#{30, 59},
            Vector#{46, 50},
            Vector#{78, 52}
        }

    def centreFacelet4(): Vector[Int32] = Vector#{9, 10, 6, 5, 70, 69, 73, 74, 86, 85, 89, 90, 22, 21, 25, 26, 38, 37, 41, 42, 57, 58, 54, 53}

    def cornerColour4(): Vector[Vector[Int32]] = Vector#{
            Vector#{0, 5, 1},
            Vector#{0, 1, 2},
            Vector#{0, 2, 4},
            Vector#{0, 4, 5},
            Vector#{3, 1, 5},
            Vector#{3, 5, 4},
            Vector#{3, 4, 2},
            Vector#{3, 2, 1}
        }

    def wingColour4(): Vector[Vector[Int32]] = Vector#{
            Vector#{2, 0},
            Vector#{1, 0},
            Vector#{5, 0},
            Vector#{4, 0},
            Vector#{0, 4},
            Vector#{5, 4},
            Vector#{3, 4},
            Vector#{2, 4},
            Vector#{0, 5},
            Vector#{1, 5},
            Vector#{3, 5},
            Vector#{4, 5},
            Vector#{0, 1},
            Vector#{2, 1},
            Vector#{3, 1},
            Vector#{5, 1},
            Vector#{0, 2},
            Vector#{4, 2},
            Vector#{3, 2},
            Vector#{1, 2},
            Vector#{5, 3},
            Vector#{1, 3},
            Vector#{2, 3},
            Vector#{4, 3}
        }

    def centreColour4(): Vector[Int32] = Vector#{0, 4, 5, 1, 2, 3}

    // ---------- the 5x5x5 tables ----------
    //
    // Corners and midges keep Kociemba's numbering, so a 5x5x5 reads as a
    // 3x3x3 with more orbits. The wings and both centre orbits are derived
    // from the twsearch 5x5x5 move model, whose SPEFFZ orbits turn out to be
    // sticker orbits: 1 and 3 are the two wing sticker orbits, 2 the
    // X-centres, 4 the plus-centres, 5 the midges.

    def cornerFacelet5(): Vector[Vector[Int32]] = Vector#{
            Vector#{24, 25, 54},
            Vector#{20, 50, 104},
            Vector#{0, 100, 129},
            Vector#{4, 125, 29},
            Vector#{79, 74, 45},
            Vector#{75, 124, 70},
            Vector#{95, 149, 120},
            Vector#{99, 49, 145}
        }

    def cornerColour5(): Vector[Vector[Int32]] = Vector#{
            Vector#{0, 1, 2},
            Vector#{0, 2, 4},
            Vector#{0, 4, 5},
            Vector#{0, 5, 1},
            Vector#{3, 2, 1},
            Vector#{3, 4, 2},
            Vector#{3, 5, 4},
            Vector#{3, 1, 5}
        }

    def midgeFacelet5(): Vector[Vector[Int32]] = Vector#{
            Vector#{14, 27},
            Vector#{22, 52},
            Vector#{10, 102},
            Vector#{2, 127},
            Vector#{89, 47},
            Vector#{77, 72},
            Vector#{85, 122},
            Vector#{97, 147},
            Vector#{64, 35},
            Vector#{60, 114},
            Vector#{139, 110},
            Vector#{135, 39}
        }

    def midgeColour5(): Vector[Vector[Int32]] = Vector#{
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

    def wingFacelet5(): Vector[Vector[Int32]] = Vector#{
            Vector#{9, 28},
            Vector#{1, 128},
            Vector#{15, 103},
            Vector#{23, 53},
            Vector#{34, 130},
            Vector#{26, 19},
            Vector#{40, 69},
            Vector#{48, 94},
            Vector#{59, 30},
            Vector#{51, 21},
            Vector#{65, 119},
            Vector#{73, 78},
            Vector#{109, 55},
            Vector#{101, 5},
            Vector#{115, 144},
            Vector#{123, 80},
            Vector#{134, 105},
            Vector#{126, 3},
            Vector#{140, 44},
            Vector#{148, 96},
            Vector#{84, 46},
            Vector#{76, 71},
            Vector#{90, 121},
            Vector#{98, 146}
        }

    def wingColour5(): Vector[Vector[Int32]] = Vector#{
            Vector#{0, 1},
            Vector#{0, 5},
            Vector#{0, 4},
            Vector#{0, 2},
            Vector#{1, 5},
            Vector#{1, 0},
            Vector#{1, 2},
            Vector#{1, 3},
            Vector#{2, 1},
            Vector#{2, 0},
            Vector#{2, 4},
            Vector#{2, 3},
            Vector#{4, 2},
            Vector#{4, 0},
            Vector#{4, 5},
            Vector#{4, 3},
            Vector#{5, 4},
            Vector#{5, 0},
            Vector#{5, 1},
            Vector#{5, 3},
            Vector#{3, 1},
            Vector#{3, 2},
            Vector#{3, 4},
            Vector#{3, 5}
        }

    /// The X-centres -- the four diagonal cells of each face's centre block.
    def xFacelet5(): Vector[Int32] = Vector#{8, 6, 16, 18, 33, 31, 41, 43, 58, 56, 66, 68, 108, 106, 116, 118, 133, 131, 141, 143, 83, 81, 91, 93}

    /// The plus-centres -- the four edge-adjacent cells.
    def plusFacelet5(): Vector[Int32] = Vector#{7, 11, 17, 13, 32, 36, 42, 38, 57, 61, 67, 63, 107, 111, 117, 113, 132, 136, 142, 138, 82, 86, 92, 88}

    /// Both centre orbits share one colour-to-face map.
    def centreColour5(): Vector[Int32] = Vector#{0, 1, 2, 4, 5, 3}

    /// The six single centres, which the format leaves out because they fix the
    /// frame of reference rather than carry information.
    def fixedFacelet5(): Vector[Int32] = Vector#{12, 37, 62, 87, 112, 137}

    ///
    /// The name of the slot convention `draw` assumes at size `n`.
    ///
    /// A token stores ordinals and no geometry, so a picture is only correct if
    /// its producer numbered slots the way this reads them. Naming the
    /// assumption is the difference between a silently wrong picture and a
    /// disagreement someone can trace.
    ///
    pub def convention(n: Int32): String = match n {
        case 2 => "kociemba-corners"
        case 3 => "kociemba-3x3x3"
        case 4 => "twizzle-4x4x4@baa0685"
        case 5 => "orbit64-5x5-draft@1"
        case _ => "none for the ${n}x${n}x${n}"
    }

    ///
    /// The net for `orbits`, or `None` for a size this module cannot draw or a
    /// state that is not a cube.
    ///
    /// `colour` false gives plain letters, for pipes and for `NO_COLOR`.
    ///
    ///
    /// Every facelet index the tables for size `n` write to, in no order.
    ///
    /// These tables are hand-derived, and the failure they invite is a
    /// duplicated or omitted index -- which a scramble fixture can miss, since
    /// a doubly-written facelet still holds a plausible colour. A caller that
    /// wants to check them can count instead: this should hold `6 * n * n`
    /// entries, all distinct. `None` for a size with no tables, and for the
    /// 2x2x2, which borrows the 3x3x3's.
    ///
    pub def writtenFacelets(n: Int32): Option[Vector[Int32]] =
        let flat = xss -> Vector.flatten(xss);
        match n {
            case 3 => Some(Vector.append(
                        Vector.append(flat(cornerFacelet()), flat(edgeFacelet())),
                        Vector.range(0, 6) |> Vector.map(i -> i * 9 + 4)))
            case 4 => Some(Vector.append(
                        Vector.append(flat(cornerFacelet4()), flat(wingFacelet4())),
                        centreFacelet4()))
            case 5 => Some(
                        Vector.append(flat(cornerFacelet5()),
                        Vector.append(flat(midgeFacelet5()),
                        Vector.append(flat(wingFacelet5()),
                        Vector.append(xFacelet5(),
                        Vector.append(plusFacelet5(), fixedFacelet5()))))))
            case _ => None
        }

    ///
    /// Whether this module has a slot convention for an `n x n x n`.
    ///
    /// Separate from `draw` because "there is no convention for a 6x6x6" and
    /// "these orbits are not a cube" are different answers, and a caller that
    /// wants to know which without building a state should not have to guess
    /// from `n`.
    ///
    pub def canDraw(n: Int32): Bool = n >= 2 and n <= 5

    ///
    /// The cube's stickers, as `6 * n * n` face indices.
    ///
    /// Facelet `face * n * n + row * n + col`, faces `U R F D L B` numbered 0
    /// to 5, row-major within a face -- the layout `flix-cube`'s `BigCube` and
    /// `cube-solvers`' `Facelets` both use, which is what makes this the layer
    /// those projects and this one can meet at. Slot orders differ between
    /// implementations and always will; sticker colours do not.
    ///
    /// Subject to the same convention `draw` names, and the same caveat: this
    /// says what the state looks like *if* its producer numbered slots the way
    /// `convention(n)` says. It is a rendering, not a proof of agreement.
    ///
    pub def toFacelets(n: Int32, orbits: List[Coord]): Result[String, Vector[Int32]] =
        let expected = Orbit64.Orbit.layout(n);
        let got = List.map(Orbit64.Coord.kind, orbits);
        if (not canDraw(n))
            Err("no slot convention for the ${n}x${n}x${n}: this module has one "
                + "only up to the 5x5x5")
        // Each orbit being individually valid is not enough. A list that is
        // short, reordered, or carries an orbit this size does not have leaves
        // stickers nothing ever writes to, and the result would be a tidy
        // picture of a cube that does not exist.
        else if (got != expected)
            Err("expected orbits ${expected} for the ${n}x${n}x${n}, got ${got}")
        // A slot-to-facelet table is indexed by the piece sitting in a slot, so
        // a permutation with an entry outside its orbit reads off the end of
        // one. Everything `decode` produces is a genuine permutation, but this
        // is public and a hand-built coordinate is not.
        else if (List.exists(c -> not Orbit64.Coord.isValid(c), orbits))
            Err("that state is not a cube")
        else if (n == 4) Ok(facelets4(orbits))
        else if (n == 5)
            match facelets5(orbits) {
                case Some(fs) => Ok(fs)
                // Unreachable: the layout check above already fixed the shape.
                case None     => Err("expected orbits ${expected} for the ${n}x${n}x${n}")
            }
        else Ok(facelets3(n, orbits))

    ///
    /// The net for `orbits`, or why there isn't one.
    ///
    pub def draw(n: Int32, orbits: List[Coord], colour: Bool): Result[String, String] =
        toFacelets(n, orbits)
            |> Result.map(fs -> render(n, fs, colour))

    ///
    /// The 2x2x2 and 3x3x3, whose tables are Kociemba's.
    ///
    /// A 2x2x2 is built on the 3x3x3's grid and then thinned to its corner
    /// cells, which are exactly its four stickers per face.
    ///
    def facelets3(n: Int32, orbits: List[Coord]): Vector[Int32] =
        region rc {
            // Centres never move, so they are the frame the rest is drawn in.
            let sticker = Array.repeat(rc, 54, 0);
            Vector.range(0, 6) |> Vector.forEach(i -> Array.put(i, i * 9 + 4, sticker));
            orbits |> List.forEach(c -> match c {
                case CornerCoord(cp, co) => placeCorners(sticker, cp, co)
                case MidgeCoord(ep, eo)  => placeEdges(sticker, ep, eo)
                case _                   => ()
            });
            let full = Array.toVector(sticker);
            if (n == 3) full
            else Vector.init(i -> {
                let face = i / 4;
                let r = Int32.modulo(i / 2, 2);
                let c = Int32.modulo(i, 2);
                Vector.get(face * 9 + (r * 2) * 3 + c * 2, full)
            }, 24)
        }

    ///
    /// A 5x5x5, drawn under `orbit64-5x5-draft@1`.
    ///
    /// The two `CenterCoord`s are told apart by list position, which is the
    /// only thing that distinguishes them: `Orbit.layout` yields
    /// `Corners, Midges, Wings, Centers, Centers`, and this convention fixes
    /// the fourth as the X-centres and the fifth as the plus-centres. Matching
    /// the whole list rather than each element is what makes that explicit.
    ///
    def facelets5(orbits: List[Coord]): Option[Vector[Int32]] =
        match orbits {
            case CornerCoord(cp, co) :: MidgeCoord(ep, eo) :: WingCoord(wp) ::
                 CenterCoord(xs) :: CenterCoord(ps) :: Nil =>
                region rc {
                    let sticker = Array.repeat(rc, 150, 0);
                    // The six single centres are not in the token; they are the frame.
                    Vector.range(0, 6) |> Vector.forEach(f ->
                        Array.put(f, Vector.get(f, fixedFacelet5()), sticker));
                    Vector.range(0, 8) |> Vector.forEach(slot ->
                        Vector.range(0, 3) |> Vector.forEach(k -> {
                            let at  = Vector.get(k, Vector.get(slot, cornerFacelet5()));
                            let col = Vector.get(Int32.modulo(k - Vector.get(slot, co) + 3, 3),
                                                 Vector.get(Vector.get(slot, cp), cornerColour5()));
                            Array.put(col, at, sticker)
                        }));
                    Vector.range(0, 12) |> Vector.forEach(slot ->
                        Vector.range(0, 2) |> Vector.forEach(k -> {
                            let at  = Vector.get(k, Vector.get(slot, midgeFacelet5()));
                            let col = Vector.get(Int32.modulo(k - Vector.get(slot, eo) + 2, 2),
                                                 Vector.get(Vector.get(slot, ep), midgeColour5()));
                            Array.put(col, at, sticker)
                        }));
                    Vector.range(0, 24) |> Vector.forEach(slot ->
                        Vector.range(0, 2) |> Vector.forEach(k -> {
                            let at  = Vector.get(k, Vector.get(slot, wingFacelet5()));
                            let col = Vector.get(k, Vector.get(Vector.get(slot, wp), wingColour5()));
                            Array.put(col, at, sticker)
                        }));
                    Vector.range(0, 24) |> Vector.forEach(slot -> {
                        Array.put(Vector.get(Vector.get(slot, xs), centreColour5()),
                                  Vector.get(slot, xFacelet5()), sticker);
                        Array.put(Vector.get(Vector.get(slot, ps), centreColour5()),
                                  Vector.get(slot, plusFacelet5()), sticker)
                    });
                    Some(Array.toVector(sticker))
                }
            case _ => None
        }

    ///
    /// A 4x4x4 has no piece that never moves, so every one of its 96 stickers
    /// comes from the token. An orbit this convention has no table for is left
    /// alone rather than guessed at.
    ///
    def facelets4(orbits: List[Coord]): Vector[Int32] =
        region rc {
            let sticker = Array.repeat(rc, 96, 0);
            orbits |> List.forEach(c -> match c {
                case CornerCoord(cp, co) =>
                    Vector.range(0, 8) |> Vector.forEach(slot ->
                        Vector.range(0, 3) |> Vector.forEach(k -> {
                            let at  = Vector.get(k, Vector.get(slot, cornerFacelet4()));
                            let ori = Vector.get(slot, co);
                            let col = Vector.get(Int32.modulo(k - ori + 3, 3),
                                                 Vector.get(Vector.get(slot, cp), cornerColour4()));
                            Array.put(col, at, sticker)
                        }))
                case WingCoord(wp) =>
                    Vector.range(0, 24) |> Vector.forEach(slot ->
                        Vector.range(0, 2) |> Vector.forEach(k -> {
                            let at  = Vector.get(k, Vector.get(slot, wingFacelet4()));
                            let col = Vector.get(k, Vector.get(Vector.get(slot, wp), wingColour4()));
                            Array.put(col, at, sticker)
                        }))
                case CenterCoord(cols) =>
                    Vector.range(0, 24) |> Vector.forEach(slot -> {
                        let at  = Vector.get(slot, centreFacelet4());
                        let col = Vector.get(Vector.get(slot, cols), centreColour4());
                        Array.put(col, at, sticker)
                    })
                case _ => ()
            });
            Array.toVector(sticker)
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
    /// `side` is the grid the stickers are stored on and `n` the cube being
    /// drawn. They differ only for the 2x2x2, which reuses the 3x3x3 grid by
    /// taking every other cell -- its four stickers are exactly the corner
    /// cells of a 3x3x3 face.
    ///
    def render(n: Int32, sticker: Vector[Int32], colour: Bool): String =
        let cell = (face, row, col) -> Vector.get(face * n * n + row * n + col, sticker);
        let band = (face, row) -> Vector.range(0, n)
            |> Vector.map(col -> paint(cell(face, row, col), colour))
            |> Vector.join("");
        // One sticker of gutter between faces, and a blank row between the
        // bands. Without it the six blocks read as one dense rectangle and the
        // face boundaries have to be counted rather than seen.
        let gap = "   ";
        let pad = String.repeat(n * 3 + 3, " ");
        let blank = Vector#{""};
        let top = Vector.range(0, n) |> Vector.map(r -> "${pad}${band(0, r)}");
        let mid = Vector.range(0, n) |> Vector.map(r ->
            "${band(4, r)}${gap}${band(2, r)}${gap}${band(1, r)}${gap}${band(5, r)}");
        let bot = Vector.range(0, n) |> Vector.map(r -> "${pad}${band(3, r)}");
        Vector.append(top, Vector.append(blank, Vector.append(mid,
            Vector.append(blank, bot)))) |> Vector.join("\n")

    def paint(face: Int32, colour: Bool): String =
        let letter = Vector.get(face, faces());
        if (not colour) " ${letter} "
        else
            let bg = Vector.get(face, colours());
            "\u001b[48;5;${bg}m\u001b[38;5;16m ${letter} \u001b[0m"

}
