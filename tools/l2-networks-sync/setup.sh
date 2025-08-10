#!/bin/bash

# L2 Networks Sync Tool Setup Script
# This script sets up the L2 networks sync tool

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running or not accessible"
        print_status "Please start Docker and try again"
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check if Node.js is installed
check_node() {
    if ! command_exists node; then
        print_error "Node.js is not installed"
        print_status "Please install Node.js 18+ and try again"
        exit 1
    fi
    
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_error "Node.js version 18+ is required, found version $(node --version)"
        exit 1
    fi
    
    print_success "Node.js $(node --version) is installed"
}

# Function to check if npm is installed
check_npm() {
    if ! command_exists npm; then
        print_error "npm is not installed"
        print_status "Please install npm and try again"
        exit 1
    fi
    print_success "npm $(npm --version) is installed"
}

# Function to create .env file
create_env_file() {
    if [ ! -f .env ]; then
        print_status "Creating .env file from template..."
        cp env.example .env
        
        print_warning "Please edit .env file with your configuration:"
        echo "  - Database connection details"
        echo "  - Node RPC URLs"
        echo "  - JWT secret path"
        echo ""
        print_status "You can edit .env file now or later"
    else
        print_status ".env file already exists"
    fi
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing Node.js dependencies..."
    npm install
    
    if [ $? -eq 0 ]; then
        print_success "Dependencies installed successfully"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
}

# Function to initialize database
init_database() {
    print_status "Initializing database..."
    
    # Check if .env file exists
    if [ ! -f .env ]; then
        print_error ".env file not found. Please run setup first."
        exit 1
    fi
    
    # Load environment variables
    source .env
    
    # Check if database is accessible
    if command_exists psql; then
        print_status "Testing database connection..."
        if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" >/dev/null 2>&1; then
            print_success "Database connection successful"
        else
            print_error "Database connection failed"
            print_status "Please check your database configuration in .env file"
            exit 1
        fi
    else
        print_warning "psql not found, skipping database connection test"
    fi
    
    # Run database initialization
    print_status "Creating L2 networks table..."
    node index.js init
    
    if [ $? -eq 0 ]; then
        print_success "Database initialized successfully"
    else
        print_error "Database initialization failed"
        exit 1
    fi
}

# Function to test the tool
test_tool() {
    print_status "Testing the tool..."
    
    # Test help command
    if node index.js --help >/dev/null 2>&1; then
        print_success "Tool is working correctly"
    else
        print_error "Tool test failed"
        exit 1
    fi
    
    # Test status command
    print_status "Checking tool status..."
    node index.js status
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help              Show this help message"
    echo "  --check-only        Only check prerequisites"
    echo "  --no-deps           Skip dependency installation"
    echo "  --no-init           Skip database initialization"
    echo "  --no-test           Skip tool testing"
    echo ""
    echo "Examples:"
    echo "  $0                  # Full setup"
    echo "  $0 --check-only     # Only check prerequisites"
    echo "  $0 --no-deps        # Skip npm install"
}

# Parse command line arguments
CHECK_ONLY=false
INSTALL_DEPS=true
INIT_DB=true
TEST_TOOL=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_usage
            exit 0
            ;;
        --check-only)
            CHECK_ONLY=true
            shift
            ;;
        --no-deps)
            INSTALL_DEPS=false
            shift
            ;;
        --no-init)
            INIT_DB=false
            shift
            ;;
        --no-test)
            TEST_TOOL=false
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main setup function
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  L2 Networks Sync Tool Setup  ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    check_docker
    check_node
    check_npm
    
    if [ "$CHECK_ONLY" = true ]; then
        print_success "All prerequisites are met!"
        exit 0
    fi
    
    # Create environment file
    create_env_file
    
    # Install dependencies
    if [ "$INSTALL_DEPS" = true ]; then
        install_dependencies
    else
        print_status "Skipping dependency installation"
    fi
    
    # Initialize database
    if [ "$INIT_DB" = true ]; then
        init_database
    else
        print_status "Skipping database initialization"
    fi
    
    # Test the tool
    if [ "$TEST_TOOL" = true ]; then
        test_tool
    else
        print_status "Skipping tool testing"
    fi
    
    echo ""
    print_success "Setup completed successfully!"
    echo ""
    print_status "Next steps:"
    echo "  1. Edit .env file with your configuration"
    echo "  2. Run 'node index.js sync' to sync networks"
    echo "  3. Run 'node index.js list' to view networks"
    echo "  4. Run 'node index.js --help' for more options"
    echo ""
    print_status "For Docker deployment, use:"
    echo "  docker-compose up -d"
    echo ""
}

# Run main function
main "$@"
