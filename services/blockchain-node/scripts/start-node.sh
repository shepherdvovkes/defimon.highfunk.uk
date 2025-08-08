#!/bin/bash

set -euo pipefail

echo "Starting Ethereum Node..."

# Переменные окружения
ETHEREUM_NODE_URL=${ETHEREUM_NODE_URL:-"http://localhost:8545"}
SYNC_MODE=${SYNC_MODE:-"full"}
CACHE_SIZE=${CACHE_SIZE:-"4096"}
MAX_PEERS=${MAX_PEERS:-"50"}
RPC_PORT=${RPC_PORT:-"8545"}
WS_PORT=${WS_PORT:-"8546"}
P2P_PORT=${P2P_PORT:-"30303"}
NAT_EXTIP=${NAT_EXTIP:-""}

# Директория данных
mkdir -p /data/ethereum

echo "Starting Geth with configuration:"
echo "  Sync Mode: $SYNC_MODE"
echo "  Cache Size: $CACHE_SIZE MB"
echo "  Max Peers: $MAX_PEERS"
echo "  RPC Port: $RPC_PORT"
echo "  WS Port: $WS_PORT"
echo "  P2P Port: $P2P_PORT"
if [ -n "$NAT_EXTIP" ]; then
  echo "  NAT extip: $NAT_EXTIP"
fi

NAT_ARGS=()
if [ -n "$NAT_EXTIP" ]; then
  NAT_ARGS=(--nat extip:$NAT_EXTIP)
fi

geth \
  --datadir /data/ethereum \
  --syncmode "$SYNC_MODE" \
  --cache "$CACHE_SIZE" \
  --maxpeers "$MAX_PEERS" \
  --http \
  --http.addr 0.0.0.0 \
  --http.port "$RPC_PORT" \
  --http.corsdomain "*" \
  --http.api "eth,net,web3,debug,txpool" \
  --ws \
  --ws.addr 0.0.0.0 \
  --ws.port "$WS_PORT" \
  --ws.api "eth,net,web3" \
  --port "$P2P_PORT" \
  --verbosity 3 \
  --metrics \
  --metrics.addr 0.0.0.0 \
  --metrics.port 6060 \
  --pprof \
  --pprof.addr 0.0.0.0 \
  --pprof.port 6061 \
  "${NAT_ARGS[@]}" &

GETH_PID=$!
echo "Geth started with PID: $GETH_PID"

echo "Waiting for Geth to start..."
sleep 30

if ! curl -fsS "http://localhost:$RPC_PORT" >/dev/null 2>&1; then
  echo "Error: Geth is not responding on port $RPC_PORT"
  exit 1
fi
echo "Geth is running successfully"

echo "Starting Rust blockchain node service..."
./target/release/blockchain-node &
RUST_PID=$!
echo "Rust service started with PID: $RUST_PID"

cleanup() {
  echo "Shutting down services..."
  kill "$GETH_PID" || true
  kill "$RUST_PID" || true
  wait || true
  echo "Services stopped"
  exit 0
}

trap cleanup SIGTERM SIGINT

wait
