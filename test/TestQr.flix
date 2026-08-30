mod TestQr {

    use Orbit64.Qr
    use Orbit64.Qr.EcLevel

    ///
    /// QR code generation produces non-empty UTF-8 block graphic encoding orbit64 token.
    ///
    @Test
    def qrCodeGeneratesNonEmptyUtf8Graphic(): Unit \ Assert =
        let qr = Qr.render("AFbO3qHtgRom");
        let qrLight = Qr.renderLight("AFbO3qHtgRom");
        let qrTok = Qr.renderWithToken("AFbO3qHtgRom");
        let hasBlock = String.contains(substr = "█", qr) or String.contains(substr = "▀", qr);
        Assert.assertTrue(hasBlock);
        Assert.assertTrue(String.length(qrLight) > 0);
        Assert.assertTrue(String.length(qrTok) > String.length(qr));
        Assert.assertTrue(String.contains(substr = "AFbO3qHtgRom", qrTok))

    ///
    /// QR code generation supports all error correction levels (L, M, Q, H).
    ///
    @Test
    def qrCodeSupportsAllEcLevels(): Unit \ Assert =
        let levels = EcLevel.L :: EcLevel.M :: EcLevel.Q :: EcLevel.H :: Nil;
        levels |> List.forEach(lvl -> {
            let qr = Qr.renderWith(lvl, true, "AFbO3qHtgRom");
            Assert.assertTrue(String.length(qr) > 0)
        })

}
