import gleam/dynamic/decode
import gleam/result
import sqlight

pub fn insert(
  conn: sqlight.Connection,
  token: String,
  user_id: Int,
) -> Result(Nil, sqlight.Error) {
  sqlight.query(
    "INSERT INTO sessions (id, user_id, expires_at)
     VALUES (?, ?, datetime('now', '+7 days'))",
    conn,
    [sqlight.text(token), sqlight.int(user_id)],
    decode.success(Nil),
  )
  |> result.map(fn(_) { Nil })
}

pub fn find(
  conn: sqlight.Connection,
  token: String,
) -> Result(List(Int), sqlight.Error) {
  sqlight.query(
    "SELECT user_id FROM sessions
     WHERE id = ? AND expires_at > datetime('now')",
    conn,
    [sqlight.text(token)],
    decode.field(0, decode.int, decode.success),
  )
}

pub fn delete(
  conn: sqlight.Connection,
  token: String,
) -> Result(Nil, sqlight.Error) {
  sqlight.query(
    "DELETE FROM sessions WHERE id = ?",
    conn,
    [sqlight.text(token)],
    decode.success(Nil),
  )
  |> result.map(fn(_) { Nil })
}
