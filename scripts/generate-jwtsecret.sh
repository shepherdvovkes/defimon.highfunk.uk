#!/usr/bin/env bash
set -euo pipefail

TARGET=${1:-infrastructure/geth-monitoring/jwtsecret}
mkdir -p "$(dirname "$TARGET")"
if [ -f "$TARGET" ]; then
  echo "JWT secret already exists at $TARGET"
  exit 0
fi
# Generate 32 random bytes RAW (not hex). Both Geth and Lighthouse accept raw 32B file.
if command -v openssl >/dev/null 2>&1; then
  openssl rand -out "$TARGET" 32
else
  # Fallback using /dev/urandom
  head -c 32 /dev/urandom > "$TARGET"
fi
chmod 600 "$TARGET"
echo "JWT secret generated at $TARGET"
