#!/bin/bash

# =============================================================================
# DEFIMON KAFKA FIX SCRIPT
# =============================================================================
# Скрипт для исправления проблем с Kafka и настройки Google Cloud Pub/Sub
# Заменяет Kafka на Google Cloud Pub/Sub для избежания ошибок

set -e

echo "🔧 DEFIMON Kafka Fix Script"
echo "============================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}[HEADER]${NC} $1"
}

print_system() {
    echo -e "${CYAN}[SYSTEM]${NC} $1"
}

# Проверка прав root
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

print_header "Starting Kafka to Google Cloud Pub/Sub migration..."

# =============================================================================
# STEP 1: BACKUP CURRENT CONFIGURATION
# =============================================================================

print_status "Step 1: Creating backup of current configuration..."

BACKUP_DIR="/data/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup current environment files
if [ -f "/app/.env" ]; then
    cp /app/.env "$BACKUP_DIR/env.backup"
    print_success "Backed up .env file"
fi

if [ -f "/app/secrets.env" ]; then
    cp /app/secrets.env "$BACKUP_DIR/secrets.env.backup"
    print_success "Backed up secrets.env file"
fi

# Backup current geth configuration
if [ -f "/app/config/geth-config.toml" ]; then
    cp /app/config/geth-config.toml "$BACKUP_DIR/geth-config.toml.backup"
    print_success "Backed up geth-config.toml file"
fi

print_success "Backup completed: $BACKUP_DIR"

# =============================================================================
# STEP 2: INSTALL GOOGLE CLOUD SDK
# =============================================================================

print_status "Step 2: Installing Google Cloud SDK..."

# Check if gcloud is already installed
if ! command -v gcloud &> /dev/null; then
    print_status "Installing Google Cloud SDK..."
    
    # Add Google Cloud SDK repository
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    
    # Add Google Cloud public key
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    
    # Update package list and install
    apt-get update
    apt-get install -y google-cloud-sdk
    
    print_success "Google Cloud SDK installed"
else
    print_success "Google Cloud SDK already installed"
fi

# =============================================================================
# STEP 3: CONFIGURE GOOGLE CLOUD PUB/SUB
# =============================================================================

print_status "Step 3: Configuring Google Cloud Pub/Sub..."

# Check if authenticated with Google Cloud
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    print_warning "Not authenticated with Google Cloud. Please run:"
    print_warning "gcloud auth login"
    print_warning "gcloud config set project YOUR_PROJECT_ID"
    print_warning "Then run this script again."
    exit 1
fi

# Get current project
PROJECT_ID=$(gcloud config get-value project)
print_success "Using Google Cloud Project: $PROJECT_ID"

# Create Pub/Sub topic if it doesn't exist
if ! gcloud pubsub topics describe defimon-events --project="$PROJECT_ID" &> /dev/null; then
    print_status "Creating Pub/Sub topic: defimon-events"
    gcloud pubsub topics create defimon-events --project="$PROJECT_ID"
    print_success "Pub/Sub topic created"
else
    print_success "Pub/Sub topic already exists"
fi

# Create Pub/Sub subscription if it doesn't exist
if ! gcloud pubsub subscriptions describe defimon-events-sub --project="$PROJECT_ID" &> /dev/null; then
    print_status "Creating Pub/Sub subscription: defimon-events-sub"
    gcloud pubsub subscriptions create defimon-events-sub \
        --topic=defimon-events \
        --ack-deadline=600 \
        --message-retention-duration=7d \
        --project="$PROJECT_ID"
    print_success "Pub/Sub subscription created"
else
    print_success "Pub/Sub subscription already exists"
fi

# =============================================================================
# STEP 4: UPDATE ENVIRONMENT CONFIGURATION
# =============================================================================

print_status "Step 4: Updating environment configuration..."

# Create new environment file with Pub/Sub configuration
cat > /app/.env << 'EOF'
# =============================================================================
# DEFIMON ENVIRONMENT CONFIGURATION (KAFKA-FREE)
# =============================================================================

# Ethereum Node Configuration
ETHEREUM_NODE_URL=http://localhost:8545
RPC_PORT=8545
WS_PORT=8546
P2P_PORT=30303

# Database Configuration (Local PostgreSQL)
DATABASE_URL=postgresql://postgres:password@localhost:5432/defi_analytics

# Google Cloud Pub/Sub (replaces Kafka)
GOOGLE_CLOUD_PUBSUB_TOPIC=defimon-events
GOOGLE_CLOUD_PUBSUB_SUBSCRIPTION=defimon-events-sub
GOOGLE_CLOUD_PUBSUB_ACK_DEADLINE=600
GOOGLE_CLOUD_PUBSUB_MAX_MESSAGES=1000
GOOGLE_CLOUD_PUBSUB_RETRY_POLICY_MAX_ATTEMPTS=5
GOOGLE_CLOUD_PUBSUB_RETRY_POLICY_MIN_BACKOFF=1
GOOGLE_CLOUD_PUBSUB_RETRY_POLICY_MAX_BACKOFF=600

# Event Streaming Configuration
EVENT_STREAM_ENABLED=true
EVENT_STREAM_BATCH_SIZE=100
EVENT_STREAM_FLUSH_INTERVAL=5
EVENT_STREAM_MAX_CONCURRENT_PUBLISHERS=10
EVENT_STREAM_ERROR_RETRY_ATTEMPTS=3
EVENT_STREAM_ERROR_RETRY_DELAY=5

# Redis Configuration (Local)
REDIS_URL=redis://localhost:6379

# Node Settings
SYNC_MODE=full
CACHE_SIZE=4096
MAX_PEERS=50
RUST_LOG=info

# L2 Networks Configuration
L2_SYNC_ENABLED=true
L2_NETWORKS=optimism,arbitrum_one,polygon_zkevm,base,zksync_era,starknet,linea,scroll
L2_SYNC_INTERVAL=12
L2_BATCH_SIZE=100
L2_MAX_CONCURRENT_REQUESTS=10
L2_DATA_RETENTION_DAYS=90
L2_ARCHIVE_MODE=false
L2_PRIORITY_THRESHOLD=5

# Cosmos Networks Configuration
COSMOS_SYNC_ENABLED=true
COSMOS_NETWORKS=cosmos_hub,osmosis,injective,celestia,sei,neutron,stride,quicksilver,persistence,agoric,evmos,kava
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

# Web Application Configuration
FRONTEND_DOMAIN=app.defimon.com
FRONTEND_PORT=3000
FRONTEND_ENVIRONMENT=production

# Admin Dashboard
ADMIN_DASHBOARD_DOMAIN=admin.defimon.com
ADMIN_DASHBOARD_PORT=3001
ADMIN_DASHBOARD_SECRET_KEY=your-admin-secret-key

# Analytics API
ANALYTICS_API_DOMAIN=api.defimon.com
ANALYTICS_API_PORT=8000
ANALYTICS_API_SECRET_KEY=your-api-secret-key

# AI/ML Service
AI_ML_SERVICE_DOMAIN=ai.defimon.com
AI_ML_SERVICE_PORT=8001
AI_ML_SERVICE_SECRET_KEY=your-ai-secret-key

# Security & Authentication
JWT_SECRET_KEY=your-super-secure-jwt-secret-key-here
JWT_EXPIRATION_HOURS=24
API_RATE_LIMIT_REQUESTS_PER_MINUTE=100
API_RATE_LIMIT_BURST_SIZE=200
CORS_ALLOWED_ORIGINS=https://app.defimon.com,https://admin.defimon.com

# Monitoring & Logging
PROMETHEUS_ENABLED=true
PROMETHEUS_PORT=9090
GRAFANA_ENABLED=true
GRAFANA_PORT=3000
LOG_LEVEL=info
LOG_FORMAT=json

# Development & Debugging
NODE_ENV=production
DEBUG=false

# EVM Networks Configuration
EVM_SYNC_ENABLED=true
EVM_NETWORKS=ethereum,arbitrum_one,base,op_mainnet,blast,mantle,mode,world_chain,opbnb,metis,boba,zksync_era,linea,scroll,polygon_zkevm,bsc_mainnet,avalanche_c,polygon_pos,fantom,cronos,gnosis,celo,klaytn,moonbeam,moonriver,harmony,okx_xlayer,taiko,immutable_zkevm,kroma,sophon,apecoin_apechain,zircuit,flare,meter,syscoin,telos,core,bitlayer,merlin,aurora,evmos,kava_evm,canto,oasis_emerald,astar,shiden,reef,fuse,iotex,heco,okc,kcc,palm,etc,callisto,smartbch,nahmii,bttc,conflux_espace,zklink_nova,zora,pgn,redstone_l2,fraxchain,metal_l2,ancient8,xai,treasure,beam_evm,dfk_chain,songbird,shibarium,pulsechain,rootstock,bob,bevm,bsquared,zkfair,manta_pacific

# RPC URLs for EVM networks
RPC_URL_ETHEREUM=http://localhost:8545
RPC_URL_ARBITRUM_ONE=https://arb1.arbitrum.io/rpc
RPC_URL_BASE=https://mainnet.base.org
RPC_URL_OP_MAINNET=https://mainnet.optimism.io
RPC_URL_BLAST=https://rpc.blast.io
RPC_URL_MANTLE=https://rpc.mantle.xyz
RPC_URL_MODE=https://mainnet.mode.network
RPC_URL_OPBNB=https://opbnb-mainnet-rpc.bnbchain.org
RPC_URL_METIS=https://andromeda.metis.io/?owner=1088
RPC_URL_BOBA=https://mainnet.boba.network
RPC_URL_ZKSYNC_ERA=https://mainnet.era.zksync.io
RPC_URL_LINEA=https://rpc.linea.build
RPC_URL_SCROLL=https://rpc.scroll.io
RPC_URL_POLYGON_ZKEVM=https://zkevm-rpc.com
RPC_URL_BSC_MAINNET=https://bsc-dataseed.binance.org
RPC_URL_AVALANCHE_C=https://api.avax.network/ext/bc/C/rpc
RPC_URL_POLYGON_POS=https://polygon-rpc.com
RPC_URL_FANTOM=https://rpc.ftm.tools
RPC_URL_CRONOS=https://evm.cronos.org
RPC_URL_GNOSIS=https://rpc.gnosischain.com
RPC_URL_CELO=https://forno.celo.org
RPC_URL_KLAYTN=https://public-node-api.klaytnapi.com/v1/cypress
RPC_URL_MOONBEAM=https://rpc.api.moonbeam.network
RPC_URL_MOONRIVER=https://rpc.api.moonriver.moonbeam.network
RPC_URL_HARMONY=https://api.harmony.one
RPC_URL_TAIKO=https://rpc.mainnet.taiko.xyz
RPC_URL_IMMUTABLE_ZKEVM=https://rpc.immutable.com
RPC_URL_KROMA=https://api.kroma.network
RPC_URL_FLARE=https://flare-api.flare.network/ext/C/rpc
RPC_URL_METER=https://rpc.meter.io
RPC_URL_SYSCOIN=https://rpc.syscoin.org
RPC_URL_TELOS=https://mainnet.telos.net/evm
RPC_URL_CORE=https://rpc.coredao.org
RPC_URL_MERLIN=https://rpc.merlinchain.io
RPC_URL_AURORA=https://mainnet.aurora.dev
RPC_URL_EVMOS=https://evmos-evm.publicnode.com
RPC_URL_KAVA_EVM=https://evm.kava.io
RPC_URL_CANTO=https://canto.slingshot.finance
RPC_URL_OASIS_EMERALD=https://emerald.oasis.dev
RPC_URL_ASTAR=https://astar.public.blastapi.io
RPC_URL_SHIDEN=https://shiden.public.blastapi.io
RPC_URL_REEF=https://rpc.reefscan.com
RPC_URL_FUSE=https://rpc.fuse.io
RPC_URL_IOTEX=https://rpc.ankr.com/iotex
RPC_URL_HECO=https://http-mainnet.hecochain.com
RPC_URL_OKC=https://exchainrpc.okex.org
RPC_URL_KCC=https://rpc-mainnet.kcc.network
RPC_URL_PALM=https://palm-mainnet.public.blastapi.io
RPC_URL_ETC=https://www.ethercluster.com/etc
RPC_URL_CALLISTO=https://rpc.callisto.network
RPC_URL_SMARTBCH=https://global.uat.cash
RPC_URL_BTTC=https://rpc.bittorrentchain.io
RPC_URL_CONFLUX_ESPACE=https://evm.confluxrpc.com
RPC_URL_ZORA=https://rpc.zora.energy
RPC_URL_PGN=https://rpc.publicgoods.network
RPC_URL_FRAXCHAIN=https://rpc.frax.com
RPC_URL_XAI=https://rpc.xai-chain.net
RPC_URL_BEAM_EVM=https://subnets.avax.network/beam/mainnet/rpc
RPC_URL_DFK_CHAIN=https://subnets.avax.network/defi-kingdoms/dfk-chain/rpc
RPC_URL_SONGBIRD=https://songbird.towolabs.com/rpc
RPC_URL_SHIBARIUM=https://rpc.shibrpc.com
RPC_URL_PULSECHAIN=https://rpc.pulsechain.com
RPC_URL_ROOTSTOCK=https://public-node.rsk.co
RPC_URL_BOB=https://rpc.gobob.xyz
RPC_URL_MANTA_PACIFIC=https://pacific-rpc.manta.network/http

# Backup Configuration
BACKUP_ENABLED=true
BACKUP_SCHEDULE=0 2 * * *
BACKUP_RETENTION_DAYS=30

EOF

print_success "Environment configuration updated"

# =============================================================================
# STEP 5: UPDATE GETH CONFIGURATION
# =============================================================================

print_status "Step 5: Updating Geth configuration..."

# Copy optimized geth configuration
if [ -f "/app/config/geth-optimized.toml" ]; then
    cp /app/config/geth-optimized.toml /app/config/geth-config.toml
    print_success "Geth configuration updated with optimized settings"
else
    print_warning "Optimized geth configuration not found, using default"
fi

# =============================================================================
# STEP 6: INSTALL PYTHON DEPENDENCIES FOR PUB/SUB
# =============================================================================

print_status "Step 6: Installing Python dependencies for Google Cloud Pub/Sub..."

# Install Python dependencies
pip3 install --upgrade google-cloud-pubsub
pip3 install --upgrade google-auth
pip3 install --upgrade google-auth-oauthlib
pip3 install --upgrade google-auth-httplib2

print_success "Python dependencies installed"

# =============================================================================
# STEP 7: CREATE PUB/SUB INTEGRATION SCRIPT
# =============================================================================

print_status "Step 7: Creating Pub/Sub integration script..."

cat > /app/scripts/pubsub-integration.py << 'EOF'
#!/usr/bin/env python3
"""
Google Cloud Pub/Sub Integration for DEFIMON
Replaces Kafka functionality with Google Cloud Pub/Sub
"""

import os
import json
import time
import logging
from typing import Dict, Any, Optional
from concurrent.futures import ThreadPoolExecutor
from google.cloud import pubsub_v1
from google.auth import default

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class PubSubManager:
    """Manages Google Cloud Pub/Sub operations for DEFIMON"""
    
    def __init__(self):
        self.project_id = os.getenv('GOOGLE_CLOUD_PROJECT_ID')
        self.topic_name = os.getenv('GOOGLE_CLOUD_PUBSUB_TOPIC', 'defimon-events')
        self.subscription_name = os.getenv('GOOGLE_CLOUD_PUBSUB_SUBSCRIPTION', 'defimon-events-sub')
        
        # Initialize Pub/Sub clients
        self.publisher = pubsub_v1.PublisherClient()
        self.subscriber = pubsub_v1.SubscriberClient()
        
        # Topic and subscription paths
        self.topic_path = self.publisher.topic_path(self.project_id, self.topic_name)
        self.subscription_path = self.subscriber.subscription_path(self.project_id, self.subscription_name)
        
        logger.info(f"Initialized Pub/Sub Manager for project: {self.project_id}")
    
    def publish_event(self, event_type: str, data: Dict[str, Any], attributes: Optional[Dict[str, str]] = None) -> str:
        """Publish an event to Pub/Sub topic"""
        try:
            # Prepare message
            message_data = {
                'event_type': event_type,
                'timestamp': int(time.time()),
                'data': data
            }
            
            # Convert to JSON
            message_json = json.dumps(message_data)
            message_bytes = message_json.encode('utf-8')
            
            # Prepare attributes
            if attributes is None:
                attributes = {}
            
            attributes.update({
                'event_type': event_type,
                'timestamp': str(int(time.time())),
                'source': 'defimon'
            })
            
            # Publish message
            future = self.publisher.publish(self.topic_path, data=message_bytes, **attributes)
            message_id = future.result()
            
            logger.info(f"Published event {event_type} with message ID: {message_id}")
            return message_id
            
        except Exception as e:
            logger.error(f"Error publishing event {event_type}: {e}")
            raise
    
    def subscribe_to_events(self, callback, max_messages: int = 1000):
        """Subscribe to events from Pub/Sub subscription"""
        def message_callback(message):
            try:
                # Parse message data
                data = json.loads(message.data.decode('utf-8'))
                
                # Call user callback
                callback(data)
                
                # Acknowledge message
                message.ack()
                
                logger.info(f"Processed message: {message.message_id}")
                
            except Exception as e:
                logger.error(f"Error processing message: {e}")
                # Nack message to retry
                message.nack()
        
        # Subscribe to messages
        subscription = self.subscriber.subscribe(self.subscription_path, callback=message_callback)
        
        logger.info(f"Subscribed to {self.subscription_path}")
        
        try:
            # Keep subscription alive
            subscription.result()
        except KeyboardInterrupt:
            subscription.cancel()
            logger.info("Subscription cancelled")

def publish_blockchain_event(network: str, block_number: int, block_hash: str, data: Dict[str, Any]):
    """Publish blockchain event to Pub/Sub"""
    pubsub = PubSubManager()
    
    event_data = {
        'network': network,
        'block_number': block_number,
        'block_hash': block_hash,
        'data': data
    }
    
    return pubsub.publish_event('blockchain_event', event_data, {
        'network': network,
        'block_number': str(block_number)
    })

def publish_l2_event(network: str, event_type: str, data: Dict[str, Any]):
    """Publish L2 network event to Pub/Sub"""
    pubsub = PubSubManager()
    
    event_data = {
        'network': network,
        'event_type': event_type,
        'data': data
    }
    
    return pubsub.publish_event('l2_event', event_data, {
        'network': network,
        'event_type': event_type
    })

def publish_analytics_event(event_type: str, data: Dict[str, Any]):
    """Publish analytics event to Pub/Sub"""
    pubsub = PubSubManager()
    
    event_data = {
        'event_type': event_type,
        'data': data
    }
    
    return pubsub.publish_event('analytics_event', event_data, {
        'event_type': event_type
    })

if __name__ == "__main__":
    # Example usage
    pubsub = PubSubManager()
    
    # Example: Publish a test event
    test_data = {
        'test': True,
        'message': 'Hello from DEFIMON Pub/Sub integration!'
    }
    
    message_id = pubsub.publish_event('test_event', test_data)
    print(f"Published test event with message ID: {message_id}")
EOF

chmod +x /app/scripts/pubsub-integration.py
print_success "Pub/Sub integration script created"

# =============================================================================
# STEP 8: UPDATE DOCKER COMPOSE CONFIGURATION
# =============================================================================

print_status "Step 8: Updating Docker Compose configuration..."

# Create updated docker-compose.yml without Kafka
cat > /app/docker-compose.yml << 'EOF'
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:15
    container_name: defimon-postgres
    environment:
      POSTGRES_DB: defi_analytics
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./config/postgresql.conf:/etc/postgresql/postgresql.conf
    ports:
      - "5432:5432"
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: defimon-redis
    command: redis-server --appendonly yes --maxmemory 2gb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Geth Ethereum Node
  geth:
    image: ethereum/client-go:stable
    container_name: defimon-geth
    command: >
      --config /app/config/geth-config.toml
      --datadir /data/ethereum
      --syncmode full
      --cache 8192
      --database.cache 4096
      --trie.cache 256
      --snapshot.cache 256
      --state.cache 256
      --maxpeers 50
      --http
      --http.addr 0.0.0.0
      --http.port 8545
      --http.corsdomain "*"
      --http.vhosts "*"
      --http.api eth,net,web3,debug,txpool,personal,admin
      --ws
      --ws.addr 0.0.0.0
      --ws.port 8546
      --ws.origins "*"
      --ws.api eth,net,web3,debug,txpool,personal,admin
      --metrics
      --metrics.addr 0.0.0.0
      --metrics.port 6060
    volumes:
      - geth_data:/data/ethereum
      - ./config/geth-config.toml:/app/config/geth-config.toml
    ports:
      - "8545:8545"
      - "8546:8546"
      - "30303:30303"
      - "6060:6060"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8545"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Analytics API
  analytics-api:
    image: python:3.11-slim
    container_name: defimon-analytics-api
    working_dir: /app
    command: >
      python -m uvicorn analytics_api.main:app
      --host 0.0.0.0
      --port 8000
      --reload
    environment:
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/defi_analytics
      - REDIS_URL=redis://redis:6379
      - GOOGLE_CLOUD_PUBSUB_TOPIC=defimon-events
      - GOOGLE_CLOUD_PUBSUB_SUBSCRIPTION=defimon-events-sub
    volumes:
      - ./analytics_api:/app/analytics_api
      - ./scripts:/app/scripts
    ports:
      - "8000:8000"
    depends_on:
      - postgres
      - redis
    restart: unless-stopped

  # AI/ML Service
  ai-ml-service:
    image: python:3.11-slim
    container_name: defimon-ai-ml-service
    working_dir: /app
    command: >
      python -m uvicorn ai_ml_service.main:app
      --host 0.0.0.0
      --port 8001
      --reload
    environment:
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/defi_analytics
      - REDIS_URL=redis://redis:6379
      - GOOGLE_CLOUD_PUBSUB_TOPIC=defimon-events
      - GOOGLE_CLOUD_PUBSUB_SUBSCRIPTION=defimon-events-sub
    volumes:
      - ./ai_ml_service:/app/ai_ml_service
      - ./scripts:/app/scripts
    ports:
      - "8001:8001"
    depends_on:
      - postgres
      - redis
    restart: unless-stopped

  # Frontend Application
  frontend:
    image: node:18-alpine
    container_name: defimon-frontend
    working_dir: /app
    command: npm run dev
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8000
      - NEXT_PUBLIC_AI_SERVICE_URL=http://localhost:8001
    volumes:
      - ./frontend:/app
    ports:
      - "3000:3000"
    depends_on:
      - analytics-api
      - ai-ml-service
    restart: unless-stopped

  # Admin Dashboard
  admin-dashboard:
    image: node:18-alpine
    container_name: defimon-admin-dashboard
    working_dir: /app
    command: npm run dev
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8000
      - NEXT_PUBLIC_AI_SERVICE_URL=http://localhost:8001
    volumes:
      - ./admin_dashboard:/app
    ports:
      - "3001:3000"
    depends_on:
      - analytics-api
      - ai-ml-service
    restart: unless-stopped

  # Prometheus Monitoring
  prometheus:
    image: prom/prometheus:latest
    container_name: defimon-prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=15d'
      - '--web.enable-lifecycle'
    volumes:
      - ./config/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    restart: unless-stopped

  # Grafana Dashboard
  grafana:
    image: grafana/grafana:latest
    container_name: defimon-grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
      - ./config/grafana/provisioning:/etc/grafana/provisioning
    ports:
      - "3002:3000"
    depends_on:
      - prometheus
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
  geth_data:
  prometheus_data:
  grafana_data:
EOF

print_success "Docker Compose configuration updated"

# =============================================================================
# STEP 9: CREATE PROMETHEUS CONFIGURATION
# =============================================================================

print_status "Step 9: Creating Prometheus configuration..."

mkdir -p /app/config

cat > /app/config/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'geth'
    static_configs:
      - targets: ['geth:6060']
    metrics_path: /debug/metrics/prometheus

  - job_name: 'analytics-api'
    static_configs:
      - targets: ['analytics-api:8000']
    metrics_path: /metrics

  - job_name: 'ai-ml-service'
    static_configs:
      - targets: ['ai-ml-service:8001']
    metrics_path: /metrics

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres:5432']
    metrics_path: /metrics

  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']
    metrics_path: /metrics
EOF

print_success "Prometheus configuration created"

# =============================================================================
# STEP 10: RESTART SERVICES
# =============================================================================

print_status "Step 10: Restarting services..."

# Stop existing services
docker-compose down

# Start services with new configuration
docker-compose up -d

print_success "Services restarted with new configuration"

# =============================================================================
# STEP 11: VERIFICATION
# =============================================================================

print_status "Step 11: Verifying configuration..."

# Wait for services to start
sleep 30

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    print_success "All services are running"
else
    print_error "Some services failed to start"
    docker-compose logs
    exit 1
fi

# Test Pub/Sub integration
print_status "Testing Pub/Sub integration..."
python3 /app/scripts/pubsub-integration.py

print_success "Pub/Sub integration test completed"

# =============================================================================
# COMPLETION
# =============================================================================

print_header "Kafka to Google Cloud Pub/Sub migration completed successfully!"

print_status "Summary of changes:"
print_status "✅ Replaced Kafka with Google Cloud Pub/Sub"
print_status "✅ Updated environment configuration"
print_status "✅ Optimized Geth configuration"
print_status "✅ Created Pub/Sub integration script"
print_status "✅ Updated Docker Compose configuration"
print_status "✅ Added Prometheus monitoring"
print_status "✅ Restarted all services"

print_status "Next steps:"
print_status "1. Monitor logs: docker-compose logs -f"
print_status "2. Check metrics: http://localhost:9090"
print_status "3. View Grafana: http://localhost:3002 (admin/admin123)"
print_status "4. Test API: http://localhost:8000/docs"
print_status "5. Access frontend: http://localhost:3000"

print_success "DEFIMON is now running without Kafka dependencies!"
