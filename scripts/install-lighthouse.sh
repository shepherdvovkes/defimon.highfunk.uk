#!/bin/bash

# Install Lighthouse Consensus Client
# This script installs Lighthouse on the crab server

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

print_status "Installing Lighthouse..."

# Install Rust if not installed
if ! command -v cargo >/dev/null 2>&1; then
    print_status "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Clone Lighthouse repository
cd /tmp
if [ -d "lighthouse" ]; then
    rm -rf lighthouse
fi

print_status "Cloning Lighthouse repository..."
git clone https://github.com/sigp/lighthouse.git
cd lighthouse

# Build Lighthouse
print_status "Building Lighthouse (this may take a while)..."
make

# Install Lighthouse
print_status "Installing Lighthouse..."
sudo cp target/release/lighthouse /usr/local/bin/
sudo chmod +x /usr/local/bin/lighthouse

# Verify installation
if command -v lighthouse >/dev/null 2>&1; then
    print_success "Lighthouse installed successfully!"
    lighthouse --version
else
    print_error "Lighthouse installation failed"
    exit 1
fi

# Cleanup
cd /tmp
rm -rf lighthouse

print_success "Lighthouse installation completed!"
