#!/usr/bin/env bash
set -euo pipefail

TARGET=${1:-infrastructure/geth-monitoring/jwtsecret}
mkdir -p "$(dirname "$TARGET")" || sudo mkdir -p "$(dirname "$TARGET")"
if [ -f "$TARGET" ]; then
  # Validate size exactly 32 bytes; otherwise re-generate
  if [ "$(wc -c < "$TARGET" 2>/dev/null || echo 0)" = "32" ]; then
    echo "JWT secret already exists at $TARGET (32 bytes)"
    exit 0
  else
    echo "Existing JWT secret at $TARGET is invalid size; regenerating..."
    rm -f "$TARGET"
  fi
fi
# Generate 32 random bytes RAW (not hex). Both Geth and Lighthouse accept raw 32B file.
if command -v openssl >/dev/null 2>&1; then
  (openssl rand -out "$TARGET" 32) || (sudo openssl rand -out "$TARGET" 32)
else
  # Fallback using /dev/urandom
  (head -c 32 /dev/urandom > "$TARGET") || (sudo sh -c 'head -c 32 /dev/urandom > "$0"' "$TARGET")
fi
chmod 600 "$TARGET" 2>/dev/null || sudo chmod 600 "$TARGET"
echo "JWT secret generated at $TARGET"
