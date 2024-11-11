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
