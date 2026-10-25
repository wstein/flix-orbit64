///
/// The 48 symmetries of the cube as permutations of the facelet indices.
///
/// A symmetry is a signed permutation of the three axes: 24 rotations and
/// their 24 mirror images. It sends every sticker to another sticker of the
/// same cube. The tables are derived from geometry alone: a facelet is
/// `face * n * n + row * n + col` over `U R F D L B`, the layout `Orbit64.Net`
/// reads and writes. `locate` places a facelet in space, `indexOf` is its
/// inverse, and a symmetry is applied to the position and the normal of a
/// sticker together.
///
/// Symmetry `g` has the axis permutation `g / 8` and the sign bits `g % 8`.
/// Row `r` of its matrix has the single entry `-1` if sign bit `r` is set and
/// `1` otherwise, in column `axes(g / 8)[r]`. Symmetry 0 is the identity
/// and symmetry 1 mirrors across the R/L plane.
///
mod Orbit64.Symmetry {

    /// The number of symmetries: the 6 axis permutations times the 8 sign choices.
    pub def count(): Int32 = 48

    /// The symmetry that mirrors across the plane between the R and L faces.
    pub def mirrorAcrossRL(): Int32 = 1

    ///
    /// Where the stickers go under symmetry `g`: sticker `i` of the cube moves
    /// to index `Vector.get(i, destinations(n, g))`.
    ///
    pub def destinations(n: Int32, g: Int32): Vector[Int32] =
        Vector.range(0, 6 * n * n) |> Vector.map(i -> {
            let (position, normal) = locate(n, i);
            indexOf(n, apply(g, position), apply(g, normal))
        })

    ///
    /// `stickers` moved by symmetry `g`; the colors stay.
    ///
    pub def image(n: Int32, g: Int32, stickers: Vector[Int32]): Vector[Int32] =
        let target = destinations(n, g);
        region rc {
            let out = Array.repeat(rc, Vector.length(stickers), 0);
            Vector.range(0, Vector.length(stickers)) |> Vector.forEach(i ->
                Array.put(Vector.get(i, stickers), Vector.get(i, target), out));
            Array.toVector(out)
        }

    ///
    /// `stickers` with its colors renamed in order of first appearance, so the
    /// first color becomes 0, the next new one 1, and so on.
    ///
    pub def relabel(stickers: Vector[Int32]): Vector[Int32] =
        let (_, names) = Vector.foldLeft((acc, c) -> {
            let (seen, out) = acc;
            match Map.get(c, seen) {
                case Some(name) => (seen, name :: out)
                case None       => (Map.insert(c, Map.size(seen), seen), Map.size(seen) :: out)
            }
        }, (Map.empty(), Nil), stickers);
        names |> List.reverse |> List.toVector

    ///
    /// The least relabeled image of `stickers` over all 48 symmetries.
    ///
    /// Images compare as sticker strings: the first sticker decides, then the
    /// second, in face order `U R F D L B`. Two cubes have the same least
    /// image exactly when one is the other turned, mirrored and recolored.
    ///
    pub def leastImage(n: Int32, stickers: Vector[Int32]): Vector[Int32] =
        let keyed = g -> {
            let candidate = relabel(image(n, g, stickers));
            (key(candidate), candidate)
        };
        let (_, least) = List.range(1, count()) |> List.foldLeft((best, g) -> {
            let (k, v) = keyed(g);
            let (bestKey, _) = best;
            if (k < bestKey) (k, v) else best
        }, keyed(0));
        least

    ///
    /// The three stickers of each corner, `U R F` first and then the other
    /// seven corners; within a corner the sticker on the U or D face comes
    /// first, then the one on R or L, then the one on F or B.
    ///
    pub def cornerStickers(n: Int32): List[Vector[Int32]] =
        let m = n - 1;
        List#{1, -1} |> List.flatMap(y ->
            List#{1, -1} |> List.flatMap(x ->
                List#{1, -1} |> List.map(z -> {
                    let at = (x * m, y * m, z * m);
                    Vector#{
                        indexOf(n, at, (0, y, 0)),
                        indexOf(n, at, (x, 0, 0)),
                        indexOf(n, at, (0, 0, z))
                    }
                })))

    /// The facelet at the middle of face `face` of an odd cube.
    pub def centerFacelet(n: Int32, face: Int32): Int32 = face * n * n + (n * n) / 2

    /// The colors as one base-6 number, so that numeric order is sticker order.
    def key(stickers: Vector[Int32]): BigInt =
        Vector.foldLeft((acc, c) -> acc * 6ii + Int32.toBigInt(c), 0ii, stickers)

    /// The axis permutations, in order.
    def axes(p: Int32): Vector[Int32] = match p {
        case 0 => Vector#{0, 1, 2}
        case 1 => Vector#{0, 2, 1}
        case 2 => Vector#{1, 0, 2}
        case 3 => Vector#{1, 2, 0}
        case 4 => Vector#{2, 0, 1}
        case _ => Vector#{2, 1, 0}
    }

    /// Symmetry `g` applied to a point or a normal.
    def apply(g: Int32, v: (Int32, Int32, Int32)): (Int32, Int32, Int32) =
        let (x, y, z) = v;
        let coordinates = Vector#{x, y, z};
        let perm = axes(g / 8);
        let signs = Int32.modulo(g, 8);
        let at = r -> {
            let value = Vector.get(Vector.get(r, perm), coordinates);
            if (Int32.modulo(signs / Int32.pow(base = 2, r), 2) == 1) -value else value
        };
        (at(0), at(1), at(2))

    ///
    /// Where facelet `i` of an `n x n x n` sits: its position, with the
    /// corner cells at `+-(n - 1)`, and the outward normal of its face.
    ///
    def locate(n: Int32, i: Int32): ((Int32, Int32, Int32), (Int32, Int32, Int32)) =
        let m = n - 1;
        let face = i / (n * n);
        let row = Int32.modulo(i, n * n) / n;
        let col = Int32.modulo(i, n);
        let a = 2 * col - m;
        let b = 2 * row - m;
        match face {
            case 0 => ((a, m, b), (0, 1, 0))
            case 1 => ((m, -b, -a), (1, 0, 0))
            case 2 => ((a, -b, m), (0, 0, 1))
            case 3 => ((a, -m, -b), (0, -1, 0))
            case 4 => ((-m, -b, a), (-1, 0, 0))
            case _ => ((-a, -b, -m), (0, 0, -1))
        }

    /// The inverse of `locate`.
    def indexOf(n: Int32, position: (Int32, Int32, Int32), normal: (Int32, Int32, Int32)): Int32 =
        let m = n - 1;
        let (face, a, b) = planeCoordinates(position, normal);
        face * n * n + ((b + m) / 2) * n + (a + m) / 2

    /// The face a normal points out of, and the position's coordinates on it.
    def planeCoordinates(position: (Int32, Int32, Int32), normal: (Int32, Int32, Int32))
            : (Int32, Int32, Int32) =
        let (x, y, z) = position;
        match normal {
            case (0, 1, 0)  => (0, x, z)
            case (1, 0, 0)  => (1, -z, -y)
            case (0, 0, 1)  => (2, x, -y)
            case (0, -1, 0) => (3, x, -z)
            case (-1, 0, 0) => (4, z, -y)
            case _          => (5, -x, -y)
        }

}
