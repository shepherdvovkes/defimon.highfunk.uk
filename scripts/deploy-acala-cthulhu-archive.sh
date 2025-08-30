#!/bin/bash

# =============================================================================
# ACALA NETWORK DEPLOYMENT ON CTHULHU - FULL CHAIN ARCHIVE MODE
# Deploys Acala network on Cthulhu with complete blockchain archive
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
CONFIG_FILE="$PROJECT_ROOT/gcp.env"

# Load configuration
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: gcp.env file not found. Please configure your Google Cloud settings.${NC}"
    exit 1
fi

source "$CONFIG_FILE"

# Cthulhu-specific configuration
CTHULHU_INSTANCE_NAME="defimon-acala-cthulhu-archive"
CTHULHU_ZONE="us-central1-a"  # Changed to us-central1-a for better availability
CTHULHU_MACHINE_TYPE="e2-standard-8"  # Higher specs for archive mode
CTHULHU_DISK_SIZE_GB=10   # Minimal disk size due to quota constraints
CTHULHU_PORT=9949
CTHULHU_WS_PORT=9950
CTHULHU_PROMETHEUS_PORT=9092

# Acala specific configuration
ACALA_CHAIN="acala"
ACALA_DOCKER_IMAGE="acala/acala-node:latest"
ACALA_BASE_PATH="/var/lib/acala"
ACALA_CHAIN_SPEC="acala"

# Archive mode configuration
ARCHIVE_MODE="--pruning=archive"
RPC_CORS="--rpc-cors=all"
RPC_EXTERNAL="--rpc-external"
WS_EXTERNAL="--ws-external"
UNSAFE_RPC_EXTERNAL="--unsafe-rpc-external"
UNSAFE_WS_EXTERNAL="--unsafe-ws-external"

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
    print_header "Checking Prerequisites for Acala Cthulhu Archive Deployment"
    
    if ! command_exists gcloud; then
        print_error "Google Cloud SDK is not installed. Please install it first:"
        echo "https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Authenticate with Google Cloud
authenticate_gcp() {
    print_header "Authenticating with Google Cloud"
    
    gcloud auth login
    gcloud config set project "$GOOGLE_CLOUD_PROJECT_ID"
    gcloud config set compute/region "$GOOGLE_CLOUD_REGION"
    
    print_success "Authenticated with Google Cloud"
}

# Enable required APIs
enable_apis() {
    print_header "Enabling Required Google Cloud APIs"
    
    gcloud services enable compute.googleapis.com
    gcloud services enable container.googleapis.com
    gcloud services enable monitoring.googleapis.com
    gcloud services enable logging.googleapis.com
    gcloud services enable storage.googleapis.com
    
    print_success "All required APIs are enabled"
}

# Create firewall rules for Acala Cthulhu
create_firewall_rules() {
    print_header "Creating Firewall Rules for Acala Cthulhu"
    
    # Create firewall rule for Acala RPC
    gcloud compute firewall-rules create "acala-cthulhu-rpc" \
        --allow tcp:$CTHULHU_PORT \
        --description "Allow Acala RPC access" \
        --direction INGRESS \
        --source-ranges 0.0.0.0/0 \
        --target-tags "acala-cthulhu" \
        --quiet || true
    
    # Create firewall rule for Acala WebSocket
    gcloud compute firewall-rules create "acala-cthulhu-ws" \
        --allow tcp:$CTHULHU_WS_PORT \
        --description "Allow Acala WebSocket access" \
        --direction INGRESS \
        --source-ranges 0.0.0.0/0 \
        --target-tags "acala-cthulhu" \
        --quiet || true
    
    # Create firewall rule for Prometheus monitoring
    gcloud compute firewall-rules create "acala-cthulhu-prometheus" \
        --allow tcp:$CTHULHU_PROMETHEUS_PORT \
        --description "Allow Prometheus monitoring access" \
        --direction INGRESS \
        --source-ranges 0.0.0.0/0 \
        --target-tags "acala-cthulhu" \
        --quiet || true
    
    # Create firewall rule for SSH
    gcloud compute firewall-rules create "acala-cthulhu-ssh" \
        --allow tcp:22 \
        --description "Allow SSH access to Acala Cthulhu" \
        --direction INGRESS \
        --source-ranges 0.0.0.0/0 \
        --target-tags "acala-cthulhu" \
        --quiet || true
    
    print_success "Firewall rules created"
}

# Create persistent disk for Acala data
create_persistent_disk() {
    print_header "Creating Persistent Disk for Acala Archive Data"
    
    print_warning "Note: Using minimal 10GB disk due to SSD quota constraints"
    print_info "Current SSD usage: 240GB/250GB (10GB available)"
    print_info "For full archive mode, consider requesting quota increase to 500GB+"
    
    gcloud compute disks create "$CTHULHU_INSTANCE_NAME-disk" \
        --size "$CTHULHU_DISK_SIZE_GB" \
        --type pd-ssd \
        --zone "$CTHULHU_ZONE" \
        --description "Persistent disk for Acala archive data" \
        --quiet || true
    
    print_success "Persistent disk created"
}

# Create compute instance for Acala Cthulhu
create_compute_instance() {
    print_header "Creating Compute Instance for Acala Cthulhu Archive"
    
    gcloud compute instances create "$CTHULHU_INSTANCE_NAME" \
        --zone "$CTHULHU_ZONE" \
        --machine-type "$CTHULHU_MACHINE_TYPE" \
        --image-family ubuntu-2204-lts \
        --image-project ubuntu-os-cloud \
        --boot-disk-size 50GB \
        --boot-disk-type pd-ssd \
        --disk name="$CTHULHU_INSTANCE_NAME-disk",device-name=acala-data,mode=rw \
        --tags "acala-cthulhu" \
        --metadata startup-script="#!/bin/bash
# Install Docker
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
curl -L \"https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create directories
mkdir -p $ACALA_BASE_PATH
mkdir -p /var/log/acala
mkdir -p /etc/acala

# Set up systemd service for Acala
cat > /etc/systemd/system/acala-cthulhu.service << 'EOF'
[Unit]
Description=Acala Node on Cthulhu (Archive Mode)
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=root
ExecStart=/usr/bin/docker run --rm \\
  --name acala-cthulhu-archive \\
  --network host \\
  -v $ACALA_BASE_PATH:/data \\
  -v /var/log/acala:/var/log/acala \\
  $ACALA_DOCKER_IMAGE \\
  --chain $ACALA_CHAIN_SPEC \\
  --base-path /data \\
  --name acala-cthulhu-archive \\
  --rpc-port $CTHULHU_PORT \\
  --ws-port $CTHULHU_WS_PORT \\
  --rpc-cors all \\
  --rpc-external \\
  --ws-external \\
  --unsafe-rpc-external \\
  --unsafe-ws-external \\
  --pruning archive \\
  --prometheus-external \\
  --prometheus-port $CTHULHU_PROMETHEUS_PORT \\
  --validator \\
  --telemetry-url 'wss://telemetry.polkadot.io/submit/ 0'

ExecStop=/usr/bin/docker stop acala-cthulhu-archive
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Acala service
systemctl daemon-reload
systemctl enable acala-cthulhu.service
systemctl start acala-cthulhu.service

# Set up monitoring with Prometheus
cat > /etc/systemd/system/prometheus-acala.service << 'EOF'
[Unit]
Description=Prometheus for Acala Cthulhu
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/docker run --rm \\
  --name prometheus-acala \\
  --network host \\
  -v /etc/prometheus:/etc/prometheus \\
  prom/prometheus:latest \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/prometheus \\
  --web.console.libraries=/etc/prometheus/console_libraries \\
  --web.console.templates=/etc/prometheus/consoles \\
  --storage.tsdb.retention.time=200h \\
  --web.enable-lifecycle

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create Prometheus configuration
mkdir -p /etc/prometheus
cat > /etc/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'acala-cthulhu'
    static_configs:
      - targets: ['localhost:$CTHULHU_PROMETHEUS_PORT']
    metrics_path: /metrics
    scrape_interval: 5s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF

# Install Node Exporter
docker run -d --name node-exporter --network host prom/node-exporter:latest

# Enable and start Prometheus
systemctl daemon-reload
systemctl enable prometheus-acala.service
systemctl start prometheus-acala.service

# Create health check script
cat > /usr/local/bin/acala-health-check.sh << 'EOF'
#!/bin/bash
# Health check for Acala Cthulhu node
if curl -s http://localhost:$CTHULHU_PORT/health > /dev/null; then
    echo \"Acala Cthulhu is healthy\"
    exit 0
else
    echo \"Acala Cthulhu health check failed\"
    exit 1
fi
EOF

chmod +x /usr/local/bin/acala-health-check.sh

# Set up log rotation
cat > /etc/logrotate.d/acala-cthulhu << 'EOF'
/var/log/acala/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        systemctl reload acala-cthulhu.service
    endscript
}
EOF" \
        --quiet
    
    print_success "Compute instance created"
}

# Wait for instance to be ready
wait_for_instance() {
    print_header "Waiting for Instance to be Ready"
    
    print_status "Waiting for instance to start..."
    sleep 30
    
    # Get instance IP
    INSTANCE_IP=$(gcloud compute instances describe "$CTHULHU_INSTANCE_NAME" \
        --zone "$CTHULHU_ZONE" \
        --format "value(networkInterfaces[0].accessConfigs[0].natIP)")
    
    print_status "Instance IP: $INSTANCE_IP"
    
    # Wait for SSH to be available
    print_status "Waiting for SSH to be available..."
    while ! gcloud compute ssh "$CTHULHU_INSTANCE_NAME" \
        --zone "$CTHULHU_ZONE" \
        --command "echo 'SSH is ready'" 2>/dev/null; do
        print_status "Waiting for SSH..."
        sleep 10
    done
    
    print_success "Instance is ready"
}

# Deploy Acala node
deploy_acala_node() {
    print_header "Deploying Acala Node on Cthulhu"
    
    # Get instance IP
    INSTANCE_IP=$(gcloud compute instances describe "$CTHULHU_INSTANCE_NAME" \
        --zone "$CTHULHU_ZONE" \
        --format "value(networkInterfaces[0].accessConfigs[0].natIP)")
    
    print_status "Deploying Acala node on $INSTANCE_IP"
    
    # Create Docker Compose file for Acala
    gcloud compute ssh "$CTHULHU_INSTANCE_NAME" \
        --zone "$CTHULHU_ZONE" \
        --command "cat > /root/docker-compose.yml << 'EOF'
version: '3.8'

services:
  acala-cthulhu-archive:
    image: $ACALA_DOCKER_IMAGE
    container_name: acala-cthulhu-archive
    restart: unless-stopped
    network_mode: host
    volumes:
      - $ACALA_BASE_PATH:/data
      - /var/log/acala:/var/log/acala
    command: >
      --chain $ACALA_CHAIN_SPEC
      --base-path /data
      --name acala-cthulhu-archive
      --rpc-port $CTHULHU_PORT
      --ws-port $CTHULHU_WS_PORT
      --rpc-cors all
      --rpc-external
      --ws-external
      --unsafe-rpc-external
      --unsafe-ws-external
      --pruning archive
      --prometheus-external
      --prometheus-port $CTHULHU_PROMETHEUS_PORT
      --validator
      --telemetry-url 'wss://telemetry.polkadot.io/submit/ 0'
    logging:
      driver: json-file
      options:
        max-size: 100m
        max-file: 3

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus-acala
    restart: unless-stopped
    network_mode: host
    volumes:
      - /etc/prometheus:/etc/prometheus
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
    container_name: node-exporter-acala
    restart: unless-stopped
    network_mode: host
    command: >
      --collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)

volumes:
  prometheus_data:
EOF"
    
    # Start the services
    gcloud compute ssh "$CTHULHU_INSTANCE_NAME" \
        --zone "$CTHULHU_ZONE" \
        --command "cd /root && docker-compose up -d"
    
    print_success "Acala node deployed"
}

# Verify deployment
verify_deployment() {
    print_header "Verifying Acala Cthulhu Deployment"
    
    # Get instance IP
    INSTANCE_IP=$(gcloud compute instances describe "$CTHULHU_INSTANCE_NAME" \
        --zone "$CTHULHU_ZONE" \
        --format "value(networkInterfaces[0].accessConfigs[0].natIP)")
    
    print_status "Verifying deployment on $INSTANCE_IP"
    
    # Check if containers are running
    gcloud compute ssh "$CTHULHU_INSTANCE_NAME" \
        --zone "$CTHULHU_ZONE" \
        --command "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
    
    # Check Acala node status
    print_status "Checking Acala node status..."
    gcloud compute ssh "$CTHULHU_INSTANCE_NAME" \
        --zone "$CTHULHU_ZONE" \
        --command "curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"system_health\",\"params\":[],\"id\":1}' http://localhost:$CTHULHU_PORT"
    
    # Check Prometheus
    print_status "Checking Prometheus..."
    gcloud compute ssh "$CTHULHU_INSTANCE_NAME" \
        --zone "$CTHULHU_ZONE" \
        --command "curl -s http://localhost:$CTHULHU_PROMETHEUS_PORT/-/healthy"
    
    print_success "Deployment verification completed"
}

# Create management script
create_management_script() {
    print_header "Creating Management Script"
    
    cat > "$PROJECT_ROOT/scripts/manage-acala-cthulhu.sh" << 'EOF'
#!/bin/bash

# Acala Cthulhu Management Script
CTHULHU_INSTANCE_NAME="defimon-acala-cthulhu-archive"
CTHULHU_ZONE="us-central1-a"
CTHULHU_PORT=9949
CTHULHU_WS_PORT=9950
CTHULHU_PROMETHEUS_PORT=9092

case "$1" in
    status)
        echo "=== Acala Cthulhu Status ==="
        gcloud compute instances describe "$CTHULHU_INSTANCE_NAME" \
            --zone "$CTHULHU_ZONE" \
            --format "value(status)"
        
        echo -e "\n=== Container Status ==="
        gcloud compute ssh "$CTHULHU_INSTANCE_NAME" \
            --zone "$CTHULHU_ZONE" \
            --command "docker ps --format 'table {{.Names}}\t{{.Status}}'"
        ;;
    
    start)
        echo "Starting Acala Cthulhu instance..."
        gcloud compute instances start "$CTHULHU_INSTANCE_NAME" --zone "$CTHULHU_ZONE"
        ;;
    
    stop)
        echo "Stopping Acala Cthulhu instance..."
        gcloud compute instances stop "$CTHULHU_INSTANCE_NAME" --zone "$CTHULHU_ZONE"
        ;;
    
    restart)
        echo "Restarting Acala Cthulhu instance..."
        gcloud compute instances stop "$CTHULHU_INSTANCE_NAME" --zone "$CTHULHU_ZONE"
        sleep 10
        gcloud compute instances start "$CTHULHU_INSTANCE_NAME" --zone "$CTHULHU_ZONE"
        ;;
    
    logs)
        echo "=== Acala Cthulhu Logs ==="
        gcloud compute ssh "$CTHULHU_INSTANCE_NAME" \
            --zone "$CTHULHU_ZONE" \
            --command "docker logs acala-cthulhu-archive --tail 50"
        ;;
    
    sync)
        echo "=== Acala Sync Status ==="
        gcloud compute ssh "$CTHULHU_INSTANCE_NAME" \
            --zone "$CTHULHU_ZONE" \
            --command "curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"system_syncState\",\"params\":[],\"id\":1}' http://localhost:$CTHULHU_PORT"
        ;;
    
    resources)
        echo "=== Resource Usage ==="
        gcloud compute ssh "$CTHULHU_INSTANCE_NAME" \
            --zone "$CTHULHU_ZONE" \
            --command "df -h && echo '---' && free -h && echo '---' && docker stats --no-stream"
        ;;
    
    backup)
        echo "Creating backup..."
        gcloud compute disks snapshot "$CTHULHU_INSTANCE_NAME-disk" \
            --zone "$CTHULHU_ZONE" \
            --snapshot-names "acala-cthulhu-backup-$(date +%Y%m%d-%H%M%S)"
        ;;
    
    test)
        echo "=== Testing Connectivity ==="
        INSTANCE_IP=$(gcloud compute instances describe "$CTHULHU_INSTANCE_NAME" \
            --zone "$CTHULHU_ZONE" \
            --format "value(networkInterfaces[0].accessConfigs[0].natIP)")
        
        echo "Testing RPC endpoint: http://$INSTANCE_IP:$CTHULHU_PORT"
        curl -s -X POST -H 'Content-Type: application/json' \
            -d '{"jsonrpc":"2.0","method":"system_health","params":[],"id":1}' \
            "http://$INSTANCE_IP:$CTHULHU_PORT"
        
        echo -e "\nTesting Prometheus: http://$INSTANCE_IP:$CTHULHU_PROMETHEUS_PORT"
        curl -s "http://$INSTANCE_IP:$CTHULHU_PROMETHEUS_PORT/-/healthy"
        ;;
    
    endpoints)
        echo "=== Acala Cthulhu Endpoints ==="
        INSTANCE_IP=$(gcloud compute instances describe "$CTHULHU_INSTANCE_NAME" \
            --zone "$CTHULHU_ZONE" \
            --format "value(networkInterfaces[0].accessConfigs[0].natIP)")
        
        echo "RPC Endpoint: http://$INSTANCE_IP:$CTHULHU_PORT"
        echo "WebSocket Endpoint: ws://$INSTANCE_IP:$CTHULHU_WS_PORT"
        echo "Prometheus: http://$INSTANCE_IP:$CTHULHU_PROMETHEUS_PORT"
        ;;
    
    *)
        echo "Usage: $0 {status|start|stop|restart|logs|sync|resources|backup|test|endpoints}"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$PROJECT_ROOT/scripts/manage-acala-cthulhu.sh"
    print_success "Management script created: scripts/manage-acala-cthulhu.sh"
}

# Generate deployment summary
generate_summary() {
    print_header "Generating Deployment Summary"
    
    INSTANCE_IP=$(gcloud compute instances describe "$CTHULHU_INSTANCE_NAME" \
        --zone "$CTHULHU_ZONE" \
        --format "value(networkInterfaces[0].accessConfigs[0].natIP)")
    
    cat > "$PROJECT_ROOT/ACALA_CTHULHU_DEPLOYMENT_SUMMARY.md" << EOF
# Acala Cthulhu Archive Deployment Summary

## Deployment Information
- **Instance Name**: $CTHULHU_INSTANCE_NAME
- **Zone**: $CTHULHU_ZONE
- **Machine Type**: $CTHULHU_MACHINE_TYPE
- **Disk Size**: ${CTHULHU_DISK_SIZE_GB}GB SSD
- **Deployment Date**: $(date)

## Endpoints
- **RPC Endpoint**: http://$INSTANCE_IP:$CTHULHU_PORT
- **WebSocket Endpoint**: ws://$INSTANCE_IP:$CTHULHU_WS_PORT
- **Prometheus**: http://$INSTANCE_IP:$CTHULHU_PROMETHEUS_PORT

## Configuration
- **Chain**: $ACALA_CHAIN_SPEC
- **Mode**: Archive (Full Chain)
- **Pruning**: Archive (keeps all historical data)
- **CORS**: All origins allowed
- **External Access**: Enabled for RPC and WebSocket

## Management Commands
\`\`\`bash
# Check status
./scripts/manage-acala-cthulhu.sh status

# View logs
./scripts/manage-acala-cthulhu.sh logs

# Check sync status
./scripts/manage-acala-cthulhu.sh sync

# Test connectivity
./scripts/manage-acala-cthulhu.sh test

# View endpoints
./scripts/manage-acala-cthulhu.sh endpoints
\`\`\`

## Monitoring
- **Prometheus**: Available on port $CTHULHU_PROMETHEUS_PORT
- **Node Exporter**: Available on port 9100
- **Logs**: Located in /var/log/acala/

## Archive Mode Features
- Complete blockchain history
- All historical transactions preserved
- Full state trie available
- Suitable for analytics and research

## Cost Estimation
- **Compute**: ~$300-400/month (e2-standard-8)
- **Storage**: ~$50-100/month (500GB SSD)
- **Network**: ~$10-20/month
- **Total**: ~$360-520/month

## Next Steps
1. Wait for initial sync (24-48 hours for full archive)
2. Monitor sync progress using management script
3. Configure your applications to use the RPC endpoints
4. Set up alerts for monitoring
5. Implement backup strategies

## Security Notes
- RPC and WebSocket endpoints are publicly accessible
- Consider implementing VPN or firewall rules for production use
- Archive mode requires significant storage and processing power
EOF
    
    print_success "Deployment summary generated: ACALA_CTHULHU_DEPLOYMENT_SUMMARY.md"
}

# Main deployment function
main() {
    print_cthulhu_header "ACALA CTHULHU ARCHIVE DEPLOYMENT"
    print_status "Starting Acala network deployment on Cthulhu with full chain archive mode"
    
    check_prerequisites
    authenticate_gcp
    enable_apis
    create_firewall_rules
    create_persistent_disk
    create_compute_instance
    wait_for_instance
    deploy_acala_node
    verify_deployment
    create_management_script
    generate_summary
    
    print_cthulhu_header "DEPLOYMENT COMPLETED"
    print_success "Acala Cthulhu archive node has been successfully deployed!"
    print_status "Use './scripts/manage-acala-cthulhu.sh' to manage the deployment"
    print_status "Check 'ACALA_CTHULHU_DEPLOYMENT_SUMMARY.md' for detailed information"
}

# Run main function
main "$@"
