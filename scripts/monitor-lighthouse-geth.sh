#!/bin/bash

# DEFIMON Lighthouse & Geth Sync Monitor
# Monitors the sync status of lighthouse and geth containers on Vovkes server
# Run this script on macOS to monitor remote containers

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

# Configuration
SERVER_HOST="vovkes-server"
DOCKER_COMPOSE_DIR="/opt/defimon/infrastructure"
LIGHTHOUSE_CONTAINER="lighthouse"
GETH_CONTAINER="geth"
MONITORING_INTERVAL=30

# Function to check if SSH connection is available
check_ssh_connection() {
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$SERVER_HOST" "echo 'SSH connection successful'" >/dev/null 2>&1; then
        print_error "Cannot connect to $SERVER_HOST via SSH"
        print_error "Make sure you have SSH access configured"
        exit 1
    fi
    print_success "SSH connection to $SERVER_HOST established"
}

# Function to get container status
get_container_status() {
    local container_name="$1"
    ssh "$SERVER_HOST" "docker ps --filter name=$container_name --format '{{.Status}}' 2>/dev/null || echo 'Container not found'"
}

# Function to get container logs (last few lines)
get_container_logs() {
    local container_name="$1"
    local lines="${2:-10}"
    ssh "$SERVER_HOST" "docker logs --tail=$lines $container_name 2>/dev/null || echo 'No logs available'"
}

# Function to check lighthouse sync status
check_lighthouse_sync() {
    print_header "🔦 Lighthouse Sync Status"
    echo "================================"
    
    # Check if container is running
    local status=$(get_container_status "$LIGHTHOUSE_CONTAINER")
    if [[ "$status" == "Container not found" ]]; then
        print_error "Lighthouse container not found"
        return 1
    fi
    
    if [[ "$status" == *"Up"* ]]; then
        print_success "✅ Lighthouse container is running"
        echo "Status: $status"
        
        # Check lighthouse API for sync status
        local sync_status=$(ssh "$SERVER_HOST" "curl -s http://localhost:5052/eth/v1/node/syncing 2>/dev/null || echo 'API not accessible'")
        if [[ "$sync_status" != "API not accessible" ]]; then
            echo "Sync API Response: $sync_status"
            
            # Parse sync status and get detailed progress
            if [[ "$sync_status" == *"false"* ]]; then
                print_success "✅ Lighthouse is fully synced"
                
                # Get current head slot
                local head_slot=$(ssh "$SERVER_HOST" "curl -s http://localhost:5052/eth/v1/beacon/headers/head 2>/dev/null | jq -r '.data.header.message.slot' 2>/dev/null || echo '0'")
                if [[ "$head_slot" != "0" ]]; then
                    local head_slot_decimal=$(printf "%d" "$head_slot")
                    echo "Current Head Slot: $head_slot_decimal"
                fi
                
            elif [[ "$sync_status" == *"true"* ]]; then
                print_warning "⚠️ Lighthouse is still syncing"
                
                # Get detailed sync progress
                local sync_data=$(ssh "$SERVER_HOST" "curl -s http://localhost:5052/eth/v1/node/syncing 2>/dev/null | jq -r '.data' 2>/dev/null || echo '{}'")
                
                if [[ "$sync_data" != "{}" ]]; then
                    local head_slot=$(echo "$sync_data" | jq -r '.head_slot // 0' 2>/dev/null || echo '0')
                    local sync_distance=$(echo "$sync_data" | jq -r '.sync_distance // 0' 2>/dev/null || echo '0')
                    local is_syncing=$(echo "$sync_data" | jq -r '.is_syncing // false' 2>/dev/null || echo 'false')
                    
                    if [[ "$head_slot" != "0" ]]; then
                        local head_slot_decimal=$(printf "%d" "$head_slot")
                        local sync_distance_decimal=$(printf "%d" "$sync_distance")
                        local current_slot=$((head_slot_decimal - sync_distance_decimal))
                        
                        echo "Target Head Slot: $head_slot_decimal"
                        echo "Current Sync Slot: $current_slot"
                        echo "Remaining Slots: $sync_distance_decimal"
                        
                        # Calculate percentage
                        if [[ "$head_slot_decimal" -gt 0 ]]; then
                            local progress_percent=$(( (current_slot * 100) / head_slot_decimal ))
                            echo "Sync Progress: ${progress_percent}%"
                        fi
                    fi
                fi
                
            else
                print_warning "⚠️ Unknown sync status"
            fi
        else
            print_warning "⚠️ Lighthouse API not accessible on port 5052"
        fi
        
        # Check JWT secret
        local jwt_size=$(ssh "$SERVER_HOST" "wc -c /jwtsecret 2>/dev/null | cut -d' ' -f1 || echo '0'")
        if [[ "$jwt_size" == "32" ]]; then
            print_success "✅ JWT secret is correct size (32 bytes)"
        else
            print_warning "⚠️ JWT secret size: $jwt_size bytes (expected 32)"
        fi
        
    else
        print_error "❌ Lighthouse container is not running"
        echo "Status: $status"
    fi
    
    echo ""
}

# Function to check geth sync status
check_geth_sync() {
    print_header "⛓️ Geth Sync Status"
    echo "=========================="
    
    # Check if container is running
    local status=$(get_container_status "$GETH_CONTAINER")
    if [[ "$status" == "Container not found" ]]; then
        print_error "Geth container not found"
        return 1
    fi
    
    if [[ "$status" == *"Up"* ]]; then
        print_success "✅ Geth container is running"
        echo "Status: $status"
        
        # Check geth RPC for sync status
        local sync_status=$(ssh "$SERVER_HOST" "curl -s -X POST -H 'Content-Type: application/json' --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_syncing\",\"params\":[],\"id\":1}' http://localhost:8545 2>/dev/null || echo 'RPC not accessible'")
        
        if [[ "$sync_status" != "RPC not accessible" ]]; then
            echo "Sync RPC Response: $sync_status"
            
            # Parse sync status and get detailed progress
            if [[ "$sync_status" == *"false"* ]]; then
                print_success "✅ Geth is fully synced"
                
                # Get current block number
                local current_block=$(ssh "$SERVER_HOST" "curl -s -X POST -H 'Content-Type: application/json' --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}' http://localhost:8545 2>/dev/null | jq -r '.result' 2>/dev/null || echo '0'")
                if [[ "$current_block" != "0" ]]; then
                    local block_decimal=$(printf "%d" "$current_block")
                    echo "Current Block: $block_decimal"
                fi
                
            elif [[ "$sync_status" == *"true"* ]]; then
                print_warning "⚠️ Geth is still syncing"
                
                # Get detailed sync progress
                local sync_data=$(ssh "$SERVER_HOST" "curl -s -X POST -H 'Content-Type: application/json' --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_syncing\",\"params\":[],\"id\":1}' http://localhost:8545 2>/dev/null | jq -r '.result' 2>/dev/null || echo '{}'")
                
                if [[ "$sync_data" != "{}" ]]; then
                    local current_block=$(echo "$sync_data" | jq -r '.currentBlock // 0' 2>/dev/null || echo '0')
                    local highest_block=$(echo "$sync_data" | jq -r '.highestBlock // 0' 2>/dev/null || echo '0')
                    local known_states=$(echo "$sync_data" | jq -r '.knownStates // 0' 2>/dev/null || echo '0')
                    local pulled_states=$(echo "$sync_data" | jq -r '.pulledStates // 0' 2>/dev/null || echo '0')
                    
                    if [[ "$current_block" != "0" && "$highest_block" != "0" ]]; then
                        local current_block_decimal=$(printf "%d" "$current_block")
                        local highest_block_decimal=$(printf "%d" "$highest_block")
                        local remaining_blocks=$((highest_block_decimal - current_block_decimal))
                        
                        echo "Target Block: $highest_block_decimal"
                        echo "Current Block: $current_block_decimal"
                        echo "Remaining Blocks: $remaining_blocks"
                        
                        # Calculate percentage
                        if [[ "$highest_block_decimal" -gt 0 ]]; then
                            local progress_percent=$(( (current_block_decimal * 100) / highest_block_decimal ))
                            echo "Sync Progress: ${progress_percent}%"
                        fi
                        
                        # Show state sync progress if available
                        if [[ "$known_states" != "0" && "$pulled_states" != "0" ]]; then
                            local known_states_decimal=$(printf "%d" "$known_states")
                            local pulled_states_decimal=$(printf "%d" "$pulled_states")
                            local remaining_states=$((known_states_decimal - pulled_states_decimal))
                            
                            echo "State Sync - Known: $known_states_decimal, Downloaded: $pulled_states_decimal, Remaining: $remaining_states"
                        fi
                    fi
                fi
                
            else
                print_warning "⚠️ Unknown sync status"
            fi
        else
            print_warning "⚠️ Geth RPC not accessible on port 8545"
        fi
        
        # Check JWT secret
        local jwt_size=$(ssh "$SERVER_HOST" "wc -c /jwtsecret 2>/dev/null | cut -d' ' -f1 || echo '0'")
        if [[ "$jwt_size" == "32" ]]; then
            print_success "✅ JWT secret is correct size (32 bytes)"
        else
            print_warning "⚠️ JWT secret size: $jwt_size bytes (expected 32)"
        fi
        
    else
        print_error "❌ Geth container is not running"
        echo "Status: $status"
    fi
    
    echo ""
}

# Function to check container resources
check_container_resources() {
    print_header "📊 Container Resources"
    echo "=========================="
    
    ssh "$SERVER_HOST" "docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}' | grep -E '($LIGHTHOUSE_CONTAINER|$GETH_CONTAINER)' || echo 'No resource data available'"
    echo ""
}

# Function to check recent logs for errors
check_recent_logs() {
    print_header "📝 Recent Logs (Last 5 lines)"
    echo "=================================="
    
    echo "Lighthouse logs:"
    get_container_logs "$LIGHTHOUSE_CONTAINER" 5 | grep -E "(ERROR|WARN|error|warn)" || echo "No errors/warnings found"
    echo ""
    
    echo "Geth logs:"
    get_container_logs "$GETH_CONTAINER" 5 | grep -E "(ERROR|WARN|error|warn)" || echo "No errors/warnings found"
    echo ""
}

# Function to check network connectivity
check_network_connectivity() {
    print_header "🌐 Network Connectivity"
    echo "============================"
    
    # Check if ports are accessible from server
    local lighthouse_port=$(ssh "$SERVER_HOST" "netstat -tlnp 2>/dev/null | grep :5052 || echo 'Port 5052 not listening'")
    local geth_port=$(ssh "$SERVER_HOST" "netstat -tlnp 2>/dev/null | grep :8545 || echo 'Port 8545 not listening'")
    
    if [[ "$lighthouse_port" != "Port 5052 not listening" ]]; then
        print_success "✅ Lighthouse listening on port 5052"
    else
        print_error "❌ Lighthouse not listening on port 5052"
    fi
    
    if [[ "$geth_port" != "Port 8545 not listening" ]]; then
        print_success "✅ Geth listening on port 8545"
    else
        print_error "❌ Geth not listening on port 8545"
    fi
    
    echo ""
}

# Function to show sync summary
show_sync_summary() {
    print_header "📊 Sync Summary"
    echo "=================="
    
    # Get lighthouse sync status
    local lighthouse_syncing=$(ssh "$SERVER_HOST" "curl -s http://localhost:5052/eth/v1/node/syncing 2>/dev/null | jq -r '.data.is_syncing // false' 2>/dev/null || echo 'unknown'")
    local geth_syncing=$(ssh "$SERVER_HOST" "curl -s -X POST -H 'Content-Type: application/json' --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_syncing\",\"params\":[],\"id\":1}' http://localhost:8545 2>/dev/null | jq -r '.result // false' 2>/dev/null || echo 'unknown'")
    
    echo "Lighthouse: $(if [[ "$lighthouse_syncing" == "false" ]]; then echo "✅ SYNCED"; elif [[ "$lighthouse_syncing" == "true" ]]; then echo "🔄 SYNCING"; else echo "❓ UNKNOWN"; fi)"
    echo "Geth:       $(if [[ "$geth_syncing" == "false" ]]; then echo "✅ SYNCED"; elif [[ "$geth_syncing" == "true" ]]; then echo "🔄 SYNCING"; else echo "❓ UNKNOWN"; fi)"
    
    # Show estimated time remaining if syncing
    if [[ "$lighthouse_syncing" == "true" ]]; then
        local lighthouse_progress=$(ssh "$SERVER_HOST" "curl -s http://localhost:5052/eth/v1/node/syncing 2>/dev/null | jq -r '.data.sync_distance // 0' 2>/dev/null || echo '0'")
        if [[ "$lighthouse_progress" != "0" ]]; then
            local progress_decimal=$(printf "%d" "$lighthouse_progress")
            echo "Lighthouse remaining: ~$progress_decimal slots"
        fi
    fi
    
    if [[ "$geth_syncing" == "true" ]]; then
        local geth_progress=$(ssh "$SERVER_HOST" "curl -s -X POST -H 'Content-Type: application/json' --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_syncing\",\"params\":[],\"id\":1}' http://localhost:8545 2>/dev/null | jq -r '.result.highestBlock // 0' 2>/dev/null || echo '0')
        local geth_current=$(ssh "$SERVER_HOST" "curl -s -X POST -H 'Content-Type: application/json' --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_syncing\",\"params\":[],\"id\":1}' http://localhost:8545 2>/dev/null | jq -r '.result.currentBlock // 0' 2>/dev/null || echo '0')
        if [[ "$geth_progress" != "0" && "$geth_current" != "0" ]]; then
            local progress_decimal=$(printf "%d" "$geth_progress")
            local current_decimal=$(printf "%d" "$geth_current")
            local remaining=$((progress_decimal - current_decimal))
            echo "Geth remaining: ~$remaining blocks"
        fi
    fi
    
    echo ""
}

# Function to show system recommendations
show_recommendations() {
    print_header "💡 Recommendations"
    echo "====================="
    
    # Check if containers are running
    local lighthouse_status=$(get_container_status "$LIGHTHOUSE_CONTAINER")
    local geth_status=$(get_container_status "$GETH_CONTAINER")
    
    if [[ "$lighthouse_status" == "Container not found" ]] || [[ "$lighthouse_status" != *"Up"* ]]; then
        print_warning "Lighthouse container is not running properly. Check docker-compose logs."
    fi
    
    if [[ "$geth_status" == "Container not found" ]] || [[ "$geth_status" != *"Up"* ]]; then
        print_warning "Geth container is not running properly. Check docker-compose logs."
    fi
    
    # Check JWT secret
    local jwt_size=$(ssh "$SERVER_HOST" "wc -c /jwtsecret 2>/dev/null | cut -d' ' -f1 || echo '0'")
    if [[ "$jwt_size" != "32" ]]; then
        print_warning "JWT secret is not the correct size. Check your JWT configuration."
    fi
    
    echo ""
}

# Main monitoring function
main_monitor() {
    echo "🔍 DEFIMON Lighthouse & Geth Sync Monitor"
    echo "=========================================="
    echo "Server: $SERVER_HOST"
    echo "Timestamp: $(date)"
    echo "Monitoring containers: $LIGHTHOUSE_CONTAINER, $GETH_CONTAINER"
    echo ""
    
    show_sync_summary
    check_lighthouse_sync
    check_geth_sync
    check_container_resources
    check_network_connectivity
    check_recent_logs
    show_recommendations
    
    echo "=========================================="
    print_success "Monitoring completed"
}

# Continuous monitoring function
continuous_monitor() {
    print_status "Starting continuous monitoring (press Ctrl+C to stop)..."
    print_status "Monitoring interval: ${MONITORING_INTERVAL} seconds"
    echo ""
    
    while true; do
        clear
        main_monitor
        print_status "Next update in ${MONITORING_INTERVAL} seconds..."
        sleep "$MONITORING_INTERVAL"
    done
}

# Help function
show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  (no args)  - Run monitoring once"
    echo "  continuous - Run continuous monitoring"
    echo "  help       - Show this help"
    echo ""
    echo "This script monitors lighthouse and geth containers on $SERVER_HOST"
    echo "Make sure you have SSH access configured for $SERVER_HOST"
}

# Main execution
case "${1:-}" in
    "continuous"|"-c")
        check_ssh_connection
        continuous_monitor
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        check_ssh_connection
        main_monitor
        ;;
esac
