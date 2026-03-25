// pages/home.gleam — like a Phoenix LiveView module for the "/" route.
// Pure view, no state. Returns Element(msg) so no element.map needed.

import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  html.div([attribute.class("hero min-h-[60vh]")], [
    html.div([attribute.class("hero-content text-center")], [
      html.div([attribute.class("max-w-md flex flex-col items-center gap-6")], [
        html.h1([attribute.class("text-5xl font-bold")], [html.text("glfood")]),
        html.p([attribute.class("opacity-70")], [
          html.text("Built with Gleam · Lustre · DaisyUI"),
        ]),
        html.a(
          [
            attribute.href("/counter"),
            attribute.class("btn btn-primary btn-wide"),
          ],
          [html.text("Get Started →")],
        ),
      ]),
    ]),
  ])
}
