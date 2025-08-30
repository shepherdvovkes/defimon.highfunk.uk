#!/bin/bash

# =============================================================================
# POLKADOT NETWORK DEPLOYMENT ON CTHULHU.LOCAL (macOS) - FULL CHAIN ARCHIVE MODE
# Deploys Polkadot network on macOS host cthulhu.local with complete blockchain archive
# =============================================================================

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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Cthulhu.local configuration
CTHULHU_HOST="cthulhu.local"
CTHULHU_USER="vovkes"
CTHULHU_SSH_KEY="~/.ssh/cthulhu"
CTHULHU_PORT=9944
CTHULHU_WS_PORT=9945
CTHULHU_PROMETHEUS_PORT=9090

# Polkadot specific configuration
POLKADOT_CHAIN="polkadot"
POLKADOT_DOCKER_IMAGE="parity/polkadot:latest"
POLKADOT_BASE_PATH="/Users/vovkes/polkadot-data"
POLKADOT_CHAIN_SPEC="polkadot"

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

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_cthulhu_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites for Polkadot Cthulhu macOS Deployment"
    
    if ! command_exists ssh; then
        print_error "SSH is not installed. Please install it first."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Test SSH connectivity to cthulhu.local
test_ssh_connectivity() {
    print_header "Testing SSH Connectivity to Cthulhu.local"
    
    if ssh -i "$CTHULHU_SSH_KEY" -o ConnectTimeout=10 -o BatchMode=yes -o PasswordAuthentication=no "$CTHULHU_USER@$CTHULHU_HOST" "echo 'SSH connection successful'" 2>/dev/null; then
        print_success "SSH connection to cthulhu.local established"
        return 0
    else
        print_error "Cannot connect to cthulhu.local via SSH"
        print_status "Please ensure:"
        print_status "1. cthulhu.local is accessible from this machine"
        print_status "2. SSH is enabled on cthulhu.local"
        print_status "3. SSH key authentication is set up for vovkes@cthulhu.local"
        print_status "4. SSH key is in ~/.ssh/cthulhu"
        exit 1
    fi
}

# Install Docker Desktop on cthulhu.local using Homebrew
install_docker() {
    print_header "Installing Docker Desktop on Cthulhu.local"
    
    ssh -i "$CTHULHU_SSH_KEY" -o PasswordAuthentication=no "$CTHULHU_USER@$CTHULHU_HOST" << 'EOF'
        # Check if Docker is already installed
        if command -v docker >/dev/null 2>&1; then
            echo "Docker is already installed"
            exit 0
        fi
        
        # Install Docker Desktop using Homebrew
        echo "Installing Docker Desktop..."
        brew install --cask docker
        
        # Start Docker Desktop
        echo "Starting Docker Desktop..."
        open /Applications/Docker.app
        
        # Wait for Docker to start
        echo "Waiting for Docker to start..."
        sleep 30
        
        echo "Docker Desktop installation completed"
EOF
    
    print_success "Docker Desktop installed on cthulhu.local"
}

# Install Docker Compose on cthulhu.local
install_docker_compose() {
    print_header "Installing Docker Compose on Cthulhu.local"
    
    ssh -i "$CTHULHU_SSH_KEY" -o PasswordAuthentication=no "$CTHULHU_USER@$CTHULHU_HOST" << 'EOF'
        # Check if Docker Compose is already installed
        if command -v docker-compose >/dev/null 2>&1; then
            echo "Docker Compose is already installed"
            exit 0
        fi
        
        # Install Docker Compose using Homebrew
        echo "Installing Docker Compose..."
        brew install docker-compose
        
        echo "Docker Compose installation completed"
EOF
    
    print_success "Docker Compose installed on cthulhu.local"
}

# Create directories on cthulhu.local
create_directories() {
    print_header "Creating Directories on Cthulhu.local"
    
    ssh -i "$CTHULHU_SSH_KEY" -o PasswordAuthentication=no "$CTHULHU_USER@$CTHULHU_HOST" << EOF
        # Create directories in user home
        mkdir -p $POLKADOT_BASE_PATH
        mkdir -p /Users/vovkes/logs/polkadot
        mkdir -p /Users/vovkes/config/polkadot
        mkdir -p /Users/vovkes/config/prometheus
        
        echo "Directories created successfully"
EOF
    
    print_success "Directories created on cthulhu.local"
}

# Create Docker Compose file on cthulhu.local
create_docker_compose() {
    print_header "Creating Docker Compose Configuration on Cthulhu.local"
    
    ssh -i "$CTHULHU_SSH_KEY" -o PasswordAuthentication=no "$CTHULHU_USER@$CTHULHU_HOST" << EOF
        cat > /Users/vovkes/docker-compose.yml << 'DOCKER_COMPOSE_EOF'
version: '3.8'

services:
  polkadot-cthulhu-archive:
    image: $POLKADOT_DOCKER_IMAGE
    container_name: polkadot-cthulhu-archive
    restart: unless-stopped
    ports:
      - "$CTHULHU_PORT:9944"
      - "$CTHULHU_WS_PORT:9945"
      - "$CTHULHU_PROMETHEUS_PORT:9615"
    volumes:
      - $POLKADOT_BASE_PATH:/data
      - /Users/vovkes/logs/polkadot:/var/log/polkadot
    command: >
      --chain $POLKADOT_CHAIN_SPEC
      --base-path /data
      --name polkadot-cthulhu-archive
      --rpc-port 9944
      --ws-port 9945
      --rpc-cors all
      --rpc-external
      --ws-external
      --unsafe-rpc-external
      --unsafe-ws-external
      --pruning archive
      --prometheus-external
      --prometheus-port 9615
      --validator
      --telemetry-url 'wss://telemetry.polkadot.io/submit/ 0'
    logging:
      driver: json-file
      options:
        max-size: 100m
        max-file: 3

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus-polkadot
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - /Users/vovkes/config/prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    command: >
      --config.file=/etc/prometheus/prometheus.yml
      --storage.tsdb.path=/prometheus
      --web.console.libraries=/etc/prometheus/console_libraries
      --web.console.templates=/etc/prometheus/consoles
      --storage.tsdb.retention.time=200h
      --web.enable-lifecycle

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter-polkadot
    restart: unless-stopped
    ports:
      - "9100:9100"
    command: >
      --collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)

volumes:
  prometheus_data:
DOCKER_COMPOSE_EOF

        echo "Docker Compose file created successfully"
EOF
    
    print_success "Docker Compose configuration created on cthulhu.local"
}

# Create Prometheus configuration on cthulhu.local
create_prometheus_config() {
    print_header "Creating Prometheus Configuration on Cthulhu.local"
    
    ssh -i "$CTHULHU_SSH_KEY" -o PasswordAuthentication=no "$CTHULHU_USER@$CTHULHU_HOST" << EOF
        cat > /Users/vovkes/config/prometheus/prometheus.yml << 'PROMETHEUS_EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'polkadot-cthulhu'
    static_configs:
      - targets: ['host.docker.internal:$CTHULHU_PROMETHEUS_PORT']
    metrics_path: /metrics
    scrape_interval: 5s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['host.docker.internal:9100']
PROMETHEUS_EOF

        echo "Prometheus configuration created successfully"
EOF
    
    print_success "Prometheus configuration created on cthulhu.local"
}

# Start Polkadot services on cthulhu.local
start_services() {
    print_header "Starting Polkadot Services on Cthulhu.local"
    
    ssh -i "$CTHULHU_SSH_KEY" -o PasswordAuthentication=no "$CTHULHU_USER@$CTHULHU_HOST" << 'EOF'
        # Stop any existing containers
        docker-compose down 2>/dev/null || true
        
        # Start services
        cd /Users/vovkes
        docker-compose up -d
        
        echo "Services started successfully"
EOF
    
    print_success "Polkadot services started on cthulhu.local"
}

# Verify deployment on cthulhu.local
verify_deployment() {
    print_header "Verifying Polkadot Cthulhu macOS Deployment"
    
    print_status "Verifying deployment on $CTHULHU_HOST"
    
    # Check if containers are running
    ssh -i "$CTHULHU_SSH_KEY" -o PasswordAuthentication=no "$CTHULHU_USER@$CTHULHU_HOST" << 'EOF'
        echo "=== Container Status ==="
        docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
        
        echo -e "\n=== Polkadot Node Status ==="
        curl -s -X POST -H 'Content-Type: application/json' \
            -d '{"jsonrpc":"2.0","method":"system_health","params":[],"id":1}' \
            http://localhost:9944 || echo "RPC not ready yet"
        
        echo -e "\n=== Prometheus Status ==="
        curl -s http://localhost:9090/-/healthy || echo "Prometheus not ready yet"
EOF
    
    print_success "Deployment verification completed"
}

# Create management script
create_management_script() {
    print_header "Creating Management Script"
    
    cat > "$PROJECT_ROOT/scripts/manage-polkadot-cthulhu-macos.sh" << 'EOF'
#!/bin/bash

# Polkadot Cthulhu macOS Management Script
CTHULHU_HOST="cthulhu.local"
CTHULHU_USER="vovkes"
CTHULHU_SSH_KEY="~/.ssh/cthulhu"
CTHULHU_PORT=9944
CTHULHU_WS_PORT=9945
CTHULHU_PROMETHEUS_PORT=9090

case "$1" in
    status)
        echo "=== Polkadot Cthulhu macOS Status ==="
        ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "docker ps --format 'table {{.Names}}\t{{.Status}}'"
        ;;
    
    start)
        echo "Starting Polkadot Cthulhu services..."
        ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "cd /Users/vovkes && docker-compose up -d"
        ;;
    
    stop)
        echo "Stopping Polkadot Cthulhu services..."
        ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "cd /Users/vovkes && docker-compose down"
        ;;
    
    restart)
        echo "Restarting Polkadot Cthulhu services..."
        ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "cd /Users/vovkes && docker-compose restart"
        ;;
    
    logs)
        echo "=== Polkadot Cthulhu macOS Logs ==="
        ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "docker logs polkadot-cthulhu-archive --tail 50"
        ;;
    
    sync)
        echo "=== Polkadot Sync Status ==="
        ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"system_syncState\",\"params\":[],\"id\":1}' http://localhost:$CTHULHU_PORT"
        ;;
    
    resources)
        echo "=== Resource Usage ==="
        ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "df -h && echo '---' && docker stats --no-stream"
        ;;
    
    backup)
        echo "Creating backup..."
        ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "tar -czf /Users/vovkes/polkadot-backup-\$(date +%Y%m%d-%H%M%S).tar.gz /Users/vovkes/polkadot-data"
        ;;
    
    test)
        echo "=== Testing Connectivity ==="
        echo "Testing RPC endpoint: http://$CTHULHU_HOST:$CTHULHU_PORT"
        curl -s -X POST -H 'Content-Type: application/json' \
            -d '{"jsonrpc":"2.0","method":"system_health","params":[],"id":1}' \
            "http://$CTHULHU_HOST:$CTHULHU_PORT"
        
        echo -e "\nTesting Prometheus: http://$CTHULHU_HOST:$CTHULHU_PROMETHEUS_PORT"
        curl -s "http://$CTHULHU_HOST:$CTHULHU_PROMETHEUS_PORT/-/healthy"
        ;;
    
    endpoints)
        echo "=== Polkadot Cthulhu macOS Endpoints ==="
        echo "RPC Endpoint: http://$CTHULHU_HOST:$CTHULHU_PORT"
        echo "WebSocket Endpoint: ws://$CTHULHU_HOST:$CTHULHU_WS_PORT"
        echo "Prometheus: http://$CTHULHU_HOST:$CTHULHU_PROMETHEUS_PORT"
        ;;
    
    *)
        echo "Usage: $0 {status|start|stop|restart|logs|sync|resources|backup|test|endpoints}"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$PROJECT_ROOT/scripts/manage-polkadot-cthulhu-macos.sh"
    print_success "Management script created: scripts/manage-polkadot-cthulhu-macos.sh"
}

# Generate deployment summary
generate_summary() {
    print_header "Generating Deployment Summary"
    
    cat > "$PROJECT_ROOT/POLKADOT_CTHULHU_MACOS_DEPLOYMENT_SUMMARY.md" << EOF
# Polkadot Cthulhu macOS Deployment Summary

## Deployment Information
- **Host**: $CTHULHU_HOST (macOS)
- **User**: $CTHULHU_USER
- **Deployment Date**: $(date)

## Endpoints
- **RPC Endpoint**: http://$CTHULHU_HOST:$CTHULHU_PORT
- **WebSocket Endpoint**: ws://$CTHULHU_HOST:$CTHULHU_WS_PORT
- **Prometheus**: http://$CTHULHU_HOST:$CTHULHU_PROMETHEUS_PORT

## Configuration
- **Chain**: $POLKADOT_CHAIN_SPEC
- **Mode**: Archive (Full Chain)
- **Pruning**: Archive (keeps all historical data)
- **CORS**: All origins allowed
- **External Access**: Enabled for RPC and WebSocket

## Management Commands
\`\`\`bash
# Check status
./scripts/manage-polkadot-cthulhu-macos.sh status

# View logs
./scripts/manage-polkadot-cthulhu-macos.sh logs

# Check sync status
./scripts/manage-polkadot-cthulhu-macos.sh sync

# Test connectivity
./scripts/manage-polkadot-cthulhu-macos.sh test

# View endpoints
./scripts/manage-polkadot-cthulhu-macos.sh endpoints
\`\`\`

## Monitoring
- **Prometheus**: Available on port $CTHULHU_PROMETHEUS_PORT
- **Node Exporter**: Available on port 9100
- **Logs**: Located in /Users/vovkes/logs/polkadot/

## Archive Mode Features
- Complete blockchain history
- All historical transactions preserved
- Full state trie available
- Suitable for analytics and research

## macOS Deployment Benefits
- No cloud costs
- Full control over resources
- No quota limitations
- Direct access to hardware
- Docker Desktop integration

## Next Steps
1. Wait for initial sync (24-48 hours for full archive)
2. Monitor sync progress using management script
3. Configure your applications to use the RPC endpoints
4. Set up local monitoring and alerts
5. Implement backup strategies

## Security Notes
- RPC and WebSocket endpoints are accessible on local network
- Consider firewall rules for network security
- Archive mode requires significant storage and processing power
EOF
    
    print_success "Deployment summary generated: POLKADOT_CTHULHU_MACOS_DEPLOYMENT_SUMMARY.md"
}

# Main deployment function
main() {
    print_cthulhu_header "POLKADOT CTHULHU macOS ARCHIVE DEPLOYMENT"
    print_status "Starting Polkadot network deployment on cthulhu.local (macOS) with full chain archive mode"
    
    check_prerequisites
    test_ssh_connectivity
    install_docker
    install_docker_compose
    create_directories
    create_docker_compose
    create_prometheus_config
    start_services
    verify_deployment
    create_management_script
    generate_summary
    
    print_cthulhu_header "DEPLOYMENT COMPLETED"
    print_success "Polkadot Cthulhu macOS archive node has been successfully deployed!"
    print_status "Use './scripts/manage-polkadot-cthulhu-macos.sh' to manage the deployment"
    print_status "Check 'POLKADOT_CTHULHU_MACOS_DEPLOYMENT_SUMMARY.md' for detailed information"
}

# Run main function
main "$@"
