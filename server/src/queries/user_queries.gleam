import gleam/dynamic/decode
import gleam/result
import sqlight

pub type User {
  User(id: Int, username: String, password: String)
}

fn decoder() -> decode.Decoder(User) {
  use id <- decode.field(0, decode.int)
  use username <- decode.field(1, decode.string)
  use password <- decode.field(2, decode.string)
  decode.success(User(id: id, username: username, password: password))
}

pub fn insert(
  conn: sqlight.Connection,
  username: String,
  hashed: String,
) -> Result(Nil, sqlight.Error) {
  sqlight.query(
    "INSERT INTO users (username, password) VALUES (?, ?)",
    conn,
    [sqlight.text(username), sqlight.text(hashed)],
    decode.success(Nil),
  )
  |> result.map(fn(_) { Nil })
}

pub fn find_by_username(
  conn: sqlight.Connection,
  username: String,
) -> Result(List(User), sqlight.Error) {
  sqlight.query(
    "SELECT id, username, password FROM users WHERE username = ?",
    conn,
    [sqlight.text(username)],
    decoder(),
  )
}
