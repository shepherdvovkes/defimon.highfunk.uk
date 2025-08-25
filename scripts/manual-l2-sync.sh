#!/bin/bash

# Manual L2 Networks Sync Script for Vovkes Server
# This script provides manual control over L2 networks synchronization

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
TOOL_DIR="/opt/tools/l2-networks-sync"
SERVICE_NAME="l2-networks-sync"
LOG_DIR="/var/log/l2-sync"
DOCKER_COMPOSE_FILE="$TOOL_DIR/docker-compose.yml"
BACKUP_DIR="/opt/backups/l2-sync"
MAX_BACKUP_AGE_DAYS=7

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
    echo -e "${PURPLE}  L2 Networks Manual Sync Tool${NC}"
    echo -e "${PURPLE}================================${NC}"
    echo ""
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Function to check if tool is installed
check_tool_installed() {
    if [[ ! -d "$TOOL_DIR" ]]; then
        print_error "L2 networks sync tool is not installed"
        print_status "Please run: ./start-l2-sync.sh install"
        exit 1
    fi
    
    if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
        print_error "Docker compose file not found at $DOCKER_COMPOSE_FILE"
        exit 1
    fi
    
    print_success "L2 networks sync tool is installed"
}

# Function to check Docker status
check_docker_status() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running"
        print_status "Starting Docker service..."
        systemctl start docker
        sleep 3
        
        if ! docker info >/dev/null 2>&1; then
            print_error "Failed to start Docker"
            exit 1
        fi
    fi
    print_success "Docker is running"
}

# Function to check service status
check_service_status() {
    if systemctl is-active --quiet $SERVICE_NAME; then
        print_success "Service $SERVICE_NAME is running"
        return 0
    else
        print_warning "Service $SERVICE_NAME is not running"
        return 1
    fi
}

# Function to start service if needed
ensure_service_running() {
    if ! check_service_status; then
        print_status "Starting service $SERVICE_NAME..."
        systemctl start $SERVICE_NAME
        sleep 5
        
        if check_service_status; then
            print_success "Service started successfully"
        else
            print_error "Failed to start service"
            exit 1
        fi
    fi
}

# Function to perform manual sync
perform_manual_sync() {
    print_status "Performing manual L2 networks sync..."
    
    cd "$TOOL_DIR"
    
    # Check if container is running
    if ! docker-compose ps | grep -q "l2-networks-sync.*Up"; then
        print_warning "L2 sync container is not running, starting it..."
        docker-compose up -d l2-networks-sync
        sleep 10
    fi
    
    # Execute sync command
    print_status "Executing sync command..."
    docker-compose exec -T l2-networks-sync node index.js sync --verbose
    
    if [ $? -eq 0 ]; then
        print_success "Manual sync completed successfully"
    else
        print_error "Manual sync failed"
        return 1
    fi
}

# Function to show sync status
show_sync_status() {
    print_status "Checking L2 networks sync status..."
    
    cd "$TOOL_DIR"
    
    # Check container status
    print_status "Container status:"
    docker-compose ps l2-networks-sync
    
    # Check service status
    print_status "Service status:"
    systemctl status $SERVICE_NAME --no-pager -l
    
    # Show recent logs
    print_status "Recent sync logs:"
    docker-compose logs --tail=20 l2-networks-sync
    
    # Show database status
    print_status "Database status:"
    docker-compose exec -T l2-networks-sync node index.js status
}

# Function to list networks
list_networks() {
    local page=${1:-1}
    local limit=${2:-20}
    
    print_status "Listing L2 networks (page $page, limit $limit)..."
    
    cd "$TOOL_DIR"
    docker-compose exec -T l2-networks-sync node index.js list --page "$page" --limit "$limit"
}

# Function to search networks
search_networks() {
    local search_term="$1"
    local page=${2:-1}
    local limit=${3:-20}
    
    if [[ -z "$search_term" ]]; then
        print_error "Search term is required"
        return 1
    fi
    
    if [[ ${#search_term} -lt 2 ]]; then
        print_error "Search term must be at least 2 characters"
        return 1
    fi
    
    print_status "Searching for networks matching '$search_term' (page $page, limit $limit)..."
    
    cd "$TOOL_DIR"
    docker-compose exec -T l2-networks-sync node index.js search "$search_term" --page "$page" --limit "$limit"
}

# Function to initialize database
initialize_database() {
    print_status "Initializing L2 networks database..."
    
    cd "$TOOL_DIR"
    docker-compose exec -T l2-networks-sync node index.js init
    
    if [ $? -eq 0 ]; then
        print_success "Database initialized successfully"
    else
        print_error "Database initialization failed"
        return 1
    fi
}

# Function to create backup
create_backup() {
    print_status "Creating L2 sync backup..."
    
    mkdir -p "$BACKUP_DIR"
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/l2-sync-backup-$timestamp.tar.gz"
    
    cd "$TOOL_DIR"
    
    # Create backup of configuration and data
    tar -czf "$backup_file" \
        --exclude="node_modules" \
        --exclude="logs" \
        --exclude=".git" \
        .
    
    if [ $? -eq 0 ]; then
        print_success "Backup created: $backup_file"
        
        # Clean old backups
        find "$BACKUP_DIR" -name "l2-sync-backup-*.tar.gz" -mtime +$MAX_BACKUP_AGE_DAYS -delete
        print_status "Old backups cleaned up"
    else
        print_error "Backup creation failed"
        return 1
    fi
}

# Function to restore backup
restore_backup() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        print_error "Backup file path is required"
        return 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        print_error "Backup file not found: $backup_file"
        return 1
    fi
    
    print_warning "This will overwrite current L2 sync configuration!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Restore cancelled"
        return 0
    fi
    
    print_status "Restoring from backup: $backup_file"
    
    # Stop service
    systemctl stop $SERVICE_NAME
    
    # Restore backup
    cd "$TOOL_DIR"
    tar -xzf "$backup_file" --strip-components=0
    
    # Restart service
    systemctl start $SERVICE_NAME
    
    print_success "Backup restored successfully"
}

# Function to show logs
show_logs() {
    local lines=${1:-50}
    local follow=${2:-false}
    
    print_status "Showing L2 sync logs (last $lines lines)..."
    
    cd "$TOOL_DIR"
    
    if [[ "$follow" == "true" ]]; then
        docker-compose logs -f --tail="$lines" l2-networks-sync
    else
        docker-compose logs --tail="$lines" l2-networks-sync
    fi
}

# Function to restart service
restart_service() {
    print_status "Restarting L2 networks sync service..."
    
    systemctl restart $SERVICE_NAME
    sleep 5
    
    if check_service_status; then
        print_success "Service restarted successfully"
    else
        print_error "Service restart failed"
        return 1
    fi
}

# Function to show help
show_help() {
    print_header
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  sync [--force]           - Perform manual sync of L2 networks"
    echo "  status                   - Show sync status and service information"
    echo "  list [page] [limit]      - List L2 networks (default: page 1, limit 20)"
    echo "  search <term> [page] [limit] - Search networks by name"
    echo "  init                     - Initialize database and create tables"
    echo "  backup                   - Create backup of configuration and data"
    echo "  restore <backup_file>    - Restore from backup file"
    echo "  logs [lines] [--follow]  - Show logs (default: 50 lines)"
    echo "  restart                  - Restart the sync service"
    echo "  help                     - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 sync                  # Perform manual sync"
    echo "  $0 sync --force          # Force sync even if recent sync exists"
    echo "  $0 list 2 10            # List networks page 2, 10 per page"
    echo "  $0 search polygon       # Search for networks containing 'polygon'"
    echo "  $0 logs 100 --follow    # Show last 100 lines and follow"
    echo "  $0 backup               # Create backup"
    echo ""
    echo "Environment:"
    echo "  TOOL_DIR: $TOOL_DIR"
    echo "  SERVICE_NAME: $SERVICE_NAME"
    echo "  LOG_DIR: $LOG_DIR"
}

# Function to parse command line arguments
parse_arguments() {
    case "${1:-}" in
        sync)
            local force=""
            if [[ "$2" == "--force" ]]; then
                force="--force"
            fi
            check_root
            check_tool_installed
            check_docker_status
            ensure_service_running
            perform_manual_sync
            ;;
        status)
            check_tool_installed
            check_docker_status
            show_sync_status
            ;;
        list)
            local page=${2:-1}
            local limit=${3:-20}
            check_tool_installed
            check_docker_status
            ensure_service_running
            list_networks "$page" "$limit"
            ;;
        search)
            local term="$2"
            local page=${3:-1}
            local limit=${4:-20}
            check_tool_installed
            check_docker_status
            ensure_service_running
            search_networks "$term" "$page" "$limit"
            ;;
        init)
            check_root
            check_tool_installed
            check_docker_status
            ensure_service_running
            initialize_database
            ;;
        backup)
            check_root
            check_tool_installed
            create_backup
            ;;
        restore)
            local backup_file="$2"
            check_root
            check_tool_installed
            restore_backup "$backup_file"
            ;;
        logs)
            local lines=${2:-50}
            local follow="false"
            if [[ "$3" == "--follow" ]]; then
                follow="true"
            fi
            check_tool_installed
            check_docker_status
            show_logs "$lines" "$follow"
            ;;
        restart)
            check_root
            check_tool_installed
            restart_service
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
}

# Main script execution
main() {
    print_header
    
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    parse_arguments "$@"
}

# Execute main function with all arguments
main "$@"
