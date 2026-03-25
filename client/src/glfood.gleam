// glfood.gleam — root app
//
// Wires pages, layout, and routing together.
// Business logic lives inside each page/component module.

import components/counter
import components/layouts/root
import components/theme_picker
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element
import lustre/element/html
import lustre/event
import pages/counter_page
import pages/home
import router.{type Route}


// --- MODEL ---

type Model {
  Model(route: Route, theme: theme_picker.Model, counter: counter.Model)
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  let model =
    Model(
      route: router.current(),
      theme: theme_picker.init(),
      counter: counter.init(),
    )

  // modem.init intercepts <a> clicks and popstate — no custom FFI needed
  #(model, router.init(RouteChanged))
}

// --- MSG ---

pub type Msg {
  RouteChanged(Route)   // fired by the hashchange listener
  NavigateTo(Route)     // fired by nav link clicks → pushes hash as effect
  ThemeMsg(theme_picker.Msg)
  CounterMsg(counter.Msg)
}

// --- UPDATE ---

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Hash changed in the browser → sync model
    RouteChanged(route) -> #(Model(..model, route: route), effect.none())

    // User clicked a nav link → push to history; modem fires RouteChanged
    NavigateTo(route) -> #(model, router.push(route))

    ThemeMsg(m) ->
      #(Model(..model, theme: theme_picker.update(model.theme, m)), effect.none())

    CounterMsg(m) ->
      #(
        Model(..model, counter: counter.update(model.counter, m)),
        effect.none(),
      )
  }
}

// --- VIEW ---

fn view(model: Model) -> element.Element(Msg) {
  root.render(
    theme: theme_picker.current(model.theme),
    nav_left: [nav_links(model.route)],
    nav_right: [element.map(theme_picker.view(model.theme), ThemeMsg)],
    content: [page_content(model)],
  )
}

fn page_content(model: Model) -> element.Element(Msg) {
  case model.route {
    router.Home -> home.view()
    router.Counter ->
      element.map(counter_page.view(model.counter), CounterMsg)
  }
}

fn nav_links(current: Route) -> element.Element(Msg) {
  html.nav([attribute.class("flex items-center gap-1")], [
    nav_link("Home", router.Home, current),
    nav_link("Counter", router.Counter, current),
  ])
}

fn nav_link(
  label: String,
  route: Route,
  current: Route,
) -> element.Element(Msg) {
  html.button(
    [
      event.on_click(NavigateTo(route)),
      attribute.class(case route == current {
        True -> "btn btn-sm btn-primary"
        False -> "btn btn-sm btn-ghost"
      }),
    ],
    [html.text(label)],
  )
}

// --- MAIN ---

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
}
