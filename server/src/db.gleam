// db.gleam — open SQLite connection + run pending migrations

import gleam/dynamic/decode
import gleam/result
import gleam/order
import gleam/string
import simplifile
import sqlight

const db_path = "app.db"

@external(erlang, "db_ffi", "priv_dir")
fn priv_dir() -> String

fn migrations_dir() -> String {
  priv_dir() <> "/migrations"
}

pub fn connect() -> Result(sqlight.Connection, sqlight.Error) {
  use conn <- result.try(sqlight.open(db_path))
  use _ <- result.try(sqlight.exec("PRAGMA foreign_keys = ON", conn))
  // WAL mode: allows external tools (DB Browser, sqlite3 CLI) to read the
  // database while the server is running without getting "database is locked".
  use _ <- result.try(sqlight.exec("PRAGMA journal_mode = WAL", conn))
  // Wait up to 5 seconds before returning SQLITE_BUSY instead of failing
  // immediately when another process holds a write lock.
  use _ <- result.try(sqlight.exec("PRAGMA busy_timeout = 5000", conn))
  Ok(conn)
}

pub fn migrate(conn: sqlight.Connection) -> Result(Nil, String) {
  let sql =
    "CREATE TABLE IF NOT EXISTS schema_migrations (
       version TEXT PRIMARY KEY,
       inserted_at TEXT NOT NULL DEFAULT (datetime('now'))
     )"
  case sqlight.exec(sql, conn) {
    Error(e) -> Error("schema_migrations setup failed: " <> string.inspect(e))
    Ok(_) -> run_pending(conn)
  }
}

fn run_pending(conn: sqlight.Connection) -> Result(Nil, String) {
  let dir = migrations_dir()
  case simplifile.read_directory(dir) {
    Error(e) -> Error("Cannot read migrations/: " <> string.inspect(e))
    Ok(files) -> {
      files
      |> list_sql_files
      |> run_each(conn, dir)
      Ok(Nil)
    }
  }
}

fn list_sql_files(files: List(String)) -> List(String) {
  files
  |> list_filter_sql
  |> list_sort
}

fn list_filter_sql(files: List(String)) -> List(String) {
  case files {
    [] -> []
    [f, ..rest] ->
      case string.ends_with(f, ".sql") {
        True -> [f, ..list_filter_sql(rest)]
        False -> list_filter_sql(rest)
      }
  }
}

fn list_sort(files: List(String)) -> List(String) {
  case files {
    [] -> []
    [first, ..rest] -> insert_sorted(first, list_sort(rest))
  }
}

fn insert_sorted(x: String, sorted: List(String)) -> List(String) {
  case sorted {
    [] -> [x]
    [head, ..tail] ->
      case string.compare(x, head) {
        order.Lt | order.Eq -> [x, head, ..tail]
        order.Gt -> [head, ..insert_sorted(x, tail)]
      }
  }
}

fn run_each(files: List(String), conn: sqlight.Connection, dir: String) -> Nil {
  case files {
    [] -> Nil
    [file, ..rest] -> {
      run_one(conn, dir, file)
      run_each(rest, conn, dir)
    }
  }
}

fn run_one(conn: sqlight.Connection, dir: String, file: String) -> Nil {
  let version = string.drop_end(file, 4)
  let already =
    sqlight.query(
      "SELECT 1 FROM schema_migrations WHERE version = ?",
      conn,
      [sqlight.text(version)],
      decode.success(Nil),
    )
  case already {
    Ok([_, ..]) -> Nil
    _ -> {
      let path = dir <> "/" <> file
      let assert Ok(sql) = simplifile.read(path)
      let assert Ok(_) = sqlight.exec(sql, conn)
      let assert Ok(_) =
        sqlight.exec(
          "INSERT INTO schema_migrations (version) VALUES ('" <> version <> "')",
          conn,
        )
      Nil
    }
  }
}
