// glfood.gleam — root app
//
// This file only wires components together.
// Business logic lives inside each component module.
//
// Pattern (same idea as React/Vue):
//   - Each component has its own Model / Msg / init / update / view
//   - Parent wraps child Msgs so it can delegate to the right component
//   - element.map converts a child Element(ChildMsg) → Element(Msg)

import components/counter
import components/layouts/root
import components/theme_picker
import lustre
import lustre/element

// --- MODEL ---
// Holds one sub-model per component.

type Model {
  Model(theme: theme_picker.Model, counter: counter.Model)
}

fn init(_flags) -> Model {
  Model(theme: theme_picker.init(), counter: counter.init())
}

// --- MSG ---
// One wrapper variant per component — delegates routing to the right update.

pub type Msg {
  ThemeMsg(theme_picker.Msg)
  CounterMsg(counter.Msg)
}

// --- UPDATE ---
// Route each message to its component, leave everything else unchanged.

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    ThemeMsg(m) -> Model(..model, theme: theme_picker.update(model.theme, m))
    CounterMsg(m) -> Model(..model, counter: counter.update(model.counter, m))
  }
}

// --- VIEW ---
// Compose component views with element.map to lift their Msg into root Msg.

fn view(model: Model) -> element.Element(Msg) {
  root.render(
    theme: theme_picker.current(model.theme),
    navbar: [element.map(theme_picker.view(model.theme), ThemeMsg)],
    content: [element.map(counter.view(model.counter), CounterMsg)],
  )
}

// --- MAIN ---

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
}
