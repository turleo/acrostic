import gleam/list
import pb/decoding
import pb/encoding.{i32_type, i64_type, len_type, varint_type}

pub type UserStatus {
  Idle
  Matching
  Gameing
}

pub const user_status_default = Idle

pub fn encode_user_status(user_status: UserStatus) -> BitArray {
  case user_status {
    Idle -> encoding.encode_varint(0)
    Matching -> encoding.encode_varint(1)
    Gameing -> encoding.encode_varint(2)
  }
}

pub fn read_user_status(binary: BitArray) -> #(UserStatus, BitArray) {
  let #(num, binary) = decoding.read_varint(binary)
  case num {
    0 -> #(Idle, binary)
    1 -> #(Matching, binary)
    2 -> #(Gameing, binary)
    _ -> panic
  }
}

pub type RoomStatus {
  RIdle
  RMatching
  RGameing
}

pub const room_status_default = RIdle

pub fn encode_room_status(room_status: RoomStatus) -> BitArray {
  case room_status {
    RIdle -> encoding.encode_varint(0)
    RMatching -> encoding.encode_varint(1)
    RGameing -> encoding.encode_varint(2)
  }
}

pub fn read_room_status(binary: BitArray) -> #(RoomStatus, BitArray) {
  let #(num, binary) = decoding.read_varint(binary)
  case num {
    0 -> #(RIdle, binary)
    1 -> #(RMatching, binary)
    2 -> #(RGameing, binary)
    _ -> panic
  }
}

// struct start -----------------------------------
pub type Item {
  Item(id: Int, num: Int, d: Float, b: Bool, s: String)
}

pub const item_defalut = Item(0, 0, 0.0, False, "")

pub fn encode_item(item: Item) -> BitArray {
  <<>>
  |> encoding.encode_int_field(1, item.id)
  |> encoding.encode_int_field(2, item.num)
  |> encoding.encode_float_field(3, item.d, i64_type)
  |> encoding.encode_bool_field(4, item.b)
  |> encoding.encode_len_field(5, item.s, encoding.encode_string)
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

        3 -> {
          let #(d, binary) = decoding.read_i64(binary)
          decode_to_item(binary, Item(..item, d: d))
        }

        4 -> {
          let #(b, binary) = decoding.read_bool(binary)
          decode_to_item(binary, Item(..item, b: b))
        }

        5 -> {
          let #(s, binary) = decoding.read_string(binary)
          decode_to_item(binary, Item(..item, s: s))
        }

        _ -> panic
      }
    }
  }
}

pub fn read_item(binary: BitArray) -> #(Item, BitArray) {
  decoding.read_len_field(binary, decode_to_item(_, item_defalut))
}

// messages start -----------------------------------
pub type Message {
  ReqUseItem(session: Int, item: Item)
  ResUseItem(session: Int, nums: List(Int), items: List(Item))
  Hello(session: Int, texts: List(String))
  TestFloat(f: Float, d: Float)
}

pub fn encode(msg: Message) -> BitArray {
  case msg {
    ReqUseItem(session, item) -> {
      <<>>
      |> encoding.encode_int_field(1, session)
      |> encoding.encode_len_field(2, item, encode_item)
    }

    ResUseItem(session, nums, items) -> {
      <<>>
      |> encoding.encode_int_field(1, session)
      |> encoding.encode_repeated_field(2, nums, encoding.encode_varint, True)
      |> encoding.encode_repeated_field(6, items, encode_item, False)
    }

    Hello(session, texts) -> {
      <<>>
      |> encoding.encode_int_field(1, session)
      |> encoding.encode_repeated_field(2, texts, encoding.encode_string, False)
    }

    TestFloat(f, d) -> {
      <<>>
      |> encoding.encode_float_field(1, f, i32_type)
      |> encoding.encode_float_field(2, d, i64_type)
    }
  }
}

pub fn decode_message(msg: Message, binary: BitArray) -> Message {
  case msg {
    ReqUseItem(session, item) -> {
      let #(key, binary) = decoding.read_key(binary)
      case key.field_number {
        1 -> {
          let #(session, binary) = decoding.read_varint(binary)
          decode_message(ReqUseItem(session, item), binary)
        }

        2 -> {
          let #(item, binary) = read_item(binary)
          decode_message(ReqUseItem(session, item), binary)
        }

        _ -> panic
      }
    }
    ResUseItem(session, nums, items) -> {
      let #(key, binary) = decoding.read_key(binary)
      case key.field_number {
        1 -> {
          let #(session, binary) = decoding.read_varint(binary)
          decode_message(ResUseItem(session, nums, items), binary)
        }

        2 -> {
          let #(nums, binary) =
            decoding.read_len_packed_field(binary, decoding.read_varint)
          decode_message(ResUseItem(session, nums, items), binary)
        }

        6 -> {
          let #(value, binary) = read_item(binary)
          decode_message(
            ResUseItem(session, nums, list.append(items, [value])),
            binary,
          )
        }

        _ -> panic
      }
    }
    Hello(session, texts) -> {
      let #(key, binary) = decoding.read_key(binary)
      case key.field_number {
        1 -> {
          let #(session, binary) = decoding.read_varint(binary)
          decode_message(Hello(session, texts), binary)
        }

        2 -> {
          let #(value, binary) = decoding.read_string(binary)
          decode_message(Hello(session, list.append(texts, [value])), binary)
        }

        _ -> panic
      }
    }
    TestFloat(f, d) -> {
      let #(key, binary) = decoding.read_key(binary)
      case key.field_number {
        1 -> {
          let #(f, binary) = decoding.read_i32(binary)
          decode_message(TestFloat(f, d), binary)
        }

        2 -> {
          let #(d, binary) = decoding.read_i64(binary)
          decode_message(TestFloat(f, d), binary)
        }

        _ -> panic
      }
    }
  }
}
