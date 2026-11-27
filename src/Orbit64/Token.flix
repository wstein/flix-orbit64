///
/// Tagged decoding of move, algorithm, and extension tokens.
///
/// State tokens are Orbit64 V2. This decoder does not read the retired V1
/// state class: a class-`00` token is an error, and `Orbit64.V2.Codec` is the
/// state decoder.
///
pub mod Orbit64.Token {
    /// A decoded literal move sequence, structured algorithm, or extension.
    pub enum Token with Eq, ToString {
        case MoveSequenceToken(Orbit64.Move.LayerClass, List[Orbit64.Move.Move]),
        case AlgorithmToken(Orbit64.Move.LayerClass, Orbit64.Algorithm.Algorithm),
        case ExtensionToken(Int32, String)
    }

    /// Dispatch on the two most significant bits of the first sextet.
    pub def decode(token: String): Result[String, Token] =
        if (String.isEmpty(token))
            Err("token is empty")
        else
            match Orbit64.Internal.Encoding.digitOf(String.charAt(0, token)) {
                case None        => Err("token contains a character outside the base64url alphabet")
                case Some(first) => dispatch(first / 16, token)
            }

    def dispatch(tokenClass: Int32, token: String): Result[String, Token] =
        match tokenClass {
            case 0 => Err("V1 state tokens are retired; decode state tokens with Orbit64.V2.Codec")
            case 1 => decodeMoves(token)
            case 2 => decodeAlgorithm(token)
            case _ => decodeExtension(token)
        }

    def decodeMoves(token: String): Result[String, Token] =
        Orbit64.Move.decode(token)
            |> Result.map(match (layerClass, moves) -> Token.MoveSequenceToken(layerClass, moves))

    def decodeAlgorithm(token: String): Result[String, Token] =
        Orbit64.Algorithm.Encoding.decode(token)
            |> Result.map(
                match (layerClass, algorithm) -> Token.AlgorithmToken(layerClass, algorithm)
            )

    def decodeExtension(token: String): Result[String, Token] =
        match Orbit64.Internal.Encoding.digitOf(String.charAt(0, token)) {
            case None        => Err("token contains a character outside the base64url alphabet")
            case Some(first) =>
                let id = first - 48;
                if (id < 15) extensionToken(id, String.drop(1, token)) else decodeExtendedId(token)
        }

    def decodeExtendedId(token: String): Result[String, Token] =
        if (String.length(token) < 2)
            Err("extension token ends before its extended format ID")
        else
            match Orbit64.Internal.Encoding.digitOf(String.charAt(1, token)) {
                case None     => Err("token contains a character outside the base64url alphabet")
                case Some(id) => extensionToken(15 + id, String.drop(2, token))
            }

    def extensionToken(id: Int32, payload: String): Result[String, Token] =
        match Orbit64.Internal.Encoding.fromBase64(payload) {
            case Some(_) => Ok(Token.ExtensionToken(id, payload))
            case None    =>
                Err("extension payload contains a character outside the base64url alphabet")
        }
}
