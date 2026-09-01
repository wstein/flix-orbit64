///
/// Tagged decoding across the Orbit64 token family.
///
mod Orbit64.Token {

    /// A decoded state, literal move sequence, or move SLP with its cube size.
    pub enum Token with Eq, ToString {
        case StateToken(Int32, List[Orbit64.Coord.Coord]),
        case MoveSequenceToken(Int32, List[Orbit64.Move.Move]),
        case MoveSlpToken(Int32, Orbit64.Move.Slp.Slp)
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
            case 2 => decodeSlp(token)
            case _ => Err("token class 11 is reserved")
        }

    def decodeMoves(token: String): Result[String, Token] =
        Orbit64.Move.decode(token)
            |> Result.map(match (n, moves) -> Token.MoveSequenceToken(n, moves))

    def decodeSlp(token: String): Result[String, Token] =
        Orbit64.Move.Slp.decode(token)
            |> Result.map(match (n, slp) -> Token.MoveSlpToken(n, slp))

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
