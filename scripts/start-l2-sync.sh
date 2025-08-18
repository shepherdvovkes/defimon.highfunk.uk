#!/bin/bash

# L2 Networks Sync Tool Startup Script
# This script manages the L2 networks synchronization tool on the Vovkes server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TOOL_DIR="/opt/tools/l2-networks-sync"
SERVICE_NAME="l2-networks-sync"
LOG_DIR="/var/log/l2-sync"
DOCKER_COMPOSE_FILE="$TOOL_DIR/docker-compose.yml"

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

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Function to create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    mkdir -p "$TOOL_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p /etc/systemd/system
    
    print_success "Directories created successfully"
}

# Function to copy tool files from git repository
copy_tool_files() {
    print_status "Copying tool files from git repository..."
    
    # Assuming we're in the project root directory
    if [[ -d "tools/l2-networks-sync" ]]; then
        cp -r tools/l2-networks-sync/* "$TOOL_DIR/"
        chmod +x "$TOOL_DIR/setup.sh"
        print_success "Tool files copied successfully"
    else
        print_error "L2 networks sync tool directory not found in current location"
        exit 1
    fi
}

# Function to setup environment
setup_environment() {
    print_status "Setting up environment..."
    
    cd "$TOOL_DIR"
    
    # Copy environment file if it doesn't exist
    if [[ ! -f ".env" ]]; then
        if [[ -f "env.example" ]]; then
            cp env.example .env
            print_warning "Please configure .env file with your database credentials"
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
}

# Function to create systemd service
create_systemd_service() {
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
ExecStart=/usr/bin/docker-compose -f $DOCKER_COMPOSE_FILE up -d
ExecStop=/usr/bin/docker-compose -f $DOCKER_COMPOSE_FILE down
ExecReload=/usr/bin/docker-compose -f $DOCKER_COMPOSE_FILE restart
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    print_success "Systemd service created successfully"
}

# Function to start the service
start_service() {
    print_status "Starting L2 networks sync service..."
    
    systemctl enable $SERVICE_NAME
    systemctl start $SERVICE_NAME
    
    # Wait for service to start
    sleep 5
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        print_success "Service started successfully"
    else
        print_error "Failed to start service"
        systemctl status $SERVICE_NAME
        exit 1
    fi
}

# Function to show service status
show_status() {
    print_status "Service status:"
    systemctl status $SERVICE_NAME --no-pager -l
    
    print_status "Container status:"
    cd "$TOOL_DIR"
    docker-compose ps
}

# Function to show logs
show_logs() {
    print_status "Showing service logs:"
    journalctl -u $SERVICE_NAME -f --no-pager
}

# Function to stop service
stop_service() {
    print_status "Stopping L2 networks sync service..."
    systemctl stop $SERVICE_NAME
    print_success "Service stopped"
}

# Function to restart service
restart_service() {
    print_status "Restarting L2 networks sync service..."
    systemctl restart $SERVICE_NAME
    print_success "Service restarted"
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install    - Install and setup the L2 networks sync tool"
    echo "  start      - Start the service"
    echo "  stop       - Stop the service"
    echo "  restart    - Restart the service"
    echo "  status     - Show service status"
    echo "  logs       - Show service logs"
    echo "  help       - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 install    # First time setup"
    echo "  $0 start      # Start the service"
    echo "  $0 status     # Check status"
}

# Main script logic
case "${1:-}" in
    install)
        check_root
        create_directories
        copy_tool_files
        setup_environment
        create_systemd_service
        start_service
        print_success "L2 networks sync tool installation completed!"
        ;;
    start)
        check_root
        start_service
        ;;
    stop)
        check_root
        stop_service
        ;;
    restart)
        check_root
        restart_service
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
