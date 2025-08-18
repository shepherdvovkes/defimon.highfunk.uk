#!/bin/bash

# Health Check Script for L2 Networks Sync Tool
# This script checks the health and status of the L2 networks synchronization tool

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/l2-sync/health-check.log"
HEALTH_ENDPOINT="http://localhost:3000/health"
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

# Function to log health check results
log_health_check() {
    local message="$1"
    local timestamp=$(date +%Y-%m-%d\ %H:%M:%S)
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# Function to check if docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running"
        log_health_check "ERROR: Docker is not running"
        return 1
    fi
    print_success "Docker is running"
    log_health_check "INFO: Docker is running"
    return 0
}

# Function to check docker-compose file
check_docker_compose() {
    if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
        print_error "Docker Compose file not found: $DOCKER_COMPOSE_FILE"
        log_health_check "ERROR: Docker Compose file not found"
        return 1
    fi
    
    # Validate docker-compose file
    if ! docker-compose -f "$DOCKER_COMPOSE_FILE" config > /dev/null 2>&1; then
        print_error "Invalid Docker Compose configuration"
        log_health_check "ERROR: Invalid Docker Compose configuration"
        return 1
    fi
    
    print_success "Docker Compose configuration is valid"
    log_health_check "INFO: Docker Compose configuration is valid"
    return 0
}

# Function to check container status
check_containers() {
    if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
        return 1
    fi
    
    cd "$TOOL_DIR"
    
    # Get container status
    local container_status=$(docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null)
    
    if [[ -z "$container_status" ]]; then
        print_error "No containers found or docker-compose failed"
        log_health_check "ERROR: No containers found"
        return 1
    fi
    
    # Check if all containers are running
    local running_containers=$(echo "$container_status" | grep -c "Up" || echo "0")
    local total_containers=$(echo "$container_status" | grep -v "Name" | wc -l)
    
    if [[ "$running_containers" -eq "$total_containers" ]]; then
        print_success "All containers are running ($running_containers/$total_containers)"
        log_health_check "INFO: All containers running ($running_containers/$total_containers)"
        
        # Show container details
        echo "$container_status"
        return 0
    else
        print_warning "Some containers are not running ($running_containers/$total_containers)"
        log_health_check "WARNING: Some containers not running ($running_containers/$total_containers)"
        
        # Show container details
        echo "$container_status"
        return 1
    fi
}

# Function to check container health
check_container_health() {
    if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
        return 1
    fi
    
    cd "$TOOL_DIR"
    
    # Get container names
    local containers=$(docker-compose ps -q 2>/dev/null)
    
    if [[ -z "$containers" ]]; then
        print_error "No containers found"
        return 1
    fi
    
    local healthy_count=0
    local total_count=0
    
    for container in $containers; do
        total_count=$((total_count + 1))
        
        # Check container health status
        local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "none")
        
        if [[ "$health_status" == "healthy" ]]; then
            healthy_count=$((healthy_count + 1))
            print_success "Container $container: HEALTHY"
            log_health_check "INFO: Container $container is healthy"
        elif [[ "$health_status" == "unhealthy" ]]; then
            print_error "Container $container: UNHEALTHY"
            log_health_check "ERROR: Container $container is unhealthy"
        elif [[ "$health_status" == "starting" ]]; then
            print_warning "Container $container: STARTING"
            log_health_check "WARNING: Container $container is starting"
        else
            print_status "Container $container: $health_status"
            log_health_check "INFO: Container $container status: $health_status"
        fi
    done
    
    if [[ "$healthy_count" -eq "$total_count" ]]; then
        print_success "All containers are healthy ($healthy_count/$total_count)"
        log_health_check "INFO: All containers healthy ($healthy_count/$total_count)"
        return 0
    else
        print_warning "Some containers are not healthy ($healthy_count/$total_count)"
        log_health_check "WARNING: Some containers not healthy ($healthy_count/$total_count)"
        return 1
    fi
}

# Function to check application health endpoint
check_health_endpoint() {
    if [[ -z "$HEALTH_ENDPOINT" ]]; then
        print_warning "Health endpoint not configured, skipping endpoint check"
        log_health_check "WARNING: Health endpoint not configured"
        return 0
    fi
    
    # Check if health endpoint is accessible
    if command -v curl > /dev/null 2>&1; then
        local response=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_ENDPOINT" --connect-timeout 5 --max-time 10 2>/dev/null || echo "000")
        
        if [[ "$response" == "200" ]]; then
            print_success "Health endpoint is accessible (HTTP $response)"
            log_health_check "INFO: Health endpoint accessible (HTTP $response)"
            return 0
        else
            print_error "Health endpoint returned HTTP $response"
            log_health_check "ERROR: Health endpoint returned HTTP $response"
            return 1
        fi
    else
        print_warning "curl not available, skipping endpoint check"
        log_health_check "WARNING: curl not available for endpoint check"
        return 0
    fi
}

# Function to check resource usage
check_resource_usage() {
    if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
        return 1
    fi
    
    cd "$TOOL_DIR"
    
    # Get container resource usage
    local resource_stats=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" 2>/dev/null)
    
    if [[ -n "$resource_stats" ]]; then
        print_status "Container resource usage:"
        echo "$resource_stats"
        log_health_check "INFO: Resource usage checked"
        
        # Check for high resource usage
        local high_cpu=$(echo "$resource_stats" | grep -E "[0-9]{2,}%" | grep -v "0%" | wc -l || echo "0")
        local high_memory=$(echo "$resource_stats" | grep -E "[0-9]{2,}%" | grep -v "0%" | wc -l || echo "0")
        
        if [[ "$high_cpu" -gt 0 ]]; then
            print_warning "High CPU usage detected in $high_cpu container(s)"
            log_health_check "WARNING: High CPU usage in $high_cpu container(s)"
        fi
        
        if [[ "$high_memory" -gt 0 ]]; then
            print_warning "High memory usage detected in $high_memory container(s)"
            log_health_check "WARNING: High memory usage in $high_memory container(s)"
        fi
    else
        print_warning "Could not retrieve resource usage"
        log_health_check "WARNING: Could not retrieve resource usage"
    fi
}

# Function to check logs for errors
check_logs() {
    if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
        return 1
    fi
    
    cd "$TOOL_DIR"
    
    # Check recent logs for errors
    local error_logs=$(docker-compose logs --tail=50 2>/dev/null | grep -i "error\|exception\|fatal\|panic" | tail -5 || echo "")
    
    if [[ -n "$error_logs" ]]; then
        print_warning "Recent error logs found:"
        echo "$error_logs"
        log_health_check "WARNING: Recent error logs found"
        return 1
    else
        print_success "No recent error logs found"
        log_health_check "INFO: No recent error logs found"
        return 0
    fi
}

# Function to check database connectivity
check_database() {
    if [[ ! -f "$TOOL_DIR/.env" ]]; then
        print_warning "Environment file not found, skipping database check"
        log_health_check "WARNING: Environment file not found for database check"
        return 0
    fi
    
    # Check if database connection can be established
    if [[ -f "$TOOL_DIR/database.js" ]] || [[ -f "$TOOL_DIR/database.py" ]]; then
        print_status "Database connectivity check available"
        log_health_check "INFO: Database connectivity check available"
        
        # Try to run database check if available
        if [[ -f "$TOOL_DIR/check-db.sh" ]]; then
            chmod +x "$TOOL_DIR/check-db.sh"
            if ./check-db.sh; then
                print_success "Database connectivity check passed"
                log_health_check "INFO: Database connectivity check passed"
                return 0
            else
                print_error "Database connectivity check failed"
                log_health_check "ERROR: Database connectivity check failed"
                return 1
            fi
        fi
    fi
    
    print_status "Database connectivity check not implemented"
    log_health_check "INFO: Database connectivity check not implemented"
    return 0
}

# Function to run comprehensive health check
run_comprehensive_check() {
    print_status "Starting comprehensive health check..."
    log_health_check "INFO: Starting comprehensive health check"
    
    local overall_health=0
    
    # Run all health checks
    check_docker || overall_health=$((overall_health + 1))
    check_docker_compose || overall_health=$((overall_health + 1))
    check_containers || overall_health=$((overall_health + 1))
    check_container_health || overall_health=$((overall_health + 1))
    check_health_endpoint || overall_health=$((overall_health + 1))
    check_resource_usage || overall_health=$((overall_health + 1))
    check_logs || overall_health=$((overall_health + 1))
    check_database || overall_health=$((overall_health + 1))
    
    echo ""
    if [[ $overall_health -eq 0 ]]; then
        print_success "All health checks passed! Tool is healthy."
        log_health_check "SUCCESS: All health checks passed"
        exit 0
    else
        print_error "Health check failed with $overall_health error(s)"
        log_health_check "ERROR: Health check failed with $overall_health error(s)"
        exit 1
    fi
}

# Function to show quick status
show_quick_status() {
    print_status "Quick status check..."
    
    if check_docker && check_containers; then
        print_success "Tool appears to be running"
        exit 0
    else
        print_error "Tool has issues"
        exit 1
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  check                 - Run comprehensive health check (default)"
    echo "  status               - Show quick status"
    echo "  containers           - Check container status only"
    echo "  resources            - Check resource usage only"
    echo "  logs                 - Check logs for errors only"
    echo "  database             - Check database connectivity only"
    echo "  help                 - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                   # Run full health check"
    echo "  $0 status            # Quick status check"
    echo "  $0 containers        # Container status only"
}

# Main script logic
case "${1:-}" in
    check|"")
        run_comprehensive_check
        ;;
    status)
        show_quick_status
        ;;
    containers)
        check_docker && check_containers
        ;;
    resources)
        check_docker && check_resource_usage
        ;;
    logs)
        check_docker && check_logs
        ;;
    database)
        check_database
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
