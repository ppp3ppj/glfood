// router.gleam — like router.ex in Phoenix
// Uses modem (official Lustre routing package) — no custom FFI needed.

import gleam/option
import gleam/uri.{type Uri}
import lustre/effect.{type Effect}
import modem

// --- ROUTES ---
// Add a new variant here whenever you create a new page.

pub type Route {
  Home
  Counter
  Login
  Register
  Admin
}

// --- PARSE ---
// Maps a Uri to a Route. Called by modem on every navigation event.

pub fn parse(uri: Uri) -> Route {
  case uri.path {
    "/counter" -> Counter
    "/login" -> Login
    "/register" -> Register
    "/admin" -> Admin
    _ -> Home
  }
}

// --- PATH ---
// The canonical path for each route — used in modem.push and <a href>.

pub fn to_path(route: Route) -> String {
  case route {
    Home -> "/"
    Counter -> "/counter"
    Login -> "/login"
    Register -> "/register"
    Admin -> "/admin"
  }
}

// --- INIT ---
// Returns an Effect that subscribes to all navigation events for the app lifetime.
// Pass this to lustre.application's init.

pub fn init(on_change: fn(Route) -> msg) -> Effect(msg) {
  modem.init(fn(uri) { on_change(parse(uri)) })
}

// --- CURRENT ---
// Read the active route from the browser's current URL (used in app init).

pub fn current() -> Route {
  case modem.initial_uri() {
    Ok(uri) -> parse(uri)
    Error(_) -> Home
  }
}

// --- NAVIGATE ---
// Returns an Effect that pushes a new route onto the history stack.
// Use this in update via the NavigateTo Msg — never call directly from a view.

pub fn push(route: Route) -> Effect(msg) {
  modem.push(to_path(route), option.None, option.None)
}
