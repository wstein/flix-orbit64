use orbit64::Orbit64

///
/// Prints the V2 registry and demonstrates a state-token round trip.
///
/// With an argument, decodes that V2 state token instead.
///
def main(): Unit \ { IO, Sys.Env } =
    match Sys.Env.getArgs() {
        case token :: _ => report(token)
        case Nil        => table()
    }

///
/// One row per registry entry, then the solved 3x3x3 color framed token.
///
def table(): Unit \ IO =
    println("  id   n  model    pose       chars");
    println("  --  --  -------  ---------  -----");
    Orbit64.V2.Registry.entries()
        |> List.forEach(e -> {
            let id = Int32.toString(e#id) |> String.padLeft(4, ' ');
            let n = Int32.toString(e#n) |> String.padLeft(2, ' ');
            let model = match e#model {
                case Orbit64.V2.Registry.Model.Color   => "color  "
                case Orbit64.V2.Registry.Model.Picture => "picture"
            };
            let pose = match e#pose {
                case Orbit64.V2.Registry.Pose.Canonical => "canonical"
                case Orbit64.V2.Registry.Pose.Framed    => "framed   "
            };
            let chars = Int32.toString(e#length) |> String.padLeft(5, ' ');
            println("${id}  ${n}  ${model}  ${pose}  ${chars}")
        });
    println("");
    demo()

///
/// Encode the solved 3x3x3 color framed state (registry entry 3) and read it back.
///
def demo(): Unit \ IO =
    let solved = Orbit64.V2.State.solved(3, Orbit64.V2.Registry.Model.Color);
    match Orbit64.V2.Codec.encode(3, solved) {
        case Err(e)    => println("encode failed: ${e}")
        case Ok(token) =>
            println("  solved 3x3x3 color framed encodes to ${token}");
            match Orbit64.V2.Codec.decode(token) {
                case Err(e)        => println("  decode failed: ${e}")
                case Ok((e, back)) =>
                    let again = Orbit64.V2.Codec.encode(e#id, back);
                    println("  decodes as entry ${e#id}, re-encodes: ${again == Ok(token)}")
            }
    }

///
/// Decode `token` with the V2 codec and print its facelets.
///
def report(token: String): Unit \ IO =
    match Orbit64.V2.Codec.decode(token) {
        case Err(why)      => println(why)
        case Ok((e, cube)) =>
            println(
                "entry ${e#id}: ${e#n}x${e#n}x${e#n} ${e#model} ${e#pose} (${e#length} characters)"
            );
            match Orbit64.V2.Facelets.toFacelets(e#n, e#model, e#pose, cube) {
                case Ok(text) => println(text)
                case Err(why) => println(why)
            }
    }
