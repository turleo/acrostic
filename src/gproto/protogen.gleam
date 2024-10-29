import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/otp/actor
import gleam/string

type State {
  State(files: List(String))
}

pub type Message {
  Load(filename: String)
  Generate(client: Subject(Result(Nil, String)))
  Shutdown
}

pub type Self =
  Subject(Message)

pub fn load(self: Self, filename: String) {
  process.send(self, Load(filename))
  self
}

pub fn generate(self: Self) {
  case process.try_call(self, Generate, within: 10_000) {
    Ok(_) -> {
      io.println("generate done")
      self
    }
    Error(e) -> {
      io.println_error(string.inspect(e))
      self
    }
  }
}

pub fn shutdown(self: Self) {
  process.send(self, Shutdown)
}

pub fn start() -> Result(Self, actor.StartError) {
  actor.start(State([]), fn(message: Message, self: State) -> actor.Next(
    Message,
    State,
  ) {
    case message {
      Load(filename) -> {
        io.println("loading filename: " <> filename)
        actor.continue(self)
      }
      Generate(client) -> {
        process.send(client, Ok(Nil))
        actor.continue(self)
      }
      Shutdown -> {
        actor.Stop(process.Normal)
      }
    }
  })
}
