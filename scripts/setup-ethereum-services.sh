#!/bin/bash

# Setup Ethereum Systemd Services
# This script creates and starts systemd services for Geth and Lighthouse

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
    echo -e "${PURPLE}  SETTING UP ETHEREUM SERVICES${NC}"
    echo -e "${PURPLE}================================${NC}"
}

setup_geth_service() {
    print_status "Setting up Geth systemd service..."
    
    sudo tee /etc/systemd/system/geth.service > /dev/null <<EOF
[Unit]
Description=Ethereum Geth Execution Client
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
    --metrics.port 6060 \\
    --verbosity 3
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    print_success "Geth service created"
}

setup_lighthouse_service() {
    print_status "Setting up Lighthouse systemd service..."
    
    sudo tee /etc/systemd/system/lighthouse.service > /dev/null <<EOF
[Unit]
Description=Ethereum Lighthouse Consensus Client
After=network.target geth.service
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
    --metrics-port 5054 \\
    --validator-monitor-auto \\
    --suggested-fee-recipient 0x0000000000000000000000000000000000000000
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    print_success "Lighthouse service created"
}

setup_monitoring_service() {
    print_status "Setting up monitoring service..."
    
    sudo tee /etc/systemd/system/ethereum-monitor.service > /dev/null <<EOF
[Unit]
Description=Ethereum Node Monitoring
After=network.target geth.service lighthouse.service
Wants=network.target

[Service]
Type=simple
User=vovkes
Group=vovkes
WorkingDirectory=/home/vovkes/ethereum
ExecStart=/home/vovkes/ethereum/monitor.sh
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    print_success "Monitoring service created"
}

enable_services() {
    print_status "Enabling services..."
    
    sudo systemctl daemon-reload
    
    # Enable services
    sudo systemctl enable geth
    sudo systemctl enable lighthouse
    sudo systemctl enable ethereum-monitor
    
    print_success "Services enabled"
}

start_services() {
    print_status "Starting Ethereum services..."
    
    # Start Geth first
    print_status "Starting Geth..."
    sudo systemctl start geth
    
    # Wait a moment for Geth to start
    sleep 10
    
    # Check Geth status
    if sudo systemctl is-active --quiet geth; then
        print_success "Geth started successfully"
    else
        print_error "Geth failed to start"
        sudo systemctl status geth
        return 1
    fi
    
    # Start Lighthouse
    print_status "Starting Lighthouse..."
    sudo systemctl start lighthouse
    
    # Wait a moment for Lighthouse to start
    sleep 10
    
    # Check Lighthouse status
    if sudo systemctl is-active --quiet lighthouse; then
        print_success "Lighthouse started successfully"
    else
        print_error "Lighthouse failed to start"
        sudo systemctl status lighthouse
        return 1
    fi
    
    # Start monitoring
    print_status "Starting monitoring service..."
    sudo systemctl start ethereum-monitor
    
    print_success "All services started successfully"
}

show_status() {
    print_status "Checking service status..."
    
    echo -e "\n${BLUE}Service Status:${NC}"
    sudo systemctl status geth --no-pager -l
    echo
    sudo systemctl status lighthouse --no-pager -l
    echo
    sudo systemctl status ethereum-monitor --no-pager -l
    
    echo -e "\n${BLUE}Service Logs (last 10 lines):${NC}"
    echo -e "${YELLOW}Geth logs:${NC}"
    sudo journalctl -u geth -n 10 --no-pager
    echo
    echo -e "${YELLOW}Lighthouse logs:${NC}"
    sudo journalctl -u lighthouse -n 10 --no-pager
}

main() {
    print_header
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_error "This script should not be run as root"
        exit 1
    fi
    
    # Setup services
    setup_geth_service
    setup_lighthouse_service
    setup_monitoring_service
    
    # Enable services
    enable_services
    
    # Start services
    if start_services; then
        print_success "Ethereum full node setup completed!"
        print_status "Services are now running and will start automatically on boot"
        
        # Show status
        show_status
        
        print_status "Useful commands:"
        print_status "  sudo systemctl status geth"
        print_status "  sudo systemctl status lighthouse"
        print_status "  sudo journalctl -u geth -f"
        print_status "  sudo journalctl -u lighthouse -f"
        print_status "  curl http://localhost:8545 -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"eth_syncing\",\"params\":[],\"id\":1}'"
    else
        print_error "Failed to start services"
        exit 1
    fi
}

# Run main function
main "$@"

