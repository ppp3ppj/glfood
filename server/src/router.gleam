// router.gleam — like router.ex in Phoenix

import controllers/auth
import gleam/http
import gleam/json
import sqlight
import wisp.{type Request, type Response}

pub fn handle(req: Request, conn: sqlight.Connection) -> Response {
  use <- wisp.log_request(req)

  // Handle CORS preflight
  case req.method {
    http.Options ->
      wisp.ok()
      |> wisp.set_header("access-control-allow-origin", "*")
      |> wisp.set_header("access-control-allow-methods", "GET, POST, DELETE, OPTIONS")
      |> wisp.set_header("access-control-allow-headers", "content-type, authorization")
    _ -> {
      let resp = case wisp.path_segments(req) {
        ["health"] -> health_check()
        ["api", "health"] -> health_check()
        ["api", "auth", "me"]       -> auth.me(req, conn)
        ["api", "auth", "register"] -> auth.register(req, conn)
        ["api", "auth", "login"]    -> auth.login(req, conn)
        ["api", "auth", "logout"]   -> auth.logout(req, conn)
        _ -> wisp.not_found()
      }
      wisp.set_header(resp, "access-control-allow-origin", "*")
    }
  }
}

fn health_check() -> Response {
  let body = json.object([
    #("status", json.string("ok")),
    #("server", json.string("glfood")),
  ])
  wisp.response(200)
  |> wisp.set_header("content-type", "application/json")
  |> wisp.string_body(json.to_string(body))
}
