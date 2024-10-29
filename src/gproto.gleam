import gleam/erlang/process
import gleam/io
import gproto/protogen

pub fn main() {
  io.println("Hello from gproto!")

  let assert Ok(generator) = protogen.start()
  let _ =
    generator
    |> protogen.load("hello.proto")
    |> protogen.load("lobby.proto")
    |> protogen.generate
    |> protogen.shutdown

  process.sleep_forever()
}
