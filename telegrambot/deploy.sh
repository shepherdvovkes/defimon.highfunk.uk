#!/bin/bash

# Google Cloud Monitor Telegram Bot Deployment Script
# This script automates the setup and deployment of the Telegram bot

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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Python
    if ! command_exists python3; then
        print_error "Python 3 is not installed. Please install Python 3.8+ first."
        exit 1
    fi
    
    # Check pip
    if ! command_exists pip3; then
        print_error "pip3 is not installed. Please install pip3 first."
        exit 1
    fi
    
    # Check Docker (optional)
    if command_exists docker; then
        DOCKER_AVAILABLE=true
        print_success "Docker is available"
    else
        DOCKER_AVAILABLE=false
        print_warning "Docker is not available. Will use local Python installation."
    fi
    
    # Check Docker Compose (optional)
    if command_exists docker-compose; then
        DOCKER_COMPOSE_AVAILABLE=true
        print_success "Docker Compose is available"
    else
        DOCKER_COMPOSE_AVAILABLE=false
        print_warning "Docker Compose is not available."
    fi
    
    print_success "Prerequisites check completed"
}

# Function to setup Python environment
setup_python_env() {
    print_status "Setting up Python environment..."
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        print_status "Creating virtual environment..."
        python3 -m venv venv
    fi
    
    # Activate virtual environment
    print_status "Activating virtual environment..."
    source venv/bin/activate
    
    # Upgrade pip
    print_status "Upgrading pip..."
    pip install --upgrade pip
    
    # Install requirements
    print_status "Installing Python dependencies..."
    pip install -r requirements.txt
    
    print_success "Python environment setup completed"
}

# Function to setup environment file
setup_env_file() {
    print_status "Setting up environment configuration..."
    
    if [ ! -f ".env" ]; then
        print_status "Creating .env file from template..."
        cp env.example .env
        
        print_warning "Please edit .env file with your configuration:"
        echo "  1. Set TELEGRAM_BOT_TOKEN"
        echo "  2. Set GOOGLE_CLOUD_PROJECT_ID"
        echo "  3. Optionally set ALLOWED_TELEGRAM_USERS"
        echo ""
        echo "Press Enter when you're ready to continue..."
        read -r
        
        # Check if .env file has been configured
        if grep -q "your_telegram_bot_token_here" .env; then
            print_error "Please configure your .env file before continuing."
            exit 1
        fi
        
        print_success "Environment configuration completed"
    else
        print_success "Environment file already exists"
    fi
}

# Function to check Google Cloud authentication
check_gcloud_auth() {
    print_status "Checking Google Cloud authentication..."
    
    if command_exists gcloud; then
        # Check if user is authenticated
        if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
            print_success "Google Cloud user authentication found"
            
            # Check application default credentials
            if gcloud auth application-default print-access-token >/dev/null 2>&1; then
                print_success "Application Default Credentials are set"
                return 0
            else
                print_warning "Application Default Credentials not set"
                print_status "Setting up Application Default Credentials..."
                gcloud auth application-default login
                print_success "Application Default Credentials configured"
                return 0
            fi
        else
            print_warning "No active Google Cloud authentication found"
            print_status "Please authenticate with Google Cloud..."
            gcloud auth login
            gcloud auth application-default login
            print_success "Google Cloud authentication completed"
            return 0
        fi
    else
        print_warning "Google Cloud SDK not found"
        print_status "Please ensure you have Google Cloud credentials configured:"
        echo "  1. Set GOOGLE_APPLICATION_CREDENTIALS environment variable, or"
        echo "  2. Install Google Cloud SDK and run: gcloud auth application-default login"
        echo ""
        echo "Press Enter when you're ready to continue..."
        read -r
        return 0
    fi
}

# Function to test Google Cloud connection
test_gcloud_connection() {
    print_status "Testing Google Cloud connection..."
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Test connection
    if python3 -c "
from gcloud_client import GCloudClient
try:
    client = GCloudClient()
    if client.test_connection():
        print('Connection successful')
        exit(0)
    else:
        print('Connection failed')
        exit(1)
except Exception as e:
    print(f'Error: {e}')
    exit(1)
"; then
        print_success "Google Cloud connection test passed"
        return 0
    else
        print_error "Google Cloud connection test failed"
        return 1
    fi
}

# Function to run bot locally
run_bot_local() {
    print_status "Starting bot locally..."
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Run the bot
    print_success "Bot is starting... Press Ctrl+C to stop"
    python3 bot.py
}

# Function to run bot with Docker
run_bot_docker() {
    if [ "$DOCKER_AVAILABLE" = false ]; then
        print_error "Docker is not available. Cannot run with Docker."
        return 1
    fi
    
    print_status "Starting bot with Docker..."
    
    # Build and run with Docker Compose
    if [ "$DOCKER_COMPOSE_AVAILABLE" = true ]; then
        print_status "Building and starting with Docker Compose..."
        docker-compose up --build -d
        
        print_success "Bot started with Docker Compose"
        print_status "View logs with: docker-compose logs -f"
        print_status "Stop with: docker-compose down"
    else
        print_status "Building Docker image..."
        docker build -t gcloud-telegram-bot .
        
        print_status "Starting Docker container..."
        docker run -d --name gcloud-telegram-bot \
            --env-file .env \
            --restart unless-stopped \
            gcloud-telegram-bot
        
        print_success "Bot started with Docker"
        print_status "View logs with: docker logs -f gcloud-telegram-bot"
        print_status "Stop with: docker stop gcloud-telegram-bot"
    fi
}

# Function to show deployment options
show_deployment_menu() {
    echo ""
    echo "=== Deployment Options ==="
    echo "1. Run locally with Python"
    echo "2. Run with Docker"
    echo "3. Exit"
    echo ""
    read -p "Choose an option (1-3): " choice
    
    case $choice in
        1)
            run_bot_local
            ;;
        2)
            run_bot_docker
            ;;
        3)
            print_status "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid option. Please choose 1-3."
            show_deployment_menu
            ;;
    esac
}

# Main deployment function
main() {
    echo "🚀 Google Cloud Monitor Telegram Bot Deployment"
    echo "================================================"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Setup Python environment
    setup_python_env
    
    # Setup environment file
    setup_env_file
    
    # Check Google Cloud authentication
    check_gcloud_connection
    
    # Test Google Cloud connection
    if ! test_gcloud_connection; then
        print_error "Google Cloud connection test failed. Please check your configuration."
        exit 1
    fi
    
    print_success "Setup completed successfully!"
    
    # Show deployment options
    show_deployment_menu
}

# Run main function
main "$@"
