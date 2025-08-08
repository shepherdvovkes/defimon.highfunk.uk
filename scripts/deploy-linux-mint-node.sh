#!/bin/bash

set -euo pipefail

echo "🚀 Deploying Ethereum Full Node for DEFIMON on Linux Mint..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_success() {
    echo -e "${PURPLE}[SUCCESS]${NC} $1"
}

# Требуются root-права
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "This script must be run as root (sudo)."
  exit 1
fi

# Определяем корень репозитория
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
NODE_DIR=/opt/defimon

print_header "=== DEFIMON Ethereum Full Node Setup for Linux Mint ==="

# Проверка системы
print_header "Checking Linux Mint system..."

# Проверка версии Linux Mint
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$NAME" == *"Linux Mint"* ]] || [[ "$NAME" == *"Ubuntu"* ]]; then
        print_status "Detected: $NAME $VERSION"
    else
        print_warning "This script is optimized for Linux Mint/Ubuntu. Current OS: $NAME"
    fi
else
    print_warning "Could not detect OS version"
fi

# Проверка системных требований
print_header "Checking system requirements..."

# Проверка RAM
TOTAL_RAM_GB=$(free -g | awk 'NR==2{print $2}')
if [ "${TOTAL_RAM_GB:-0}" -lt 8 ]; then
    print_error "Insufficient RAM: ${TOTAL_RAM_GB}GB available. Required: 8GB+, Recommended: 16GB+"
    exit 1
elif [ "${TOTAL_RAM_GB:-0}" -lt 16 ]; then
    print_warning "Low RAM: ${TOTAL_RAM_GB}GB available. Recommended: 16GB+ for optimal performance"
else
    print_success "RAM: ${TOTAL_RAM_GB}GB - Sufficient"
fi

# Проверка CPU
CPU_CORES=$(nproc)
if [ "$CPU_CORES" -lt 4 ]; then
    print_error "Insufficient CPU cores: $CPU_CORES. Required: 4+, Recommended: 8+"
    exit 1
elif [ "$CPU_CORES" -lt 8 ]; then
    print_warning "Low CPU cores: $CPU_CORES. Recommended: 8+ for optimal performance"
else
    print_success "CPU cores: $CPU_CORES - Sufficient"
fi

# Проверка свободного места
FREE_SPACE_KB=$(df -kP / | awk 'NR==2 {print $4}')
FREE_SPACE_GB=$((FREE_SPACE_KB / 1024 / 1024))
if [ "$FREE_SPACE_GB" -lt 100 ]; then
    print_error "Insufficient disk space: ${FREE_SPACE_GB}GB available. Required: 100GB+, Recommended: 1TB+"
    exit 1
elif [ "$FREE_SPACE_GB" -lt 500 ]; then
    print_warning "Low disk space: ${FREE_SPACE_GB}GB available. Recommended: 1TB+ for full node"
else
    print_success "Disk space: ${FREE_SPACE_GB}GB - Sufficient"
fi

# Поиск лучшего диска для данных
print_header "Finding optimal disk for node data..."

# Список всех дисков
DISKS=$(lsblk -d -n -o NAME,SIZE,TYPE | grep -E '^(sd|nvme|hd)' | awk '{print $1}')
BEST_DISK=""
BEST_SIZE=0

for disk in $DISKS; do
    if [ -b "/dev/$disk" ]; then
        size=$(lsblk -d -n -o SIZE "/dev/$disk" | sed 's/G//')
        if [ "$size" -gt "$BEST_SIZE" ]; then
            BEST_SIZE=$size
            BEST_DISK=$disk
        fi
    fi
done

if [ -n "$BEST_DISK" ]; then
    print_status "Best disk for data: /dev/$BEST_DISK (${BEST_SIZE}GB)"
    # Создаем отдельную директорию для данных на лучшем диске
    DATA_DIR="/mnt/$BEST_DISK/defimon-data"
    mkdir -p "$DATA_DIR"
    print_status "Data directory: $DATA_DIR"
else
    DATA_DIR="$NODE_DIR/data"
    print_warning "Using default data directory: $DATA_DIR"
fi

print_status "System requirements check completed"

# Установка зависимостей
print_header "Installing dependencies..."

# Обновление системы
print_status "Updating system packages..."
apt-get update -y

# Установка необходимых пакетов
print_status "Installing required packages..."
apt-get install -y \
    curl \
    wget \
    git \
    htop \
    iotop \
    iftop \
    nethogs \
    sysstat \
    lm-sensors \
    smartmontools \
    hdparm \
    cpufrequtils \
    ufw \
    fail2ban \
    logrotate \
    rsync \
    unzip \
    zip \
    jq \
    bc \
    tree \
    ncdu \
    nload \
    vnstat

# Установка Docker
print_status "Installing Docker..."
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker $SUDO_USER
    rm get-docker.sh
fi

# Docker Compose
if docker compose version >/dev/null 2>&1; then
    COMPOSE_BIN="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_BIN="docker-compose"
else
    print_status "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    COMPOSE_BIN="docker-compose"
fi

print_success "Dependencies installed successfully"

# Оптимизация системы для Linux Mint
print_header "Optimizing system for Linux Mint..."

# Настройка CPU для производительности
if command -v cpupower >/dev/null 2>&1; then
    print_status "Setting CPU to performance mode..."
    cpupower frequency-set -g performance
fi

# Настройка swappiness
print_status "Optimizing memory management..."
echo 'vm.swappiness=10' >> /etc/sysctl.conf
echo 'vm.dirty_ratio=15' >> /etc/sysctl.conf
echo 'vm.dirty_background_ratio=5' >> /etc/sysctl.conf
sysctl -p

# Настройка файрвола
print_status "Configuring firewall..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow from 127.0.0.1 to any port 8545
ufw allow from 127.0.0.1 to any port 8546
ufw allow from 127.0.0.1 to any port 3001
ufw allow from 127.0.0.1 to any port 9090
ufw allow from 127.0.0.1 to any port 8080

print_success "System optimization completed"

# Создание директорий
print_header "Creating directory structure..."
mkdir -p "$NODE_DIR" \
         "$DATA_DIR/ethereum" \
         "$NODE_DIR/logs" \
         "$NODE_DIR/config" \
         "$NODE_DIR/backup" \
         "$NODE_DIR/monitoring/grafana/dashboards" \
         "$NODE_DIR/monitoring/grafana/datasources" \
         "$NODE_DIR/scripts"

# Копирование конфигов
print_status "Copying configuration files..."
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

# Создание .env файла
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
API_KEY_SECRET=your_api_key_secret_here

# Data Directory
DATA_DIR=$DATA_DIR
EOF

print_success "Environment configuration created"

# Создание docker-compose для ноды
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
      NAT_EXTIP: \$(hostname -I | awk '{print \$1}')
    volumes:
      - ${DATA_DIR}/ethereum:/data/ethereum
      - ${REPO_ROOT}/services/blockchain-node:/app
      - ${NODE_DIR}/logs:/app/logs
    ports:
      - "127.0.0.1:8545:8545"
      - "127.0.0.1:8546:8546"
      - "30303:30303"
      - "30303:30303/udp"
      - "127.0.0.1:6060:6060"
      - "127.0.0.1:6061:6061"
    depends_on:
      - postgres
      - kafka
      - redis
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 8G
          cpus: '4.0'
        reservations:
          memory: 4G
          cpus: '2.0'

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
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'

  # Redis для кэширования
  redis:
    image: redis:7-alpine
    container_name: defimon-redis
    command: redis-server --appendonly yes --maxmemory 1gb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    ports:
      - "127.0.0.1:6379:6379"
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'

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
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'

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
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'

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
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'

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
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'

  # Admin Dashboard
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
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'

volumes:
  postgres_data:
  redis_data:
  prometheus_data:
  grafana_data:
EOF

print_success "Docker Compose configuration created"

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
    DATA_DIR=$(grep "DATA_DIR=" "$NODE_DIR/.env" | cut -d'=' -f2)
    tar -czf "$NODE_DIR/backup/ethereum-backup-$(date +%Y%m%d-%H%M%S).tar.gz" -C "$DATA_DIR" ethereum
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

print_success "Systemd service created and enabled"

# Создание скрипта мониторинга
print_header "Creating monitoring script..."
cat > "$NODE_DIR/monitor-node.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

echo "=== DEFIMON Node Status ==="
echo "Timestamp: $(date)"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime)"

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
  # Проверка синхронизации
  SYNC_STATUS=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
    http://localhost:8545 | jq -r '.result')
  if [ "$SYNC_STATUS" = "false" ]; then
    echo "Node is fully synced"
  else
    echo "Node is syncing: $SYNC_STATUS"
  fi
else
  echo "Node is not responding on port 8545"
fi

echo -e "\n--- Disk Usage ---"
df -h /opt/defimon

echo -e "\n--- Memory Usage ---"
free -h

echo -e "\n--- CPU Usage ---"
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1

echo -e "\n--- Recent Logs (blockchain-service) ---"
($COMPOSE_BIN -f /opt/defimon/docker-compose.node.yml logs --tail=20 blockchain-service 2>/dev/null) || echo "No logs available"
EOF

chmod +x "$NODE_DIR/monitor-node.sh"

# Создание скрипта диагностики
print_header "Creating diagnostic script..."
cat > "$NODE_DIR/diagnose.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

echo "=== DEFIMON Node Diagnostics ==="
echo "Timestamp: $(date)"

echo -e "\n--- System Information ---"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"

echo -e "\n--- Hardware Information ---"
echo "CPU: $(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
echo "CPU Cores: $(nproc)"
echo "RAM: $(free -h | grep Mem | awk '{print $2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $2}')"

echo -e "\n--- Network Information ---"
echo "IP Address: $(hostname -I)"
echo "Default Gateway: $(ip route | grep default | awk '{print $3}')"

echo -e "\n--- Docker Information ---"
docker --version
docker compose version 2>/dev/null || docker-compose --version

echo -e "\n--- Service Status ---"
systemctl status defimon-node.service --no-pager -l

echo -e "\n--- Container Status ---"
docker ps -a

echo -e "\n--- Resource Usage ---"
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)"
echo "Memory Usage:"
free -h
echo "Disk Usage:"
df -h

echo -e "\n--- Network Connections ---"
netstat -tuln | grep -E ':(8545|8546|3001|9090|8080)'

echo -e "\n--- Log Files ---"
echo "Recent system logs:"
journalctl -u defimon-node.service --no-pager -n 20

echo -e "\n--- Docker Logs ---"
echo "Recent blockchain-service logs:"
docker logs defimon-blockchain-service --tail=20 2>/dev/null || echo "Container not found"
EOF

chmod +x "$NODE_DIR/diagnose.sh"

# Настройка cron для мониторинга
print_header "Setting up monitoring cron jobs..."
(crontab -l 2>/dev/null; echo "*/5 * * * * $NODE_DIR/monitor-node.sh >> $NODE_DIR/logs/monitor.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "0 2 * * * $NODE_DIR/manage-node.sh backup >> $NODE_DIR/logs/backup.log 2>&1") | crontab -

print_success "Monitoring setup completed"

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
echo "Admin Dashboard: http://localhost:8080"
echo ""
echo "=== Management Commands ==="
echo "Start node:   sudo $NODE_DIR/manage-node.sh start"
echo "Stop node:    sudo $NODE_DIR/manage-node.sh stop"
echo "Check status: sudo $NODE_DIR/manage-node.sh status"
echo "View logs:    sudo $NODE_DIR/manage-node.sh logs"
echo "Monitor:      sudo $NODE_DIR/monitor-node.sh"
echo "Diagnose:     sudo $NODE_DIR/diagnose.sh"
echo ""
echo "=== Important Notes ==="
echo "1. Full sync may take 1-2 weeks depending on your hardware"
echo "2. Monitor disk space regularly: df -h /opt/defimon"
echo "3. Check logs for sync progress: sudo $NODE_DIR/manage-node.sh logs"
echo "4. The node will automatically restart on system reboot"
echo "5. Backups are created daily at 2:00 AM"
echo "6. Monitoring runs every 5 minutes"
echo ""
print_success "Ethereum full node deployment completed!"
print_success "Optimized for Linux Mint and Lenovo ThinkPad"
