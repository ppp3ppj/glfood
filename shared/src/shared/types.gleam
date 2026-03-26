// shared/types.gleam
// Types shared between client and server.

import gleam/dynamic
import gleam/dynamic/decode
import gleam/json

// --- ROLE ---

pub type Role {
  Admin
  User
}

pub fn encode_role(role: Role) -> json.Json {
  case role {
    Admin -> json.string("admin")
    User -> json.string("user")
  }
}

pub fn decode_role() -> decode.Decoder(Role) {
  use s <- decode.then(decode.string)
  case s {
    "admin" -> decode.success(Admin)
    "user" -> decode.success(User)
    _ -> decode.failure(User, "Role")
  }
}

// --- AUTH TYPES ---

pub type RegisterRequest {
  RegisterRequest(username: String, password: String)
}

pub type LoginRequest {
  LoginRequest(username: String, password: String)
}

pub type AuthResponse {
  AuthResponse(token: String, role: Role)
}

pub type ApiError {
  ApiError(message: String)
}

// --- ENCODERS (server → client, client → server) ---

pub fn encode_auth_response(r: AuthResponse) -> json.Json {
  json.object([#("token", json.string(r.token)), #("role", encode_role(r.role))])
}

pub fn encode_login_request(r: LoginRequest) -> json.Json {
  json.object([
    #("username", json.string(r.username)),
    #("password", json.string(r.password)),
  ])
}

pub fn encode_register_request(r: RegisterRequest) -> json.Json {
  json.object([
    #("username", json.string(r.username)),
    #("password", json.string(r.password)),
  ])
}

// --- CLIENT-SIDE DECODER ---

pub fn auth_response_decoder() -> decode.Decoder(AuthResponse) {
  use token <- decode.field("token", decode.string)
  use role <- decode.field("role", decode_role())
  decode.success(AuthResponse(token: token, role: role))
}

pub fn api_error_decoder() -> decode.Decoder(ApiError) {
  use message <- decode.field("error", decode.string)
  decode.success(ApiError(message: message))
}

pub fn encode_error(e: ApiError) -> json.Json {
  json.object([#("error", json.string(e.message))])
}

// --- DECODERS (JSON body → Gleam type) ---

pub fn decode_register_request(
  data: dynamic.Dynamic,
) -> Result(RegisterRequest, List(decode.DecodeError)) {
  let decoder = {
    use username <- decode.field("username", decode.string)
    use password <- decode.field("password", decode.string)
    decode.success(RegisterRequest(username: username, password: password))
  }
  decode.run(data, decoder)
}

pub fn decode_login_request(
  data: dynamic.Dynamic,
) -> Result(LoginRequest, List(decode.DecodeError)) {
  let decoder = {
    use username <- decode.field("username", decode.string)
    use password <- decode.field("password", decode.string)
    decode.success(LoginRequest(username: username, password: password))
  }
  decode.run(data, decoder)
}
