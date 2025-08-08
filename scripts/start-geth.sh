#!/bin/bash

set -euo pipefail

echo "🚀 Starting Geth Ethereum Full Node..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[HEADER]${NC} $1"
}

# Проверка переменных окружения
DATA_DIR="${DATA_DIR:-/data/ethereum}"
CONFIG_FILE="${CONFIG_FILE:-/app/config/geth-config.toml}"
LOG_FILE="${LOG_FILE:-/data/ethereum/geth.log}"

print_header "Ethereum Full Node Configuration"

# Проверка директории данных
if [ ! -d "$DATA_DIR" ]; then
    print_status "Creating data directory: $DATA_DIR"
    mkdir -p "$DATA_DIR"
fi

# Проверка конфигурационного файла
if [ ! -f "$CONFIG_FILE" ]; then
    print_error "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

print_status "Data directory: $DATA_DIR"
print_status "Config file: $CONFIG_FILE"
print_status "Log file: $LOG_FILE"

# Проверка системных ресурсов
print_header "Checking system resources..."

# Проверка свободного места
FREE_SPACE_KB=$(df -kP "$DATA_DIR" | awk 'NR==2 {print $4}')
FREE_SPACE_GB=$((FREE_SPACE_KB / 1024 / 1024))
if [ "$FREE_SPACE_GB" -lt 100 ]; then
    print_warning "Low disk space: ${FREE_SPACE_GB}GB available. Recommended: 1TB+ for full node"
fi

# Проверка RAM
TOTAL_RAM_GB=$(free -g | awk 'NR==2{print $2}')
if [ "${TOTAL_RAM_GB:-0}" -lt 8 ]; then
    print_warning "Low RAM: ${TOTAL_RAM_GB}GB available. Recommended: 16GB+ for full node"
fi

print_status "System resources check completed"

# Оптимизированные параметры запуска Geth
print_header "Starting Geth with optimized parameters..."

# Основные параметры для полной ноды
GETH_PARAMS=(
    "--config" "$CONFIG_FILE"
    "--datadir" "$DATA_DIR"
    "--syncmode" "full"
    "--cache" "8192"
    "--database.cache" "4096"
    "--trie.cache" "256"
    "--snapshot.cache" "256"
    "--state.cache" "256"
    "--maxpeers" "50"
    "--http"
    "--http.addr" "0.0.0.0"
    "--http.port" "8545"
    "--http.corsdomain" "*"
    "--http.vhosts" "*"
    "--http.api" "eth,net,web3,debug,txpool"
    "--ws"
    "--ws.addr" "0.0.0.0"
    "--ws.port" "8546"
    "--ws.origins" "*"
    "--ws.api" "eth,net,web3,debug,txpool"
    "--metrics"
    "--metrics.addr" "0.0.0.0"
    "--metrics.port" "6060"
    "--metrics.influxdb"
    "--metrics.influxdb.endpoint" "http://localhost:8086"
    "--metrics.influxdb.database" "ethereum"
    "--metrics.influxdb.username" "admin"
    "--metrics.influxdb.password" "admin"
    "--verbosity" "3"
    "--log.json"
    "--log.file" "$LOG_FILE"
    "--log.maxsize" "100"
    "--log.maxbackups" "10"
    "--log.maxage" "30"
    "--log.compress"
)

# Дополнительные параметры для производительности
if [ "${TOTAL_RAM_GB:-0}" -ge 16 ]; then
    print_status "High RAM detected, enabling additional optimizations..."
    GETH_PARAMS+=(
        "--cache" "16384"
        "--database.cache" "8192"
        "--trie.cache" "512"
        "--snapshot.cache" "512"
        "--state.cache" "512"
    )
fi

# Параметры для SSD
if command -v lsblk >/dev/null 2>&1; then
    DISK_TYPE=$(lsblk -d -n -o TYPE "$(df "$DATA_DIR" | awk 'NR==2 {print $1}' | sed 's/[0-9]*$//')" 2>/dev/null || echo "unknown")
    if [[ "$DISK_TYPE" == *"ssd"* ]] || [[ "$DISK_TYPE" == *"nvme"* ]]; then
        print_status "SSD detected, enabling SSD optimizations..."
        GETH_PARAMS+=(
            "--database.ancient" "$DATA_DIR/chaindata/ancient"
            "--cache" "12288"
        )
    fi
fi

# Параметры для сети
GETH_PARAMS+=(
    "--nat" "any"
    "--discovery.v5"
    "--light.serve" "0"
    "--light.maxpeers" "0"
    "--light.nopruning"
)

print_status "Starting Geth with parameters:"
echo "${GETH_PARAMS[@]}"

# Запуск Geth
exec geth "${GETH_PARAMS[@]}"
