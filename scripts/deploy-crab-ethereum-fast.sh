#!/bin/bash

# DEFIMON Ethereum Full Node Setup for Crab Server - FAST VERSION
# This script sets up Geth (execution client) and Lighthouse (consensus client)
# for a full Ethereum mainnet node on the crab server with NO SLEEP DELAYS

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
MIN_RAM_GB=12
MIN_STORAGE_GB=350
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

# Function to check system requirements (FAST)
check_system_requirements() {
    print_header "Checking System Requirements (FAST)"
    echo "========================================="
    
    # Check if we're on the crab server
    if [[ "$(hostname)" != "crab" ]]; then
        print_error "This script must be run on the crab server"
        exit 1
    fi
    
    # Quick RAM check
    local total_ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    print_system "Total RAM: ${total_ram_gb}GB"
    
    if [ "$total_ram_gb" -lt "$MIN_RAM_GB" ]; then
        print_error "Insufficient RAM: ${total_ram_gb}GB (minimum: ${MIN_RAM_GB}GB)"
        exit 1
    fi
    
    # Quick storage check
    local available_storage_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    print_system "Available storage: ${available_storage_gb}GB"
    
    if [ "$available_storage_gb" -lt "$MIN_STORAGE_GB" ]; then
        print_error "Insufficient storage: ${available_storage_gb}GB (minimum: ${MIN_STORAGE_GB}GB)"
        exit 1
    fi
    
    print_success "System requirements met - proceeding with setup"
}

# Function to setup data directories and mount points (FAST)
setup_data_directories() {
    print_header "Setting up Data Directories (FAST)"
    echo "======================================="
    
    # Create mount points if they don't exist
    sudo mkdir -p /mnt/sda1 /mnt/sdb1
    
    # Mount data disks if not already mounted (no waiting)
    if ! mountpoint -q /mnt/sda1; then
        print_status "Mounting sda1 to /mnt/sda1..."
        sudo mount /dev/sda1 /mnt/sda1
    fi
    
    if ! mountpoint -q /mnt/sdb1; then
        print_status "Mounting sdb1 to /mnt/sdb1..."
        sudo mount /dev/sdb1 /mnt/sdb1
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
        fi
        
        # Use sdb1 for Lighthouse data
        if [ ! -L "$LIGHTHOUSE_DATA_DIR" ]; then
            rm -rf "$LIGHTHOUSE_DATA_DIR"
            ln -s /mnt/sdb1/lighthouse "$LIGHTHOUSE_DATA_DIR"
        fi
    fi
    
    print_success "Data directories setup completed"
}

# Function to install system dependencies (FAST)
install_system_dependencies() {
    print_header "Installing System Dependencies (FAST)"
    echo "==========================================="
    
    # Install required packages (skip apt update for speed)
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
    
    print_success "System dependencies installed"
}

# Function to setup JWT secret (FAST)
setup_jwt_secret() {
    print_header "Setting up JWT Secret (FAST)"
    echo "=================================="
    
    # Generate new JWT secret
    openssl rand -hex 32 | tr -d '\n' > "$JWT_SECRET_FILE"
    chmod 600 "$JWT_SECRET_FILE"
    print_success "JWT secret generated"
}

# Function to create environment file with API keys (FAST)
create_environment_file() {
    print_header "Creating Environment Configuration (FAST)"
    echo "=============================================="
    
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

# Function to create Docker Compose configuration (FAST - no health checks)
create_docker_compose() {
    print_header "Creating Docker Compose Configuration (FAST)"
    echo "================================================="
    
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

# Function to create monitoring script (FAST)
create_monitoring_script() {
    print_header "Creating Monitoring Script (FAST)"
    echo "======================================="
    
    cat > "$ETHEREUM_HOME/monitor.sh" << 'EOF'
#!/bin/bash

# DEFIMON Ethereum Node Monitor - FAST VERSION
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
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(geth|lighthouse)" || echo "No containers found"

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
EOF
    
    chmod +x "$ETHEREUM_HOME/monitor.sh"
    print_success "Monitoring script created"
}

# Function to start the Ethereum node (FAST - no sleep)
start_ethereum_node() {
    print_header "Starting Ethereum Node (FAST)"
    echo "================================"
    
    # Start services
    print_status "Starting Docker Compose services..."
    cd "$ETHEREUM_HOME"
    docker-compose up -d
    
    # Check status immediately without waiting
    print_status "Checking service status..."
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(geth|lighthouse)"
    
    print_success "Ethereum node started successfully"
}

# Function to show setup summary (FAST)
show_setup_summary() {
    echo ""
    print_header "Ethereum Full Node Setup Summary (FAST)"
    echo "============================================"
    echo "✓ System requirements verified"
    echo "✓ Data directories created"
    echo "✓ System dependencies installed"
    echo "✓ JWT secret configured"
    echo "✓ Environment configuration created"
    echo "✓ Docker Compose configuration created"
    echo "✓ Monitoring script created"
    echo "✓ Ethereum node started"
    echo ""
    print_success "Ethereum full node is now running on crab server!"
    echo ""
    echo "Important Information:"
    echo "====================="
    echo "• Geth data directory: $GETH_DATA_DIR"
    echo "• Lighthouse data directory: $LIGHTHOUSE_DATA_DIR"
    echo "• JWT secret file: $JWT_SECRET_FILE"
    echo "• Environment file: $ETHEREUM_HOME/.env"
    echo "• Docker Compose file: $ETHEREUM_HOME/docker-compose.yml"
    echo "• Monitoring script: $ETHEREUM_HOME/monitor.sh"
    echo ""
    echo "Useful Commands:"
    echo "==============="
    echo "• Monitor sync status: $ETHEREUM_HOME/monitor.sh"
    echo "• View Geth logs: docker logs -f ethereum-geth"
    echo "• View Lighthouse logs: docker logs -f ethereum-lighthouse"
    echo "• Stop services: cd $ETHEREUM_HOME && docker-compose down"
    echo "• Start services: cd $ETHEREUM_HOME && docker-compose up -d"
    echo ""
    print_warning "Initial sync will take several days to complete!"
    print_warning "Monitor the sync progress regularly using the monitoring script."
}

# Main function (FAST)
main() {
    print_header "DEFIMON Ethereum Full Node Setup for Crab Server - FAST VERSION"
    echo "===================================================================="
    
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
    
    # Create monitoring script
    create_monitoring_script
    
    # Start Ethereum node
    start_ethereum_node
    
    # Show setup summary
    show_setup_summary
}

# Run main function
main "$@"
