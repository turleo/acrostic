import gleam/bit_array
import gleam/float
import gleam/int
import gleam/io
import gleeunit
import gleeunit/should
import pbf/encoding
import proto.{Hello, Item, ReqUseItem, ResUseItem, TestFloat}

pub fn main() {
  gleeunit.main()
}

pub fn pb_message_test() {
  encoding.encode_i32(1.0)
  |> bit_array.base16_encode
  |> io.debug
  io.debug("-------------------------------")

  encoding.encode_i64(1.0)
  |> bit_array.base16_encode
  |> io.debug
  io.debug("-------------------------------")

  proto.encode_item(Item(1, 100, 0.0, False, ""))
  |> bit_array.base16_encode
  |> io.debug
  io.debug("-------------------------------")

  proto.encode(Hello(1, ["hello", "world"]))
  |> bit_array.base16_encode
  |> io.debug
  io.debug("-------------------------------")

  proto.encode(ReqUseItem(100, Item(1, 100, 0.0, False, "")))
  |> bit_array.base16_encode
  |> io.debug
  io.debug("-------------------------------")

  proto.encode(
    ResUseItem(100, [0, 0, 1], [
      Item(1, 100, 0.0, False, ""),
      Item(2, 100, 0.0, False, ""),
    ]),
  )
  |> bit_array.base16_encode
  |> io.debug
  io.debug("-------------------------------")

  proto.encode(TestFloat({ int.to_float(100_000_000_000) }, 1000.0))
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
