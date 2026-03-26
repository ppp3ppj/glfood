# Role-Based Access Control (RBAC)

Inspired by Elixir's [Bodyguard](https://github.com/schrockwell/bodyguard) library. There is no existing Gleam RBAC library, so this is built from scratch using the same policy pattern.

---

## Roles

| Role    | Value in DB | Description              |
|---------|-------------|--------------------------|
| `User`  | `"user"`    | Default for all new accounts |
| `Admin` | `"admin"`   | Full access               |

New users always get `"user"`. To promote a user to admin, update the database directly:

```sql
UPDATE users SET role = 'admin' WHERE username = 'alice';
```

---

## Core Modules

### `authorization/policy.gleam`

Defines all the shared types:

```gleam
pub type Role    { Admin | User }
pub type Action  { Create | Read | Update | Delete | Manage }
pub type AuthUser { AuthUser(id: Int, username: String, role: Role) }
pub type Policy  = fn(AuthUser, Action) -> Bool
```

`Manage` is a wildcard — if a policy returns `True` for `Manage`, all actions are allowed.

---

### `authorization/middleware.gleam`

Resolves the `Authorization: Bearer <token>` header into an `AuthUser`.

| Function | Description |
|---|---|
| `require_auth(req, conn, next)` | 401 if no valid token, otherwise calls `next(actor)` |
| `require_role(req, conn, role, next)` | 401 if not authenticated, 403 if wrong role |
| `get_current_user(req, conn)` | Returns `Result(AuthUser, String)` without short-circuiting |

---

## Usage

### Pattern A — Require any logged-in user

```gleam
import authorization/middleware

pub fn profile(req: Request, conn: sqlight.Connection) -> Response {
  use actor <- middleware.require_auth(req, conn)
  // actor: AuthUser — id, username, role are available
  json_response(200, json.object([
    #("username", json.string(actor.username)),
  ]))
}
```

### Pattern B — Require a specific role

```gleam
import authorization/middleware
import authorization/policy

pub fn dashboard(req: Request, conn: sqlight.Connection) -> Response {
  use actor <- middleware.require_role(req, conn, policy.Admin)
  // only Admin reaches here — others get 403
  json_response(200, json.object([#("admin", json.string(actor.username))]))
}
```

### Pattern C — Resource-level policy (Bodyguard pattern)

Define a policy function close to the resource, then call `policy.permit`:

```gleam
import authorization/middleware
import authorization/policy

pub type Post {
  Post(id: Int, author_id: Int, published: Bool)
}

fn post_policy(post: Post) -> policy.Policy {
  fn(actor: policy.AuthUser, action: policy.Action) -> Bool {
    case action {
      policy.Read   -> post.published || actor.id == post.author_id
      policy.Create -> True
      policy.Update | policy.Delete -> actor.role == policy.Admin || actor.id == post.author_id
      policy.Manage -> actor.role == policy.Admin
    }
  }
}

pub fn update_post(req: Request, conn: sqlight.Connection, post_id: Int) -> Response {
  use actor <- middleware.require_auth(req, conn)
  // fetch post from DB here...
  let post = Post(id: post_id, author_id: 42, published: True)
  use <- policy.permit(actor, policy.Update, post_policy(post))
  // only reaches here if policy allows it — otherwise 403
  json_response(200, json.object([#("ok", json.bool(True))]))
}
```

### Pattern D — Optional auth (guest vs logged-in)

```gleam
import authorization/middleware

pub fn feed(req: Request, conn: sqlight.Connection) -> Response {
  let current = middleware.get_current_user(req, conn)
  case current {
    Ok(actor) -> render_personalized_feed(actor)
    Error(_)  -> render_public_feed()
  }
}
```

---

## Adding a Route

### Server — `server/src/router.gleam`

```gleam
http.Get, ["api", "admin", "something"] -> admin.something(req, conn)
```

### Client — `client/src/router.gleam`

Add the variant to `Route`, `parse`, and `to_path`:

```gleam
pub type Route { ..., MyPage }

pub fn parse(uri: Uri) -> Route {
  case uri.path {
    "/my-page" -> MyPage
    ...
  }
}

pub fn to_path(route: Route) -> String {
  case route {
    MyPage -> "/my-page"
    ...
  }
}
```

Then guard it in `glfood.gleam`'s `update` if needed:

```gleam
RouteChanged(router.MyPage) ->
  case model.role {
    option.Some(shared.Admin) -> #(Model(..model, route: router.MyPage), effect.none())
    _ -> #(model, router.push(router.Login))
  }
```

---

## Adding a New Role

1. Add the variant to `authorization/policy.gleam`:
   ```gleam
   pub type Role { Admin | Moderator | User }
   ```

2. Update `role_from_string` / `role_to_string`:
   ```gleam
   pub fn role_from_string(s: String) -> Result(Role, Nil) {
     case s {
       "admin"     -> Ok(Admin)
       "moderator" -> Ok(Moderator)
       "user"      -> Ok(User)
       _           -> Error(Nil)
     }
   }
   ```

3. Update `shared/types.gleam` the same way (for the client).

4. Update `require_role` in middleware if you need hierarchy (e.g. Admin can access Moderator routes):
   ```gleam
   fn role_gte(actual: Role, required: Role) -> Bool {
     case required {
       User      -> True
       Moderator -> actual == Moderator || actual == Admin
       Admin     -> actual == Admin
     }
   }
   ```

---

## HTTP Responses

| Situation | Status |
|---|---|
| No / invalid `Authorization` header | `401 Unauthorized` |
| Valid token but insufficient role | `403 Forbidden` |
| Policy function returns `False` | `403 Forbidden` |
| Authorized | handler runs normally |

---

## Files Reference

| File | Purpose |
|---|---|
| `server/src/authorization/policy.gleam` | Core types: `Role`, `AuthUser`, `Action`, `Policy`, `permit` |
| `server/src/authorization/middleware.gleam` | `require_auth`, `require_role`, `get_current_user` |
| `server/src/controllers/admin.gleam` | Example admin controller |
| `server/priv/migrations/003_user_roles.sql` | Adds `role` column to `users` table |
| `shared/src/shared/types.gleam` | `Role` type shared with the client |
| `client/src/pages/admin.gleam` | Admin dashboard page (client) |
