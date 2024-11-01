import bitsandbobs/ints
import gleam/bit_array
import gleam/int
import gleam/io
import gleam/list
import gleam/result

// import gleam/result.{Result}

const mask_wire_type = 0b111

pub type DecodeError {
  NoBit
}

pub fn decode_key(num: Int) -> #(Int, Int) {
  let wire_type = int.bitwise_and(num, mask_wire_type)
  let field_number = int.bitwise_shift_right(num - wire_type, 3)
  #(field_number, wire_type)
}

pub fn read_i32(bin: BitArray) -> #(Float, BitArray) {
  case bin {
    <<first:float-size(32), rest:bits>> -> #(first, rest)
    _ -> panic as "can't read i32"
  }
}

pub fn read_i64(bin: BitArray) -> #(Float, BitArray) {
  case bin {
    <<first:float-size(64), rest:bits>> -> #(first, rest)
    _ -> panic as "can't read i64"
  }
}

pub fn read_varint(bin: BitArray) -> #(Int, BitArray) {
  // [high -> low]
  let #(bytes, bin) = read_varint_bytes(bin, [])
  #(calc_varint(bytes, 0), bin)
}

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
) -> #(List(Int), BitArray) {
  case read_byte(bin) {
    #(0, bin) -> #(results, bin)
    #(byte, bin) -> {
      case int.bitwise_and(byte, 0x80) {
        flag if flag > 0 ->
          read_varint_bytes(bin, [int.bitwise_and(byte, 0x7F), ..results])
        _ -> #([byte, ..results], bin)
      }
    }
  }
}

fn read_byte(bin: BitArray) -> #(Int, BitArray) {
  case bin {
    <<>> -> #(0, <<>>)
    <<byte:size(8), rest:bits>> -> #(byte, rest)
    _ -> panic
  }
}
