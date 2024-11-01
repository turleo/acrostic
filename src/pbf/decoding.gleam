import bitsandbobs/ints
import gleam/bit_array
import gleam/int
import gleam/io
import gleam/list
import gleam/result

pub type Key {
  Key(field_number: Int, wire_type: Int)
}

const wire_type_mask = 0b111

pub type DecodeError {
  NoBit
}

pub fn decode_i32(bin: BitArray) -> #(Float, BitArray) {
  case bin {
    <<first:float-size(32), rest:bits>> -> #(first, rest)
    _ -> panic as "can't read i32"
  }
}

pub fn decode_i64(bin: BitArray) -> #(Float, BitArray) {
  case bin {
    <<first:float-size(64), rest:bits>> -> #(first, rest)
    _ -> panic as "can't read i64"
  }
}

pub fn decode_key(bin: BitArray) -> #(Key, BitArray) {
  let #(num, bin) = decode_varint(bin)
  let wire_type = int.bitwise_and(num, wire_type_mask)
  let field_number = int.bitwise_shift_right(num - wire_type, 3)
  #(Key(field_number, wire_type), bin)
}

pub fn decode_varint(bin: BitArray) -> #(Int, BitArray) {
  // [high -> low]
  let #(bin, bytes) = read_varint_bytes(bin, [])
  #(calc_varint(bytes, 0), bin)
}

// util ------------------------------------------------------------------------
fn calc_varint(bytes: List(Int), sum: Int) -> Int {
  case list.length(bytes) {
    len if len > 0 -> {
      let assert [first, ..rest] = bytes
      calc_varint(rest, int.bitwise_shift_left(first, { len - 1 } * 7) + sum)
    }
    _ -> sum
  }
}

fn read_varint_bytes(
  bin: BitArray,
  results: List(Int),
) -> #(BitArray, List(Int)) {
  case read_byte(bin) {
    #(bin, 0) -> #(bin, results)
    #(bin, byte) -> {
      case int.bitwise_and(byte, 0x80) {
        flag if flag > 0 ->
          read_varint_bytes(bin, [int.bitwise_and(byte, 0x7F), ..results])
        _ -> #(bin, [byte, ..results])
      }
    }
  }
}

fn read_byte(bin: BitArray) -> #(BitArray, Int) {
  case bin {
    <<>> -> #(<<>>, 0)
    <<byte:size(8), rest:bits>> -> #(rest, byte)
    _ -> panic
  }
}
