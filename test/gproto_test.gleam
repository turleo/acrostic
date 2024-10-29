import gleam/bit_array
import gleam/int
import gleam/io
import gleam/string
import gleeunit
import gleeunit/should
import gproto/buffer

pub fn main() {
  gleeunit.main()
}

// hello.proto -------------------------------

// message HeartBeat {
//     int32 session = 1;
//     repeated string texts = 2;
// }

// ended ------------------------------------

// Generated, Don't change!
type Message {
  HeartBeat(session: Int, texts: List(String))
}

fn encode_message(message: Message) -> BitArray {
  case message {
    HeartBeat(session, texts) -> {
      // 1 is read from `.proto`
      <<>>
      |> buffer.encode_int_field(1, session)
      |> buffer.encode_repeated_field(2, texts, buffer.encode_string)
    }
  }
}

pub fn pb_message_test() {
  HeartBeat(1, ["hello", "world"])
  |> encode_message
  |> bit_array.base16_encode
  |> io.debug
  io.debug("-------------------------------")
}
// message TestVarInt {
//     int32 v = 1;
// }
// pub fn pb_encode_test() {
//   todo
// }
