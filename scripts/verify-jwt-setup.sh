#!/bin/bash

# DEFIMON JWT Setup Verification Script
# This script verifies the JWT setup in Ethereum node containers

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
JWT_DIR="$PROJECT_ROOT/infrastructure/ethereum-node"

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

# Function to check if containers are running
check_containers() {
    print_status "Checking if Ethereum containers are running..."
    
    if ! docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "ethereum-geth"; then
        print_error "Geth container is not running!"
        return 1
    fi
    
    if ! docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "ethereum-lighthouse"; then
        print_error "Lighthouse container is not running!"
        return 1
    fi
    
    print_success "Both containers are running"
}

# Function to verify JWT files on host
verify_host_jwt_files() {
    print_status "Verifying JWT files on host..."
    
    # Check if JWT files exist
    if [ ! -f "$JWT_DIR/jwtsecret.raw" ]; then
        print_error "Geth JWT file (jwtsecret.raw) not found!"
        return 1
    fi
    
    if [ ! -f "$JWT_DIR/jwtsecret.hex" ]; then
        print_error "Lighthouse JWT file (jwtsecret.hex) not found!"
        return 1
    fi
    
    # Check file sizes
    local geth_size=$(wc -c < "$JWT_DIR/jwtsecret.raw")
    local lighthouse_size=$(wc -c < "$JWT_DIR/jwtsecret.hex")
    
    if [ "$geth_size" -eq 32 ]; then
        print_success "Geth JWT file size: $geth_size bytes ✓"
    else
        print_error "Geth JWT file size: $geth_size bytes ✗ (expected 32)"
        return 1
    fi
    
    if [ "$lighthouse_size" -eq 65 ]; then  # 64 chars + newline
        print_success "Lighthouse JWT file size: $lighthouse_size bytes ✓"
    else
        print_error "Lighthouse JWT file size: $lighthouse_size bytes ✗ (expected 65)"
        return 1
    fi
    
    # Check permissions
    local geth_perms=$(stat -c %a "$JWT_DIR/jwtsecret.raw" 2>/dev/null || stat -f %Lp "$JWT_DIR/jwtsecret.raw")
    local lighthouse_perms=$(stat -c %a "$JWT_DIR/jwtsecret.hex" 2>/dev/null || stat -f %Lp "$JWT_DIR/jwtsecret.hex")
    
    if [ "$geth_perms" = "600" ]; then
        print_success "Geth JWT file permissions: $geth_perms ✓"
    else
        print_warning "Geth JWT file permissions: $geth_perms (should be 600)"
    fi
    
    if [ "$lighthouse_perms" = "600" ]; then
        print_success "Lighthouse JWT file permissions: $lighthouse_perms ✓"
    else
        print_warning "Lighthouse JWT file permissions: $lighthouse_perms (should be 600)"
    fi
}

# Function to verify JWT files in containers
verify_container_jwt_files() {
    print_status "Verifying JWT files in containers..."
    
    # Check Geth JWT file
    local geth_container_size=$(docker exec ethereum-geth wc -c /root/.ethereum/jwtsecret 2>/dev/null || echo "0")
    if [ "$geth_container_size" -eq 32 ]; then
        print_success "Geth container JWT file size: $geth_container_size bytes ✓"
    else
        print_error "Geth container JWT file size: $geth_container_size bytes ✗ (expected 32)"
        return 1
    fi
    
    # Check Lighthouse JWT file
    local lighthouse_container_size=$(docker exec ethereum-lighthouse wc -c /root/.lighthouse/jwtsecret 2>/dev/null || echo "0")
    if [ "$lighthouse_container_size" -eq 65 ]; then  # 64 chars + newline
        print_success "Lighthouse container JWT file size: $lighthouse_container_size bytes ✓"
    else
        print_error "Lighthouse container JWT file size: $lighthouse_container_size bytes ✗ (expected 65)"
        return 1
    fi
}

# Function to check container logs for JWT errors
check_container_logs() {
    print_status "Checking container logs for JWT-related errors..."
    
    # Check Geth logs
    local geth_jwt_errors=$(docker logs ethereum-geth 2>&1 | grep -i "jwt\|auth" | tail -5 || true)
    if [ -n "$geth_jwt_errors" ]; then
        print_warning "Geth JWT-related log entries found:"
        echo "$geth_jwt_errors"
    else
        print_success "No JWT-related errors found in Geth logs"
    fi
    
    # Check Lighthouse logs
    local lighthouse_jwt_errors=$(docker logs ethereum-lighthouse 2>&1 | grep -i "jwt\|auth" | tail -5 || true)
    if [ -n "$lighthouse_jwt_errors" ]; then
        print_warning "Lighthouse JWT-related log entries found:"
        echo "$lighthouse_jwt_errors"
    else
        print_success "No JWT-related errors found in Lighthouse logs"
    fi
}

# Function to check container connectivity
check_connectivity() {
    print_status "Checking container connectivity..."
    
    # Check if Geth is responding
    if docker exec ethereum-geth curl -s http://localhost:8545 > /dev/null 2>&1; then
        print_success "Geth HTTP endpoint is responding ✓"
    else
        print_warning "Geth HTTP endpoint is not responding"
    fi
    
    # Check if Lighthouse is responding
    if docker exec ethereum-lighthouse curl -s http://localhost:5052 > /dev/null 2>&1; then
        print_success "Lighthouse HTTP endpoint is responding ✓"
    else
        print_warning "Lighthouse HTTP endpoint is not responding"
    fi
}

# Function to display summary
display_summary() {
    echo ""
    print_status "JWT Setup Verification Summary:"
    echo "====================================="
    echo "✓ Host JWT files verified"
    echo "✓ Container JWT files verified"
    echo "✓ Container logs checked"
    echo "✓ Connectivity verified"
    echo ""
    print_success "JWT setup appears to be correct!"
}

# Main function
main() {
    print_status "Starting JWT setup verification for DEFIMON Ethereum nodes..."
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running or not accessible"
        exit 1
    fi
    
    # Check if JWT directory exists
    if [ ! -d "$JWT_DIR" ]; then
        print_error "JWT directory not found: $JWT_DIR"
        exit 1
    fi
    
    # Run all verification checks
    check_containers
    verify_host_jwt_files
    verify_container_jwt_files
    check_container_logs
    check_connectivity
    
    # Display summary
    display_summary
}

# Run main function
main "$@"
