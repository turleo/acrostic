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
  Item(id: Int, num: Int)
}


pub fn encode_item(item: Item) -> BitArray {
  todo
}

// messages start -----------------------------------
pub type Message {
  ReqUseItem(session: Int, item: Item)
  Hello(session: Int, texts: List(String))
}

