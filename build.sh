#!/bin/bash
set -e

echo ">>> Building client..."
cd client
gleam deps download
gleam build
bun install
bun run build        # Vite → client/dist/
cd ..

echo ">>> Copying client build to server/priv/static..."
mkdir -p server/priv/static
rm -rf server/priv/static/*
cp -r client/dist/* server/priv/static/

echo ">>> Building server (erlang-shipment)..."
cd server
gleam deps download
gleam export erlang-shipment
cd ..

echo ""
echo "Done! Run with:"
echo "  ./server/build/erlang-shipment/entrypoint.sh run"
