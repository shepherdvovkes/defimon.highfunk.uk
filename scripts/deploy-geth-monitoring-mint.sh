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

# 2. Базовые утилиты (jq, curl, tmux) и синхронизация времени
sudo apt-get update -y
sudo apt-get install -y jq curl tmux || true
# (опционально) синхронизация времени повышает стабильность консенсуса
if command -v timedatectl >/dev/null 2>&1; then
  sudo timedatectl set-ntp true || true
fi

# 3. Проверка и установка Docker Compose (v2 предпочтительно)
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

# 4. Системные параметры хоста (исключаем ошибки sysctl в контейнерах)
echo "Настраиваю системные параметры ядра (sysctl)..."
SYSCTL_FILE="/etc/sysctl.d/99-defimon.conf"
sudo bash -c "cat > $SYSCTL_FILE" << 'EOF'
vm.max_map_count=262144
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.core.rmem_default=67108864
net.core.wmem_default=67108864
EOF
sudo sysctl --system || true

# 5. Создание директории для данных, если ее нет
mkdir -p ./data/geth

# 6. Настройка режима запуска
# USE_INTERNAL_GETH=1 (по умолчанию) — поднимаем внутренний geth
# USE_INTERNAL_GETH=0 + EXECUTION_ENDPOINT + JWTSECRET_PATH — используем внешний geth
USE_INTERNAL_GETH="${USE_INTERNAL_GETH:-1}"
RUN_MONITOR="${RUN_MONITOR:-0}"

COMPOSE_FILE="./infrastructure/geth-monitoring/docker-compose.yml"

if [ "$USE_INTERNAL_GETH" = "1" ]; then
    echo "Режим: внутренний Geth (profile: internal-geth)"
    echo "Генерирую JWT секрет для связи Execution<->Consensus (если отсутствует)..."
    ./scripts/generate-jwtsecret.sh
    echo "Очищаю возможные нездоровые остатки прошлого запуска..."
    $COMPOSE_BIN -f "$COMPOSE_FILE" down --remove-orphans || true
    docker rm -f geth-full-node lighthouse-beacon 2>/dev/null || true
    docker volume rm $(docker volume ls -q | grep -E 'geth-monitoring_|_geth_data|_lighthouse_data') 2>/dev/null || true

    echo "Перезапускаю стек мониторинга (Geth, Lighthouse, Prometheus, Grafana)..."
    export JWTSECRET_PATH="$(realpath infrastructure/geth-monitoring/jwtsecret)"
    $COMPOSE_BIN -f "$COMPOSE_FILE" --profile internal-geth up -d --build
    echo "Проверяю запуск контейнеров..."
    sleep 5
    $COMPOSE_BIN -f "$COMPOSE_FILE" ps || true
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

# 7. Быстрая проверка доступности RPC и Beacon API
echo "Проверка RPC и Beacon API..."
sleep 5
if curl -fsS http://localhost:8545 >/dev/null 2>&1; then
  echo "Execution RPC (8545) отвечает"
  curl -s -X POST -H 'Content-Type: application/json' \
    --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
    http://localhost:8545 | jq -r '.result' || true
else
  echo "Execution RPC (8545) недоступен — пробую docker exec..."
  if docker ps --format '{{.Names}}' | grep -qx geth-full-node; then
    docker exec geth-full-node curl -s -X POST -H 'Content-Type: application/json' \
      --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
      http://127.0.0.1:8545 | jq -r '.result' || true
  fi
fi

if curl -fsS http://localhost:5052/eth/v1/node/health >/dev/null 2>&1; then
  echo "Consensus (Lighthouse) API (5052) отвечает"
else
  echo "Consensus (Lighthouse) API (5052) недоступен (нормально на старте, подождите)"
fi

# 8. Необязательный автозапуск монитора в tmux (верх статус, низ логи)
if [ "$RUN_MONITOR" = "1" ]; then
  echo "Запускаю мониторинг ноды (Ctrl+C для выхода из tmux)..."
  ENABLE_SPLIT=1 ./scripts/geth-cli-monitor.sh || true
fi
