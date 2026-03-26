// components/theme_picker.gleam
// Self-contained theme picker component.
// Parent reads `current(model)` to know which theme is active.

import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import theme.{type Theme}

// --- MODEL ---

pub type Model {
  Model(theme: Theme)
}

pub fn init() -> Model {
  setup_click_outside()
  Model(theme: theme.load())
}

// Expose active theme so parent can set data-theme on the root element
pub fn current(model: Model) -> Theme {
  model.theme
}

// --- MSG ---

pub type Msg {
  SetTheme(Theme)
}

// --- UPDATE ---

pub fn update(_model: Model, msg: Msg) -> Model {
  case msg {
    SetTheme(t) -> {
      theme.save(t)
      Model(theme: t)
    }
  }
}

@external(javascript, "./theme_picker_ffi.mjs", "setup_click_outside")
fn setup_click_outside() -> Nil

// --- VIEW ---

pub fn view(model: Model) -> Element(Msg) {
  // <details> handles open/close natively — clicking outside closes it,
  // no conflict with other Lustre event handlers.
  html.details([attribute.class("dropdown dropdown-end")], [
    trigger(),
    panel(model.theme),
  ])
}

fn trigger() -> Element(Msg) {
  html.summary(
    [attribute.class("btn btn-ghost gap-1 px-2 list-none")],
    [
      color_dots(None),
      html.span([attribute.class("opacity-50 text-xs")], [html.text("▾")]),
    ],
  )
}

fn panel(current: Theme) -> Element(Msg) {
  html.div(
    [
      attribute.class(
        "dropdown-content bg-base-100 rounded-box shadow-lg z-10 w-screen max-w-[13rem] mt-1 flex flex-col",
      ),
    ],
    [
      html.div(
        [
          attribute.class(
            "px-4 pt-3 pb-1 text-xs font-semibold opacity-50 uppercase tracking-wider",
          ),
        ],
        [html.text("Theme")],
      ),
      html.ul(
        [attribute.class("menu menu-sm p-2 w-full max-h-80 overflow-y-auto flex-nowrap")],
        list.map(theme.all, fn(t) { theme_item(t, current) }),
      ),
    ],
  )
}

fn theme_item(t: Theme, current: Theme) -> Element(Msg) {
  let is_active = t == current
  // No data-theme on <li> — background comes from the active theme
  // data-theme only on the dots div so only the dots use that theme's palette
  html.li([], [
    html.button(
      [
        event.on_click(SetTheme(t)),
        attribute.class(case is_active {
          True -> "flex items-center gap-3 w-full active"
          False -> "flex items-center gap-3 w-full"
        }),
      ],
      [
        color_dots(Some(t)),
        html.span([attribute.class("capitalize flex-1 text-left")], [
          html.text(t),
        ]),
        case is_active {
          True -> html.span([attribute.class("text-xs")], [html.text("✓")])
          False -> html.span([], [])
        },
      ],
    ),
  ])
}

// Pass Some(theme) to isolate that theme's colors to the dots only.
// Pass None to inherit from the nearest data-theme ancestor.
fn color_dots(t: Option(Theme)) -> Element(Msg) {
  let theme_attr = case t {
    Some(name) -> [attribute.attribute("data-theme", name)]
    None -> []
  }
  html.div(
    [
      attribute.class(
        "grid grid-cols-2 gap-0.5 shrink-0 rounded p-0.5 border border-base-content/10",
      ),
      ..theme_attr
    ],
    [
      html.span([attribute.class("bg-primary rounded-sm size-2")], []),
      html.span([attribute.class("bg-secondary rounded-sm size-2")], []),
      html.span([attribute.class("bg-accent rounded-sm size-2")], []),
      html.span([attribute.class("bg-neutral rounded-sm size-2")], []),
    ],
  )
}
