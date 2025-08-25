#!/bin/bash

# DEFIMON Admin Dashboard Startup Script

set -e

echo "🚀 Запуск DEFIMON Admin Dashboard..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker не запущен. Пожалуйста, запустите Docker и попробуйте снова."
    exit 1
fi

# Navigate to infrastructure directory
cd "$(dirname "$0")/../infrastructure"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Файл docker-compose.yml не найден в директории infrastructure/"
    exit 1
fi

# Build and start admin dashboard
echo "📦 Сборка и запуск admin-dashboard..."
docker-compose up --build admin-dashboard -d

# Wait for the service to be ready
echo "⏳ Ожидание запуска admin-dashboard..."
sleep 10

# Check if the service is running
if docker-compose ps admin-dashboard | grep -q "Up"; then
    echo "✅ Admin Dashboard успешно запущен!"
    echo ""
    echo "🌐 Доступные URL:"
    echo "   - Локально: http://localhost:8080"
    echo "   - Через API Gateway: http://localhost:8000/admin"
    echo ""
    echo "📊 Мониторинг сервисов:"
    echo "   - Analytics API: http://localhost:8002/health"
    echo "   - AI/ML Service: http://localhost:8001/health"
    echo "   - Prometheus: http://localhost:9090"
    echo "   - Grafana: http://localhost:3001"
    echo ""
    echo "🔧 Управление:"
    echo "   - Остановить: docker-compose stop admin-dashboard"
    echo "   - Логи: docker-compose logs -f admin-dashboard"
    echo "   - Перезапустить: docker-compose restart admin-dashboard"
else
    echo "❌ Ошибка запуска admin-dashboard"
    echo "Проверьте логи: docker-compose logs admin-dashboard"
    exit 1
fi
