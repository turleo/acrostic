import gleam/list
import pb/decoding
import pb/encoding

// struct start -----------------------------------
pub type Item {
  Item(id: Int, num: Int)
}

pub const item_default = Item(0, 0)

pub fn encode_item(item: Item) -> BitArray {
  <<>>
  |> encoding.encode_int_field(1, item.id)
  |> encoding.encode_int_field(2, item.num)
}

pub fn decode_to_item(binary: BitArray, item: Item) -> Result(Item, String) {
  case binary {
    <<>> -> Ok(item)
    _ -> {
      let #(key, binary) = decoding.read_key(binary)
      case key.field_number {
        1 -> {
          let #(id, binary) = decoding.read_varint(binary)
          decode_to_item(binary, Item(..item, id: id))
        }

        2 -> {
          let #(num, binary) = decoding.read_varint(binary)
          decode_to_item(binary, Item(..item, num: num))
        }

        _ -> panic
      }
    }
  }
}

pub fn read_item(binary: BitArray) -> #(Item, BitArray) {
  decoding.read_len_field(binary, decode_to_item(_, item_default))
}

// messages start -----------------------------------
pub type Message {
  Ping(hello: String, world: String)
}

pub fn encode(msg: Message) -> BitArray {
  case msg {
    Ping(hello, world) -> {
      <<1:big-size(16)>>
      |> encoding.encode_len_field(1, hello, encoding.encode_string)
      |> encoding.encode_len_field(2, world, encoding.encode_string)
    }
  }
}

pub fn decode_message(msg: Message, binary: BitArray) -> Message {
  case binary {
    <<>> -> msg
    _ ->
      case msg {
        Ping(hello, world) -> {
          let #(key, binary) = decoding.read_key(binary)
          case key.field_number {
            1 -> {
              let #(hello, binary) = decoding.read_string(binary)
              decode_message(Ping(hello, world), binary)
            }

            2 -> {
              let #(world, binary) = decoding.read_string(binary)
              decode_message(Ping(hello, world), binary)
            }

            _ -> panic
          }
        }
      }
  }
}

pub const ping_default = Ping("", "")

pub fn decode(binary: BitArray) -> Message {
  let assert <<id:big-size(16), binary:bits>> = binary
  case id {
    1 -> decode_message(ping_default, binary)
    _ -> panic
  }
}
