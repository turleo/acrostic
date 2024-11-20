import gleam/option.{None, Some}
import gleam/set
import nibble.{do, return}
import nibble/lexer

pub type PbMessageField {
  Field(repeated: Bool, ty: String, name: String, tag: Int)
}

pub type PbMessage {
  Message(name: String, fields: List(PbMessageField))
}

pub type PbEnumField {
  PbEnumField(name: String, tag: Int)
}

pub type PbEnum {
  PbEnum(name: String, fields: List(PbEnumField))
}

pub type Token {
  MessageKeyword
  EnumKeyword
  LeftCurly
  RightCurly
  Repeated
  Equals
  Semicolon
  Num(Int)
  Comment(String)
  PascalIdentifier(String)
  SnakeIdentifier(String)
  Identifier(String)
}

pub fn parser() {
  let lexer =
    lexer.simple([
      lexer.keyword("message", "\\W", MessageKeyword),
      lexer.keyword("enum", "\\W", EnumKeyword),
      lexer.token("{", LeftCurly),
      lexer.token("}", RightCurly),
      lexer.keyword("repeated", "\\W", Repeated),
      lexer.token("=", Equals),
      lexer.token(";", Semicolon),
      lexer.int(Num),
      lexer.identifier("[A-Z]", "[a-zA-Z0-9_]", set.new(), PascalIdentifier),
      lexer.variable(set.new(), SnakeIdentifier),
      lexer.comment("//", Comment) |> lexer.ignore,
      lexer.whitespace(Nil) |> lexer.ignore,
    ])

  let parse_pascal_identifier = {
    use tok <- nibble.take_map("Expected PascalCase identifier")
    case tok {
      PascalIdentifier(str) -> Some(str)
      _ -> None
    }
  }

  let parse_snake_identifier = {
    use tok <- nibble.take_map("Expected snake_case identifier")
    case tok {
      SnakeIdentifier(str) -> Some(str)
      _ -> None
    }
  }

  let parse_identifier = {
    use tok <- nibble.take_map("Expected identifier")
    case tok {
      SnakeIdentifier(str) -> Some(str)
      PascalIdentifier(str) -> Some(str)
      _ -> None
    }
  }

  let parse_num = {
    use tok <- nibble.take_map("Expected number")
    case tok {
      Num(num) -> Some(num)
      _ -> None
    }
  }

  let parse_field = {
    use repeated <- do(nibble.optional(nibble.token(Repeated)))
    use ty <- do(parse_identifier)
    use name <- do(parse_snake_identifier)
    use _ <- do(nibble.token(Equals))
    use tag <- do(parse_num)
    use _ <- do(nibble.token(Semicolon))
    return(Field(option.is_some(repeated), ty:, name:, tag:))
  }

  let parse_enum_field = {
    use name <- do(parse_pascal_identifier)
    use _ <- do(nibble.token(Equals))
    use tag <- do(parse_num)
    use _ <- do(nibble.token(Semicolon))
    return(PbEnumField(name:, tag:))
  }

  let message_parser = {
    use _ <- do(nibble.token(MessageKeyword))
    use message_name <- do(parse_pascal_identifier)
    use _ <- do(nibble.token(LeftCurly))
    // TODO: should this be many1?
    use fields <- do(nibble.many(parse_field))
    use _ <- do(nibble.token(RightCurly))

    return(Message(message_name, fields))
  }

  let enum_parser = {
    use _ <- do(nibble.token(EnumKeyword))
    use enum_name <- do(parse_pascal_identifier)
    use _ <- do(nibble.token(LeftCurly))
    use fields <- do(nibble.many(parse_enum_field))
    use _ <- do(nibble.token(RightCurly))
    return(PbEnum(enum_name, fields))
  }

  #(lexer, message_parser, enum_parser)
}
