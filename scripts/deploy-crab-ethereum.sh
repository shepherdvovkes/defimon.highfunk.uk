#!/bin/bash

# DEFIMON Ethereum Full Node Deployment to Crab Server with API Integration
# This script deploys the Ethereum full node setup to the crab server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ETHEREUM_DIR="$PROJECT_ROOT/infrastructure/ethereum-node"

# API Keys
ETHERSCAN_API_KEY="753BZTQQDZ1B6TYNDUPQAZHPDWSMWXUXGQ"
INFURA_API_KEY="69a45c7511e54941925b96c368f1f9a3"

# Crab server configuration
CRAB_HOST="crab"
CRAB_USER="vovkes"

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

# Function to verify JWT files
verify_jwt_files() {
    print_status "Verifying JWT files..."
    
    if [ ! -f "$ETHEREUM_DIR/jwtsecret.raw" ]; then
        print_error "Geth JWT file (jwtsecret.raw) not found!"
        return 1
    fi
    
    if [ ! -f "$ETHEREUM_DIR/jwtsecret.hex" ]; then
        print_error "Lighthouse JWT file (jwtsecret.hex) not found!"
        return 1
    fi
    
    # Check file sizes
    local geth_size=$(wc -c < "$ETHEREUM_DIR/jwtsecret.raw")
    local lighthouse_size=$(wc -c < "$ETHEREUM_DIR/jwtsecret.hex")
    
    if [ "$geth_size" -eq 32 ]; then
        print_success "Geth JWT file size: $geth_size bytes ✓"
    else
        print_error "Geth JWT file size: $geth_size bytes ✗ (expected 32)"
        return 1
    fi
    
    if [ "$lighthouse_size" -eq 65 ]; then  # 64 chars + newline
        print_success "Lighthouse JWT file size: $lighthouse_size bytes ✓"
    else
        print_error "Lighthouse JWT file size: $lighthouse_size bytes ✗ (expected 65)"
        return 1
    fi
    
    print_success "JWT files verified successfully"
}

# Function to copy files to crab server
copy_files_to_crab() {
    print_status "Copying files to crab server..."
    
    # Copy JWT secret
    scp "$ETHEREUM_DIR/jwtsecret.raw" "$CRAB_USER@$CRAB_HOST:/tmp/"
    
    # Create setup script with API integration
    cat > /tmp/setup-crab-ethereum-node.sh << 'EOF'
#!/bin/bash

# DEFIMON Ethereum Full Node Setup for Crab Server with API Integration
# This script sets up Geth (execution client) and Lighthouse (consensus client)
# for a full Ethereum mainnet node on the crab server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
ETHEREUM_HOME="/home/vovkes/ethereum"
GETH_DATA_DIR="/home/vovkes/ethereum/geth"
LIGHTHOUSE_DATA_DIR="/home/vovkes/ethereum/lighthouse"
JWT_SECRET_FILE="/home/vovkes/ethereum/jwtsecret"

# API Keys
ETHERSCAN_API_KEY="753BZTQQDZ1B6TYNDUPQAZHPDWSMWXUXGQ"
INFURA_API_KEY="69a45c7511e54941925b96c368f1f9a3"

# System requirements
MIN_RAM_GB=16
MIN_STORAGE_GB=1000
RECOMMENDED_RAM_GB=32
RECOMMENDED_STORAGE_GB=2000

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

# Function to check system requirements
check_system_requirements() {
    print_header "Checking System Requirements"
    echo "=================================="
    
    # Check if we're on the crab server
    if [[ "$(hostname)" != "crab" ]]; then
        print_error "This script must be run on the crab server"
        exit 1
    fi
    
    # Check available RAM
    local total_ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    print_system "Total RAM: ${total_ram_gb}GB"
    
    if [ "$total_ram_gb" -lt "$MIN_RAM_GB" ]; then
        print_error "Insufficient RAM: ${total_ram_gb}GB (minimum: ${MIN_RAM_GB}GB)"
        exit 1
    elif [ "$total_ram_gb" -lt "$RECOMMENDED_RAM_GB" ]; then
        print_warning "RAM is below recommended: ${total_ram_gb}GB (recommended: ${RECOMMENDED_RAM_GB}GB)"
    else
        print_success "RAM is sufficient: ${total_ram_gb}GB"
    fi
    
    # Check available storage
    local available_storage_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    print_system "Available storage on root: ${available_storage_gb}GB"
    
    if [ "$available_storage_gb" -lt "$MIN_STORAGE_GB" ]; then
        print_error "Insufficient storage: ${available_storage_gb}GB (minimum: ${MIN_STORAGE_GB}GB)"
        exit 1
    elif [ "$available_storage_gb" -lt "$RECOMMENDED_STORAGE_GB" ]; then
        print_warning "Storage is below recommended: ${available_storage_gb}GB (recommended: ${RECOMMENDED_STORAGE_GB}GB)"
    else
        print_success "Storage is sufficient: ${available_storage_gb}GB"
    fi
    
    # Check if data disks are available
    print_system "Checking available disks..."
    lsblk -f
    
    # Check if sda1 and sdb1 are available for data storage
    if [ -b "/dev/sda1" ] && [ -b "/dev/sdb1" ]; then
        print_success "Data disks sda1 and sdb1 are available"
        
        # Check if they're mounted
        if ! mountpoint -q /mnt/sda1 2>/dev/null; then
            print_warning "sda1 is not mounted, will mount to /mnt/sda1"
        fi
        
        if ! mountpoint -q /mnt/sdb1 2>/dev/null; then
            print_warning "sdb1 is not mounted, will mount to /mnt/sdb1"
        fi
    else
        print_warning "Data disks not found, will use root filesystem"
    fi
}

# Function to setup data directories and mount points
setup_data_directories() {
    print_header "Setting up Data Directories"
    echo "================================"
    
    # Create mount points if they don't exist
    sudo mkdir -p /mnt/sda1 /mnt/sdb1
    
    # Mount data disks if not already mounted
    if ! mountpoint -q /mnt/sda1; then
        print_status "Mounting sda1 to /mnt/sda1..."
        sudo mount /dev/sda1 /mnt/sda1
        print_success "sda1 mounted successfully"
    fi
    
    if ! mountpoint -q /mnt/sdb1; then
        print_status "Mounting sdb1 to /mnt/sdb1..."
        sudo mount /dev/sdb1 /mnt/sdb1
        print_success "sdb1 mounted successfully"
    fi
    
    # Create ethereum directories
    mkdir -p "$ETHEREUM_HOME"
    mkdir -p "$GETH_DATA_DIR"
    mkdir -p "$LIGHTHOUSE_DATA_DIR"
    
    # Create symbolic links to use data disks
    if [ -d "/mnt/sda1" ] && [ -d "/mnt/sdb1" ]; then
        print_status "Setting up symbolic links to data disks..."
        
        # Use sda1 for Geth data
        if [ ! -L "$GETH_DATA_DIR" ]; then
            rm -rf "$GETH_DATA_DIR"
            ln -s /mnt/sda1/geth "$GETH_DATA_DIR"
            print_success "Geth data directory linked to /mnt/sda1/geth"
        fi
        
        # Use sdb1 for Lighthouse data
        if [ ! -L "$LIGHTHOUSE_DATA_DIR" ]; then
            rm -rf "$LIGHTHOUSE_DATA_DIR"
            ln -s /mnt/sdb1/lighthouse "$LIGHTHOUSE_DATA_DIR"
            print_success "Lighthouse data directory linked to /mnt/sdb1/lighthouse"
        fi
    fi
    
    print_success "Data directories setup completed"
}

# Function to install system dependencies
install_system_dependencies() {
    print_header "Installing System Dependencies"
    echo "===================================="
    
    # Update package list
    print_status "Updating package list..."
    sudo apt update
    
    # Install required packages
    print_status "Installing required packages..."
    sudo apt install -y \
        curl \
        wget \
        git \
        build-essential \
        pkg-config \
        libssl-dev \
        libclang-dev \
        cmake \
        docker.io \
        docker-compose \
        htop \
        iotop \
        nethogs \
        jq \
        screen \
        tmux \
        python3 \
        python3-pip \
        nodejs \
        npm
    
    # Start and enable Docker
    print_status "Starting Docker service..."
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add user to docker group
    sudo usermod -aG docker "$USER"
    print_success "User added to docker group (log out and back in for changes to take effect)"
    
    print_success "System dependencies installed"
}

# Function to setup JWT secret
setup_jwt_secret() {
    print_header "Setting up JWT Secret"
    echo "=========================="
    
    # Copy JWT secret from uploaded file
    if [ -f "/tmp/jwtsecret.raw" ]; then
        cp "/tmp/jwtsecret.raw" "$JWT_SECRET_FILE"
        chmod 600 "$JWT_SECRET_FILE"
        print_success "JWT secret copied from uploaded file"
    else
        # Generate new JWT secret
        print_status "Generating new JWT secret..."
        openssl rand -hex 32 | tr -d '\n' > "$JWT_SECRET_FILE"
        chmod 600 "$JWT_SECRET_FILE"
        print_success "New JWT secret generated"
    fi
    
    print_success "JWT secret setup completed"
}

# Function to create environment file with API keys
create_environment_file() {
    print_header "Creating Environment Configuration"
    echo "======================================="
    
    cat > "$ETHEREUM_HOME/.env" << EOF
# Ethereum Node Configuration
ETHEREUM_HOME=$ETHEREUM_HOME
GETH_DATA_DIR=$GETH_DATA_DIR
LIGHTHOUSE_DATA_DIR=$LIGHTHOUSE_DATA_DIR

# API Keys
ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY
INFURA_API_KEY=$INFURA_API_KEY

# Network Configuration
NETWORK=mainnet
GETH_HTTP_PORT=8545
GETH_WS_PORT=8546
LIGHTHOUSE_HTTP_PORT=5052
LIGHTHOUSE_P2P_PORT=9000

# Docker Configuration
DOCKER_COMPOSE_FILE=$ETHEREUM_HOME/docker-compose.yml
EOF
    
    chmod 600 "$ETHEREUM_HOME/.env"
    print_success "Environment configuration created"
}

# Function to create Docker Compose configuration with API integration
create_docker_compose() {
    print_header "Creating Docker Compose Configuration"
    echo "==========================================="
    
    cat > "$ETHEREUM_HOME/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  geth:
    image: ethereum/client-go:latest
    container_name: ethereum-geth
    restart: unless-stopped
    ports:
      - "8545:8545"   # HTTP RPC
      - "8546:8546"   # WebSocket RPC
      - "30303:30303" # P2P
      - "30303:30303/udp" # P2P UDP
    volumes:
      - geth-data:/root/.ethereum
      - ./jwtsecret:/root/.ethereum/jwtsecret:ro
    environment:
      - ETHERSCAN_API_KEY=${ETHERSCAN_API_KEY}
      - INFURA_API_KEY=${INFURA_API_KEY}
    command: >
      --mainnet
      --datadir /root/.ethereum
      --http
      --http.addr 0.0.0.0
      --http.port 8545
      --http.corsdomain "*"
      --http.vhosts "*"
      --http.api eth,net,web3,debug,txpool,engine
      --ws
      --ws.addr 0.0.0.0
      --ws.port 8546
      --ws.api eth,net,web3
      --authrpc.addr 0.0.0.0
      --authrpc.port 8551
      --authrpc.vhosts "*"
      --authrpc.jwtsecret /root/.ethereum/jwtsecret
      --syncmode snap
      --cache 8192
      --maxpeers 50
      --metrics
      --metrics.addr 0.0.0.0
      --metrics.port 6060
      --verbosity 3
    networks:
      - ethereum
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8545"]
      interval: 30s
      timeout: 10s
      retries: 3

  lighthouse:
    image: sigp/lighthouse:latest
    container_name: ethereum-lighthouse
    restart: unless-stopped
    ports:
      - "5052:5052"   # HTTP API
      - "9000:9000"   # P2P
      - "9000:9000/udp" # P2P UDP
    volumes:
      - lighthouse-data:/root/.lighthouse
      - ./jwtsecret:/root/.lighthouse/jwtsecret:ro
    environment:
      - ETHERSCAN_API_KEY=${ETHERSCAN_API_KEY}
      - INFURA_API_KEY=${INFURA_API_KEY}
    command: >
      lighthouse bn
      --network mainnet
      --datadir /root/.lighthouse
      --http
      --http-address 0.0.0.0
      --http-port 5052
      --http-allow-origin "*"
      --execution-jwt /root/.lighthouse/jwtsecret
      --execution-endpoint http://geth:8551
      --checkpoint-sync-url https://sync-mainnet.beaconcha.in
      --disable-deposit-contract-sync
      --validator-monitor-auto
      --metrics
      --metrics-address 0.0.0.0
      --metrics-port 5054
      --port 9000
      --discovery-port 9000
      --target-peers 50
      --logfile-max-number 5
      --logfile-max-size 200
      --logfile-compress
    networks:
      - ethereum
    depends_on:
      - geth
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5052/eth/v1/node/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # API Integration Service
  api-integration:
    image: node:18-alpine
    container_name: ethereum-api-integration
    restart: unless-stopped
    ports:
      - "3000:3000"   # API Integration service
    volumes:
      - ./api-integration:/app
      - ./logs:/app/logs
    working_dir: /app
    environment:
      - ETHERSCAN_API_KEY=${ETHERSCAN_API_KEY}
      - INFURA_API_KEY=${INFURA_API_KEY}
      - GETH_RPC_URL=http://geth:8545
      - LIGHTHOUSE_RPC_URL=http://lighthouse:5052
    command: >
      sh -c "
        npm install &&
        npm start
      "
    networks:
      - ethereum
    depends_on:
      - geth
      - lighthouse

volumes:
  geth-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/vovkes/ethereum/geth
  lighthouse-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/vovkes/ethereum/lighthouse

networks:
  ethereum:
    driver: bridge
EOF
    
    print_success "Docker Compose configuration created"
}

# Function to create API integration service
create_api_integration_service() {
    print_header "Creating API Integration Service"
    echo "======================================"
    
    # Create API integration directory
    mkdir -p "$ETHEREUM_HOME/api-integration"
    mkdir -p "$ETHEREUM_HOME/logs"
    
    # Create package.json
    cat > "$ETHEREUM_HOME/api-integration/package.json" << 'EOF'
{
  "name": "ethereum-api-integration",
  "version": "1.0.0",
  "description": "Ethereum API Integration Service",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "axios": "^1.6.0",
    "web3": "^4.2.0",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "morgan": "^1.10.0",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF
    
    # Create server.js
    cat > "$ETHEREUM_HOME/api-integration/server.js" << 'EOF'
const express = require('express');
const axios = require('axios');
const Web3 = require('web3');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Environment variables
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
const INFURA_API_KEY = process.env.INFURA_API_KEY;
const GETH_RPC_URL = process.env.GETH_RPC_URL || 'http://localhost:8545';
const LIGHTHOUSE_RPC_URL = process.env.LIGHTHOUSE_RPC_URL || 'http://localhost:5052';

// Initialize Web3
const web3 = new Web3(GETH_RPC_URL);

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// Logging setup
const logDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
}

const logStream = fs.createWriteStream(path.join(logDir, 'api.log'), { flags: 'a' });
app.use(morgan('combined', { stream: logStream }));

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Ethereum node status
app.get('/status', async (req, res) => {
    try {
        const [gethSyncing, lighthouseSyncing, currentBlock] = await Promise.all([
            web3.eth.isSyncing(),
            axios.get(`${LIGHTHOUSE_RPC_URL}/eth/v1/node/syncing`).catch(() => ({ data: { data: { is_syncing: true } } })),
            web3.eth.getBlockNumber()
        ]);

        res.json({
            geth: {
                syncing: gethSyncing,
                currentBlock: currentBlock.toString(),
                connected: true
            },
            lighthouse: {
                syncing: lighthouseSyncing.data.data.is_syncing,
                connected: true
            },
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Etherscan API proxy
app.get('/etherscan/:endpoint', async (req, res) => {
    try {
        const { endpoint } = req.params;
        const { ...queryParams } = req.query;
        
        const url = `https://api.etherscan.io/api`;
        const params = {
            ...queryParams,
            apikey: ETHERSCAN_API_KEY
        };

        const response = await axios.get(url, { params });
        res.json(response.data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Infura API proxy
app.get('/infura/:endpoint', async (req, res) => {
    try {
        const { endpoint } = req.params;
        const { ...queryParams } = req.query;
        
        const url = `https://mainnet.infura.io/v3/${INFURA_API_KEY}/${endpoint}`;
        const response = await axios.get(url, { params: queryParams });
        res.json(response.data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Block information
app.get('/block/:blockNumber', async (req, res) => {
    try {
        const { blockNumber } = req.params;
        const block = await web3.eth.getBlock(blockNumber, true);
        res.json(block);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Transaction information
app.get('/tx/:txHash', async (req, res) => {
    try {
        const { txHash } = req.params;
        const tx = await web3.eth.getTransaction(txHash);
        const receipt = await web3.eth.getTransactionReceipt(txHash);
        
        res.json({
            transaction: tx,
            receipt: receipt
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Gas price
app.get('/gas', async (req, res) => {
    try {
        const gasPrice = await web3.eth.getGasPrice();
        res.json({
            gasPrice: gasPrice.toString(),
            gasPriceGwei: web3.utils.fromWei(gasPrice, 'gwei')
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Network stats
app.get('/network', async (req, res) => {
    try {
        const [peerCount, gasPrice, blockNumber] = await Promise.all([
            web3.eth.net.getPeerCount(),
            web3.eth.getGasPrice(),
            web3.eth.getBlockNumber()
        ]);

        res.json({
            peerCount: peerCount.toString(),
            gasPrice: gasPrice.toString(),
            gasPriceGwei: web3.utils.fromWei(gasPrice, 'gwei'),
            blockNumber: blockNumber.toString(),
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Error handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

// Start server
app.listen(PORT, () => {
    console.log(`Ethereum API Integration Service running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
    console.log(`Node status: http://localhost:${PORT}/status`);
});
EOF
    
    print_success "API integration service created"
}

# Function to create systemd service
create_systemd_service() {
    print_header "Creating Systemd Service"
    echo "============================="
    
    cat > /tmp/ethereum-node.service << EOF
[Unit]
Description=DEFIMON Ethereum Full Node with API Integration
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$ETHEREUM_HOME
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
    
    sudo cp /tmp/ethereum-node.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable ethereum-node.service
    
    print_success "Systemd service created and enabled"
}

# Function to create enhanced monitoring script
create_monitoring_script() {
    print_header "Creating Enhanced Monitoring Script"
    echo "========================================="
    
    cat > "$ETHEREUM_HOME/monitor.sh" << 'EOF'
#!/bin/bash

# DEFIMON Ethereum Node Monitor with API Integration
# Run this script to monitor the sync status of Geth and Lighthouse

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

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

# Check container status
echo "=== Container Status ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(geth|lighthouse|api-integration)" || echo "No containers found"

# Check Geth sync status
echo ""
echo "=== Geth Sync Status ==="
if docker exec ethereum-geth geth attach --exec "eth.syncing" 2>/dev/null | grep -q "false"; then
    print_success "Geth is fully synced"
    CURRENT_BLOCK=$(docker exec ethereum-geth geth attach --exec "eth.blockNumber" 2>/dev/null | tr -d '\n')
    print_status "Current block: $CURRENT_BLOCK"
else
    SYNC_STATUS=$(docker exec ethereum-geth geth attach --exec "eth.syncing" 2>/dev/null)
    print_warning "Geth is syncing: $SYNC_STATUS"
fi

# Check Lighthouse sync status
echo ""
echo "=== Lighthouse Sync Status ==="
LIGHTHOUSE_SYNC=$(curl -s http://localhost:5052/eth/v1/node/syncing 2>/dev/null || echo "API not accessible")
if [[ "$LIGHTHOUSE_SYNC" == *"false"* ]]; then
    print_success "Lighthouse is fully synced"
    HEAD_SLOT=$(curl -s http://localhost:5052/eth/v1/beacon/headers/head 2>/dev/null | jq -r '.data.header.message.slot' 2>/dev/null || echo "0")
    print_status "Current head slot: $HEAD_SLOT"
else
    print_warning "Lighthouse sync status: $LIGHTHOUSE_SYNC"
fi

# Check API Integration service
echo ""
echo "=== API Integration Service ==="
API_STATUS=$(curl -s http://localhost:3000/health 2>/dev/null || echo "Service not accessible")
if [[ "$API_STATUS" == *"healthy"* ]]; then
    print_success "API Integration service is running"
    
    # Get network stats
    NETWORK_STATS=$(curl -s http://localhost:3000/network 2>/dev/null || echo "{}")
    if [[ "$NETWORK_STATS" != "{}" ]]; then
        PEER_COUNT=$(echo "$NETWORK_STATS" | jq -r '.peerCount' 2>/dev/null || echo "0")
        GAS_PRICE=$(echo "$NETWORK_STATS" | jq -r '.gasPriceGwei' 2>/dev/null || echo "0")
        print_status "Peer count: $PEER_COUNT"
        print_status "Gas price: ${GAS_PRICE} Gwei"
    fi
else
    print_warning "API Integration service: $API_STATUS"
fi

# Check disk usage
echo ""
echo "=== Disk Usage ==="
df -h /mnt/sda1 /mnt/sdb1 / 2>/dev/null || df -h /

# Check memory usage
echo ""
echo "=== Memory Usage ==="
free -h

# Check recent logs
echo ""
echo "=== Recent Geth Logs ==="
docker logs ethereum-geth --tail 5 2>/dev/null || echo "No logs available"

echo ""
echo "=== Recent Lighthouse Logs ==="
docker logs ethereum-lighthouse --tail 5 2>/dev/null || echo "No logs available"

echo ""
echo "=== Recent API Integration Logs ==="
docker logs ethereum-api-integration --tail 5 2>/dev/null || echo "No logs available"

# API Endpoints summary
echo ""
echo "=== Available API Endpoints ==="
echo "• Health check: http://localhost:3000/health"
echo "• Node status: http://localhost:3000/status"
echo "• Network stats: http://localhost:3000/network"
echo "• Gas price: http://localhost:3000/gas"
echo "• Block info: http://localhost:3000/block/{blockNumber}"
echo "• Transaction info: http://localhost:3000/tx/{txHash}"
echo "• Etherscan proxy: http://localhost:3000/etherscan/{endpoint}"
echo "• Infura proxy: http://localhost:3000/infura/{endpoint}"
EOF
    
    chmod +x "$ETHEREUM_HOME/monitor.sh"
    print_success "Enhanced monitoring script created"
}

# Function to start the Ethereum node
start_ethereum_node() {
    print_header "Starting Ethereum Node with API Integration"
    echo "================================================"
    
    # Start services
    print_status "Starting Docker Compose services..."
    cd "$ETHEREUM_HOME"
    docker-compose up -d
    
    # Wait for services to start
    print_status "Waiting for services to start..."
    sleep 60
    
    # Check status
    print_status "Checking service status..."
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(geth|lighthouse|api-integration)"
    
    print_success "Ethereum node with API integration started successfully"
}

# Function to show setup summary
show_setup_summary() {
    echo ""
    print_header "Ethereum Full Node Setup Summary with API Integration"
    echo "=========================================================="
    echo "✓ System requirements verified"
    echo "✓ Data directories created"
    echo "✓ System dependencies installed"
    echo "✓ JWT secret configured"
    echo "✓ Environment configuration created"
    echo "✓ Docker Compose configuration created"
    echo "✓ API integration service created"
    echo "✓ Systemd service configured"
    echo "✓ Enhanced monitoring script created"
    echo "✓ Ethereum node with API integration started"
    echo ""
    print_success "Ethereum full node with API integration is now running on crab server!"
    echo ""
    echo "Important Information:"
    echo "====================="
    echo "• Geth data directory: $GETH_DATA_DIR"
    echo "• Lighthouse data directory: $LIGHTHOUSE_DATA_DIR"
    echo "• JWT secret file: $JWT_SECRET_FILE"
    echo "• Environment file: $ETHEREUM_HOME/.env"
    echo "• Docker Compose file: $ETHEREUM_HOME/docker-compose.yml"
    echo "• API Integration service: http://localhost:3000"
    echo "• Monitoring script: $ETHEREUM_HOME/monitor.sh"
    echo ""
    echo "API Endpoints:"
    echo "============="
    echo "• Health check: http://localhost:3000/health"
    echo "• Node status: http://localhost:3000/status"
    echo "• Network stats: http://localhost:3000/network"
    echo "• Gas price: http://localhost:3000/gas"
    echo "• Block info: http://localhost:3000/block/{blockNumber}"
    echo "• Transaction info: http://localhost:3000/tx/{txHash}"
    echo "• Etherscan proxy: http://localhost:3000/etherscan/{endpoint}"
    echo "• Infura proxy: http://localhost:3000/infura/{endpoint}"
    echo ""
    echo "Useful Commands:"
    echo "==============="
    echo "• Monitor sync status: $ETHEREUM_HOME/monitor.sh"
    echo "• View Geth logs: docker logs -f ethereum-geth"
    echo "• View Lighthouse logs: docker logs -f ethereum-lighthouse"
    echo "• View API logs: docker logs -f ethereum-api-integration"
    echo "• Stop services: cd $ETHEREUM_HOME && docker-compose down"
    echo "• Start services: cd $ETHEREUM_HOME && docker-compose up -d"
    echo "• Check systemd service: sudo systemctl status ethereum-node"
    echo ""
    print_warning "Initial sync will take several days to complete!"
    print_warning "Monitor the sync progress regularly using the monitoring script."
    echo ""
    print_success "API integration is ready to use with Etherscan and Infura!"
}

# Main function
main() {
    print_header "DEFIMON Ethereum Full Node Setup for Crab Server with API Integration"
    echo "======================================================================="
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        exit 1
    fi
    
    # Check system requirements
    check_system_requirements
    
    # Setup data directories
    setup_data_directories
    
    # Install system dependencies
    install_system_dependencies
    
    # Setup JWT secret
    setup_jwt_secret
    
    # Create environment file
    create_environment_file
    
    # Create Docker Compose configuration
    create_docker_compose
    
    # Create API integration service
    create_api_integration_service
    
    # Create systemd service
    create_systemd_service
    
    # Create enhanced monitoring script
    create_monitoring_script
    
    # Start Ethereum node
    start_ethereum_node
    
    # Show setup summary
    show_setup_summary
}

# Run main function
main "$@"
EOF
    
    # Copy setup script to crab server
    scp /tmp/setup-crab-ethereum-node.sh "$CRAB_USER@$CRAB_HOST:/tmp/"
    
    print_success "Files copied to crab server successfully"
}

# Function to deploy on crab server
deploy_on_crab() {
    print_status "Deploying Ethereum node with API integration on crab server..."
    
    ssh "$CRAB_USER@$CRAB_HOST" << 'EOF'
        # Make script executable and run it
        chmod +x /tmp/setup-crab-ethereum-node.sh
        cd /tmp
        ./setup-crab-ethereum-node.sh
EOF
    
    print_success "Deployment completed on crab server!"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment on crab server..."
    
    ssh "$CRAB_USER@$CRAB_HOST" << 'EOF'
        echo "=== Container Status ==="
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(geth|lighthouse|api-integration)"
        
        echo ""
        echo "=== Service Health ==="
        # Check if Geth is responding
        if docker exec ethereum-geth curl -s http://localhost:8545 > /dev/null 2>&1; then
            echo "✓ Geth HTTP endpoint is responding"
        else
            echo "✗ Geth HTTP endpoint is not responding"
        fi
        
        # Check if Lighthouse is responding
        if docker exec ethereum-lighthouse curl -s http://localhost:5052 > /dev/null 2>&1; then
            echo "✓ Lighthouse HTTP endpoint is responding"
        else
            echo "✗ Lighthouse HTTP endpoint is not responding"
        fi
        
        # Check if API Integration service is responding
        if curl -s http://localhost:3000/health > /dev/null 2>&1; then
            echo "✓ API Integration service is responding"
        else
            echo "✗ API Integration service is not responding"
        fi
        
        echo ""
        echo "=== API Endpoints Test ==="
        curl -s http://localhost:3000/health | jq . 2>/dev/null || echo "Health endpoint not accessible"
        
        echo ""
        echo "=== Environment Configuration ==="
        if [ -f "/home/vovkes/ethereum/.env" ]; then
            echo "✓ Environment file exists"
            echo "API Keys configured:"
            grep -E "(ETHERSCAN_API_KEY|INFURA_API_KEY)" /home/vovkes/ethereum/.env | sed 's/=.*/=***/'
        else
            echo "✗ Environment file not found"
        fi
EOF
    
    print_success "Deployment verification completed!"
}

# Function to show deployment summary
show_deployment_summary() {
    echo ""
    print_header "Ethereum Node Deployment Summary with API Integration"
    echo "=========================================================="
    echo "✓ JWT files verified locally"
    echo "✓ Files copied to crab server"
    echo "✓ Ethereum node with API integration deployed"
    echo "✓ Deployment verified"
    echo ""
    print_success "Ethereum full node with API integration is now running on crab server!"
    echo ""
    echo "API Integration Features:"
    echo "========================"
    echo "• Etherscan API integration for blockchain data"
    echo "• Infura API integration for enhanced connectivity"
    echo "• RESTful API endpoints for easy access"
    echo "• Real-time network statistics"
    echo "• Transaction and block information"
    echo "• Gas price monitoring"
    echo ""
    echo "Available Endpoints:"
    echo "==================="
    echo "• Health check: http://crab:3000/health"
    echo "• Node status: http://crab:3000/status"
    echo "• Network stats: http://crab:3000/network"
    echo "• Gas price: http://crab:3000/gas"
    echo "• Block info: http://crab:3000/block/{blockNumber}"
    echo "• Transaction info: http://crab:3000/tx/{txHash}"
    echo "• Etherscan proxy: http://crab:3000/etherscan/{endpoint}"
    echo "• Infura proxy: http://crab:3000/infura/{endpoint}"
    echo ""
    echo "Next steps:"
    echo "1. Monitor sync status: ssh crab '/home/vovkes/ethereum/monitor.sh'"
    echo "2. Check API integration: curl http://crab:3000/health"
    echo "3. View logs: ssh crab 'docker logs -f ethereum-api-integration'"
    echo "4. Test Etherscan integration: curl 'http://crab:3000/etherscan/account?address=0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6'"
    echo "5. Test Infura integration: curl 'http://crab:3000/infura/eth_blockNumber'"
}

# Main function
main() {
    print_header "DEFIMON Ethereum Full Node Deployment to Crab Server with API Integration"
    echo "============================================================================="
    
    # Verify JWT files
    verify_jwt_files
    
    # Copy files to crab server
    copy_files_to_crab
    
    # Deploy on crab server
    deploy_on_crab
    
    # Verify deployment
    verify_deployment
    
    # Show deployment summary
    show_deployment_summary
}

# Run main function
main "$@"
