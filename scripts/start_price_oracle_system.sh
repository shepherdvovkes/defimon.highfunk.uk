#!/bin/bash

# Price Oracle System Startup Script
# This script initializes and starts the complete price oracle system

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
LOG_DIR="$PROJECT_ROOT/logs"
DOCKER_COMPOSE_FILE="$PROJECT_ROOT/infrastructure/docker-compose.yml"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if port is available
port_available() {
    ! nc -z localhost "$1" 2>/dev/null
}

# Function to wait for service to be ready
wait_for_service() {
    local service_name="$1"
    local port="$2"
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for $service_name to be ready on port $port..."
    
    while [ $attempt -le $max_attempts ]; do
        if nc -z localhost "$port" 2>/dev/null; then
            print_success "$service_name is ready!"
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts - $service_name not ready yet..."
        sleep 2
        ((attempt++))
    done
    
    print_error "$service_name failed to start within expected time"
    return 1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Python 3.11+ is available
    if ! command_exists python3; then
        print_error "Python 3 is required but not installed"
        exit 1
    fi
    
    python_version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    if [[ $(echo "$python_version >= 3.11" | bc -l) -eq 0 ]]; then
        print_error "Python 3.11 or higher is required (found $python_version)"
        exit 1
    fi
    
    print_success "Python version: $python_version"
    
    # Check if pip is available
    if ! command_exists pip3; then
        print_error "pip3 is required but not installed"
        exit 1
    fi
    
    # Check if Docker is available (optional)
    if command_exists docker; then
        print_success "Docker is available"
    else
        print_warning "Docker not found - will use local services"
    fi
    
    # Check if docker-compose is available
    if command_exists docker-compose; then
        print_success "Docker Compose is available"
    else
        print_warning "Docker Compose not found - will use local services"
    fi
    
    # Check if required ports are available
    local ports=(5432 6379 9092 8000 8081 8082)
    for port in "${ports[@]}"; do
        if ! port_available "$port"; then
            print_warning "Port $port is already in use"
        fi
    done
}

# Function to setup virtual environment
setup_virtual_environment() {
    print_status "Setting up Python virtual environment..."
    
    local venv_dir="$PROJECT_ROOT/venv"
    
    if [ ! -d "$venv_dir" ]; then
        python3 -m venv "$venv_dir"
        print_success "Virtual environment created"
    else
        print_status "Virtual environment already exists"
    fi
    
    # Activate virtual environment
    source "$venv_dir/bin/activate"
    
    # Upgrade pip
    pip install --upgrade pip
    
    print_success "Virtual environment activated"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing Python dependencies..."
    
    # Install dependencies for price oracle service
    if [ -f "$PROJECT_ROOT/services/price-oracle-service/requirements.txt" ]; then
        pip install -r "$PROJECT_ROOT/services/price-oracle-service/requirements.txt"
        print_success "Price oracle service dependencies installed"
    fi
    
    # Install dependencies for price API service
    if [ -f "$PROJECT_ROOT/services/price-api-service/requirements.txt" ]; then
        pip install -r "$PROJECT_ROOT/services/price-api-service/requirements.txt"
        print_success "Price API service dependencies installed"
    fi
    
    print_success "All dependencies installed"
}

# Function to initialize database
initialize_database() {
    print_status "Initializing database..."
    
    # Check if database initialization script exists
    local init_script="$PROJECT_ROOT/scripts/init_price_oracle_db.py"
    
    if [ ! -f "$init_script" ]; then
        print_error "Database initialization script not found: $init_script"
        exit 1
    fi
    
    # Make script executable
    chmod +x "$init_script"
    
    # Run database initialization
    if python3 "$init_script"; then
        print_success "Database initialized successfully"
    else
        print_error "Database initialization failed"
        exit 1
    fi
}

# Function to start infrastructure services
start_infrastructure() {
    print_status "Starting infrastructure services..."
    
    # Check if we should use Docker
    if command_exists docker && command_exists docker-compose && [ -f "$DOCKER_COMPOSE_FILE" ]; then
        print_status "Using Docker Compose for infrastructure..."
        
        cd "$PROJECT_ROOT/infrastructure"
        
        # Start services in background
        docker-compose up -d postgres redis kafka
        
        # Wait for services to be ready
        wait_for_service "PostgreSQL" 5432
        wait_for_service "Redis" 6379
        wait_for_service "Kafka" 9092
        
        print_success "Infrastructure services started with Docker"
    else
        print_warning "Docker not available - assuming local services are running"
        print_status "Please ensure PostgreSQL, Redis, and Kafka are running locally"
    fi
}

# Function to start price oracle service
start_price_oracle_service() {
    print_status "Starting Price Oracle Service..."
    
    local service_dir="$PROJECT_ROOT/services/price-oracle-service"
    local log_file="$LOG_DIR/price_oracle_service.log"
    
    if [ ! -d "$service_dir" ]; then
        print_error "Price oracle service directory not found: $service_dir"
        exit 1
    fi
    
    # Start service in background
    cd "$service_dir"
    nohup python3 main.py > "$log_file" 2>&1 &
    local oracle_pid=$!
    
    # Save PID for later cleanup
    echo "$oracle_pid" > "$LOG_DIR/price_oracle_service.pid"
    
    # Wait for service to be ready
    wait_for_service "Price Oracle Service" 8081
    
    print_success "Price Oracle Service started (PID: $oracle_pid)"
}

# Function to start price API service
start_price_api_service() {
    print_status "Starting Price API Service..."
    
    local service_dir="$PROJECT_ROOT/services/price-api-service"
    local log_file="$LOG_DIR/price_api_service.log"
    
    if [ ! -d "$service_dir" ]; then
        print_error "Price API service directory not found: $service_dir"
        exit 1
    fi
    
    # Start service in background
    cd "$service_dir"
    nohup python3 main.py > "$log_file" 2>&1 &
    local api_pid=$!
    
    # Save PID for later cleanup
    echo "$api_pid" > "$LOG_DIR/price_api_service.pid"
    
    # Wait for service to be ready
    wait_for_service "Price API Service" 8000
    
    print_success "Price API Service started (PID: $api_pid)"
}

# Function to show system status
show_status() {
    print_status "System Status:"
    echo
    
    # Check if services are running
    if [ -f "$LOG_DIR/price_oracle_service.pid" ]; then
        local oracle_pid=$(cat "$LOG_DIR/price_oracle_service.pid")
        if kill -0 "$oracle_pid" 2>/dev/null; then
            print_success "Price Oracle Service: Running (PID: $oracle_pid)"
        else
            print_error "Price Oracle Service: Not running"
        fi
    else
        print_error "Price Oracle Service: Not started"
    fi
    
    if [ -f "$LOG_DIR/price_api_service.pid" ]; then
        local api_pid=$(cat "$LOG_DIR/price_api_service.pid")
        if kill -0 "$api_pid" 2>/dev/null; then
            print_success "Price API Service: Running (PID: $api_pid)"
        else
            print_error "Price API Service: Not running"
        fi
    else
        print_error "Price API Service: Not started"
    fi
    
    echo
    print_status "Service URLs:"
    echo "  Price API: http://localhost:8000"
    echo "  API Docs: http://localhost:8000/docs"
    echo "  Oracle Metrics: http://localhost:8081/metrics"
    echo "  API Metrics: http://localhost:8082/metrics"
    echo
    print_status "Log files:"
    echo "  Oracle Service: $LOG_DIR/price_oracle_service.log"
    echo "  API Service: $LOG_DIR/price_api_service.log"
}

# Function to cleanup on exit
cleanup() {
    print_status "Cleaning up..."
    
    # Stop services
    if [ -f "$LOG_DIR/price_oracle_service.pid" ]; then
        local oracle_pid=$(cat "$LOG_DIR/price_oracle_service.pid")
        if kill -0 "$oracle_pid" 2>/dev/null; then
            kill "$oracle_pid"
            print_status "Stopped Price Oracle Service"
        fi
        rm -f "$LOG_DIR/price_oracle_service.pid"
    fi
    
    if [ -f "$LOG_DIR/price_api_service.pid" ]; then
        local api_pid=$(cat "$LOG_DIR/price_api_service.pid")
        if kill -0 "$api_pid" 2>/dev/null; then
            kill "$api_pid"
            print_status "Stopped Price API Service"
        fi
        rm -f "$LOG_DIR/price_api_service.pid"
    fi
}

# Set up signal handlers
trap cleanup EXIT INT TERM

# Main execution
main() {
    print_status "Starting Price Oracle System..."
    echo
    
    # Check prerequisites
    check_prerequisites
    echo
    
    # Setup virtual environment
    setup_virtual_environment
    echo
    
    # Install dependencies
    install_dependencies
    echo
    
    # Start infrastructure
    start_infrastructure
    echo
    
    # Initialize database
    initialize_database
    echo
    
    # Start services
    start_price_oracle_service
    echo
    
    start_price_api_service
    echo
    
    # Show final status
    show_status
    echo
    
    print_success "Price Oracle System started successfully!"
    print_status "Press Ctrl+C to stop all services"
    
    # Keep script running
    while true; do
        sleep 10
    done
}

# Run main function
main "$@"
