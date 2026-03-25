// components/layouts/root.gleam
//
// The root layout — equivalent to root.html.heex in Phoenix.
// Renders the full page shell: navbar + main content area.
//
// Usage (in glfood.gleam or any page):
//
//   root.render(
//     theme: "dark",
//     navbar: [element.map(theme_picker.view(model.theme), ThemeMsg)],
//     content: [element.map(counter.view(model.counter), CounterMsg)],
//   )

import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// Renders the root layout shell.
///
/// - `theme`   — DaisyUI theme name applied to the whole page via data-theme
/// - `navbar`  — elements rendered on the right side of the top navbar
/// - `content` — page body rendered inside <main>
pub fn render(
  theme theme: String,
  navbar navbar: List(Element(msg)),
  content content: List(Element(msg)),
) -> Element(msg) {
  html.div(
    [
      attribute.class("min-h-screen bg-base-200 flex flex-col"),
      attribute.attribute("data-theme", theme),
    ],
    [nav(navbar), main(content)],
  )
}

// --- PRIVATE ---

fn nav(actions: List(Element(msg))) -> Element(msg) {
  html.header([attribute.class("navbar bg-base-100 shadow-sm px-4")], [
    // Left slot — add logo or app name here
    html.div([attribute.class("flex-1")], [
      html.span([attribute.class("font-semibold text-lg")], [html.text("glfood")]),
    ]),
    // Right slot — navbar actions (theme picker, user menu, etc.)
    html.div([attribute.class("flex-none flex items-center gap-2")], actions),
  ])
}

fn main(children: List(Element(msg))) -> Element(msg) {
  html.main(
    [attribute.class("flex flex-1 flex-col items-center justify-center gap-6 p-4")],
    children,
  )
}
