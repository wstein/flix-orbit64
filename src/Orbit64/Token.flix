///
/// Tagged decoding across the Orbit64 token family.
///
mod Orbit64.Token {

    /// A decoded state, literal move sequence, structured algorithm, or extension.
    pub enum Token with Eq, ToString {
        case StateToken(Int32, List[Orbit64.Coord.Coord]),
        case MoveSequenceToken(Orbit64.Move.LayerClass, List[Orbit64.Move.Move]),
        case AlgorithmToken(Orbit64.Move.LayerClass, Orbit64.Algorithm.Algorithm),
        case ExtensionToken(Int32, String)
    }

    /// Dispatch on the two most significant bits of the first sextet.
    pub def decode(token: String): Result[String, Token] =
        if (String.isEmpty(token)) Err("token is empty")
        else match Orbit64.Internal.Encoding.digitOf(String.charAt(0, token)) {
            case None => Err("token contains a character outside the base64url alphabet")
            case Some(first) => dispatch(first / 16, token)
        }

    def dispatch(tokenClass: Int32, token: String): Result[String, Token] =
        match tokenClass {
            case 0 => decodeState(token)
            case 1 => decodeMoves(token)
            case 2 => decodeAlgorithm(token)
            case _ => decodeExtension(token)
        }

    def decodeMoves(token: String): Result[String, Token] =
        Orbit64.Move.decode(token)
            |> Result.map(match (layerClass, moves) ->
                Token.MoveSequenceToken(layerClass, moves))

    def decodeAlgorithm(token: String): Result[String, Token] =
        Orbit64.Algorithm.Encoding.decode(token)
            |> Result.map(match (layerClass, algorithm) ->
                Token.AlgorithmToken(layerClass, algorithm))

    def decodeExtension(token: String): Result[String, Token] =
        match Orbit64.Internal.Encoding.digitOf(String.charAt(0, token)) {
            case None => Err("token contains a character outside the base64url alphabet")
            case Some(first) =>
                let id = first - 48;
                if (id < 15) extensionToken(id, String.drop(1, token))
                else decodeExtendedId(token)
        }

    def decodeExtendedId(token: String): Result[String, Token] =
        if (String.length(token) < 2) Err("extension token ends before its extended format ID")
        else match Orbit64.Internal.Encoding.digitOf(String.charAt(1, token)) {
            case None => Err("token contains a character outside the base64url alphabet")
            case Some(id) => extensionToken(15 + id, String.drop(2, token))
        }

    def extensionToken(id: Int32, payload: String): Result[String, Token] =
        match Orbit64.Internal.Encoding.fromBase64(payload) {
            case Some(_) => Ok(Token.ExtensionToken(id, payload))
            case None => Err("extension payload contains a character outside the base64url alphabet")
        }

    def decodeState(token: String): Result[String, Token] =
        match sizeForWidth(String.length(token), 2) {
            case None => Err("no cube size uses a ${String.length(token)}-character state token")
            case Some(n) => Orbit64.State.decode(n, token)
                |> Result.map(state -> Token.StateToken(n, state))
        }

    def sizeForWidth(target: Int32, n: Int32): Option[Int32] =
        let width = Orbit64.State.width(n);
        if (width == target) Some(n)
        else if (width > target) None
        else sizeForWidth(target, n + 1)

}
