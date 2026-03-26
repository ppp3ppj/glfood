ARG GLEAM_VERSION=v1.15.2

# ---- Build stage ----
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang-alpine AS builder

# Install Node.js + Bun for the Vite client build
# gcc/g++/musl-dev/make/sqlite-dev are required to compile the esqlite NIF (used by sqlight)
RUN apk add --no-cache nodejs npm curl bash gcc g++ musl-dev make sqlite-dev
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:$PATH"

# Copy each project separately so dependency layers are cached independently
COPY ./shared /build/shared
COPY ./client /build/client
COPY ./server /build/server

# Download dependencies (shared first — server depends on it)
RUN cd /build/shared && gleam deps download
RUN cd /build/client && gleam deps download
RUN cd /build/server && gleam deps download

# Build client with Vite via Bun
RUN cd /build/client \
  && gleam build \
  && bun install \
  && bun run build

# Copy Vite output into server priv/static
RUN mkdir -p /build/server/priv/static \
  && cp -r /build/client/dist/* /build/server/priv/static/

# Export server as a self-contained Erlang shipment
RUN cd /build/server && gleam export erlang-shipment

# ---- Runtime stage ----
# Use the same Gleam image to guarantee Erlang version compatibility
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang-alpine

# sqlite-libs for the esqlite NIF; libgcc/libstdc++ for NIF linking
RUN apk add --no-cache libgcc libstdc++ sqlite-libs

WORKDIR /app
COPY --from=builder /build/server/build/erlang-shipment .

ENV HOST=0.0.0.0
ENV PORT=4000
EXPOSE 4000

CMD ["./entrypoint.sh", "run"]
