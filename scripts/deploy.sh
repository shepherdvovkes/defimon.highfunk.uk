#!/bin/bash

set -e

echo "🚀 Deploying DeFi Analytics Platform..."

# Environment variables
export COMPOSE_PROJECT_NAME=defi-analytics
export DOCKER_BUILDKIT=1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_arch() {
    echo -e "${BLUE}[ARCH]${NC} $1"
}

# Определение архитектуры системы
print_status "Detecting system architecture..."
ARCH=$(uname -m)
OS=$(uname -s)

print_arch "Detected: $ARCH on $OS"

# Настройка параметров в зависимости от архитектуры
case $ARCH in
    "x86_64"|"amd64")
        print_arch "x86_64 architecture detected"
        export DOCKER_DEFAULT_PLATFORM=linux/amd64
        export RUST_TARGET=x86_64-unknown-linux-gnu
        export GOARCH=amd64
        export GOOS=linux
        ;;
    "aarch64"|"arm64")
        print_arch "ARM64 architecture detected"
        export DOCKER_DEFAULT_PLATFORM=linux/arm64
        export RUST_TARGET=aarch64-unknown-linux-gnu
        export GOARCH=arm64
        export GOOS=linux
        ;;
    "armv7l")
        print_arch "ARM32 architecture detected"
        export DOCKER_DEFAULT_PLATFORM=linux/arm/v7
        export RUST_TARGET=armv7-unknown-linux-gnueabihf
        export GOARCH=arm
        export GOOS=linux
        ;;
    *)
        print_error "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

print_status "Setting up environment for $ARCH..."

# Настройка параметров ядра для ClickHouse/Elasticsearch
print_status "Configuring kernel parameters..."
if [ "$(id -u)" -eq 0 ]; then
    # Если запущено от root, настраиваем параметры ядра
    sysctl -w vm.max_map_count=262144
    sysctl -w fs.file-max=65536
    sysctl -w vm.swappiness=1
    print_status "Kernel parameters configured"
else
    # Если не root, проверяем текущие значения
    CURRENT_MAX_MAP_COUNT=$(sysctl -n vm.max_map_count)
    if [ "$CURRENT_MAX_MAP_COUNT" -lt 262144 ]; then
        print_warning "vm.max_map_count is too low ($CURRENT_MAX_MAP_COUNT). Please run as root or set:"
        print_warning "sudo sysctl -w vm.max_map_count=262144"
        print_warning "sudo sysctl -w fs.file-max=65536"
        print_warning "sudo sysctl -w vm.swappiness=1"
    else
        print_status "Kernel parameters are sufficient"
    fi
fi

# Экспорт переменных окружения для Docker
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1

# Создание .env файла с архитектурными параметрами
print_status "Creating environment configuration..."
cat > .env << EOF
# Architecture Configuration
ARCH=$ARCH
RUST_TARGET=$RUST_TARGET
DOCKER_DEFAULT_PLATFORM=$DOCKER_DEFAULT_PLATFORM

# Database Configuration
POSTGRES_DB=defi_analytics
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password

# ClickHouse Configuration
CLICKHOUSE_DB=analytics
CLICKHOUSE_USER=default
CLICKHOUSE_PASSWORD=password

# External API Keys (Optional - for additional data sources)
# These are not required as we use our own nodes
# THE_GRAPH_API_KEY=your_the_graph_api_key
# ALCHEMY_API_KEY=your_alchemy_api_key
# COINGECKO_API_KEY=your_coingecko_api_key

# Ethereum Node Configuration
ETHEREUM_NODE_URL=http://localhost:8545
SYNC_MODE=full
CACHE_SIZE=4096
MAX_PEERS=50

# L2 Networks Configuration
L2_SYNC_ENABLED=true
L2_NETWORKS=optimism,arbitrum_one,polygon_zkevm,base,zksync_era,starknet,linea,scroll
L2_SYNC_INTERVAL=12
L2_BATCH_SIZE=100
L2_MAX_CONCURRENT_REQUESTS=10
L2_DATA_RETENTION_DAYS=90
L2_ARCHIVE_MODE=false
L2_PRIORITY_THRESHOLD=5

# EVM Networks Configuration
EVM_SYNC_ENABLED=true
EVM_NETWORKS=ethereum,arbitrum_one,base,op_mainnet,blast,mantle,mode,world_chain,opbnb,metis,boba,zksync_era,linea,scroll,polygon_zkevm,bsc_mainnet,avalanche_c,polygon_pos,fantom,cronos,gnosis,celo,klaytn,moonbeam,moonriver,harmony,okx_xlayer,taiko,immutable_zkevm,kroma,sophon,apecoin_apechain,zircuit,flare,meter,syscoin,telos,core,bitlayer,merlin,aurora,evmos,kava_evm,canto,oasis_emerald,astar,shiden,reef,fuse,iotex,heco,okc,kcc,palm,etc,callisto,smartbch,nahmii,bttc,conflux_espace,zklink_nova,zora,pgn,redstone_l2,fraxchain,metal_l2,ancient8,xai,treasure,beam_evm,dfk_chain,songbird,shibarium,pulsechain,rootstock,bob,bevm,bsquared,zkfair,manta_pacific

# Substrate Networks Configuration
SUBSTRATE_SYNC_ENABLED=true
SUBSTRATE_NETWORKS=polkadot,kusama,westend,rococo,moonbeam,moonriver,astar,acala,parallel,centrifuge,hydradx,bifrost,interlay,unique,phala,zeitgeist
SUBSTRATE_SYNC_INTERVAL=8
SUBSTRATE_BATCH_SIZE=25
SUBSTRATE_MAX_CONCURRENT_REQUESTS=6
SUBSTRATE_DATA_RETENTION_DAYS=90
SUBSTRATE_PRIORITY_THRESHOLD=5

# Cosmos Networks Configuration
COSMOS_SYNC_ENABLED=true
COSMOS_NETWORKS=cosmos_hub,osmosis,injective,celestia,sei,neutron,stride,quicksilver,persistence,agoric,evmos,kava,terra,terra_classic,secret,band,akash,stargaze,comdex,gravity_bridge,iris,likecoin,sentinel,regen,bitcanna,cheqd,emoney,impacthub,ixo,medibloc,microtick,panacea,passage,provenance,rizon,shentu,starname,teritori,umee,vidulum,assetmantle,axelar,binance_smart_chain,binance_chain,thorchain
COSMOS_SYNC_INTERVAL=15
COSMOS_BATCH_SIZE=50
COSMOS_MAX_CONCURRENT_REQUESTS=8
COSMOS_DATA_RETENTION_DAYS=90
COSMOS_PRIORITY_THRESHOLD=5

# Polkadot Networks Configuration
POLKADOT_SYNC_ENABLED=true
POLKADOT_NETWORKS=polkadot,kusama,westend,rococo
POLKADOT_SYNC_INTERVAL=10
POLKADOT_BATCH_SIZE=20
POLKADOT_MAX_CONCURRENT_REQUESTS=5
POLKADOT_DATA_RETENTION_DAYS=90
POLKADOT_PRIORITY_THRESHOLD=5

# Logging
RUST_LOG=info
EOF

print_status "Environment configuration created for $ARCH"

# Создание необходимых директорий
print_status "Creating necessary directories..."
mkdir -p data/postgres data/clickhouse data/redis data/grafana logs

# Проверка Docker
print_status "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed"
    exit 1
fi

print_status "Docker and Docker Compose are available"

# Остановка существующих контейнеров
print_status "Stopping existing containers..."
docker-compose -f infrastructure/docker-compose.yml down --remove-orphans || true

# Очистка старых образов
print_status "Cleaning old images..."
docker system prune -f

# Сборка образов с правильной архитектурой
print_status "Building Docker images for $ARCH..."
docker-compose -f infrastructure/docker-compose.yml build --no-cache

print_status "Starting databases..."
docker-compose -f infrastructure/docker-compose.yml up -d postgres clickhouse redis kafka zookeeper

# Ожидание готовности баз данных
print_status "Waiting for databases to be ready..."
sleep 30

# Проверка здоровья баз данных
print_status "Checking database health..."
if ! docker-compose -f infrastructure/docker-compose.yml exec -T postgres pg_isready -U postgres; then
    print_error "PostgreSQL is not ready"
    exit 1
fi

if ! curl -f http://localhost:8123/ping > /dev/null 2>&1; then
    print_error "ClickHouse is not ready"
    exit 1
fi

if ! docker-compose -f infrastructure/docker-compose.yml exec -T redis redis-cli ping > /dev/null 2>&1; then
    print_error "Redis is not ready"
    exit 1
fi

print_status "All databases are healthy"

# Запуск миграций базы данных
print_status "Running database migrations..."
docker-compose -f infrastructure/docker-compose.yml exec -T postgres psql -U postgres -d defi_analytics -f /docker-entrypoint-initdb.d/init.sql

print_status "Setting up ClickHouse schema..."
docker-compose -f infrastructure/docker-compose.yml exec -T clickhouse clickhouse-client --multiquery < infrastructure/clickhouse_schema.sql

# Запуск сервисов приложения
print_status "Starting application services..."
docker-compose -f infrastructure/docker-compose.yml up -d data-ingestion stream-processor ai-ml-service analytics-api

# Запуск blockchain-node с правильной архитектурой
print_status "Starting blockchain node for $ARCH..."
docker-compose -f infrastructure/docker-compose.yml up -d blockchain-node

# Запуск фронтенда и мониторинга
print_status "Starting frontend and monitoring..."
docker-compose -f infrastructure/docker-compose.yml up -d frontend api-gateway prometheus grafana admin-dashboard

# Проверки здоровья
print_status "Running health checks..."
sleep 15

# Проверка API Gateway
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    print_status "✅ API Gateway is healthy"
else
    print_warning "⚠️ API Gateway health check failed (may need more time to start)"
fi

# Проверка Analytics API
if curl -f http://localhost:8002/health > /dev/null 2>&1; then
    print_status "✅ Analytics API is healthy"
else
    print_warning "⚠️ Analytics API health check failed (may need more time to start)"
fi

# Проверка ML Service
if curl -f http://localhost:8001/health > /dev/null 2>&1; then
    print_status "✅ ML Service is healthy"
else
    print_warning "⚠️ ML Service health check failed (may need more time to start)"
fi

# Проверка Frontend
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    print_status "✅ Frontend is healthy"
else
    print_warning "⚠️ Frontend health check failed (may need more time to start)"
fi

# Проверка Admin Dashboard
if curl -f http://localhost:8080 > /dev/null 2>&1; then
    print_status "✅ Admin Dashboard is healthy"
else
    print_warning "⚠️ Admin Dashboard health check failed (may need more time to start)"
fi

# Проверка Blockchain Node
if curl -f http://localhost:8545 > /dev/null 2>&1; then
    print_status "✅ Blockchain Node is healthy"
else
    print_warning "⚠️ Blockchain Node health check failed (may need more time to start)"
fi

print_status "🎉 Deployment completed for $ARCH!"
echo ""
echo "📱 Services:"
echo "   Frontend: http://localhost:3000"
echo "   API Gateway: http://localhost:8000"
echo "   Analytics API: http://localhost:8002"
echo "   ML Service: http://localhost:8001"
echo "   Admin Dashboard: http://localhost:8080"
echo ""
echo "📊 Monitoring:"
echo "   Grafana: http://localhost:3001 (admin/admin)"
echo "   Prometheus: http://localhost:9090"
echo "   Kong Admin: http://localhost:8001"
echo ""
echo "🗄️ Databases:"
echo "   PostgreSQL: localhost:5432"
echo "   ClickHouse: localhost:8123"
echo "   Redis: localhost:6379"
echo "   Kafka: localhost:9092"
echo ""
echo "🔗 Blockchain:"
echo "   Ethereum RPC: http://localhost:8545"
echo "   Ethereum WebSocket: ws://localhost:8546"
echo ""

# Показать логи
print_status "📝 Showing recent logs..."
docker-compose -f infrastructure/docker-compose.yml logs --tail=20 analytics-api ai-ml-service blockchain-node admin-dashboard

echo ""
print_status "To view all logs: docker-compose -f infrastructure/docker-compose.yml logs -f"
print_status "To stop services: docker-compose -f infrastructure/docker-compose.yml down"
print_status "To restart services: docker-compose -f infrastructure/docker-compose.yml restart"
print_status "Architecture: $ARCH"
