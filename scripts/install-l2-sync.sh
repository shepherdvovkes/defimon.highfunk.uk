#!/bin/bash

# L2 Networks Sync Tool Installation Script for Vovkes Server
# This script installs the L2 networks sync tool

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Configuration
TOOL_DIR="/opt/tools/l2-networks-sync"
SERVICE_NAME="l2-networks-sync"
LOG_DIR="/var/log/l2-sync"
BACKUP_DIR="/opt/backups/l2-sync"

print_status "Installing L2 Networks Sync Tool..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p "$TOOL_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p /etc/systemd/system

# Copy tool files from temporary location
print_status "Copying tool files..."
if [[ -d "/tmp/l2-networks-sync" ]]; then
    cp -r /tmp/l2-networks-sync/* "$TOOL_DIR/"
    chmod +x "$TOOL_DIR/setup.sh"
    print_success "Tool files copied successfully"
else
    print_error "L2 networks sync tool directory not found in /tmp/"
    exit 1
fi

# Copy manual sync script
if [[ -f "/tmp/manual-l2-sync.sh" ]]; then
    cp /tmp/manual-l2-sync.sh /usr/local/bin/manual-l2-sync
    chmod +x /usr/local/bin/manual-l2-sync
    print_success "Manual sync script installed to /usr/local/bin/manual-l2-sync"
fi

# Setup environment
print_status "Setting up environment..."
cd "$TOOL_DIR"

# Copy environment file if it doesn't exist
if [[ ! -f ".env" ]]; then
    if [[ -f "env.example" ]]; then
        cp env.example .env
        print_warning "Please configure .env file with your database credentials"
        print_status "Edit file: nano $TOOL_DIR/.env"
    else
        print_error "Environment example file not found"
        exit 1
    fi
fi

# Run setup script
if [[ -f "setup.sh" ]]; then
    chmod +x setup.sh
    ./setup.sh
    print_success "Environment setup completed"
else
    print_error "Setup script not found"
    exit 1
fi

# Create systemd service
print_status "Creating systemd service..."
cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=L2 Networks Sync Tool
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$TOOL_DIR
ExecStart=/usr/bin/docker-compose -f docker-compose.yml up -d
ExecStop=/usr/bin/docker-compose -f docker-compose.yml down
ExecReload=/usr/bin/docker-compose -f docker-compose.yml restart
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
print_success "Systemd service created successfully"

# Create cron job for scheduled sync (optional)
print_status "Creating cron job for scheduled sync..."
cat > /etc/cron.d/l2-sync << EOF
# L2 Networks Sync - Run every 6 hours
0 */6 * * * root cd $TOOL_DIR && docker-compose exec -T l2-networks-sync node index.js sync >> $LOG_DIR/cron.log 2>&1
EOF

print_success "Cron job created for scheduled sync every 6 hours"

# Set permissions
chown -R root:root "$TOOL_DIR"
chmod -R 755 "$TOOL_DIR"
chown -R root:root "$LOG_DIR"
chmod -R 755 "$LOG_DIR"

print_success "L2 Networks Sync Tool installation completed!"
echo ""
print_status "Next steps:"
echo "1. Configure database connection in: $TOOL_DIR/.env"
echo "2. Start the service: systemctl start $SERVICE_NAME"
echo "3. Enable auto-start: systemctl enable $SERVICE_NAME"
echo "4. Use manual sync: manual-l2-sync help"
echo ""
print_status "Configuration file location: $TOOL_DIR/.env"
print_status "Log directory: $LOG_DIR"
print_status "Service name: $SERVICE_NAME"
