import pbf/encoding.{i32_type, i64_type, len_type, varint_type}

pub type UserStatus {
  Idle
  Matching
  Gameing
}

pub fn encode_user_status(user_status: UserStatus) -> BitArray {
  case user_status {
    Idle -> encoding.encode_varint(0)
    Matching -> encoding.encode_varint(1)
    Gameing -> encoding.encode_varint(2)
  }
}

pub type RoomStatus {
  RIdle
  RMatching
  RGameing
}

pub fn encode_room_status(room_status: RoomStatus) -> BitArray {
  case room_status {
    RIdle -> encoding.encode_varint(0)
    RMatching -> encoding.encode_varint(1)
    RGameing -> encoding.encode_varint(2)
  }
}

// struct start -----------------------------------
pub type Item {
  Item(id: Int, num: Int, d: Float, b: Bool, s: String)
}

pub fn encode_item(item: Item) -> BitArray {
  <<>>
  |> encoding.encode_int_field(1, item.id)
  |> encoding.encode_int_field(2, item.num)
  |> encoding.encode_float_field(3, item.d, i64_type)
  |> encoding.encode_bool_field(4, item.b)
  |> encoding.encode_len_field(5, item.s, encoding.encode_string)
}

// messages start -----------------------------------
pub type Message {
  ReqUseItem(session: Int, item: Item)
  Hello(session: Int, texts: List(String))
}
