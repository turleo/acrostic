import gleam/int
import gleam/list
import gleam/regex
import gleam/result
import gleam/string
import nibble
import nibble/lexer
import pb/helper
import pb/parser
import simplifile
import sprinkle.{format}

pub fn generate_proto(text: String, out_path: String) {
  let #(lexer, message_parser, enum_parser) = parser.parser()
  let enums = get_enums(text, lexer, enum_parser)
  let structs = get_structs(text, lexer, message_parser)
  let messages =
    get_messages(text, lexer, message_parser)
    |> list.filter(fn(msg) {
      !{ list.find(structs, fn(a) { a.name == msg.name }) |> result.is_ok }
    })

  let assert Ok(_) =
    "
    import gleam/list
    import pb/encoding
    import pb/decoding
    "
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

// f.name <> ": " <> to_gleam_ty(f.ty, f.repeated)
fn write_messages(messages: List(parser.Message), out_path: String) {
  let assert Ok(_) =
    simplifile.append(to: out_path, contents: "pub type Message {\n")
  let assert Ok(_) =
    messages
    |> list.map(message_to_string(_, fn(field) {
      field.name <> ": " <> to_gleam_ty(field.ty, field.repeated)
    }))
    |> list.fold("", string.append)
    |> simplifile.append(to: out_path)

  let assert Ok(_) = simplifile.append(to: out_path, contents: "}\n\n")

  // encoding gen
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
          #("message", message_to_string(msg, fn(f) { f.name })),
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

  let assert Ok(_) =
    "
    pub fn encode(msg: Message) -> BitArray {
    case msg {
        {body}
    }
  }
  "
    |> format([#("body", body)])
    |> simplifile.append(to: out_path)

  // decoding
  messages
  |> list.map(fn(msg) { get_message_case_code(msg) })
  |> list.fold(
    "
    pub fn decode_message(msg: Message, binary: BitArray) -> Message {
    case binary {
      <<>> -> msg
     _ -> case msg {
  ",
    string.append,
  )
  |> string.append(
    "
        }
      }
    }
  ",
  )
  |> simplifile.append(to: out_path)
}

//     Hello(session, texts) -> {
//       let #(key, bin) = decoding.decode_key(bin)
//       case key.field_number {
//         1 -> {
//           let #(session, bin) = decoding.decode_varint(bin)
//           decode_message(Hello(session, texts), bin)
//         }
//         _ -> todo
//       }
//     }
fn get_message_case_code(msg: parser.Message) -> String {
  msg.fields
  |> list.map(fn(f) {
    format(
      "
        {field_number} -> {
          let #({field_name}, binary) = {reader}
          decode_message({message}, binary)
        }
      ",
      [
        #("reader", get_reader_string(f)),
        #("field_number", int.to_string(f.tag)),
        #("field_name", {
          case f.repeated, field_is_packed(f) {
            True, False -> "value"
            _, _ -> f.name
          }
        }),
        #(
          "message",
          message_to_string(msg, fn(f2) {
            case f.name == f2.name, f2.repeated, field_is_packed(f2) {
              True, True, False ->
                format("list.append({field_name}, [value])", [
                  #("field_name", f2.name),
                ])
              _, _, _ -> f2.name
            }
          }),
        ),
      ],
    )
  })
  |> list.fold(message_to_string(msg, fn(f) { f.name }) <> "
    -> {
      let #(key, binary) = decoding.read_key(binary)
      case key.field_number {
  ", string.append)
  |> string.append(
    "
          _ -> panic
      }
    }
  ",
  )
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
        contents: message_to_string(struct, fn(field) {
          field.name <> ": " <> to_gleam_ty(field.ty, field.repeated)
        })
          <> "}\n\n",
      )

    // default
    // pub const item_default = Item(0, 0)
    let assert Ok(_) =
      "pub const {name}_default = {value}\n"
      |> format([
        #("name", pascal_to_snake(struct.name)),
        #(
          "value",
          struct.fields
            |> list.map(fn(f) { get_default_value(f.ty, f.repeated) })
            |> list.fold(struct.name <> "(", fn(a, b) { a <> b <> "," })
            |> string.append(")"),
        ),
      ])
      |> simplifile.append(to: out_path)
    // encoding gen
    // fn encode_item(item: Item) -> BitArray {
    //   <<>>
    //   |> encoding.encode_int_field(1, item.id)
    //   |> encoding.encode_int_field(2, item.num)
    // }
    let assert Ok(_) =
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
    // decoding gen
    let assert Ok(_) =
      format(
        "
      pub fn decode_to_{name}(binary: BitArray, {name}: {typename}) -> Result({typename}, String) {
        case binary {
          <<>> -> Ok({name})
          _ -> {
            let #(key, binary) = decoding.read_key(binary)
            case key.field_number {
              {body}
                _ -> panic
              }
            }
          }
        }
      ",
        [
          #("name", pascal_to_snake(struct.name)),
          #("typename", struct.name),
          #(
            "body",
            struct.fields
              |> list.map(fn(f) {
                format(
                  "
                  {field_number} -> {
                    let #({var_name}, binary) = {reader}
                    decode_to_{name}(binary, {typename}(..{name}, {field_name}: {field_value}))
                  }
                ",
                  [
                    #("name", pascal_to_snake(struct.name)),
                    #("typename", struct.name),
                    #("reader", get_reader_string(f)),
                    #("field_number", int.to_string(f.tag)),
                    #("field_name", f.name),
                    #("var_name", {
                      case f.repeated, field_is_packed(f) {
                        True, False -> "value"
                        _, _ -> f.name
                      }
                    }),
                    #("field_value", {
                      case f.repeated, field_is_packed(f) {
                        True, False ->
                          format("list.append({name}.{field_name}, [value])", [
                            #("name", pascal_to_snake(struct.name)),
                            #("field_name", f.name),
                          ])
                        _, _ -> f.name
                      }
                    }),
                  ],
                )
              })
              |> list.fold("", string.append),
          ),
        ],
      )
      |> simplifile.append(to: out_path)
    // read_xxxx gen
    // pub fn read_item(binary: BitArray) -> #(Item, BitArray) {
    //   decoding.read_len_field(binary, decode_to_item(_, item_default))
    // }
    let assert Ok(_) =
      format(
        "
        pub fn read_{name}(binary: BitArray) -> #({typename}, BitArray) {
          decoding.read_len_field(binary, decode_to_{name}(_, {name}_default))
        }
      ",
        [#("name", pascal_to_snake(struct.name)), #("typename", struct.name)],
      )
      |> simplifile.append(to: out_path)
  })
}

// fn to_gleam_ty(ty: String, repeated: Bool) -> String {
//   let ty = case ty {
//     // string
//     "string" -> "String"
//     // varint
//     "int32" | "int64" | "uint32" | "uint64" -> "Int"
//     "bool" -> "Bool"
//     // i64
//     "fixed64" | "sfixed64" | "double" -> "Float"
//     // i32
//     "fixed32" | "sfixed32" | "float" -> "Float"
//     // Custom Type (Struct | Enum)
//     x -> x
//   }
// decoding.decode_varint(binary)
fn get_reader_string(field: parser.Field) -> String {
  case field.repeated {
    True -> {
      case field.ty {
        "string" -> "decoding.read_string(binary)"
        "int32" | "int64" | "uint32" | "uint64" ->
          "decoding.read_len_packed_field(binary, decoding.read_varint)"
        "bool" -> "decoding.read_len_packed_field(binary, decoding.read_bool)"
        "fixed64" | "sfixed64" | "double" ->
          "decoding.read_len_packed_field(binary, decoding.read_i64)"
        "fixed32" | "sfixed32" | "float" ->
          "decoding.read_len_packed_field(binary, decoding.read_i32)"
        // Custom Type (Enum)
        ty -> "read_" <> pascal_to_snake(ty) <> "(binary)"
      }
    }
    False -> {
      case field.ty {
        "string" -> "decoding.read_string(binary)"
        "int32" | "int64" | "uint32" | "uint64" ->
          "decoding.read_varint(binary)"
        "bool" -> "decoding.read_bool(binary)"
        "fixed64" | "sfixed64" | "double" -> "decoding.read_i64(binary)"
        "fixed32" | "sfixed32" | "float" -> "decoding.read_i32(binary)"
        // Custom Type (Enum)
        ty -> "read_" <> pascal_to_snake(ty) <> "(binary)"
      }
    }
  }
}

fn field_is_packed(field: parser.Field) -> Bool {
  case field.ty {
    "int32" | "int64" | "uint32" | "uint64" if field.repeated -> True
    "bool" if field.repeated -> True
    "fixed64" | "sfixed64" | "double" if field.repeated -> True
    "fixed32" | "sfixed32" | "float" if field.repeated -> True
    // Custom Type (Enum)
    _ -> False
  }
}

// fn get_len_docoder_string(field: parser.Field) -> String {
//   case field.ty {
//     "string" -> "decoding.decode_to_string"
//     // Custom Type (Struct)
//     ty -> "decode_to_" <> ty
//   }
// }

fn get_default_value(ty: String, repeated: Bool) -> String {
  case to_gleam_ty(ty, False) {
    _any if repeated -> "[]"
    "Int" -> "0"
    "Bool" -> "False"
    "Float" -> "0.0"
    "String" -> "\"\""
    // Enum or Struct
    x -> pascal_to_snake(x) <> "_default"
  }
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
              #(
                "wire_type",
                "encoding." <> float_wire_type(field.ty) <> "_type",
              ),
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
    // todo: Enum is Int, is packed
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

    // default value
    // pub const user_status_default = Idle
    let assert Ok(_) =
      "pub const {name}_default = {value}\n"
      |> format([
        #("name", pascal_to_snake(enum.name)),
        #("value", case enum.fields |> list.first {
          Ok(f) -> f.name
          _ -> panic as { "Invalid empty enum: " <> enum.name }
        }),
      ])
      |> simplifile.append(to: out_path)

    // encoding gen
    // pub fn encode_item(item: Item) -> BitArray {
    //   ...
    // }
    let assert Ok(_) =
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
    // decoding gen

    let assert Ok(_) =
      format(
        "
          pub fn read_{name}(binary: BitArray) -> #({type}, BitArray) {
            let #(num, binary) = decoding.read_varint(binary)
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
                format("    {key} -> {value}\n", [
                  #("key", int.to_string(f.tag)),
                  #("value", "#(" <> f.name <> ", binary)"),
                ])
              })
              |> list.fold("case num {\n", string.append)
              |> string.append("  _ -> panic\n")
              |> string.append("  }\n"),
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
      "//\\s*@gleam\\s+record\\s*\nmessage\\s+\\w+\\s*{((?:.|\n)*?)}",
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
fn message_to_string(
  message: parser.Message,
  convert: fn(parser.Field) -> String,
) -> String {
  case list.length(message.fields) > 0 {
    True -> {
      format("  {name}({body})\n", [
        #("name", message.name),
        #("body", {
          message.fields
          |> list.map(convert)
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
