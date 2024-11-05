import gleam/bit_array
import gleam/int
import gleam/list
import gleam/result

pub type Key {
  Key(field_number: Int, wire_type: Int)
}

const wire_type_mask = 0b111

// decoder start -------------------------------------------
pub fn decode_to_i64(binary: BitArray) -> Result(Float, String) {
  case binary {
    <<n:float-size(64)>> -> Ok(n)
    _ -> Error("unable decode to i64")
  }
}

pub fn decode_to_i32(binary: BitArray) -> Result(Float, String) {
  case binary {
    <<n:float-size(32)>> -> Ok(n)
    _ -> Error("unable decode to i32")
  }
}

pub fn decode_to_string(binary: BitArray) -> Result(String, String) {
  case binary |> bit_array.to_string {
    Ok(str) -> Ok(str)
    Error(_) -> Error("unable decode to string")
  }
}

// deocder ended -------------------------------------------

// reader --------------------------------------------------
pub fn read_string(binary: BitArray) -> #(String, BitArray) {
  let #(len, binary) = read_varint(binary)
  case read_bytes(binary, len) {
    Ok(#(first, second)) -> #(
      first |> bit_array.to_string |> result.unwrap(""),
      second,
    )
    _ -> panic
  }
}

pub fn read_i32(binary: BitArray) -> #(Float, BitArray) {
  case binary {
    <<first:float-size(32), rest:bits>> -> #(first, rest)
    _ -> panic as "can't read i32"
  }
}

pub fn read_i64(binary: BitArray) -> #(Float, BitArray) {
  case binary {
    <<first:float-size(64), rest:bits>> -> #(first, rest)
    _ -> panic as "can't read i64"
  }
}

pub fn read_key(binary: BitArray) -> #(Key, BitArray) {
  let #(num, binary) = read_varint(binary)
  let wire_type = int.bitwise_and(num, wire_type_mask)
  let field_number = int.bitwise_shift_right(num - wire_type, 3)
  #(Key(field_number, wire_type), binary)
}

pub fn read_bool(binary: BitArray) -> #(Bool, BitArray) {
  let #(num, binary) = read_varint(binary)
  case num {
    0 -> #(False, binary)
    1 -> #(True, binary)
    x -> panic as { "Invalid bool: " <> int.to_string(x) }
  }
}

pub fn read_varint(bin: BitArray) -> #(Int, BitArray) {
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

pub fn read_bytes(
  bin: BitArray,
  length: Int,
) -> Result(#(BitArray, BitArray), Nil) {
  case bit_array.byte_size(bin) > length {
    True ->
      Ok(#(
        bit_array.slice(bin, 0, length) |> result.unwrap(<<>>),
        bit_array.slice(bin, length, bit_array.byte_size(bin) - length)
          |> result.unwrap(<<>>),
      ))
    False -> Error(Nil)
  }
}

fn read_byte(bin: BitArray) -> #(BitArray, Int) {
  case bin {
    <<>> -> #(<<>>, 0)
    <<byte:size(8), rest:bits>> -> #(rest, byte)
    _ -> panic
  }
}
