// pages/admin.gleam — admin dashboard page

import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  html.div([attribute.class("p-8 max-w-2xl mx-auto")], [
    html.h1([attribute.class("text-3xl font-bold mb-2")], [
      html.text("Admin Dashboard"),
    ]),
    html.p([attribute.class("text-base-content/60 mb-8")], [
      html.text("Only admins can see this page."),
    ]),
    html.div([attribute.class("grid gap-4")], [
      admin_card("Users", "Manage registered users and their roles"),
      admin_card("Settings", "Configure application settings"),
    ]),
  ])
}

fn admin_card(title: String, description: String) -> Element(msg) {
  html.div([attribute.class("card bg-base-200 shadow")], [
    html.div([attribute.class("card-body")], [
      html.h2([attribute.class("card-title")], [html.text(title)]),
      html.p([], [html.text(description)]),
    ]),
  ])
}
