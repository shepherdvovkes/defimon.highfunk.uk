#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}### DEPLOYING GETH FULL NODE WITH MONITORING ON LINUX MINT ###${NC}"

# 1. Проверка и установка Docker
if ! command -v docker &> /dev/null
then
    echo "Docker не найден. Устанавливаю..."
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    echo "Docker успешно установлен."
else
    echo "Docker уже установлен."
fi

# 2. Проверка и установка Docker Compose
if ! command -v docker-compose &> /dev/null
then
    echo "Docker Compose не найден. Устанавливаю..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose успешно установлен."
else
    echo "Docker Compose уже установлен."
fi

# 3. Создание директории для данных, если ее нет
mkdir -p ./data/geth

# 4. Запуск Docker Compose
echo "Запускаю Docker контейнеры (Geth, Prometheus, Grafana)..."
docker-compose -f ./infrastructure/geth-monitoring/docker-compose.yml up -d

echo -e "${GREEN}### ДЕПЛОЙ УСПЕШНО ЗАВЕРШЕН ###${NC}"
echo "Geth нода запущена и синхронизируется."
echo "Prometheus доступен по адресу: http://localhost:9090"
echo "Grafana доступна по адресу: http://localhost:3000 (логин/пароль: admin/admin)"
