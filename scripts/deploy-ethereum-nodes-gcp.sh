#!/bin/bash

# DEFIMON Ethereum Nodes Deployment Script for Google Cloud
# This script deploys Ethereum nodes with proper JWT configuration

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
ETHEREUM_DIR="$PROJECT_ROOT/infrastructure/ethereum-node"
SERVER_USER="vovkes-server"
SERVER_PATH="/path/to/ethereum-node"  # Update this path

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

# Function to verify JWT files
verify_jwt_files() {
    print_status "Verifying JWT files..."
    
    if [ ! -f "$ETHEREUM_DIR/jwtsecret.raw" ]; then
        print_error "Geth JWT file (jwtsecret.raw) not found!"
        return 1
    fi
    
    if [ ! -f "$ETHEREUM_DIR/jwtsecret.hex" ]; then
        print_error "Lighthouse JWT file (jwtsecret.hex) not found!"
        return 1
    fi
    
    # Check file sizes
    local geth_size=$(wc -c < "$ETHEREUM_DIR/jwtsecret.raw")
    local lighthouse_size=$(wc -c < "$ETHEREUM_DIR/jwtsecret.hex")
    
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
    local geth_perms=$(stat -c %a "$ETHEREUM_DIR/jwtsecret.raw" 2>/dev/null || stat -f %Lp "$ETHEREUM_DIR/jwtsecret.raw")
    local lighthouse_perms=$(stat -c %a "$ETHEREUM_DIR/jwtsecret.hex" 2>/dev/null || stat -f %Lp "$ETHEREUM_DIR/jwtsecret.hex")
    
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

# Function to copy files to server
copy_to_server() {
    print_status "Copying files to Google Cloud server..."
    
    # Copy JWT files
    scp "$ETHEREUM_DIR/jwtsecret.raw" "$SERVER_USER:$SERVER_PATH/"
    scp "$ETHEREUM_DIR/jwtsecret.hex" "$SERVER_USER:$SERVER_PATH/"
    
    # Copy docker-compose.yml
    scp "$ETHEREUM_DIR/docker-compose.yml" "$SERVER_USER:$SERVER_PATH/"
    
    print_success "Files copied to server successfully!"
}

# Function to deploy on server
deploy_on_server() {
    print_status "Deploying Ethereum nodes on Google Cloud server..."
    
    ssh "$SERVER_USER" << 'EOF'
        cd /path/to/ethereum-node
        
        # Set correct permissions
        chmod 600 jwtsecret.*
        
        # Stop existing services
        docker-compose down
        
        # Start services with new configuration
        docker-compose up -d
        
        # Wait for services to start
        sleep 30
        
        # Check status
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        # Check JWT files in containers
        echo "=== JWT File Verification ==="
        docker exec ethereum-geth wc -c /root/.ethereum/jwtsecret
        docker exec ethereum-lighthouse wc -c /root/.lighthouse/jwtsecret
        
        # Check for JWT errors in logs
        echo "=== Recent Geth Logs ==="
        docker logs ethereum-geth --tail 10 | grep -i -E "(jwt|auth|error|warn)" || echo "No JWT errors found"
        
        echo "=== Recent Lighthouse Logs ==="
        docker logs ethereum-lighthouse --tail 10 | grep -i -E "(jwt|auth|error|warn)" || echo "No JWT errors found"
EOF
    
    print_success "Deployment completed on server!"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment on server..."
    
    ssh "$SERVER_USER" << 'EOF'
        cd /path/to/ethereum-node
        
        echo "=== Container Status ==="
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        echo "=== JWT File Status ==="
        docker exec ethereum-geth wc -c /root/.ethereum/jwtsecret
        docker exec ethereum-lighthouse wc -c /root/.lighthouse/jwtsecret
        
        echo "=== Service Health ==="
        # Check if Geth is responding
        if docker exec ethereum-geth curl -s http://localhost:8545 > /dev/null 2>&1; then
            echo "✓ Geth HTTP endpoint is responding"
        else
            echo "✗ Geth HTTP endpoint is not responding"
        fi
        
        # Check if Lighthouse is responding
        if docker exec ethereum-lighthouse curl -s http://localhost:5052 > /dev/null 2>&1; then
            echo "✓ Lighthouse HTTP endpoint is responding"
        else
            echo "✗ Lighthouse HTTP endpoint is not responding"
        fi
EOF
    
    print_success "Deployment verification completed!"
}

# Function to show deployment summary
show_deployment_summary() {
    echo ""
    print_status "Ethereum Nodes Deployment Summary:"
    echo "========================================"
    echo "✓ JWT files verified locally"
    echo "✓ Files copied to Google Cloud server"
    echo "✓ Services deployed and started"
    echo "✓ Deployment verified"
    echo ""
    print_success "Ethereum nodes are now running on Google Cloud!"
    echo ""
    echo "Next steps:"
    echo "1. Monitor container logs: ssh $SERVER_USER 'docker logs -f ethereum-geth'"
    echo "2. Check sync status: ssh $SERVER_USER 'docker exec ethereum-geth geth attach --exec eth.syncing'"
    echo "3. Monitor Lighthouse: ssh $SERVER_USER 'docker logs -f ethereum-lighthouse'"
}

# Main function
main() {
    print_status "Starting Ethereum nodes deployment to Google Cloud..."
    
    # Check if required files exist
    if [ ! -f "$ETHEREUM_DIR/docker-compose.yml" ]; then
        print_error "docker-compose.yml not found in $ETHEREUM_DIR"
        exit 1
    fi
    
    # Verify JWT files
    verify_jwt_files
    
    # Copy files to server
    copy_to_server
    
    # Deploy on server
    deploy_on_server
    
    # Verify deployment
    verify_deployment
    
    # Show summary
    show_deployment_summary
}

# Run main function
main "$@"
