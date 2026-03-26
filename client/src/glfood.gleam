// glfood.gleam — root app

import components/counter
import components/layouts/root
import components/theme_picker
import gleam/http/request
import gleam/option.{type Option}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element
import lustre/element/html
import lustre/event
import rsvp
import pages/counter_page
import pages/home
import pages/login as login_page
import pages/register as register_page
import router.{type Route}

// --- STORAGE FFI (localStorage — no Gleam package for this) ---

@external(javascript, "./storage_ffi.mjs", "load_token")
fn load_token_ffi() -> String

@external(javascript, "./storage_ffi.mjs", "save_token")
fn save_token_ffi(token: String) -> Nil

@external(javascript, "./storage_ffi.mjs", "clear_token")
fn clear_token_ffi() -> Nil

fn load_token() -> Option(String) {
  case load_token_ffi() {
    "" -> option.None
    t -> option.Some(t)
  }
}

// --- MODEL ---

type Model {
  Model(
    route: Route,
    theme: theme_picker.Model,
    counter: counter.Model,
    login: login_page.Model,
    register: register_page.Model,
    token: Option(String),
  )
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  let stored = load_token()
  let model =
    Model(
      route: router.current(),
      theme: theme_picker.init(),
      counter: counter.init(),
      login: login_page.init(),
      register: register_page.init(),
      token: stored,
    )
  let verify_effect = case stored {
    option.None -> effect.none()
    option.Some(t) -> verify_token(t)
  }
  #(model, effect.batch([router.init(RouteChanged), verify_effect]))
}

fn verify_token(token: String) -> Effect(Msg) {
  let assert Ok(req) = request.to("http://localhost:4000/api/auth/me")
  let req = request.set_header(req, "authorization", "Bearer " <> token)
  rsvp.send(req, rsvp.expect_ok_response(fn(result) {
    case result {
      Ok(_) -> TokenVerified(True)
      Error(_) -> TokenVerified(False)
    }
  }))
}

// --- MSG ---

pub type Msg {
  RouteChanged(Route)
  NavigateTo(Route)
  ThemeMsg(theme_picker.Msg)
  CounterMsg(counter.Msg)
  LoginMsg(login_page.Msg)
  RegisterMsg(register_page.Msg)
  TokenVerified(Bool)
  Logout
}

// --- UPDATE ---

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    RouteChanged(route) -> #(Model(..model, route: route), effect.none())

    NavigateTo(route) -> #(model, router.push(route))

    ThemeMsg(m) ->
      #(
        Model(..model, theme: theme_picker.update(model.theme, m)),
        effect.none(),
      )

    CounterMsg(m) ->
      #(
        Model(..model, counter: counter.update(model.counter, m)),
        effect.none(),
      )

    // Login succeeded — persist token and go home
    LoginMsg(login_page.GotToken(Ok(auth))) ->
      #(
        Model(..model, token: option.Some(auth.token), login: login_page.init()),
        effect.batch([
          router.push(router.Home),
          effect.from(fn(_) { save_token_ffi(auth.token) }),
        ]),
      )

    LoginMsg(m) -> {
      let #(login, eff) = login_page.update(model.login, m)
      #(Model(..model, login: login), effect.map(eff, LoginMsg))
    }

    // Register succeeded — go to login
    RegisterMsg(register_page.GotResult(Ok(_response))) ->
      #(
        Model(..model, register: register_page.init()),
        router.push(router.Login),
      )

    RegisterMsg(m) -> {
      let #(register, eff) = register_page.update(model.register, m)
      #(Model(..model, register: register), effect.map(eff, RegisterMsg))
    }

    // Stored token check on startup
    TokenVerified(True) -> #(model, effect.none())
    TokenVerified(False) ->
      #(
        Model(..model, token: option.None),
        effect.batch([
          router.push(router.Login),
          effect.from(fn(_) { clear_token_ffi() }),
        ]),
      )

    Logout ->
      #(
        Model(..model, token: option.None),
        effect.batch([
          router.push(router.Home),
          effect.from(fn(_) { clear_token_ffi() }),
        ]),
      )
  }
}

// --- VIEW ---

fn view(model: Model) -> element.Element(Msg) {
  root.render(
    theme: theme_picker.current(model.theme),
    nav_left: [nav_links(model.route, model.token)],
    nav_right: [element.map(theme_picker.view(model.theme), ThemeMsg)],
    content: [page_content(model)],
  )
}

fn page_content(model: Model) -> element.Element(Msg) {
  case model.route {
    router.Home -> home.view()
    router.Counter ->
      element.map(counter_page.view(model.counter), CounterMsg)
    router.Login -> element.map(login_page.view(model.login), LoginMsg)
    router.Register ->
      element.map(register_page.view(model.register), RegisterMsg)
  }
}

fn nav_links(current: Route, token: Option(String)) -> element.Element(Msg) {
  html.nav([attribute.class("flex items-center gap-1")], [
    nav_link("Home", router.Home, current),
    nav_link("Counter", router.Counter, current),
    case token {
      option.None -> nav_link("Login", router.Login, current)
      option.Some(_) ->
        html.button(
          [
            event.on_click(Logout),
            attribute.class("btn btn-sm btn-ghost text-error"),
          ],
          [html.text("Logout")],
        )
    },
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
