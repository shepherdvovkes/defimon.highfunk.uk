#!/bin/bash

# =============================================================================
# POLKADOT & ACALA GOOGLE CLOUD DEPLOYMENT SCRIPT
# Deploys Polkadot and Acala networks on Google Cloud Platform
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Polkadot and Acala specific configuration
POLKADOT_INSTANCE_NAME="defimon-polkadot-node"
ACALA_INSTANCE_NAME="defimon-acala-node"
POLKADOT_ZONE="us-central1-a"
ACALA_ZONE="us-central1-b"
POLKADOT_MACHINE_TYPE="e2-standard-4"
ACALA_MACHINE_TYPE="e2-standard-4"
POLKADOT_DISK_SIZE_GB=100
ACALA_DISK_SIZE_GB=100
POLKADOT_PORT=9944
ACALA_PORT=9949

# Docker images
POLKADOT_IMAGE="parity/polkadot:latest"
ACALA_IMAGE="acala/acala-node:latest"

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
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
    print_header "Enabling Required APIs"
    
    gcloud services enable \
        compute.googleapis.com \
        container.googleapis.com \
        cloudbuild.googleapis.com \
        cloudresourcemanager.googleapis.com \
        sqladmin.googleapis.com \
        storage-component.googleapis.com \
        pubsub.googleapis.com \
        redis.googleapis.com \
        monitoring.googleapis.com \
        logging.googleapis.com \
        secretmanager.googleapis.com \
        iam.googleapis.com
    
    print_success "Required APIs enabled"
}

# Create service account if it doesn't exist
create_service_account() {
    print_header "Setting up Service Account"
    
    if ! gcloud iam service-accounts describe "$GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL" >/dev/null 2>&1; then
        print_status "Creating service account..."
        gcloud iam service-accounts create defimon-infrastructure \
            --display-name="DEFIMON Infrastructure Service Account"
    else
        print_status "Service account already exists"
    fi
    
    # Grant necessary roles
    gcloud projects add-iam-policy-binding "$GOOGLE_CLOUD_PROJECT_ID" \
        --member="serviceAccount:$GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL" \
        --role="roles/compute.admin"
    
    gcloud projects add-iam-policy-binding "$GOOGLE_CLOUD_PROJECT_ID" \
        --member="serviceAccount:$GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL" \
        --role="roles/storage.admin"
    
    gcloud projects add-iam-policy-binding "$GOOGLE_CLOUD_PROJECT_ID" \
        --member="serviceAccount:$GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL" \
        --role="roles/logging.admin"
    
    gcloud projects add-iam-policy-binding "$GOOGLE_CLOUD_PROJECT_ID" \
        --member="serviceAccount:$GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL" \
        --role="roles/monitoring.admin"
    
    print_success "Service account configured"
}

# Create firewall rules
create_firewall_rules() {
    print_header "Creating Firewall Rules"
    
    # Create firewall rule for Polkadot
    gcloud compute firewall-rules create polkadot-node-rule \
        --allow tcp:$POLKADOT_PORT \
        --source-ranges 0.0.0.0/0 \
        --description "Allow Polkadot RPC traffic" \
        --target-tags polkadot-node || true
    
    # Create firewall rule for Acala
    gcloud compute firewall-rules create acala-node-rule \
        --allow tcp:$ACALA_PORT \
        --source-ranges 0.0.0.0/0 \
        --description "Allow Acala RPC traffic" \
        --target-tags acala-node || true
    
    # Create firewall rule for monitoring
    gcloud compute firewall-rules create monitoring-rule \
        --allow tcp:9090,tcp:3000,tcp:9100 \
        --source-ranges 0.0.0.0/0 \
        --description "Allow monitoring traffic" \
        --target-tags monitoring || true
    
    print_success "Firewall rules created"
}

# Create persistent disks
create_persistent_disks() {
    print_header "Creating Persistent Disks"
    
    # Create disk for Polkadot
    gcloud compute disks create polkadot-data-disk \
        --size="$POLKADOT_DISK_SIZE_GB" \
        --zone="$POLKADOT_ZONE" \
        --type=pd-ssd \
        --description="Persistent disk for Polkadot node data" || true
    
    # Create disk for Acala
    gcloud compute disks create acala-data-disk \
        --size="$ACALA_DISK_SIZE_GB" \
        --zone="$ACALA_ZONE" \
        --type=pd-ssd \
        --description="Persistent disk for Acala node data" || true
    
    print_success "Persistent disks created"
}

# Create startup script for Polkadot
create_polkadot_startup_script() {
    cat > /tmp/polkadot-startup.sh << 'EOF'
#!/bin/bash

# Install Docker
apt-get update
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# Create data directory
mkdir -p /data/polkadot

# Mount persistent disk
if [ ! -d /data/polkadot/chain ]; then
    mkdir -p /data/polkadot/chain
fi

# Run Polkadot node
docker run -d \
    --name polkadot-node \
    --restart unless-stopped \
    -p 9944:9944 \
    -v /data/polkadot/chain:/polkadot/chain \
    parity/polkadot:latest \
    --base-path /polkadot/chain \
    --chain polkadot \
    --rpc-cors all \
    --rpc-external \
    --rpc-port 9944 \
    --ws-external \
    --ws-port 9944 \
    --pruning archive \
    --name "DEFIMON-Polkadot-Node"

# Install monitoring
docker run -d \
    --name prometheus \
    --restart unless-stopped \
    -p 9090:9090 \
    -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus:latest

# Create Prometheus config
cat > /tmp/prometheus.yml << 'PROMEOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'polkadot'
    static_configs:
      - targets: ['localhost:9944']
PROMEOF
EOF

    chmod +x /tmp/polkadot-startup.sh
}

# Create startup script for Acala
create_acala_startup_script() {
    cat > /tmp/acala-startup.sh << 'EOF'
#!/bin/bash

# Install Docker
apt-get update
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# Create data directory
mkdir -p /data/acala

# Mount persistent disk
if [ ! -d /data/acala/chain ]; then
    mkdir -p /data/acala/chain
fi

# Run Acala node
docker run -d \
    --name acala-node \
    --restart unless-stopped \
    -p 9949:9944 \
    -v /data/acala/chain:/acala/chain \
    acala/acala-node:latest \
    --base-path /acala/chain \
    --chain acala \
    --rpc-cors all \
    --rpc-external \
    --rpc-port 9944 \
    --ws-external \
    --ws-port 9944 \
    --pruning archive \
    --name "DEFIMON-Acala-Node"

# Install monitoring
docker run -d \
    --name prometheus-acala \
    --restart unless-stopped \
    -p 9091:9090 \
    -v /tmp/prometheus-acala.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus:latest

# Create Prometheus config
cat > /tmp/prometheus-acala.yml << 'PROMEOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'acala'
    static_configs:
      - targets: ['localhost:9949']
PROMEOF
EOF

    chmod +x /tmp/acala-startup.sh
}

# Deploy Polkadot instance
deploy_polkadot() {
    print_header "Deploying Polkadot Node"
    
    create_polkadot_startup_script
    
    gcloud compute instances create "$POLKADOT_INSTANCE_NAME" \
        --zone="$POLKADOT_ZONE" \
        --machine-type="$POLKADOT_MACHINE_TYPE" \
        --service-account="$GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL" \
        --scopes=cloud-platform \
        --tags=polkadot-node,monitoring \
        --disk=name=polkadot-data-disk,device-name=polkadot-data-disk,mode=rw,boot=no \
        --metadata-from-file=startup-script=/tmp/polkadot-startup.sh \
        --image-family=ubuntu-2204-lts \
        --image-project=ubuntu-os-cloud \
        --boot-disk-size=20GB \
        --boot-disk-type=pd-ssd
    
    print_success "Polkadot instance created"
    
    # Get external IP
    POLKADOT_IP=$(gcloud compute instances describe "$POLKADOT_INSTANCE_NAME" \
        --zone="$POLKADOT_ZONE" \
        --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
    
    print_status "Polkadot node will be available at: http://$POLKADOT_IP:$POLKADOT_PORT"
    print_status "Prometheus monitoring at: http://$POLKADOT_IP:9090"
}

# Deploy Acala instance
deploy_acala() {
    print_header "Deploying Acala Node"
    
    create_acala_startup_script
    
    gcloud compute instances create "$ACALA_INSTANCE_NAME" \
        --zone="$ACALA_ZONE" \
        --machine-type="$ACALA_MACHINE_TYPE" \
        --service-account="$GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL" \
        --scopes=cloud-platform \
        --tags=acala-node,monitoring \
        --disk=name=acala-data-disk,device-name=acala-data-disk,mode=rw,boot=no \
        --metadata-from-file=startup-script=/tmp/acala-startup.sh \
        --image-family=ubuntu-2204-lts \
        --image-project=ubuntu-os-cloud \
        --boot-disk-size=20GB \
        --boot-disk-type=pd-ssd
    
    print_success "Acala instance created"
    
    # Get external IP
    ACALA_IP=$(gcloud compute instances describe "$ACALA_INSTANCE_NAME" \
        --zone="$ACALA_ZONE" \
        --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
    
    print_status "Acala node will be available at: http://$ACALA_IP:$ACALA_PORT"
    print_status "Prometheus monitoring at: http://$ACALA_IP:9091"
}

# Create load balancer
create_load_balancer() {
    print_header "Creating Load Balancer"
    
    # Create health checks
    gcloud compute health-checks create http polkadot-health-check \
        --port=$POLKADOT_PORT \
        --request-path="/" || true
    
    gcloud compute health-checks create http acala-health-check \
        --port=$ACALA_PORT \
        --request-path="/" || true
    
    # Create backend services
    gcloud compute backend-services create polkadot-backend \
        --health-checks=polkadot-health-check \
        --global || true
    
    gcloud compute backend-services create acala-backend \
        --health-checks=acala-health-check \
        --global || true
    
    # Add instances to backend services
    gcloud compute backend-services add-backend polkadot-backend \
        --instance-group="$POLKADOT_INSTANCE_NAME" \
        --instance-group-zone="$POLKADOT_ZONE" \
        --global || true
    
    gcloud compute backend-services add-backend acala-backend \
        --instance-group="$ACALA_INSTANCE_NAME" \
        --instance-group-zone="$ACALA_ZONE" \
        --global || true
    
    # Create URL maps
    gcloud compute url-maps create polkadot-acala-lb \
        --default-service=polkadot-backend || true
    
    # Create HTTP proxy
    gcloud compute target-http-proxies create polkadot-acala-http-proxy \
        --url-map=polkadot-acala-lb || true
    
    # Create forwarding rule
    gcloud compute forwarding-rules create polkadot-acala-forwarding-rule \
        --target-http-proxy=polkadot-acala-http-proxy \
        --ports=80 \
        --global || true
    
    print_success "Load balancer created"
}

# Setup monitoring and logging
setup_monitoring() {
    print_header "Setting up Monitoring and Logging"
    
    # Enable Cloud Monitoring
    gcloud services enable monitoring.googleapis.com
    
    # Create monitoring workspace
    gcloud monitoring workspaces create \
        --display-name="DEFIMON Polkadot/Acala Monitoring" || true
    
    # Create log sinks
    gcloud logging sinks create polkadot-acala-logs \
        storage.googleapis.com/$GOOGLE_CLOUD_STORAGE_BUCKET \
        --log-filter="resource.type=gce_instance AND (resource.labels.instance_name=$POLKADOT_INSTANCE_NAME OR resource.labels.instance_name=$ACALA_INSTANCE_NAME)" || true
    
    print_success "Monitoring and logging configured"
}

# Create deployment summary
create_deployment_summary() {
    print_header "Deployment Summary"
    
    POLKADOT_IP=$(gcloud compute instances describe "$POLKADOT_INSTANCE_NAME" \
        --zone="$POLKADOT_ZONE" \
        --format="value(networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null || echo "N/A")
    
    ACALA_IP=$(gcloud compute instances describe "$ACALA_INSTANCE_NAME" \
        --zone="$ACALA_ZONE" \
        --format="value(networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null || echo "N/A")
    
    cat > "$PROJECT_ROOT/POLKADOT_ACALA_DEPLOYMENT_SUMMARY.md" << EOF
# Polkadot & Acala Google Cloud Deployment Summary

## Deployment Information
- **Project ID**: $GOOGLE_CLOUD_PROJECT_ID
- **Region**: $GOOGLE_CLOUD_REGION
- **Deployment Date**: $(date)

## Instance Details

### Polkadot Node
- **Instance Name**: $POLKADOT_INSTANCE_NAME
- **Zone**: $POLKADOT_ZONE
- **Machine Type**: $POLKADOT_MACHINE_TYPE
- **External IP**: $POLKADOT_IP
- **RPC Endpoint**: http://$POLKADOT_IP:$POLKADOT_PORT
- **Prometheus**: http://$POLKADOT_IP:9090

### Acala Node
- **Instance Name**: $ACALA_INSTANCE_NAME
- **Zone**: $ACALA_ZONE
- **Machine Type**: $ACALA_MACHINE_TYPE
- **External IP**: $ACALA_IP
- **RPC Endpoint**: http://$ACALA_IP:$ACALA_PORT
- **Prometheus**: http://$ACALA_IP:9091

## Storage
- **Polkadot Data Disk**: ${POLKADOT_DISK_SIZE_GB}GB SSD
- **Acala Data Disk**: ${ACALA_DISK_SIZE_GB}GB SSD

## Network Configuration
- **Polkadot Port**: $POLKADOT_PORT
- **Acala Port**: $ACALA_PORT
- **Firewall Rules**: polkadot-node-rule, acala-node-rule, monitoring-rule

## Monitoring
- **Cloud Monitoring**: Enabled
- **Log Sinks**: polkadot-acala-logs
- **Storage Bucket**: $GOOGLE_CLOUD_STORAGE_BUCKET

## Management Commands

### Check Instance Status
\`\`\`bash
gcloud compute instances list --filter="name~defimon-(polkadot|acala)"
\`\`\`

### SSH to Instances
\`\`\`bash
# Polkadot
gcloud compute ssh $POLKADOT_INSTANCE_NAME --zone=$POLKADOT_ZONE

# Acala
gcloud compute ssh $ACALA_INSTANCE_NAME --zone=$ACALA_ZONE
\`\`\`

### View Logs
\`\`\`bash
# Polkadot logs
gcloud logging read "resource.type=gce_instance AND resource.labels.instance_name=$POLKADOT_INSTANCE_NAME" --limit=50

# Acala logs
gcloud logging read "resource.type=gce_instance AND resource.labels.instance_name=$ACALA_INSTANCE_NAME" --limit=50
\`\`\`

### Stop Instances
\`\`\`bash
gcloud compute instances stop $POLKADOT_INSTANCE_NAME --zone=$POLKADOT_ZONE
gcloud compute instances stop $ACALA_INSTANCE_NAME --zone=$ACALA_ZONE
\`\`\`

### Start Instances
\`\`\`bash
gcloud compute instances start $POLKADOT_INSTANCE_NAME --zone=$POLKADOT_ZONE
gcloud compute instances start $ACALA_INSTANCE_NAME --zone=$ACALA_ZONE
\`\`\`

## Cost Estimation
- **Polkadot Instance**: ~$150-200/month
- **Acala Instance**: ~$150-200/month
- **Storage**: ~$20-40/month
- **Network**: ~$10-20/month
- **Total Estimated**: ~$330-460/month

## Next Steps
1. Wait for nodes to sync (can take 24-48 hours)
2. Configure your application to use the RPC endpoints
3. Set up alerts in Cloud Monitoring
4. Consider setting up automated backups
5. Monitor resource usage and adjust machine types if needed
EOF

    print_success "Deployment summary created: POLKADOT_ACALA_DEPLOYMENT_SUMMARY.md"
}

# Main deployment function
main() {
    print_header "Polkadot & Acala Google Cloud Deployment"
    
    check_prerequisites
    authenticate_gcp
    enable_apis
    create_service_account
    create_firewall_rules
    create_persistent_disks
    deploy_polkadot
    deploy_acala
    create_load_balancer
    setup_monitoring
    create_deployment_summary
    
    print_header "Deployment Complete!"
    print_success "Polkadot and Acala nodes have been deployed to Google Cloud"
    print_status "Check POLKADOT_ACALA_DEPLOYMENT_SUMMARY.md for details"
    print_warning "Nodes will take 24-48 hours to fully sync"
}

# Run main function
main "$@"
