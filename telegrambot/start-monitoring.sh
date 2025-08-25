#!/bin/bash

# Google Cloud Infrastructure Monitor Bot - Quick Start Script
# Этот скрипт помогает быстро запустить систему мониторинга

set -e

echo "🚀 Google Cloud Infrastructure Monitor Bot - Quick Start"
echo "========================================================"

# Проверка наличия Docker и Docker Compose
if ! command -v docker &> /dev/null; then
    echo "❌ Docker не установлен. Пожалуйста, установите Docker."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose не установлен. Пожалуйста, установите Docker Compose."
    exit 1
fi

# Проверка наличия .env файла
if [ ! -f .env ]; then
    echo "⚠️  Файл .env не найден. Создаю из примера..."
    if [ -f env.example ]; then
        cp env.example .env
        echo "✅ Файл .env создан из env.example"
        echo "⚠️  Пожалуйста, отредактируйте .env файл и заполните необходимые переменные:"
        echo "   - TELEGRAM_BOT_TOKEN"
        echo "   - GOOGLE_CLOUD_PROJECT_ID"
        echo "   - TELEGRAM_CHAT_ID"
        echo ""
        echo "После настройки запустите скрипт снова."
        exit 1
    else
        echo "❌ Файл env.example не найден. Пожалуйста, создайте .env файл вручную."
        exit 1
    fi
fi

# Проверка обязательных переменных
source .env

if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ "$TELEGRAM_BOT_TOKEN" = "your_telegram_bot_token_here" ]; then
    echo "❌ TELEGRAM_BOT_TOKEN не настроен в .env файле"
    exit 1
fi

if [ -z "$GOOGLE_CLOUD_PROJECT_ID" ] || [ "$GOOGLE_CLOUD_PROJECT_ID" = "your_gcp_project_id_here" ]; then
    echo "❌ GOOGLE_CLOUD_PROJECT_ID не настроен в .env файле"
    exit 1
fi

if [ -z "$TELEGRAM_CHAT_ID" ] || [ "$TELEGRAM_CHAT_ID" = "your_chat_id_here" ]; then
    echo "❌ TELEGRAM_CHAT_ID не настроен в .env файле"
    exit 1
fi

echo "✅ Конфигурация проверена успешно"
echo ""

# Проверка Google Cloud аутентификации
echo "🔍 Проверка Google Cloud аутентификации..."

if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ] && [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo "✅ Service Account ключ найден: $GOOGLE_APPLICATION_CREDENTIALS"
else
    echo "⚠️  Service Account ключ не найден. Проверяю Application Default Credentials..."
    
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        echo "✅ Application Default Credentials настроены"
    else
        echo "❌ Google Cloud аутентификация не настроена"
        echo "Пожалуйста, выполните одну из команд:"
        echo "  gcloud auth application-default login"
        echo "  или настройте GOOGLE_APPLICATION_CREDENTIALS в .env файле"
        exit 1
    fi
fi

echo ""

# Сборка и запуск контейнеров
echo "🐳 Сборка и запуск контейнеров..."

# Остановка существующих контейнеров
echo "🛑 Остановка существующих контейнеров..."
docker-compose down 2>/dev/null || true

# Сборка образов
echo "🔨 Сборка Docker образов..."
docker-compose build --no-cache

# Запуск сервисов
echo "🚀 Запуск сервисов..."
docker-compose up -d

# Ожидание запуска сервисов
echo "⏳ Ожидание запуска сервисов..."
sleep 10

# Проверка статуса
echo "🔍 Проверка статуса сервисов..."
docker-compose ps

echo ""
echo "✅ Система мониторинга запущена успешно!"
echo ""
echo "📱 Telegram Bot: @$(curl -s "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getMe" | grep -o '"username":"[^"]*"' | cut -d'"' -f4)"
echo "🏗️  Infrastructure Monitor: Запущен"
echo ""
echo "📋 Полезные команды:"
echo "  docker-compose logs -f telegram-bot          # Логи бота"
echo "  docker-compose logs -f infrastructure-monitor # Логи мониторинга"
echo "  docker-compose down                          # Остановка"
echo "  docker-compose restart                       # Перезапуск"
echo ""
echo "🔧 Для настройки мониторинга отредактируйте .env файл"
echo "📖 Подробная документация: README_INFRASTRUCTURE_MONITORING.md"
echo ""
echo "🎉 Готово! Отправьте /start боту в Telegram для начала работы."
