import gleam/bit_array
import gleam/int
import gleam/io
import gleam/string
import gleeunit
import gleeunit/should
import gproto/proto

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
  Ping(session: Int)
  Item(id: Int, num: Int)
  HeartBeat(session: Int, items: List(Int))
}

fn encode_message(message: Message) -> BitArray {
  case message {
    Ping(session) -> {
      <<>>
      |> proto.encode_int_field(1, session, proto.varint_type)
    }
    Item(id, num) -> {
      <<>>
      |> proto.encode_int_field(1, id, proto.varint_type)
      |> proto.encode_int_field(2, num, proto.varint_type)
    }
    HeartBeat(session, items) -> {
      <<>>
      |> proto.encode_int_field(1, session, proto.varint_type)
      |> proto.encode_repeated_field(2, items, proto.encode_varint, True)
    }
  }
}

// lua    0801 12 026869
// gleam  0801 1203 026869

pub fn pb_message_test() {
  Ping(0xffffffff)
  |> encode_message
  |> bit_array.base16_encode
  |> io.debug

  HeartBeat(1, [0, 1, 2])
  |> encode_message
  |> bit_array.base16_encode
  |> io.debug
  io.debug("-------------------------------")
  // io.debug()
}
// message TestVarInt {
//     int32 v = 1;
// }
// pub fn pb_encode_test() {
//   todo
// }
