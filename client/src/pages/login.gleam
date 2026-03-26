// pages/login.gleam

import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import rsvp
import shared/types as shared

// --- MODEL ---

pub type Model {
  Model(username: String, password: String, error: String, loading: Bool)
}

pub fn init() -> Model {
  Model(username: "", password: "", error: "", loading: False)
}

// --- MSG ---

pub type Msg {
  SetUsername(String)
  SetPassword(String)
  Submit
  GotToken(Result(shared.AuthResponse, rsvp.Error))
}

// --- UPDATE ---

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    SetUsername(v) -> #(Model(..model, username: v), effect.none())
    SetPassword(v) -> #(Model(..model, password: v), effect.none())

    Submit ->
      #(
        Model(..model, loading: True, error: ""),
        rsvp.post(
          "http://localhost:4000/api/auth/login",
          shared.encode_login_request(
            shared.LoginRequest(username: model.username, password: model.password),
          ),
          rsvp.expect_json(shared.auth_response_decoder(), GotToken),
        ),
      )

    GotToken(Ok(_)) -> #(model, effect.none())

    GotToken(Error(err)) ->
      #(Model(..model, loading: False, error: error_message(err)), effect.none())
  }
}

fn error_message(err: rsvp.Error) -> String {
  case err {
    rsvp.HttpError(resp) ->
      case resp.status {
        401 -> "Invalid username or password"
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
                html.span([attribute.class("label-text")], [html.text("Username")]),
              ]),
              html.input([
                attribute.type_("text"),
                attribute.class("input input-bordered w-full"),
                attribute.placeholder("your_username"),
                attribute.value(model.username),
                event.on_input(SetUsername),
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
