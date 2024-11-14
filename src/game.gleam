import gleam/bit_array
import gleam/list
import pb/decoding
import pb/encoding.{type FieldEncoder, FieldEncoder}

// struct start -----------------------------------
pub type Item {
  Item(id: Int, num: Int)
}

pub const item_default = Item(0, 0)

pub fn encode_item(item: Item) -> BitArray {
  <<>>
  |> bit_array.append(encoding.encode_field(
    1,
    item.id,
    encoding.int_field_encoder,
  ))
  |> bit_array.append(encoding.encode_field(
    2,
    item.num,
    encoding.int_field_encoder,
  ))
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

pub const item_field_encoder = FieldEncoder(encoding.WireLenTy, encode_item)

// messages start -----------------------------------
pub type Message {
  Test(hello: String, world: Float, item: Item, nums: List(Int))
}

pub fn encode(msg: Message) -> BitArray {
  case msg {
    Test(hello, world, item, nums) -> {
      <<1:big-size(16)>>
      |> bit_array.append(encoding.encode_field(
        1,
        hello,
        encoding.string_field_encoder,
      ))
      |> bit_array.append(encoding.encode_field(
        2,
        world,
        encoding.i64_field_encoder,
      ))
      |> bit_array.append(encoding.encode_field(3, item, item_field_encoder))
      |> bit_array.append(encoding.encode_repeated_field(
        4,
        nums,
        encoding.int_field_encoder,
      ))
    }
  }
}

pub fn decode_message(msg: Message, binary: BitArray) -> Message {
  case binary {
    <<>> -> msg
    _ ->
      case msg {
        Test(hello, world, item, nums) -> {
          let #(key, binary) = decoding.read_key(binary)
          case key.field_number {
            1 -> {
              let #(hello, binary) = decoding.read_string(binary)
              decode_message(Test(hello, world, item, nums), binary)
            }
            2 -> {
              let #(world, binary) = decoding.read_i64(binary)
              decode_message(Test(hello, world, item, nums), binary)
            }
            3 -> {
              let #(item, binary) = read_item(binary)
              decode_message(Test(hello, world, item, nums), binary)
            }
            4 -> {
              let #(nums, binary) =
                decoding.read_len_packed_field(binary, decoding.read_varint)
              decode_message(Test(hello, world, item, nums), binary)
            }
            _ -> panic
          }
        }
      }
  }
}

pub const test_default = Test("", 0.0, item_default, [])

pub fn decode(binary: BitArray) -> Message {
  let assert <<id:big-size(16), binary:bits>> = binary
  case id {
    1 -> decode_message(test_default, binary)
    _ -> panic
  }
}
