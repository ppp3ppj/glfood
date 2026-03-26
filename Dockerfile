# ---- Build stage ----
FROM ghcr.io/gleam-lang/gleam:v1.12.0-erlang-alpine AS builder

# Install Node.js + Bun for the Vite client build
RUN apk add --no-cache nodejs npm curl bash
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:$PATH"

WORKDIR /build
COPY . .

# Build client
WORKDIR /build/client
RUN gleam deps download
RUN gleam build
RUN bun install
RUN bun run build

# Copy Vite output into server priv/static
RUN mkdir -p /build/server/priv/static
RUN cp -r /build/client/dist/* /build/server/priv/static/

# Export server as a self-contained Erlang release
WORKDIR /build/server
RUN gleam deps download
RUN gleam export erlang-shipment

# ---- Runtime stage ----
FROM alpine:3.19

RUN apk add --no-cache libgcc libstdc++ ncurses-libs

WORKDIR /app
COPY --from=builder /build/server/build/erlang-shipment .

ENV HOST=0.0.0.0
ENV PORT=4000
EXPOSE 4000

ENTRYPOINT ["./entrypoint.sh", "run"]
