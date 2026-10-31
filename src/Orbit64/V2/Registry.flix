///
/// The Orbit64 V2 registry of puzzle types (see `FORMAT-V2.md`).
///
/// Entries are placed in registry order. Each takes the shortest token length
/// whose unallocated values still hold all its states, and starts directly
/// after the entries already placed at that length. Appending an entry
/// therefore never changes an earlier entry's length or offset.
///
mod Orbit64.V2.Registry {

    /// How much of a sticker is visible: colors only, or every sticker distinct.
    pub enum Model with Eq, Order, ToString {
        case Color
        case Picture
    }

    /// Whether the whole-cube orientation is part of the state.
    pub enum Pose with Eq, Order, ToString {
        case Canonical
        case Framed
    }

    /// One puzzle type with its allocated token range.
    pub type alias Entry = {
        id = Int32, n = Int32, model = Model, pose = Pose,
        length = Int32, offset = BigInt, count = BigInt
    }

    /// The types of the initial registry, in registry order, as `(n, model, pose)`.
    pub def initialTypes(): List[(Int32, Model, Pose)] =
        List.range(2, 16) |> List.flatMap(n ->
            let color = (n, Model.Color, Pose.Canonical) :: (n, Model.Color, Pose.Framed) :: Nil;
            if (n == 2) color
            else List.append(color,
                (n, Model.Picture, Pose.Canonical) :: (n, Model.Picture, Pose.Framed) :: Nil))

    /// Every entry of the registry with its length and offset, in ID order.
    pub def entries(): List[Entry] = allocate(initialTypes())

    /// Place `types` in order with the allocation rule.
    pub def allocate(types: List[(Int32, Model, Pose)]): List[Entry] =
        let step = (acc, t) -> {
            let (used, out) = acc;
            let (n, model, pose) = t;
            let count = Orbit64.V2.State.count(n, model, pose);
            let id = List.length(out);
            let length = shortest(used, count);
            let offset = Map.getWithDefault(length, 0ii, used);
            let entry = { id = id, n = n, model = model, pose = pose,
                          length = length, offset = offset, count = count };
            (Map.insert(length, offset + count, used), entry :: out)
        };
        let (_, out) = List.foldLeft(step, (Map.empty(), Nil), types);
        List.reverse(out)

    /// The least length `L >= 1` with `used(L) + count <= 64^L`.
    def shortest(used: Map[Int32, BigInt], count: BigInt): Int32 = shortestLoop(used, count, 1, 64ii)

    def shortestLoop(used: Map[Int32, BigInt], count: BigInt, length: Int32, capacity: BigInt): Int32 =
        if (Map.getWithDefault(length, 0ii, used) + count <= capacity) length
        else shortestLoop(used, count, length + 1, capacity * 64ii)

    def holds(e: Entry, value: BigInt): Bool = e#offset <= value and value < e#offset + e#count

    /// The entry with the given ID, if the registry has one.
    pub def entry(id: Int32): Option[Entry] =
        entries() |> List.find(e -> e#id == id)

    /// The entry and rank a token of the given length and value addresses.
    pub def lookup(length: Int32, value: BigInt): Option[(Entry, BigInt)] =
        entries() |> List.find(e -> e#length == length and holds(e, value))
                  |> Option.map(e -> (e, value - e#offset))

}
