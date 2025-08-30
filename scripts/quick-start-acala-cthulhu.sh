#!/bin/bash

# =============================================================================
# QUICK START - ACALA CTHULHU ARCHIVE DEPLOYMENT
# Simple script to deploy Acala network on Cthulhu with full chain archive
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}ACALA CTHULHU QUICK START${NC}"
    echo -e "${PURPLE}================================${NC}"
}

print_info() {
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

# Check if running from the correct directory
check_directory() {
    if [ ! -f "gcp.env" ]; then
        print_error "Please run this script from the project root directory"
        print_info "Current directory: $(pwd)"
        print_info "Expected files: gcp.env"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v gcloud >/dev/null 2>&1; then
        print_error "Google Cloud SDK is not installed"
        print_info "Please install it from: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker is not installed"
        print_info "Please install Docker first"
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Show deployment information
show_deployment_info() {
    print_header
    echo
    print_info "This will deploy Acala network on Cthulhu with:"
    echo "  • Full chain archive mode (complete blockchain history)"
    echo "  • 10GB SSD storage for archive data (quota-constrained)"
    echo "  • e2-standard-8 machine (8 vCPU, 32GB RAM)"
    echo "  • Prometheus monitoring"
    echo "  • RPC and WebSocket endpoints"
    echo
    print_warning "Estimated cost: ~$311-422/month"
    echo
    print_info "Deployment will take 10-15 minutes"
    echo
}

# Confirm deployment
confirm_deployment() {
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled"
        exit 0
    fi
}

# Run the deployment
run_deployment() {
    print_info "Starting Acala Cthulhu deployment..."
    echo
    
    # Run the main deployment script
    ./scripts/deploy-acala-cthulhu-archive.sh
    
    if [ $? -eq 0 ]; then
        print_success "Deployment completed successfully!"
        echo
        print_info "Next steps:"
        echo "  1. Check deployment status: ./scripts/manage-acala-cthulhu.sh status"
        echo "  2. View logs: ./scripts/manage-acala-cthulhu.sh logs"
        echo "  3. Check sync progress: ./scripts/manage-acala-cthulhu.sh sync"
        echo "  4. Test connectivity: ./scripts/manage-acala-cthulhu.sh test"
        echo "  5. View endpoints: ./scripts/manage-acala-cthulhu.sh endpoints"
        echo
        print_info "Full documentation: ACALA_CTHULHU_DEPLOYMENT_SUMMARY.md"
    else
        print_error "Deployment failed. Check the logs above for details."
        exit 1
    fi
}

# Main function
main() {
    check_directory
    check_prerequisites
    show_deployment_info
    confirm_deployment
    run_deployment
}

# Run main function
main "$@"
