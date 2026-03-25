// router.gleam — like router.ex in Phoenix

import controllers/auth
import sqlight
import wisp.{type Request, type Response}

pub fn handle(req: Request, conn: sqlight.Connection) -> Response {
  let resp = case wisp.path_segments(req) {
    // Auth API
    ["api", "auth", "register"] -> auth.register(req, conn)
    ["api", "auth", "login"]    -> auth.login(req, conn)
    ["api", "auth", "logout"]   -> auth.logout(req, conn)

    // Serve compiled client from priv/static (catch-all for SPA)
    _ -> wisp.not_found()
  }

  wisp.set_header(resp, "access-control-allow-origin", "*")
}
