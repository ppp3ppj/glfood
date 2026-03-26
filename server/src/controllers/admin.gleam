// controllers/admin.gleam
//
// Example admin-only controller demonstrating both RBAC patterns.
//
// Pattern A — role gate (simple, covers whole handler):
//   use actor <- middleware.require_role(req, conn, policy.Admin)
//
// Pattern B — resource policy (fine-grained, per-resource):
//   use actor <- middleware.require_auth(req, conn)
//   use <- policy.permit(actor, policy.Update, item_policy(item))

import authorization/middleware
import authorization/policy
import gleam/json
import sqlight
import wisp.{type Request, type Response}

/// GET /api/admin/dashboard — admin only.
pub fn dashboard(req: Request, conn: sqlight.Connection) -> Response {
  use actor <- middleware.require_role(req, conn, policy.Admin)
  json_response(
    200,
    json.object([
      #("message", json.string("Welcome to the admin dashboard")),
      #("admin", json.string(actor.username)),
    ]),
  )
}

// ---------------------------------------------------------------------------
// Example: resource-level policy (Bodyguard pattern)
// ---------------------------------------------------------------------------
//
// Uncomment and adapt when you add a resource that needs per-record auth.
//
// import queries/item_queries
//
// pub type Item {
//   Item(id: Int, owner_id: Int, name: String)
// }
//
// fn item_policy(item: Item) -> policy.Policy {
//   fn(actor: policy.AuthUser, action: policy.Action) -> Bool {
//     case action {
//       policy.Read   -> True
//       policy.Manage -> actor.role == policy.Admin
//       _             -> actor.role == policy.Admin || actor.id == item.owner_id
//     }
//   }
// }
//
// pub fn update_item(req: Request, conn: sqlight.Connection, item_id: Int) -> Response {
//   use actor <- middleware.require_auth(req, conn)
//   // Fetch the item from DB, then check policy
//   let item = Item(id: item_id, owner_id: 42, name: "example")
//   use <- policy.permit(actor, policy.Update, item_policy(item))
//   json_response(200, json.object([#("ok", json.bool(True))]))
// }

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fn json_response(status: Int, body: json.Json) -> Response {
  wisp.response(status)
  |> wisp.set_header("content-type", "application/json")
  |> wisp.string_body(json.to_string(body))
}
