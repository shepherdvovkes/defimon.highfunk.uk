#!/bin/bash

set -e

echo "🚀 Quick Deploy for DeFi Analytics Platform"

# Определение архитектуры
ARCH=$(uname -m)
echo "📋 Detected architecture: $ARCH"

# Настройка переменных окружения
case $ARCH in
    "x86_64"|"amd64")
        export DOCKER_DEFAULT_PLATFORM=linux/amd64
        export RUST_TARGET=x86_64-unknown-linux-gnu
        ;;
    "aarch64"|"arm64")
        export DOCKER_DEFAULT_PLATFORM=linux/arm64
        export RUST_TARGET=aarch64-unknown-linux-gnu
        ;;
    *)
        echo "❌ Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "🔧 Using platform: $DOCKER_DEFAULT_PLATFORM"
echo "🔧 Using Rust target: $RUST_TARGET"

# Проверка системных параметров
echo "🔍 Checking system parameters..."
CURRENT_MAX_MAP_COUNT=$(sysctl -n vm.max_map_count 2>/dev/null || echo "0")
if [ "$CURRENT_MAX_MAP_COUNT" -lt 262144 ]; then
    echo "⚠️  Warning: vm.max_map_count is too low ($CURRENT_MAX_MAP_COUNT)"
    echo "💡 Run: sudo ./scripts/setup-system.sh to fix this"
    echo "   Or manually: sudo sysctl -w vm.max_map_count=262144"
fi

# Остановка существующих контейнеров
echo "🛑 Stopping existing containers..."
docker-compose -f infrastructure/docker-compose.yml down --remove-orphans || true

# Очистка
echo "🧹 Cleaning up..."
docker system prune -f

# Сборка и запуск
echo "🔨 Building and starting services..."
docker-compose -f infrastructure/docker-compose.yml up -d --build

echo "✅ Quick deploy completed!"
echo ""
echo "📱 Services:"
echo "   Frontend: http://localhost:3000"
echo "   API Gateway: http://localhost:8000"
echo "   Admin Dashboard: http://localhost:8080"
echo "   Blockchain Node: http://localhost:8545"
echo ""
echo "📊 Monitoring:"
echo "   Grafana: http://localhost:3001 (admin/admin)"
echo "   Prometheus: http://localhost:9090"
echo ""
echo "To view logs: docker-compose -f infrastructure/docker-compose.yml logs -f"
echo "To stop: docker-compose -f infrastructure/docker-compose.yml down"
