// pages/counter_page.gleam — like a Phoenix LiveView for the "/counter" route.
// Thin page wrapper around the counter component.
// Returns Element(counter.Msg) — caller lifts it with element.map(_, CounterMsg).

import components/counter
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(model: counter.Model) -> Element(counter.Msg) {
  html.div([attribute.class("flex flex-col items-center gap-4")], [
    html.h2([attribute.class("text-2xl font-semibold opacity-60")], [
      html.text("Counter"),
    ]),
    counter.view(model),
  ])
}
