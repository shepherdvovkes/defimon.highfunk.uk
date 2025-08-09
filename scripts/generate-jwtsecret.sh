#!/usr/bin/env bash
set -euo pipefail

TARGET=${1:-infrastructure/geth-monitoring/jwtsecret}
mkdir -p "$(dirname "$TARGET")"
if [ -f "$TARGET" ]; then
  echo "JWT secret already exists at $TARGET"
  exit 0
fi
# 32 random bytes hex-encoded (Geth/Lighthouse accept raw 32 bytes; here we write raw)
openssl rand -out "$TARGET" 32
chmod 600 "$TARGET"
echo "JWT secret generated at $TARGET"
