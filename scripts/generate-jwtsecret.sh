#!/usr/bin/env bash
set -euo pipefail

TARGET_BASE=${1:-infrastructure/geth-monitoring/jwtsecret}
DIR_PATH="$(dirname "$TARGET_BASE")"
RAW_PATH="$TARGET_BASE.raw"
HEX_PATH="$TARGET_BASE.hex"

mkdir -p "$DIR_PATH" || sudo mkdir -p "$DIR_PATH"

# RAW secret: exactly 32 bytes
need_gen=1
if [ -f "$RAW_PATH" ]; then
  size=$(wc -c < "$RAW_PATH" 2>/dev/null || echo 0)
  if [ "$size" = "32" ]; then need_gen=0; fi
fi
if [ "$need_gen" = "1" ]; then
  if command -v openssl >/dev/null 2>&1; then
    (openssl rand -out "$RAW_PATH" 32) || (sudo openssl rand -out "$RAW_PATH" 32)
  else
    (head -c 32 /dev/urandom > "$RAW_PATH") || (sudo sh -c 'head -c 32 /dev/urandom > "$0"' "$RAW_PATH")
  fi
fi

# HEX secret: 64 ascii chars, for clients that require hex
if command -v xxd >/dev/null 2>&1; then
  (xxd -p -c 256 "$RAW_PATH" | tr -d '\n' > "$HEX_PATH") || (sudo sh -c 'xxd -p -c 256 "$0" | tr -d '\''\n'\'' > "$1"' "$RAW_PATH" "$HEX_PATH")
else
  (hexdump -v -e '1/1 "%02x"' "$RAW_PATH" > "$HEX_PATH") || (sudo sh -c 'hexdump -v -e '"'1/1 "%02x"'"' "$0" > "$1"' "$RAW_PATH" "$HEX_PATH")
fi

chmod 600 "$RAW_PATH" 2>/dev/null || sudo chmod 600 "$RAW_PATH"
chmod 600 "$HEX_PATH" 2>/dev/null || sudo chmod 600 "$HEX_PATH"
echo "JWT secrets ready: RAW=$RAW_PATH (32 bytes), HEX=$HEX_PATH (64 chars)"
