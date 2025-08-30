#!/bin/bash

# =============================================================================
# ACALA CTHULHU DEPLOYMENT TEST SCRIPT
# Tests connectivity and functionality of Acala Cthulhu deployment
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
CTHULHU_INSTANCE_NAME="defimon-acala-cthulhu-archive"
CTHULHU_ZONE="us-central1-a"
CTHULHU_PORT=9949
CTHULHU_WS_PORT=9950
CTHULHU_PROMETHEUS_PORT=9092

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}ACALA CTHULHU TEST SUITE${NC}"
    echo -e "${PURPLE}================================${NC}"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Get instance IP
get_instance_ip() {
    INSTANCE_IP=$(gcloud compute instances describe "$CTHULHU_INSTANCE_NAME" \
        --zone "$CTHULHU_ZONE" \
        --format "value(networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null || echo "")
    
    if [ -z "$INSTANCE_IP" ]; then
        print_error "Could not get instance IP. Is the instance running?"
        return 1
    fi
    
    echo "$INSTANCE_IP"
}

# Test instance status
test_instance_status() {
    print_info "Testing instance status..."
    
    STATUS=$(gcloud compute instances describe "$CTHULHU_INSTANCE_NAME" \
        --zone "$CTHULHU_ZONE" \
        --format "value(status)" 2>/dev/null || echo "NOT_FOUND")
    
    if [ "$STATUS" = "RUNNING" ]; then
        print_success "Instance is running"
        return 0
    elif [ "$STATUS" = "NOT_FOUND" ]; then
        print_error "Instance not found. Has it been deployed?"
        return 1
    else
        print_warning "Instance status: $STATUS"
        return 1
    fi
}

# Test SSH connectivity
test_ssh_connectivity() {
    print_info "Testing SSH connectivity..."
    
    if gcloud compute ssh "$CTHULHU_INSTANCE_NAME" \
        --zone "$CTHULHU_ZONE" \
        --command "echo 'SSH test successful'" 2>/dev/null; then
        print_success "SSH connectivity working"
        return 0
    else
        print_error "SSH connectivity failed"
        return 1
    fi
}

# Test container status
test_container_status() {
    print_info "Testing container status..."
    
    CONTAINER_STATUS=$(gcloud compute ssh "$CTHULHU_INSTANCE_NAME" \
        --zone "$CTHULHU_ZONE" \
        --command "docker ps --filter name=acala-cthulhu-archive --format '{{.Status}}'" 2>/dev/null || echo "NOT_RUNNING")
    
    if [[ "$CONTAINER_STATUS" == *"Up"* ]]; then
        print_success "Acala container is running: $CONTAINER_STATUS"
        return 0
    else
        print_error "Acala container is not running: $CONTAINER_STATUS"
        return 1
    fi
}

# Test RPC endpoint
test_rpc_endpoint() {
    print_info "Testing RPC endpoint..."
    
    INSTANCE_IP=$(get_instance_ip)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Test system health
    HEALTH_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"system_health","params":[],"id":1}' \
        "http://$INSTANCE_IP:$CTHULHU_PORT" 2>/dev/null || echo "ERROR")
    
    if [[ "$HEALTH_RESPONSE" == *"result"* ]]; then
        print_success "RPC endpoint responding: $HEALTH_RESPONSE"
        return 0
    else
        print_error "RPC endpoint not responding: $HEALTH_RESPONSE"
        return 1
    fi
}

# Test sync status
test_sync_status() {
    print_info "Testing sync status..."
    
    INSTANCE_IP=$(get_instance_ip)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    SYNC_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"system_syncState","params":[],"id":1}' \
        "http://$INSTANCE_IP:$CTHULHU_PORT" 2>/dev/null || echo "ERROR")
    
    if [[ "$SYNC_RESPONSE" == *"result"* ]]; then
        print_success "Sync status available: $SYNC_RESPONSE"
        return 0
    else
        print_error "Sync status not available: $SYNC_RESPONSE"
        return 1
    fi
}

# Test Prometheus endpoint
test_prometheus_endpoint() {
    print_info "Testing Prometheus endpoint..."
    
    INSTANCE_IP=$(get_instance_ip)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    PROMETHEUS_RESPONSE=$(curl -s "http://$INSTANCE_IP:$CTHULHU_PROMETHEUS_PORT/-/healthy" 2>/dev/null || echo "ERROR")
    
    if [ "$PROMETHEUS_RESPONSE" = "OK" ]; then
        print_success "Prometheus endpoint healthy"
        return 0
    else
        print_error "Prometheus endpoint not responding: $PROMETHEUS_RESPONSE"
        return 1
    fi
}

# Test WebSocket endpoint
test_websocket_endpoint() {
    print_info "Testing WebSocket endpoint..."
    
    INSTANCE_IP=$(get_instance_ip)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Simple WebSocket connection test using curl
    WS_RESPONSE=$(curl -s -I "http://$INSTANCE_IP:$CTHULHU_WS_PORT" 2>/dev/null | head -1 || echo "ERROR")
    
    if [[ "$WS_RESPONSE" == *"HTTP"* ]]; then
        print_success "WebSocket endpoint responding: $WS_RESPONSE"
        return 0
    else
        print_error "WebSocket endpoint not responding: $WS_RESPONSE"
        return 1
    fi
}

# Test resource usage
test_resource_usage() {
    print_info "Testing resource usage..."
    
    RESOURCE_INFO=$(gcloud compute ssh "$CTHULHU_INSTANCE_NAME" \
        --zone "$CTHULHU_ZONE" \
        --command "echo '=== Disk Usage ===' && df -h / && echo '=== Memory Usage ===' && free -h && echo '=== CPU Usage ===' && top -bn1 | grep 'Cpu(s)'" 2>/dev/null || echo "ERROR")
    
    if [[ "$RESOURCE_INFO" != "ERROR" ]]; then
        print_success "Resource usage check completed"
        echo "$RESOURCE_INFO"
        return 0
    else
        print_error "Could not check resource usage"
        return 1
    fi
}

# Run comprehensive test
run_comprehensive_test() {
    print_header
    echo
    
    TESTS_PASSED=0
    TESTS_TOTAL=0
    
    # Test 1: Instance Status
    ((TESTS_TOTAL++))
    if test_instance_status; then
        ((TESTS_PASSED++))
    fi
    echo
    
    # Test 2: SSH Connectivity
    ((TESTS_TOTAL++))
    if test_ssh_connectivity; then
        ((TESTS_PASSED++))
    fi
    echo
    
    # Test 3: Container Status
    ((TESTS_TOTAL++))
    if test_container_status; then
        ((TESTS_PASSED++))
    fi
    echo
    
    # Test 4: RPC Endpoint
    ((TESTS_TOTAL++))
    if test_rpc_endpoint; then
        ((TESTS_PASSED++))
    fi
    echo
    
    # Test 5: Sync Status
    ((TESTS_TOTAL++))
    if test_sync_status; then
        ((TESTS_PASSED++))
    fi
    echo
    
    # Test 6: Prometheus Endpoint
    ((TESTS_TOTAL++))
    if test_prometheus_endpoint; then
        ((TESTS_PASSED++))
    fi
    echo
    
    # Test 7: WebSocket Endpoint
    ((TESTS_TOTAL++))
    if test_websocket_endpoint; then
        ((TESTS_PASSED++))
    fi
    echo
    
    # Test 8: Resource Usage
    ((TESTS_TOTAL++))
    if test_resource_usage; then
        ((TESTS_PASSED++))
    fi
    echo
    
    # Summary
    print_header
    print_info "Test Results: $TESTS_PASSED/$TESTS_TOTAL tests passed"
    
    if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
        print_success "All tests passed! Acala Cthulhu deployment is working correctly."
        
        # Show endpoints
        INSTANCE_IP=$(get_instance_ip)
        if [ $? -eq 0 ]; then
            echo
            print_info "Available Endpoints:"
            echo "  RPC: http://$INSTANCE_IP:$CTHULHU_PORT"
            echo "  WebSocket: ws://$INSTANCE_IP:$CTHULHU_WS_PORT"
            echo "  Prometheus: http://$INSTANCE_IP:$CTHULHU_PROMETHEUS_PORT"
        fi
    else
        print_warning "Some tests failed. Check the deployment and try again."
        print_info "Use './scripts/manage-acala-cthulhu.sh logs' to check logs"
    fi
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo
    echo "Options:"
    echo "  --comprehensive    Run all tests (default)"
    echo "  --instance        Test instance status only"
    echo "  --ssh             Test SSH connectivity only"
    echo "  --container       Test container status only"
    echo "  --rpc             Test RPC endpoint only"
    echo "  --sync            Test sync status only"
    echo "  --prometheus      Test Prometheus endpoint only"
    echo "  --websocket       Test WebSocket endpoint only"
    echo "  --resources       Test resource usage only"
    echo "  --help            Show this help message"
}

# Main function
main() {
    case "${1:---comprehensive}" in
        --comprehensive)
            run_comprehensive_test
            ;;
        --instance)
            test_instance_status
            ;;
        --ssh)
            test_ssh_connectivity
            ;;
        --container)
            test_container_status
            ;;
        --rpc)
            test_rpc_endpoint
            ;;
        --sync)
            test_sync_status
            ;;
        --prometheus)
            test_prometheus_endpoint
            ;;
        --websocket)
            test_websocket_endpoint
            ;;
        --resources)
            test_resource_usage
            ;;
        --help)
            show_usage
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
