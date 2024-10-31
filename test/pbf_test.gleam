import gleam/bit_array
import gleam/io
import gleeunit
import gleeunit/should
import proto.{Hello, Item, ReqUseItem, ResUseItem}

pub fn main() {
  gleeunit.main()
}

pub fn pb_message_test() {
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
  // io.debug()
}
// message TestVarInt {
//     int32 v = 1;
// }
// pub fn pb_encode_test() {
//   todo
// }
