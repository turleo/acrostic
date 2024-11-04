// pub fn decode_user_status(bin: BitArray) -> #(UserStatus, BitArray) {
//   let #(num, bin) = decoding.decode_varint(bin)
//   case num {
//     1 -> #(Idle, bin)
//     _ -> todo
//   }
// }

// decoder 
pub fn decode_varint(bin: BitArray) -> Float {
  case bin {
    <<first:float-size(32)>> -> first
    <<>> -> 0.0
  }
}

pub fn decode_i32(bin: BitArray) -> Float {
  case bin {
    <<first:float-size(32)>> -> first
    <<>> -> 0.0
  }
}

// field decode
pub fn decode_int_field(bin: BitArray) -> #(Int, BitArray)
pub fn decode_float_field(bin: BitArray) -> #(Float, BitArray)




Item {
    id: Int
    text: String
    items: Item
}

pub fn decode_item(bin: BitArray, item: Item) -> Item {
  case bin {
    <<>> -> item
    _ -> {
      let #(filed_number, wire_type) = decoding.decode_key()
      case filed_number {
        1 -> {
          let #(id, bin) = decoding.decode_varint(bin)
          decode_item(bin, Item(..item, id: id))
        }
        2 -> {
            let #(text, bin) = decoding.decode_string(bin)
            decode_item(bin, Item(..item, text: text))
        }
        3 -> {
            let #(item, bin) = decoding.decode_item(bin, item_default)
            decode_item(bin, Item(..item, text: text))
        }
        _ -> todo
      }
      todo
    }
  }
}

// pub fn decode_message(msg: Message, bin: BitArray) -> Message {
//   case msg {
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
//     _ -> todo
//   }
// }

// const message_hello_default = Hello(0, [])

// user ex decode

// pub fn decode(id: Int, bin: BitArray) -> Message {
//   case id {
//     1 -> decode_message(message_hello_default, bin)
//     _ -> todo
//   }
// }
