#!/bin/bash

# Ethereum Node Real-time Monitor
# Мониторинг Geth и Lighthouse в реальном времени

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
GETH_CONTAINER="${GETH_CONTAINER:-geth-full-node-simple}"
LIGHTHOUSE_CONTAINER="${LIGHTHOUSE_CONTAINER:-lighthouse-beacon}"
GETH_RPC_URL="${GETH_RPC_URL:-http://localhost:8545}"
LIGHTHOUSE_RPC_URL="${LIGHTHOUSE_RPC_URL:-http://localhost:5052}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-5}"

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

# Function to format bytes to human readable
format_bytes() {
    local bytes=$1
    if [ "$bytes" -gt 1073741824 ]; then
        echo "$(echo "scale=2; $bytes/1073741824" | bc) GB"
    elif [ "$bytes" -gt 1048576 ]; then
        echo "$(echo "scale=2; $bytes/1048576" | bc) MB"
    elif [ "$bytes" -gt 1024 ]; then
        echo "$(echo "scale=2; $bytes/1024" | bc) KB"
    else
        echo "${bytes} B"
    fi
}

# Function to format time
format_time() {
    local seconds=$1
    if [ "$seconds" -le 0 ]; then echo "0s"; return; fi
    local d=$((seconds/86400))
    local h=$(( (seconds%86400)/3600 ))
    local m=$(( (seconds%3600)/60 ))
    local s=$(( seconds%60 ))
    local out=""
    [ $d -gt 0 ] && out+="${d}d "
    [ $h -gt 0 ] && out+="${h}h "
    [ $m -gt 0 ] && out+="${m}m "
    out+="${s}s"
    echo "$out"
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

# Function to get disk space used by Ethereum data
get_ethereum_disk_usage() {
    if command -v docker &> /dev/null; then
        local geth_size=$(docker exec $GETH_CONTAINER du -sh /root/.ethereum 2>/dev/null | awk '{print $1}' || echo "0")
        local lighthouse_size=$(docker exec $LIGHTHOUSE_CONTAINER du -sh /root/.lighthouse 2>/dev/null | awk '{print $1}' || echo "0")
        echo "Geth: $geth_size | Lighthouse: $lighthouse_size"
    else
        echo "Docker not available"
    fi
}

# Function to get Geth status
get_geth_status() {
    local response=$(curl -s -X POST -H 'Content-Type: application/json' \
        --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
        "$GETH_RPC_URL" 2>/dev/null || echo '{"result":false}')
    
    local syncing=$(echo "$response" | jq -r '.result // false')
    
    if [ "$syncing" = "false" ]; then
        local block_number=$(curl -s -X POST -H 'Content-Type: application/json' \
            --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            "$GETH_RPC_URL" 2>/dev/null | jq -r '.result // "0x0"')
        local block_dec=$(printf "%d" "$block_number")
        echo "SYNCED:$block_dec"
    else
        local current=$(echo "$response" | jq -r '.result.currentBlock // "0x0"')
        local highest=$(echo "$response" | jq -r '.result.highestBlock // "0x0"')
        local current_dec=$(printf "%d" "$current")
        local highest_dec=$(printf "%d" "$highest")
        local progress=0
        if [ "$highest_dec" -gt 0 ]; then
            progress=$(echo "scale=2; $current_dec * 100 / $highest_dec" | bc)
        fi
        echo "SYNCING:$current_dec:$highest_dec:$progress"
    fi
}

# Function to get Lighthouse status
get_lighthouse_status() {
    local response=$(curl -s -X GET "$LIGHTHOUSE_RPC_URL/eth/v1/node/syncing" 2>/dev/null || echo '{"data":{"is_syncing":false}}')
    
    local syncing=$(echo "$response" | jq -r '.data.is_syncing // false')
    
    if [ "$syncing" = "false" ]; then
        local head_slot=$(curl -s -X GET "$LIGHTHOUSE_RPC_URL/eth/v1/beacon/headers/head" 2>/dev/null | jq -r '.data.header.message.slot // "0"')
        echo "SYNCED:$head_slot"
    else
        local head_slot=$(echo "$response" | jq -r '.data.head_slot // "0"')
        local sync_distance=$(echo "$response" | jq -r '.data.sync_distance // "0"')
        local est_time=$(echo "$response" | jq -r '.data.est_time // "0"')
        echo "SYNCING:$head_slot:$sync_distance:$est_time"
    fi
}

# Function to get container stats
get_container_stats() {
    local container=$1
    if command -v docker &> /dev/null && docker ps | grep -q "$container"; then
        local stats=$(docker stats --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" "$container" 2>/dev/null | tail -1)
        echo "$stats"
    else
        echo "Container not running"
    fi
}

# Function to clear screen and show header
clear_screen() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    Ethereum Node Real-time Monitor                          ║${NC}"
    echo -e "${WHITE}║                    Geth + Lighthouse Status Dashboard                       ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to show system resources
show_system_resources() {
    echo -e "${CYAN}📊 System Resources:${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    local cpu_usage=$(get_cpu_usage)
    local mem_usage=$(get_memory_usage)
    local disk_usage=$(get_disk_usage)
    local ethereum_disk=$(get_ethereum_disk_usage)
    
    printf "%-20s %-15s %-15s %-15s\n" "Resource" "Usage" "Status" "Details"
    echo "────────────────────────────────────────────────────────────────────────────────"
    
    # CPU
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        printf "%-20s %-15s %-15s %-15s\n" "CPU" "${cpu_usage}%" "${RED}HIGH${NC}" ""
    elif (( $(echo "$cpu_usage > 60" | bc -l) )); then
        printf "%-20s %-15s %-15s %-15s\n" "CPU" "${cpu_usage}%" "${YELLOW}MODERATE${NC}" ""
    else
        printf "%-20s %-15s %-15s %-15s\n" "CPU" "${cpu_usage}%" "${GREEN}NORMAL${NC}" ""
    fi
    
    # Memory
    if (( $(echo "$mem_usage > 80" | bc -l) )); then
        printf "%-20s %-15s %-15s %-15s\n" "Memory" "${mem_usage}%" "${RED}HIGH${NC}" ""
    elif (( $(echo "$mem_usage > 60" | bc -l) )); then
        printf "%-20s %-15s %-15s %-15s\n" "Memory" "${mem_usage}%" "${YELLOW}MODERATE${NC}" ""
    else
        printf "%-20s %-15s %-15s %-15s\n" "Memory" "${mem_usage}%" "${GREEN}NORMAL${NC}" ""
    fi
    
    # Disk
    if [ "$disk_usage" -gt 80 ]; then
        printf "%-20s %-15s %-15s %-15s\n" "Disk" "${disk_usage}%" "${RED}HIGH${NC}" ""
    elif [ "$disk_usage" -gt 60 ]; then
        printf "%-20s %-15s %-15s %-15s\n" "Disk" "${disk_usage}%" "${YELLOW}MODERATE${NC}" ""
    else
        printf "%-20s %-15s %-15s %-15s\n" "Disk" "${disk_usage}%" "${GREEN}NORMAL${NC}" ""
    fi
    
    echo ""
    echo -e "${CYAN}📁 Ethereum Data Usage:${NC}"
    echo "$ethereum_disk"
    echo ""
}

# Function to show Geth status
show_geth_status() {
    echo -e "${GREEN}🔗 Geth (Execution Client) Status:${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    local geth_status=$(get_geth_status)
    local container_stats=$(get_container_stats "$GETH_CONTAINER")
    
    if [[ "$geth_status" == SYNCED:* ]]; then
        local block_number=$(echo "$geth_status" | cut -d: -f2)
        printf "%-20s %-15s %-15s %-15s\n" "Status" "Block Number" "Sync Progress" "Container"
        echo "────────────────────────────────────────────────────────────────────────────────"
        printf "%-20s %-15s %-15s %-15s\n" "${GREEN}SYNCED${NC}" "$block_number" "100%" "${GREEN}Running${NC}"
    elif [[ "$geth_status" == SYNCING:* ]]; then
        local current=$(echo "$geth_status" | cut -d: -f2)
        local highest=$(echo "$geth_status" | cut -d: -f3)
        local progress=$(echo "$geth_status" | cut -d: -f4)
        printf "%-20s %-15s %-15s %-15s\n" "Status" "Current Block" "Progress" "Container"
        echo "────────────────────────────────────────────────────────────────────────────────"
        printf "%-20s %-15s %-15s %-15s\n" "${YELLOW}SYNCING${NC}" "$current / $highest" "${progress}%" "${GREEN}Running${NC}"
    else
        printf "%-20s %-15s %-15s %-15s\n" "Status" "Block Number" "Sync Progress" "Container"
        echo "────────────────────────────────────────────────────────────────────────────────"
        printf "%-20s %-15s %-15s %-15s\n" "${RED}ERROR${NC}" "N/A" "N/A" "${RED}Error${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}📊 Container Stats:${NC}"
    echo "$container_stats"
    echo ""
}

# Function to show Lighthouse status
show_lighthouse_status() {
    echo -e "${BLUE}🏮 Lighthouse (Consensus Client) Status:${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    local lighthouse_status=$(get_lighthouse_status)
    local container_stats=$(get_container_stats "$LIGHTHOUSE_CONTAINER")
    
    if [[ "$lighthouse_status" == SYNCED:* ]]; then
        local head_slot=$(echo "$lighthouse_status" | cut -d: -f2)
        printf "%-20s %-15s %-15s %-15s\n" "Status" "Head Slot" "Sync Progress" "Container"
        echo "────────────────────────────────────────────────────────────────────────────────"
        printf "%-20s %-15s %-15s %-15s\n" "${GREEN}SYNCED${NC}" "$head_slot" "100%" "${GREEN}Running${NC}"
    elif [[ "$lighthouse_status" == SYNCING:* ]]; then
        local head_slot=$(echo "$lighthouse_status" | cut -d: -f2)
        local sync_distance=$(echo "$lighthouse_status" | cut -d: -f3)
        local est_time=$(echo "$lighthouse_status" | cut -d: -f4)
        printf "%-20s %-15s %-15s %-15s\n" "Status" "Head Slot" "Distance" "Container"
        echo "────────────────────────────────────────────────────────────────────────────────"
        printf "%-20s %-15s %-15s %-15s\n" "${YELLOW}SYNCING${NC}" "$head_slot" "$sync_distance slots" "${GREEN}Running${NC}"
        if [ "$est_time" != "0" ] && [ "$est_time" != "null" ]; then
            echo -e "${CYAN}Estimated time to completion:${NC} $est_time"
        fi
    else
        printf "%-20s %-15s %-15s %-15s\n" "Status" "Head Slot" "Sync Progress" "Container"
        echo "────────────────────────────────────────────────────────────────────────────────"
        printf "%-20s %-15s %-15s %-15s\n" "${RED}ERROR${NC}" "N/A" "N/A" "${RED}Error${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}📊 Container Stats:${NC}"
    echo "$container_stats"
    echo ""
}

# Function to show network info
show_network_info() {
    echo -e "${PURPLE}🌐 Network Information:${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    printf "%-20s %-15s %-15s %-15s\n" "Service" "Port" "Status" "URL"
    echo "────────────────────────────────────────────────────────────────────────────────"
    
    # Geth RPC
    if curl -f "$GETH_RPC_URL" > /dev/null 2>&1; then
        printf "%-20s %-15s %-15s %-15s\n" "Geth RPC" "8545" "${GREEN}UP${NC}" "$GETH_RPC_URL"
    else
        printf "%-20s %-15s %-15s %-15s\n" "Geth RPC" "8545" "${RED}DOWN${NC}" "$GETH_RPC_URL"
    fi
    
    # Geth WebSocket
    if curl -f "http://localhost:8546" > /dev/null 2>&1; then
        printf "%-20s %-15s %-15s %-15s\n" "Geth WebSocket" "8546" "${GREEN}UP${NC}" "ws://localhost:8546"
    else
        printf "%-20s %-15s %-15s %-15s\n" "Geth WebSocket" "8546" "${RED}DOWN${NC}" "ws://localhost:8546"
    fi
    
    # Lighthouse RPC
    if curl -f "$LIGHTHOUSE_RPC_URL/eth/v1/node/version" > /dev/null 2>&1; then
        printf "%-20s %-15s %-15s %-15s\n" "Lighthouse RPC" "5052" "${GREEN}UP${NC}" "$LIGHTHOUSE_RPC_URL"
    else
        printf "%-20s %-15s %-15s %-15s\n" "Lighthouse RPC" "5052" "${RED}DOWN${NC}" "$LIGHTHOUSE_RPC_URL"
    fi
    
    # Geth Metrics
    if curl -f "http://localhost:6060/debug/metrics" > /dev/null 2>&1; then
        printf "%-20s %-15s %-15s %-15s\n" "Geth Metrics" "6060" "${GREEN}UP${NC}" "http://localhost:6060"
    else
        printf "%-20s %-15s %-15s %-15s\n" "Geth Metrics" "6060" "${RED}DOWN${NC}" "http://localhost:6060"
    fi
    
    # Lighthouse Metrics
    if curl -f "http://localhost:5054/metrics" > /dev/null 2>&1; then
        printf "%-20s %-15s %-15s %-15s\n" "Lighthouse Metrics" "5054" "${GREEN}UP${NC}" "http://localhost:5054"
    else
        printf "%-20s %-15s %-15s %-15s\n" "Lighthouse Metrics" "5054" "${RED}DOWN${NC}" "http://localhost:5054"
    fi
    
    echo ""
}

# Function to show footer
show_footer() {
    echo -e "${WHITE}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Last updated:${NC} $(date '+%Y-%m-%d %H:%M:%S') | ${CYAN}Refresh interval:${NC} ${INTERVAL_SECONDS}s"
    echo -e "${CYAN}Press Ctrl+C to exit${NC}"
    echo ""
}

# Main monitoring loop
main() {
    # Check dependencies
    if ! command -v jq >/dev/null 2>&1; then
        print_error "jq is required but not installed. Please install jq."
        exit 1
    fi
    
    if ! command -v bc >/dev/null 2>&1; then
        print_error "bc is required but not installed. Please install bc."
        exit 1
    fi
    
    print_header "Starting Ethereum Node Monitor..."
    print_status "Monitoring containers: $GETH_CONTAINER, $LIGHTHOUSE_CONTAINER"
    print_status "Refresh interval: ${INTERVAL_SECONDS} seconds"
    echo ""
    
    # Main loop
    while true; do
        clear_screen
        show_system_resources
        show_geth_status
        show_lighthouse_status
        show_network_info
        show_footer
        sleep "$INTERVAL_SECONDS"
    done
}

# Handle Ctrl+C
trap 'echo -e "\n${GREEN}Monitor stopped.${NC}"; exit 0' INT

# Run main function
main "$@"
