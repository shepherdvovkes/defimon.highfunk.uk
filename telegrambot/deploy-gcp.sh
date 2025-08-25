#!/bin/bash

# Telegram Bot Google Cloud Deployment Script
# This script deploys the Telegram bot to Google Cloud Compute Engine without Kubernetes

set -e

# Configuration
PROJECT_ID="${GOOGLE_CLOUD_PROJECT_ID:-$(gcloud config get-value project)}"
INSTANCE_NAME="telegram-bot-vm"
ZONE="us-central1-a"
MACHINE_TYPE="e2-micro"  # Small instance for cost optimization
IMAGE_FAMILY="debian-11"
IMAGE_PROJECT="debian-cloud"
DISK_SIZE="20GB"
NETWORK="default"
FIREWALL_RULE="telegram-bot-allow-ssh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Check if gcloud is installed and authenticated
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v gcloud &> /dev/null; then
        print_error "Google Cloud SDK is not installed. Please install it first."
        exit 1
    fi
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "Not authenticated with Google Cloud. Please run: gcloud auth login"
        exit 1
    fi
    
    if [ -z "$PROJECT_ID" ]; then
        print_error "No project ID specified. Set GOOGLE_CLOUD_PROJECT_ID or run: gcloud config set project PROJECT_ID"
        exit 1
    fi
    
    print_status "Prerequisites check passed"
}

# Create firewall rule for SSH access
create_firewall_rule() {
    print_status "Creating firewall rule for SSH access..."
    
    if ! gcloud compute firewall-rules describe "$FIREWALL_RULE" --project="$PROJECT_ID" &>/dev/null; then
        gcloud compute firewall-rules create "$FIREWALL_RULE" \
            --project="$PROJECT_ID" \
            --direction=INGRESS \
            --priority=1000 \
            --network="$NETWORK" \
            --action=ALLOW \
            --rules=tcp:22 \
            --source-ranges=0.0.0.0/0 \
            --description="Allow SSH access to Telegram bot VM"
        print_status "Firewall rule created: $FIREWALL_RULE"
    else
        print_status "Firewall rule already exists: $FIREWALL_RULE"
    fi
}

# Create VM instance
create_vm_instance() {
    print_status "Creating VM instance: $INSTANCE_NAME in zone $ZONE..."
    
    if gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" &>/dev/null; then
        print_warning "Instance $INSTANCE_NAME already exists. Stopping and deleting..."
        gcloud compute instances delete "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" --quiet
    fi
    
    gcloud compute instances create "$INSTANCE_NAME" \
        --project="$PROJECT_ID" \
        --zone="$ZONE" \
        --machine-type="$MACHINE_TYPE" \
        --image-family="$IMAGE_FAMILY" \
        --image-project="$IMAGE_PROJECT" \
        --boot-disk-size="$DISK_SIZE" \
        --boot-disk-type=pd-standard \
        --network="$NETWORK" \
        --metadata=startup-script="$(cat startup-script-simple.sh)" \
        --tags=telegram-bot \
        --description="Telegram Bot VM for monitoring Google Cloud resources"
    
    print_status "VM instance created successfully"
}

# Wait for VM to be ready
wait_for_vm_ready() {
    print_status "Waiting for VM to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" --command="echo 'VM is ready'" &>/dev/null; then
            print_status "VM is ready and accessible"
            return 0
        fi
        
        print_status "Waiting for VM to be ready... (attempt $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    print_error "VM did not become ready within expected time"
    return 1
}

# Deploy Telegram bot
deploy_telegram_bot() {
    print_status "Deploying Telegram bot to VM..."
    
    # Copy deployment files to VM
    gcloud compute scp --recurse . "$INSTANCE_NAME":~/telegram-bot --zone="$ZONE" --project="$PROJECT_ID"
    
    # Execute deployment commands on VM
    gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" --command="
        cd ~/telegram-bot
        chmod +x deploy-on-vm.sh
        ./deploy-on-vm.sh
    "
    
    print_status "Telegram bot deployment completed"
}

# Get connection information
show_connection_info() {
    print_status "Deployment completed successfully!"
    echo
    echo "Connection Information:"
    echo "======================"
    echo "Instance Name: $INSTANCE_NAME"
    echo "Zone: $ZONE"
    echo "Project ID: $PROJECT_ID"
    echo
    echo "To connect to the VM:"
    echo "gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --project=$PROJECT_ID"
    echo
    echo "To view logs:"
    echo "gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --project=$PROJECT_ID --command='docker logs gcloud-telegram-bot'"
    echo
    echo "To restart the bot:"
    echo "gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --project=$PROJECT_ID --command='cd ~/telegram-bot && docker-compose restart'"
    echo
    echo "To stop the bot:"
    echo "gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --project=$PROJECT_ID --command='cd ~/telegram-bot && docker-compose down'"
}

# Main deployment flow
main() {
    print_status "Starting Telegram Bot deployment to Google Cloud..."
    echo
    
    check_prerequisites
    create_firewall_rule
    create_vm_instance
    wait_for_vm_ready
    deploy_telegram_bot
    show_connection_info
}

# Run main function
main "$@"
