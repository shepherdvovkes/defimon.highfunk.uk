#!/bin/bash

# ETH Price Prediction System Deployment Script
# Answers the 5 most popular ETH price questions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
API_PORT=8001
REDIS_PORT=6379

echo -e "${BLUE}=== ETH Price Prediction System Deployment ===${NC}"
echo "Script directory: $SCRIPT_DIR"
echo "Project root: $PROJECT_ROOT"
echo "API port: $API_PORT"
echo ""

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

# Function to check Python dependencies
check_python_dependencies() {
    print_status "Checking Python dependencies..."
    
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed"
        return 1
    fi
    
    # Check required packages
    required_packages=("fastapi" "uvicorn" "aiohttp" "pandas" "numpy" "redis" "structlog")
    
    for package in "${required_packages[@]}"; do
        if ! python3 -c "import $package" 2>/dev/null; then
            print_warning "Package $package is missing"
            print_status "Installing $package..."
            pip3 install "$package"
        fi
    done
    
    print_status "All required Python packages are available"
}

# Function to check Redis
check_redis() {
    print_status "Checking Redis connection..."
    
    if command -v redis-cli &> /dev/null; then
        if redis-cli ping > /dev/null 2>&1; then
            print_status "Redis is running and accessible"
            return 0
        else
            print_warning "Redis is not running"
            print_status "Starting Redis..."
            brew services start redis 2>/dev/null || true
            sleep 2
            
            if redis-cli ping > /dev/null 2>&1; then
                print_status "Redis started successfully"
                return 0
            else
                print_warning "Could not start Redis, continuing without caching"
                return 1
            fi
        fi
    else
        print_warning "Redis CLI not found, continuing without caching"
        return 1
    fi
}

# Function to run ETH price predictions
run_eth_predictions() {
    print_status "Running ETH price predictions..."
    
    cd "$SCRIPT_DIR"
    
    if [ ! -f "test_eth_predictions.py" ]; then
        print_error "Test script not found: test_eth_predictions.py"
        return 1
    fi
    
    print_status "Executing ETH price prediction test..."
    python3 test_eth_predictions.py
    
    if [ $? -eq 0 ]; then
        print_status "ETH price predictions completed successfully"
        return 0
    else
        print_error "ETH price predictions failed"
        return 1
    fi
}

# Function to start the API server
start_api_server() {
    print_status "Starting ETH Price Prediction API server..."
    
    cd "$SCRIPT_DIR"
    
    if [ ! -f "eth_price_api.py" ]; then
        print_error "API script not found: eth_price_api.py"
        return 1
    fi
    
    print_status "Starting API server on port $API_PORT..."
    print_status "API will be available at: http://localhost:$API_PORT"
    print_status "API documentation: http://localhost:$API_PORT/docs"
    
    # Start the server in the background
    python3 eth_price_api.py &
    API_PID=$!
    
    # Wait a moment for the server to start
    sleep 3
    
    # Check if server is running
    if curl -s "http://localhost:$API_PORT/health" > /dev/null 2>&1; then
        print_status "API server started successfully (PID: $API_PID)"
        echo $API_PID > /tmp/eth_price_api.pid
        return 0
    else
        print_error "API server failed to start"
        return 1
    fi
}

# Function to test API endpoints
test_api_endpoints() {
    print_status "Testing API endpoints..."
    
    local base_url="http://localhost:$API_PORT"
    
    # Test health endpoint
    print_status "Testing health endpoint..."
    if curl -s "$base_url/health" | grep -q "healthy"; then
        print_status "✓ Health endpoint working"
    else
        print_error "✗ Health endpoint failed"
        return 1
    fi
    
    # Test root endpoint
    print_status "Testing root endpoint..."
    if curl -s "$base_url/" | grep -q "ETH Price Prediction API"; then
        print_status "✓ Root endpoint working"
    else
        print_error "✗ Root endpoint failed"
        return 1
    fi
    
    # Test popular questions endpoint
    print_status "Testing popular questions endpoint..."
    if curl -s "$base_url/questions/popular" | grep -q "questions"; then
        print_status "✓ Popular questions endpoint working"
    else
        print_error "✗ Popular questions endpoint failed"
        return 1
    fi
    
    # Test all predictions endpoint
    print_status "Testing all predictions endpoint..."
    if curl -s "$base_url/predict/eth/all" | grep -q "predictions"; then
        print_status "✓ All predictions endpoint working"
    else
        print_error "✗ All predictions endpoint failed"
        return 1
    fi
    
    print_status "All API endpoints tested successfully"
}

# Function to display API usage
display_api_usage() {
    echo ""
    echo -e "${BLUE}=== ETH Price Prediction API Usage ===${NC}"
    echo ""
    echo "API Base URL: http://localhost:$API_PORT"
    echo ""
    echo "Available endpoints:"
    echo "  GET  /                    - API information"
    echo "  GET  /health              - Health check"
    echo "  GET  /questions/popular   - Get the 5 most popular ETH price questions"
    echo "  GET  /predict/eth/all     - Get predictions for all timeframes"
    echo "  POST /predict/eth/{tf}    - Predict ETH price for specific timeframe"
    echo "  GET  /analysis/eth/trends - Get detailed ETH trend analysis"
    echo ""
    echo "Example API calls:"
    echo "  curl http://localhost:$API_PORT/questions/popular"
    echo "  curl http://localhost:$API_PORT/predict/eth/all"
    echo "  curl -X POST http://localhost:$API_PORT/predict/eth/1m"
    echo ""
    echo "API Documentation: http://localhost:$API_PORT/docs"
    echo ""
}

# Function to display the 5 popular questions and answers
display_popular_questions() {
    echo ""
    echo -e "${BLUE}=== THE 5 MOST POPULAR ETH PRICE QUESTIONS ===${NC}"
    echo ""
    
    local base_url="http://localhost:$API_PORT"
    
    # Get popular questions
    if response=$(curl -s "$base_url/questions/popular" 2>/dev/null); then
        echo "1️⃣ What will be the ETH price in 1 month?"
        echo "2️⃣ What will be the ETH price in 5 months?"
        echo "3️⃣ What will be the ETH price in 6 months?"
        echo "4️⃣ What will be the ETH price in 1 year?"
        echo "5️⃣ What are the ETH price trends and predictions?"
        echo ""
        echo "Answers are available via the API at: $base_url/questions/popular"
        echo ""
        
        # Extract and display current predictions
        if all_predictions=$(curl -s "$base_url/predict/eth/all" 2>/dev/null); then
            current_price=$(echo "$all_predictions" | grep -o '"current_price":[0-9.]*' | cut -d: -f2)
            echo -e "${GREEN}Current ETH Price: \$${current_price:,.2f}${NC}"
            echo ""
            
            # Extract predictions
            predictions=$(echo "$all_predictions" | grep -A 20 '"predictions"')
            echo "Predicted Prices:"
            echo "$predictions" | grep -E '"predicted_price"|"timeframe"' | head -8
        fi
    else
        echo "Could not fetch questions from API"
    fi
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up..."
    
    # Stop API server if running
    if [ -f /tmp/eth_price_api.pid ]; then
        API_PID=$(cat /tmp/eth_price_api.pid)
        if kill -0 $API_PID 2>/dev/null; then
            print_status "Stopping API server (PID: $API_PID)..."
            kill $API_PID
        fi
        rm -f /tmp/eth_price_api.pid
    fi
    
    print_status "Cleanup completed"
}

# Main execution
main() {
    echo -e "${BLUE}Starting ETH Price Prediction System${NC}"
    echo ""
    
    # Set up cleanup on exit
    trap cleanup EXIT
    
    # Check prerequisites
    if ! check_python_dependencies; then
        print_error "Python dependencies check failed."
        exit 1
    fi
    
    check_redis
    
    # Run ETH price predictions
    if ! run_eth_predictions; then
        print_error "ETH price predictions failed."
        exit 1
    fi
    
    # Start API server
    if ! start_api_server; then
        print_error "API server failed to start."
        exit 1
    fi
    
    # Test API endpoints
    if ! test_api_endpoints; then
        print_error "API endpoint tests failed."
        exit 1
    fi
    
    # Display usage information
    display_api_usage
    
    # Display popular questions
    display_popular_questions
    
    echo ""
    echo -e "${GREEN}=== ETH Price Prediction System Deployed Successfully ===${NC}"
    echo ""
    echo "The system is now answering the 5 most popular ETH price questions:"
    echo "1. What will be the ETH price in 1 month?"
    echo "2. What will be the ETH price in 5 months?"
    echo "3. What will be the ETH price in 6 months?"
    echo "4. What will be the ETH price in 1 year?"
    echo "5. What are the ETH price trends and predictions?"
    echo ""
    echo "API is running at: http://localhost:$API_PORT"
    echo "Press Ctrl+C to stop the system"
    echo ""
    
    # Keep the script running
    while true; do
        sleep 10
        # Check if API is still running
        if ! curl -s "http://localhost:$API_PORT/health" > /dev/null 2>&1; then
            print_error "API server stopped unexpectedly"
            break
        fi
    done
}

# Run main function
main "$@"
