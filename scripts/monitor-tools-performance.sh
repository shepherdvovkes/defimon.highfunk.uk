#!/bin/bash

# Tools Performance Monitoring Script
# This script monitors the performance and health of all deployed tools

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
METRICS_DIR="/var/log/tools/metrics"
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=85
ALERT_THRESHOLD_DISK=90

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

# Function to create necessary directories
create_directories() {
    mkdir -p "$METRICS_DIR"
}

# Function to get system metrics
get_system_metrics() {
    local timestamp=$(date +%Y-%m-%d\ %H:%M:%S)
    
    # CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    
    # Memory usage
    local memory_info=$(free | grep Mem)
    local memory_total=$(echo $memory_info | awk '{print $2}')
    local memory_used=$(echo $memory_info | awk '{print $3}')
    local memory_usage=$(awk "BEGIN {printf \"%.1f\", ($memory_used/$memory_total)*100}")
    
    # Disk usage
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    # Load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    echo "$timestamp|$cpu_usage|$memory_usage|$disk_usage|$load_avg"
}

# Function to get docker container metrics
get_docker_metrics() {
    local tool_name="$1"
    local metrics=""
    
    if [[ -f "$TOOLS_BASE_DIR/$tool_name/docker-compose.yml" ]]; then
        cd "$TOOLS_BASE_DIR/$tool_name"
        
        # Get container stats
        local container_stats=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" 2>/dev/null || echo "")
        
        if [[ -n "$container_stats" ]]; then
            metrics="$container_stats"
        fi
        
        cd - > /dev/null
    fi
    
    echo "$metrics"
}

# Function to check tool health
check_tool_health() {
    local tool_name="$1"
    local health_status="UNKNOWN"
    local response_time="N/A"
    
    # Check if tool directory exists
    if [[ ! -d "$TOOLS_BASE_DIR/$tool_name" ]]; then
        echo "NOT_DEPLOYED|N/A|N/A"
        return
    fi
    
    # Check systemd service status
    local service_name="${tool_name//-/_}"
    if systemctl list-unit-files | grep -q "$service_name"; then
        if systemctl is-active --quiet "$service_name"; then
            health_status="HEALTHY"
        else
            health_status="STOPPED"
        fi
    else
        # Check docker-compose status
        if [[ -f "$TOOLS_BASE_DIR/$tool_name/docker-compose.yml" ]]; then
            cd "$TOOLS_BASE_DIR/$tool_name"
            local container_status=$(docker-compose ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null)
            
            if echo "$container_status" | grep -q "Up"; then
                health_status="HEALTHY"
            else
                health_status="UNHEALTHY"
            fi
            
            cd - > /dev/null
        fi
    fi
    
    # Try to measure response time if tool has health endpoint
    if [[ -f "$TOOLS_BASE_DIR/$tool_name/health-check.sh" ]]; then
        cd "$TOOLS_BASE_DIR/$tool_name"
        local start_time=$(date +%s%N)
        ./health-check.sh > /dev/null 2>&1
        local end_time=$(date +%s%N)
        response_time=$(awk "BEGIN {printf \"%.2f\", ($end_time - $start_time) / 1000000}")
        cd - > /dev/null
    fi
    
    echo "$health_status|$response_time|$(date +%Y-%m-%d\ %H:%M:%S)"
}

# Function to generate performance report
generate_performance_report() {
    local timestamp=$(date +%Y-%m-%d\ %H:%M:%S)
    local report_file="$METRICS_DIR/performance_report_$(date +%Y%m%d_%H%M%S).txt"
    
    print_header "Generating Performance Report"
    
    {
        echo "TOOLS PERFORMANCE REPORT"
        echo "Generated: $timestamp"
        echo "=================================="
        echo ""
        
        # System metrics
        echo "SYSTEM METRICS:"
        echo "---------------"
        local system_metrics=$(get_system_metrics)
        echo "Timestamp: $(echo $system_metrics | cut -d'|' -f1)"
        echo "CPU Usage: $(echo $system_metrics | cut -d'|' -f2)%"
        echo "Memory Usage: $(echo $system_metrics | cut -d'|' -f3)%"
        echo "Disk Usage: $(echo $system_metrics | cut -d'|' -f4)%"
        echo "Load Average: $(echo $system_metrics | cut -d'|' -f5)"
        echo ""
        
        # Tool health status
        echo "TOOL HEALTH STATUS:"
        echo "-------------------"
        printf "%-20s %-15s %-15s %-20s\n" "Tool" "Status" "Response Time" "Last Check"
        printf "%-20s %-15s %-15s %-20s\n" "----" "------" "-------------" "-----------"
        
        for tool in "${!TOOLS[@]}"; do
            local health_info=$(check_tool_health "$tool")
            local status=$(echo $health_info | cut -d'|' -f1)
            local response_time=$(echo $health_info | cut -d'|' -f2)
            local last_check=$(echo $health_info | cut -d'|' -f3)
            
            printf "%-20s %-15s %-15s %-20s\n" "$tool" "$status" "$response_time" "$last_check"
        done
        
        echo ""
        
        # Docker container metrics
        echo "DOCKER CONTAINER METRICS:"
        echo "-------------------------"
        for tool in "${!TOOLS[@]}"; do
            if [[ -d "$TOOLS_BASE_DIR/$tool_name" ]]; then
                echo "Tool: $tool"
                local docker_metrics=$(get_docker_metrics "$tool")
                if [[ -n "$docker_metrics" ]]; then
                    echo "$docker_metrics"
                else
                    echo "No containers running"
                fi
                echo ""
            fi
        done
        
        # Alerts
        echo "ALERTS:"
        echo "-------"
        local system_metrics=$(get_system_metrics)
        local cpu_usage=$(echo $system_metrics | cut -d'|' -f2)
        local memory_usage=$(echo $system_metrics | cut -d'|' -f3)
        local disk_usage=$(echo $system_metrics | cut -d'|' -f4)
        
        if (( $(echo "$cpu_usage > $ALERT_THRESHOLD_CPU" | bc -l) )); then
            echo "⚠️  HIGH CPU USAGE: ${cpu_usage}% (Threshold: ${ALERT_THRESHOLD_CPU}%)"
        fi
        
        if (( $(echo "$memory_usage > $ALERT_THRESHOLD_MEMORY" | bc -l) )); then
            echo "⚠️  HIGH MEMORY USAGE: ${memory_usage}% (Threshold: ${ALERT_THRESHOLD_MEMORY}%)"
        fi
        
        if (( $(echo "$disk_usage > $ALERT_THRESHOLD_DISK" | bc -l) )); then
            echo "⚠️  HIGH DISK USAGE: ${disk_usage}% (Threshold: ${ALERT_THRESHOLD_DISK}%)"
        fi
        
        # Check for unhealthy tools
        for tool in "${!TOOLS[@]}"; do
            local health_info=$(check_tool_health "$tool")
            local status=$(echo $health_info | cut -d'|' -f1)
            
            if [[ "$status" == "UNHEALTHY" ]]; then
                echo "🚨 UNHEALTHY TOOL: $tool"
            elif [[ "$status" == "STOPPED" ]]; then
                echo "🟡 STOPPED TOOL: $tool"
            fi
        done
        
    } > "$report_file"
    
    print_success "Performance report generated: $report_file"
    echo "$report_file"
}

# Function to monitor tools continuously
monitor_continuously() {
    local interval="${1:-60}"
    
    print_header "Starting Continuous Monitoring (Interval: ${interval}s)"
    print_status "Press Ctrl+C to stop monitoring"
    
    while true; do
        clear
        print_header "Real-time Tools Monitoring"
        echo "Last updated: $(date)"
        echo "Press Ctrl+C to stop"
        echo ""
        
        # System overview
        echo "SYSTEM OVERVIEW:"
        echo "================"
        local system_metrics=$(get_system_metrics)
        local cpu_usage=$(echo $system_metrics | cut -d'|' -f2)
        local memory_usage=$(echo $system_metrics | cut -d'|' -f3)
        local disk_usage=$(echo $system_metrics | cut -d'|' -f4)
        local load_avg=$(echo $system_metrics | cut -d'|' -f5)
        
        printf "CPU: %-6s | Memory: %-6s | Disk: %-6s | Load: %-6s\n" \
               "${cpu_usage}%" "${memory_usage}%" "${disk_usage}%" "$load_avg"
        
        echo ""
        
        # Tools status
        echo "TOOLS STATUS:"
        echo "============="
        printf "%-20s %-15s %-15s %-10s\n" "Tool" "Status" "Response Time" "Health"
        printf "%-20s %-15s %-15s %-10s\n" "----" "------" "-------------" "------"
        
        for tool in "${!TOOLS[@]}"; do
            local health_info=$(check_tool_health "$tool")
            local status=$(echo $health_info | cut -d'|' -f1)
            local response_time=$(echo $health_info | cut -d'|' -f2)
            
            local health_icon=""
            case "$status" in
                "HEALTHY") health_icon="🟢" ;;
                "UNHEALTHY") health_icon="🔴" ;;
                "STOPPED") health_icon="🟡" ;;
                "NOT_DEPLOYED") health_icon="⚪" ;;
                *) health_icon="❓" ;;
            esac
            
            printf "%-20s %-15s %-15s %-10s\n" "$tool" "$status" "$response_time" "$health_icon"
        done
        
        echo ""
        echo "Monitoring will refresh in ${interval} seconds..."
        sleep "$interval"
    done
}

# Function to show historical metrics
show_historical_metrics() {
    local tool_name="$1"
    local days="${2:-7}"
    
    print_header "Historical Metrics for $tool_name (Last $days days)"
    
    local metrics_files=$(find "$METRICS_DIR" -name "performance_report_*.txt" -mtime -$days | sort)
    
    if [[ -z "$metrics_files" ]]; then
        print_warning "No historical metrics found for the last $days days"
        return
    fi
    
    echo "Available reports:"
    for file in $metrics_files; do
        local filename=$(basename "$file")
        local timestamp=$(echo "$filename" | sed 's/performance_report_\(.*\)\.txt/\1/' | sed 's/_/ /')
        echo "  $timestamp - $filename"
    done
    
    echo ""
    print_status "To view a specific report, use: cat $METRICS_DIR/filename"
}

# Function to cleanup old metrics
cleanup_old_metrics() {
    local days="${1:-30}"
    
    print_header "Cleaning up metrics older than $days days"
    
    local old_files=$(find "$METRICS_DIR" -name "performance_report_*.txt" -mtime +$days)
    
    if [[ -z "$old_files" ]]; then
        print_status "No old metrics files to clean up"
        return
    fi
    
    local count=0
    for file in $old_files; do
        rm "$file"
        count=$((count + 1))
    done
    
    print_success "Cleaned up $count old metrics files"
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  report [INTERVAL]     - Generate performance report (optional interval in seconds)"
    echo "  monitor [INTERVAL]    - Monitor tools continuously (default: 60s)"
    echo "  history [TOOL] [DAYS] - Show historical metrics for a tool (default: 7 days)"
    echo "  cleanup [DAYS]        - Clean up old metrics files (default: 30 days)"
    echo "  help                  - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 report                    # Generate single report"
    echo "  $0 report 300               # Generate report every 5 minutes"
    echo "  $0 monitor                  # Start continuous monitoring"
    echo "  $0 monitor 30               # Monitor with 30s refresh"
    echo "  $0 history l2-networks-sync # Show history for specific tool"
    echo "  $0 cleanup 14               # Clean up files older than 14 days"
}

# Main script logic
case "${1:-}" in
    report)
        create_directories
        if [[ -n "$2" ]] && [[ "$2" =~ ^[0-9]+$ ]]; then
            while true; do
                generate_performance_report
                sleep "$2"
            done
        else
            generate_performance_report
        fi
        ;;
    monitor)
        create_directories
        local interval="${2:-60}"
        monitor_continuously "$interval"
        ;;
    history)
        if [[ -z "$2" ]]; then
            print_error "Please specify a tool name"
            show_help
            exit 1
        fi
        show_historical_metrics "$2" "$3"
        ;;
    cleanup)
        create_directories
        cleanup_old_metrics "$2"
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
