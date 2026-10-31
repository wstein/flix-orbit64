///
/// Orbit64 V2 state tokens: a registry entry's rank written at its length.
///
mod Orbit64.V2.Codec {

    use Orbit64.V2.Registry.Entry
    use Orbit64.V2.State.Cube

    /// Encode a state of the registry entry `id`.
    pub def encode(id: Int32, cube: Cube): Result[String, String] =
        match Orbit64.V2.Registry.entry(id) {
            case None => Err("unknown registry entry ${id}")
            case Some(e) =>
                Result.map(r -> Orbit64.Internal.Encoding.toBase64(e#offset + r, e#length),
                           Orbit64.V2.State.rank(e#n, e#model, e#pose, cube))
        }

    /// Decode a token to its registry entry and state.
    pub def decode(token: String): Result[String, (Entry, Cube)] =
        match Orbit64.Internal.Encoding.fromBase64(token) {
            case None => Err("token contains a character outside the base64url alphabet")
            case Some(value) =>
                match Orbit64.V2.Registry.lookup(String.length(token), value) {
                    case None => Err("not a known V2 state token")
                    case Some((e, r)) =>
                        Ok((e, Orbit64.V2.State.unrank(e#n, e#model, e#pose, r)))
                }
        }

}
