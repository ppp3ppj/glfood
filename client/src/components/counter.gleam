// components/counter.gleam
// Self-contained counter component.

import gleam/int
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

// --- MODEL ---

pub type Model {
  Model(count: Int)
}

pub fn init() -> Model {
  Model(count: 0)
}

// --- MSG ---

pub type Msg {
  Increment
  Decrement
}

// --- UPDATE ---

pub fn update(model: Model, msg: Msg) -> Model {
  case msg {
    Increment -> Model(count: model.count + 1)
    Decrement -> Model(count: model.count - 1)
  }
}

// --- VIEW ---

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("card bg-base-100 shadow-xl w-80")], [
    html.div([attribute.class("card-body items-center text-center gap-4")], [
      html.h1([attribute.class("card-title text-2xl")], [
        html.text("Hello from Lustre!"),
      ]),
      html.div([attribute.class("badge badge-primary badge-lg text-lg px-6")], [
        html.text(int.to_string(model.count)),
      ]),
      html.div([attribute.class("card-actions gap-2")], [
        html.button(
          [attribute.class("btn btn-primary"), event.on_click(Increment)],
          [html.text("+ Add")],
        ),
        html.button(
          [attribute.class("btn btn-error"), event.on_click(Decrement)],
          [html.text("− Sub")],
        ),
      ]),
    ]),
  ])
}
