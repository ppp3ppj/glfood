// pages/register.gleam

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
  Model(
    email: String,
    password: String,
    confirm_password: String,
    error: String,
    loading: Bool,
  )
}

pub fn init() -> Model {
  Model(
    email: "",
    password: "",
    confirm_password: "",
    error: "",
    loading: False,
  )
}

// --- MSG ---

pub type Msg {
  SetEmail(String)
  SetPassword(String)
  SetConfirmPassword(String)
  Submit
  GotResult(Result(Nil, String))
}

// --- UPDATE ---

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    SetEmail(v) -> #(Model(..model, email: v), effect.none())
    SetPassword(v) -> #(Model(..model, password: v), effect.none())
    SetConfirmPassword(v) -> #(Model(..model, confirm_password: v), effect.none())

    Submit -> {
      case model.password == model.confirm_password {
        False ->
          #(
            Model(..model, error: "Passwords do not match"),
            effect.none(),
          )
        True -> {
          let body =
            json.to_string(shared.encode_register_request(
              shared.RegisterRequest(email: model.email, password: model.password),
            ))
          let req =
            effect.from(fn(dispatch) {
              post_json_ffi(
                "http://localhost:4000/api/auth/register",
                body,
                fn(_data) { dispatch(GotResult(Ok(Nil))) },
                fn(err) { dispatch(GotResult(Error(err))) },
              )
            })
          #(Model(..model, loading: True, error: ""), req)
        }
      }
    }

    GotResult(Ok(_)) -> #(model, effect.none())

    GotResult(Error(msg)) ->
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
              [html.text("Create account")],
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
            html.label([attribute.class("form-control w-full")], [
              html.div([attribute.class("label")], [
                html.span([attribute.class("label-text")], [
                  html.text("Confirm password"),
                ]),
              ]),
              html.input([
                attribute.type_("password"),
                attribute.class("input input-bordered w-full"),
                attribute.placeholder("••••••••"),
                attribute.value(model.confirm_password),
                event.on_input(SetConfirmPassword),
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
                  True -> "Creating account…"
                  False -> "Create account"
                }),
              ],
            ),
            html.p([attribute.class("text-center text-sm opacity-70")], [
              html.text("Already have an account? "),
              html.a(
                [attribute.href("/login"), attribute.class("link link-primary")],
                [html.text("Sign in")],
              ),
            ]),
          ]),
        ],
      ),
    ],
  )
}
