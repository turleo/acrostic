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

// messages start -----------------------------------
pub type Message {
  ReqUseItem(session: Int, item: Item)
  Hello(session: Int, texts: List(String))
}

