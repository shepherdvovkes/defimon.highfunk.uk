#!/bin/bash

# DEFIMON Ethereum Disks Management Script
# This script provides disk management functions for Ethereum nodes

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
}

# Get disk information
get_disk_info() {
    print_status "Getting disk information..."
    
    gcloud compute disks list \
        --filter="name~ethereum" \
        --format="table(name,sizeGb,type,zone,users,status)"
}

# Create additional disk
create_disk() {
    DISK_SIZE=${1:-2048}
    DISK_TYPE=${2:-"pd-standard"}
    
    print_status "Creating additional disk: ${DISK_SIZE}GB ${DISK_TYPE}"
    
    gcloud compute disks create ethereum-data-disk \
        --size="${DISK_SIZE}GB" \
        --type="$DISK_TYPE" \
        --zone="$GOOGLE_CLOUD_ZONE" \
        --description="Ethereum node data disk"
    
    print_success "Disk created successfully"
}

# Attach disk to VM
attach_disk() {
    DISK_NAME=${1:-"ethereum-data-disk"}
    
    print_status "Attaching disk $DISK_NAME to VM..."
    
    # Stop VM first
    gcloud compute instances stop "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE"
    
    # Attach disk
    gcloud compute instances attach-disk "$VM_NAME" \
        --disk="$DISK_NAME" \
        --zone="$GOOGLE_CLOUD_ZONE"
    
    # Start VM
    gcloud compute instances start "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE"
    
    print_success "Disk attached successfully"
}

# Detach disk from VM
detach_disk() {
    DISK_NAME=${1:-"ethereum-data-disk"}
    
    print_status "Detaching disk $DISK_NAME from VM..."
    
    # Stop VM first
    gcloud compute instances stop "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE"
    
    # Detach disk
    gcloud compute instances detach-disk "$VM_NAME" \
        --disk="$DISK_NAME" \
        --zone="$GOOGLE_CLOUD_ZONE"
    
    # Start VM
    gcloud compute instances start "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE"
    
    print_success "Disk detached successfully"
}

# Resize disk
resize_disk() {
    DISK_NAME=${1:-"ethereum-data-disk"}
    NEW_SIZE=${2:-4096}
    
    print_status "Resizing disk $DISK_NAME to ${NEW_SIZE}GB..."
    
    # Stop VM first
    gcloud compute instances stop "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE"
    
    # Resize disk
    gcloud compute disks resize "$DISK_NAME" \
        --size="${NEW_SIZE}GB" \
        --zone="$GOOGLE_CLOUD_ZONE"
    
    # Start VM
    gcloud compute instances start "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE"
    
    print_success "Disk resized successfully"
    
    # SSH to VM and resize filesystem
    print_status "Resizing filesystem on VM..."
    gcloud compute ssh "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE" --command="
        sudo resize2fs /dev/sdb
        df -h /mnt/ethereum-data
    "
}

# Create disk snapshot
create_snapshot() {
    DISK_NAME=${1:-"ethereum-data-disk"}
    SNAPSHOT_NAME="ethereum-data-$(date +%Y%m%d-%H%M%S)"
    
    print_status "Creating snapshot $SNAPSHOT_NAME from disk $DISK_NAME..."
    
    gcloud compute disks snapshot "$DISK_NAME" \
        --snapshot-names="$SNAPSHOT_NAME" \
        --zone="$GOOGLE_CLOUD_ZONE" \
        --description="Ethereum node data backup $(date)"
    
    print_success "Snapshot created: $SNAPSHOT_NAME"
}

# List snapshots
list_snapshots() {
    print_status "Listing disk snapshots..."
    
    gcloud compute snapshots list \
        --filter="name~ethereum-data" \
        --format="table(name,creationTimestamp,diskSizeGb,status)"
}

# Restore from snapshot
restore_from_snapshot() {
    SNAPSHOT_NAME=${1}
    
    if [ -z "$SNAPSHOT_NAME" ]; then
        print_error "Please provide snapshot name"
        exit 1
    fi
    
    print_status "Restoring disk from snapshot $SNAPSHOT_NAME..."
    
    # Stop VM
    gcloud compute instances stop "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE"
    
    # Detach current disk
    gcloud compute instances detach-disk "$VM_NAME" \
        --disk="ethereum-data-disk" \
        --zone="$GOOGLE_CLOUD_ZONE"
    
    # Create new disk from snapshot
    gcloud compute disks create ethereum-data-disk-restored \
        --source-snapshot="$SNAPSHOT_NAME" \
        --zone="$GOOGLE_CLOUD_ZONE"
    
    # Attach new disk
    gcloud compute instances attach-disk "$VM_NAME" \
        --disk="ethereum-data-disk-restored" \
        --zone="$GOOGLE_CLOUD_ZONE"
    
    # Start VM
    gcloud compute instances start "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE"
    
    print_success "Disk restored from snapshot successfully"
}

# Check disk health
check_disk_health() {
    print_status "Checking disk health..."
    
    gcloud compute ssh "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE" --command="
        echo '--- Disk Health Check ---'
        echo 'Disk Information:'
        lsblk -f
        echo ''
        echo 'Mount Points:'
        mount | grep ethereum
        echo ''
        echo 'Disk Usage:'
        df -h /mnt/ethereum-data
        echo ''
        echo 'Disk I/O Stats:'
        iostat -x 1 3
        echo ''
        echo 'Smart Disk Info:'
        sudo smartctl -a /dev/sdb 2>/dev/null || echo 'Smart monitoring not available'
    "
}

# Optimize disk performance
optimize_disk() {
    print_status "Optimizing disk performance..."
    
    gcloud compute ssh "$VM_NAME" --zone="$GOOGLE_CLOUD_ZONE" --command="
        echo '--- Disk Optimization ---'
        echo 'Current mount options:'
        mount | grep ethereum-data
        echo ''
        echo 'Optimizing mount options...'
        # Remount with optimized options
        sudo mount -o remount,noatime,nodiratime,data=writeback /mnt/ethereum-data
        echo 'New mount options:'
        mount | grep ethereum-data
        echo ''
        echo 'Updating fstab for persistence...'
        # Update fstab to persist optimized options
        sudo sed -i 's|/dev/sdb /mnt/ethereum-data ext4 defaults|/dev/sdb /mnt/ethereum-data ext4 noatime,nodiratime,data=writeback|' /etc/fstab
        echo 'fstab updated successfully'
    "
}

# Show help
show_help() {
    echo "DEFIMON Ethereum Disks Management Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  info                    - Show disk information"
    echo "  create [SIZE] [TYPE]    - Create new disk (default: 2048GB pd-standard)"
    echo "  attach [DISK_NAME]      - Attach disk to VM"
    echo "  detach [DISK_NAME]      - Detach disk from VM"
    echo "  resize [DISK_NAME] [SIZE] - Resize disk"
    echo "  snapshot [DISK_NAME]    - Create disk snapshot"
    echo "  snapshots               - List snapshots"
    echo "  restore [SNAPSHOT]      - Restore disk from snapshot"
    echo "  health                  - Check disk health"
    echo "  optimize                - Optimize disk performance"
    echo "  help                    - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 info"
    echo "  $0 create 4096 pd-ssd"
    echo "  $0 attach ethereum-data-disk"
    echo "  $0 resize ethereum-data-disk 4096"
    echo "  $0 snapshot ethereum-data-disk"
    echo "  $0 restore ethereum-data-20241201-120000"
}

# Main function
main() {
    check_prerequisites
    
    case "${1:-help}" in
        info)
            get_disk_info
            ;;
        create)
            create_disk "$2" "$3"
            ;;
        attach)
            attach_disk "$2"
            ;;
        detach)
            detach_disk "$2"
            ;;
        resize)
            resize_disk "$2" "$3"
            ;;
        snapshot)
            create_snapshot "$2"
            ;;
        snapshots)
            list_snapshots
            ;;
        restore)
            restore_from_snapshot "$2"
            ;;
        health)
            check_disk_health
            ;;
        optimize)
            optimize_disk
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
