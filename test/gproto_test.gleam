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
  // varint
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

  // i32
  <<>>
  |> buffer.encode_key(1, buffer.i32_type)
  |> buffer.encode_i32(1)
  |> bit_array.base16_encode
  |> io.debug

  // i64
  <<>>
  |> buffer.encode_key(1, buffer.i64_type)
  |> buffer.encode_i64(1)
  |> bit_array.base16_encode
  |> io.debug
}
