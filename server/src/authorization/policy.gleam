// authorization/policy.gleam
//
// Bodyguard-inspired RBAC core.
//
// Usage in a controller:
//
//   import authorization/policy.{type AuthUser}
//
//   pub fn update(req: Request, conn: Connection, actor: AuthUser) -> Response {
//     use <- policy.permit(actor, policy.Update, my_resource_policy)
//     // ... authorized handler body
//   }

import gleam/json
import wisp

// ---------------------------------------------------------------------------
// Public types
// ---------------------------------------------------------------------------

/// The role assigned to a user. Stored in the DB as TEXT: 'admin' | 'user'.
pub type Role {
  Admin
  User
}

/// The authenticated user passed into every protected handler.
/// This is NOT the DB User — it deliberately has no password field.
/// Constructed by middleware after verifying the session token.
pub type AuthUser {
  AuthUser(id: Int, username: String, role: Role)
}

/// Standard CRUD actions plus Manage (wildcard — grants all actions).
/// Extend as needed: e.g. Publish | Archive
pub type Action {
  Create
  Read
  Update
  Delete
  Manage
}

/// A Policy is a pure function: given an actor and action, can they proceed?
/// Capture resource-specific data in a closure when constructing the fn.
///
/// Example:
///   fn post_policy(post: Post) -> policy.Policy {
///     fn(actor: AuthUser, action: Action) -> Bool {
///       case action {
///         Read   -> post.published || actor.id == post.author_id
///         Manage -> actor.role == Admin
///         _      -> actor.role == Admin || actor.id == post.author_id
///       }
///     }
///   }
pub type Policy =
  fn(AuthUser, Action) -> Bool

// ---------------------------------------------------------------------------
// Core permit function
// ---------------------------------------------------------------------------

/// The central authorization gate. Call at the top of any handler that
/// requires authorization. Returns 403 if denied, otherwise calls `next`.
///
///   use <- policy.permit(actor, policy.Update, my_resource_policy)
///   // ... authorized code here
///
/// Manage is a wildcard: if the policy returns True for Manage, all
/// actions are allowed — useful for admin override.
pub fn permit(
  actor: AuthUser,
  action: Action,
  resource_policy: Policy,
  next: fn() -> wisp.Response,
) -> wisp.Response {
  case resource_policy(actor, action) || resource_policy(actor, Manage) {
    True -> next()
    False -> forbidden()
  }
}

// ---------------------------------------------------------------------------
// Role helpers
// ---------------------------------------------------------------------------

/// Decode a role string from the database.
pub fn role_from_string(s: String) -> Result(Role, Nil) {
  case s {
    "admin" -> Ok(Admin)
    "user" -> Ok(User)
    _ -> Error(Nil)
  }
}

/// Encode a role to the string stored in the database / JSON.
pub fn role_to_string(role: Role) -> String {
  case role {
    Admin -> "admin"
    User -> "user"
  }
}

/// Encode a role to JSON (for API responses sent to the client).
pub fn encode_role(role: Role) -> json.Json {
  json.string(role_to_string(role))
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

fn forbidden() -> wisp.Response {
  wisp.response(403)
  |> wisp.set_header("content-type", "application/json")
  |> wisp.string_body("{\"error\":\"forbidden\"}")
}
