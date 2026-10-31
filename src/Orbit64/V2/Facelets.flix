///
/// The facelet bridge of Orbit64 V2: a cube state to its stickers and back.
///
/// A facelet string writes the `6 n^2` stickers as the letters `U R F D L B`,
/// one per facelet, six face fields in that order separated by one space, in
/// the layout of `FORMAT.md` (facelet `face * n^2 + row * n + col`). Reading
/// ignores spaces. This is the notation of V1's `Orbit64.Net`, for every
/// `n = 2..15`.
///
/// Only the color model has letters: its stickers are exactly the six colors.
///
/// The slot tables follow the V1 slot convention `orbit64-Nxn-draft@1` and
/// its extension to `n >= 8` ("Conventions" in `FORMAT-V2.md`). Three
/// reference tables carry it: the corners and midges of the 5x5x5, and the
/// wings of the 4x4x4. Every other size takes its slots by replacing each
/// axis of a reference facelet, `0` by `0`, `1` by the wing depth `d`, `2` (5x5x5
/// only) by `n / 2`, and the last two by `n - 1 - d` and `n - 1`. Center
/// orbits come from geometry: the four quarter turn images of a cell, on six
/// faces, ordered by facelet index. Because a piece is numbered by its home
/// slot and the solved cube shows face colors, a piece's colors are the faces
/// of its home slot's facelets, so no color table is needed.
///
/// A whole-cube rotation is applied to a facelet string through the geometry
/// of `FORMAT.md`, not through V1's `x`, `z`, `y` composition: frame `r` is
/// the rotation that moves physical face `faces(r)[i]` into slot `i`.
///
mod Orbit64.V2.Facelets {

    use Orbit64.V2.Registry.{Model, Pose}
    use Orbit64.V2.State.Cube

    /// The facelets of every slot of a cube, in slot order.
    type alias Tables = {
        corners = Vector[Vector[Int32]], midges = Vector[Vector[Int32]],
        wings = Vector[Vector[Vector[Int32]]], centers = Vector[Vector[Int32]],
        fixed = Vector[Int32]
    }

    /// A vector of three integers: a position (on the doubled grid) or a direction.
    type alias Vec = (Int32, Int32, Int32)

    /// A rotation as the images of the unit vectors `x`, `y` and `z`.
    type alias Turn = (Vec, Vec, Vec)

    def odd(n: Int32): Bool = Int32.modulo(n, 2) == 1

    def letters(): Vector[String] = Vector#{"U", "R", "F", "D", "L", "B"}

    // ------------------------------------------------------------ slot tables

    /// Corner slots of the 5x5x5: the facelet orientation counts from, then clockwise.
    def cornerReference(): Vector[Vector[Int32]] = Vector#{
        Vector#{24, 25, 54}, Vector#{20, 50, 104}, Vector#{0, 100, 129},
        Vector#{4, 125, 29}, Vector#{79, 74, 45}, Vector#{75, 124, 70},
        Vector#{95, 149, 120}, Vector#{99, 49, 145}
    }

    /// Midge slots of the 5x5x5.
    def midgeReference(): Vector[Vector[Int32]] = Vector#{
        Vector#{14, 27}, Vector#{22, 52}, Vector#{10, 102}, Vector#{2, 127},
        Vector#{89, 47}, Vector#{77, 72}, Vector#{85, 122}, Vector#{97, 147},
        Vector#{64, 35}, Vector#{60, 114}, Vector#{139, 110}, Vector#{135, 39}
    }

    /// Wing slots of the 4x4x4, the reference sticker first.
    def wingReference(): Vector[Vector[Int32]] = Vector#{
        Vector#{1, 82}, Vector#{7, 18}, Vector#{8, 66}, Vector#{14, 34},
        Vector#{17, 11}, Vector#{23, 84}, Vector#{24, 43}, Vector#{30, 59},
        Vector#{33, 13}, Vector#{39, 20}, Vector#{40, 75}, Vector#{46, 50},
        Vector#{49, 45}, Vector#{55, 29}, Vector#{56, 77}, Vector#{62, 93},
        Vector#{65, 4}, Vector#{71, 36}, Vector#{72, 91}, Vector#{78, 52},
        Vector#{81, 2}, Vector#{87, 68}, Vector#{88, 27}, Vector#{94, 61}
    }

    /// Carry a reference facelet of a `base x base` cube to wing depth `depth` of an `n x n x n`.
    def expandFacelet(n: Int32, base: Int32, depth: Int32, index: Int32): Int32 =
        let face = index / (base * base);
        let row = Int32.modulo(index / base, base);
        let col = Int32.modulo(index, base);
        face * n * n + expandAxis(n, base, depth, row) * n + expandAxis(n, base, depth, col)

    def expandAxis(n: Int32, base: Int32, depth: Int32, value: Int32): Int32 =
        let mapped = if (base == 4) Vector#{0, depth, n - 1 - depth, n - 1}
                     else Vector#{0, depth, n / 2, n - 1 - depth, n - 1};
        Vector.get(value, mapped)

    def expandTable(n: Int32, base: Int32, depth: Int32,
                    table: Vector[Vector[Int32]]): Vector[Vector[Int32]] =
        Vector.map(row -> Vector.map(i -> expandFacelet(n, base, depth, i), row), table)

    def centerRepresentative(n: Int32, row: Int32, col: Int32): Bool =
        let last = n - 1;
        let rank = row * n + col;
        rank <= col * n + last - row and
        rank <= (last - row) * n + last - col and
        rank <= (last - col) * n + row

    /// The four quarter turn images of a cell, on all six faces, by facelet index.
    def centerTable(n: Int32, row: Int32, col: Int32): Vector[Int32] =
        let last = n - 1;
        List.range(0, 6 * n * n)
            |> List.filter(i -> {
                let cell = Int32.modulo(i, n * n);
                cell == row * n + col or cell == col * n + last - row or
                cell == (last - row) * n + last - col or
                cell == (last - col) * n + row
            })
            |> List.toVector

    /// Center orbits ordered by their lowest facelet; the fixed center of an odd cube is no orbit.
    def centerTables(n: Int32): Vector[Vector[Int32]] =
        List.range(1, n - 1) |> List.flatMap(row ->
            List.range(1, n - 1) |> List.filterMap(col ->
                if (centerRepresentative(n, row, col)
                    and not (odd(n) and row == n / 2 and col == n / 2))
                    Some(centerTable(n, row, col))
                else None))
            |> List.toVector

    def fixedFacelets(n: Int32): Vector[Int32] =
        let middle = (n * n - 1) / 2;
        if (odd(n)) Vector.range(0, 6) |> Vector.map(f -> f * n * n + middle)
        else Vector.empty()

    def tables(n: Int32): Tables =
        { corners = expandTable(n, 5, 1, cornerReference()),
          midges = if (odd(n)) expandTable(n, 5, 1, midgeReference()) else Vector.empty(),
          wings = Vector.range(1, Orbit64.V2.State.wingOrbits(n) + 1)
              |> Vector.map(d -> expandTable(n, 4, d, wingReference())),
          centers = centerTables(n),
          fixed = fixedFacelets(n) }

    /// The face color of a facelet: in the solved cube a sticker shows its face.
    def faceOf(n: Int32, facelet: Int32): Int32 = facelet / (n * n)

    // --------------------------------------------------------------- geometry

    /// Position (doubled grid, `-m..m` with `m = n - 1`) and outward normal of a facelet.
    def geometry(n: Int32, index: Int32): (Vec, Vec) =
        let m = n - 1;
        let face = index / (n * n);
        let a = 2 * Int32.modulo(index, n) - m;
        let b = 2 * Int32.modulo(index / n, n) - m;
        match face {
            case 0 => ((a, m, b), (0, 1, 0))
            case 1 => ((m, -b, -a), (1, 0, 0))
            case 2 => ((a, -b, m), (0, 0, 1))
            case 3 => ((a, -m, -b), (0, -1, 0))
            case 4 => ((-m, -b, a), (-1, 0, 0))
            case _ => ((-a, -b, -m), (0, 0, -1))
        }

    /// The inverse of `geometry`.
    def faceletAt(n: Int32, position: Vec, normal: Vec): Int32 =
        let m = n - 1;
        let face = faceOfNormal(normal);
        let (a, b) = gridOf(face, position);
        face * n * n + (b + m) / 2 * n + (a + m) / 2

    def faceOfNormal(normal: Vec): Int32 = match normal {
        case (0, 1, 0)  => 0
        case (1, 0, 0)  => 1
        case (0, 0, 1)  => 2
        case (0, -1, 0) => 3
        case (-1, 0, 0) => 4
        case _          => 5
    }

    /// The `(a, b)` grid coordinates of a position on a face, as in `geometry`.
    def gridOf(face: Int32, position: Vec): (Int32, Int32) =
        let (x, y, z) = position;
        match face {
            case 0 => (x, z)
            case 1 => (-z, -y)
            case 2 => (x, -y)
            case 3 => (x, -z)
            case 4 => (z, -y)
            case _ => (-x, -y)
        }

    def normalOf(face: Int32): Vec = match face {
        case 0 => (0, 1, 0)
        case 1 => (1, 0, 0)
        case 2 => (0, 0, 1)
        case 3 => (0, -1, 0)
        case 4 => (-1, 0, 0)
        case _ => (0, 0, -1)
    }

    def faceIndex(face: Orbit64.Move.Face): Int32 = match face {
        case Orbit64.Move.Face.U => 0
        case Orbit64.Move.Face.R => 1
        case Orbit64.Move.Face.F => 2
        case Orbit64.Move.Face.D => 3
        case Orbit64.Move.Face.L => 4
        case Orbit64.Move.Face.B => 5
    }

    /// The physical faces in slots `U R F D L B` of a frame, as indices.
    def frameFaces(frame: Int32): List[Int32] =
        Orbit64.Frame.faces(Orbit64.Frame.unrank(frame)) |> List.map(faceIndex)

    /// The rotation of frame `frame`: it moves physical face `faces[i]` onto slot `i`.
    def turnOf(frame: Int32): Turn =
        let faces = frameFaces(frame);
        let slotOf = f -> normalOf(Option.getWithDefault(0, List.indexOf(f, faces)));
        (slotOf(1), slotOf(0), slotOf(2))

    def dot(a: Vec, b: Vec): Int32 =
        let (ax, ay, az) = a;
        let (bx, by, bz) = b;
        ax * bx + ay * by + az * bz

    def forward(turn: Turn, v: Vec): Vec =
        let (ex, ey, ez) = turn;
        let (x, y, z) = v;
        add(scale(x, ex), add(scale(y, ey), scale(z, ez)))

    def scale(k: Int32, v: Vec): Vec =
        let (x, y, z) = v;
        (k * x, k * y, k * z)

    def add(a: Vec, b: Vec): Vec =
        let (ax, ay, az) = a;
        let (bx, by, bz) = b;
        (ax + bx, ay + by, az + bz)

    /// The inverse of a rotation is its transpose.
    def backward(turn: Turn, v: Vec): Vec =
        let (ex, ey, ez) = turn;
        (dot(v, ex), dot(v, ey), dot(v, ez))

    /// The stickers after the cube is rotated by `turn`: each sticker moves with its color.
    def rotate(n: Int32, turn: Turn, fs: Vector[Int32]): Vector[Int32] =
        Vector.init(i -> {
            let (p, q) = geometry(n, i);
            Vector.get(faceletAt(n, backward(turn, p), backward(turn, q)), fs)
        }, Vector.length(fs))

    /// The stickers of the cube rotated back: the inverse of `rotate`.
    def unrotate(n: Int32, turn: Turn, fs: Vector[Int32]): Vector[Int32] =
        Vector.init(i -> {
            let (p, q) = geometry(n, i);
            Vector.get(faceletAt(n, forward(turn, p), forward(turn, q)), fs)
        }, Vector.length(fs))

    // ---------------------------------------------------------- cube to stickers

    def writeOriented(n: Int32, sticker: Array[Int32, r], table: Vector[Vector[Int32]],
                      pieces: Vector[Int32], twists: Vector[Int32]): Unit \ r =
        Vector.range(0, Vector.length(table)) |> Vector.forEach(slot -> {
            let m = Vector.length(Vector.get(slot, table));
            let home = Vector.get(Vector.get(slot, pieces), table);
            let twist = Vector.get(slot, twists);
            Vector.range(0, m) |> Vector.forEach(k ->
                Array.put(faceOf(n, Vector.get(Int32.modulo(k - twist + m, m), home)),
                          Vector.get(k, Vector.get(slot, table)), sticker))
        })

    def writeWings(n: Int32, sticker: Array[Int32, r], table: Vector[Vector[Int32]],
                   pieces: Vector[Int32]): Unit \ r =
        writeOriented(n, sticker, table, pieces, Vector.repeat(24, 0))

    def writeCenters(sticker: Array[Int32, r], table: Vector[Int32],
                     colors: Vector[Int32]): Unit \ r =
        Vector.range(0, Vector.length(table)) |> Vector.forEach(slot ->
            Array.put(Vector.get(slot, colors), Vector.get(slot, table), sticker))

    /// The stickers of a canonical-pose cube; fixed centers are home.
    def paint(n: Int32, t: Tables, cube: Cube): Vector[Int32] =
        region rc {
            let sticker = Array.repeat(rc, 6 * n * n, 0);
            Vector.range(0, Vector.length(t#fixed)) |> Vector.forEach(f ->
                Array.put(f, Vector.get(f, t#fixed), sticker));
            writeOriented(n, sticker, t#corners, cube#cornerPieces, cube#cornerTwists);
            if (odd(n)) writeOriented(n, sticker, t#midges, cube#midgePieces, cube#midgeFlips)
            else ();
            Vector.range(0, Vector.length(t#wings)) |> Vector.forEach(i ->
                writeWings(n, sticker, Vector.get(i, t#wings), Vector.get(i, cube#wings)));
            Vector.range(0, Vector.length(t#centers)) |> Vector.forEach(i ->
                writeCenters(sticker, Vector.get(i, t#centers), Vector.get(i, cube#centers)));
            Array.toVector(sticker)
        }

    def faultText(n: Int32, model: Model): String =
        Option.getWithDefault("", typeFault(n, model))

    /// Why a type has no facelet letters, if it has none.
    def typeFault(n: Int32, model: Model): Option[String] =
        if (n < 2 or n > 15) Some("no V2 type for the ${n}x${n}x${n}")
        else if (model == Model.Picture) Some("the picture model has no letters")
        else None

    def spell(n: Int32, fs: Vector[Int32]): String =
        Vector.range(0, 6) |> Vector.map(face ->
            Vector.range(0, n * n)
                |> Vector.map(i -> Vector.get(Vector.get(face * n * n + i, fs), letters()))
                |> Vector.join(""))
            |> Vector.join(" ")

    /// The facelet string of a cube state of the type `(n, model, pose)`.
    ///
    /// A canonical cube is written in its reference pose. A framed cube of an
    /// odd size is that picture rotated by `cube#frame`; a framed cube of an
    /// even size shows its pose in its corners already. Only the color model
    /// has letters.
    pub def toFacelets(n: Int32, model: Model, pose: Pose, cube: Cube): Result[String, String] =
        if (not Option.isEmpty(typeFault(n, model))) Err(faultText(n, model))
        else
            Orbit64.V2.State.rank(n, model, pose, cube)
                |> Result.map(_ -> {
                    let fs = paint(n, tables(n), cube);
                    spell(n, if (odd(n)) rotate(n, turnOf(cube#frame), fs) else fs)
                })

    // ---------------------------------------------------------- stickers to cube

    /// The stickers of a facelet string, as face indices, or why it is no string of `n^2` per face.
    def parse(n: Int32, text: String): Result[String, Vector[Int32]] =
        let chars = String.toList(text) |> List.filter(c -> c != ' ');
        let length = List.length(chars);
        if (length != 6 * n * n)
            Err("expected ${6 * n * n} facelets for the ${n}x${n}x${n}, got ${length}")
        else
            chars |> Result.traverse(c -> match List.indexOf(c, "URFDLB" |> String.toList) {
                case Some(i) => Ok(i)
                case None => Err("facelet '${c}' is not one of U R F D L B")
            }) |> Result.map(List.toVector)

    def checkCounts(n: Int32, fs: Vector[Int32]): Result[String, Unit] =
        match List.range(0, 6) |> List.find(f -> Vector.count(x -> x == f, fs) != n * n) {
            case Some(f) => Err("color ${Vector.get(f, letters())} occurs "
                                + "${Vector.count(x -> x == f, fs)} times, expected ${n * n}")
            case None => Ok(())
        }

    /// The stickers on the facelets of one slot.
    def seenAt(table: Vector[Vector[Int32]], slot: Int32, fs: Vector[Int32]): Vector[Int32] =
        Vector.get(slot, table) |> Vector.map(at -> Vector.get(at, fs))

    /// The piece and twist whose colors, read from the slot's first facelet, are `seen`.
    def readPiece(n: Int32, table: Vector[Vector[Int32]],
                  seen: Vector[Int32]): Option[(Int32, Int32)] =
        let m = Vector.length(seen);
        List.range(0, Vector.length(table)) |> List.findMap(p ->
            List.range(0, m)
                |> List.find(o -> List.range(0, m) |> List.forAll(k ->
                    Vector.get(k, seen)
                        == faceOf(n, Vector.get(Int32.modulo(k - o + m, m), Vector.get(p, table))))
                    )
                |> Option.map(o -> (p, o)))

    def noPiece(what: String, slot: Int32, seen: Vector[Int32]): String =
        let shown = seen |> Vector.map(f -> Vector.get(f, letters())) |> Vector.join("");
        "${what} slot ${slot} shows ${shown}, which is no ${what} of this cube"

    def readOriented(n: Int32, what: String, table: Vector[Vector[Int32]],
                     fs: Vector[Int32]): Result[String, (Vector[Int32], Vector[Int32])] =
        List.range(0, Vector.length(table)) |> Result.traverse(slot -> {
            let seen = seenAt(table, slot, fs);
            match readPiece(n, table, seen) {
                case Some(po) => Ok(po)
                case None => Err(noPiece(what, slot, seen))
            }
        }) |> Result.map(ps -> (pick(fst, ps), pick(snd, ps)))

    def pick(f: ((Int32, Int32)) -> Int32, ps: List[(Int32, Int32)]): Vector[Int32] =
        ps |> List.map(f) |> List.toVector

    /// A wing carries no twist: its two stickers sit in the order of its home slot or not at all.
    def readWingsStrict(n: Int32, table: Vector[Vector[Int32]],
                        fs: Vector[Int32]): Result[String, Vector[Int32]] =
        List.range(0, Vector.length(table)) |> Result.traverse(slot -> {
            let seen = seenAt(table, slot, fs);
            match List.range(0, Vector.length(table))
                    |> List.find(p -> seenAt(table, p, Vector.range(0, 6 * n * n)
                                              |> Vector.map(i -> faceOf(n, i))) == seen) {
                case Some(p) => Ok(p)
                case None => Err(noPiece("wing", slot, seen))
            }
        }) |> Result.map(List.toVector)

    def readCenters(table: Vector[Int32], fs: Vector[Int32]): Vector[Int32] =
        table |> Vector.map(at -> Vector.get(at, fs))

    /// The coordinates of a canonical-pose string; the frame is `frame`.
    def readCube(n: Int32, t: Tables, frame: Int32, fs: Vector[Int32]): Result[String, Cube] =
        forM (
            (cp, co) <- readOriented(n, "corner", t#corners, fs);
            (mp, mo) <- if (odd(n)) readOriented(n, "midge", t#midges, fs)
                        else Ok((Vector.empty(), Vector.empty()));
            ws <- t#wings |> Vector.toList
                      |> Result.traverse(table -> readWingsStrict(n, table, fs))
        ) yield {
            cornerPieces = cp, cornerTwists = co, midgePieces = mp, midgeFlips = mo,
            wings = List.toVector(ws),
            centers = t#centers |> Vector.map(table -> readCenters(table, fs)),
            rotations = Vector.empty(), frame = frame
        }

    /// Rotate an odd cube so that its fixed centers are home; the frame is the one they show.
    def normalizeOdd(n: Int32, t: Tables,
                     fs: Vector[Int32]): Result[String, (Int32, Vector[Int32])] =
        let shown = t#fixed |> Vector.map(at -> Vector.get(at, fs)) |> Vector.toList;
        match List.range(0, Orbit64.Frame.count()) |> List.find(r -> frameFaces(r) == shown) {
            case Some(r) => Ok((r, unrotate(n, turnOf(r), fs)))
            case None => Err("the six fixed centers are not a right-handed whole-cube frame")
        }

    /// Rotate an even cube so that its DBL corner is in slot DBL with twist 0.
    def normalizeEven(n: Int32, t: Tables, fs: Vector[Int32]): Result[String, Vector[Int32]] =
        let home = r -> {
            let rotated = unrotate(n, turnOf(r), fs);
            (rotated, readPiece(n, t#corners, seenAt(t#corners, 6, rotated)))
        };
        match List.range(0, Orbit64.Frame.count()) |> List.map(home)
                |> List.find(match (_, po) -> po == Some((6, 0))) {
            case Some((rotated, _)) => Ok(rotated)
            case None => Err("no whole-cube rotation puts the DBL corner home")
        }

    /// The cube state shown by a facelet string, in the pose of `pose`.
    ///
    /// A canonical read turns the cube so that its reference is home first
    /// (fixed centers on an odd cube, the DBL corner on an even one) and so
    /// accepts any whole-cube orientation. A framed read of an odd cube keeps
    /// the orientation as `cube#frame`; of an even cube, in its corners.
    /// Anything that is no reachable cube is an error: wrong counts, a slot
    /// that shows no piece, a piece twice, a broken orientation law or parity.
    pub def fromFacelets(n: Int32, model: Model, pose: Pose,
                         facelets: String): Result[String, Cube] =
        if (not Option.isEmpty(typeFault(n, model))) Err(faultText(n, model))
        else {
            let t = tables(n);
            forM (
                fs <- parse(n, facelets);
                _ <- checkCounts(n, fs);
                posed <- posedStickers(n, pose, t, fs);
                cube <- readCube(n, t, fst(posed), snd(posed));
                _ <- Orbit64.V2.State.rank(n, model, pose, cube)
            ) yield cube
        }

    /// The frame to record and the stickers in the pose the type reads them in.
    def posedStickers(n: Int32, pose: Pose, t: Tables,
                      fs: Vector[Int32]): Result[String, (Int32, Vector[Int32])] =
        if (odd(n))
            normalizeOdd(n, t, fs)
                |> Result.map(match (r, c) -> (if (pose == Pose.Framed) r else 0, c))
        else if (pose == Pose.Canonical)
            normalizeEven(n, t, fs) |> Result.map(c -> (0, c))
        else Ok((0, fs))

    // ---------------------------------------------------- registry level helpers

    /// The V2 token of the cube a facelet string shows, for registry entry `id`.
    pub def encode(id: Int32, facelets: String): Result[String, String] =
        match Orbit64.V2.Registry.entry(id) {
            case None => Err("unknown registry entry ${id}")
            case Some(e) =>
                fromFacelets(e#n, e#model, e#pose, facelets)
                    |> Result.flatMap(cube -> Orbit64.V2.Codec.encode(id, cube))
        }

    /// The registry entry of a token and the facelet string of its state.
    pub def decode(token: String): Result[String, (Orbit64.V2.Registry.Entry, String)] =
        Orbit64.V2.Codec.decode(token) |> Result.flatMap(match (e, cube) ->
            toFacelets(e#n, e#model, e#pose, cube) |> Result.map(text -> (e, text)))

}
