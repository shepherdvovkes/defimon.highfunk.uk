#!/bin/bash

# =============================================================================
# POLKADOT & ACALA MANAGEMENT SCRIPT
# Provides easy management commands for deployed nodes
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

# Instance configuration
POLKADOT_INSTANCE_NAME="defimon-polkadot-node"
ACALA_INSTANCE_NAME="defimon-acala-node"
POLKADOT_ZONE="us-central1-a"
ACALA_ZONE="us-central1-b"
POLKADOT_PORT=9944
ACALA_PORT=9949

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

# Function to get instance IPs
get_instance_ips() {
    POLKADOT_IP=$(gcloud compute instances describe "$POLKADOT_INSTANCE_NAME" \
        --zone="$POLKADOT_ZONE" \
        --format="value(networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null || echo "N/A")
    
    ACALA_IP=$(gcloud compute instances describe "$ACALA_INSTANCE_NAME" \
        --zone="$ACALA_ZONE" \
        --format="value(networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null || echo "N/A")
}

# Function to check instance status
check_status() {
    print_header "Instance Status"
    
    echo "Polkadot Node:"
    gcloud compute instances describe "$POLKADOT_INSTANCE_NAME" \
        --zone="$POLKADOT_ZONE" \
        --format="table(name,status,zone,networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null || echo "  Instance not found"
    
    echo ""
    echo "Acala Node:"
    gcloud compute instances describe "$ACALA_INSTANCE_NAME" \
        --zone="$ACALA_ZONE" \
        --format="table(name,status,zone,networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null || echo "  Instance not found"
}

# Function to start instances
start_instances() {
    print_header "Starting Instances"
    
    print_status "Starting Polkadot node..."
    gcloud compute instances start "$POLKADOT_INSTANCE_NAME" --zone="$POLKADOT_ZONE"
    
    print_status "Starting Acala node..."
    gcloud compute instances start "$ACALA_INSTANCE_NAME" --zone="$ACALA_ZONE"
    
    print_success "Instances started successfully"
    check_status
}

# Function to stop instances
stop_instances() {
    print_header "Stopping Instances"
    
    print_status "Stopping Polkadot node..."
    gcloud compute instances stop "$POLKADOT_INSTANCE_NAME" --zone="$POLKADOT_ZONE"
    
    print_status "Stopping Acala node..."
    gcloud compute instances stop "$ACALA_INSTANCE_NAME" --zone="$ACALA_ZONE"
    
    print_success "Instances stopped successfully"
    check_status
}

# Function to restart instances
restart_instances() {
    print_header "Restarting Instances"
    
    print_status "Restarting Polkadot node..."
    gcloud compute instances reset "$POLKADOT_INSTANCE_NAME" --zone="$POLKADOT_ZONE"
    
    print_status "Restarting Acala node..."
    gcloud compute instances reset "$ACALA_INSTANCE_NAME" --zone="$ACALA_ZONE"
    
    print_success "Instances restarted successfully"
    check_status
}

# Function to view logs
view_logs() {
    local instance_name=$1
    local zone=$2
    local container_name=$3
    
    print_header "Viewing Logs for $instance_name"
    
    gcloud compute ssh "$instance_name" --zone="$zone" --command="docker logs $container_name --tail 50"
}

# Function to check sync status
check_sync_status() {
    print_header "Checking Sync Status"
    
    get_instance_ips
    
    if [ "$POLKADOT_IP" != "N/A" ]; then
        print_status "Checking Polkadot sync status..."
        gcloud compute ssh "$POLKADOT_INSTANCE_NAME" --zone="$POLKADOT_ZONE" \
            --command="docker logs polkadot-node --tail 20 | grep -E '(Imported|Finalized|Syncing)'" 2>/dev/null || echo "  Unable to check Polkadot sync status"
    fi
    
    if [ "$ACALA_IP" != "N/A" ]; then
        print_status "Checking Acala sync status..."
        gcloud compute ssh "$ACALA_INSTANCE_NAME" --zone="$ACALA_ZONE" \
            --command="docker logs acala-node --tail 20 | grep -E '(Imported|Finalized|Syncing)'" 2>/dev/null || echo "  Unable to check Acala sync status"
    fi
}

# Function to check resource usage
check_resources() {
    print_header "Resource Usage"
    
    print_status "Polkadot node resources:"
    gcloud compute ssh "$POLKADOT_INSTANCE_NAME" --zone="$POLKADOT_ZONE" \
        --command="echo 'CPU and Memory:'; top -bn1 | grep 'Cpu(s)' && free -h && echo 'Disk Usage:'; df -h" 2>/dev/null || echo "  Unable to check Polkadot resources"
    
    echo ""
    print_status "Acala node resources:"
    gcloud compute ssh "$ACALA_INSTANCE_NAME" --zone="$ACALA_ZONE" \
        --command="echo 'CPU and Memory:'; top -bn1 | grep 'Cpu(s)' && free -h && echo 'Disk Usage:'; df -h" 2>/dev/null || echo "  Unable to check Acala resources"
}

# Function to create backup
create_backup() {
    print_header "Creating Backups"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    print_status "Creating Polkadot backup..."
    gcloud compute disks snapshot polkadot-data-disk \
        --snapshot-names="polkadot-backup-$timestamp" \
        --zone="$POLKADOT_ZONE" \
        --description="Polkadot backup created on $(date)"
    
    print_status "Creating Acala backup..."
    gcloud compute disks snapshot acala-data-disk \
        --snapshot-names="acala-backup-$timestamp" \
        --zone="$ACALA_ZONE" \
        --description="Acala backup created on $(date)"
    
    print_success "Backups created successfully"
}

# Function to list backups
list_backups() {
    print_header "Available Backups"
    
    echo "Polkadot backups:"
    gcloud compute snapshots list --filter="name~polkadot-backup" --format="table(name,creationTimestamp,description)"
    
    echo ""
    echo "Acala backups:"
    gcloud compute snapshots list --filter="name~acala-backup" --format="table(name,creationTimestamp,description)"
}

# Function to test connectivity
test_connectivity() {
    print_header "Testing Connectivity"
    
    get_instance_ips
    
    if [ "$POLKADOT_IP" != "N/A" ]; then
        print_status "Testing Polkadot RPC..."
        curl -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"system_health","params":[],"id":1}' \
            "http://$POLKADOT_IP:$POLKADOT_PORT" 2>/dev/null | jq . 2>/dev/null || echo "  Unable to connect to Polkadot RPC"
    fi
    
    if [ "$ACALA_IP" != "N/A" ]; then
        print_status "Testing Acala RPC..."
        curl -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"system_health","params":[],"id":1}' \
            "http://$ACALA_IP:$ACALA_PORT" 2>/dev/null | jq . 2>/dev/null || echo "  Unable to connect to Acala RPC"
    fi
}

# Function to show endpoints
show_endpoints() {
    print_header "Node Endpoints"
    
    get_instance_ips
    
    echo "Polkadot Node:"
    echo "  RPC Endpoint: http://$POLKADOT_IP:$POLKADOT_PORT"
    echo "  WebSocket: ws://$POLKADOT_IP:$POLKADOT_PORT"
    echo "  Prometheus: http://$POLKADOT_IP:9090"
    
    echo ""
    echo "Acala Node:"
    echo "  RPC Endpoint: http://$ACALA_IP:$ACALA_PORT"
    echo "  WebSocket: ws://$ACALA_IP:$ACALA_PORT"
    echo "  Prometheus: http://$ACALA_IP:9091"
}

# Function to show costs
show_costs() {
    print_header "Cost Estimation"
    
    echo "Current estimated monthly costs:"
    echo "  Polkadot Instance (e2-standard-4): ~$150-200"
    echo "  Acala Instance (e2-standard-4): ~$150-200"
    echo "  Storage (200GB SSD): ~$20-40"
    echo "  Network: ~$10-20"
    echo "  Total: ~$330-460/month"
    echo ""
    echo "To view actual costs, visit:"
    echo "  https://console.cloud.google.com/billing"
}

# Function to show help
show_help() {
    print_header "Polkadot & Acala Management Commands"
    
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  status          - Check instance status"
    echo "  start           - Start all instances"
    echo "  stop            - Stop all instances"
    echo "  restart         - Restart all instances"
    echo "  logs            - View container logs"
    echo "  sync            - Check sync status"
    echo "  resources       - Check resource usage"
    echo "  backup          - Create disk backups"
    echo "  backups         - List available backups"
    echo "  test            - Test RPC connectivity"
    echo "  endpoints       - Show node endpoints"
    echo "  costs           - Show cost estimation"
    echo "  help            - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 logs polkadot"
    echo "  $0 backup"
}

# Main script logic
case "${1:-help}" in
    "status")
        check_status
        ;;
    "start")
        start_instances
        ;;
    "stop")
        stop_instances
        ;;
    "restart")
        restart_instances
        ;;
    "logs")
        case "$2" in
            "polkadot")
                view_logs "$POLKADOT_INSTANCE_NAME" "$POLKADOT_ZONE" "polkadot-node"
                ;;
            "acala")
                view_logs "$ACALA_INSTANCE_NAME" "$ACALA_ZONE" "acala-node"
                ;;
            *)
                print_error "Please specify 'polkadot' or 'acala' for logs"
                echo "Usage: $0 logs [polkadot|acala]"
                ;;
        esac
        ;;
    "sync")
        check_sync_status
        ;;
    "resources")
        check_resources
        ;;
    "backup")
        create_backup
        ;;
    "backups")
        list_backups
        ;;
    "test")
        test_connectivity
        ;;
    "endpoints")
        show_endpoints
        ;;
    "costs")
        show_costs
        ;;
    "help"|*)
        show_help
        ;;
esac
