#!/bin/bash

# DeFiMon Demo Updates Deployment Script
# This script fetches real data and deploys updated demo components

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

# Function to check if we're in the right directory
check_environment() {
    print_status "Checking environment..."
    
    if [ ! -f "README.md" ] || [ ! -d "mvp-website" ]; then
        print_error "Please run this script from the DeFiMon project root directory"
        exit 1
    fi
    
    if ! command_exists python3; then
        print_error "Python 3 is required but not installed"
        exit 1
    fi
    
    if ! command_exists pip3; then
        print_error "pip3 is required but not installed"
        exit 1
    fi
    
    print_success "Environment check passed"
}

# Function to install Python dependencies
install_dependencies() {
    print_status "Installing Python dependencies..."
    
    # Install required packages for data ingestion
    pip3 install aiohttp psycopg2-binary python-dotenv requests asyncio
    
    print_success "Dependencies installed"
}

# Function to fetch real data from external APIs
fetch_real_data() {
    print_status "Fetching real DeFi data from external APIs..."
    
    # Check if environment file exists
    if [ ! -f ".env" ]; then
        print_warning "No .env file found. Creating from example..."
        if [ -f "env.example" ]; then
            cp env.example .env
            print_warning "Please update .env with your API keys before running data ingestion"
        else
            print_error "No env.example file found. Please create .env file with required API keys"
            exit 1
        fi
    fi
    
    # Run the data ingestion script
    if [ -f "scripts/fetch_last_month_data.py" ]; then
        print_status "Running data ingestion script..."
        python3 scripts/fetch_last_month_data.py
        print_success "Data ingestion completed"
    else
        print_error "Data ingestion script not found"
        exit 1
    fi
}

# Function to build and deploy the frontend
deploy_frontend() {
    print_status "Building and deploying frontend..."
    
    cd mvp-website
    
    # Install frontend dependencies
    if [ ! -d "node_modules" ]; then
        print_status "Installing frontend dependencies..."
        npm install
    fi
    
    # Build the application
    print_status "Building the application..."
    npm run build
    
    # Check if build was successful
    if [ ! -d ".next" ]; then
        print_error "Build failed - .next directory not found"
        exit 1
    fi
    
    print_success "Frontend built successfully"
    
    # Deploy to Google Cloud (if configured)
    if command_exists gcloud; then
        print_status "Deploying to Google Cloud..."
        
        # Check if we're authenticated
        if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
            # Get the project ID
            PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
            
            if [ -n "$PROJECT_ID" ]; then
                print_status "Deploying to project: $PROJECT_ID"
                
                # Deploy to Cloud Run or App Engine
                if [ -f "app.yaml" ]; then
                    gcloud app deploy --quiet
                    print_success "Deployed to Google App Engine"
                else
                    # Try Cloud Run deployment
                    SERVICE_NAME="defimon-demo"
                    REGION="us-central1"
                    
                    gcloud run deploy $SERVICE_NAME \
                        --source . \
                        --region $REGION \
                        --allow-unauthenticated \
                        --quiet
                    
                    print_success "Deployed to Google Cloud Run"
                fi
            else
                print_warning "No Google Cloud project configured. Skipping deployment."
            fi
        else
            print_warning "Not authenticated with Google Cloud. Skipping deployment."
        fi
    else
        print_warning "Google Cloud CLI not found. Skipping deployment."
    fi
    
    cd ..
}

# Function to update database schema if needed
update_database() {
    print_status "Checking database schema..."
    
    # Check if PostgreSQL is accessible
    if command_exists psql; then
        # Try to connect to the database
        if [ -f ".env" ]; then
            source .env
            if [ -n "$POSTGRES_HOST" ] && [ -n "$POSTGRES_DB" ]; then
                print_status "Updating database schema..."
                
                # Run schema updates if needed
                if [ -f "infrastructure/init.sql" ]; then
                    print_status "Running database initialization..."
                    psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f infrastructure/init.sql
                    print_success "Database schema updated"
                fi
            else
                print_warning "Database connection details not found in .env"
            fi
        else
            print_warning "No .env file found. Skipping database updates."
        fi
    else
        print_warning "PostgreSQL client not found. Skipping database updates."
    fi
}

# Function to start local development server
start_local_server() {
    print_status "Starting local development server..."
    
    cd mvp-website
    
    # Start the development server
    print_status "Starting Next.js development server..."
    npm run dev &
    
    DEV_SERVER_PID=$!
    
    # Wait a moment for server to start
    sleep 5
    
    # Check if server is running
    if curl -s http://localhost:3000 > /dev/null; then
        print_success "Local development server started at http://localhost:3000"
        print_status "Press Ctrl+C to stop the server"
        
        # Wait for user to stop
        wait $DEV_SERVER_PID
    else
        print_error "Failed to start development server"
        kill $DEV_SERVER_PID 2>/dev/null || true
        exit 1
    fi
    
    cd ..
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --fetch-data     Fetch real data from external APIs"
    echo "  --deploy         Build and deploy to Google Cloud"
    echo "  --local          Start local development server"
    echo "  --all            Run all steps (fetch data, deploy, start local)"
    echo "  --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --fetch-data    # Only fetch real data"
    echo "  $0 --deploy        # Only deploy to Google Cloud"
    echo "  $0 --local         # Only start local server"
    echo "  $0 --all           # Run complete deployment"
}

# Main execution
main() {
    print_status "Starting DeFiMon Demo Updates Deployment"
    print_status "========================================"
    
    # Parse command line arguments
    FETCH_DATA=false
    DEPLOY=false
    LOCAL=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fetch-data)
                FETCH_DATA=true
                shift
                ;;
            --deploy)
                DEPLOY=true
                shift
                ;;
            --local)
                LOCAL=true
                shift
                ;;
            --all)
                FETCH_DATA=true
                DEPLOY=true
                LOCAL=true
                shift
                ;;
            --help)
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
    
    # If no options specified, run all
    if [ "$FETCH_DATA" = false ] && [ "$DEPLOY" = false ] && [ "$LOCAL" = false ]; then
        FETCH_DATA=true
        DEPLOY=true
        LOCAL=true
    fi
    
    # Check environment
    check_environment
    
    # Install dependencies
    install_dependencies
    
    # Fetch real data
    if [ "$FETCH_DATA" = true ]; then
        fetch_real_data
    fi
    
    # Update database
    update_database
    
    # Deploy frontend
    if [ "$DEPLOY" = true ]; then
        deploy_frontend
    fi
    
    # Start local server
    if [ "$LOCAL" = true ]; then
        start_local_server
    fi
    
    print_success "DeFiMon Demo Updates completed successfully!"
    print_status "============================================="
}

# Run main function with all arguments
main "$@"
