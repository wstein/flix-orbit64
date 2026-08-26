///
/// The demo command line, kept out of the library's public surface.
///
/// A package that defines a top-level `main` cannot be depended on -- the
/// consumer's own `main` collides with it -- so this lives in a module and is
/// reached through `--entrypoint Orbit64.Cli.main`.
///
mod Orbit64.Cli {

    ///
    /// Prints the format's size table and demonstrates a round-trip.
    ///
    /// With an argument, decodes that token instead: `./flixw run -- <token>`.
    /// The token's length picks the puzzle, since no two sizes share a width.
    ///
    pub def main(): Unit \ { IO, Sys.Env } =
        // https://no-color.org -- any non-empty value means plain text.
        let colour = match Sys.Env.getVar("NO_COLOR") {
            case Some(v) => String.isEmpty(v)
            case None    => true
        };
        match Sys.Env.getArgs() {
            case token :: _ => report(token, colour)
            case Nil        => table(colour)
        }

    ///
    /// One row per cube size: how many states, how wide a token, and what the
    /// solved cube looks like.
    ///
    def table(colour: Bool): Unit \ IO =
        println("  cube      states  bits  chars");
        println("  ----  ----------  ----  -----");
        List.range(2, 8) |> List.forEach(n -> {
            let total = Orbit64.stateCount(n);
            // BigInt.log2 is the bit length, i.e. the ceiling of the real log.
            let bits = BigInt.log2(total) |> Int32.toString |> String.padLeft(4, ' ');
            let chars = Orbit64.width(n) |> Int32.toString |> String.padLeft(5, ' ');
            println("  ${n}x${n}x${n}  ${sci(total)}  ${bits}  ${chars}")
        });
        println("");
        demo(colour)

    ///
    /// Encode a scrambled 3x3x3 and read it back.
    ///
    /// The state below is the superflip: every corner solved, every edge in place
    /// but flipped. Its coordinate is exactly 2047 -- the eleven free flip bits all
    /// set, and nothing else -- which is a fair advertisement for what mixed-radix
    /// packing buys over fixed-width fields.
    ///
    def demo(colour: Bool): Unit \ IO =
        let superflip = List#{
            Orbit64.Coord.Coord.CornerCoord(Vector.range(0, 8), Vector.repeat(8, 0)),
            Orbit64.Coord.Coord.MidgeCoord(Vector.range(0, 12), Vector.repeat(12, 1))
        };
        match Orbit64.encode(3, superflip) {
            case Err(e) => println("encode failed: ${e}")
            case Ok(token) =>
                println("  superflip encodes to ${token}");
                match Orbit64.decode(3, token) {
                    case Err(e) => println("  decode failed: ${e}")
                    case Ok(back) =>
                        println("  decodes back identically: ${back == superflip}");
                        draw(3, back, colour)
                }
        }

    ///
    /// Decode `token`, inferring the cube size from its length.
    ///
    def report(token: String, colour: Bool): Unit \ IO =
        match List.range(2, 8) |> List.find(n -> Orbit64.width(n) == String.length(token)) {
            case None => println("no cube size uses a ${String.length(token)}-character token")
            case Some(n) => match Orbit64.decode(n, token) {
                case Err(e) => println("not a valid ${n}x${n}x${n} token: ${e}")
                case Ok(orbits) =>
                    println("${n}x${n}x${n}, ${List.length(orbits)} orbits:");
                    orbits |> List.forEach(c -> println("  ${Orbit64.Coord.kind(c)}: ${c}"));
                    draw(n, orbits, colour)
            }
        }

    ///
    /// Print the net, or say why there isn't one.
    ///
    def draw(n: Int32, orbits: List[Orbit64.Coord.Coord], colour: Bool): Unit \ IO =
        println("");
        match Orbit64.Net.draw(n, orbits, colour) {
            case Ok(net) =>
                println(net);
                // A token carries ordinals, not geometry. Which slot sits where
                // is agreed out of band, so the picture has to say what it read.
                println("");
                println("  drawn as ${Orbit64.Net.convention(n)}")
            // Why it declined is the library's to say. Inferring it from `n`
            // here was how the message came to claim things that were not so.
            case Err(why) => println("  (${why})")
        }

    ///
    /// A rough magnitude for `x`, as `d.dddEn`. Only for the table.
    ///
    def sci(x: BigInt): String =
        let digits = BigInt.toString(x);
        let n = String.length(digits);
        if (n <= 4) String.padLeft(10, ' ', digits)
        else
            let head = String.slice(start = 0, end = 1, digits);
            let tail = String.slice(start = 1, end = 4, digits);
            String.padLeft(10, ' ', "${head}.${tail}e${n - 1}")

}
