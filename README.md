# glfood

Full-stack web application built with Gleam.

**Stack**
- **Client** — [Lustre](https://lustre.build) SPA · [DaisyUI](https://daisyui.com) · [Tailwind CSS v4](https://tailwindcss.com) · Vite
- **Server** — [Wisp](https://hexdocs.pm/wisp) · [Mist](https://hexdocs.pm/mist) · SQLite via [sqlight](https://hexdocs.pm/sqlight)
- **Shared** — Types and encoders/decoders shared between client and server

---

## Project structure

```
glfood/
├── client/          # Lustre SPA (compiles to JavaScript)
├── server/          # Wisp HTTP server (compiles to Erlang)
│   └── priv/
│       ├── migrations/   # SQL migration files
│       └── static/       # Built client assets (generated)
├── shared/          # Shared Gleam types
├── build.sh         # Production build script
└── Dockerfile
```

---

## Development

### Requirements

- [Gleam](https://gleam.run/getting-started/installing/) >= 1.14
- [Erlang/OTP](https://www.erlang.org/downloads) >= 26
- [Bun](https://bun.sh) (for the client Vite build)

### Run the server

```bash
cd server
gleam deps download
gleam run
# Listening on http://localhost:4000
```

Configure via environment variables:

```bash
HOST=0.0.0.0 PORT=8080 gleam run
```

### Run the client (dev, with hot reload)

```bash
cd client
gleam deps download
bun install
bun run dev
# Opens http://localhost:3000
```

Editing any `.gleam` file triggers an automatic `gleam build` + browser reload.

---

## API

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| POST | `/api/auth/register` | Register `{ email, password }` |
| POST | `/api/auth/login` | Login → `{ token }` |
| DELETE | `/api/auth/logout` | Logout (Bearer token) |
| GET | `/api/auth/me` | Verify token (Bearer token) |

---

## Production build

```bash
chmod +x build.sh
./build.sh
```

This will:
1. Build the client with Vite → `client/dist/`
2. Copy the output to `server/priv/static/`
3. Export the server as a self-contained Erlang shipment → `server/build/erlang-shipment/`

Run the production build:

```bash
./server/build/erlang-shipment/entrypoint.sh run
```

---

## Docker

### Build the image

```bash
docker build -t glfood .
```

### Build the image without caching (larger but ensures all steps are fresh)
```bash
docker build --no-cache -t glfood .
```

### Run the container

```bash
docker run -p 4000:4000 glfood
```

Open [http://localhost:4000](http://localhost:4000).

### Custom port

```bash
docker run -p 8080:8080 -e PORT=8080 glfood
```

### Persist the database

The SQLite database (`app.db`) is created in the container's working directory. Mount a volume to keep it across restarts:

```bash
docker run -p 4000:4000 -v $(pwd)/data:/app/data -e DB_PATH=/app/data/app.db glfood
```

### Docker Compose (optional)

```yaml
services:
  glfood:
    build: .
    ports:
      - "4000:4000"
    environment:
      HOST: 0.0.0.0
      PORT: 4000
    volumes:
      - ./data:/app/data
    restart: unless-stopped
```

```bash
docker compose up -d
```

---

## Adding a migration

Create a new numbered SQL file in `server/priv/migrations/`:

```bash
# e.g. 003_products.sql
```

The server runs all pending migrations automatically on startup.
