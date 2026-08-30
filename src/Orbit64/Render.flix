/// Reusable QR and cube-image rendering over Orbit64 facelet vectors.
mod Orbit64.Render {

    use Orbit64.Render.Qr
    use Orbit64.Render.Icon

    /// Generate a compact dark-theme QR graphic.
    pub def qr(text: String): String = Qr.render(text)

    /// Generate a compact light-theme QR graphic.
    pub def qrLight(text: String): String = Qr.renderLight(text)

    /// Generate a compact QR graphic with explicit error correction and theme.
    pub def qrWith(ec: Qr.EcLevel, darkTheme: Bool, text: String): String =
        Qr.renderWith(ec, darkTheme, text)

    /// Write a PNG QR code, optionally carrying an isometric cube-state logo.
    pub def qrWritePng(
        path: String,
        n: Int32,
        facelets: Vector[Int32],
        text: String,
        withLogo: Bool
    ): Result[String, Unit] \ IO =
        Qr.writeCubePng(path, n, facelets, text, withLogo)

    /// Write a standalone isometric cube-state PNG.
    pub def iconWritePng(
        path: String,
        n: Int32,
        facelets: Vector[Int32],
        imgSize: Int32,
        transparent: Bool
    ): Result[String, Unit] \ IO =
        Icon.writePng(path, n, facelets, imgSize, transparent)

}
