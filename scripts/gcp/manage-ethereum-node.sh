#!/bin/bash

# Ethereum Node Management Script for GCP
# This script provides easy management commands for your deployed Ethereum node

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE} $1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    if ! command_exists gcloud; then
        print_error "Google Cloud SDK is not installed. Please install it first."
        exit 1
    fi
}

# Get instance information
get_instance_info() {
    print_header "Ethereum Node Instance Information"
    
    print_status "Getting instance details..."
    
    # Get instance group information
    echo "=== Instance Group ==="
    gcloud compute instance-groups managed describe ethereum-node-group \
        --zone="$(gcloud config get-value compute/zone)" \
        --format="table(name,baseInstanceName,size,autoscaler.enabled,autoscaler.minNumReplicas,autoscaler.maxNumReplicas)"
    
    echo ""
    echo "=== Running Instances ==="
    gcloud compute instances list \
        --filter="name~ethereum-node" \
        --format="table(name,machineType,status,zone,internalIP,externalIP)"
    
    echo ""
    echo "=== Persistent Disks ==="
    gcloud compute disks list \
        --filter="name~ethereum" \
        --format="table(name,sizeGb,type,zone,status)"
    
    echo ""
    echo "=== Auto-scaling Status ==="
    gcloud compute instance-groups managed describe ethereum-node-group \
        --zone="$(gcloud config get-value compute/zone)" \
        --format="value(autoscaler.status)"
}

# Check node sync status
check_sync_status() {
    print_header "Ethereum Node Sync Status"
    
    # Get external IP of the instance
    EXTERNAL_IP=$(gcloud compute instances list \
        --filter="name~ethereum-node AND status=RUNNING" \
        --format="value(externalIP)" | head -1)
    
    if [ -z "$EXTERNAL_IP" ]; then
        print_error "No running Ethereum node instances found"
        return 1
    fi
    
    print_status "Checking sync status on $EXTERNAL_IP..."
    
    # Check Geth sync status
    echo "=== Geth Sync Status ==="
    if curl -s "http://$EXTERNAL_IP:8545" >/dev/null 2>&1; then
        SYNC_STATUS=$(curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
            "http://$EXTERNAL_IP:8545" | jq -r '.result')
        
        if [ "$SYNC_STATUS" = "false" ]; then
            print_success "Geth is fully synced!"
        else
            print_warning "Geth is still syncing: $SYNC_STATUS"
        fi
        
        # Get current block
        CURRENT_BLOCK=$(curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            "http://$EXTERNAL_IP:8545" | jq -r '.result')
        
        echo "Current block: $CURRENT_BLOCK"
    else
        print_error "Cannot connect to Geth RPC endpoint"
    fi
    
    echo ""
    echo "=== Lighthouse Sync Status ==="
    if curl -s "http://$EXTERNAL_IP:5052" >/dev/null 2>&1; then
        BEACON_INFO=$(curl -s "http://$EXTERNAL_IP:5052/eth/v1/node/syncing" | jq -r '.data')
        echo "Beacon sync status: $BEACON_INFO"
    else
        print_error "Cannot connect to Lighthouse API endpoint"
    fi
    
    echo ""
    echo "=== Monitoring Services ==="
    echo "Prometheus: http://$EXTERNAL_IP:9090"
    echo "Grafana: http://$EXTERNAL_IP:3000 (admin/admin)"
    echo "Node Exporter: http://$EXTERNAL_IP:9100"
}

# Scale the instance group
scale_instance_group() {
    print_header "Scale Instance Group"
    
    if [ -z "$1" ]; then
        echo "Usage: $0 scale <number_of_instances>"
        echo "Example: $0 scale 2"
        return 1
    fi
    
    NEW_SIZE=$1
    
    print_status "Scaling ethereum-node-group to $NEW_SIZE instances..."
    
    gcloud compute instance-groups managed resize ethereum-node-group \
        --size="$NEW_SIZE" \
        --zone="$(gcloud config get-value compute/zone)"
    
    print_success "Instance group scaled to $NEW_SIZE instances"
    
    # Wait for instances to be ready
    print_status "Waiting for instances to be ready..."
    sleep 30
    
    get_instance_info
}

# Monitor costs
monitor_costs() {
    print_header "Cost Monitoring"
    
    PROJECT_ID=$(gcloud config get-value project)
    REGION=$(gcloud config get-value compute/region)
    
    echo "=== DEFIMON Ethereum Node Cost Report ==="
    echo "Project: $PROJECT_ID"
    echo "Region: $REGION"
    echo "Date: $(date)"
    echo ""
    
    # Get current month's cost
    echo "=== Current Month Costs ==="
    echo "Billing Account: $(gcloud billing accounts list --format='value(ACCOUNT_ID)' | head -1)"
    echo "Project Billing Status:"
    gcloud billing projects describe $PROJECT_ID --format="value(billingAccountName,billingEnabled,projectId)"
    
    echo ""
    echo "=== Resource Usage ==="
    
    # Instance costs
    echo "Compute Engine Instances:"
    gcloud compute instances list --format="table(name,machineType,status,zone)" --filter="name~ethereum-node"
    
    echo ""
    echo "Persistent Disks:"
    gcloud compute disks list --format="table(name,sizeGb,type,zone)" --filter="name~ethereum"
    
    echo ""
    echo "=== Network Resources ==="
    gcloud compute addresses list --filter="name~ethereum" --format="table(name,address,status,region)" 2>/dev/null || echo "No static IPs found"
    
    echo ""
    echo "=== Firewall Rules ==="
    gcloud compute firewall-rules list --filter="name~ethereum" --format="table(name,network,direction,priority,sourceRanges.list())" 2>/dev/null || echo "No firewall rules found"
    
    echo ""
    echo "=== Estimated Monthly Cost ==="
    echo "Based on current usage patterns:"
    
    # Calculate estimated costs
    INSTANCE_COUNT=$(gcloud compute instances list --filter="name~ethereum-node" --format="value(machineType)" | wc -l)
    
    # Get actual machine types for more accurate cost estimation
    MACHINE_TYPES=$(gcloud compute instances list --filter="name~ethereum-node" --format="value(machineType)")
    INSTANCE_COST=0
    
    # Calculate cost based on machine type (rough estimates)
    for machine_type in $MACHINE_TYPES; do
        case $machine_type in
            "e2-standard-2") INSTANCE_COST=$((INSTANCE_COST + 50)) ;;
            "e2-standard-4") INSTANCE_COST=$((INSTANCE_COST + 100)) ;;
            "e2-standard-8") INSTANCE_COST=$((INSTANCE_COST + 200)) ;;
            "n2-standard-2") INSTANCE_COST=$((INSTANCE_COST + 70)) ;;
            "n2-standard-4") INSTANCE_COST=$((INSTANCE_COST + 140)) ;;
            "n2-standard-8") INSTANCE_COST=$((INSTANCE_COST + 280)) ;;
            *) INSTANCE_COST=$((INSTANCE_COST + 150)) ;; # Default estimate
        esac
    done
    
    DISK_SIZE=$(gcloud compute disks list --filter="name~ethereum" --format="value(sizeGb)" | awk '{sum+=$1} END {print sum+0}')
    DISK_COST=$((DISK_SIZE * 2))  # Rough estimate per GB per month
    
    NETWORK_COST=30  # Rough estimate for network egress
    
    TOTAL_ESTIMATE=$((INSTANCE_COST + DISK_COST + NETWORK_COST))
    
    echo "Instance costs: ~\$$INSTANCE_COST/month (based on $INSTANCE_COUNT instances)"
    echo "Storage costs: ~\$$DISK_COST/month (${DISK_SIZE}GB total)"
    echo "Network costs: ~\$$NETWORK_COST/month (estimated)"
    echo "Total estimated: ~\$$TOTAL_ESTIMATE/month"
    
    echo ""
    echo "=== Cost Optimization Tips ==="
    echo "1. Use preemptible instances for non-critical workloads"
    echo "2. Enable sustained use discounts for long-running instances"
    echo "3. Consider committed use contracts for predictable workloads"
    echo "4. Monitor and adjust auto-scaling policies"
    echo "5. Use appropriate machine types for your workload"
    
    echo ""
    echo "=== Budget Alerts ==="
    echo "Current budget alerts:"
    BILLING_ACCOUNT=$(gcloud billing accounts list --format="value(ACCOUNT_ID)" | head -1)
    if [ -n "$BILLING_ACCOUNT" ]; then
        gcloud billing budgets list --billing-account="$BILLING_ACCOUNT" --format="table(name,amount,thresholdRules)" 2>/dev/null || echo "No budgets configured or insufficient permissions"
    else
        echo "No billing account found"
    fi
}

# View logs
view_logs() {
    print_header "View Ethereum Node Logs"
    
    INSTANCE_NAME=$(gcloud compute instances list \
        --filter="name~ethereum-node AND status=RUNNING" \
        --format="value(name)" | head -1)
    
    if [ -z "$INSTANCE_NAME" ]; then
        print_error "No running Ethereum node instances found"
        return 1
    fi
    
    print_status "Viewing logs for instance: $INSTANCE_NAME"
    
    echo "=== Recent System Logs ==="
    gcloud compute instances get-serial-port-output "$INSTANCE_NAME" \
        --zone="$(gcloud config get-value compute/zone)" \
        --port=1 | tail -50
    
    echo ""
    echo "=== Docker Container Logs ==="
    echo "To view container logs, SSH into the instance and run:"
    echo "  docker-compose logs -f geth"
    echo "  docker-compose logs -f lighthouse"
    echo "  docker-compose logs -f prometheus"
    echo "  docker-compose logs -f grafana"
    echo "  docker-compose logs -f node-exporter"
}

# SSH into instance
ssh_instance() {
    print_header "SSH into Ethereum Node Instance"
    
    INSTANCE_NAME=$(gcloud compute instances list \
        --filter="name~ethereum-node AND status=RUNNING" \
        --format="value(name)" | head -1)
    
    if [ -z "$INSTANCE_NAME" ]; then
        print_error "No running Ethereum node instances found"
        return 1
    fi
    
    print_status "Connecting to instance: $INSTANCE_NAME"
    
    gcloud compute ssh "$INSTANCE_NAME" \
        --zone="$(gcloud config get-value compute/zone)"
}

# Stop all instances
stop_instances() {
    print_header "Stop All Ethereum Node Instances"
    
    print_warning "This will stop all running Ethereum node instances"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Operation cancelled"
        return 0
    fi
    
    print_status "Stopping all instances..."
    
    gcloud compute instance-groups managed resize ethereum-node-group \
        --size=0 \
        --zone="$(gcloud config get-value compute/zone)"
    
    print_success "All instances stopped"
}

# Start instances
start_instances() {
    print_header "Start Ethereum Node Instances"
    
    if [ -z "$1" ]; then
        INSTANCE_COUNT=1
    else
        INSTANCE_COUNT=$1
    fi
    
    print_status "Starting $INSTANCE_COUNT instances..."
    
    gcloud compute instance-groups managed resize ethereum-node-group \
        --size="$INSTANCE_COUNT" \
        --zone="$(gcloud config get-value compute/zone)"
    
    print_success "Started $INSTANCE_COUNT instances"
    
    # Wait for instances to be ready
    print_status "Waiting for instances to be ready..."
    sleep 30
    
    get_instance_info
}

# Check monitoring status
check_monitoring() {
    print_header "Monitoring Status Check"
    
    INSTANCE_NAME=$(gcloud compute instances list \
        --filter="name~ethereum-node AND status=RUNNING" \
        --format="value(name)" | head -1)
    
    if [ -z "$INSTANCE_NAME" ]; then
        print_error "No running Ethereum node instances found"
        return 1
    fi
    
    EXTERNAL_IP=$(gcloud compute instances list \
        --filter="name=$INSTANCE_NAME" \
        --format="value(externalIP)")
    
    echo "=== Service Health Check ==="
    
    # Check Prometheus
    if curl -s "http://$EXTERNAL_IP:9090" >/dev/null 2>&1; then
        print_success "Prometheus: Running (http://$EXTERNAL_IP:9090)"
    else
        print_error "Prometheus: Not accessible"
    fi
    
    # Check Grafana
    if curl -s "http://$EXTERNAL_IP:3000" >/dev/null 2>&1; then
        print_success "Grafana: Running (http://$EXTERNAL_IP:3000)"
    else
        print_error "Grafana: Not accessible"
    fi
    
    # Check Node Exporter
    if curl -s "http://$EXTERNAL_IP:9100" >/dev/null 2>&1; then
        print_success "Node Exporter: Running (http://$EXTERNAL_IP:9100)"
    else
        print_error "Node Exporter: Not accessible"
    fi
    
    echo ""
    echo "=== Access Information ==="
    echo "Prometheus: http://$EXTERNAL_IP:9090"
    echo "Grafana: http://$EXTERNAL_IP:3000 (admin/admin)"
    echo "Node Exporter: http://$EXTERNAL_IP:9100"
    echo "Geth RPC: http://$EXTERNAL_IP:8545"
    echo "Lighthouse API: http://$EXTERNAL_IP:5052"
}

# Clean up resources
cleanup() {
    print_header "Clean Up GCP Resources"
    
    print_warning "This will delete ALL GCP resources created for the Ethereum node"
    print_warning "This action cannot be undone!"
    read -p "Are you absolutely sure? Type 'DELETE' to confirm: " -r
    
    if [ "$REPLY" != "DELETE" ]; then
        print_warning "Cleanup cancelled"
        return 0
    fi
    
    ZONE=$(gcloud config get-value compute/zone)
    REGION=$(gcloud config get-value compute/region)
    
    print_status "Cleaning up resources..."
    
    # Delete instance group
    gcloud compute instance-groups managed delete ethereum-node-group \
        --zone="$ZONE" --quiet || true
    
    # Delete instance template
    gcloud compute instance-templates delete ethereum-node-template --quiet || true
    
    # Delete health check
    gcloud compute health-checks delete ethereum-node-health-check --quiet || true
    
    # Delete persistent disks
    gcloud compute disks delete ethereum-data-disk --zone="$ZONE" --quiet || true
    gcloud compute disks delete lighthouse-data-disk --zone="$ZONE" --quiet || true
    
    # Delete firewall rules
    gcloud compute firewall-rules delete defimon-allow-internal --quiet || true
    gcloud compute firewall-rules delete defimon-allow-external --quiet || true
    
    # Delete network
    gcloud compute networks delete defimon-network --quiet || true
    
    # Delete service account
    gcloud iam service-accounts delete "defimon-infrastructure@$(gcloud config get-value project).iam.gserviceaccount.com" --quiet || true
    
    print_success "All resources cleaned up successfully!"
}

# Show help
show_help() {
    print_header "Ethereum Node Management Commands"
    
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  info                    - Show instance information"
    echo "  status                  - Check node sync status"
    echo "  monitoring              - Check monitoring services status"
    echo "  scale <number>          - Scale instance group to specified number"
    echo "  costs                   - Monitor costs and spending"
    echo "  logs                    - View instance logs"
    echo "  ssh                     - SSH into an instance"
    echo "  stop                    - Stop all instances"
    echo "  start [number]          - Start instances (default: 1)"
    echo "  cleanup                 - Delete all GCP resources"
    echo "  help                    - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 info                 - Show instance details"
    echo "  $0 status               - Check sync status"
    echo "  $0 monitoring           - Check monitoring services"
    echo "  $0 scale 2              - Scale to 2 instances"
    echo "  $0 costs                - View cost report"
    echo "  $0 cleanup              - Delete all resources"
}

# Main function
main() {
    check_prerequisites
    
    case "${1:-help}" in
        info)
            get_instance_info
            ;;
        status)
            check_sync_status
            ;;
        monitoring)
            check_monitoring
            ;;
        scale)
            scale_instance_group "$2"
            ;;
        costs)
            monitor_costs
            ;;
        logs)
            view_logs
            ;;
        ssh)
            ssh_instance
            ;;
        stop)
            stop_instances
            ;;
        start)
            start_instances "$2"
            ;;
        cleanup)
            cleanup
            ;;
        help|*)
            show_help
            ;;
    esac
}

# Run main function
main "$@"
