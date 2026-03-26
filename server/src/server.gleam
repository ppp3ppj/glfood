// server.gleam — entry point
// 1. Open SQLite + run migrations
// 2. Start HTTP server on port 4000

import db
import gleam/erlang/process
import mist
import router
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()

  let assert Ok(conn) = db.connect()
  let assert Ok(_) = db.migrate(conn)

  let handler = fn(req) { router.handle(req, conn) }

  let assert Ok(_) =
    wisp_mist.handler(handler, "secret_key_base_change_in_prod")
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(4000)
    |> mist.start

  process.sleep_forever()
}
