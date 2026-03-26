import authorization/policy
import gleam/dynamic/decode
import gleam/result
import sqlight

/// Raw DB row — includes hashed password, used only during login.
pub type User {
  User(id: Int, username: String, password: String, role: policy.Role)
}

fn decoder() -> decode.Decoder(User) {
  use id <- decode.field(0, decode.int)
  use username <- decode.field(1, decode.string)
  use password <- decode.field(2, decode.string)
  use role_str <- decode.field(3, decode.string)
  let role = policy.role_from_string(role_str) |> result.unwrap(policy.User)
  decode.success(User(id: id, username: username, password: password, role: role))
}

fn auth_user_decoder() -> decode.Decoder(policy.AuthUser) {
  use id <- decode.field(0, decode.int)
  use username <- decode.field(1, decode.string)
  use role_str <- decode.field(2, decode.string)
  let role = policy.role_from_string(role_str) |> result.unwrap(policy.User)
  decode.success(policy.AuthUser(id: id, username: username, role: role))
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
    "SELECT id, username, password, role FROM users WHERE username = ?",
    conn,
    [sqlight.text(username)],
    decoder(),
  )
}

/// Used by middleware to resolve a session's user_id into an AuthUser.
/// Does NOT select password — intentionally lean.
pub fn find_by_id(
  conn: sqlight.Connection,
  user_id: Int,
) -> Result(List(policy.AuthUser), sqlight.Error) {
  sqlight.query(
    "SELECT id, username, role FROM users WHERE id = ?",
    conn,
    [sqlight.int(user_id)],
    auth_user_decoder(),
  )
}
