// controllers/auth.gleam
// POST /api/auth/register
// POST /api/auth/login
// DELETE /api/auth/logout

import gleam/crypto
import gleam/http/request
import gleam/json
import gleam/string
import queries/session_queries
import queries/user_queries
import shared/types
import sqlight
import wisp.{type Request, type Response}

pub fn register(req: Request, conn: sqlight.Connection) -> Response {
  use body <- wisp.require_json(req)
  case types.decode_register_request(body) {
    Error(_) -> wisp.bad_request("Invalid request body")
    Ok(data) -> {
      let hashed = hash_password(data.password)
      case user_queries.insert(conn, data.email, hashed) {
        Error(_) -> json_response(409, types.encode_error(types.ApiError("email already taken")))
        Ok(_) -> json_response(201, json.object([#("ok", json.bool(True))]))
      }
    }
  }
}

pub fn login(req: Request, conn: sqlight.Connection) -> Response {
  use body <- wisp.require_json(req)
  case types.decode_login_request(body) {
    Error(_) -> wisp.bad_request("Invalid request body")
    Ok(data) -> {
      case user_queries.find_by_email(conn, data.email) {
        Ok([user, ..]) ->
          case verify_password(data.password, user.password) {
            True -> {
              let token = random_token()
              case session_queries.insert(conn, token, user.id) {
                Ok(_) -> json_response(200, types.encode_auth_response(types.AuthResponse(token)))
                Error(_) -> wisp.internal_server_error()
              }
            }
            False -> json_response(401, types.encode_error(types.ApiError("invalid credentials")))
          }
        _ -> json_response(401, types.encode_error(types.ApiError("invalid credentials")))
      }
    }
  }
}

pub fn logout(req: Request, conn: sqlight.Connection) -> Response {
  case request.get_header(req, "authorization") {
    Error(_) -> wisp.bad_request("Invalid request body")
    Ok(header) -> {
      let token = string.replace(header, "Bearer ", "")
      case session_queries.delete(conn, token) {
        Ok(_) -> json_response(200, json.object([#("ok", json.bool(True))]))
        Error(_) -> wisp.internal_server_error()
      }
    }
  }
}

// --- helpers ---

fn json_response(status: Int, body: json.Json) -> Response {
  wisp.response(status)
  |> wisp.set_header("content-type", "application/json")
  |> wisp.string_body(json.to_string(body))
}

fn random_token() -> String {
  crypto.strong_random_bytes(32)
  |> bit_array_to_hex
}

@external(erlang, "binary", "encode_hex")
fn bit_array_to_hex(bytes: BitArray) -> String

@external(erlang, "Elixir.Argon2", "hash_pwd_salt")
fn hash_password(password: String) -> String

@external(erlang, "Elixir.Argon2", "verify_pass")
fn verify_password(password: String, hash: String) -> Bool
