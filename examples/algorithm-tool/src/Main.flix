use Fs.FileRead
use Fs.FileWrite

/// Generate a class-`10` token and reconstructed source from native input.
def main(): Unit \ { FileRead, FileWrite, Sys.Env, IO } =
    match Sys.Env.getArgs() {
        case input :: tokenPath :: textPath :: Nil => convert(input, tokenPath, textPath)
        case _ =>
            println("usage: algorithm-tool <input.alg> <output.orbit64> <reconstructed.alg>")
    }

/// Convert native notation into its token and deterministic reconstructed form.
def convert(input: String, tokenPath: String, textPath: String):
        Unit \ { FileRead, FileWrite, IO } =
    match FileRead.read(input) {
        case Err(error) => println("cannot read ${input}: ${error}")
        case Ok(source) => match AlgorithmTool.RoundTrip.roundTrip(2, source) {
            case Err(message) => println("round trip failed: ${message}")
            case Ok((token, text)) => writeArtifacts(tokenPath, textPath, token, text)
        }
    }

/// Write both successful conversion outputs.
def writeArtifacts(tokenPath: String, textPath: String, token: String, text: String):
        Unit \ { FileWrite, IO } =
    match FileWrite.write(str = String.concat(token, "\n"), tokenPath) {
        case Err(error) => println("cannot write ${tokenPath}: ${error}")
        case Ok(_) => match FileWrite.write(str = text, textPath) {
            case Err(error) => println("cannot write ${textPath}: ${error}")
            case Ok(_) => println("wrote ${tokenPath} and ${textPath}")
        }
    }
