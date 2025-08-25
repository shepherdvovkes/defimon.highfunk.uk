#!/bin/bash

# DeFiMon Dashboard Startup Script
# Этот скрипт запускает backend и frontend серверы

echo "🚀 Запуск DeFiMon Dashboard..."

# Проверяем, что мы в корневой директории проекта
if [ ! -f "README.md" ]; then
    echo "❌ Ошибка: Запустите скрипт из корневой директории проекта"
    exit 1
fi

# Функция для остановки процессов
cleanup() {
    echo "🛑 Остановка серверов..."
    pkill -f "test_server.py"
    pkill -f "next dev"
    exit 0
}

# Обработка сигналов для корректного завершения
trap cleanup SIGINT SIGTERM

# Запуск backend сервера
echo "📡 Запуск backend сервера (порт 8002)..."
cd services/analytics-api
if [ ! -d "venv" ]; then
    echo "🔧 Создание виртуального окружения..."
    python3 -m venv venv
fi

source venv/bin/activate
pip install -q fastapi uvicorn requests python-dotenv

# Запуск backend в фоне
python test_server.py &
BACKEND_PID=$!

# Возвращаемся в корневую директорию
cd ../..

# Ждем запуска backend
echo "⏳ Ожидание запуска backend..."
sleep 3

# Проверяем, что backend запустился
if curl -s http://localhost:8002/health > /dev/null; then
    echo "✅ Backend сервер запущен успешно"
else
    echo "❌ Ошибка запуска backend сервера"
    exit 1
fi

# Запуск frontend сервера
echo "🌐 Запуск frontend сервера (порт 3000)..."
cd frontend

# Проверяем, установлены ли зависимости
if [ ! -d "node_modules" ]; then
    echo "📦 Установка зависимостей frontend..."
    npm install
fi

# Запуск frontend в фоне
npm run dev &
FRONTEND_PID=$!

# Возвращаемся в корневую директорию
cd ..

# Ждем запуска frontend
echo "⏳ Ожидание запуска frontend..."
sleep 5

# Проверяем, что frontend запустился
if curl -s http://localhost:3000 > /dev/null; then
    echo "✅ Frontend сервер запущен успешно"
else
    echo "❌ Ошибка запуска frontend сервера"
    exit 1
fi

echo ""
echo "🎉 DeFiMon Dashboard запущен успешно!"
echo ""
echo "📊 Доступные URL:"
echo "   Frontend: http://localhost:3000"
echo "   Backend API: http://localhost:8002"
echo "   API Docs: http://localhost:8002/docs"
echo "   Health Check: http://localhost:8002/health"
echo ""
echo "🔧 Полезные команды:"
echo "   Проверить API: curl http://localhost:8002/api/external-apis/summary"
echo "   Остановить серверы: Ctrl+C"
echo ""

# Ждем завершения процессов
wait $BACKEND_PID $FRONTEND_PID
