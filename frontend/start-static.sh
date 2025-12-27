#!/usr/bin/env sh

# Simple helper to serve the static site from frontend/public
PORT="${PORT:-8020}"
HOST="${HOST:-127.0.0.1}"

cd "$(dirname "$0")/public" || exit 1
echo "Serving frontend/public at http://${HOST}:${PORT} (Ctrl+C to stop)..."
python3 -m http.server "$PORT" --bind "$HOST"
