#!/bin/bash

# =============================================================================
# QUICK DEPLOYMENT SCRIPT FOR POLKADOT & ACALA ON GOOGLE CLOUD
# This script provides a streamlined deployment process
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if we're in the right directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ ! -f "$PROJECT_ROOT/gcp.env" ]; then
    print_error "gcp.env file not found. Please ensure you're in the correct project directory."
    exit 1
fi

print_header "Polkadot & Acala Quick Deployment"

# Check prerequisites
print_status "Checking prerequisites..."

if ! command -v gcloud &> /dev/null; then
    print_error "Google Cloud SDK is not installed. Please install it first:"
    echo "https://cloud.google.com/sdk/docs/install"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    print_warning "Docker is not installed locally, but will be installed on the instances."
fi

# Load configuration
source "$PROJECT_ROOT/gcp.env"

print_status "Configuration loaded from gcp.env"
print_status "Project ID: $GOOGLE_CLOUD_PROJECT_ID"
print_status "Region: $GOOGLE_CLOUD_REGION"

# Confirm deployment
echo ""
print_warning "This will deploy the following resources:"
echo "  - Polkadot node (e2-standard-4, 100GB SSD)"
echo "  - Acala node (e2-standard-4, 100GB SSD)"
echo "  - Firewall rules and monitoring"
echo "  - Estimated cost: ~$330-460/month"
echo ""

read -p "Do you want to proceed with deployment? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Deployment cancelled."
    exit 0
fi

# Run the main deployment script
print_status "Starting deployment..."
print_status "This may take 10-15 minutes..."

cd "$PROJECT_ROOT"
./scripts/deploy-polkadot-acala-gcp.sh

# Check if deployment was successful
if [ $? -eq 0 ]; then
    print_header "Deployment Successful!"
    
    # Get instance IPs
    POLKADOT_IP=$(gcloud compute instances describe defimon-polkadot-node \
        --zone=us-central1-a \
        --format="value(networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null || echo "N/A")
    
    ACALA_IP=$(gcloud compute instances describe defimon-acala-node \
        --zone=us-central1-b \
        --format="value(networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null || echo "N/A")
    
    echo ""
    print_status "Your nodes are now running:"
    echo "  Polkadot RPC: http://$POLKADOT_IP:9944"
    echo "  Acala RPC: http://$ACALA_IP:9949"
    echo "  Polkadot Prometheus: http://$POLKADOT_IP:9090"
    echo "  Acala Prometheus: http://$ACALA_IP:9091"
    echo ""
    print_warning "Note: Nodes will take 24-48 hours to fully sync"
    echo ""
    print_status "Check POLKADOT_ACALA_DEPLOYMENT_SUMMARY.md for detailed information"
    print_status "Run './scripts/manage-polkadot-acala.sh' for management commands"
    
else
    print_error "Deployment failed. Check the logs above for details."
    exit 1
fi
