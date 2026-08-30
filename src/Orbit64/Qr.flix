///
/// Backwards-compatible QR rendering entry points.
///
/// New code should use `Orbit64.Render.Qr`; this module remains because it was
/// public in Orbit64 0.3 and QR generation does not need cube-solving state.
///
mod Orbit64.Qr {

    use Orbit64.Render.Qr

    /// QR error-correction level.
    pub enum EcLevel with Eq, Order, ToString {
        case L
        case M
        case Q
        case H
    }

    /// Generate a compact dark-theme QR graphic.
    pub def render(text: String): String =
        Qr.render(text)

    /// Generate a compact light-theme QR graphic.
    pub def renderLight(text: String): String =
        Qr.renderLight(text)

    /// Generate a compact QR graphic with the token centred beneath it.
    pub def renderWithToken(token: String): String =
        Qr.renderWithToken(token)

    /// Generate a compact QR graphic with explicit error correction and theme.
    pub def renderWith(ec: EcLevel, darkTheme: Bool, text: String): String =
        Qr.renderWith(renderLevel(ec), darkTheme, text)

    def renderLevel(ec: EcLevel): Qr.EcLevel = match ec {
        case EcLevel.L => Qr.EcLevel.L
        case EcLevel.M => Qr.EcLevel.M
        case EcLevel.Q => Qr.EcLevel.Q
        case EcLevel.H => Qr.EcLevel.H
    }

}
