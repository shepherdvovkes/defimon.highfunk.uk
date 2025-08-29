#!/bin/bash

# DEFIMON Crab Server Swap File Setup
# This script creates a 24GB swap file on the crab server

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
SWAP_SIZE_GB=24
SWAP_FILE="/swapfile"
SWAP_SIZE_BYTES=$((SWAP_SIZE_GB * 1024 * 1024 * 1024))

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
    echo -e "${PURPLE}  CRAB SERVER SWAP SETUP${NC}"
    echo -e "${PURPLE}================================${NC}"
}

check_existing_swap() {
    print_status "Checking existing swap configuration..."
    
    if swapon --show | grep -q "$SWAP_FILE"; then
        print_warning "Swap file $SWAP_FILE already exists and is active"
        CURRENT_SWAP_SIZE=$(swapon --show | grep "$SWAP_FILE" | awk '{print $3}')
        print_status "Current swap size: $CURRENT_SWAP_SIZE"
        return 1
    fi
    
    if [ -f "$SWAP_FILE" ]; then
        print_warning "Swap file $SWAP_FILE exists but is not active"
        return 1
    fi
    
    print_success "No existing swap file found"
    return 0
}

create_swap_file() {
    print_status "Creating $SWAP_SIZE_GB GB swap file..."
    
    # Check available disk space
    AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
    REQUIRED_SPACE=$((SWAP_SIZE_BYTES / 1024))
    
    if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        print_error "Insufficient disk space. Available: ${AVAILABLE_SPACE}KB, Required: ${REQUIRED_SPACE}KB"
        return 1
    fi
    
    # Create swap file
    print_status "Allocating $SWAP_SIZE_GB GB for swap file..."
    sudo fallocate -l ${SWAP_SIZE_GB}G "$SWAP_FILE"
    
    if [ $? -ne 0 ]; then
        print_warning "fallocate failed, trying dd method..."
        sudo dd if=/dev/zero of="$SWAP_FILE" bs=1G count=$SWAP_SIZE_GB
    fi
    
    # Set correct permissions
    sudo chmod 600 "$SWAP_FILE"
    
    # Make it a swap file
    print_status "Setting up swap file..."
    sudo mkswap "$SWAP_FILE"
    
    print_success "Swap file created successfully"
}

activate_swap() {
    print_status "Activating swap file..."
    sudo swapon "$SWAP_FILE"
    
    if [ $? -eq 0 ]; then
        print_success "Swap file activated successfully"
    else
        print_error "Failed to activate swap file"
        return 1
    fi
}

make_swap_permanent() {
    print_status "Making swap permanent in /etc/fstab..."
    
    # Check if entry already exists
    if grep -q "$SWAP_FILE" /etc/fstab; then
        print_warning "Swap file entry already exists in /etc/fstab"
        return 0
    fi
    
    # Add entry to /etc/fstab
    echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab
    
    print_success "Swap file added to /etc/fstab"
}

verify_swap() {
    print_status "Verifying swap configuration..."
    
    # Show swap information
    echo -e "${CYAN}Current swap configuration:${NC}"
    swapon --show
    
    echo -e "\n${CYAN}Memory and swap summary:${NC}"
    free -h
    
    echo -e "\n${CYAN}Swap usage:${NC}"
    cat /proc/swaps
}

optimize_swap_settings() {
    print_status "Optimizing swap settings..."
    
    # Set swappiness to 10 (prefer RAM over swap)
    if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
        echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
        print_success "Added vm.swappiness=10 to /etc/sysctl.conf"
    else
        print_warning "vm.swappiness already configured in /etc/sysctl.conf"
    fi
    
    # Apply settings immediately
    sudo sysctl vm.swappiness=10
}

main() {
    print_header
    
    print_status "Starting swap file setup on crab server..."
    print_status "Target swap size: $SWAP_SIZE_GB GB"
    
    # Check if running as root or with sudo
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run with sudo privileges"
        exit 1
    fi
    
    # Check existing swap
    if ! check_existing_swap; then
        print_warning "Existing swap detected. Do you want to continue? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_status "Setup cancelled by user"
            exit 0
        fi
    fi
    
    # Create swap file
    if ! create_swap_file; then
        print_error "Failed to create swap file"
        exit 1
    fi
    
    # Activate swap
    if ! activate_swap; then
        print_error "Failed to activate swap"
        exit 1
    fi
    
    # Make permanent
    make_swap_permanent
    
    # Optimize settings
    optimize_swap_settings
    
    # Verify setup
    verify_swap
    
    print_success "Swap file setup completed successfully!"
    print_status "The system now has an additional $SWAP_SIZE_GB GB of virtual memory"
    print_status "Swap file location: $SWAP_FILE"
    print_status "Swap will persist across reboots"
}

# Run main function
main "$@"
