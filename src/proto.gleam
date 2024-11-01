import pbf/encoding.{i32_type, i64_type, len_type, varint_type}

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
