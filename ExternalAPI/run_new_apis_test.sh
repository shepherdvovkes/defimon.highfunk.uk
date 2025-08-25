#!/bin/bash

# Script to run new APIs testing
# This script sets up environment variables and runs the comprehensive API tests

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
if [ ! -f "test_new_apis.py" ]; then
    print_error "test_new_apis.py not found. Please run this script from the ExternalAPI directory."
    exit 1
fi

print_status "Setting up environment for new APIs testing..."

# Set environment variables for the new API keys
export QUICKNODE_API_KEY="QN_6a9c24b3a5fc491f88e8c24c3294ef36"
export BLAST_API_KEY="325ff3a1-dfd9-4eee-92e9-164637c78628"
export BLAST_API_URL="https://abstract-mainnet.blastapi.io/325ff3a1-dfd9-4eee-92e9-164637c78628"
export BLAST_WSS_URL="wss://abstract-mainnet.blastapi.io/325ff3a1-dfd9-4eee-92e9-164637c78628"
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

REQUIRED_PACKAGES=("requests" "websocket-client")
MISSING_PACKAGES=()

for package in "${REQUIRED_PACKAGES[@]}"; do
    if ! python3 -c "import $package" 2>/dev/null; then
        MISSING_PACKAGES+=("$package")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
    print_warning "Missing packages: ${MISSING_PACKAGES[*]}"
    print_status "Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    print_status "Installing missing packages..."
    pip install "${MISSING_PACKAGES[@]}"
    print_success "Packages installed successfully"
else
    # Check if virtual environment exists and activate it
    if [ -d "venv" ]; then
        print_status "Activating existing virtual environment..."
        source venv/bin/activate
    fi
fi

# Create timestamp for this test run
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
print_status "Starting API tests at $TIMESTAMP"

# Run the tests
print_status "Running comprehensive API tests..."
python test_new_apis.py

# Check if tests completed successfully
if [ $? -eq 0 ]; then
    print_success "API tests completed successfully!"
    
    # Look for generated files
    RESULTS_FILE=$(ls -t new_apis_test_results_*.json 2>/dev/null | head -1)
    REPORT_FILE=$(ls -t new_apis_test_report_*.txt 2>/dev/null | head -1)
    
    if [ -n "$RESULTS_FILE" ]; then
        print_success "Results saved to: $RESULTS_FILE"
    fi
    
    if [ -n "$REPORT_FILE" ]; then
        print_success "Report saved to: $REPORT_FILE"
        echo ""
        print_status "Test Report Summary:"
        echo "===================="
        tail -20 "$REPORT_FILE"
    fi
    
else
    print_error "API tests failed!"
    exit 1
fi

print_status "Test run completed at $(date)"
