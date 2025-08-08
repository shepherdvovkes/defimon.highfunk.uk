#!/bin/bash

set -e

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

# Проверка системных требований
print_header "Checking system requirements..."

# Проверка Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Проверка Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Проверка свободного места
FREE_SPACE=$(df / | awk 'NR==2 {print $4}')
FREE_SPACE_GB=$((FREE_SPACE / 1024 / 1024))

if [ $FREE_SPACE_GB -lt 100 ]; then
    print_warning "Low disk space: ${FREE_SPACE_GB}GB available. Recommended: 500GB+ for full node"
fi

# Проверка RAM
TOTAL_RAM=$(free -g | awk 'NR==2{print $2}')
if [ $TOTAL_RAM -lt 8 ]; then
    print_warning "Low RAM: ${TOTAL_RAM}GB available. Recommended: 16GB+ for full node"
fi

print_status "System requirements check completed"

# Создание директорий
print_header "Creating directories..."
mkdir -p /opt/defimon/ethereum
mkdir -p /opt/defimon/logs
mkdir -p /opt/defimon/config
mkdir -p /opt/defimon/backup

# Создание .env файла для ноды
print_header "Creating environment configuration..."
cat > /opt/defimon/.env << EOF
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
EOF

print_status "Environment configuration created"

# Создание docker-compose для ноды
print_header "Creating Docker Compose configuration..."
cat > /opt/defimon/docker-compose.node.yml << EOF
version: '3.8'

services:
  # Ethereum Node
  ethereum-node:
    image: ethereum/client-go:latest
    container_name: defimon-ethereum-node
    command: >
      --datadir /data/ethereum
      --syncmode full
      --cache 8192
      --maxpeers 50
      --http
      --http.addr 0.0.0.0
      --http.port 8545
      --http.corsdomain "*"
      --http.api "eth,net,web3,debug,txpool,personal"
      --ws
      --ws.addr 0.0.0.0
      --ws.port 8546
      --ws.api "eth,net,web3"
      --port 30303
      --allow-insecure-unlock
      --verbosity 3
      --metrics
      --metrics.addr 0.0.0.0
      --metrics.port 6060
      --pprof
      --pprof.addr 0.0.0.0
      --pprof.port 6061
    volumes:
      - ethereum_data:/data/ethereum
      - /opt/defimon/logs:/var/log/ethereum
    ports:
      - "8545:8545"
      - "8546:8546"
      - "30303:30303"
      - "30303:30303/udp"
      - "6060:6060"
      - "6061:6061"
    environment:
      - ETHEREUM_NODE_URL=http://localhost:8545
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 8G
          cpus: '4.0'
        reservations:
          memory: 4G
          cpus: '2.0'

  # Blockchain Node Service (Rust)
  blockchain-service:
    build: 
      context: ./services/blockchain-node
      dockerfile: Dockerfile
    container_name: defimon-blockchain-service
    environment:
      ETHEREUM_NODE_URL: http://ethereum-node:8545
      DATABASE_URL: postgresql://postgres:password@postgres:5432/defi_analytics
      KAFKA_BOOTSTRAP_SERVERS: kafka:9092
      REDIS_URL: redis://redis:6379
      RUST_LOG: info
      SYNC_MODE: full
      CACHE_SIZE: 4096
      MAX_PEERS: 50
    volumes:
      - ./services/blockchain-node:/app
      - /opt/defimon/logs:/app/logs
    depends_on:
      - ethereum-node
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
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    restart: unless-stopped

  # Redis для кэширования
  redis:
    image: redis:7-alpine
    container_name: defimon-redis
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    restart: unless-stopped

  # Kafka для потоковой обработки
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    container_name: defimon-zookeeper
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - "2181:2181"
    restart: unless-stopped

  kafka:
    image: confluentinc/cp-kafka:latest
    container_name: defimon-kafka
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
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
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    ports:
      - "9090:9090"
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: defimon-grafana
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
      GF_INSTALL_PLUGINS: grafana-clock-panel,grafana-simple-json-datasource
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./monitoring/grafana/datasources:/etc/grafana/provisioning/datasources
    ports:
      - "3001:3000"
    restart: unless-stopped

volumes:
  ethereum_data:
  postgres_data:
  redis_data:
  prometheus_data:
  grafana_data:
EOF

print_status "Docker Compose configuration created"

# Создание скрипта управления
print_header "Creating management scripts..."
cat > /opt/defimon/manage-node.sh << 'EOF'
#!/bin/bash

set -e

NODE_DIR="/opt/defimon"
COMPOSE_FILE="$NODE_DIR/docker-compose.node.yml"

case "$1" in
    start)
        echo "Starting Ethereum node..."
        cd $NODE_DIR
        docker-compose -f $COMPOSE_FILE up -d
        echo "Node started successfully"
        ;;
    stop)
        echo "Stopping Ethereum node..."
        cd $NODE_DIR
        docker-compose -f $COMPOSE_FILE down
        echo "Node stopped successfully"
        ;;
    restart)
        echo "Restarting Ethereum node..."
        cd $NODE_DIR
        docker-compose -f $COMPOSE_FILE restart
        echo "Node restarted successfully"
        ;;
    status)
        echo "Checking node status..."
        cd $NODE_DIR
        docker-compose -f $COMPOSE_FILE ps
        ;;
    logs)
        echo "Showing logs..."
        cd $NODE_DIR
        docker-compose -f $COMPOSE_FILE logs -f
        ;;
    backup)
        echo "Creating backup..."
        cd $NODE_DIR
        tar -czf backup/ethereum-backup-$(date +%Y%m%d-%H%M%S).tar.gz data/
        echo "Backup created successfully"
        ;;
    update)
        echo "Updating node..."
        cd $NODE_DIR
        docker-compose -f $COMPOSE_FILE pull
        docker-compose -f $COMPOSE_FILE up -d
        echo "Node updated successfully"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|backup|update}"
        exit 1
        ;;
esac
EOF

chmod +x /opt/defimon/manage-node.sh

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
WorkingDirectory=/opt/defimon
ExecStart=/opt/defimon/manage-node.sh start
ExecStop=/opt/defimon/manage-node.sh stop
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Перезагрузка systemd и включение сервиса
systemctl daemon-reload
systemctl enable defimon-node.service

print_status "Systemd service created and enabled"

# Создание скрипта мониторинга
print_header "Creating monitoring script..."
cat > /opt/defimon/monitor-node.sh << 'EOF'
#!/bin/bash

echo "=== DEFIMON Node Status ==="
echo "Timestamp: $(date)"

# Проверка Docker контейнеров
echo -e "\n--- Docker Containers ---"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Проверка использования ресурсов
echo -e "\n--- Resource Usage ---"
echo "CPU Usage:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Проверка синхронизации ноды
echo -e "\n--- Node Sync Status ---"
if curl -s http://localhost:8545 > /dev/null; then
    echo "Node is responding on port 8545"
    # Здесь можно добавить проверку синхронизации через RPC
else
    echo "Node is not responding on port 8545"
fi

# Проверка дискового пространства
echo -e "\n--- Disk Usage ---"
df -h /opt/defimon

# Проверка логов
echo -e "\n--- Recent Logs ---"
tail -n 20 /opt/defimon/logs/ethereum.log 2>/dev/null || echo "No logs found"
EOF

chmod +x /opt/defimon/monitor-node.sh

# Создание cron задачи для мониторинга
print_header "Setting up monitoring cron job..."
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/defimon/monitor-node.sh >> /opt/defimon/logs/monitor.log 2>&1") | crontab -

print_status "Monitoring setup completed"

# Запуск ноды
print_header "Starting Ethereum node..."
cd /opt/defimon
docker-compose -f docker-compose.node.yml up -d

# Ожидание запуска
print_status "Waiting for services to start..."
sleep 30

# Проверка статуса
print_header "Checking service status..."
docker-compose -f docker-compose.node.yml ps

print_header "Deployment completed successfully!"
echo ""
echo "=== Access Information ==="
echo "Ethereum RPC: http://localhost:8545"
echo "Ethereum WS:  ws://localhost:8546"
echo "Grafana:      http://localhost:3001 (admin/admin)"
echo "Prometheus:   http://localhost:9090"
echo ""
echo "=== Management Commands ==="
echo "Start node:   /opt/defimon/manage-node.sh start"
echo "Stop node:    /opt/defimon/manage-node.sh stop"
echo "Check status: /opt/defimon/manage-node.sh status"
echo "View logs:    /opt/defimon/manage-node.sh logs"
echo "Monitor:      /opt/defimon/monitor-node.sh"
echo ""
echo "=== Important Notes ==="
echo "1. Full sync may take 1-2 weeks depending on your hardware"
echo "2. Ensure you have at least 500GB free disk space"
echo "3. Monitor the logs for sync progress"
echo "4. The node will automatically restart on system reboot"
echo ""
print_status "Ethereum node deployment completed!"
