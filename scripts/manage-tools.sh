#!/bin/bash

# Tools Management Script
# This script provides centralized management for all tools on the Vovkes server

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
TOOLS_BASE_DIR="/opt/tools"
LOG_DIR="/var/log/tools"
CONFIG_DIR="/etc/tools"

# Available tools
declare -A TOOLS=(
    ["l2-networks-sync"]="L2 Networks Synchronization Tool"
    ["admin-dashboard"]="Admin Dashboard Service"
    ["ai-ml-service"]="AI/ML Service"
    ["analytics-api"]="Analytics API Service"
    ["blockchain-node"]="Blockchain Node Service"
    ["data-ingestion"]="Data Ingestion Service"
    ["stream-processing"]="Stream Processing Service"
)

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

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE} $1${NC}"
    echo -e "${PURPLE}================================${NC}"
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
    
    mkdir -p "$TOOLS_BASE_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$CONFIG_DIR"
    
    print_success "Directories created successfully"
}

# Function to list all tools
list_tools() {
    print_header "Available Tools"
    
    for tool in "${!TOOLS[@]}"; do
        local status=""
        local service_name="${tool//-/_}"
        
        if systemctl is-active --quiet "$service_name" 2>/dev/null; then
            status="${GREEN}● RUNNING${NC}"
        elif systemctl is-enabled --quiet "$service_name" 2>/dev/null; then
            status="${YELLOW}● STOPPED${NC}"
        else
            status="${RED}● NOT INSTALLED${NC}"
        fi
        
        printf "%-20s %-35s %s\n" "$tool" "${TOOLS[$tool]}" "$status"
    done
    
    echo ""
}

# Function to check tool status
check_tool_status() {
    local tool_name="$1"
    local service_name="${tool_name//-/_}"
    
    print_header "Status for $tool_name"
    
    # Check systemd service
    if systemctl list-unit-files | grep -q "$service_name"; then
        print_status "Systemd service: $service_name"
        systemctl status "$service_name" --no-pager -l
        
        echo ""
        print_status "Recent logs:"
        journalctl -u "$service_name" --no-pager -l -n 20
    else
        print_warning "Systemd service not found: $service_name"
    fi
    
    # Check if tool directory exists
    if [[ -d "$TOOLS_BASE_DIR/$tool_name" ]]; then
        print_status "Tool directory: $TOOLS_BASE_DIR/$tool_name"
        ls -la "$TOOLS_BASE_DIR/$tool_name"
    else
        print_warning "Tool directory not found: $TOOLS_BASE_DIR/$tool_name"
    fi
    
    # Check if docker-compose exists and show container status
    if [[ -f "$TOOLS_BASE_DIR/$tool_name/docker-compose.yml" ]]; then
        print_status "Docker containers:"
        cd "$TOOLS_BASE_DIR/$tool_name"
        docker-compose ps
    fi
}

# Function to install a specific tool
install_tool() {
    local tool_name="$1"
    
    if [[ ! -v TOOLS[$tool_name] ]]; then
        print_error "Unknown tool: $tool_name"
        return 1
    fi
    
    print_header "Installing $tool_name"
    
    # Check if tool directory exists in current location
    if [[ ! -d "tools/$tool_name" ]]; then
        print_error "Tool directory not found: tools/$tool_name"
        print_error "Please ensure you're running this script from the project root"
        return 1
    fi
    
    # Create tool directory
    mkdir -p "$TOOLS_BASE_DIR/$tool_name"
    
    # Copy tool files
    print_status "Copying tool files..."
    cp -r "tools/$tool_name"/* "$TOOLS_BASE_DIR/$tool_name/"
    
    # Make setup script executable if it exists
    if [[ -f "$TOOLS_BASE_DIR/$tool_name/setup.sh" ]]; then
        chmod +x "$TOOLS_BASE_DIR/$tool_name/setup.sh"
    fi
    
    # Run tool-specific installation if available
    if [[ -f "$TOOLS_BASE_DIR/$tool_name/install.sh" ]]; then
        print_status "Running tool-specific installation..."
        chmod +x "$TOOLS_BASE_DIR/$tool_name/install.sh"
        cd "$TOOLS_BASE_DIR/$tool_name"
        ./install.sh
    fi
    
    print_success "Tool $tool_name installed successfully"
}

# Function to start a tool
start_tool() {
    local tool_name="$1"
    local service_name="${tool_name//-/_}"
    
    print_header "Starting $tool_name"
    
    if systemctl list-unit-files | grep -q "$service_name"; then
        systemctl start "$service_name"
        print_success "Tool $tool_name started successfully"
    else
        print_warning "Systemd service not found, trying direct docker-compose..."
        
        if [[ -f "$TOOLS_BASE_DIR/$tool_name/docker-compose.yml" ]]; then
            cd "$TOOLS_BASE_DIR/$tool_name"
            docker-compose up -d
            print_success "Tool $tool_name started via docker-compose"
        else
            print_error "No systemd service or docker-compose found for $tool_name"
        fi
    fi
}

# Function to stop a tool
stop_tool() {
    local tool_name="$1"
    local service_name="${tool_name//-/_}"
    
    print_header "Stopping $tool_name"
    
    if systemctl list-unit-files | grep -q "$service_name"; then
        systemctl stop "$service_name"
        print_success "Tool $tool_name stopped successfully"
    else
        print_warning "Systemd service not found, trying direct docker-compose..."
        
        if [[ -f "$TOOLS_BASE_DIR/$tool_name/docker-compose.yml" ]]; then
            cd "$TOOLS_BASE_DIR/$tool_name"
            docker-compose down
            print_success "Tool $tool_name stopped via docker-compose"
        else
            print_error "No systemd service or docker-compose found for $tool_name"
        fi
    fi
}

# Function to restart a tool
restart_tool() {
    local tool_name="$1"
    local service_name="${tool_name//-/_}"
    
    print_header "Restarting $tool_name"
    
    if systemctl list-unit-files | grep -q "$service_name"; then
        systemctl restart "$service_name"
        print_success "Tool $tool_name restarted successfully"
    else
        print_warning "Systemd service not found, trying direct docker-compose..."
        
        if [[ -f "$TOOLS_BASE_DIR/$tool_name/docker-compose.yml" ]]; then
            cd "$TOOLS_BASE_DIR/$tool_name"
            docker-compose restart
            print_success "Tool $tool_name restarted via docker-compose"
        else
            print_error "No systemd service or docker-compose found for $tool_name"
        fi
    fi
}

# Function to show tool logs
show_tool_logs() {
    local tool_name="$1"
    local service_name="${tool_name//-/_}"
    
    print_header "Logs for $tool_name"
    
    if systemctl list-unit-files | grep -q "$service_name"; then
        print_status "Systemd service logs:"
        journalctl -u "$service_name" -f --no-pager
    else
        print_warning "Systemd service not found, showing docker logs..."
        
        if [[ -f "$TOOLS_BASE_DIR/$tool_name/docker-compose.yml" ]]; then
            cd "$TOOLS_BASE_DIR/$tool_name"
            docker-compose logs -f
        else
            print_error "No logs available for $tool_name"
        fi
    fi
}

# Function to update all tools from git
update_tools() {
    print_header "Updating all tools from git repository"
    
    # Check if we're in the project root
    if [[ ! -d "tools" ]]; then
        print_error "Tools directory not found. Please run this script from the project root."
        return 1
    fi
    
    # Pull latest changes
    print_status "Pulling latest changes from git..."
    git pull origin main
    
    # Update each tool
    for tool in "${!TOOLS[@]}"; do
        if [[ -d "tools/$tool" ]]; then
            print_status "Updating $tool..."
            if [[ -d "$TOOLS_BASE_DIR/$tool" ]]; then
                cp -r "tools/$tool"/* "$TOOLS_BASE_DIR/$tool/"
                print_success "Tool $tool updated"
            else
                print_warning "Tool $tool not installed, skipping update"
            fi
        fi
    done
    
    print_success "All tools updated successfully"
}

# Function to show system resources
show_system_resources() {
    print_header "System Resources"
    
    print_status "CPU Usage:"
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
    
    print_status "Memory Usage:"
    free -h
    
    print_status "Disk Usage:"
    df -h
    
    print_status "Docker Status:"
    docker system df
    
    print_status "Running Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND] [TOOL_NAME]"
    echo ""
    echo "Commands:"
    echo "  list                    - List all available tools and their status"
    echo "  status [TOOL_NAME]      - Show status of a specific tool"
    echo "  install [TOOL_NAME]     - Install a specific tool"
    echo "  start [TOOL_NAME]       - Start a specific tool"
    echo "  stop [TOOL_NAME]        - Stop a specific tool"
    echo "  restart [TOOL_NAME]     - Restart a specific tool"
    echo "  logs [TOOL_NAME]        - Show logs of a specific tool"
    echo "  update                  - Update all tools from git repository"
    echo "  resources               - Show system resources"
    echo "  help                    - Show this help message"
    echo ""
    echo "Available Tools:"
    for tool in "${!TOOLS[@]}"; do
        printf "  %-20s - %s\n" "$tool" "${TOOLS[$tool]}"
    done
    echo ""
    echo "Examples:"
    echo "  $0 list                           # List all tools"
    echo "  $0 status l2-networks-sync        # Check status of L2 sync tool"
    echo "  $0 install l2-networks-sync       # Install L2 sync tool"
    echo "  $0 start l2-networks-sync         # Start L2 sync tool"
    echo "  $0 update                         # Update all tools from git"
}

# Main script logic
case "${1:-}" in
    list)
        list_tools
        ;;
    status)
        if [[ -z "$2" ]]; then
            print_error "Please specify a tool name"
            show_help
            exit 1
        fi
        check_tool_status "$2"
        ;;
    install)
        check_root
        if [[ -z "$2" ]]; then
            print_error "Please specify a tool name"
            show_help
            exit 1
        fi
        install_tool "$2"
        ;;
    start)
        if [[ -z "$2" ]]; then
            print_error "Please specify a tool name"
            show_help
            exit 1
        fi
        start_tool "$2"
        ;;
    stop)
        if [[ -z "$2" ]]; then
            print_error "Please specify a tool name"
            show_help
            exit 1
        fi
        stop_tool "$2"
        ;;
    restart)
        if [[ -z "$2" ]]; then
            print_error "Please specify a tool name"
            show_help
            exit 1
        fi
        restart_tool "$2"
        ;;
    logs)
        if [[ -z "$2" ]]; then
            print_error "Please specify a tool name"
            show_help
            exit 1
        fi
        show_tool_logs "$2"
        ;;
    update)
        check_root
        update_tools
        ;;
    resources)
        show_system_resources
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
