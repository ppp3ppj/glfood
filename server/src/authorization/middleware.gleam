// authorization/middleware.gleam
//
// Wisp middleware that resolves the Bearer token into an AuthUser and
// injects it into protected route handlers.
//
// Usage patterns:
//
//   Pattern A — just authentication:
//     use actor <- middleware.require_auth(req, conn)
//     // actor: AuthUser
//
//   Pattern B — authentication + role gate:
//     use actor <- middleware.require_role(req, conn, policy.Admin)
//     // actor: AuthUser (guaranteed to be Admin)
//
//   Pattern C — optional auth (behave differently for guests vs logged-in):
//     let current = middleware.get_current_user(req, conn)

import authorization/policy.{type AuthUser, type Role}
import gleam/http/request
import gleam/string
import queries/session_queries
import queries/user_queries
import sqlight
import wisp.{type Request, type Response}

// ---------------------------------------------------------------------------
// Public middleware functions
// ---------------------------------------------------------------------------

/// Verify the Bearer token and resolve it to an AuthUser.
/// Calls `next(actor)` on success, returns 401 on failure.
///
///   use actor <- middleware.require_auth(req, conn)
///
pub fn require_auth(
  req: Request,
  conn: sqlight.Connection,
  next: fn(AuthUser) -> Response,
) -> Response {
  case get_current_user(req, conn) {
    Ok(actor) -> next(actor)
    Error(e) -> unauthorized(e)
  }
}

/// Verify token AND assert the user has the required role.
/// Returns 401 if not authenticated, 403 if authenticated but wrong role.
///
///   use actor <- middleware.require_role(req, conn, policy.Admin)
///
pub fn require_role(
  req: Request,
  conn: sqlight.Connection,
  required_role: Role,
  next: fn(AuthUser) -> Response,
) -> Response {
  case get_current_user(req, conn) {
    Error(e) -> unauthorized(e)
    Ok(actor) ->
      case actor.role == required_role {
        True -> next(actor)
        False -> forbidden()
      }
  }
}

/// Extract the AuthUser from the request without short-circuiting.
/// Returns Ok(AuthUser) if the token is valid, Error(reason) otherwise.
/// Useful for optional-auth endpoints.
pub fn get_current_user(
  req: Request,
  conn: sqlight.Connection,
) -> Result(AuthUser, String) {
  use token <- extract_token(req)
  use user_id <- resolve_session(conn, token)
  use actor <- resolve_user(conn, user_id)
  Ok(actor)
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

fn extract_token(
  req: Request,
  next: fn(String) -> Result(AuthUser, String),
) -> Result(AuthUser, String) {
  case request.get_header(req, "authorization") {
    Error(_) -> Error("missing authorization header")
    Ok(header) ->
      case string.split_once(header, "Bearer ") {
        Ok(#(_, token)) -> next(token)
        Error(_) -> Error("malformed authorization header")
      }
  }
}

fn resolve_session(
  conn: sqlight.Connection,
  token: String,
  next: fn(Int) -> Result(AuthUser, String),
) -> Result(AuthUser, String) {
  case session_queries.find(conn, token) {
    Ok([user_id, ..]) -> next(user_id)
    Ok([]) -> Error("expired or invalid token")
    Error(_) -> Error("session lookup failed")
  }
}

fn resolve_user(
  conn: sqlight.Connection,
  user_id: Int,
  next: fn(AuthUser) -> Result(AuthUser, String),
) -> Result(AuthUser, String) {
  case user_queries.find_by_id(conn, user_id) {
    Ok([actor, ..]) -> next(actor)
    Ok([]) -> Error("user not found")
    Error(_) -> Error("user lookup failed")
  }
}

fn unauthorized(reason: String) -> Response {
  wisp.response(401)
  |> wisp.set_header("content-type", "application/json")
  |> wisp.string_body("{\"error\":\"" <> reason <> "\"}")
}

fn forbidden() -> Response {
  wisp.response(403)
  |> wisp.set_header("content-type", "application/json")
  |> wisp.string_body("{\"error\":\"forbidden\"}")
}

