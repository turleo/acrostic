import gleam/int

pub type WireType {
  VarInt
  I64
  Len
  I32
}

pub fn to_int(wire: WireType) {
  case wire {
    VarInt -> 0
    I64 -> 1
    Len -> 2
    I32 -> 5
  }
}

pub fn from_int(n: Int) {
  case n {
    0 -> Ok(VarInt)
    1 -> Ok(I64)
    2 -> Ok(Len)
    5 -> Ok(I32)
    x -> Error("Invalid wire number, " <> int.to_string(x))
  }
}
