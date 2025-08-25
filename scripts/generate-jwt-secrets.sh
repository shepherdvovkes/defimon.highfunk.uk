#!/bin/bash

# DEFIMON JWT Secrets Generation Script
# This script generates proper JWT secrets for Ethereum nodes

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

# Function to generate JWT secrets
generate_jwt_secrets() {
    print_status "Generating JWT secrets for Ethereum nodes..."
    
    # Create JWT directory if it doesn't exist
    mkdir -p "$JWT_DIR"
    
    # Generate RAW format for Geth (32 bytes)
    print_status "Generating RAW JWT secret for Geth..."
    openssl rand -out "$JWT_DIR/jwtsecret.raw" 32
    
    # Generate HEX format for Lighthouse (64 characters)
    print_status "Generating HEX JWT secret for Lighthouse..."
    openssl rand -hex 32 > "$JWT_DIR/jwtsecret.hex"
    
    # Set proper permissions
    chmod 600 "$JWT_DIR/jwtsecret.raw"
    chmod 600 "$JWT_DIR/jwtsecret.hex"
    
    print_success "JWT secrets generated successfully!"
}

# Function to verify JWT secrets
verify_jwt_secrets() {
    print_status "Verifying JWT secrets..."
    
    # Check Geth JWT file
    local geth_size=$(wc -c < "$JWT_DIR/jwtsecret.raw")
    if [ "$geth_size" -eq 32 ]; then
        print_success "Geth JWT file size: $geth_size bytes ✓"
    else
        print_error "Geth JWT file size: $geth_size bytes ✗ (expected 32)"
        return 1
    fi
    
    # Check Lighthouse JWT file
    local lighthouse_size=$(wc -c < "$JWT_DIR/jwtsecret.hex")
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

# Function to backup existing JWT files
backup_existing_jwt() {
    if [ -f "$JWT_DIR/jwtsecret" ]; then
        print_warning "Found existing JWT file, creating backup..."
        cp "$JWT_DIR/jwtsecret" "$JWT_DIR/jwtsecret.backup.$(date +%Y%m%d_%H%M%S)"
        print_success "Backup created"
    fi
}

# Function to update docker-compose.yml
update_docker_compose() {
    local compose_file="$JWT_DIR/docker-compose.yml"
    
    if [ -f "$compose_file" ]; then
        print_status "Updating docker-compose.yml with new JWT file paths..."
        
        # Create backup
        cp "$compose_file" "$compose_file.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Update volume mounts
        sed -i.bak 's|./jwtsecret:/root/.ethereum/jwtsecret|./jwtsecret.raw:/root/.ethereum/jwtsecret:ro|g' "$compose_file"
        sed -i.bak 's|./jwtsecret:/root/.lighthouse/jwtsecret|./jwtsecret.hex:/root/.lighthouse/jwtsecret:ro|g' "$compose_file"
        
        # Remove backup files
        rm -f "$compose_file.bak"
        
        print_success "docker-compose.yml updated successfully!"
    else
        print_warning "docker-compose.yml not found, skipping update"
    fi
}

# Function to display next steps
show_next_steps() {
    print_status "Next steps:"
    echo "1. Review the generated JWT files:"
    echo "   - Geth: $JWT_DIR/jwtsecret.raw (32 bytes)"
    echo "   - Lighthouse: $JWT_DIR/jwtsecret.hex (64 characters)"
    echo ""
    echo "2. Update your deployment scripts if needed"
    echo "3. Restart your Ethereum nodes:"
    echo "   cd $JWT_DIR && docker-compose down && docker-compose up -d"
    echo ""
    echo "4. Verify the setup:"
    echo "   docker exec ethereum-geth wc -c /root/.ethereum/jwtsecret"
    echo "   docker exec ethereum-lighthouse wc -c /root/.lighthouse/jwtsecret"
}

# Main function
main() {
    print_status "Starting JWT secrets generation for DEFIMON Ethereum nodes..."
    
    # Check if openssl is available
    if ! command -v openssl &> /dev/null; then
        print_error "openssl is not installed. Please install it first."
        exit 1
    fi
    
    # Backup existing files
    backup_existing_jwt
    
    # Generate new secrets
    generate_jwt_secrets
    
    # Verify secrets
    verify_jwt_secrets
    
    # Update docker-compose if needed
    update_docker_compose
    
    # Show next steps
    show_next_steps
    
    print_success "JWT secrets generation completed successfully!"
}

# Run main function
main "$@"
