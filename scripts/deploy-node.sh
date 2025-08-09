#!/bin/bash

set -euo pipefail

echo "🚀 Deploying Ethereum Node for DEFIMON..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода
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

# Требуются root-права
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "This script must be run as root (sudo)."
  exit 1
fi

# Определяем корень репозитория
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
NODE_DIR=/opt/defimon

# Проверка системных требований
print_header "Checking system requirements..."

# Docker
if ! command -v docker >/dev/null 2>&1; then
  print_status "Installing Docker..."
  apt-get update -y
  apt-get install -y docker.io
fi

# Docker Compose (поддержка и v2 'docker compose', и v1 'docker-compose')
if docker compose version >/dev/null 2>&1; then
  COMPOSE_BIN="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_BIN="docker-compose"
else
  print_status "Installing Docker Compose plugin..."
  apt-get update -y
  apt-get install -y docker-compose-plugin || apt-get install -y docker-compose || true
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_BIN="docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_BIN="docker-compose"
  else
    print_error "Docker Compose is not installed. Install docker-compose-plugin or docker-compose."
    exit 1
  fi
fi

# Проверка свободного места
FREE_SPACE_KB=$(df -kP / | awk 'NR==2 {print $4}')
FREE_SPACE_GB=$((FREE_SPACE_KB / 1024 / 1024))
if [ "$FREE_SPACE_GB" -lt 100 ]; then
  print_warning "Low disk space: ${FREE_SPACE_GB}GB available. Recommended: 500GB+ for full node"
fi

# Проверка RAM
TOTAL_RAM_GB=$(free -g | awk 'NR==2{print $2}')
if [ "${TOTAL_RAM_GB:-0}" -lt 8 ]; then
  print_warning "Low RAM: ${TOTAL_RAM_GB}GB available. Recommended: 16GB+ for full node"
fi

print_status "System requirements check completed"

# Создание директорий и копирование конфигов
print_header "Creating directories..."
mkdir -p "$NODE_DIR/data/ethereum" "$NODE_DIR/logs" "$NODE_DIR/config" "$NODE_DIR/backup" \
         "$NODE_DIR/monitoring/grafana/dashboards" "$NODE_DIR/monitoring/grafana/datasources"

# Копируем необходимые конфиги из репозитория
if [ -f "$REPO_ROOT/infrastructure/monitoring/prometheus.yml" ]; then
  cp -f "$REPO_ROOT/infrastructure/monitoring/prometheus.yml" "$NODE_DIR/monitoring/prometheus.yml"
fi
if [ -d "$REPO_ROOT/infrastructure/monitoring/grafana/dashboards" ]; then
  cp -rf "$REPO_ROOT/infrastructure/monitoring/grafana/dashboards/." "$NODE_DIR/monitoring/grafana/dashboards/"
fi
if [ -d "$REPO_ROOT/infrastructure/monitoring/grafana/datasources" ]; then
  cp -rf "$REPO_ROOT/infrastructure/monitoring/grafana/datasources/." "$NODE_DIR/monitoring/grafana/datasources/"
fi
if [ -f "$REPO_ROOT/infrastructure/init.sql" ]; then
  cp -f "$REPO_ROOT/infrastructure/init.sql" "$NODE_DIR/init.sql"
fi

# Создание .env файла для ноды
print_header "Creating environment configuration..."
cat > "$NODE_DIR/.env" << EOF
# Ethereum Node Configuration
ETHEREUM_NODE_URL=http://localhost:8545
DATABASE_URL=postgresql://postgres:password@localhost:5432/defi_analytics
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
REDIS_URL=redis://localhost:6379

# Node Settings
SYNC_MODE=full
CACHE_SIZE=8192
MAX_PEERS=50
RPC_PORT=8545
WS_PORT=8546
P2P_PORT=30303

# Rust Application
RUST_LOG=info
RUST_BACKTRACE=1

# Monitoring
PROMETHEUS_PORT=9090
GRAFANA_PORT=3001

# Security
JWT_SECRET=your_jwt_secret_here
# API_KEY_SECRET=your_api_key_secret_here  # Optional - for external API access
EOF

print_status "Environment configuration created"

# Создание docker-compose для ноды (один контейнер с Geth + Rust)
print_header "Creating Docker Compose configuration..."
cat > "$NODE_DIR/docker-compose.node.yml" << EOF
version: '3.8'

services:
  # Blockchain Node Service (Geth + Rust)
  blockchain-service:
    build:
      context: ${REPO_ROOT}/services/blockchain-node
      dockerfile: Dockerfile
    container_name: defimon-blockchain-service
    environment:
      ETHEREUM_NODE_URL: http://localhost:8545
      DATABASE_URL: postgresql://postgres:password@postgres:5432/defi_analytics
      KAFKA_BOOTSTRAP_SERVERS: kafka:9092
      REDIS_URL: redis://redis:6379
      RUST_LOG: info
      SYNC_MODE: full
      CACHE_SIZE: 4096
      MAX_PEERS: 50
      RPC_PORT: 8545
      WS_PORT: 8546
      P2P_PORT: 30303
      NAT_EXTIP: 192.168.0.153
    volumes:
      - ${NODE_DIR}/data/ethereum:/data/ethereum
      - ${REPO_ROOT}/services/blockchain-node:/app
      - ${NODE_DIR}/logs:/app/logs
    ports:
      - "192.168.0.153:8545:8545"
      - "192.168.0.153:8546:8546"
      - "30303:30303"
      - "30303:30303/udp"
      - "127.0.0.1:6060:6060"
      - "127.0.0.1:6061:6061"
    depends_on:
      - postgres
      - kafka
      - redis
    restart: unless-stopped

  # PostgreSQL для локального хранения
  postgres:
    image: postgres:15
    container_name: defimon-postgres
    environment:
      POSTGRES_DB: defi_analytics
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ${NODE_DIR}/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "127.0.0.1:5432:5432"
    restart: unless-stopped

  # Redis для кэширования
  redis:
    image: redis:7-alpine
    container_name: defimon-redis
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    ports:
      - "127.0.0.1:6379:6379"
    restart: unless-stopped

  # Kafka для потоковой обработки
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    container_name: defimon-zookeeper
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - "127.0.0.1:2181:2181"
    restart: unless-stopped

  kafka:
    image: confluentinc/cp-kafka:latest
    container_name: defimon-kafka
    depends_on:
      - zookeeper
    ports:
      - "127.0.0.1:9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092,PLAINTEXT_HOST://localhost:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
    restart: unless-stopped

  # Мониторинг
  prometheus:
    image: prom/prometheus:latest
    container_name: defimon-prometheus
    volumes:
      - ${NODE_DIR}/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    ports:
      - "127.0.0.1:9090:9090"
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: defimon-grafana
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
      GF_INSTALL_PLUGINS: grafana-clock-panel,grafana-simple-json-datasource
    volumes:
      - grafana_data:/var/lib/grafana
      - ${NODE_DIR}/monitoring/grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ${NODE_DIR}/monitoring/grafana/datasources:/etc/grafana/provisioning/datasources
    ports:
      - "127.0.0.1:3001:3000"
    restart: unless-stopped

  # Admin Dashboard (локально на 127.0.0.1)
  admin-dashboard:
    build:
      context: ${REPO_ROOT}/services/admin-dashboard
      dockerfile: Dockerfile
    container_name: defimon-admin-dashboard
    environment:
      NODE_ENV: production
      PORT: 8080
    ports:
      - "127.0.0.1:8080:8080"
    depends_on:
      - blockchain-service
      - postgres
      - redis
      - kafka
      - prometheus
      - grafana
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
  prometheus_data:
  grafana_data:
EOF

print_status "Docker Compose configuration created"

# Создание скрипта управления
print_header "Creating management scripts..."
cat > "$NODE_DIR/manage-node.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

NODE_DIR="/opt/defimon"
COMPOSE_FILE="$NODE_DIR/docker-compose.node.yml"

if docker compose version >/dev/null 2>&1; then
  COMPOSE_BIN="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_BIN="docker-compose"
else
  echo "Docker Compose is not installed"; exit 1
fi

case "${1:-}" in
  start)
    echo "Starting Ethereum node..."
    cd "$NODE_DIR"
    $COMPOSE_BIN -f "$COMPOSE_FILE" up -d
    echo "Node started successfully"
    ;;
  stop)
    echo "Stopping Ethereum node..."
    cd "$NODE_DIR"
    $COMPOSE_BIN -f "$COMPOSE_FILE" down
    echo "Node stopped successfully"
    ;;
  restart)
    echo "Restarting Ethereum node..."
    cd "$NODE_DIR"
    $COMPOSE_BIN -f "$COMPOSE_FILE" restart
    echo "Node restarted successfully"
    ;;
  status)
    echo "Checking node status..."
    cd "$NODE_DIR"
    $COMPOSE_BIN -f "$COMPOSE_FILE" ps
    ;;
  logs)
    echo "Showing logs (press Ctrl+C to exit)..."
    cd "$NODE_DIR"
    $COMPOSE_BIN -f "$COMPOSE_FILE" logs -f --tail=200 blockchain-service
    ;;
  backup)
    echo "Creating backup..."
    mkdir -p "$NODE_DIR/backup"
    tar -czf "$NODE_DIR/backup/ethereum-backup-$(date +%Y%m%d-%H%M%S).tar.gz" -C "$NODE_DIR" data/ethereum
    echo "Backup created successfully"
    ;;
  update)
    echo "Updating node..."
    cd "$NODE_DIR"
    $COMPOSE_BIN -f "$COMPOSE_FILE" pull || true
    $COMPOSE_BIN -f "$COMPOSE_FILE" build
    $COMPOSE_BIN -f "$COMPOSE_FILE" up -d
    echo "Node updated successfully"
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status|logs|backup|update}"
    exit 1
    ;;
esac
EOF

chmod +x "$NODE_DIR/manage-node.sh"

# Создание systemd сервиса
print_header "Creating systemd service..."
cat > /etc/systemd/system/defimon-node.service << EOF
[Unit]
Description=DEFIMON Ethereum Node
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${NODE_DIR}
ExecStart=${NODE_DIR}/manage-node.sh start
ExecStop=${NODE_DIR}/manage-node.sh stop
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable defimon-node.service

print_status "Systemd service created and enabled"

# Создание скрипта мониторинга
print_header "Creating monitoring script..."
cat > "$NODE_DIR/monitor-node.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

echo "=== DEFIMON Node Status ==="
echo "Timestamp: $(date)"

if docker compose version >/dev/null 2>&1; then
  COMPOSE_BIN="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_BIN="docker-compose"
else
  echo "Docker Compose is not installed"; exit 1
fi

echo -e "\n--- Docker Containers ---"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | (sed -u 1q; sort -u)

echo -e "\n--- Resource Usage ---"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo -e "\n--- Node Sync Status ---"
if curl -fsS http://localhost:8545 >/dev/null; then
  echo "Node is responding on port 8545"
else
  echo "Node is not responding on port 8545"
fi

echo -e "\n--- Disk Usage ---"
df -h /opt/defimon

echo -e "\n--- Recent Logs (blockchain-service) ---"
($COMPOSE_BIN -f /opt/defimon/docker-compose.node.yml logs --tail=50 blockchain-service 2>/dev/null) || echo "No logs available"
EOF

chmod +x "$NODE_DIR/monitor-node.sh"

# Cron для мониторинга
print_header "Setting up monitoring cron job..."
(crontab -l 2>/dev/null; echo "*/5 * * * * $NODE_DIR/monitor-node.sh >> $NODE_DIR/logs/monitor.log 2>&1") | crontab -

print_status "Monitoring setup completed"

# Запуск ноды
print_header "Starting Ethereum node..."
cd "$NODE_DIR"
$COMPOSE_BIN -f docker-compose.node.yml up -d

print_status "Waiting for services to start..."
sleep 30

print_header "Checking service status..."
$COMPOSE_BIN -f docker-compose.node.yml ps

print_header "Deployment completed successfully!"
echo ""
echo "=== Access Information ==="
echo "Ethereum RPC: http://localhost:8545"
echo "Ethereum WS:  ws://localhost:8546"
echo "Grafana:      http://localhost:3001 (admin/admin)"
echo "Prometheus:   http://localhost:9090"
echo ""
echo "=== Management Commands ==="
echo "Start node:   $NODE_DIR/manage-node.sh start"
echo "Stop node:    $NODE_DIR/manage-node.sh stop"
echo "Check status: $NODE_DIR/manage-node.sh status"
echo "View logs:    $NODE_DIR/manage-node.sh logs"
echo "Monitor:      $NODE_DIR/monitor-node.sh"
echo ""
echo "=== Important Notes ==="
echo "1. Full sync may take 1-2 weeks depending on your hardware"
echo "2. Ensure you have at least 500GB free disk space"
echo "3. Monitor the logs for sync progress"
echo "4. The node will automatically restart on system reboot"
echo ""
print_status "Ethereum node deployment completed!"
