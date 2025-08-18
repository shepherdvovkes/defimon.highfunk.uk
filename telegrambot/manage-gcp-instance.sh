#!/bin/bash

# Google Cloud VM Instance Management Script for Telegram Bot
# This script provides easy management commands for the VM instance

set -e

# Configuration
PROJECT_ID="${GOOGLE_CLOUD_PROJECT_ID:-$(gcloud config get-value project)}"
INSTANCE_NAME="telegram-bot-vm"
ZONE="us-central1-a"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}[HEADER]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    if ! command -v gcloud &> /dev/null; then
        print_error "Google Cloud SDK is not installed"
        exit 1
    fi
    
    if [ -z "$PROJECT_ID" ]; then
        print_error "No project ID specified. Set GOOGLE_CLOUD_PROJECT_ID or run: gcloud config set project PROJECT_ID"
        exit 1
    fi
}

# Get instance status
get_instance_status() {
    gcloud compute instances describe "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" \
        --format="value(status)" 2>/dev/null || echo "NOT_FOUND"
}

# Start the VM instance
start_instance() {
    print_status "Starting VM instance: $INSTANCE_NAME"
    
    local status=$(get_instance_status)
    
    case $status in
        "RUNNING")
            print_warning "Instance is already running"
            ;;
        "STOPPED"|"TERMINATED")
            gcloud compute instances start "$INSTANCE_NAME" \
                --zone="$ZONE" \
                --project="$PROJECT_ID"
            print_status "Instance started successfully"
            ;;
        "NOT_FOUND")
            print_error "Instance not found. Please run the deployment script first."
            exit 1
            ;;
        *)
            print_warning "Instance status: $status"
            gcloud compute instances start "$INSTANCE_NAME" \
                --zone="$ZONE" \
                --project="$PROJECT_ID"
            ;;
    esac
}

# Stop the VM instance
stop_instance() {
    print_status "Stopping VM instance: $INSTANCE_NAME"
    
    local status=$(get_instance_status)
    
    if [ "$status" = "RUNNING" ]; then
        gcloud compute instances stop "$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID"
        print_status "Instance stopped successfully"
    else
        print_warning "Instance is not running (status: $status)"
    fi
}

# Restart the VM instance
restart_instance() {
    print_status "Restarting VM instance: $INSTANCE_NAME"
    
    local status=$(get_instance_status)
    
    if [ "$status" = "RUNNING" ]; then
        gcloud compute instances reset "$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID"
        print_status "Instance restarted successfully"
    else
        print_warning "Instance is not running (status: $status)"
    fi
}

# Delete the VM instance
delete_instance() {
    print_warning "This will permanently delete the VM instance and all its data!"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deleting VM instance: $INSTANCE_NAME"
        gcloud compute instances delete "$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" \
            --quiet
        print_status "Instance deleted successfully"
    else
        print_status "Operation cancelled"
    fi
}

# Connect to the VM instance
connect_instance() {
    local status=$(get_instance_status)
    
    if [ "$status" = "RUNNING" ]; then
        print_status "Connecting to VM instance: $INSTANCE_NAME"
        gcloud compute ssh "$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID"
    else
        print_error "Cannot connect: Instance is not running (status: $status)"
        exit 1
    fi
}

# View instance logs
view_logs() {
    local status=$(get_instance_status)
    
    if [ "$status" = "RUNNING" ]; then
        print_status "Fetching logs from VM instance: $INSTANCE_NAME"
        gcloud compute ssh "$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" \
            --command="cd ~/telegram-bot && docker logs gcloud-telegram-bot --tail=50"
    else
        print_error "Cannot fetch logs: Instance is not running (status: $status)"
        exit 1
    fi
}

# Check bot status
check_bot_status() {
    local status=$(get_instance_status)
    
    if [ "$status" = "RUNNING" ]; then
        print_status "Checking bot status on VM instance: $INSTANCE_NAME"
        gcloud compute ssh "$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" \
            --command="cd ~/telegram-bot && docker-compose ps && echo '--- Bot Logs ---' && docker logs gcloud-telegram-bot --tail=10"
    else
        print_error "Cannot check status: Instance is not running (status: $status)"
        exit 1
    fi
}

# Restart the bot
restart_bot() {
    local status=$(get_instance_status)
    
    if [ "$status" = "RUNNING" ]; then
        print_status "Restarting bot on VM instance: $INSTANCE_NAME"
        gcloud compute ssh "$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" \
            --command="cd ~/telegram-bot && docker-compose restart && echo 'Bot restarted successfully'"
    else
        print_error "Cannot restart bot: Instance is not running (status: $status)"
        exit 1
    fi
}

# Show instance information
show_instance_info() {
    print_header "Instance Information"
    echo "========================"
    echo "Name: $INSTANCE_NAME"
    echo "Zone: $ZONE"
    echo "Project: $PROJECT_ID"
    echo "Status: $(get_instance_status)"
    
    if [ "$(get_instance_status)" = "RUNNING" ]; then
        echo
        print_header "Instance Details"
        echo "=================="
        gcloud compute instances describe "$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" \
            --format="table(name,zone,machineType,status,internalIP,externalIP,creationTimestamp)"
        
        echo
        print_header "Disk Information"
        echo "=================="
        gcloud compute disks list \
            --filter="users:instances/$INSTANCE_NAME" \
            --project="$PROJECT_ID" \
            --format="table(name,sizeGb,type,status)"
    fi
}

# Monitor instance resources
monitor_resources() {
    local status=$(get_instance_status)
    
    if [ "$status" = "RUNNING" ]; then
        print_status "Monitoring resources on VM instance: $INSTANCE_NAME"
        gcloud compute ssh "$INSTANCE_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" \
            --command="echo '=== System Resources ===' && free -h && echo '=== Disk Usage ===' && df -h && echo '=== Docker Status ===' && docker stats --no-stream"
    else
        print_error "Cannot monitor: Instance is not running (status: $status)"
        exit 1
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  start       - Start the VM instance"
    echo "  stop        - Stop the VM instance"
    echo "  restart     - Restart the VM instance"
    echo "  delete      - Delete the VM instance (permanent)"
    echo "  connect     - SSH into the VM instance"
    echo "  logs        - View bot logs"
    echo "  status      - Check bot status"
    echo "  restart-bot - Restart the Telegram bot"
    echo "  info        - Show instance information"
    echo "  monitor     - Monitor instance resources"
    echo "  help        - Show this help message"
    echo
    echo "Examples:"
    echo "  $0 start        # Start the VM"
    echo "  $0 connect      # SSH into the VM"
    echo "  $0 logs         # View bot logs"
    echo "  $0 status       # Check bot status"
}

# Main function
main() {
    check_prerequisites
    
    case "${1:-help}" in
        "start")
            start_instance
            ;;
        "stop")
            stop_instance
            ;;
        "restart")
            restart_instance
            ;;
        "delete")
            delete_instance
            ;;
        "connect")
            connect_instance
            ;;
        "logs")
            view_logs
            ;;
        "status")
            check_bot_status
            ;;
        "restart-bot")
            restart_bot
            ;;
        "info")
            show_instance_info
            ;;
        "monitor")
            monitor_resources
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            print_error "Unknown command: $1"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
