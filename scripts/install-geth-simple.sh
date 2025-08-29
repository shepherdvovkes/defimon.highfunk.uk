#!/bin/bash

# Simple Geth Installation Script
# This script installs Geth using a different approach

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Installing Geth..."

# Try different download methods
cd /tmp

# Method 1: Try direct download from a known working URL
print_status "Trying method 1: Direct download..."
wget -O geth.tar.gz "https://github.com/ethereum/go-ethereum/releases/download/v1.13.15/geth-linux-amd64-1.13.15-6c65905a.tar.gz" || {
    print_status "Method 1 failed, trying method 2..."
    
    # Method 2: Try building from source
    print_status "Trying method 2: Building from source..."
    
    # Install Go if not installed
    if ! command -v go >/dev/null 2>&1; then
        print_status "Installing Go..."
        wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
        sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        export PATH=$PATH:/usr/local/go/bin
    fi
    
    # Clone and build Geth
    print_status "Cloning Geth repository..."
    git clone https://github.com/ethereum/go-ethereum.git
    cd go-ethereum
    
    print_status "Building Geth (this may take a while)..."
    make geth
    
    print_status "Installing Geth..."
    sudo cp build/bin/geth /usr/local/bin/
    sudo chmod +x /usr/local/bin/geth
    
    # Cleanup
    cd /tmp
    rm -rf go-ethereum go1.21.5.linux-amd64.tar.gz
}

# If we downloaded the tar.gz, extract it
if [ -f "geth.tar.gz" ]; then
    print_status "Extracting Geth..."
    sudo tar -xzf geth.tar.gz -C /usr/local/bin --strip-components=1 geth-linux-amd64-*/geth
    sudo chmod +x /usr/local/bin/geth
    rm geth.tar.gz
fi

# Verify installation
if command -v geth >/dev/null 2>&1; then
    print_success "Geth installed successfully!"
    geth version
else
    print_error "Geth installation failed"
    exit 1
fi
