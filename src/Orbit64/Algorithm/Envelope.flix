// SPDX-License-Identifier: Apache-2.0
/// A separate, lossless, canonical JSON envelope for finite algorithm DAGs.
/// This additive review-draft API does not change V1 or the V2 state registry.
mod Orbit64.Algorithm.Envelope {
    use Orbit64.Algorithm.Algorithm.Algorithm

    /// Distinguish local policy, resource exhaustion, malformed wire and invalid graphs.
    pub enum Fault with Eq, ToString {
        case InvalidLimits(String)
        case ResourceLimit(String)
        case Malformed(String)
        case InvalidGraph(String)
        case NonCanonical
    }

    /// Local resource policy, independent of graph semantics and expanded move count.
    pub type alias Limits = {
        maxInputChars = Int32, maxNodes = Int32, maxReferences = Int32,
        maxSymbols = Int32, maxCountDigits = Int32, maxDepth = Int32,
        maxJsonDepth = Int32, maxMetadataWork = Int32
    }

    /// Conservative reference ceilings; callers may lower each positive budget.
    pub def defaultLimits(): Limits = {
        maxInputChars = 1048576, maxNodes = 4096, maxReferences = 65536,
        maxSymbols = 65536, maxCountDigits = 4096, maxDepth = 256,
        maxJsonDepth = 8, maxMetadataWork = 1048576
    }

    /// Encode the entire graph with the default resource policy, without expansion.
    pub def encode(n: Int32, graph: Orbit64.Algorithm.Algorithm): Result[Fault, String] =
        encodeWith(defaultLimits(), n, graph)

    /// Decode canonical ASCII JSON with the default resource policy.
    pub def decode(text: String): Result[Fault, (Int32, Orbit64.Algorithm.Algorithm)] =
        decodeWith(defaultLimits(), text)

    /// Validate resource use and semantics before rendering canonical JSON.
    pub def encodeWith(limits: Limits, n: Int32, graph: Orbit64.Algorithm.Algorithm):
            Result[Fault, String] =
        let Algorithm(nodes, _) = graph;
        Orbit64.Internal.AlgorithmEnvelopeBudget.settings(limits)
            |> Result.flatMap(_ -> Orbit64.Internal.AlgorithmEnvelopeBudget.graph(limits, nodes))
            |> Result.flatMap(_ -> semantic(n, graph))
            |> Result.flatMap(_ -> render(limits, n, graph))

    def render(limits: Limits, n: Int32, graph: Orbit64.Algorithm.Algorithm):
            Result[Fault, String] =
        let text = Orbit64.Internal.AlgorithmEnvelopeJson.write(n, graph);
        Orbit64.Internal.AlgorithmEnvelopeBudget.input(limits, text) |> Result.map(_ -> text)

    /// Preflight parsing, retain every node field, and reject noncanonical spelling.
    pub def decodeWith(limits: Limits, text: String):
            Result[Fault, (Int32, Orbit64.Algorithm.Algorithm)] =
        Orbit64.Internal.AlgorithmEnvelopeBudget.settings(limits)
            |> Result.flatMap(_ -> Orbit64.Internal.AlgorithmEnvelopeBudget.input(limits, text))
            |> Result.flatMap(_ -> Util.Json.parse(text)
                |> Result.mapErr(_ -> Fault.Malformed("invalid JSON")))
            |> Result.flatMap(json -> Orbit64.Internal.AlgorithmEnvelopeJson.read(
                    limits#maxCountDigits, limits#maxNodes,
                    Int32.max(limits#maxReferences, limits#maxSymbols), json)
                |> Result.mapErr(readFault))
            |> Result.flatMap(pair -> validateSpelling(limits, text, pair))

    def validateSpelling(limits: Limits, text: String,
                         pair: (Int32, Orbit64.Algorithm.Algorithm)):
            Result[Fault, (Int32, Orbit64.Algorithm.Algorithm)] =
        let (n, graph) = pair;
        encodeWith(limits, n, graph)
            |> Result.flatMap(canonical -> sameSpelling(canonical, text))
            |> Result.map(_ -> pair)

    def semantic(n: Int32, graph: Orbit64.Algorithm.Algorithm): Result[Fault, Unit] =
        match Orbit64.Algorithm.faultOf(n, graph) {
            case Some(why) => Err(Fault.InvalidGraph(why))
            case None => Ok(())
        }

    def sameSpelling(canonical: String, text: String): Result[Fault, Unit] =
        if (canonical == text) Ok(()) else Err(Fault.NonCanonical)

    def readFault(why: String): Fault = match why {
        case "repeat count digit budget exceeded" => Fault.ResourceLimit(why)
        case "node budget exceeded" => Fault.ResourceLimit(why)
        case "stored index-list budget exceeded" => Fault.ResourceLimit(why)
        case _ => Fault.Malformed(why)
    }
}
