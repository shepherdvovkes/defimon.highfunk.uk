#!/bin/bash

set -euo pipefail

echo "🔄 Restarting DEFIMON Ethereum Node deployment..."

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

# Проверка root прав
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "This script must be run as root (sudo)."
  exit 1
fi

NODE_DIR="/opt/defimon"

print_header "Stopping existing services..."

# Остановка существующих сервисов
if [ -f "$NODE_DIR/manage-node.sh" ]; then
    "$NODE_DIR/manage-node.sh" stop || true
fi

# Остановка Docker контейнеров
docker compose -f "$NODE_DIR/docker-compose.node.yml" down || true

print_status "Cleaning up Docker images..."

# Очистка Docker образов
docker system prune -f || true

print_header "Rebuilding and starting services..."

# Переход в директорию ноды
cd "$NODE_DIR"

# Пересборка и запуск сервисов
if docker compose version >/dev/null 2>&1; then
    COMPOSE_BIN="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_BIN="docker-compose"
else
    print_error "Docker Compose is not installed"
    exit 1
fi

# Пересборка образов
print_status "Rebuilding Docker images..."
$COMPOSE_BIN -f docker-compose.node.yml build --no-cache

# Запуск сервисов
print_status "Starting services..."
$COMPOSE_BIN -f docker-compose.node.yml up -d

print_status "Waiting for services to start..."
sleep 30

print_header "Checking service status..."
$COMPOSE_BIN -f docker-compose.node.yml ps

print_header "Deployment restarted successfully!"
echo ""
echo "=== Service Status ==="
$COMPOSE_BIN -f docker-compose.node.yml ps

echo ""
echo "=== Access Information ==="
echo "Ethereum RPC: http://localhost:8545"
echo "Ethereum WS:  ws://localhost:8546"
echo "Grafana:      http://localhost:3001 (admin/admin)"
echo "Prometheus:   http://localhost:9090"
echo "Admin Dashboard: http://localhost:8080"

echo ""
echo "=== Management Commands ==="
echo "Check status: sudo $NODE_DIR/manage-node.sh status"
echo "View logs:    sudo $NODE_DIR/manage-node.sh logs"
echo "Monitor:      sudo $NODE_DIR/monitor-node.sh"

print_status "Restart completed successfully!"
