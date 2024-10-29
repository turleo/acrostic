import gleam/int

pub fn valid_int32(n: Int, fallback: fn(Int, Int) -> Int) -> Int {
  case int.clamp(n, -{ 0x80000000 }, 0x7FFFFFFF) {
    x if x == n -> n
    x -> {
      fallback(n, x)
    }
  }
}

pub fn valid_int64(n: Int, fallback: fn(Int, Int) -> Int) -> Int {
  case int.clamp(n, -{ 0x8000000000000000 }, 0x7FFFFFFFFFFFFFFF) {
    x if x == n -> n
    x -> {
      fallback(n, x)
    }
  }
}

pub fn valid_uint32(n: Int, fallback: fn(Int, Int) -> Int) -> Int {
  case int.clamp(n, 0, 0xFFFFFFFF) {
    x if x == n -> n
    x -> {
      fallback(n, x)
    }
  }
}

pub fn valid_uint64(n: Int, fallback: fn(Int, Int) -> Int) -> Int {
  case int.clamp(n, 0, 0xFFFFFFFFFFFFFFFF) {
    x if x == n -> n
    x -> {
      fallback(n, x)
    }
  }
}
