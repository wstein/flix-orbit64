/// Parser for the compact native Orbit64 algorithm source grammar.
mod AlgorithmTool.Parser {

    use AlgorithmTool.Ast.Program.{Program}
    use AlgorithmTool.Ast.Definition.{Definition}
    use AlgorithmTool.Ast.Expr.{Move, Reference, Concat, Repeat, Inverse}
    use AlgorithmTool.Ast.Expr.{Conjugate, Commutator, Slice}
    use AlgorithmTool.Parser.Token.{Name, Terminal, Number, Def, Export, Equals, LeftParen}
    use AlgorithmTool.Parser.Token.{RightParen, LeftBracket, RightBracket, Colon, Comma, Prime}
    use Orbit64.Move.Move.{LayerTurn}
    use Orbit64.Move.Face.{U, R, F, D, L, B}
    use Orbit64.Move.Amount.{Clockwise, Half}

    enum Token {
        case Name(String)
        case Terminal(Orbit64.Move.Move)
        case Number(BigInt)
        case Def
        case Export
        case Equals
        case LeftParen
        case RightParen
        case LeftBracket
        case RightBracket
        case Colon
        case Comma
        case Prime
    }

    /// Parse a complete program with ordered definitions and one export.
    pub def parse(source: String): Result[String, AlgorithmTool.Ast.Program] =
        lex(String.toList(source), Nil) |> Result.flatMap(tokens ->
            parseDefinitions(tokens, Nil) |> Result.flatMap(match (definitions, export, rest) ->
                if (List.isEmpty(rest)) Ok(Program(definitions, export))
                else Err("unexpected token after export")))

    def lex(chars: List[Char], out: List[Token]): Result[String, List[Token]] = match chars {
        case Nil => finishLex(out)
        case '#' :: rest => lexComment(rest, out)
        case c :: rest if Char.isWhitespace(c) => lexWhitespace(rest, out)
        case c :: rest => lexCharacter(c, rest, out)
    }

    def finishLex(out: List[Token]): Result[String, List[Token]] = Ok(List.reverse(out))

    def lexComment(rest: List[Char], out: List[Token]): Result[String, List[Token]] =
        lex(dropComment(rest), out)

    def lexWhitespace(rest: List[Char], out: List[Token]): Result[String, List[Token]] =
        lex(rest, out)

    def lexCharacter(c: Char, rest: List[Char], out: List[Token]): Result[String, List[Token]] =
        match punctuation(c) {
            case Some(token) => lex(rest, token :: out)
            case None => lexWordOrError(c, rest, out)
        }

    def lexWordOrError(c: Char, rest: List[Char], out: List[Token]): Result[String, List[Token]] =
        if (Char.isLetterOrDigit(c) or c == '_')
            let (word, afterWord) = takeWord(rest, c :: Nil);
            classify(word) |> Result.flatMap(token -> lex(afterWord, token :: out))
        else Err("unexpected character '${Char.toString(c)}'")

    def punctuation(c: Char): Option[Token] = match c {
        case '=' => Some(Equals)
        case '(' => Some(LeftParen)
        case ')' => Some(RightParen)
        case '[' => Some(LeftBracket)
        case ']' => Some(RightBracket)
        case ':' => Some(Colon)
        case ',' => Some(Comma)
        case '\'' => Some(Prime)
        case _ => None
    }

    def dropComment(chars: List[Char]): List[Char] = match chars {
        case Nil => Nil
        case '\n' :: rest => rest
        case _ :: rest => dropComment(rest)
    }

    def takeWord(chars: List[Char], reversed: List[Char]): (String, List[Char]) = match chars {
        case c :: rest if Char.isLetterOrDigit(c) or c == '_' =>
            takeWord(rest, c :: reversed)
        case _ => (charsToString(List.reverse(reversed)), chars)
    }

    def charsToString(chars: List[Char]): String = match chars {
        case Nil => ""
        case c :: rest => String.concat(Char.toString(c), charsToString(rest))
    }

    def classify(word: String): Result[String, Token] = match keyword(word) {
        case Some(token) => Ok(token)
        case None => classifyValue(word)
    }

    def keyword(word: String): Option[Token] =
        if (word == "def") Some(Def)
        else if (word == "export") Some(Export)
        else None

    def classifyValue(word: String): Result[String, Token] = match moveOf(word) {
            case Some(move) => Ok(Terminal(move))
            case None => match BigInt.fromString(word) {
                case Some(value) => Ok(Number(value))
                case None => Ok(Name(word))
            }
    }

    def moveOf(word: String): Option[Orbit64.Move.Move] = match word {
        case "U" => Some(LayerTurn(U, 0, Clockwise))
        case "R" => Some(LayerTurn(R, 0, Clockwise))
        case "F" => Some(LayerTurn(F, 0, Clockwise))
        case "D" => Some(LayerTurn(D, 0, Clockwise))
        case "L" => Some(LayerTurn(L, 0, Clockwise))
        case "B" => Some(LayerTurn(B, 0, Clockwise))
        case "U2" => Some(LayerTurn(U, 0, Half))
        case "R2" => Some(LayerTurn(R, 0, Half))
        case "F2" => Some(LayerTurn(F, 0, Half))
        case "D2" => Some(LayerTurn(D, 0, Half))
        case "L2" => Some(LayerTurn(L, 0, Half))
        case "B2" => Some(LayerTurn(B, 0, Half))
        case _ => None
    }

    def parseDefinitions(tokens: List[Token], out: List[AlgorithmTool.Ast.Definition]):
            Result[String, (List[AlgorithmTool.Ast.Definition], String,
                List[Token])] = match tokens {
        case Def :: Name(name) :: Equals :: rest =>
            parseExpr(rest) |> Result.flatMap(match (body, afterBody) ->
                parseDefinitions(afterBody, Definition(name, body) :: out))
        case Export :: Name(name) :: rest => Ok((List.reverse(out), name, rest))
        case Nil => Err("program has no export")
        case _ => Err("expected 'def' or 'export'")
    }

    def parseExpr(tokens: List[Token]): Result[String, (AlgorithmTool.Ast.Expr, List[Token])] =
        parseTerms(tokens, Nil)

    def parseTerms(tokens: List[Token], out: List[AlgorithmTool.Ast.Expr]):
            Result[String, (AlgorithmTool.Ast.Expr, List[Token])] = match tokens {
        case Nil => finishTerms(out, Nil)
        case Def :: _ => finishTerms(out, tokens)
        case Export :: _ => finishTerms(out, tokens)
        case RightParen :: _ => finishTerms(out, tokens)
        case RightBracket :: _ => finishTerms(out, tokens)
        case Colon :: _ => finishTerms(out, tokens)
        case Comma :: _ => finishTerms(out, tokens)
        case _ => parsePostfix(tokens) |> Result.flatMap(match (term, rest) ->
            parseTerms(rest, term :: out))
    }

    def finishTerms(reversed: List[AlgorithmTool.Ast.Expr], rest: List[Token]):
            Result[String, (AlgorithmTool.Ast.Expr, List[Token])] =
        match List.reverse(reversed) {
            case Nil => Err("expected an expression")
            case expression :: Nil => Ok((expression, rest))
            case expressions => Ok((Concat(expressions), rest))
        }

    def parsePostfix(tokens: List[Token]): Result[String, (AlgorithmTool.Ast.Expr, List[Token])] =
        parsePrimary(tokens) |> Result.flatMap(match (primary, rest) ->
            parseSuffixes(primary, rest))

    def parseSuffixes(expression: AlgorithmTool.Ast.Expr, tokens: List[Token]):
            Result[String, (AlgorithmTool.Ast.Expr, List[Token])] = match tokens {
        case Prime :: rest => parseSuffixes(Inverse(expression), rest)
        case Number(count) :: rest =>
            if (count <= 0ii) Err("repeat count must be positive")
            else parseSuffixes(Repeat(expression, count), rest)
        case _ => Ok((expression, tokens))
    }

    def parsePrimary(tokens: List[Token]): Result[String, (AlgorithmTool.Ast.Expr, List[Token])] =
        match tokens {
            case Terminal(move) :: rest => Ok((Move(move), rest))
            case Name(name) :: LeftBracket :: rest => parseSlice(name, rest)
            case Name(name) :: rest => Ok((Reference(name), rest))
            case LeftParen :: rest => parseParenthesized(rest)
            case LeftBracket :: rest => parseBracket(rest)
            case _ => Err("expected a move, name, '(', or '['")
        }

    def parseParenthesized(tokens: List[Token]):
            Result[String, (AlgorithmTool.Ast.Expr, List[Token])] =
        parseExpr(tokens) |> Result.flatMap(match (body, afterBody) ->
            closeParenthesis(body, afterBody))

    def closeParenthesis(expression: AlgorithmTool.Ast.Expr, tokens: List[Token]):
            Result[String, (AlgorithmTool.Ast.Expr, List[Token])] = match tokens {
        case RightParen :: rest => Ok((expression, rest))
        case _ => Err("expected ')'")
    }

    def parseBracket(tokens: List[Token]): Result[String, (AlgorithmTool.Ast.Expr, List[Token])] =
        parseExpr(tokens) |> Result.flatMap(match (left, afterLeft) ->
            parseBracketOperator(left, afterLeft))

    def parseBracketOperator(left: AlgorithmTool.Ast.Expr, tokens: List[Token]):
            Result[String, (AlgorithmTool.Ast.Expr, List[Token])] = match tokens {
        case Colon :: rest => parseRightBracket(left, rest, true)
        case Comma :: rest => parseRightBracket(left, rest, false)
        case _ => Err("expected ':' or ',' in '[' expression")
    }

    def parseRightBracket(left: AlgorithmTool.Ast.Expr, tokens: List[Token],
                          conjugate: Bool): Result[String, (AlgorithmTool.Ast.Expr, List[Token])] =
        parseExpr(tokens) |> Result.flatMap(match (right, afterRight) ->
            let expression = if (conjugate) Conjugate(left, right) else Commutator(left, right);
            closeBracket(expression, afterRight))

    def closeBracket(expression: AlgorithmTool.Ast.Expr, tokens: List[Token]):
            Result[String, (AlgorithmTool.Ast.Expr, List[Token])] = match tokens {
        case RightBracket :: rest => Ok((expression, rest))
        case _ => Err("expected ']'")
    }

    def parseSlice(name: String, tokens: List[Token]):
            Result[String, (AlgorithmTool.Ast.Expr, List[Token])] =
        match tokens {
            case Number(start) :: Colon :: Number(end) :: RightBracket :: rest =>
                sliceExpression(name, start, end, rest)
            case Number(start) :: RightBracket :: rest =>
                sliceExpression(name, start, start + 1ii, rest)
            case Number(start) :: Colon :: RightBracket :: rest =>
                sliceExpression(name, start, 2147483647ii, rest)
            case Colon :: Number(end) :: RightBracket :: rest =>
                sliceExpression(name, 0ii, end, rest)
            case _ => Err("expected a zero-based slice range")
        }

    def sliceExpression(name: String, start: BigInt, end: BigInt, rest: List[Token]):
            Result[String, (AlgorithmTool.Ast.Expr, List[Token])] =
        match (BigInt.tryToInt32(start), BigInt.tryToInt32(end)) {
            case (Some(first), Some(last)) if first >= 0 and last >= first =>
                Ok((Slice(name, first, last), rest))
            case _ => Err("slice bounds must be non-negative Int32 values")
        }

}
