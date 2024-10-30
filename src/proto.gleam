import gproto/proto

pub type UserStatus {
  Idle
  Matching
  Gameing
}

pub fn encode_user_status(user_status: UserStatus) -> BitArray {
  case user_status {
    Idle -> proto.encode_varint(0)
    Matching -> proto.encode_varint(1)
    Gameing -> proto.encode_varint(2)
  }
}

pub type RoomStatus {
  RIdle
  RMatching
  RGameing
}

pub fn encode_room_status(room_status: RoomStatus) -> BitArray {
  case room_status {
    RIdle -> proto.encode_varint(0)
    RMatching -> proto.encode_varint(1)
    RGameing -> proto.encode_varint(2)
  }
}

// struct start -----------------------------------
pub type Item {
  Item(id: Int, num: Int)
}

// messages start -----------------------------------
pub type Message {
  ReqUseItem(session: Int, item: Item)
  Hello(session: Int, texts: List(String))
}
