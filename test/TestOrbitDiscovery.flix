//
// An independent derivation of `Orbit.layout`, from geometry rather than
// arithmetic.
//
// `Orbit.layout(n)` computes the orbits of an n-cube as pure arithmetic in n:
// one corner orbit, midges when n is odd, (n-2)/2 wing orbits and (n-2)^2/4
// centre orbits. That is the claim this file exists to check, and it checks it
// the long way round -- by building a cube, turning it, and seeing which pieces
// can reach which.
//
// Two pieces are in the same orbit exactly when some sequence of turns carries
// one to the other, which is connected components of the "one turn maps p to q"
// graph. That is a transitive closure, so it is written as three Datalog rules
// rather than a hand-rolled union-find.
//
// Nothing here is part of the library. The codec has no notion of a face, an
// axis or a turn, and that is precisely why this makes a real test: the two
// sides share no code.
//

mod OrbitDiscovery {

    use Orbit64.Orbit.Orbit
    use Orbit64.Orbit.Orbit.{Corners, Midges, Wings, Centers}

    ///
    /// Whether coordinate `c` lies on a face of an `n`-cube.
    ///
    def onFace(n: Int32, c: Int32): Bool = c == 0 or c == n - 1

    ///
    /// How many faces the cubie at `(x, y, z)` shows: 3 for a corner, 2 for an
    /// edge, 1 for a centre, 0 for a piece buried inside the cube.
    ///
    def visible(n: Int32, x: Int32, y: Int32, z: Int32): Int32 =
        (if (onFace(n, x)) 1 else 0) +
        (if (onFace(n, y)) 1 else 0) +
        (if (onFace(n, z)) 1 else 0)

    def encode(n: Int32, x: Int32, y: Int32, z: Int32): Int32 = (x * n + y) * n + z

    def decode(n: Int32, p: Int32): (Int32, Int32, Int32) =
        (p / (n * n), Int32.modulo(p / n, n), Int32.modulo(p, n))

    ///
    /// Every cubie that shows at least one sticker.
    ///
    def surface(n: Int32): List[Int32] =
        List.range(0, n) |> List.flatMap(x ->
            List.range(0, n) |> List.flatMap(y ->
                List.range(0, n) |> List.filterMap(z ->
                    if (visible(n, x, y, z) > 0) Some(encode(n, x, y, z)) else None)))

    ///
    /// Where the cubie `p` lands when layer `k` perpendicular to `axis` is given
    /// a quarter turn. A cubie outside that layer stays put.
    ///
    /// Which way it turns does not matter: a permutation and its inverse
    /// connect the same pieces.
    ///
    def rotate(n: Int32, axis: Int32, k: Int32, p: Int32): Int32 =
        let (x, y, z) = decode(n, p);
        let m = n - 1;
        match axis {
            case 0 => if (x == k) encode(n, x, z, m - y) else p
            case 1 => if (y == k) encode(n, m - z, y, x) else p
            case _ => if (z == k) encode(n, y, m - x, z) else p
        }

    ///
    /// The layers a solver is allowed to turn.
    ///
    /// The outer `n/2` layers from each of the six faces, which on an odd cube
    /// leaves the middle layer alone -- turning it would move the fixed centres
    /// that define the cube's frame of reference.
    ///
    def layers(n: Int32): List[Int32] =
        let h = n / 2;
        List.append(List.range(0, h), List.range(n - h, n))

    ///
    /// One `(from, to)` fact per piece per legal turn, identity included so that
    /// a piece nothing ever moves still shows up.
    ///
    def turns(n: Int32): List[(Int32, Int32)] =
        List.range(0, 3) |> List.flatMap(axis ->
            layers(n) |> List.flatMap(k ->
                surface(n) |> List.map(p -> (p, rotate(n, axis, k, p)))))

    ///
    /// The orbits of an `n`-cube, as connected components of the turn graph.
    ///
    /// Returns one representative-and-size pair per component.
    ///
    def components(n: Int32): List[(Int32, Int32)] =
        let facts = inject turns(n) into Turn/2;
        let rules = #{
            Same(x, y) :- Turn(x, y).
            Same(x, y) :- Same(y, x).
            Same(x, z) :- Same(x, y), Same(y, z).
        };
        let same = query facts, rules select (x, y) from Same(x, y);
        // A component is named by its least member, so every member agrees.
        let rep = same |> Vector.toList |> List.foldLeft((m, xy) -> {
            let (x, y) = xy;
            let best = Map.get(x, m) |> Option.getWithDefault(y);
            Map.insert(x, Int32.min(best, y), m)
        }, Map#{});
        let reps = Map.valuesOf(rep);
        reps |> List.distinct |> List.map(r -> (r, List.count(x -> x == r, reps)))

    ///
    /// Which kind of orbit a component of `size` pieces each showing `faces`
    /// stickers is. `None` for the fixed centres, which the format leaves out
    /// because they never move relative to one another.
    ///
    def classify(faces: Int32, size: Int32): Option[Orbit] =
        match (faces, size) {
            case (3, 8)  => Some(Corners)
            case (2, 12) => Some(Midges)
            case (2, 24) => Some(Wings)
            case (1, 24) => Some(Centers)
            case (1, 1)  => None          // a fixed centre, on an odd cube
            case _       => None
        }

    ///
    /// The layout of an `n`-cube as geometry says it is, sorted so it can be
    /// compared against `Orbit.layout` without agreeing on an order.
    ///
    pub def derivedLayout(n: Int32): List[Orbit] =
        components(n)
            |> List.filterMap(match (r, size) -> {
                let (x, y, z) = decode(n, r);
                classify(visible(n, x, y, z), size)
            })
            |> List.sort

    ///
    /// Every component is accounted for: the pieces classified, plus the fixed
    /// centres, must be every surface cubie there is.
    ///
    pub def accountedFor(n: Int32): (Int32, Int32) =
        let counted = components(n)
            |> List.map(match (_, size) -> size)
            |> List.sum;
        (counted, List.length(surface(n)))

}

// ---------- the layout, derived rather than asserted ----------

@Test
def derivedLayoutAgreesWithArithmetic(): Unit \ Assert =
    List.range(2, 8) |> List.forEach(n ->
        Assert.assertEq(
            expected = List.sort(Orbit64.Orbit.layout(n)),
            OrbitDiscovery.derivedLayout(n)))

@Test
def everySurfacePieceLandsInSomeComponent(): Unit \ Assert =
    List.range(2, 8) |> List.forEach(n -> {
        let (counted, total) = OrbitDiscovery.accountedFor(n);
        Assert.assertEq(expected = total, counted)
    })
