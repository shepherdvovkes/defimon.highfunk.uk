#!/bin/bash

# L2 Analytics Server Deployment Script
# This script deploys a complete L2 analytics infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
L2_ANALYTICS_DIR="infrastructure/l2-analytics-server"
ENV_FILE=".env.l2analytics"

echo -e "${BLUE}🚀 Starting L2 Analytics Server Deployment${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install it and try again.${NC}"
    exit 1
fi

# Create environment file if it doesn't exist
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}📝 Creating environment file...${NC}"
    cat > "$ENV_FILE" << EOF
# L2 Analytics Server Environment Configuration

# Database Passwords
POSTGRES_PASSWORD=l2password_secure_$(openssl rand -hex 8)
CLICKHOUSE_PASSWORD=l2password_secure_$(openssl rand -hex 8)

# Grafana Configuration
GRAFANA_PASSWORD=admin_secure_$(openssl rand -hex 4)

# API Configuration
API_SECRET_KEY=$(openssl rand -hex 32)
JWT_SECRET=$(openssl rand -hex 32)

# Network Configuration
L2_NETWORKS=optimism,arbitrum_one,polygon_zkevm,base,zksync_era,starknet,linea,scroll,polygon_pos,bsc,avalanche,solana,mantle,metis,loopring

# Performance Configuration
L2_SYNC_INTERVAL=12
L2_BATCH_SIZE=100
L2_MAX_CONCURRENT_REQUESTS=20
L2_PRIORITY_THRESHOLD=6

# Monitoring Configuration
PROMETHEUS_RETENTION_DAYS=30
GRAFANA_ADMIN_EMAIL=admin@defimon.highfunk.uk
EOF
    echo -e "${GREEN}✅ Environment file created: $ENV_FILE${NC}"
fi

# Load environment variables
echo -e "${YELLOW}📋 Loading environment variables...${NC}"
export $(cat "$ENV_FILE" | grep -v '^#' | xargs)

# Create necessary directories
echo -e "${YELLOW}📁 Creating necessary directories...${NC}"
mkdir -p "$L2_ANALYTICS_DIR/grafana/dashboards"
mkdir -p "$L2_ANALYTICS_DIR/logs"
mkdir -p "$L2_ANALYTICS_DIR/data"

# Copy schema files
echo -e "${YELLOW}📋 Copying database schemas...${NC}"
cp infrastructure/l2_schema.sql "$L2_ANALYTICS_DIR/"
cp infrastructure/clickhouse_schema.sql "$L2_ANALYTICS_DIR/"
cp infrastructure/init.sql "$L2_ANALYTICS_DIR/"

# Build and start services
echo -e "${YELLOW}🔨 Building and starting services...${NC}"
cd "$L2_ANALYTICS_DIR"

# Pull latest images
echo -e "${BLUE}📥 Pulling latest Docker images...${NC}"
docker-compose pull

# Build custom images
echo -e "${BLUE}🔨 Building custom images...${NC}"
docker-compose build --no-cache

# Start services
echo -e "${BLUE}🚀 Starting L2 Analytics services...${NC}"
docker-compose up -d

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 30

# Check service health
echo -e "${YELLOW}🔍 Checking service health...${NC}"
for service in postgres clickhouse redis kafka l2_analytics_api admin_dashboard blockchain_node; do
    if docker-compose ps | grep -q "$service.*Up"; then
        echo -e "${GREEN}✅ $service is running${NC}"
    else
        echo -e "${RED}❌ $service is not running${NC}"
        docker-compose logs "$service"
    fi
done

# Initialize databases
echo -e "${YELLOW}🗄️ Initializing databases...${NC}"
docker-compose exec -T postgres psql -U l2user -d l2_analytics -c "SELECT version();" > /dev/null 2>&1 || {
    echo -e "${RED}❌ PostgreSQL initialization failed${NC}"
    docker-compose logs postgres
    exit 1
}

# Setup Grafana dashboards
echo -e "${YELLOW}📊 Setting up Grafana dashboards...${NC}"
sleep 10

# Create L2 Analytics Dashboard
cat > "$L2_ANALYTICS_DIR/grafana/dashboards/l2-analytics-dashboard.json" << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "L2 Analytics Dashboard",
    "tags": ["l2", "analytics", "defimon"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "L2 Networks Overview",
        "type": "stat",
        "targets": [
          {
            "expr": "l2_networks_total",
            "legendFormat": "Total Networks"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "displayMode": "list"
            }
          }
        }
      },
      {
        "id": 2,
        "title": "Blocks Processed per Network",
        "type": "timeseries",
        "targets": [
          {
            "expr": "rate(l2_blocks_processed_total[5m])",
            "legendFormat": "{{network}}"
          }
        ]
      },
      {
        "id": 3,
        "title": "Transactions per Second",
        "type": "timeseries",
        "targets": [
          {
            "expr": "rate(l2_transactions_processed_total[5m])",
            "legendFormat": "{{network}}"
          }
        ]
      },
      {
        "id": 4,
        "title": "Gas Fees (L2 vs L1)",
        "type": "timeseries",
        "targets": [
          {
            "expr": "l2_gas_fees_l2",
            "legendFormat": "L2 Gas - {{network}}"
          },
          {
            "expr": "l2_gas_fees_l1",
            "legendFormat": "L1 Gas - {{network}}"
          }
        ]
      },
      {
        "id": 5,
        "title": "Sync Status",
        "type": "table",
        "targets": [
          {
            "expr": "l2_sync_status",
            "format": "table"
          }
        ]
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "10s"
  }
}
EOF

# Wait for Grafana to be ready
echo -e "${YELLOW}⏳ Waiting for Grafana to be ready...${NC}"
until curl -s http://localhost:3001/api/health > /dev/null 2>&1; do
    echo -e "${YELLOW}⏳ Waiting for Grafana...${NC}"
    sleep 5
done

# Import dashboard
echo -e "${YELLOW}📊 Importing Grafana dashboard...${NC}"
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(curl -s -X POST -H "Content-Type: application/json" -d '{"name":"admin","email":"admin@defimon.highfunk.uk","login":"admin","password":"'$GRAFANA_PASSWORD'"}' http://localhost:3001/api/admin/users | jq -r '.key')" \
  -d @grafana/dashboards/l2-analytics-dashboard.json \
  http://localhost:3001/api/dashboards/db

# Display service URLs
echo -e "${GREEN}🎉 L2 Analytics Server deployment completed!${NC}"
echo -e "${BLUE}📊 Service URLs:${NC}"
echo -e "  • Admin Dashboard: ${GREEN}http://localhost:3000${NC}"
echo -e "  • Grafana: ${GREEN}http://localhost:3001${NC} (admin/$GRAFANA_PASSWORD)"
echo -e "  • API Gateway: ${GREEN}http://localhost:8443${NC}"
echo -e "  • Prometheus: ${GREEN}http://localhost:9090${NC}"
echo -e "  • Kong Admin: ${GREEN}http://localhost:8002${NC}"
echo -e "  • PostgreSQL: ${GREEN}localhost:5432${NC}"
echo -e "  • ClickHouse: ${GREEN}localhost:8123${NC}"
echo -e "  • Redis: ${GREEN}localhost:6379${NC}"
echo -e "  • Kafka: ${GREEN}localhost:9092${NC}"

echo -e "${BLUE}📋 Monitoring Commands:${NC}"
echo -e "  • View logs: ${YELLOW}cd $L2_ANALYTICS_DIR && docker-compose logs -f${NC}"
echo -e "  • Stop services: ${YELLOW}cd $L2_ANALYTICS_DIR && docker-compose down${NC}"
echo -e "  • Restart services: ${YELLOW}cd $L2_ANALYTICS_DIR && docker-compose restart${NC}"
echo -e "  • Check status: ${YELLOW}cd $L2_ANALYTICS_DIR && docker-compose ps${NC}"

echo -e "${GREEN}✅ L2 Analytics Server is ready for monitoring 50+ L2 networks!${NC}"
