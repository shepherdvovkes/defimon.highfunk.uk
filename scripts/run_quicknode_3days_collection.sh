#!/bin/bash

# QuickNode 3-Day Data Collection Script
# This script runs the QuickNode data collection for the last 3 days

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Log file
LOG_FILE="$PROJECT_ROOT/quicknode_3days_collection_$(date +%Y%m%d_%H%M%S).log"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Python dependencies
check_python_dependencies() {
    print_status "Checking Python dependencies..."
    
    local missing_deps=()
    
    # Check required packages
    python3 -c "import asyncio" 2>/dev/null || missing_deps+=("asyncio")
    python3 -c "import aiohttp" 2>/dev/null || missing_deps+=("aiohttp")
    python3 -c "import asyncpg" 2>/dev/null || missing_deps+=("asyncpg")
    python3 -c "import dotenv" 2>/dev/null || missing_deps+=("python-dotenv")
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing Python dependencies: ${missing_deps[*]}"
        print_status "Installing missing dependencies..."
        pip3 install "${missing_deps[@]}"
    else
        print_status "All Python dependencies are installed"
    fi
}

# Function to check environment variables
check_environment() {
    print_status "Checking environment configuration..."
    
    # Load environment file if it exists
    if [ -f "$PROJECT_ROOT/.env" ]; then
        print_status "Loading environment from .env file"
        export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
    elif [ -f "$PROJECT_ROOT/env.example" ]; then
        print_warning "No .env file found, using env.example as reference"
        print_status "Please create a .env file with your configuration"
    fi
    
    # Check required environment variables
    local missing_vars=()
    
    if [ -z "$QUICKNODE_ENDPOINT_NAME" ]; then
        missing_vars+=("QUICKNODE_ENDPOINT_NAME")
    fi
    
    if [ -z "$QUICKNODE_TOKEN_ID" ]; then
        missing_vars+=("QUICKNODE_TOKEN_ID")
    fi
    
    if [ -z "$POSTGRES_HOST" ]; then
        missing_vars+=("POSTGRES_HOST")
    fi
    
    if [ -z "$POSTGRES_DB" ]; then
        missing_vars+=("POSTGRES_DB")
    fi
    
    if [ -z "$POSTGRES_USER" ]; then
        missing_vars+=("POSTGRES_USER")
    fi
    
    if [ -z "$POSTGRES_PASSWORD" ]; then
        missing_vars+=("POSTGRES_PASSWORD")
    fi
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        print_error "Missing environment variables: ${missing_vars[*]}"
        print_status "Please set these variables in your .env file or environment"
        return 1
    fi
    
    print_status "Environment configuration is valid"
    return 0
}

# Function to test database connection
test_database_connection() {
    print_status "Testing database connection..."
    
    if command_exists psql; then
        if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" >/dev/null 2>&1; then
            print_status "Database connection successful"
            return 0
        else
            print_error "Database connection failed"
            return 1
        fi
    else
        print_warning "psql not found, skipping database connection test"
        return 0
    fi
}

# Function to test QuickNode API connection
test_quicknode_connection() {
    print_status "Testing QuickNode API connection..."
    
    local endpoint_name="$QUICKNODE_ENDPOINT_NAME"
    local token_id="$QUICKNODE_TOKEN_ID"
    local test_url="https://${endpoint_name}.quiknode.pro/${token_id}/"
    
    # Test with curl if available
    if command_exists curl; then
        local response
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            "$test_url" 2>/dev/null)
        
        if echo "$response" | grep -q '"result"'; then
            print_status "QuickNode API connection successful"
            return 0
        else
            print_error "QuickNode API connection failed"
            return 1
        fi
    else
        print_warning "curl not found, skipping QuickNode API test"
        return 0
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -n, --networks NETWORKS    Specific networks to collect (comma-separated)"
    echo "                             Available: ethereum,polygon,arbitrum,optimism,base,bsc,avalanche"
    echo "  -b, --batch-size SIZE      Batch size for block processing (default: 200)"
    echo "  -c, --max-concurrent NUM   Maximum concurrent requests (default: 15)"
    echo "  -r, --rate-limit DELAY     Rate limit delay in seconds (default: 0.05)"
    echo "  -d, --dry-run              Show what would be done without executing"
    echo "  -t, --test-only            Run connection tests only"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Collect all networks"
    echo "  $0 -n ethereum,polygon               # Collect only Ethereum and Polygon"
    echo "  $0 -b 100 -c 10 -r 0.1               # Custom batch and rate settings"
    echo "  $0 -t                                # Test connections only"
    echo ""
}

# Function to parse command line arguments
parse_arguments() {
    NETWORKS=""
    BATCH_SIZE=""
    MAX_CONCURRENT=""
    RATE_LIMIT=""
    DRY_RUN=false
    TEST_ONLY=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--networks)
                NETWORKS="$2"
                shift 2
                ;;
            -b|--batch-size)
                BATCH_SIZE="$2"
                shift 2
                ;;
            -c|--max-concurrent)
                MAX_CONCURRENT="$2"
                shift 2
                ;;
            -r|--rate-limit)
                RATE_LIMIT="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -t|--test-only)
                TEST_ONLY=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Function to build Python command
build_python_command() {
    local cmd="python3 $SCRIPT_DIR/quicknode_3days_data_collector.py"
    
    if [ -n "$NETWORKS" ]; then
        cmd="$cmd --networks $NETWORKS"
    fi
    
    if [ -n "$BATCH_SIZE" ]; then
        cmd="$cmd --batch-size $BATCH_SIZE"
    fi
    
    if [ -n "$MAX_CONCURRENT" ]; then
        cmd="$cmd --max-concurrent $MAX_CONCURRENT"
    fi
    
    if [ -n "$RATE_LIMIT" ]; then
        cmd="$cmd --rate-limit $RATE_LIMIT"
    fi
    
    echo "$cmd"
}

# Function to run the collection
run_collection() {
    print_header "QuickNode 3-Day Data Collection"
    
    # Check dependencies
    check_python_dependencies
    
    # Check environment
    if ! check_environment; then
        exit 1
    fi
    
    # Test connections
    if ! test_database_connection; then
        exit 1
    fi
    
    if ! test_quicknode_connection; then
        exit 1
    fi
    
    if [ "$TEST_ONLY" = true ]; then
        print_status "Connection tests completed successfully"
        exit 0
    fi
    
    # Build Python command
    local python_cmd
    python_cmd=$(build_python_command)
    
    if [ "$DRY_RUN" = true ]; then
        print_status "DRY RUN - Would execute:"
        echo "$python_cmd"
        exit 0
    fi
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Run the collection
    print_status "Starting QuickNode 3-day data collection..."
    print_status "Log file: $LOG_FILE"
    
    # Execute the Python script
    if eval "$python_cmd" 2>&1 | tee "$LOG_FILE"; then
        print_status "Data collection completed successfully!"
        print_status "Check the log file for details: $LOG_FILE"
    else
        print_error "Data collection failed!"
        print_error "Check the log file for details: $LOG_FILE"
        exit 1
    fi
}

# Main execution
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Run the collection
    run_collection
}

# Run main function with all arguments
main "$@"
