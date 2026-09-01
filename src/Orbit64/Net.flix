///
/// Draws a decoded cube as a net, and reads one back out of its facelets.
///
/// A token carries every *movable* piece and nothing besides. An odd cube's six
/// fixed centres are deliberately outside the format -- they never move
/// relative to one another, so they fix the frame of reference rather than
/// carry information -- which means this module supplies them itself before it
/// can draw anything. They are the first thing `draw` puts down.
///
/// This is the only module in the package that knows a cube has faces. The
/// codec is pure arithmetic in `n` and defines no geometry whatsoever, which is
/// exactly what lets it cover every size from the 2x2x2 up. A picture needs to
/// know which slot sits where, so this module supplies a convention and
/// `convention` names it.
///
/// One set of tables serves both directions. `toFacelets` writes a state out as
/// stickers and `fromFacelets` reads one back in, which is what lets a project
/// carrying a cube engine of its own both consume and produce tokens without
/// ever restating the slot convention -- the one thing it could not restate
/// correctly without copying these tables.
///
/// Every table below is derived from cube geometry alone. No other project's
/// puzzle definition is read, which keeps this Apache-2.0 package clear of the
/// GPL sources that describe the same shapes. The derivation takes three
/// inputs -- a cube is n^3 cubies, a face turn rotates a layer, and a facelet is
/// `face * n * n + row * n + col` over `U R F D L B` -- and the rest follows:
///
///   corners   the standard URF UFL ULB UBR DFR DLF DBL DRB
///   midges    the standard UR UF UL UB DR DF DL DB FR FL BL BR
///   wings     by the facelet index of the piece's reference sticker
///   centres   by facelet index, each orbit separately
///
/// Orientation counts clockwise seen from outside: for a corner from its U or D
/// facelet, for a midge from U or D where it has one and F or B otherwise. A
/// wing carries no orientation, and its reference sticker is the one in the
/// first chirality class -- a wing cannot be flipped in place, so its 48
/// stickers fall into two orbits of 24, and that picks the reference without
/// anyone choosing.
///
/// Ordering wings and centres by facelet index makes slot order a consequence
/// of the facelet layout rather than a second thing to agree on. It also makes
/// a centre's colour index its face index, so a solved cube is
/// `0 0 0 0 1 1 1 1 ...` with no lookup in between.
///
/// The 3x3x3 tables come out as the ones in wide use. That is not borrowing:
/// given the standard facelet numbering and the standard piece names there is
/// exactly one right answer, and deriving it from geometry reproduces those
/// values bit for bit.
///
/// One caveat applies at every size: the picture assumes whoever produced the
/// token numbered their slots the way `convention(n)` says. A token does not
/// say, and the checked-in test vectors cannot settle it -- relabelling slots
/// and pieces by any bijection conjugates every permutation, and conjugation
/// preserves cycle structure, permutation parity and the orientation sums, so
/// no property of the arrays tells one labelling from another.
///
/// The 6x6x6 and up are neither drawn nor read.
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

    // ---------- the 4x4x4 tables ----------
    //
    // Corners in the standard order; wings and centres by facelet index.

    def cornerFacelet4(): Vector[Vector[Int32]] = Vector#{
            Vector#{15, 16, 35},
            Vector#{12, 32, 67},
            Vector#{0, 64, 83},
            Vector#{3, 80, 19},
            Vector#{51, 47, 28},
            Vector#{48, 79, 44},
            Vector#{60, 95, 76},
            Vector#{63, 31, 92}
        }

    def wingFacelet4(): Vector[Vector[Int32]] = Vector#{
            Vector#{1, 82},
            Vector#{7, 18},
            Vector#{8, 66},
            Vector#{14, 34},
            Vector#{17, 11},
            Vector#{23, 84},
            Vector#{24, 43},
            Vector#{30, 59},
            Vector#{33, 13},
            Vector#{39, 20},
            Vector#{40, 75},
            Vector#{46, 50},
            Vector#{49, 45},
            Vector#{55, 29},
            Vector#{56, 77},
            Vector#{62, 93},
            Vector#{65, 4},
            Vector#{71, 36},
            Vector#{72, 91},
            Vector#{78, 52},
            Vector#{81, 2},
            Vector#{87, 68},
            Vector#{88, 27},
            Vector#{94, 61}
        }

    def centreFacelet4(): Vector[Int32] = Vector#{5, 6, 9, 10, 21, 22, 25, 26, 37, 38, 41, 42, 53, 54, 57, 58, 69, 70, 73, 74, 85, 86, 89, 90}

    def cornerColour4(): Vector[Vector[Int32]] = Vector#{
            Vector#{0, 1, 2},
            Vector#{0, 2, 4},
            Vector#{0, 4, 5},
            Vector#{0, 5, 1},
            Vector#{3, 2, 1},
            Vector#{3, 4, 2},
            Vector#{3, 5, 4},
            Vector#{3, 1, 5}
        }

    def wingColour4(): Vector[Vector[Int32]] = Vector#{
            Vector#{0, 5},
            Vector#{0, 1},
            Vector#{0, 4},
            Vector#{0, 2},
            Vector#{1, 0},
            Vector#{1, 5},
            Vector#{1, 2},
            Vector#{1, 3},
            Vector#{2, 0},
            Vector#{2, 1},
            Vector#{2, 4},
            Vector#{2, 3},
            Vector#{3, 2},
            Vector#{3, 1},
            Vector#{3, 4},
            Vector#{3, 5},
            Vector#{4, 0},
            Vector#{4, 2},
            Vector#{4, 5},
            Vector#{4, 3},
            Vector#{5, 0},
            Vector#{5, 4},
            Vector#{5, 1},
            Vector#{5, 3}
        }

    def centreColour4(): Vector[Int32] = Vector#{0, 1, 2, 3, 4, 5}

    // ---------- the 5x5x5 tables ----------
    //
    // Corners and midges in the standard orders, so a 5x5x5 reads as a 3x3x3
    // with more orbits. Wings, X-centres and plus-centres by facelet index.

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
            Vector#{1, 128},
            Vector#{9, 28},
            Vector#{15, 103},
            Vector#{23, 53},
            Vector#{26, 19},
            Vector#{34, 130},
            Vector#{40, 69},
            Vector#{48, 94},
            Vector#{51, 21},
            Vector#{59, 30},
            Vector#{65, 119},
            Vector#{73, 78},
            Vector#{76, 71},
            Vector#{84, 46},
            Vector#{90, 121},
            Vector#{98, 146},
            Vector#{101, 5},
            Vector#{109, 55},
            Vector#{115, 144},
            Vector#{123, 80},
            Vector#{126, 3},
            Vector#{134, 105},
            Vector#{140, 44},
            Vector#{148, 96}
        }

    def wingColour5(): Vector[Vector[Int32]] = Vector#{
            Vector#{0, 5},
            Vector#{0, 1},
            Vector#{0, 4},
            Vector#{0, 2},
            Vector#{1, 0},
            Vector#{1, 5},
            Vector#{1, 2},
            Vector#{1, 3},
            Vector#{2, 0},
            Vector#{2, 1},
            Vector#{2, 4},
            Vector#{2, 3},
            Vector#{3, 2},
            Vector#{3, 1},
            Vector#{3, 4},
            Vector#{3, 5},
            Vector#{4, 0},
            Vector#{4, 2},
            Vector#{4, 5},
            Vector#{4, 3},
            Vector#{5, 0},
            Vector#{5, 4},
            Vector#{5, 1},
            Vector#{5, 3}
        }

    /// The X-centres -- the four diagonal cells of each face's centre block.
    def xFacelet5(): Vector[Int32] = Vector#{6, 8, 16, 18, 31, 33, 41, 43, 56, 58, 66, 68, 81, 83, 91, 93, 106, 108, 116, 118, 131, 133, 141, 143}

    /// The plus-centres -- the four edge-adjacent cells.
    def plusFacelet5(): Vector[Int32] = Vector#{7, 11, 13, 17, 32, 36, 38, 42, 57, 61, 63, 67, 82, 86, 88, 92, 107, 111, 113, 117, 132, 136, 138, 142}

    /// Both centre orbits share one colour-to-face map.
    def centreColour5(): Vector[Int32] = Vector#{0, 1, 2, 3, 4, 5}

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
        case 2 => "orbit64-2x2-draft@1"
        case 3 => "orbit64-3x3-draft@1"
        case 4 => "orbit64-4x4-draft@1"
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
        validate(n, orbits) |> Result.flatMap(_ -> dispatch(n, orbits))

    ///
    /// The three checks any drawable state must pass regardless of size: this
    /// module has a convention for `n`, `orbits` names each orbit that
    /// convention expects, and every coordinate in it is one a real cube can
    /// be in.
    ///
    def validate(n: Int32, orbits: List[Coord]): Result[String, Unit] =
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
        else Ok(())

    ///
    /// `toFacelets`'s size dispatch, once `validate` has fixed `orbits`'
    /// shape.
    ///
    def dispatch(n: Int32, orbits: List[Coord]): Result[String, Vector[Int32]] =
        if (n == 4) Ok(facelets4(orbits))
        else if (n == 5)
            match facelets5(orbits) {
                case Some(fs) => Ok(fs)
                // Unreachable: validate already fixed the shape.
                case None     =>
                    Err("expected orbits ${Orbit64.Orbit.layout(n)} for the ${n}x${n}x${n}")
            }
        else Ok(facelets3(n, orbits))

    ///
    /// The net for `orbits`, or why there isn't one.
    ///
    pub def draw(n: Int32, orbits: List[Coord], colour: Bool): Result[String, String] =
        toFacelets(n, orbits)
            |> Result.map(fs -> render(n, fs, colour))

    ///
    /// The orbits `facelets` describes, or why it describes no cube.
    ///
    /// The exact inverse of `toFacelets`, and the direction a project with a
    /// cube engine of its own needs in order to *produce* a token rather than
    /// merely draw one. Both directions read the same private tables, so an
    /// adapter never has to restate this package's slot convention -- the one
    /// thing it could not restate correctly without copying it.
    ///
    /// Facelets carry colours and no slot numbers, so this recovers the state
    /// as `convention(n)` numbers it. A project whose own slot order differs
    /// still gets the same cube, described in Orbit64's terms, which is exactly
    /// what makes the facelet layer the place two such projects can meet.
    ///
    /// It refuses a state whose fixed centres have moved. An odd cube's six
    /// single centres are the frame this format is written in rather than state
    /// it carries, so a slice turn or a whole-cube rotation leaves something a
    /// token has nowhere to record. Normalising it silently would return a
    /// different state than the caller handed over; saying so is the honest
    /// answer, and the caller knows which turn to undo.
    ///
    pub def fromFacelets(n: Int32, facelets: Vector[Int32]): Result[String, List[Coord]] =
        if (not canDraw(n))
            Err("no slot convention for the ${n}x${n}x${n}: this module has one "
                + "only up to the 5x5x5")
        else if (Vector.length(facelets) != 6 * n * n)
            Err("expected ${6 * n * n} facelets for the ${n}x${n}x${n}, "
                + "got ${Vector.length(facelets)}")
        else if (not Vector.forAll(f -> f >= 0 and f < 6, facelets))
            Err("every facelet must name a face, 0 to 5")
        else
            checkFrame(n, facelets)
                |> Result.flatMap(_ -> readOrbits(n, facelets))
                |> Result.flatMap(allCubes)

    ///
    /// The 2x2x2 and 3x3x3.
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
    /// Dispatch to the reader for `n`, once `fromFacelets` has established that
    /// the input is the right length and made of face indices.
    ///
    def readOrbits(n: Int32, fs: Vector[Int32]): Result[String, List[Coord]] =
        if (n == 4) orbits4(fs)
        else if (n == 5) orbits5(fs)
        else orbits3(n, fs)

    ///
    /// A 2x2x2 or 3x3x3, read off the 3x3x3 grid the tables are written for.
    ///
    def orbits3(n: Int32, fs: Vector[Int32]): Result[String, List[Coord]] =
        let grid = if (n == 2) inflate2(fs) else fs;
        if (n == 2)
            forM ((cp, co) <- readOriented("corner", cornerFacelet(), cornerColor(), grid))
                yield CornerCoord(cp, co) :: Nil
        else
            forM (
                (cp, co) <- readOriented("corner", cornerFacelet(), cornerColor(), grid);
                (ep, eo) <- readOriented("edge", edgeFacelet(), edgeColor(), grid)
            ) yield CornerCoord(cp, co) :: MidgeCoord(ep, eo) :: Nil

    ///
    /// A 4x4x4, read under `orbit64-4x4-draft@1`.
    ///
    def orbits4(fs: Vector[Int32]): Result[String, List[Coord]] =
        forM (
            (cp, co) <- readOriented("corner", cornerFacelet4(), cornerColour4(), fs);
            wp       <- readUnoriented("wing", wingFacelet4(), wingColour4(), fs);
            cols     <- readCentres("centre", centreFacelet4(), centreColour4(), fs)
        ) yield CornerCoord(cp, co) :: WingCoord(wp) :: CenterCoord(cols) :: Nil

    ///
    /// A 5x5x5, read under `orbit64-5x5-draft@1`.
    ///
    /// The two centre orbits come back in the order that convention fixes --
    /// the X-centres fourth and the plus-centres fifth -- which is the same
    /// order `facelets5` writes them in, and the only thing that tells two
    /// `CenterCoord`s apart.
    ///
    def orbits5(fs: Vector[Int32]): Result[String, List[Coord]] =
        forM (
            (cp, co) <- readOriented("corner", cornerFacelet5(), cornerColour5(), fs);
            (ep, eo) <- readOriented("midge", midgeFacelet5(), midgeColour5(), fs);
            wp       <- readUnoriented("wing", wingFacelet5(), wingColour5(), fs);
            xs       <- readCentres("X-centre", xFacelet5(), centreColour5(), fs);
            ps       <- readCentres("plus-centre", plusFacelet5(), centreColour5(), fs)
        ) yield CornerCoord(cp, co) :: MidgeCoord(ep, eo) :: WingCoord(wp)
                    :: CenterCoord(xs) :: CenterCoord(ps) :: Nil

    ///
    /// A 2x2x2's 24 stickers, spread back over the 3x3x3 grid its tables index.
    ///
    /// The inverse of the thinning `facelets3` ends with: a 2x2x2 sticker is a
    /// corner cell of a 3x3x3 face, and the cells in between are ones no corner
    /// table names. They are filled with their own face so the grid stays a
    /// picture of something rather than a heap of zeroes; nothing reads them.
    ///
    def inflate2(fs: Vector[Int32]): Vector[Int32] =
        Vector.init(i -> {
            let face = i / 9;
            let r = Int32.modulo(i / 3, 3);
            let c = Int32.modulo(i, 3);
            if (Int32.modulo(r, 2) == 0 and Int32.modulo(c, 2) == 0)
                Vector.get(face * 4 + (r / 2) * 2 + c / 2, fs)
            else face
        }, 54)

    ///
    /// The stickers sitting on `slot`'s facelets, in table order.
    ///
    def stickersAt(table: Vector[Vector[Int32]], slot: Int32, fs: Vector[Int32]): Vector[Int32] =
        Vector.get(slot, table) |> Vector.map(at -> Vector.get(at, fs))

    ///
    /// The permutation and orientation of an orbit whose pieces can be turned
    /// in place: corners, and the midges of an odd cube.
    ///
    def readOriented(
        what: String,
        table: Vector[Vector[Int32]],
        colours: Vector[Vector[Int32]],
        fs: Vector[Int32]
    ): Result[String, (Vector[Int32], Vector[Int32])] =
        List.range(0, Vector.length(table))
            |> Result.traverse(slot ->
                let seen = stickersAt(table, slot, fs);
                match readPiece(colours, seen) {
                    case Some(po) => Ok(po)
                    case None     => Err(noSuchPiece(what, slot, seen))
                })
            |> Result.map(ps ->
                (List.toVector(List.map(fst, ps)), List.toVector(List.map(snd, ps))))

    ///
    /// The permutation of an orbit whose pieces carry no orientation: wings.
    ///
    def readUnoriented(
        what: String,
        table: Vector[Vector[Int32]],
        colours: Vector[Vector[Int32]],
        fs: Vector[Int32]
    ): Result[String, Vector[Int32]] =
        List.range(0, Vector.length(table))
            |> Result.traverse(slot ->
                let seen = stickersAt(table, slot, fs);
                match List.range(0, Vector.length(colours))
                        |> List.find(p -> Vector.get(p, colours) == seen) {
                    case Some(p) => Ok(p)
                    case None    => Err(noSuchPiece(what, slot, seen))
                })
            |> Result.map(List.toVector)

    ///
    /// The colours of a centre orbit, one per slot.
    ///
    /// A centre is a single sticker and the four of a colour are alike, so
    /// there is no piece to identify -- only a colour to look up. Under this
    /// convention that lookup is the identity, because ordering centres by
    /// facelet index makes a centre's colour index its face index. The table is
    /// consulted anyway rather than the sticker being taken for the answer, so
    /// that the convention stays stated in one place.
    ///
    def readCentres(
        what: String,
        table: Vector[Int32],
        colours: Vector[Int32],
        fs: Vector[Int32]
    ): Result[String, Vector[Int32]] =
        List.range(0, Vector.length(table))
            |> Result.traverse(slot ->
                let seen = Vector.get(Vector.get(slot, table), fs);
                match Vector.indexOf(seen, colours) {
                    case Some(col) => Ok(col)
                    // Unreachable while the colour table is a permutation of
                    // the six faces, which `fromFacelets` has already bounded
                    // the sticker to. It is the table's property, not this
                    // reader's, so the reader still answers rather than trusts.
                    case None      => Err(noSuchPiece(what, slot, Vector#{seen}))
                })
            |> Result.map(List.toVector)

    ///
    /// The piece and orientation whose colours are `seen`, or nothing when no
    /// piece of that orbit carries those colours in that cyclic order.
    ///
    /// `toFacelets` writes the sticker on `table[slot][j]` as
    /// `colours[piece][(j - orientation) mod m]`, and this inverts exactly
    /// that. The answer is unique because no two pieces of an orbit share a
    /// colour set, and no piece's colours are cyclically symmetric.
    ///
    def readPiece(colours: Vector[Vector[Int32]], seen: Vector[Int32]): Option[(Int32, Int32)] =
        let m = Vector.length(seen);
        List.range(0, Vector.length(colours)) |> List.findMap(p ->
            List.range(0, m)
                |> List.find(o -> List.range(0, m) |> List.forAll(j ->
                    Vector.get(j, seen)
                        == Vector.get(Int32.modulo(j - o + m, m), Vector.get(p, colours))))
                |> Option.map(o -> (p, o)))

    ///
    /// An odd cube's six single centres are the frame this format is written
    /// in, not state it carries. A slice turn or a whole-cube rotation moves
    /// them, and a token has nowhere to record where they went, so such a state
    /// can be drawn but not read back. Turning it back into the frame is the
    /// caller's to do: doing it here would hand back a different state than the
    /// one that arrived, without saying so.
    ///
    def checkFrame(n: Int32, fs: Vector[Int32]): Result[String, Unit] =
        match fixedFacelets(n) {
            case None => Ok(())
            case Some(centres) =>
                match List.range(0, 6)
                        |> List.find(f -> Vector.get(Vector.get(f, centres), fs) != f) {
                    case None    => Ok(())
                    case Some(f) =>
                        let shows = Vector.get(Vector.get(Vector.get(f, centres), fs), faces());
                        Err("the ${Vector.get(f, faces())} centre shows ${shows}: the six fixed "
                            + "centres are the frame this format is written in, so a state whose "
                            + "centres have moved has to be turned back into that frame before it "
                            + "can be read")
                }
        }

    ///
    /// Where the six fixed centres sit at size `n`, or `None` for an even cube,
    /// which has none.
    ///
    def fixedFacelets(n: Int32): Option[Vector[Int32]] = match n {
        case 3 => Some(Vector.range(0, 6) |> Vector.map(f -> f * 9 + 4))
        case 5 => Some(fixedFacelet5())
        case _ => None
    }

    ///
    /// Every coordinate read back has to be a cube in its own right.
    ///
    /// Reading is slot by slot, so nothing above notices two slots claiming the
    /// same piece, or a colour turning up five times where four is the whole
    /// supply. `Coord.faultOf` states those constraints once, and this is where
    /// the facelet direction leans on them -- the same check, and the same
    /// wording, that `Orbit64.State.encode` gives a caller building coordinates by
    /// hand.
    ///
    def allCubes(orbits: List[Coord]): Result[String, List[Coord]] =
        match orbits
                |> List.filterMap(c -> Orbit64.Coord.faultOf(c)
                    |> Option.map(why -> (Orbit64.Coord.kind(c), why)))
                |> List.head {
            case Some((o, why)) => Err("the ${o} these facelets show are not a cube: ${why}")
            case None           => Ok(orbits)
        }

    ///
    /// Name the stickers a slot shows, for a reader that has to say what it
    /// could not identify. Face letters rather than indices: the caller is
    /// looking at a cube, not at a table.
    ///
    def noSuchPiece(what: String, slot: Int32, seen: Vector[Int32]): String =
        let letters = seen |> Vector.map(f -> Vector.get(f, faces())) |> Vector.join("");
        "${what} slot ${slot} shows ${letters}, which is no ${what} of this cube"

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
