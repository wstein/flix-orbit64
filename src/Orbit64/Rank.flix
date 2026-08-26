///
/// Bijective rank/unrank primitives.
///
/// Every function here maps a combinatorial object onto a contiguous range of
/// integers starting at zero, and back. The codec is built entirely from these
/// three families, so the total size of a cube encoding is just the product of
/// the ranges -- no bits are lost to alignment inside a coordinate.
///
mod Orbit64.Rank {

    ///
    /// Binomial coefficient, saturating at `Int32.maxValue`. Returns `0` when
    /// `k` is out of range.
    ///
    /// The result stays in `Int32` because that is what the ranks it feeds are:
    /// the codec only ever asks for `C(24, 4)` and smaller, so the largest it
    /// really produces is `10626`. The running product is `Int64` all the same,
    /// because this is public and a caller is not bound by what the codec asks.
    /// Overflowing to a negative number would be worse than saying "very
    /// large" -- `combUnrank` searches upwards until this exceeds a rank, and a
    /// negative never does.
    ///
    /// `C(n, k) = C(n, n - k)`, and the smaller of the two is taken. That is
    /// not only cheaper: it keeps the running product monotone, so stopping
    /// early at the cap cannot skip past a final value that would have fitted.
    ///
    pub def binomial(n: Int32, k: Int32): Int32 =
        if (k < 0 or k > n) 0
        else
            let j = Int32.min(k, n - k);
            let v = Vector.range(0, j) |> Vector.foldLeft((acc, i) ->
                if (acc >= saturation()) saturation()
                else acc * Int32.toInt64(n - i) / Int32.toInt64(i + 1), 1i64);
            if (v >= saturation()) Int32.maxValue()
            else Int64.tryToInt32(v) |> Option.getWithDefault(0)

    /// `Int32.maxValue` as the running product sees it.
    def saturation(): Int64 = 2147483647i64

    ///
    /// Lexicographic (Lehmer) rank of the permutation `p` of `0..n-1`.
    ///
    /// Runs in `O(n^2)`: for each element it counts how many smaller elements
    /// follow it. At `n = 24` that is 276 comparisons, which measured cheaper
    /// than maintaining a Fenwick tree.
    ///
    pub def permRank(p: Vector[Int32]): BigInt =
        let n = Vector.length(p);
        Vector.range(0, n) |> Vector.foldLeft((acc, i) -> {
            let pi = Vector.get(i, p);
            let smaller = Vector.range(i + 1, n)
                |> Vector.count(j -> Vector.get(j, p) < pi);
            acc * Int32.toBigInt(n - i) + Int32.toBigInt(smaller)
        }, 0ii)

    ///
    /// The inverse of `permRank`: the permutation of `0..n-1` with rank `r`.
    ///
    /// Dearer than `permRank`, despite extracting its digits in a linear pass:
    /// removing the chosen element rebuilds `avail` at every digit, so the fold
    /// is quadratic in allocation. `permRank`'s quadratic inversion count
    /// allocates nothing at all, and measures about four times cheaper at
    /// `n = 24`.
    ///
    pub def permUnrank(r: BigInt, n: Int32): Vector[Int32] =
        let digits = digitsOf(r, n, 1, Nil);
        let step = (acc, d) -> {
            let (avail, out) = acc;
            let (pre, post) = List.splitAt(d, avail);
            match post {
                case y :: rest => (List.append(pre, rest), y :: out)
                case Nil       => (avail, out)
            }
        };
        let (_, rev) = List.foldLeft(step, (List.range(0, n), Nil), digits);
        List.reverse(rev) |> List.toVector

    ///
    /// Mixed-radix digits of `r` for radices `1, 2, ..., n`, most significant
    /// first. Split out so `permUnrank` reads as a single fold.
    ///
    def digitsOf(r: BigInt, n: Int32, i: Int32, acc: List[Int32]): List[Int32] =
        if (i > n) acc
        else
            let b = Int32.toBigInt(i);
            let q = r / b;
            let d = (r - q * b) |> BigInt.tryToInt32 |> Option.getWithDefault(0);
            digitsOf(q, n, i + 1, d :: acc)

    ///
    /// Colexicographic rank of a `k`-subset of `0..n-1`, in `[0, C(n, k))`.
    ///
    /// The combinatorial number system: `rank = sum C(c_i, i+1)` over the
    /// sorted elements. This is Kociemba's `UDSlice` coordinate generalised.
    ///
    pub def combRank(subset: Vector[Int32]): Int32 =
        Vector.sortBy(x -> x, subset)
            |> Vector.mapWithIndex((i, c) -> binomial(c, i + 1))
            |> Vector.sum

    ///
    /// The inverse of `combRank`.
    ///
    /// `r` is expected below `C(n, k)` for the `n` the caller has in mind --
    /// which is not a number this function is given, so it cannot check it. A
    /// rank from outside that range still returns, and still returns `k`
    /// ascending values; they are simply not a subset of anything the caller
    /// asked about.
    ///
    pub def combUnrank(r: Int32, k: Int32): Vector[Int32] =
        unrankDown(r, k, Nil) |> List.toVector

    def unrankDown(r: Int32, i: Int32, acc: List[Int32]): List[Int32] =
        if (i == 0) acc
        else
            let c = largestBelow(r, i, i - 1);
            unrankDown(r - binomial(c, i), i - 1, c :: acc)

    ///
    /// The largest `c` with `C(c, i) <= r`, found by climbing.
    ///
    /// The climb is bounded twice over, because an unbounded one is what an
    /// out-of-range `r` used to get. `binomial` saturates rather than
    /// overflowing, so it eventually exceeds any rank and the climb ends. And
    /// `C(c, i) >= c - i + 1`, so the answer can never exceed `r + i - 1` --
    /// stated as `c - i + 1 < r`, which cannot overflow the way `r + i - 1`
    /// could. Either alone would do; together the loop is finite by arithmetic
    /// rather than by trusting a value not to wrap.
    ///
    def largestBelow(r: Int32, i: Int32, c: Int32): Int32 =
        if (c - i + 1 < r and binomial(c + 1, i) <= r) largestBelow(r, i, c + 1) else c

    ///
    /// Rank an arrangement of `ntypes` labels over `n` slots, `k` copies of
    /// each, in `[0, n! / (k!)^ntypes)`.
    ///
    /// Decomposed into a chain of combination ranks -- pick the slots holding
    /// label 0, then label 1 from what remains, and so on. The last label is
    /// forced, so it contributes nothing. Every intermediate radix stays small
    /// enough for `Int32`, which is why centre orbits need no big integers
    /// until the final assembly.
    ///
    pub def multisetRank(labels: Vector[Int32], k: Int32, ntypes: Int32): BigInt =
        let n = Vector.length(labels);
        let step = (acc, t) -> {
            let (rem, value) = acc;
            let hits = rem |> List.zipWithIndex
                |> List.filter(match (_, s) -> Vector.get(s, labels) == t)
                |> List.map(match (i, _) -> i);
            let rest = rem |> List.zipWithIndex
                |> List.filter(match (i, _) -> not List.memberOf(i, hits))
                |> List.map(match (_, s) -> s);
            let radix = binomial(List.length(rem), k) |> Int32.toBigInt;
            let rank = combRank(List.toVector(hits)) |> Int32.toBigInt;
            (rest, value * radix + rank)
        };
        let (_, v) = List.foldLeft(step, (List.range(0, n), 0ii), List.range(0, ntypes - 1));
        v

    ///
    /// The inverse of `multisetRank`.
    ///
    pub def multisetUnrank(value: BigInt, n: Int32, k: Int32, ntypes: Int32): Vector[Int32] =
        let radices = List.range(0, ntypes - 1) |> List.map(t -> binomial(n - k * t, k));
        let (_, digitsRev) = List.foldLeft((acc, radix) -> {
            let (v, ds) = acc;
            let b = Int32.toBigInt(radix);
            let d = BigInt.modulo(v, b) |> BigInt.tryToInt32 |> Option.getWithDefault(0);
            (v / b, d :: ds)
        }, (value, Nil), List.reverse(radices));
        let assign = (acc, td) -> {
            let (rem, out) = acc;
            let (t, d) = td;
            let hits = combUnrank(d, k) |> Vector.toList;
            let chosen = hits |> List.filterMap(h -> List.drop(h, rem) |> List.head);
            let rest = rem |> List.filter(s -> not List.memberOf(s, chosen));
            (rest, List.append(out, chosen |> List.map(s -> (s, t))))
        };
        let pairs = List.zip(List.range(0, ntypes - 1), digitsRev);
        let (leftover, placed) = List.foldLeft(assign, (List.range(0, n), Nil), pairs);
        let full = List.append(placed, leftover |> List.map(s -> (s, ntypes - 1)));
        // `full` names every slot exactly once, so scattering into an array
        // inverts it in one pass. Sorting measured slower at `n = 24`, and
        // rebuilding it slot by slot slower still.
        region rc {
            let slots = Array.repeat(rc, n, 0);
            full |> List.forEach(match (s, t) -> Array.put(t, s, slots));
            Array.toVector(slots)
        }

}
