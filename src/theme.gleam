// theme.gleam — reusable theme library
// Theme is a String alias — clean for large lists, no verbose variants.

import gleam/list

// --- TYPE ---

pub type Theme =
  String

// --- ALL THEMES ---

pub const all: List(Theme) = [
  "light", "dark", "cupcake", "bumblebee", "emerald", "corporate",
  "synthwave", "retro", "cyberpunk", "valentine", "halloween", "garden",
  "forest", "aqua", "lofi", "pastel", "fantasy", "wireframe", "black",
  "luxury", "dracula", "cmyk", "autumn", "business", "acid", "lemonade",
  "night", "coffee", "winter", "dim", "nord", "sunset",
]

pub fn default() -> Theme {
  "light"
}

// --- HELPERS ---

pub fn from_string(s: String) -> Theme {
  case list.contains(all, s) {
    True -> s
    False -> default()
  }
}

// --- LOCALSTORAGE ---

pub fn load() -> Theme {
  load_theme() |> from_string
}

pub fn save(theme: Theme) -> Nil {
  save_theme(theme)
}

@external(javascript, "./theme_ffi.mjs", "load_theme")
fn load_theme() -> String

@external(javascript, "./theme_ffi.mjs", "save_theme")
fn save_theme(_theme: String) -> Nil
