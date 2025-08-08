#!/bin/bash

set -e

echo "Starting Ethereum Node..."

# Проверка переменных окружения
ETHEREUM_NODE_URL=${ETHEREUM_NODE_URL:-"http://localhost:8545"}
SYNC_MODE=${SYNC_MODE:-"full"}
CACHE_SIZE=${CACHE_SIZE:-"4096"}
MAX_PEERS=${MAX_PEERS:-"50"}
RPC_PORT=${RPC_PORT:-"8545"}
WS_PORT=${WS_PORT:-"8546"}
P2P_PORT=${P2P_PORT:-"30303"}

# Создание директории для данных
mkdir -p /data/ethereum

# Запуск Geth в фоновом режиме
echo "Starting Geth with configuration:"
echo "  Sync Mode: $SYNC_MODE"
echo "  Cache Size: $CACHE_SIZE MB"
echo "  Max Peers: $MAX_PEERS"
echo "  RPC Port: $RPC_PORT"
echo "  WS Port: $WS_PORT"
echo "  P2P Port: $P2P_PORT"

geth \
    --datadir /data/ethereum \
    --syncmode $SYNC_MODE \
    --cache $CACHE_SIZE \
    --maxpeers $MAX_PEERS \
    --http \
    --http.addr 0.0.0.0 \
    --http.port $RPC_PORT \
    --http.corsdomain "*" \
    --http.api "eth,net,web3,debug,txpool" \
    --ws \
    --ws.addr 0.0.0.0 \
    --ws.port $WS_PORT \
    --ws.api "eth,net,web3" \
    --port $P2P_PORT \
    --allow-insecure-unlock \
    --unlock 0 \
    --password /dev/null \
    --mine \
    --miner.threads 1 \
    --miner.etherbase 0 \
    --verbosity 3 \
    --metrics \
    --metrics.addr 0.0.0.0 \
    --metrics.port 6060 \
    --pprof \
    --pprof.addr 0.0.0.0 \
    --pprof.port 6061 &

GETH_PID=$!

echo "Geth started with PID: $GETH_PID"

# Ожидание запуска Geth
echo "Waiting for Geth to start..."
sleep 30

# Проверка статуса Geth
if ! curl -f http://localhost:$RPC_PORT > /dev/null 2>&1; then
    echo "Error: Geth is not responding on port $RPC_PORT"
    exit 1
fi

echo "Geth is running successfully"

# Запуск Rust приложения
echo "Starting Rust blockchain node service..."
./target/release/blockchain-node &

RUST_PID=$!

echo "Rust service started with PID: $RUST_PID"

# Функция для graceful shutdown
cleanup() {
    echo "Shutting down services..."
    kill $GETH_PID
    kill $RUST_PID
    wait
    echo "Services stopped"
    exit 0
}

# Обработка сигналов для graceful shutdown
trap cleanup SIGTERM SIGINT

# Ожидание завершения процессов
wait
