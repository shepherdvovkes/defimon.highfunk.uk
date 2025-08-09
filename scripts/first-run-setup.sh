#!/usr/bin/env bash
set -euo pipefail

# One-shot setup for full Geth + Lighthouse + monitoring on Linux Mint
# Idempotent and safe to re-run

log() { echo -e "\033[0;32m$*\033[0m"; }
warn() { echo -e "\033[0;33m$*\033[0m"; }
err() { echo -e "\033[0;31m$*\033[0m" 1>&2; }

REPO_DIR=${REPO_DIR:-$(pwd)}
COMPOSE_FILE="$REPO_DIR/infrastructure/geth-monitoring/docker-compose.yml"
JWT_BASE="$REPO_DIR/infrastructure/geth-monitoring/jwtsecret"

log "Installing base deps (jq, curl, tmux)"
sudo apt-get update -y
sudo apt-get install -y jq curl tmux || true

log "Enabling NTP (if available)"
if command -v timedatectl >/dev/null 2>&1; then sudo timedatectl set-ntp true || true; fi

log "Tuning sysctl for node performance"
sudo bash -c 'cat > /etc/sysctl.d/99-defimon.conf' << 'EOF'
vm.max_map_count=262144
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.core.rmem_default=67108864
net.core.wmem_default=67108864
EOF
sudo sysctl --system || true

log "Selecting Docker Compose binary"
if docker compose version >/dev/null 2>&1; then
  COMPOSE_BIN="docker compose"
else
  COMPOSE_BIN="docker-compose"
fi

log "Generating JWT secrets (RAW + HEX)"
chmod +x "$REPO_DIR/scripts/generate-jwtsecret.sh"
"$REPO_DIR/scripts/generate-jwtsecret.sh" "$JWT_BASE"
RAW_PATH="$JWT_BASE.raw"
HEX_PATH="$JWT_BASE.hex"
[ "$(wc -c < "$RAW_PATH")" -eq 32 ] || { err "JWT RAW must be 32 bytes"; exit 1; }
log "RAW: $RAW_PATH (32B) | HEX: $HEX_PATH (64 chars)"

log "Cleaning previous stack (containers/volumes)"
$COMPOSE_BIN -f "$COMPOSE_FILE" down --remove-orphans || true

docker rm -f geth-full-node lighthouse-beacon prometheus-monitor grafana-dashboard 2>/dev/null || true

log "Exporting env and starting stack (internal geth)"
export JWTSECRET_RAW_PATH="$RAW_PATH"
export JWTSECRET_HEX_PATH="$HEX_PATH"
# Default checkpoint sync URL for Lighthouse (can be overridden by env)
export CHECKPOINT_SYNC_URL="${CHECKPOINT_SYNC_URL:-https://mainnet.checkpoint.sigp.io}"
log "Using CHECKPOINT_SYNC_URL=$CHECKPOINT_SYNC_URL"
$COMPOSE_BIN -f "$COMPOSE_FILE" --profile internal-geth up -d --build

log "Waiting for containers to initialize..."
sleep 8
$COMPOSE_BIN -f "$COMPOSE_FILE" ps || true

log "Verifying JWT inside containers"
if docker ps --format '{{.Names}}' | grep -qx geth-full-node; then
  docker exec geth-full-node wc -c /jwtsecret || true
fi
if docker ps --format '{{.Names}}' | grep -qx lighthouse-beacon; then
  docker exec lighthouse-beacon wc -c /jwtsecret || true
fi

log "If both lines above show 32, JWT secrets are correctly mounted."

warn "To view Geth logs (no tmux): ./scripts/geth-cli-monitor.sh"
warn "Prometheus: http://localhost:9091 | Grafana: http://localhost:3000 (admin/admin)"
