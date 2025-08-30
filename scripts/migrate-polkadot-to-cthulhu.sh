#!/bin/bash

# Polkadot Migration Script: Localhost -> Cthulhu
# This script migrates all Polkadot-related containers from localhost to Cthulhu

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CTHULHU_HOST="cthulhu.local"
CTHULHU_USER="vovkes"
CTHULHU_SSH_KEY="~/.ssh/cthulhu"
CTHULHU_PROJECT_DIR="/Users/vovkes/defimon.highfunk.uk"

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
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to stop containers on localhost
stop_local_containers() {
    print_header "Stopping Polkadot containers on localhost"
    
    local containers=(
        "polkadot-node"
        "kusama-node"
        "westend-node"
        "parallel-node"
        "centrifuge-node"
        "moonbeam-node"
        "acala-node"
        "hydradx-node"
        "polkadot-prometheus"
        "polkadot-grafana"
    )
    
    for container in "${containers[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
            print_status "Stopping $container..."
            docker stop "$container"
            print_status "Removing $container..."
            docker rm "$container"
        else
            print_warning "Container $container not found or already stopped"
        fi
    done
}

# Function to create docker-compose file on Cthulhu
create_cthulhu_compose() {
    print_header "Creating docker-compose.yml on Cthulhu"
    
    ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "cd $CTHULHU_PROJECT_DIR && cat > docker-compose-polkadot.yml << 'EOF'
version: '3.8'

services:
  # Polkadot Node
  polkadot-node:
    image: parity/polkadot:latest
    container_name: polkadot-node
    restart: unless-stopped
    platform: linux/amd64
    ports:
      - \"9944:9944\"
    volumes:
      - /Users/vovkes/polkadot-data:/polkadot/data
    command: >
      --chain polkadot
      --base-path /polkadot/data
      --name Polkadot-Shrimp
      --rpc-cors all
      --rpc-methods unsafe
      --rpc-external
      --prometheus-external
      --state-pruning=archive
      --blocks-pruning=archive
      --no-hardware-benchmarks
    deploy:
      resources:
        limits:
          cpus: '4.0'
          memory: 4G
        reservations:
          cpus: '2.0'
          memory: 2G

  # Kusama Node
  kusama-node:
    image: parity/polkadot:latest
    container_name: kusama-node
    restart: unless-stopped
    platform: linux/amd64
    ports:
      - \"9945:9944\"
    volumes:
      - /Users/vovkes/kusama-data:/polkadot/data
    command: >
      --chain kusama
      --base-path /polkadot/data
      --name Kusama-Shrimp
      --rpc-cors all
      --rpc-methods unsafe
      --rpc-external
      --prometheus-external
      --state-pruning=archive
      --blocks-pruning=archive
      --no-hardware-benchmarks
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G

  # Westend Node
  westend-node:
    image: parity/polkadot:latest
    container_name: westend-node
    restart: unless-stopped
    platform: linux/amd64
    ports:
      - \"9946:9944\"
    volumes:
      - /Users/vovkes/westend-data:/polkadot/data
    command: >
      --chain westend
      --base-path /polkadot/data
      --name Westend-Shrimp
      --rpc-cors all
      --rpc-methods unsafe
      --rpc-external
      --prometheus-external
      --state-pruning=archive
      --blocks-pruning=archive
      --no-hardware-benchmarks
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M

  # Moonbeam Node
  moonbeam-node:
    image: purestake/moonbeam:latest
    container_name: moonbeam-node
    restart: unless-stopped
    ports:
      - \"9947:9944\"
    volumes:
      - /Users/vovkes/moonbeam-data:/moonbeam/data
    command: >
      --chain moonbeam
      --base-path /moonbeam/data
      --name Moonbeam-Shrimp
      --rpc-cors all
      --rpc-methods unsafe
      --rpc-external
      --prometheus-external
      --state-pruning=archive
      --blocks-pruning=archive
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G

  # Parallel Node
  parallel-node:
    image: parallelfinance/parallel:latest
    container_name: parallel-node
    restart: unless-stopped
    ports:
      - \"9950:9944\"
    volumes:
      - /Users/vovkes/parallel-data:/parallel/data
    command: >
      --chain parallel
      --base-path /parallel/data
      --name Parallel-Shrimp
      --rpc-cors all
      --rpc-methods unsafe
      --rpc-external
      --prometheus-external
      --state-pruning=archive
      --blocks-pruning=archive
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M

  # HydraDX Node
  hydradx-node:
    image: galacticcouncil/hydra-dx:latest
    container_name: hydradx-node
    restart: unless-stopped
    ports:
      - \"9952:9944\"
    volumes:
      - /Users/vovkes/hydradx-data:/hydradx/data
    command: >
      --chain hydradx
      --base-path /hydradx/data
      --name HydraDX-Shrimp
      --rpc-cors all
      --rpc-methods unsafe
      --rpc-external
      --prometheus-external
      --state-pruning=archive
      --blocks-pruning=archive
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M

  # Centrifuge Node
  centrifuge-node:
    image: centrifugeio/centrifuge-chain:latest
    container_name: centrifuge-node
    restart: unless-stopped
    ports:
      - \"9953:9944\"
    volumes:
      - /Users/vovkes/centrifuge-data:/centrifuge/data
    command: >
      --chain centrifuge
      --base-path /centrifuge/data
      --name Centrifuge-Shrimp
      --rpc-cors all
      --rpc-methods unsafe
      --rpc-external
      --prometheus-external
      --state-pruning=archive
      --blocks-pruning=archive
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M

  # Acala Node
  acala-node:
    image: acala/acala-node:latest
    container_name: acala-node
    restart: unless-stopped
    ports:
      - \"9949:9944\"
    volumes:
      - /Users/vovkes/acala-data:/acala/data
    command: >
      --chain acala
      --base-path /acala/data
      --name Acala-Shrimp
      --rpc-cors all
      --rpc-methods unsafe
      --rpc-external
      --prometheus-external
      --state-pruning=archive
      --blocks-pruning=archive
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G

  # Prometheus
  polkadot-prometheus:
    image: prom/prometheus:latest
    container_name: polkadot-prometheus
    restart: unless-stopped
    ports:
      - \"9090:9090\"
    volumes:
      - /Users/vovkes/prometheus-config:/etc/prometheus
      - prometheus_data:/prometheus
    command: >
      --config.file=/etc/prometheus/prometheus.yml
      --storage.tsdb.path=/prometheus
      --web.console.libraries=/etc/prometheus/console_libraries
      --web.console.templates=/etc/prometheus/consoles
      --storage.tsdb.retention.time=200h
      --web.enable-lifecycle
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M

  # Grafana
  polkadot-grafana:
    image: grafana/grafana:latest
    container_name: polkadot-grafana
    restart: unless-stopped
    ports:
      - \"3000:3000\"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
      GF_INSTALL_PLUGINS: grafana-clock-panel,grafana-simple-json-datasource
    volumes:
      - grafana_data:/var/lib/grafana
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M

volumes:
  prometheus_data:
  grafana_data:
EOF"
}

# Function to create data directories on Cthulhu
create_data_directories() {
    print_header "Creating data directories on Cthulhu"
    
    local directories=(
        "polkadot-data"
        "kusama-data"
        "westend-data"
        "moonbeam-data"
        "parallel-data"
        "hydradx-data"
        "centrifuge-data"
        "acala-data"
        "prometheus-config"
    )
    
    for dir in "${directories[@]}"; do
        print_status "Creating /Users/vovkes/$dir..."
        ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "mkdir -p /Users/vovkes/$dir"
    done
}

# Function to start containers on Cthulhu
start_cthulhu_containers() {
    print_header "Starting Polkadot containers on Cthulhu"
    
    ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "cd $CTHULHU_PROJECT_DIR && export PATH=/usr/local/bin:\$PATH && /usr/local/bin/docker-compose -f docker-compose-polkadot.yml up -d"
}

# Function to verify migration
verify_migration() {
    print_header "Verifying migration to Cthulhu"
    
    print_status "Checking container status on Cthulhu..."
    ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "export PATH=/usr/local/bin:\$PATH && /usr/local/bin/docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
    
    print_status "Checking localhost containers..."
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || print_warning "No containers running on localhost (expected)"
}

# Main migration process
main() {
    print_header "Polkadot Migration: Localhost -> Cthulhu"
    
    print_warning "This will stop all Polkadot containers on localhost and start them on Cthulhu"
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Migration cancelled"
        exit 1
    fi
    
    # Step 1: Stop containers on localhost
    stop_local_containers
    
    # Step 2: Create data directories on Cthulhu
    create_data_directories
    
    # Step 3: Create docker-compose file on Cthulhu
    create_cthulhu_compose
    
    # Step 4: Start containers on Cthulhu
    start_cthulhu_containers
    
    # Step 5: Verify migration
    verify_migration
    
    print_header "Migration Complete!"
    print_status "Polkadot services are now running on Cthulhu"
    print_status "Access endpoints:"
    echo "  - Polkadot RPC: http://cthulhu.local:9944"
    echo "  - Kusama RPC: http://cthulhu.local:9945"
    echo "  - Westend RPC: http://cthulhu.local:9946"
    echo "  - Moonbeam RPC: http://cthulhu.local:9947"
    echo "  - Acala RPC: http://cthulhu.local:9949"
    echo "  - Parallel RPC: http://cthulhu.local:9950"
    echo "  - HydraDX RPC: http://cthulhu.local:9952"
    echo "  - Centrifuge RPC: http://cthulhu.local:9953"
    echo "  - Prometheus: http://cthulhu.local:9090"
    echo "  - Grafana: http://cthulhu.local:3000"
}

# Run main function
main "$@"
