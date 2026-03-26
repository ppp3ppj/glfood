// server.gleam — entry point
// 1. Open SQLite + run migrations
// 2. Start HTTP server (HOST/PORT from env, default localhost:4000)

import db
import envoy
import gleam/erlang/process
import gleam/int
import gleam/result
import mist
import router
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()

  let host = envoy.get("HOST") |> result.unwrap("localhost")
  let port = envoy.get("PORT") |> result.try(int.parse) |> result.unwrap(4000)

  let assert Ok(conn) = db.connect()
  let assert Ok(_) = db.migrate(conn)

  let assert Ok(priv_dir) = wisp.priv_directory("server")
  let static_dir = priv_dir <> "/static"

  let handler = fn(req) { router.handle(req, conn, static_dir) }

  let assert Ok(_) =
    wisp_mist.handler(handler, "secret_key_base_change_in_prod")
    |> mist.new
    |> mist.bind(host)
    |> mist.port(port)
    |> mist.start

  process.sleep_forever()
}
