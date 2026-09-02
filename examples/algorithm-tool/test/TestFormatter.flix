@Test
def formatterRoundTripsTheNativeGrammar(): Unit \ Assert =
    let source = "def a = (U R)33\ndef b = [L: U] [D, B] a'\nexport b";
    let formatted = AlgorithmTool.Parser.parse(source)
        |> Result.map(AlgorithmTool.Formatter.format);
    let expected = Ok("def a = (U R)33\ndef b = [L: U] [D, B] (a)'\nexport b\n");
    Assert.assertEq(expected = expected, formatted)
