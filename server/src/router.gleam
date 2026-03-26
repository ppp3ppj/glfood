// router.gleam — like router.ex in Phoenix

import controllers/auth
import gleam/http
import gleam/json
import simplifile
import sqlight
import wisp.{type Request, type Response}

pub fn handle(
  req: Request,
  conn: sqlight.Connection,
  static_dir: String,
) -> Response {
  use req <- app_middleware(req, static_dir)

  let resp = case req.method, wisp.path_segments(req) {
    // CORS preflight
    http.Options, _ ->
      wisp.ok()
      |> wisp.set_header("access-control-allow-methods", "GET, POST, DELETE, OPTIONS")
      |> wisp.set_header("access-control-allow-headers", "content-type, authorization")

    _, ["health"]       -> health_check()
    _, ["api", "health"] -> health_check()

    http.Get,    ["api", "auth", "me"]       -> auth.me(req, conn)
    http.Post,   ["api", "auth", "register"] -> auth.register(req, conn)
    http.Post,   ["api", "auth", "login"]    -> auth.login(req, conn)
    http.Delete, ["api", "auth", "logout"]   -> auth.logout(req, conn)

    // SPA fallback — serve index.html for all unknown GET routes
    // so the Lustre/modem client-side router handles navigation
    http.Get, _ -> serve_spa(static_dir)

    _, _ -> wisp.not_found()
  }

  // Allow cross-origin requests (needed for local dev on port 3000)
  wisp.set_header(resp, "access-control-allow-origin", "*")
}

fn app_middleware(
  req: Request,
  static_dir: String,
  next: fn(Request) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  // Serve Vite-built assets (JS chunks, CSS, images) from priv/static
  use <- wisp.serve_static(req, under: "/", from: static_dir)
  next(req)
}

fn serve_spa(static_dir: String) -> Response {
  case simplifile.read(static_dir <> "/index.html") {
    Ok(html) -> wisp.html_response(html, 200)
    Error(_) -> wisp.not_found()
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
