import gleam/bit_array
import gleam/bool
import gleam/int
import gleam/list
import gproto/intex.{lsr}

// int32, int64, uint32, uint64, bool, enum
pub const varint_type = 0

// fixed64, sfixed64, double
pub const i64_type = 1

// string, bytes, embedded messages, repeated fields
pub const len_type = 2

// deprecated
// pub const sgroup_type = 3
// pub const egroup_type = 4

// fixed32, sfixed32, float
pub const i32_type = 5

// const mask32bit = 0xFFFFFFFF
const mask64bit = 0xFFFFFFFFFFFFFFFF

pub fn encode_key(
  buf: BitArray,
  field_number field_number: Int,
  wire_type wire_type: Int,
) -> BitArray {
  <<
    buf:bits,
    { field_number |> int.bitwise_shift_left(3) |> int.bitwise_or(wire_type) },
  >>
}

pub fn encode_i64(n: Int) -> BitArray {
  <<n:little-size(64)>>
}

pub fn encode_i32(n: Int) -> BitArray {
  <<n:little-size(32)>>
}

pub fn encode_varint(n: Int) -> BitArray {
  case int.bitwise_and(n, mask64bit) {
    x if x >= 0x80 -> {
      bit_array.append(
        <<{ n |> int.bitwise_and(0x7F) |> int.bitwise_or(0x80) }>>,
        encode_varint(lsr(x, 7)),
      )
    }
    x -> <<int.bitwise_and(x, 0x7F)>>
  }
}

pub fn encode_string(s: String) -> BitArray {
  <<s:utf8>>
}

// 子类型也使用 Len 类型 key + body_size + body

// 重复元素 packed : key + body_size + body, body 包含多个元素, 每个元素的大小取决于它的类型

pub fn encode_int_field(
  buf: BitArray,
  field_number: Int,
  value: Int,
  // varint_type, i32_type, i64_type
  wire_type: Int,
) -> BitArray {
  case
    wire_type == varint_type || wire_type == i32_type || wire_type == i64_type
  {
    True -> {
      case value == 0 {
        True -> buf
        False -> {
          buf
          |> encode_key(field_number, wire_type)
          |> bit_array.append(encode_varint(value))
        }
      }
    }
    False -> panic as { "Invalid int wire_type" <> int.to_string(wire_type) }
  }
}

pub fn encode_bool_field(buf: BitArray, field_number: Int, b: Bool) -> BitArray {
  encode_int_field(buf, field_number, varint_type, bool.to_int(b))
}

pub fn encode_len_field(
  buf: BitArray,
  field_number: Int,
  child: a,
  encoder: fn(a) -> BitArray,
) -> BitArray {
  let data = encoder(child)
  let length = bit_array.byte_size(data)
  case length == 0 {
    True -> buf
    False -> {
      buf
      |> encode_key(field_number, len_type)
      |> bit_array.append(encode_varint(length))
      |> bit_array.append(data)
    }
  }
}

pub fn encode_repeated_field(
  buf: BitArray,
  field_number: Int,
  children: List(a),
  encoder: fn(a) -> BitArray,
) -> BitArray {
  let data =
    children
    |> list.map(fn(a) {
      let data = encoder(a)
      let length = bit_array.byte_size(data)

      <<>>
      |> encode_key(field_number, len_type)
      |> bit_array.append(encode_varint(length))
      |> bit_array.append(data)
    })
    |> list.fold(<<>>, bit_array.append)

  buf |> bit_array.append(data)
}
