import gleam/int
import gproto/intex.{lsr}

// int32, int64, uint32, uint64, bool, enum
pub const varint_type = 0

pub const i64_type = 1

pub const len_type = 2

// deprecated
pub const sgroup_type = 3

// deprecated
pub const egroup_type = 4

pub const i32_type = 5

const mask64bit = 0xFFFFFFFFFFFFFFFF

pub fn encode_key(buf: BitArray, field_number: Int, wire_type: Int) -> BitArray {
  <<
    buf:bits,
    { field_number |> int.bitwise_shift_left(3) |> int.bitwise_or(wire_type) },
  >>
}

pub fn encode_varint(buf: BitArray, n: Int) -> BitArray {
  case int.bitwise_and(n, mask64bit) {
    x if x >= 0x80 ->
      encode_varint(
        <<buf:bits, { n |> int.bitwise_and(0x7F) |> int.bitwise_or(0x80) }>>,
        lsr(n, 7),
      )
    x -> <<buf:bits, int.bitwise_and(x, 0x7F)>>
  }
}

pub fn encode_bool(buf: BitArray, b: Bool) -> BitArray {
  case b {
    True -> encode_varint(buf, 1)
    False -> encode_varint(buf, 0)
  }
}
