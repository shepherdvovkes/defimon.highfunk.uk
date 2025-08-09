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

# 2. Проверка и установка Docker Compose (v2 предпочтительно)
if docker compose version >/dev/null 2>&1; then
    COMPOSE_BIN="docker compose"
    echo "Найден современный Docker Compose (v2)"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_BIN="docker-compose"
    echo "Найден legacy docker-compose"
else
    echo "Docker Compose не найден. Устанавливаю legacy docker-compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    COMPOSE_BIN="docker-compose"
fi

# 3. Создание директории для данных, если ее нет
mkdir -p ./data/geth

# Настройка режима запуска
# USE_INTERNAL_GETH=1 (по умолчанию) — поднимаем внутренний geth
# USE_INTERNAL_GETH=0 + EXECUTION_ENDPOINT + JWTSECRET_PATH — используем внешний geth
USE_INTERNAL_GETH="${USE_INTERNAL_GETH:-1}"

COMPOSE_FILE="./infrastructure/geth-monitoring/docker-compose.yml"

if [ "$USE_INTERNAL_GETH" = "1" ]; then
    echo "Режим: внутренний Geth (profile: internal-geth)"
    echo "Генерирую JWT секрет для связи Execution<->Consensus (если отсутствует)..."
    ./scripts/generate-jwtsecret.sh
    echo "Перезапускаю стек мониторинга (Geth, Lighthouse, Prometheus, Grafana)..."
    $COMPOSE_BIN -f "$COMPOSE_FILE" down --remove-orphans || true
    # Включаем профиль internal-geth, чтобы стартовал geth
    $COMPOSE_BIN -f "$COMPOSE_FILE" --profile internal-geth up -d --build
else
    echo "Режим: внешний Geth"
    : "${EXECUTION_ENDPOINT:?EXECUTION_ENDPOINT не задан (пример: http://host.docker.internal:8551 или http://<HOST_IP>:8551)}"
    : "${JWTSECRET_PATH:?JWTSECRET_PATH не задан (пример: /path/to/jwtsecret)}"
    if [ ! -f "$JWTSECRET_PATH" ]; then
        echo "Файл JWT секрета не найден по пути: $JWTSECRET_PATH" >&2
        exit 1
    fi
    echo "Перезапускаю стек мониторинга (Lighthouse, Prometheus, Grafana) без внутреннего geth..."
    EXECUTION_ENDPOINT="$EXECUTION_ENDPOINT" JWTSECRET_PATH="$JWTSECRET_PATH" \
      $COMPOSE_BIN -f "$COMPOSE_FILE" down --remove-orphans || true
    EXECUTION_ENDPOINT="$EXECUTION_ENDPOINT" JWTSECRET_PATH="$JWTSECRET_PATH" \
      $COMPOSE_BIN -f "$COMPOSE_FILE" up -d --build
fi

echo -e "${GREEN}### ДЕПЛОЙ УСПЕШНО ЗАВЕРШЕН ###${NC}"
if [ "$USE_INTERNAL_GETH" = "1" ]; then
  echo "Geth (Execution) и Lighthouse (Consensus) запущены и синхронизируются."
else
  echo "Lighthouse (Consensus) запущен и подключается к внешнему Execution: $EXECUTION_ENDPOINT"
fi
echo "Prometheus: http://localhost:9090"
echo "Grafana: http://localhost:3000 (логин/пароль: admin/admin)"
