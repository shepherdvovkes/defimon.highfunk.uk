#!/bin/bash

# =============================================================================
# POLKADOT SHRIMP SERVER DEPLOYMENT SCRIPT
# Enhanced version with all parachains using official Docker images
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
POLKADOT_HOME="$HOME/polkadot"
INTERNAL_DATA_DIR="$HOME/polkadot-internal"
MIN_STORAGE_GB=10
RECOMMENDED_STORAGE_GB=50
MIN_RAM_GB=4
RECOMMENDED_RAM_GB=8

# Network configurations with official Docker images
NETWORKS="polkadot kusama westend moonbeam astar acala parallel bifrost hydradx centrifuge"

# Docker images for each network (official images)
POLKADOT_IMAGE="parity/polkadot:latest"
KUSAMA_IMAGE="parity/polkadot:latest"
WESTEND_IMAGE="parity/polkadot:latest"
MOONBEAM_IMAGE="purestake/moonbeam:latest"
ASTAR_IMAGE="staketechnologies/astar-collator:latest"
ACALA_IMAGE="acala/acala-node:latest"
PARALLEL_IMAGE="parallelfinance/parallel:latest"
BIFROST_IMAGE="thebifrost/bifrost-node:latest"
HYDRADX_IMAGE="galacticcouncil/hydra-dx:latest"
CENTRIFUGE_IMAGE="centrifugeio/centrifuge-chain:latest"

# Port configurations
POLKADOT_PORT="9944"
KUSAMA_PORT="9945"
WESTEND_PORT="9946"
MOONBEAM_PORT="9947"
ASTAR_PORT="9948"
ACALA_PORT="9949"
PARALLEL_PORT="9950"
BIFROST_PORT="9951"
HYDRADX_PORT="9952"
CENTRIFUGE_PORT="9953"

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

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Check system requirements
check_system_requirements() {
    print_header "Checking System Requirements"
    
    # Check OS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS. Detected OS: $OSTYPE"
        exit 1
    fi
    
    # Check available storage
    local available_storage=$(df -g / | awk 'NR==2 {print $4}')
    print_status "Available storage: ${available_storage}GB"
    
    if [ "$available_storage" -lt "$MIN_STORAGE_GB" ]; then
        print_error "Insufficient storage: ${available_storage}GB (minimum: ${MIN_STORAGE_GB}GB)"
        exit 1
    fi
    
    if [ "$available_storage" -lt "$RECOMMENDED_STORAGE_GB" ]; then
        print_warning "Low storage: ${available_storage}GB (recommended: ${RECOMMENDED_STORAGE_GB}GB)"
    fi
    
    # Check RAM
    local total_ram=$(sysctl -n hw.memsize | awk '{print $0/1024/1024/1024}')
    local total_ram_gb=$(printf "%.0f" "$total_ram")
    print_status "Total RAM: ${total_ram_gb}GB"
    
    if [ "$total_ram_gb" -lt "$MIN_RAM_GB" ]; then
        print_error "Insufficient RAM: ${total_ram_gb}GB (minimum: ${MIN_RAM_GB}GB)"
        exit 1
    fi
    
    if [ "$total_ram_gb" -lt "$RECOMMENDED_RAM_GB" ]; then
        print_warning "Low RAM: ${total_ram_gb}GB (recommended: ${RECOMMENDED_RAM_GB}GB)"
    fi
    
    print_status "System requirements check passed!"
}

# Install dependencies
install_dependencies() {
    print_header "Installing Dependencies"
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        print_warning "Homebrew not found. Please install it manually:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo "  Then add it to your PATH and run this script again."
        exit 1
    fi
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_warning "Docker not found. Please install Docker Desktop manually:"
        echo "  Visit: https://www.docker.com/products/docker-desktop"
        echo "  Download and install Docker Desktop for Mac"
        echo "  Then run this script again."
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker Desktop and try again."
        exit 1
    fi
    
    # Check if Docker Compose is available
    if ! command -v docker-compose &> /dev/null; then
        print_warning "Docker Compose not found. Installing..."
        brew install docker-compose
    fi
    
    print_status "Dependencies check passed!"
}

# Setup storage directories
setup_storage_directories() {
    print_header "Setting Up Storage Directories"
    
    # Create main directories on external USB
    mkdir -p "$POLKADOT_HOME"
    mkdir -p "$INTERNAL_DATA_DIR"
    
    # Create data directories for each network
    for network in $NETWORKS; do
        mkdir -p "$POLKADOT_HOME/data/$network"
        mkdir -p "$POLKADOT_HOME/chains/$network"
        print_status "Created directories for $network"
    done
    
    # Create monitoring directories
    mkdir -p "$POLKADOT_HOME/monitoring/prometheus"
    mkdir -p "$POLKADOT_HOME/monitoring/grafana/provisioning/datasources"
    mkdir -p "$POLKADOT_HOME/monitoring/grafana/provisioning/dashboards"
    
    print_status "Storage directories setup complete!"
}

# Create Docker Compose configuration
create_docker_compose() {
    print_header "Creating Docker Compose Configuration"
    
    cat > "$POLKADOT_HOME/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  # Polkadot Relay Chain
  polkadot:
    image: parity/polkadot:latest
    platform: linux/amd64
    container_name: polkadot-node
    ports:
      - "9944:9944"
    volumes:
      - ./data/polkadot:/polkadot/data
    command: >
      --chain polkadot
      --base-path /polkadot/data
      --name "Polkadot-Shrimp"
      --rpc-cors all
      --rpc-methods unsafe
      --rpc-external
      --prometheus-external
      --state-pruning=archive
      --blocks-pruning=archive
      --no-hardware-benchmarks
    restart: unless-stopped
    networks:
      - polkadot-network

  # Kusama
  kusama:
    image: parity/polkadot:latest
    platform: linux/amd64
    container_name: kusama-node
    ports:
      - "9945:9944"
    volumes:
      - ./data/kusama:/polkadot/data
    command: >
      --chain kusama
      --base-path /polkadot/data
      --name "Kusama-Shrimp"
      --rpc-cors all
      --rpc-methods unsafe
      --rpc-external
      --prometheus-external
      --state-pruning=archive
      --blocks-pruning=archive
      --no-hardware-benchmarks
    restart: unless-stopped
    networks:
      - polkadot-network

  # Westend Testnet
  westend:
    image: parity/polkadot:latest
    platform: linux/amd64
    container_name: westend-node
    ports:
      - "9946:9944"
    volumes:
      - ./data/westend:/polkadot/data
    command: >
      --chain westend
      --base-path /polkadot/data
      --name "Westend-Shrimp"
      --rpc-cors all
      --rpc-methods unsafe
      --rpc-external
      --prometheus-external
      --state-pruning=archive
      --blocks-pruning=archive
      --no-hardware-benchmarks
    restart: unless-stopped
    networks:
      - polkadot-network

  # Moonbeam
  moonbeam:
    image: purestake/moonbeam:latest
    platform: linux/amd64
    container_name: moonbeam-node
    ports:
      - "9947:9944"
    volumes:
      - ./data/moonbeam:/moonbeam/data
    command: >
      --chain moonbeam
      --base-path /moonbeam/data
      --name "Moonbeam-Shrimp"
      --rpc-cors all
      --rpc-methods unsafe
      --rpc-external
      --prometheus-external
      --state-pruning=archive
      --blocks-pruning=archive
      --no-hardware-benchmarks
    restart: unless-stopped
    networks:
      - polkadot-network

  # Astar
  astar:
    image: staketechnologies/astar-collator:latest
    platform: linux/amd64
    container_name: astar-node
    ports:
      - "9948:9944"
    volumes:
      - ./data/astar:/astar/data
    command: >
      --chain astar
      --base-path /astar/data
      --name "Astar-Shrimp"
      --rpc-cors all
      --rpc-methods unsafe
      --rpc-external
      --prometheus-external
      --state-pruning=archive
      --blocks-pruning=archive
      --no-hardware-benchmarks
    restart: unless-stopped
    networks:
      - polkadot-network

  # Acala
  acala:
    image: acala/acala-node:latest
    platform: linux/amd64
    container_name: acala-node
    ports:
      - "9949:9944"
    volumes:
      - ./data/acala:/acala/data
    command: >
      --chain acala
      --base-path /acala/data
      --name "Acala-Shrimp"
      --rpc-cors all
      --rpc-methods unsafe
      --rpc-external
      --prometheus-external
      --state-pruning=archive
      --blocks-pruning=archive
    restart: unless-stopped
    networks:
      - polkadot-network

  # Parallel Finance
  parallel:
    image: parallelfinance/parallel:latest
    platform: linux/amd64
    container_name: parallel-node
    ports:
      - "9950:9944"
    volumes:
      - ./data/parallel:/parallel/data
    command: >
      --chain parallel
      --base-path /parallel/data
      --name "Parallel-Shrimp"
      --rpc-cors all
      --rpc-methods unsafe
      --rpc-external
      --prometheus-external
      --state-pruning=archive
      --blocks-pruning=archive
    restart: unless-stopped
    networks:
      - polkadot-network

  # Bifrost
  bifrost:
    image: thebifrost/bifrost-node:latest
    platform: linux/amd64
    container_name: bifrost-node
    ports:
      - "9951:9944"
    volumes:
      - ./data/bifrost:/bifrost/data
    command: >
      --chain bifrost
      --base-path /bifrost/data
      --name "Bifrost-Shrimp"
      --rpc-cors all
      --rpc-methods unsafe
      --rpc-external
      --prometheus-external
      --state-pruning=archive
      --blocks-pruning=archive
    restart: unless-stopped
    networks:
      - polkadot-network

  # HydraDX
  hydradx:
    image: galacticcouncil/hydra-dx:latest
    platform: linux/amd64
    container_name: hydradx-node
    ports:
      - "9952:9944"
    volumes:
      - ./data/hydradx:/hydradx/data
    command: >
      --chain hydradx
      --base-path /hydradx/data
      --name "HydraDX-Shrimp"
      --rpc-cors all
      --rpc-methods unsafe
      --rpc-external
      --prometheus-external
      --state-pruning=archive
      --blocks-pruning=archive
    restart: unless-stopped
    networks:
      - polkadot-network

  # Centrifuge
  centrifuge:
    image: centrifugeio/centrifuge-chain:latest
    platform: linux/amd64
    container_name: centrifuge-node
    ports:
      - "9953:9944"
    volumes:
      - ./data/centrifuge:/centrifuge/data
    command: >
      --chain centrifuge
      --base-path /centrifuge/data
      --name "Centrifuge-Shrimp"
      --rpc-cors all
      --rpc-methods unsafe
      --rpc-external
      --prometheus-external
      --state-pruning=archive
      --blocks-pruning=archive
    restart: unless-stopped
    networks:
      - polkadot-network

  # Prometheus
  prometheus:
    image: prom/prometheus:latest
    container_name: polkadot-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    restart: unless-stopped
    networks:
      - polkadot-network

  # Grafana
  grafana:
    image: grafana/grafana:latest
    container_name: polkadot-grafana
    ports:
      - "3000:3000"
    volumes:
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    restart: unless-stopped
    networks:
      - polkadot-network

volumes:
  prometheus_data:
  grafana_data:

networks:
  polkadot-network:
    driver: bridge
EOF

    print_status "Docker Compose configuration created!"
}

# Create Prometheus configuration
create_prometheus_config() {
    print_header "Creating Prometheus Configuration"
    
    cat > "$POLKADOT_HOME/monitoring/prometheus/prometheus.yml" << 'EOF'
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

  - job_name: 'polkadot'
    static_configs:
      - targets: ['polkadot:9615']
    metrics_path: /metrics

  - job_name: 'kusama'
    static_configs:
      - targets: ['kusama:9615']
    metrics_path: /metrics

  - job_name: 'westend'
    static_configs:
      - targets: ['westend:9615']
    metrics_path: /metrics

  - job_name: 'moonbeam'
    static_configs:
      - targets: ['moonbeam:9615']
    metrics_path: /metrics

  - job_name: 'astar'
    static_configs:
      - targets: ['astar:9615']
    metrics_path: /metrics

  - job_name: 'acala'
    static_configs:
      - targets: ['acala:9615']
    metrics_path: /metrics

  - job_name: 'parallel'
    static_configs:
      - targets: ['parallel:9615']
    metrics_path: /metrics

  - job_name: 'bifrost'
    static_configs:
      - targets: ['bifrost:9615']
    metrics_path: /metrics

  - job_name: 'hydradx'
    static_configs:
      - targets: ['hydradx:9615']
    metrics_path: /metrics

  - job_name: 'centrifuge'
    static_configs:
      - targets: ['centrifuge:9615']
    metrics_path: /metrics

EOF

    print_status "Prometheus configuration created!"
}

# Create Grafana datasource configuration
create_grafana_datasource() {
    print_header "Creating Grafana Datasource Configuration"
    
    cat > "$POLKADOT_HOME/monitoring/grafana/provisioning/datasources/prometheus.yml" << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

    print_status "Grafana datasource configuration created!"
}

# Create Grafana dashboard configuration
create_grafana_dashboard() {
    print_header "Creating Grafana Dashboard Configuration"
    
    cat > "$POLKADOT_HOME/monitoring/grafana/provisioning/dashboards/polkadot-dashboard.json" << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Polkadot Networks Overview",
    "tags": ["polkadot"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Block Height",
        "type": "stat",
        "targets": [
          {
            "expr": "substrate_block_height",
            "legendFormat": "{{chain}}"
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
        "title": "Peers",
        "type": "stat",
        "targets": [
          {
            "expr": "substrate_peers_count",
            "legendFormat": "{{chain}}"
          }
        ]
      },
      {
        "id": 3,
        "title": "Sync Status",
        "type": "stat",
        "targets": [
          {
            "expr": "substrate_sync_state",
            "legendFormat": "{{chain}}"
          }
        ]
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
EOF

    print_status "Grafana dashboard configuration created!"
}

# Start services
start_services() {
    print_header "Starting Polkadot Services"
    
    cd "$POLKADOT_HOME"
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not available. Please install Docker Desktop and try again."
        exit 1
    fi
    
    # Pull images
    print_status "Pulling Docker images..."
    docker-compose pull
    
    # Start services
    print_status "Starting services..."
    docker-compose up -d
    
    print_status "Services started successfully!"
}

# Display final status
display_final_status() {
    print_header "Deployment Complete!"
    
    echo -e "${GREEN}✅ All Polkadot networks are now running in archive mode!${NC}"
    echo ""
    echo -e "${BLUE}🌐 Network Access Points:${NC}"
    echo "  • Polkadot Relay Chain: http://localhost:9944"
    echo "  • Kusama:              http://localhost:9945"
    echo "  • Westend Testnet:     http://localhost:9946"
    echo "  • Moonbeam:            http://localhost:9947"
    echo "  • Astar:               http://localhost:9948"
    echo "  • Acala:               http://localhost:9949"
    echo "  • Parallel Finance:    http://localhost:9950"
    echo "  • Bifrost:             http://localhost:9951"
    echo "  • HydraDX:             http://localhost:9952"
    echo "  • Centrifuge:          http://localhost:9953"
    echo ""
    echo -e "${BLUE}📊 Monitoring:${NC}"
    echo "  • Prometheus:          http://localhost:9090"
    echo "  • Grafana:             http://localhost:3000 (admin/admin)"
    echo ""
    echo -e "${BLUE}💾 Data Storage:${NC}"
    echo "  • External USB:        $POLKADOT_HOME"
    echo "  • Archive Mode:        ✅ Enabled (complete historical data)"
    echo ""
    echo -e "${YELLOW}⏳ Initial sync will take several hours to days depending on network size${NC}"
    echo -e "${YELLOW}📈 Monitor progress via Grafana dashboard${NC}"
    echo ""
    echo -e "${BLUE}🔧 Management Commands:${NC}"
    echo "  • View logs:           docker-compose logs -f [service-name]"
    echo "  • Stop services:       docker-compose down"
    echo "  • Restart services:    docker-compose restart"
    echo "  • Update images:       docker-compose pull && docker-compose up -d"
}

# Main execution
main() {
    print_header "Polkadot Shrimp Server Deployment"
    echo "This script will deploy all major Polkadot networks in archive mode"
    echo "for complete historical data access on your shrimp server."
    echo ""
    
    check_system_requirements
    install_dependencies
    setup_storage_directories
    create_docker_compose
    create_prometheus_config
    create_grafana_datasource
    create_grafana_dashboard
    start_services
    display_final_status
}

# Run main function
main "$@"
