#!/bin/bash

# Install Ethereum Clients (Geth and Lighthouse) on Crab Server
# This script installs the latest stable versions of Geth and Lighthouse

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

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
    echo -e "${PURPLE}  INSTALLING ETHEREUM CLIENTS${NC}"
    echo -e "${PURPLE}================================${NC}"
}

install_geth() {
    print_status "Installing Geth (Ethereum execution client)..."
    
    # Create temporary directory
    cd /tmp
    
    # Download Geth v1.13.11 (stable version)
    print_status "Downloading Geth v1.13.11..."
    wget -O geth.tar.gz "https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.13.11-6c65905a.tar.gz"
    
    if [ $? -ne 0 ]; then
        print_warning "Failed to download from Azure blob, trying alternative source..."
        wget -O geth.tar.gz "https://github.com/ethereum/go-ethereum/releases/download/v1.13.11/geth-linux-amd64-1.13.11-6c65905a.tar.gz"
    fi
    
    if [ $? -ne 0 ]; then
        print_error "Failed to download Geth"
        return 1
    fi
    
    # Extract and install
    print_status "Extracting Geth..."
    sudo tar -xzf geth.tar.gz -C /usr/local/bin --strip-components=1 geth-linux-amd64-1.13.11-6c65905a/geth
    
    # Make executable
    sudo chmod +x /usr/local/bin/geth
    
    # Verify installation
    if command -v geth >/dev/null 2>&1; then
        print_success "Geth installed successfully"
        geth version
    else
        print_error "Geth installation failed"
        return 1
    fi
    
    # Cleanup
    rm -f geth.tar.gz
}

install_lighthouse() {
    print_status "Installing Lighthouse (Ethereum consensus client)..."
    
    # Install Rust if not installed
    if ! command -v cargo >/dev/null 2>&1; then
        print_status "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source ~/.cargo/env
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
        print_success "Lighthouse installed successfully"
        lighthouse --version
    else
        print_error "Lighthouse installation failed"
        return 1
    fi
    
    # Cleanup
    cd /tmp
    rm -rf lighthouse
}

setup_systemd_services() {
    print_status "Setting up systemd services..."
    
    # Create systemd service files
    sudo tee /etc/systemd/system/geth.service > /dev/null <<EOF
[Unit]
Description=Ethereum Geth Client
After=network.target
Wants=network.target

[Service]
Type=simple
User=vovkes
Group=vovkes
WorkingDirectory=/home/vovkes/ethereum
ExecStart=/usr/local/bin/geth \\
    --datadir /mnt/sda1/geth \\
    --http \\
    --http.addr 0.0.0.0 \\
    --http.port 8545 \\
    --http.corsdomain "*" \\
    --http.vhosts "*" \\
    --ws \\
    --ws.addr 0.0.0.0 \\
    --ws.port 8546 \\
    --ws.origins "*" \\
    --authrpc.addr 0.0.0.0 \\
    --authrpc.port 8551 \\
    --authrpc.vhosts "*" \\
    --authrpc.jwtsecret /home/vovkes/ethereum/jwtsecret \\
    --syncmode snap \\
    --cache 8192 \\
    --maxpeers 50 \\
    --metrics \\
    --metrics.addr 0.0.0.0 \\
    --metrics.port 6060
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo tee /etc/systemd/system/lighthouse.service > /dev/null <<EOF
[Unit]
Description=Ethereum Lighthouse Consensus Client
After=network.target
Wants=network.target

[Service]
Type=simple
User=vovkes
Group=vovkes
WorkingDirectory=/home/vovkes/ethereum
ExecStart=/usr/local/bin/lighthouse bn \\
    --datadir /mnt/sdb1/lighthouse \\
    --network mainnet \\
    --http \\
    --http-address 0.0.0.0 \\
    --http-port 5052 \\
    --execution-endpoint http://localhost:8551 \\
    --execution-jwt /home/vovkes/ethereum/jwtsecret \\
    --checkpoint-sync-url https://sync-mainnet.beaconcha.in \\
    --metrics \\
    --metrics-address 0.0.0.0 \\
    --metrics-port 5054
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd
    sudo systemctl daemon-reload
    
    print_success "Systemd services created"
}

main() {
    print_header
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_error "This script should not be run as root"
        exit 1
    fi
    
    # Install Geth
    if ! install_geth; then
        print_error "Failed to install Geth"
        exit 1
    fi
    
    # Install Lighthouse
    if ! install_lighthouse; then
        print_error "Failed to install Lighthouse"
        exit 1
    fi
    
    # Setup systemd services
    setup_systemd_services
    
    print_success "Ethereum clients installation completed!"
    print_status "Geth and Lighthouse are now installed and ready to use"
    print_status "You can start the services with:"
    print_status "  sudo systemctl start geth"
    print_status "  sudo systemctl start lighthouse"
    print_status "  sudo systemctl enable geth lighthouse"
}

# Run main function
main "$@"
