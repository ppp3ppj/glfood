// db.gleam — open SQLite connection + run pending migrations

import gleam/dynamic/decode
import gleam/result
import gleam/order
import gleam/string
import simplifile
import sqlight

const db_path = "app.db"

const migrations_dir = "migrations"

pub fn connect() -> Result(sqlight.Connection, sqlight.Error) {
  use conn <- result.try(sqlight.open(db_path))
  use _ <- result.try(sqlight.exec("PRAGMA foreign_keys = ON", conn))
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
  case simplifile.read_directory(migrations_dir) {
    Error(e) -> Error("Cannot read migrations/: " <> string.inspect(e))
    Ok(files) -> {
      files
      |> list_sql_files
      |> run_each(conn)
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
  // Simple insertion sort — migration list is always tiny
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

fn run_each(files: List(String), conn: sqlight.Connection) -> Nil {
  case files {
    [] -> Nil
    [file, ..rest] -> {
      run_one(conn, file)
      run_each(rest, conn)
    }
  }
}

fn run_one(conn: sqlight.Connection, file: String) -> Nil {
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
      let path = migrations_dir <> "/" <> file
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
