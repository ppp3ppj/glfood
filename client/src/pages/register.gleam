// pages/register.gleam

import gleam/http/response
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import rsvp
import shared/types as shared

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
  Model(email: "", password: "", confirm_password: "", error: "", loading: False)
}

// --- MSG ---

pub type Msg {
  SetEmail(String)
  SetPassword(String)
  SetConfirmPassword(String)
  Submit
  GotResult(Result(response.Response(String), rsvp.Error))
}

// --- UPDATE ---

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    SetEmail(v) -> #(Model(..model, email: v), effect.none())
    SetPassword(v) -> #(Model(..model, password: v), effect.none())
    SetConfirmPassword(v) -> #(Model(..model, confirm_password: v), effect.none())

    Submit ->
      case model.password == model.confirm_password {
        False ->
          #(Model(..model, error: "Passwords do not match"), effect.none())
        True ->
          #(
            Model(..model, loading: True, error: ""),
            rsvp.post(
              "http://localhost:4000/api/auth/register",
              shared.encode_register_request(
                shared.RegisterRequest(
                  email: model.email,
                  password: model.password,
                ),
              ),
              rsvp.expect_ok_response(GotResult),
            ),
          )
      }

    GotResult(Ok(_)) -> #(model, effect.none())

    GotResult(Error(err)) ->
      #(Model(..model, loading: False, error: error_message(err)), effect.none())
  }
}

fn error_message(err: rsvp.Error) -> String {
  case err {
    rsvp.HttpError(resp) ->
      case resp.status {
        409 -> "Email already taken"
        _ -> "Request failed"
      }
    rsvp.NetworkError -> "Network error"
    _ -> "Request failed"
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
