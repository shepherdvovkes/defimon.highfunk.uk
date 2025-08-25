#!/bin/bash

# DEFIMON System Performance Monitor
# Детальный мониторинг производительности системы

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_header() {
    echo -e "${PURPLE}[HEADER]${NC} $1"
}

print_system() {
    echo -e "${CYAN}[SYSTEM]${NC} $1"
}

# Function to get CPU usage
get_cpu_usage() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo "$cpu_usage"
}

# Function to get memory usage
get_memory_usage() {
    local mem_usage=$(free | awk '/Mem:/ {printf("%.1f", $3/$2 * 100.0)}')
    echo "$mem_usage"
}

# Function to get disk usage
get_disk_usage() {
    local disk_usage=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
    echo "$disk_usage"
}

# Function to get network usage
get_network_usage() {
    local interface=$(ip route | grep default | awk '{print $5}' | head -1)
    if [ -n "$interface" ]; then
        local rx_bytes=$(cat /sys/class/net/$interface/statistics/rx_bytes 2>/dev/null || echo "0")
        local tx_bytes=$(cat /sys/class/net/$interface/statistics/tx_bytes 2>/dev/null || echo "0")
        echo "$interface:$rx_bytes:$tx_bytes"
    else
        echo "unknown:0:0"
    fi
}

# Function to check Docker containers
check_docker_containers() {
    echo "🐳 Docker Containers Status:"
    echo "============================"
    
    if command -v docker &> /dev/null; then
        local containers=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")
        echo "$containers"
        
        # Check for stopped containers
        local stopped=$(docker ps -a --filter "status=exited" --format "{{.Names}}")
        if [ -n "$stopped" ]; then
            print_warning "Stopped containers:"
            echo "$stopped"
        fi
    else
        print_error "Docker not installed"
    fi
    echo ""
}

# Function to check service health
check_service_health() {
    echo "🔍 Service Health Check:"
    echo "========================"
    
    local services=(
        "http://localhost:8000/health:API Gateway"
        "http://localhost:8002/health:Analytics API"
        "http://localhost:8001/health:AI/ML Service"
        "http://localhost:3000:Frontend"
        "http://localhost:8080:Admin Dashboard"
        "http://localhost:9090/-/healthy:Prometheus"
        "http://localhost:3001/api/health:Grafana"
    )
    
    for service in "${services[@]}"; do
        local url=$(echo "$service" | cut -d: -f1)
        local name=$(echo "$service" | cut -d: -f2)
        
        if curl -f "$url" > /dev/null 2>&1; then
            print_success "✅ $name"
        else
            print_error "❌ $name"
        fi
    done
    echo ""
}

# Function to check database status
check_database_status() {
    echo "🗄️ Database Status:"
    echo "==================="
    
    # PostgreSQL
    if command -v docker &> /dev/null && docker ps | grep -q postgres; then
        if docker-compose -f infrastructure/docker-compose.yml exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
            print_success "✅ PostgreSQL"
        else
            print_error "❌ PostgreSQL"
        fi
    else
        print_warning "⚠️ PostgreSQL container not running"
    fi
    
    # Redis
    if command -v docker &> /dev/null && docker ps | grep -q redis; then
        if docker-compose -f infrastructure/docker-compose.yml exec -T redis redis-cli ping > /dev/null 2>&1; then
            print_success "✅ Redis"
        else
            print_error "❌ Redis"
        fi
    else
        print_warning "⚠️ Redis container not running"
    fi
    
    # ClickHouse
    if curl -f http://localhost:8123/ping > /dev/null 2>&1; then
        print_success "✅ ClickHouse"
    else
        print_error "❌ ClickHouse"
    fi
    
    # Kafka
    if command -v docker &> /dev/null && docker ps | grep -q kafka; then
        if docker-compose -f infrastructure/docker-compose.yml exec -T kafka kafka-topics --bootstrap-server localhost:9092 --list > /dev/null 2>&1; then
            print_success "✅ Kafka"
        else
            print_error "❌ Kafka"
        fi
    else
        print_warning "⚠️ Kafka container not running"
    fi
    echo ""
}

# Function to show system resources
show_system_resources() {
    echo "📊 System Resources:"
    echo "===================="
    
    # CPU
    local cpu_usage=$(get_cpu_usage)
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        print_error "CPU Usage: ${cpu_usage}% (High)"
    elif (( $(echo "$cpu_usage > 60" | bc -l) )); then
        print_warning "CPU Usage: ${cpu_usage}% (Moderate)"
    else
        print_success "CPU Usage: ${cpu_usage}% (Normal)"
    fi
    
    # Memory
    local mem_usage=$(get_memory_usage)
    if (( $(echo "$mem_usage > 80" | bc -l) )); then
        print_error "Memory Usage: ${mem_usage}% (High)"
    elif (( $(echo "$mem_usage > 60" | bc -l) )); then
        print_warning "Memory Usage: ${mem_usage}% (Moderate)"
    else
        print_success "Memory Usage: ${mem_usage}% (Normal)"
    fi
    
    # Disk
    local disk_usage=$(get_disk_usage)
    if [ "$disk_usage" -gt 80 ]; then
        print_error "Disk Usage: ${disk_usage}% (High)"
    elif [ "$disk_usage" -gt 60 ]; then
        print_warning "Disk Usage: ${disk_usage}% (Moderate)"
    else
        print_success "Disk Usage: ${disk_usage}% (Normal)"
    fi
    
    # Network
    local network_info=$(get_network_usage)
    local interface=$(echo "$network_info" | cut -d: -f1)
    local rx_bytes=$(echo "$network_info" | cut -d: -f2)
    local tx_bytes=$(echo "$network_info" | cut -d: -f3)
    
    if [ "$interface" != "unknown" ]; then
        local rx_mb=$(echo "scale=2; $rx_bytes / 1024 / 1024" | bc -l 2>/dev/null || echo "0")
        local tx_mb=$(echo "scale=2; $tx_bytes / 1024 / 1024" | bc -l 2>/dev/null || echo "0")
        print_success "Network: $interface (RX: ${rx_mb}MB, TX: ${tx_mb}MB)"
    else
        print_warning "Network: Unable to determine interface"
    fi
    echo ""
}

# Function to show disk space
show_disk_space() {
    echo "💾 Disk Space:"
    echo "=============="
    
    df -h | grep -E "^/dev/" | while read line; do
        local filesystem=$(echo "$line" | awk '{print $1}')
        local size=$(echo "$line" | awk '{print $2}')
        local used=$(echo "$line" | awk '{print $3}')
        local available=$(echo "$line" | awk '{print $4}')
        local use_percent=$(echo "$line" | awk '{print $5}')
        local mountpoint=$(echo "$line" | awk '{print $6}')
        
        if [[ $use_percent =~ ^[0-9]+$ ]] && [ "$use_percent" -gt 80 ]; then
            print_error "$filesystem: ${use_percent}% used (${available} available) -> $mountpoint"
        elif [[ $use_percent =~ ^[0-9]+$ ]] && [ "$use_percent" -gt 60 ]; then
            print_warning "$filesystem: ${use_percent}% used (${available} available) -> $mountpoint"
        else
            print_success "$filesystem: ${use_percent}% used (${available} available) -> $mountpoint"
        fi
    done
    echo ""
}

# Function to show process information
show_process_info() {
    echo "🔧 Top Processes:"
    echo "================="
    
    echo "CPU Usage:"
    ps aux --sort=-%cpu | head -6 | awk '{print $3"%", $11}' | while read line; do
        echo "  $line"
    done
    
    echo ""
    echo "Memory Usage:"
    ps aux --sort=-%mem | head -6 | awk '{print $4"%", $11}' | while read line; do
        echo "  $line"
    done
    echo ""
}

# Function to show Docker resource usage
show_docker_resources() {
    if command -v docker &> /dev/null; then
        echo "🐳 Docker Resource Usage:"
        echo "========================="
        
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" | head -10
        echo ""
    fi
}

# Function to show system information
show_system_info() {
    echo "ℹ️ System Information:"
    echo "====================="
    
    echo "OS: $(lsb_release -d | cut -f2 2>/dev/null || echo "Unknown")"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "CPU: $(nproc) cores"
    echo "RAM: $(free -h | awk '/^Mem:/{print $2}')"
    echo "Uptime: $(uptime -p)"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
}

# Function to show recommendations
show_recommendations() {
    echo "💡 Recommendations:"
    echo "=================="
    
    local cpu_usage=$(get_cpu_usage)
    local mem_usage=$(get_memory_usage)
    local disk_usage=$(get_disk_usage)
    
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        print_warning "High CPU usage detected. Consider optimizing processes or upgrading CPU."
    fi
    
    if (( $(echo "$mem_usage > 80" | bc -l) )); then
        print_warning "High memory usage detected. Consider adding more RAM or optimizing memory usage."
    fi
    
    if [ "$disk_usage" -gt 80 ]; then
        print_warning "High disk usage detected. Consider cleaning up files or expanding storage."
    fi
    
    # Check for stopped containers
    if command -v docker &> /dev/null; then
        local stopped_count=$(docker ps -a --filter "status=exited" -q | wc -l)
        if [ "$stopped_count" -gt 0 ]; then
            print_warning "Found $stopped_count stopped containers. Consider cleaning them up."
        fi
    fi
    
    echo ""
}

# Main function
main() {
    echo "🔍 DEFIMON System Performance Monitor"
    echo "====================================="
    echo "Timestamp: $(date)"
    echo ""
    
    show_system_info
    show_system_resources
    show_disk_space
    check_docker_containers
    check_service_health
    check_database_status
    show_process_info
    show_docker_resources
    show_recommendations
    
    echo "====================================="
    print_success "System monitoring completed"
}

# Handle command line arguments
case "${1:-}" in
    "continuous"|"-c")
        print_status "Starting continuous monitoring (press Ctrl+C to stop)..."
        while true; do
            clear
            main
            sleep 30
        done
        ;;
    "json"|"-j")
        # Output in JSON format for API consumption
        cpu_usage=$(get_cpu_usage)
        mem_usage=$(get_memory_usage)
        disk_usage=$(get_disk_usage)
        
        cat << EOF
{
  "timestamp": "$(date -Iseconds)",
  "system": {
    "cpu_usage": $cpu_usage,
    "memory_usage": $mem_usage,
    "disk_usage": $disk_usage,
    "uptime": "$(uptime -p | sed 's/up //')",
    "load_average": "$(uptime | awk -F'load average:' '{print $2}' | tr -d ' ')",
    "kernel": "$(uname -r)",
    "architecture": "$(uname -m)"
  },
  "docker": {
    "running_containers": $(docker ps -q | wc -l),
    "stopped_containers": $(docker ps -a --filter "status=exited" -q | wc -l)
  }
}
EOF
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no args)  - Run system monitor once"
        echo "  continuous - Run continuous monitoring"
        echo "  json       - Output in JSON format"
        echo "  help       - Show this help"
        ;;
    *)
        main
        ;;
esac
