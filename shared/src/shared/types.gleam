// shared/types.gleam
// Types shared between client and server.

import gleam/dynamic
import gleam/dynamic/decode
import gleam/json

// --- AUTH TYPES ---

pub type RegisterRequest {
  RegisterRequest(email: String, password: String)
}

pub type LoginRequest {
  LoginRequest(email: String, password: String)
}

pub type AuthResponse {
  AuthResponse(token: String)
}

pub type ApiError {
  ApiError(message: String)
}

// --- ENCODERS (server → client) ---

pub fn encode_auth_response(r: AuthResponse) -> json.Json {
  json.object([#("token", json.string(r.token))])
}

pub fn encode_error(e: ApiError) -> json.Json {
  json.object([#("error", json.string(e.message))])
}

// --- DECODERS (JSON body → Gleam type) ---

pub fn decode_register_request(
  data: dynamic.Dynamic,
) -> Result(RegisterRequest, List(decode.DecodeError)) {
  let decoder = {
    use email <- decode.field("email", decode.string)
    use password <- decode.field("password", decode.string)
    decode.success(RegisterRequest(email: email, password: password))
  }
  decode.run(data, decoder)
}

pub fn decode_login_request(
  data: dynamic.Dynamic,
) -> Result(LoginRequest, List(decode.DecodeError)) {
  let decoder = {
    use email <- decode.field("email", decode.string)
    use password <- decode.field("password", decode.string)
    decode.success(LoginRequest(email: email, password: password))
  }
  decode.run(data, decoder)
}
