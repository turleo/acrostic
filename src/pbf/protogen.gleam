import gleam/dict.{type Dict}
import gleam/erlang
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import gleam/regex
import gleam/result
import gleam/string
import nibble
import nibble/lexer
import pbf/helper
import pbf/parser
import pprint
import simplifile
import sprinkle.{format}

type State {
  State(files: List(String))
}

pub type Message {
  Load(filename: String)
  Generate(client: Subject(Result(Nil, String)), out_path: String)
  Shutdown
}

pub type Self =
  Subject(Message)

pub fn load(self: Self, filename: String) {
  process.send(self, Load(filename))
  self
}

pub fn generate(self: Self, out_path: String) {
  case process.try_call(self, Generate(_, out_path), within: 10_000) {
    Ok(_) -> {
      io.println("generate done")
      self
    }
    Error(e) -> {
      io.println_error(string.inspect(e))
      self
    }
  }
}

pub fn shutdown(self: Self) {
  process.send(self, Shutdown)
}

pub fn start() -> Result(Self, actor.StartError) {
  actor.start(State([]), fn(message: Message, self: State) -> actor.Next(
    Message,
    State,
  ) {
    case message {
      Load(filename) -> {
        io.println("loading filename: " <> filename)
        actor.continue(State(files: [filename, ..self.files]))
      }
      Generate(client, out_path) -> {
        self.files
        |> list.map(fn(filepath) {
          let assert Ok(content) = simplifile.read(from: filepath)
          content
        })
        |> list.fold("", string.append)
        |> generate_proto(out_path)

        process.send(client, Ok(Nil))
        actor.continue(self)
      }
      Shutdown -> {
        actor.Stop(process.Normal)
      }
    }
  })
}

fn generate_proto(text: String, out_path: String) {
  let #(lexer, message_parser, enum_parser) = parser.parser()
  let enums = get_enums(text, lexer, enum_parser)
  let structs = get_structs(text, lexer, message_parser)
  let messages =
    get_messages(text, lexer, message_parser)
    |> list.filter(fn(msg) {
      !{ list.find(structs, fn(a) { a.name == msg.name }) |> result.is_ok }
    })

  io.println("===========" <> out_path)
  pprint.debug(enums)
  io.println("===========")
  pprint.debug(structs)
  io.println("===========")
  pprint.debug(messages)

  let assert Ok(_) = simplifile.delete(out_path)
  let assert Ok(_) =
    "import pbf/encoding.{i32_type, i64_type, len_type, varint_type}\n\n"
    |> simplifile.write(to: out_path)

  write_enums(enums, out_path)
  // write structs
  let _ = case list.length(structs) > 0 {
    True -> {
      let _ =
        simplifile.append(
          to: out_path,
          contents: "// struct start -----------------------------------\n",
        )
      write_structs(structs, out_path)
    }
    _ -> Nil
  }
  // write messages
  let _ = case list.length(messages) > 0 {
    True -> {
      let _ =
        simplifile.append(
          to: out_path,
          contents: "// messages start -----------------------------------\n",
        )
      let _ = write_messages(messages, out_path)
      Nil
    }
    _ -> Nil
  }

  helper.cmd("gleam format " <> out_path)
}

// pub type Message {
//   Ping(msg: String)
//   Pong(msg: String)
// }
fn write_messages(messages: List(parser.Message), out_path: String) {
  let assert Ok(_) =
    simplifile.append(to: out_path, contents: "pub type Message {\n")
  let assert Ok(_) =
    messages
    |> list.map(message_to_string(_, True))
    |> list.fold("", string.append)
    |> simplifile.append(to: out_path)

  let assert Ok(_) = simplifile.append(to: out_path, contents: "}\n\n")
  // encoding gen
  // pub fn encode(msg: Message) -> BitArray {
  //   case msg {
  //     ReqUseItem(session, item) -> {
  //       <<>>
  //       |> encoding.encode_int_field(1, session)
  //       |> encoding.encode_len_field(2, item, encode_item)
  //     }
  //     Hello(session, texts) -> {
  //       <<>>
  //       |> encoding.encode_int_field(1, session)
  //       |> encoding.encode_repeated_field(2, texts, encoding.encode_string, False)
  //     }
  //   }
  // }

  let body =
    messages
    |> list.map(fn(msg) {
      format(
        "
  {message} -> {
{fields}
  }
        ",
        [
          #("message", message_to_string(msg, False)),
          #(
            "fields",
            msg.fields
              |> list.map(get_field_encoding(_, ""))
              |> list.fold("<<>>\n", string.append),
          ),
        ],
      )
    })
    |> list.fold("", string.append)

  "
    pub fn encode(msg: Message) -> BitArray {
    case msg {
        {body}
    }
  }
  "
  |> format([#("body", body)])
  |> simplifile.append(to: out_path)
}

// pub type Item {
//   Item(id: Int, num: Int)
// }
fn write_structs(structs: List(parser.Message), out_path: String) {
  structs
  |> list.each(fn(struct) {
    // define gen
    let assert Ok(_) =
      simplifile.append(
        to: out_path,
        contents: "pub type " <> struct.name <> " {\n",
      )
    let assert Ok(_) =
      simplifile.append(
        to: out_path,
        contents: message_to_string(struct, True) <> "}\n\n",
      )
    // encoding gen
    // fn encode_item(item: Item) -> BitArray {
    //   <<>>
    //   |> encoding.encode_int_field(1, item.id)
    //   |> encoding.encode_int_field(2, item.num)
    // }
    format(
      "
pub fn encode_{name}({name}: {type}) -> BitArray {
  {body}
}

",
      [
        #("name", pascal_to_snake(struct.name)),
        #("type", struct.name),
        #(
          "body",
          struct.fields
            |> list.map(get_field_encoding(
              _,
              pascal_to_snake(struct.name) <> ".",
            ))
            |> list.fold("<<>>\n", string.append),
        ),
      ],
    )
    |> simplifile.append(to: out_path)
  })
}

//   |> encoding.encode_int_field(1, item.id, varint_type)
fn get_field_encoding(field: parser.Field, field_prefix: String) -> String {
  case field.repeated {
    True ->
      format(
        "  |> encoding.encode_repeated_field({tag}, {value}, {encoder}, {packed})\n",
        [
          #("tag", int.to_string(field.tag)),
          #("value", field_prefix <> field.name),
          #("encoder", get_encoder_and_packed(field.ty).0),
          #("packed", get_encoder_and_packed(field.ty).1),
        ],
      )
    False -> {
      case to_gleam_ty(field.ty, False) {
        "Int" ->
          format("  |> encoding.encode_int_field({tag}, {value})\n", [
            #("tag", int.to_string(field.tag)),
            #("value", field_prefix <> field.name),
          ])
        "Float" ->
          format(
            "  |> encoding.encode_float_field({tag}, {value}, {wire_type})\n",
            [
              #("tag", int.to_string(field.tag)),
              #("value", field_prefix <> field.name),
              #("wire_type", float_wire_type(field.ty) <> "_type"),
            ],
          )
        "Bool" ->
          format("  |> encoding.encode_bool_field({tag}, {value})\n", [
            #("tag", int.to_string(field.tag)),
            #("value", field_prefix <> field.name),
          ])
        "String" ->
          format("  |> encoding.encode_len_field({tag}, {value}, {encoder})\n", [
            #("tag", int.to_string(field.tag)),
            #("value", field_prefix <> field.name),
            #("encoder", "encoding.encode_string"),
          ])
        x ->
          // Enum or Struct
          format("  |> encoding.encode_len_field({tag}, {value}, {encoder})\n", [
            #("tag", int.to_string(field.tag)),
            #("value", field_prefix <> field.name),
            #("encoder", "encode_" <> pascal_to_snake(x)),
          ])
      }
    }
  }
}

fn get_encoder_and_packed(ty: String) -> #(String, String) {
  case to_gleam_ty(ty, False) {
    "Int" -> #("encoding.encode_varint", "True")
    "Bool" -> #("encoding.encode_bool", "True")
    "Float" -> #("encoding.encode_" <> float_wire_type(ty), "True")
    "String" -> #("encoding.encode_string", "False")
    // Enum or Struct
    x -> #("encode_" <> pascal_to_snake(x), "False")
  }
}

fn float_wire_type(ty: String) -> String {
  case ty {
    "fixed32" | "sfixed32" | "float" -> "i32"
    "fixed64" | "sfixed64" | "double" -> "i64"
    x -> panic as { "Invalid float type: " <> x }
  }
}

// pub type Season {
//   Spring
//   Summer
// }
fn write_enums(enums: List(parser.PbEnum), out_path: String) {
  enums
  |> list.each(fn(enum) {
    // define gen
    let assert Ok(_) =
      simplifile.append(
        to: out_path,
        contents: "pub type " <> enum.name <> " {\n",
      )
    enum.fields
    |> list.each(fn(field) {
      let assert Ok(_) =
        simplifile.append(to: out_path, contents: "  " <> field.name <> "\n")
    })
    let assert Ok(_) = simplifile.append(to: out_path, contents: "}\n\n")

    // encoding gen

    // pub fn encode_item(item: Item) -> BitArray {
    //   ...
    // }
    format(
      "
pub fn encode_{name}({name}: {type}) -> BitArray {
  {body}
}

",
      [
        #("name", pascal_to_snake(enum.name)),
        #("type", enum.name),
        #(
          "body",
          enum.fields
            |> list.map(fn(f) {
              format("    {key} -> encoding.encode_varint({value})\n", [
                #("key", f.name),
                #("value", int.to_string(f.tag)),
              ])
            })
            |> list.fold(
              "case " <> pascal_to_snake(enum.name) <> " {\n",
              string.append,
            )
            |> string.append("  }"),
        ),
      ],
    )
    |> simplifile.append(to: out_path)
  })
}

fn get_enums(text: String, lexer, parser) {
  let assert Ok(re) = regex.from_string("enum\\s+\\w+\\s*{[^{}]*}")
  regex.scan(re, text)
  |> list.map(fn(a) {
    let assert Ok(tokens) = lexer.run(a.content, lexer)
    let assert Ok(enum) = nibble.run(tokens, parser)
    enum
  })
}

fn get_structs(text: String, lexer, parser) {
  let assert Ok(re) =
    regex.from_string(
      "//\\s*@gleam\\s+struct\\s*\nmessage\\s+\\w+\\s*{((?:.|\n)*?)}",
    )
  regex.scan(re, text)
  |> list.map(fn(a) {
    let assert Ok(tokens) = lexer.run(a.content, lexer)
    let assert Ok(message) = nibble.run(tokens, parser)
    message
  })
}

fn get_messages(text: String, lexer, parser) {
  let assert Ok(re) = regex.from_string("message\\s+\\w+\\s*{[^{}]*}")
  regex.scan(re, text)
  |> list.map(fn(a) {
    let assert Ok(tokens) = lexer.run(a.content, lexer)
    let assert Ok(message) = nibble.run(tokens, parser)
    message
  })
}

// "  Item(id: Int, num: Int)\n"
fn message_to_string(message: parser.Message, type_suffix: Bool) -> String {
  case list.length(message.fields) > 0 {
    True -> {
      format("  {name}({body})\n", [
        #("name", message.name),
        #("body", {
          message.fields
          |> list.map(fn(f) {
            case type_suffix {
              True -> f.name <> ": " <> to_gleam_ty(f.ty, f.repeated)
              False -> f.name
            }
          })
          |> list.fold("", fn(a, b) { a <> b <> ", " })
          |> string.drop_right(2)
        }),
      ])
    }
    False -> "  " <> message.name <> "\n"
  }
}

// varint: int32, int64, uint32, uint64, bool, enum
// i64: fixed64, sfixed64, double
// i32: fixed32, sfixed32, float
fn to_gleam_ty(ty: String, repeated: Bool) -> String {
  let ty = case ty {
    // string
    "string" -> "String"
    // varint
    "int32" | "int64" | "uint32" | "uint64" -> "Int"
    "bool" -> "Bool"
    // i64
    "fixed64" | "sfixed64" | "double" -> "Float"
    // i32
    "fixed32" | "sfixed32" | "float" -> "Float"
    // Custom Type (Struct | Enum)
    x -> x
  }
  case repeated {
    True -> "List(" <> ty <> ")"
    False -> ty
  }
}

fn pascal_to_snake(ident: String) -> String {
  let assert Ok(re) = regex.from_string("[A-Z][a-z]*")
  regex.scan(re, ident)
  |> list.map(fn(a) { a.content })
  |> list.map(fn(a) { string.lowercase(a) })
  |> list.fold("", fn(a, b) { a <> "_" <> b })
  |> string.drop_left(1)
}
