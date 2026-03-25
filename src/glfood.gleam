import gleam/int
import lustre
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

// --- MODEL ---
// The state of your app.

type Model =
  Int

fn init(_flags) -> Model {
  0
}

// --- MSG ---
// All the things a user can do.

pub type Msg {
  Increment
  Decrement
}

// --- UPDATE ---
// How the model changes for each message.

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    Increment -> model + 1
    Decrement -> model - 1
  }
}

// --- VIEW ---
// Pure function: model -> HTML. No side effects here.

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.h1([], [html.text("Hello from Lustre!")]),
    html.p([], [html.text("Count: " <> int.to_string(model))]),
    html.button([event.on_click(Increment)], [html.text("+ Add")]),
    html.button([event.on_click(Decrement)], [html.text("- Sub")]),
  ])
}

// --- MAIN ---
// Wire everything together and mount onto #app in index.html.

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
}
