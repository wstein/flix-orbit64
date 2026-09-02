/// Connect source lowering, the Orbit64 token codec, and source reconstruction.
mod AlgorithmTool.RoundTrip {

    /// Encode source as class `10`, decode it, and reconstruct canonical source.
    pub def roundTrip(n: Int32, source: String): Result[String, (String, String)] =
        AlgorithmTool.Parser.parse(source) |> Result.flatMap(AlgorithmTool.Lowering.lower)
            |> Result.flatMap(algorithm -> Orbit64.Algorithm.Encoding.encode(n, algorithm))
            |> Result.flatMap(token ->
                Orbit64.Algorithm.Encoding.decode(token) |> Result.map(
                    match (_, decoded) -> (token, AlgorithmTool.Reconstruction.source(decoded))))

}
