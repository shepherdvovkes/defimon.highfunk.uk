#!/bin/bash

# Script to run external APIs integration tests for analytics-api service
# This script tests the integration of new APIs in the analytics-api service

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if we're in the right directory
if [ ! -f "test_external_apis_integration.py" ]; then
    print_error "test_external_apis_integration.py not found. Please run this script from the analytics-api directory."
    exit 1
fi

print_status "Setting up environment for analytics-api integration testing..."

# Set environment variables for the new API keys
export QUICKNODE_API_KEY="QN_6a9c24b3a5fc491f88e8c24c3294ef36"
export BLAST_API_KEY="azoNgu3Cle2YBWFElUzVWNCXw-g_F31RvQjQKJmfVcg"
export COINGECKO_API_KEY="CG-32UZHngR3w1V7u2vQ76tP3Fi"
export COINCAP_API_KEY="dbdbfe12346bb92d9dac28504e5fee49ee721659429345b8a8fd8da5bab9c715"
export GITHUB_API_TOKEN="[GITHUB_TOKEN_PLACEHOLDER]"
export GITHUB_USERNAME="shepherdvovkes"

print_success "Environment variables set successfully"

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    print_error "Python3 is not installed or not in PATH"
    exit 1
fi

# Check if required packages are installed
print_status "Checking required Python packages..."

REQUIRED_PACKAGES=("requests" "fastapi" "uvicorn" "sqlalchemy" "python-dotenv")
MISSING_PACKAGES=()

for package in "${REQUIRED_PACKAGES[@]}"; do
    if ! python3 -c "import $package" 2>/dev/null; then
        MISSING_PACKAGES+=("$package")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
    print_warning "Missing packages: ${MISSING_PACKAGES[*]}"
    print_status "Installing missing packages..."
    pip3 install "${MISSING_PACKAGES[@]}"
    print_success "Packages installed successfully"
fi

# Check if analytics-api service is running
print_status "Checking if analytics-api service is running..."
if ! curl -s http://localhost:8002/health > /dev/null 2>&1; then
    print_warning "Analytics API service is not running on localhost:8002"
    print_status "Starting analytics-api service in background..."
    
    # Start the service in background
    python3 main.py &
    SERVICE_PID=$!
    
    # Wait for service to start
    print_status "Waiting for service to start..."
    sleep 10
    
    # Check if service started successfully
    if ! curl -s http://localhost:8002/health > /dev/null 2>&1; then
        print_error "Failed to start analytics-api service"
        exit 1
    fi
    
    print_success "Analytics API service started successfully (PID: $SERVICE_PID)"
    SERVICE_STARTED=true
else
    print_success "Analytics API service is already running"
    SERVICE_STARTED=false
fi

# Create timestamp for this test run
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
print_status "Starting integration tests at $TIMESTAMP"

# Run the integration tests
print_status "Running analytics-api external APIs integration tests..."
python3 test_external_apis_integration.py

# Check if tests completed successfully
if [ $? -eq 0 ]; then
    print_success "Integration tests completed successfully!"
    
    # Look for generated files
    RESULTS_FILE=$(ls -t analytics_api_integration_test_results_*.json 2>/dev/null | head -1)
    REPORT_FILE=$(ls -t analytics_api_integration_test_report_*.txt 2>/dev/null | head -1)
    
    if [ -n "$RESULTS_FILE" ]; then
        print_success "Results saved to: $RESULTS_FILE"
    fi
    
    if [ -n "$REPORT_FILE" ]; then
        print_success "Report saved to: $REPORT_FILE"
        echo ""
        print_status "Integration Test Report Summary:"
        echo "=================================="
        tail -20 "$REPORT_FILE"
    fi
    
else
    print_error "Integration tests failed!"
    exit 1
fi

# Clean up - stop service if we started it
if [ "$SERVICE_STARTED" = true ]; then
    print_status "Stopping analytics-api service..."
    kill $SERVICE_PID 2>/dev/null || true
    print_success "Service stopped"
fi

print_status "Integration test run completed at $(date)"
