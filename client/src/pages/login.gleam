// pages/login.gleam

import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared/types as shared

// --- FFI ---

@external(javascript, "./login_ffi.mjs", "post_json")
fn post_json_ffi(
  url: String,
  body: String,
  on_ok: fn(dynamic.Dynamic) -> Nil,
  on_err: fn(String) -> Nil,
) -> Nil

// --- MODEL ---

pub type Model {
  Model(email: String, password: String, error: String, loading: Bool)
}

pub fn init() -> Model {
  Model(email: "", password: "", error: "", loading: False)
}

// --- MSG ---

pub type Msg {
  SetEmail(String)
  SetPassword(String)
  Submit
  GotToken(Result(shared.AuthResponse, String))
}

// --- UPDATE ---

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    SetEmail(v) -> #(Model(..model, email: v), effect.none())
    SetPassword(v) -> #(Model(..model, password: v), effect.none())

    Submit -> {
      let body =
        json.to_string(shared.encode_login_request(
          shared.LoginRequest(email: model.email, password: model.password),
        ))
      let req =
        effect.from(fn(dispatch) {
          post_json_ffi(
            "http://localhost:4000/api/auth/login",
            body,
            fn(data) {
              case decode.run(data, shared.auth_response_decoder()) {
                Ok(auth) -> dispatch(GotToken(Ok(auth)))
                Error(_) -> dispatch(GotToken(Error("Unexpected response")))
              }
            },
            fn(err) { dispatch(GotToken(Error(err))) },
          )
        })
      #(Model(..model, loading: True, error: ""), req)
    }

    GotToken(Ok(_)) -> #(model, effect.none())

    GotToken(Error(msg)) ->
      #(Model(..model, loading: False, error: msg), effect.none())
  }
}

// --- VIEW ---

pub fn view(model: Model) -> Element(Msg) {
  html.div(
    [attribute.class("flex items-center justify-center min-h-96")],
    [
      html.div(
        [attribute.class("card bg-base-200 w-full max-w-sm shadow-xl")],
        [
          html.div([attribute.class("card-body gap-4")], [
            html.h2(
              [attribute.class("card-title justify-center text-2xl")],
              [html.text("Sign in")],
            ),
            case model.error {
              "" -> html.text("")
              err ->
                html.div(
                  [attribute.class("alert alert-error text-sm")],
                  [html.text(err)],
                )
            },
            html.label([attribute.class("form-control w-full")], [
              html.div([attribute.class("label")], [
                html.span([attribute.class("label-text")], [html.text("Email")]),
              ]),
              html.input([
                attribute.type_("email"),
                attribute.class("input input-bordered w-full"),
                attribute.placeholder("you@example.com"),
                attribute.value(model.email),
                event.on_input(SetEmail),
              ]),
            ]),
            html.label([attribute.class("form-control w-full")], [
              html.div([attribute.class("label")], [
                html.span([attribute.class("label-text")], [
                  html.text("Password"),
                ]),
              ]),
              html.input([
                attribute.type_("password"),
                attribute.class("input input-bordered w-full"),
                attribute.placeholder("••••••••"),
                attribute.value(model.password),
                event.on_input(SetPassword),
              ]),
            ]),
            html.button(
              [
                attribute.class("btn btn-primary w-full"),
                attribute.disabled(model.loading),
                event.on_click(Submit),
              ],
              [
                html.text(case model.loading {
                  True -> "Signing in…"
                  False -> "Sign in"
                }),
              ],
            ),
            html.p([attribute.class("text-center text-sm opacity-70")], [
              html.text("No account? "),
              html.a(
                [
                  attribute.href("/register"),
                  attribute.class("link link-primary"),
                ],
                [html.text("Create one")],
              ),
            ]),
          ]),
        ],
      ),
    ],
  )
}
