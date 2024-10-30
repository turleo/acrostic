import gleam/erlang/process
import gleam/io
import gproto/protogen

pub fn main() {
  io.println("Hello from gproto!")

  let assert Ok(generator) = protogen.start()
  let _ =
    generator
    |> protogen.load("protos/common.proto")
    |> protogen.load("protos/hello.proto")
    |> protogen.load("protos/lobby.proto")
    |> protogen.generate("src/proto.gleam")
    |> protogen.shutdown

  process.sleep_forever()
}
