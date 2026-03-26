import gleam/dynamic/decode
import gleam/result
import sqlight

pub type User {
  User(id: Int, email: String, password: String)
}

fn decoder() -> decode.Decoder(User) {
  use id <- decode.field(0, decode.int)
  use email <- decode.field(1, decode.string)
  use password <- decode.field(2, decode.string)
  decode.success(User(id: id, email: email, password: password))
}

pub fn insert(
  conn: sqlight.Connection,
  email: String,
  hashed: String,
) -> Result(Nil, sqlight.Error) {
  sqlight.query(
    "INSERT INTO users (email, password) VALUES (?, ?)",
    conn,
    [sqlight.text(email), sqlight.text(hashed)],
    decode.success(Nil),
  )
  |> result.map(fn(_) { Nil })
}

pub fn find_by_email(
  conn: sqlight.Connection,
  email: String,
) -> Result(List(User), sqlight.Error) {
  sqlight.query(
    "SELECT id, email, password FROM users WHERE email = ?",
    conn,
    [sqlight.text(email)],
    decoder(),
  )
}
