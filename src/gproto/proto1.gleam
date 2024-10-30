import gproto/proto

pub type UserStatus {
  Idle
  Matching
  Gameing
}

pub type RoomStatus {
  RIdle
  RMatching
  RGameing
}

// struct start -----------------------------------
pub type Item {
  Item(id: Int, num: Int)
}

fn encode_item(item: Item) -> BitArray {
  todo
}

// messages start -----------------------------------
pub type Message {
  ReqUseItem(session: Int, item: Item)
  Hello(session: Int, texts: List(String))
}

fn encode_message(message: Message) -> BitArray {
  todo
}

fn decode_message_req_use_item(bin: BitArray) {
  let msg = ReqUseItem(session: 0, item: Item(id: 0, num: 0))
  // todo: decodeing
  msg
}

fn decode_message_hello(bin: BitArray) {
  let msg = Hello(session: 0, texts: [])
  // todo: decodeing
  msg
}

// use define
fn decode_message(id: Int, bin: BitArray) -> Message {
  case id {
    1 -> decode_message_hello(bin)
    2 -> decode_message_req_use_item(bin)
    _ -> panic as "Invliad message id"
  }
}
