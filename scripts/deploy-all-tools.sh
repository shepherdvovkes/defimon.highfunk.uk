#!/bin/bash

# Deploy All Tools Script
# This script automatically deploys all tools from the git repository to the Vovkes server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
TOOLS_BASE_DIR="/opt/tools"
LOG_DIR="/var/log/tools"
CONFIG_DIR="/etc/tools"
BACKUP_DIR="/opt/tools/backups"

# Available tools with their dependencies
declare -A TOOLS=(
    ["l2-networks-sync"]="L2 Networks Synchronization Tool"
    ["admin-dashboard"]="Admin Dashboard Service"
    ["ai-ml-service"]="AI/ML Service"
    ["analytics-api"]="Analytics API Service"
    ["blockchain-node"]="Blockchain Node Service"
    ["data-ingestion"]="Data Ingestion Service"
    ["stream-processing"]="Stream Processing Service"
)

# Tool deployment order (dependencies first)
TOOL_ORDER=(
    "l2-networks-sync"
    "admin-dashboard"
    "ai-ml-service"
    "analytics-api"
    "blockchain-node"
    "data-ingestion"
    "stream-processing"
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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if git is available
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Please install git first."
        exit 1
    fi
    
    # Check if docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install docker first."
        exit 1
    fi
    
    # Check if docker-compose is available
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install docker-compose first."
        exit 1
    fi
    
    # Check if we're in a git repository
    if [[ ! -d ".git" ]]; then
        print_error "This script must be run from a git repository root"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    mkdir -p "$TOOLS_BASE_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$BACKUP_DIR"
    
    print_success "Directories created successfully"
}

# Function to backup existing tool
backup_tool() {
    local tool_name="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/${tool_name}_${timestamp}"
    
    if [[ -d "$TOOLS_BASE_DIR/$tool_name" ]]; then
        print_status "Backing up existing $tool_name..."
        cp -r "$TOOLS_BASE_DIR/$tool_name" "$backup_path"
        print_success "Backup created: $backup_path"
    fi
}

# Function to deploy a specific tool
deploy_tool() {
    local tool_name="$1"
    
    print_header "Deploying $tool_name"
    
    # Check if tool directory exists in current location
    if [[ ! -d "tools/$tool_name" ]]; then
        print_warning "Tool directory not found: tools/$tool_name, skipping..."
        return 0
    fi
    
    # Backup existing tool if it exists
    backup_tool "$tool_name"
    
    # Create tool directory
    mkdir -p "$TOOLS_BASE_DIR/$tool_name"
    
    # Copy tool files
    print_status "Copying tool files..."
    cp -r "tools/$tool_name"/* "$TOOLS_BASE_DIR/$tool_name/"
    
    # Make scripts executable
    find "$TOOLS_BASE_DIR/$tool_name" -name "*.sh" -exec chmod +x {} \;
    
    # Run tool-specific setup if available
    if [[ -f "$TOOLS_BASE_DIR/$tool_name/setup.sh" ]]; then
        print_status "Running tool-specific setup..."
        cd "$TOOLS_BASE_DIR/$tool_name"
        ./setup.sh
        cd - > /dev/null
    fi
    
    # Create systemd service if service template exists
    if [[ -f "$TOOLS_BASE_DIR/$tool_name/service.template" ]]; then
        print_status "Creating systemd service..."
        create_systemd_service "$tool_name"
    fi
    
    print_success "Tool $tool_name deployed successfully"
}

# Function to create systemd service from template
create_systemd_service() {
    local tool_name="$1"
    local service_name="${tool_name//-/_}"
    local template_file="$TOOLS_BASE_DIR/$tool_name/service.template"
    local service_file="/etc/systemd/system/$service_name.service"
    
    # Replace placeholders in template
    sed "s|{{TOOL_DIR}}|$TOOLS_BASE_DIR/$tool_name|g" "$template_file" > "$service_file"
    
    # Reload systemd
    systemctl daemon-reload
    
    print_success "Systemd service created: $service_name"
}

# Function to start all tools
start_all_tools() {
    print_header "Starting all tools..."
    
    for tool in "${TOOL_ORDER[@]}"; do
        if [[ -d "$TOOLS_BASE_DIR/$tool" ]]; then
            print_status "Starting $tool..."
            
            # Try to start via systemd first
            local service_name="${tool//-/_}"
            if systemctl list-unit-files | grep -q "$service_name"; then
                systemctl start "$service_name" || print_warning "Failed to start $service_name service"
            fi
            
            # Try docker-compose if available
            if [[ -f "$TOOLS_BASE_DIR/$tool/docker-compose.yml" ]]; then
                cd "$TOOLS_BASE_DIR/$tool"
                docker-compose up -d || print_warning "Failed to start $tool via docker-compose"
                cd - > /dev/null
            fi
        fi
    done
    
    print_success "All tools started"
}

# Function to check deployment status
check_deployment_status() {
    print_header "Deployment Status Check"
    
    local success_count=0
    local total_count=0
    
    for tool in "${TOOL_ORDER[@]}"; do
        total_count=$((total_count + 1))
        
        if [[ -d "$TOOLS_BASE_DIR/$tool" ]]; then
            local service_name="${tool//-/_}"
            local status=""
            
            if systemctl is-active --quiet "$service_name" 2>/dev/null; then
                status="${GREEN}● RUNNING${NC}"
                success_count=$((success_count + 1))
            elif systemctl is-enabled --quiet "$service_name" 2>/dev/null; then
                status="${YELLOW}● STOPPED${NC}"
            else
                status="${RED}● NOT INSTALLED${NC}"
            fi
            
            printf "%-20s %-35s %s\n" "$tool" "${TOOLS[$tool]}" "$status"
        else
            printf "%-20s %-35s %s\n" "$tool" "${TOOLS[$tool]}" "${RED}● NOT DEPLOYED${NC}"
        fi
    done
    
    echo ""
    print_status "Deployment Summary: $success_count/$total_count tools running"
    
    if [[ $success_count -eq $total_count ]]; then
        print_success "All tools deployed and running successfully!"
    else
        print_warning "Some tools may need attention. Check individual tool status."
    fi
}

# Function to show deployment logs
show_deployment_logs() {
    print_header "Recent Deployment Logs"
    
    # Show system logs for tools
    for tool in "${TOOL_ORDER[@]}"; do
        local service_name="${tool//-/_}"
        
        if systemctl list-unit-files | grep -q "$service_name"; then
            print_status "Logs for $tool ($service_name):"
            journalctl -u "$service_name" --no-pager -l -n 10
            echo ""
        fi
    done
    
    # Show docker logs
    print_status "Docker container logs:"
    docker-compose logs --tail=20 2>/dev/null || print_warning "No docker-compose logs available"
}

# Function to rollback deployment
rollback_deployment() {
    local tool_name="$1"
    
    if [[ -z "$tool_name" ]]; then
        print_error "Please specify a tool name to rollback"
        return 1
    fi
    
    print_header "Rolling back $tool_name"
    
    # Find latest backup
    local latest_backup=$(ls -t "$BACKUP_DIR/${tool_name}_"* 2>/dev/null | head -1)
    
    if [[ -z "$latest_backup" ]]; then
        print_error "No backup found for $tool_name"
        return 1
    fi
    
    print_status "Found backup: $latest_backup"
    
    # Stop current tool
    local service_name="${tool_name//-/_}"
    if systemctl list-unit-files | grep -q "$service_name"; then
        systemctl stop "$service_name" || true
    fi
    
    # Remove current deployment
    rm -rf "$TOOLS_BASE_DIR/$tool_name"
    
    # Restore from backup
    cp -r "$latest_backup" "$TOOLS_BASE_DIR/$tool_name"
    
    print_success "Tool $tool_name rolled back successfully"
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  deploy              - Deploy all tools from git repository"
    echo "  start               - Start all deployed tools"
    echo "  status              - Check deployment status of all tools"
    echo "  logs                - Show deployment logs"
    echo "  rollback [TOOL]     - Rollback a specific tool to previous version"
    echo "  backup              - Create backup of all tools"
    echo "  help                - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy                    # Deploy all tools"
    echo "  $0 start                     # Start all tools"
    echo "  $0 status                    # Check status"
    echo "  $0 rollback l2-networks-sync # Rollback specific tool"
    echo ""
    echo "Note: This script must be run as root and from the git repository root"
}

# Function to create backup of all tools
backup_all_tools() {
    print_header "Creating backup of all tools"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/full_backup_${timestamp}"
    
    mkdir -p "$backup_path"
    
    for tool in "${TOOL_ORDER[@]}"; do
        if [[ -d "$TOOLS_BASE_DIR/$tool" ]]; then
            print_status "Backing up $tool..."
            cp -r "$TOOLS_BASE_DIR/$tool" "$backup_path/"
        fi
    done
    
    print_success "Full backup created: $backup_path"
}

# Main script logic
case "${1:-}" in
    deploy)
        check_root
        check_prerequisites
        create_directories
        
        print_header "Starting deployment of all tools"
        
        # Deploy each tool in order
        for tool in "${TOOL_ORDER[@]}"; do
            deploy_tool "$tool"
        done
        
        print_success "All tools deployed successfully!"
        ;;
    start)
        check_root
        start_all_tools
        ;;
    status)
        check_deployment_status
        ;;
    logs)
        show_deployment_logs
        ;;
    rollback)
        check_root
        if [[ -z "$2" ]]; then
            print_error "Please specify a tool name to rollback"
            show_help
            exit 1
        fi
        rollback_deployment "$2"
        ;;
    backup)
        check_root
        backup_all_tools
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
