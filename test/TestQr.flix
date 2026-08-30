mod TestQr {

    use Orbit64.Qr
    use Orbit64.Qr.EcLevel
    use Orbit64.Render

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

    /// The new rendering namespace offers the same pure QR contract.
    @Test
    def renderNamespaceKeepsTheTerminalQrContract(): Unit \ Assert =
        let qr = Render.qrWith(Orbit64.Render.Qr.EcLevel.H, true, "AFbO3qHtgRom");
        Assert.assertTrue(String.contains(substr = "█", qr) or String.contains(substr = "▀", qr))

    /// PNG writers operate on Orbit64's size and facelet-vector interchange,
    /// without depending on a solver-specific cube representation.
    @Test
    def renderersWriteQrAndCubeImages(): Unit \ { Assert, IO } =
        let facelets = Vector.range(0, 54) |> Vector.map(i -> i / 9);
        Assert.assertEq(expected = Ok(()),
            Render.qrWritePng("build/test_qr_logo.png", 3, facelets, "AFbO3qHtgRom", true));
        Assert.assertEq(expected = Ok(()),
            Render.iconWritePng("build/test_cube_icon.png", 3, facelets, 256, true))

}
