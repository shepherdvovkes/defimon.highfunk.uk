#!/bin/bash

# 🚀 POLKADOT DEPLOYMENT SCRIPT - SHRIMP SERVER
# This script deploys Polkadot and multiple parachains on the shrimp server

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SHRIMP_HOST="shrimp"
POLKADOT_HOME="/opt/polkadot"
DATA_DIR="/Volumes/USB_APFS/polkadot-data"
INTERNAL_DATA_DIR="$HOME/polkadot-data"

# System requirements
MIN_RAM_GB=6
MIN_STORAGE_GB=100
RECOMMENDED_RAM_GB=8
RECOMMENDED_STORAGE_GB=200

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

# Function to check if we're on shrimp server
check_shrimp_server() {
    print_header "Checking Shrimp Server Connection"
    echo "======================================"
    
    if [[ "$(hostname)" == "shrimp" ]] || [[ "$(hostname)" == "shrimp.local" ]]; then
        print_success "Running on shrimp server"
        return 0
    fi
    
    print_error "This script must be run on the shrimp server"
    print_status "Please SSH to shrimp and run this script there"
    exit 1
}

# Function to check system requirements
check_system_requirements() {
    print_header "Checking System Requirements"
    echo "=================================="
    
    # Check available RAM
    local total_ram_gb=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
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
    
    # Check if external USB is available
    if [ -d "/Volumes/USB_APFS" ]; then
        local usb_storage_gb=$(df -BG /Volumes/USB_APFS | awk 'NR==2 {print $4}' | sed 's/G//')
        print_success "External USB storage available: ${usb_storage_gb}GB"
    else
        print_warning "External USB storage not found. Will use internal storage only."
    fi
    
    # Check CPU cores
    local cpu_cores=$(sysctl -n hw.ncpu)
    print_system "CPU cores: ${cpu_cores}"
    
    if [ "$cpu_cores" -lt 4 ]; then
        print_warning "Low CPU cores: ${cpu_cores}. Recommended: 4+ cores"
    else
        print_success "CPU cores sufficient: ${cpu_cores}"
    fi
}

# Function to install dependencies
install_dependencies() {
    print_header "Installing Dependencies"
    echo "==========================="
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        print_status "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install Docker Desktop
    if ! command -v docker &> /dev/null; then
        print_status "Installing Docker Desktop..."
        brew install --cask docker
        print_warning "Please start Docker Desktop manually and ensure it's running"
    else
        print_success "Docker is already installed"
    fi
    
    # Install Rust
    if ! command -v cargo &> /dev/null; then
        print_status "Installing Rust toolchain..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source ~/.cargo/env
    else
        print_success "Rust is already installed"
    fi
    
    # Install additional tools
    print_status "Installing additional tools..."
    brew install jq curl wget git node
    
    print_success "Dependencies installed successfully"
}

# Function to setup storage directories
setup_storage_directories() {
    print_header "Setting up Storage Directories"
    echo "==================================="
    
    # Create internal data directories
    print_status "Creating internal data directories..."
    mkdir -p "$INTERNAL_DATA_DIR"/{polkadot,kusama,westend}
    mkdir -p "$POLKADOT_HOME"/{config,logs,monitoring}
    
    # Create external USB data directories
    if [ -d "/Volumes/USB_APFS" ]; then
        print_status "Creating external USB data directories..."
        mkdir -p "$DATA_DIR"/{moonbeam,astar,acala,parallel,analytics}
    else
        print_warning "External USB not available, using internal storage for all data"
        mkdir -p "$INTERNAL_DATA_DIR"/{moonbeam,astar,acala,parallel,analytics}
        DATA_DIR="$INTERNAL_DATA_DIR"
    fi
    
    # Set permissions
    chmod 755 "$INTERNAL_DATA_DIR"
    chmod 755 "$POLKADOT_HOME"
    if [ -d "$DATA_DIR" ]; then
        chmod 755 "$DATA_DIR"
    fi
    
    print_success "Storage directories created successfully"
}

# Function to create Docker Compose configuration
create_docker_compose() {
    print_header "Creating Docker Compose Configuration"
    echo "=========================================="
    
    cat > "$POLKADOT_HOME/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  # Polkadot Relay Chain
  polkadot-relay:
    image: parity/polkadot:latest
    container_name: polkadot-relay
    restart: unless-stopped
    ports:
      - "9944:9944"   # WebSocket RPC
      - "30333:30333" # P2P
    volumes:
      - ./data/polkadot:/polkadot/data
    command: >
      --chain=polkadot
      --pruning=1000
      --rpc-cors=all
      --rpc-methods=unsafe
      --ws-external
      --rpc-external
      --prometheus-external
      --prometheus-port=9615
      --base-path=/polkadot/data
      --name=shrimp-polkadot
      --validator
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 1G
    networks:
      - polkadot-network

  # Kusama
  kusama:
    image: parity/polkadot:latest
    container_name: kusama
    restart: unless-stopped
    ports:
      - "9945:9944"   # WebSocket RPC
      - "30334:30333" # P2P
    volumes:
      - ./data/kusama:/polkadot/data
    command: >
      --chain=kusama
      --pruning=1000
      --rpc-cors=all
      --rpc-methods=unsafe
      --ws-external
      --rpc-external
      --prometheus-external
      --prometheus-port=9616
      --base-path=/polkadot/data
      --name=shrimp-kusama
      --validator
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1.5G
        reservations:
          cpus: '0.5'
          memory: 1G
    networks:
      - polkadot-network

  # Westend Testnet
  westend:
    image: parity/polkadot:latest
    container_name: westend
    restart: unless-stopped
    ports:
      - "9946:9944"   # WebSocket RPC
      - "30335:30333" # P2P
    volumes:
      - ./data/westend:/polkadot/data
    command: >
      --chain=westend
      --pruning=1000
      --rpc-cors=all
      --rpc-methods=unsafe
      --ws-external
      --rpc-external
      --prometheus-external
      --prometheus-port=9617
      --base-path=/polkadot/data
      --name=shrimp-westend
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 1G
        reservations:
          cpus: '0.25'
          memory: 512M
    networks:
      - polkadot-network

  # Moonbeam (Archive Node)
  moonbeam:
    image: purestake/moonbeam:latest
    container_name: moonbeam
    restart: unless-stopped
    ports:
      - "9947:9944"   # WebSocket RPC
      - "30336:30333" # P2P
    volumes:
      - /Volumes/USB_APFS/polkadot-data/moonbeam:/moonbeam/data
    command: >
      --chain=moonbeam
      --archive
      --rpc-cors=all
      --rpc-methods=unsafe
      --ws-external
      --rpc-external
      --prometheus-external
      --prometheus-port=9618
      --base-path=/moonbeam/data
      --name=shrimp-moonbeam
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 1G
        reservations:
          cpus: '0.25'
          memory: 512M
    networks:
      - polkadot-network

  # Astar (Archive Node)
  astar:
    image: astarnetwork/astar-collator:latest
    container_name: astar
    restart: unless-stopped
    ports:
      - "9948:9944"   # WebSocket RPC
      - "30337:30333" # P2P
    volumes:
      - /Volumes/USB_APFS/polkadot-data/astar:/astar/data
    command: >
      --chain=astar
      --archive
      --rpc-cors=all
      --rpc-methods=unsafe
      --ws-external
      --rpc-external
      --prometheus-external
      --prometheus-port=9619
      --base-path=/astar/data
      --name=shrimp-astar
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 1G
        reservations:
          cpus: '0.25'
          memory: 512M
    networks:
      - polkadot-network

  # Prometheus for monitoring
  prometheus:
    image: prom/prometheus:latest
    container_name: polkadot-prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
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
    networks:
      - polkadot-network

  # Grafana for dashboards
  grafana:
    image: grafana/grafana:latest
    container_name: polkadot-grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    networks:
      - polkadot-network

volumes:
  prometheus_data:
  grafana_data:

networks:
  polkadot-network:
    driver: bridge
EOF

    print_success "Docker Compose configuration created"
}

# Function to create monitoring configuration
create_monitoring_config() {
    print_header "Creating Monitoring Configuration"
    echo "======================================"
    
    # Create Prometheus configuration
    mkdir -p "$POLKADOT_HOME/monitoring"
    
    cat > "$POLKADOT_HOME/monitoring/prometheus.yml" << 'EOF'
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

  - job_name: 'polkadot-relay'
    static_configs:
      - targets: ['polkadot-relay:9615']

  - job_name: 'kusama'
    static_configs:
      - targets: ['kusama:9616']

  - job_name: 'westend'
    static_configs:
      - targets: ['westend:9617']

  - job_name: 'moonbeam'
    static_configs:
      - targets: ['moonbeam:9618']

  - job_name: 'astar'
    static_configs:
      - targets: ['astar:9619']
EOF

    # Create Grafana provisioning
    mkdir -p "$POLKADOT_HOME/monitoring/grafana/provisioning/datasources"
    mkdir -p "$POLKADOT_HOME/monitoring/grafana/provisioning/dashboards"
    
    cat > "$POLKADOT_HOME/monitoring/grafana/provisioning/datasources/prometheus.yml" << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

    print_success "Monitoring configuration created"
}

# Function to create environment configuration
create_environment_config() {
    print_header "Creating Environment Configuration"
    echo "========================================"
    
    cat > "$POLKADOT_HOME/.env" << 'EOF'
# Polkadot Networks Configuration
POLKADOT_SYNC_ENABLED=true
POLKADOT_NETWORKS=polkadot,kusama,westend,moonbeam,astar
POLKADOT_SYNC_INTERVAL=10
POLKADOT_BATCH_SIZE=20
POLKADOT_MAX_CONCURRENT_REQUESTS=5
POLKADOT_DATA_RETENTION_DAYS=90
POLKADOT_PRIORITY_THRESHOLD=5

# Database Configuration
DATABASE_URL=postgresql://postgres:password@localhost:5432/polkadot_analytics

# Redis Configuration
REDIS_URL=redis://localhost:6379

# Monitoring Configuration
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
METRICS_ENABLED=true

# Logging Configuration
RUST_LOG=info
LOG_LEVEL=info

# Security
JWT_SECRET=your_jwt_secret_here
API_KEY_SECRET=your_api_key_secret_here
EOF

    chmod 600 "$POLKADOT_HOME/.env"
    print_success "Environment configuration created"
}

# Function to create systemd services
create_systemd_services() {
    print_header "Creating Systemd Services"
    echo "=============================="
    
    # Create Polkadot service
    sudo tee /Library/LaunchDaemons/com.defimon.polkadot.plist > /dev/null << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.defimon.polkadot</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/docker-compose</string>
        <string>-f</string>
        <string>$POLKADOT_HOME/docker-compose.yml</string>
        <string>up</string>
        <string>-d</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$POLKADOT_HOME</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$POLKADOT_HOME/logs/polkadot.log</string>
    <key>StandardErrorPath</key>
    <string>$POLKADOT_HOME/logs/polkadot-error.log</string>
</dict>
</plist>
EOF

    # Load the service
    sudo launchctl load /Library/LaunchDaemons/com.defimon.polkadot.plist
    
    print_success "Systemd services created and loaded"
}

# Function to start services
start_services() {
    print_header "Starting Polkadot Services"
    echo "=============================="
    
    cd "$POLKADOT_HOME"
    
    # Start Docker Compose services
    print_status "Starting Docker Compose services..."
    docker-compose up -d
    
    # Wait for services to start
    print_status "Waiting for services to start..."
    sleep 30
    
    # Check service status
    print_status "Checking service status..."
    docker-compose ps
    
    print_success "Polkadot services started successfully"
}

# Function to create monitoring dashboard
create_monitoring_dashboard() {
    print_header "Creating Monitoring Dashboard"
    echo "=================================="
    
    cat > "$POLKADOT_HOME/monitoring/grafana/provisioning/dashboards/polkadot-dashboard.json" << 'EOF'
{
  "dashboard": {
    "title": "Polkadot Networks Monitoring",
    "panels": [
      {
        "title": "Polkadot Blocks Processed",
        "type": "stat",
        "targets": [
          {
            "expr": "polkadot_blocks_processed_total",
            "legendFormat": "{{network}}"
          }
        ]
      },
      {
        "title": "Polkadot Latest Block Number",
        "type": "stat",
        "targets": [
          {
            "expr": "polkadot_latest_block_number",
            "legendFormat": "{{network}}"
          }
        ]
      },
      {
        "title": "Polkadot Extrinsics Processed",
        "type": "stat",
        "targets": [
          {
            "expr": "polkadot_extrinsics_processed_total",
            "legendFormat": "{{network}}"
          }
        ]
      },
      {
        "title": "Polkadot Validators",
        "type": "stat",
        "targets": [
          {
            "expr": "polkadot_validators_total",
            "legendFormat": "{{network}}"
          }
        ]
      }
    ]
  }
}
EOF

    print_success "Monitoring dashboard created"
}

# Function to display final status
display_final_status() {
    print_header "Deployment Complete!"
    echo "====================="
    
    print_success "Polkadot deployment completed successfully!"
    echo ""
    print_status "Services deployed:"
    echo "  ✅ Polkadot Relay Chain (Port 9944)"
    echo "  ✅ Kusama (Port 9945)"
    echo "  ✅ Westend Testnet (Port 9946)"
    echo "  ✅ Moonbeam (Port 9947)"
    echo "  ✅ Astar (Port 9948)"
    echo "  ✅ Prometheus (Port 9090)"
    echo "  ✅ Grafana (Port 3000)"
    echo ""
    print_status "Access URLs:"
    echo "  🌐 Grafana Dashboard: http://localhost:3000 (admin/admin)"
    echo "  📊 Prometheus: http://localhost:9090"
    echo "  🔗 Polkadot RPC: ws://localhost:9944"
    echo "  🔗 Kusama RPC: ws://localhost:9945"
    echo "  🔗 Moonbeam RPC: ws://localhost:9947"
    echo ""
    print_status "Storage Usage:"
    echo "  🔥 Internal Storage: $INTERNAL_DATA_DIR"
    echo "  🌡️ External USB: $DATA_DIR"
    echo ""
    print_status "Next steps:"
    echo "  1. Access Grafana dashboard to monitor networks"
    echo "  2. Configure alerts in Prometheus"
    echo "  3. Integrate with existing analytics system"
    echo "  4. Set up automated backups"
}

# Main execution
main() {
    print_header "POLKADOT DEPLOYMENT - SHRIMP SERVER"
    echo "========================================="
    
    # Check if running on shrimp server
    check_shrimp_server
    
    # Check system requirements
    check_system_requirements
    
    # Install dependencies
    install_dependencies
    
    # Setup storage directories
    setup_storage_directories
    
    # Create Docker Compose configuration
    create_docker_compose
    
    # Create monitoring configuration
    create_monitoring_config
    
    # Create environment configuration
    create_environment_config
    
    # Create systemd services
    create_systemd_services
    
    # Start services
    start_services
    
    # Create monitoring dashboard
    create_monitoring_dashboard
    
    # Display final status
    display_final_status
}

# Run main function
main "$@"
