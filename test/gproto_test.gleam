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

// message TestVarInt {
//     int32 v = 1;
// }
pub fn pb_encode_test() {
  <<>>
  |> buffer.encode_key(1, buffer.varint_type)
  |> buffer.encode_varint(1)
  |> bit_array.base16_encode
  |> io.debug

  <<>>
  |> buffer.encode_key(1, buffer.varint_type)
  |> buffer.encode_varint(150)
  |> bit_array.base16_encode
  |> io.debug

  <<>>
  |> buffer.encode_key(1, buffer.varint_type)
  |> buffer.encode_varint(-150)
  |> bit_array.base16_encode
  |> io.debug
}
