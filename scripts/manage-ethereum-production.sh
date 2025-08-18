#!/bin/bash

# DEFIMON Ethereum Nodes Production Management Script
# This script provides management functions for Ethereum nodes running on GCP

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
CONFIG_FILE="$PROJECT_ROOT/.env"

# Load configuration
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: .env file not found. Please copy scripts/gcp-production.env to .env and configure it.${NC}"
    exit 1
fi

source "$CONFIG_FILE"

# VM instance name
VM_NAME="ethereum-production"

# Function to print colored output
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    if ! command_exists gcloud; then
        print_error "Google Cloud SDK is not installed."
        exit 1
    fi
    
    if ! command_exists jq; then
        print_warning "jq is not installed. Some features may not work properly."
    fi
}

# Get VM status
get_vm_status() {
    print_status "Getting VM status..."
    
    gcloud compute instances describe "$VM_NAME" \
        --zone="$GOOGLE_CLOUD_ZONE" \
        --format="table(name,status,machineType,zone,networkInterfaces[0].accessConfigs[0].natIP)"
}

# Get VM external IP
get_vm_ip() {
    VM_IP=$(gcloud compute instances describe "$VM_NAME" \
        --zone="$GOOGLE_CLOUD_ZONE" \
        --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
    
    if [ -n "$VM_IP" ]; then
        print_success "VM external IP: $VM_IP"
        echo "$VM_IP"
    else
        print_error "Could not get VM IP"
        return 1
    fi
}

# Start VM
start_vm() {
    print_status "Starting VM..."
    
    gcloud compute instances start "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE"
    
    # Wait for VM to be ready
    print_status "Waiting for VM to be ready..."
    sleep 60
    
    print_success "VM started successfully"
}

# Stop VM
stop_vm() {
    print_status "Stopping VM..."
    
    gcloud compute instances stop "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE"
    
    print_success "VM stopped successfully"
}

# Restart VM
restart_vm() {
    print_status "Restarting VM..."
    
    gcloud compute instances reset "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE"
    
    # Wait for VM to be ready
    print_status "Waiting for VM to be ready..."
    sleep 120
    
    print_success "VM restarted successfully"
}

# SSH into VM
ssh_to_vm() {
    print_status "Connecting to VM via SSH..."
    
    gcloud compute ssh "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE"
}

# Check services status
check_services() {
    print_status "Checking services status..."
    
    gcloud compute ssh "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE" --command="
        cd /opt/defimon
        docker-compose ps
        echo '--- Service Logs ---'
        docker-compose logs --tail=20
    "
}

# View specific service logs
view_logs() {
    SERVICE_NAME=${1:-"all"}
    
    print_status "Viewing logs for service: $SERVICE_NAME"
    
    if [ "$SERVICE_NAME" = "all" ]; then
        gcloud compute ssh "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE" --command="
            cd /opt/defimon
            docker-compose logs --tail=50
        "
    else
        gcloud compute ssh "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE" --command="
            cd /opt/defimon
            docker-compose logs --tail=50 $SERVICE_NAME
        "
    fi
}

# Restart services
restart_services() {
    SERVICE_NAME=${1:-"all"}
    
    print_status "Restarting services: $SERVICE_NAME"
    
    if [ "$SERVICE_NAME" = "all" ]; then
        gcloud compute ssh "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE" --command="
            cd /opt/defimon
            docker-compose restart
        "
    else
        gcloud compute ssh "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE" --command="
            cd /opt/defimon
            docker-compose restart $SERVICE_NAME
        "
    fi
    
    print_success "Services restarted"
}

# Check Ethereum node sync status
check_sync_status() {
    print_status "Checking Ethereum node sync status..."
    
    VM_IP=$(get_vm_ip)
    
    if [ -n "$VM_IP" ]; then
        echo "--- Geth Sync Status ---"
        curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
            "https://$DOMAIN/eth/" | jq .
        
        echo "--- Lighthouse Sync Status ---"
        curl -s "https://$DOMAIN/beacon/syncing" | jq .
        
        echo "--- Node Health ---"
        curl -s "https://$DOMAIN/health"
    else
        print_error "Could not get VM IP"
    fi
}

# Check monitoring metrics
check_metrics() {
    print_status "Checking monitoring metrics..."
    
    VM_IP=$(get_vm_ip)
    
    if [ -n "$VM_IP" ]; then
        echo "--- Prometheus Targets ---"
        curl -s -u admin:admin123 "https://$DOMAIN/metrics/api/v1/targets" | jq .
        
        echo "--- Grafana Status ---"
        curl -s "https://$DOMAIN/api/health" | jq .
    else
        print_error "Could not get VM IP"
    fi
}

# Backup node data
backup_data() {
    print_status "Starting backup of node data..."
    
    gcloud compute ssh "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE" --command="
        cd /opt/defimon
        ./backup-ethereum.sh
    "
    
    print_success "Backup completed"
}

# Update SSL certificate
update_ssl() {
    print_status "Updating SSL certificate..."
    
    gcloud compute ssh "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE" --command="
        certbot renew --force-renewal
        docker restart nginx-proxy
    "
    
    print_success "SSL certificate updated"
}

# Scale VM resources
scale_vm() {
    MACHINE_TYPE=${1:-"e2-standard-4"}
    
    print_status "Scaling VM to machine type: $MACHINE_TYPE"
    
    # Stop VM first
    stop_vm
    
    # Change machine type
    gcloud compute instances set-machine-type "$VM_NAME" \
        --machine-type="$MACHINE_TYPE" \
        --zone="$GOOGLE_CLOUD_ZONE"
    
    # Start VM
    start_vm
    
    print_success "VM scaled successfully"
}

# Monitor resources
monitor_resources() {
    print_status "Monitoring VM resources..."
    
    gcloud compute ssh "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE" --command="
        echo '--- System Resources ---'
        free -h
        df -h
        echo '--- Disk Usage ---'
        lsblk
        echo '--- Ethereum Data Disk ---'
        df -h /mnt/ethereum-data
        echo '--- Docker Resources ---'
        docker stats --no-stream
        echo '--- Process List ---'
        ps aux --sort=-%cpu | head -10
    "
}

# View NGINX access logs
view_nginx_logs() {
    print_status "Viewing NGINX access logs..."
    
    gcloud compute ssh "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE" --command="
        cd /opt/defimon
        tail -50 logs/access.log
    "
}

# View NGINX error logs
view_nginx_errors() {
    print_status "Viewing NGINX error logs..."
    
    gcloud compute ssh "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE" --command="
        cd /opt/defimon
        tail -50 logs/error.log
    "
}

# Test endpoints
test_endpoints() {
    print_status "Testing endpoints..."
    
    VM_IP=$(get_vm_ip)
    
    if [ -n "$VM_IP" ]; then
        echo "--- Health Check ---"
        curl -s "https://$DOMAIN/health"
        
        echo -e "\n--- Status Check ---"
        curl -s "https://$DOMAIN/status"
        
        echo -e "\n--- Ethereum RPC ---"
        curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
            "https://$DOMAIN/eth/"
        
        echo -e "\n--- Beacon API ---"
        curl -s "https://$DOMAIN/beacon/genesis" | jq .
    else
        print_error "Could not get VM IP"
    fi
}

# Check disk status
check_disk_status() {
    print_status "Checking disk status..."
    
    gcloud compute ssh "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE" --command="
        echo '--- Disk Information ---'
        lsblk -f
        echo '--- Mount Points ---'
        mount | grep ethereum
        echo '--- Disk Usage ---'
        df -h /mnt/ethereum-data
        echo '--- Directory Contents ---'
        ls -la /mnt/ethereum-data/
        echo '--- Geth Data Size ---'
        du -sh /mnt/ethereum-data/geth/chaindata 2>/dev/null || echo 'Geth data not yet synced'
        echo '--- Lighthouse Data Size ---'
        du -sh /mnt/ethereum-data/lighthouse/beacon 2>/dev/null || echo 'Lighthouse data not yet synced'
    "
}

# Show help
show_help() {
    echo "DEFIMON Ethereum Nodes Production Management Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  status              - Show VM status"
    echo "  ip                  - Get VM external IP"
    echo "  start               - Start VM"
    echo "  stop                - Stop VM"
    echo "  restart             - Restart VM"
    echo "  ssh                 - SSH into VM"
    echo "  services            - Check services status"
    echo "  logs [SERVICE]      - View service logs (default: all)"
    echo "  restart-services [SERVICE] - Restart services (default: all)"
    echo "  sync                - Check sync status"
    echo "  metrics             - Check monitoring metrics"
    echo "  backup              - Backup node data"
    echo "  ssl                 - Update SSL certificate"
    echo "  scale [MACHINE_TYPE] - Scale VM resources"
    echo "  monitor             - Monitor VM resources"
    echo "  nginx-logs          - View NGINX access logs"
    echo "  nginx-errors        - View NGINX error logs"
    echo "  test                - Test endpoints"
    echo "  disk                - Check disk status and usage"
    echo "  help                - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 logs geth"
    echo "  $0 restart-services nginx"
    echo "  $0 scale e2-standard-8"
}

# Main function
main() {
    check_prerequisites
    
    case "${1:-help}" in
        status)
            get_vm_status
            ;;
        ip)
            get_vm_ip
            ;;
        start)
            start_vm
            ;;
        stop)
            stop_vm
            ;;
        restart)
            restart_vm
            ;;
        ssh)
            ssh_to_vm
            ;;
        services)
            check_services
            ;;
        logs)
            view_logs "$2"
            ;;
        restart-services)
            restart_services "$2"
            ;;
        sync)
            check_sync_status
            ;;
        metrics)
            check_metrics
            ;;
        backup)
            backup_data
            ;;
        ssl)
            update_ssl
            ;;
        scale)
            scale_vm "$2"
            ;;
        monitor)
            monitor_resources
            ;;
        nginx-logs)
            view_nginx_logs
            ;;
        nginx-errors)
            view_nginx_errors
            ;;
        test)
            test_endpoints
            ;;
        disk)
            check_disk_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
