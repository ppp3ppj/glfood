// components/layouts/root.gleam
//
// Root layout — equivalent to root.html.heex in Phoenix.
// Renders the full page shell: navbar + main content area.
//
// Usage:
//   root.render(
//     theme: "dark",
//     nav_left:  [nav_links(model.route)],   ← logo area + page links
//     nav_right: [element.map(theme_picker.view(model.theme), ThemeMsg)],
//     content:   [page_content(model)],
//   )

import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn render(
  theme theme: String,
  nav_left nav_left: List(Element(msg)),
  nav_right nav_right: List(Element(msg)),
  content content: List(Element(msg)),
) -> Element(msg) {
  html.div(
    [
      attribute.class("min-h-screen bg-base-200 flex flex-col"),
      attribute.attribute("data-theme", theme),
    ],
    [navbar(nav_left, nav_right), main(content)],
  )
}

// --- PRIVATE ---

fn navbar(left: List(Element(msg)), right: List(Element(msg))) -> Element(msg) {
  html.header([attribute.class("navbar bg-base-100 shadow-sm px-4")], [
    // Left: app name + nav links
    html.div([attribute.class("flex-1 flex items-center gap-3")], [
      html.span([attribute.class("font-bold text-lg")], [html.text("glfood")]),
      html.div([attribute.class("flex items-center gap-1")], left),
    ]),
    // Right: theme picker, user menu, etc.
    html.div([attribute.class("flex-none flex items-center gap-2")], right),
  ])
}

fn main(children: List(Element(msg))) -> Element(msg) {
  html.main(
    [
      attribute.class(
        "flex flex-1 flex-col items-center justify-center gap-6 p-4",
      ),
    ],
    children,
  )
}
