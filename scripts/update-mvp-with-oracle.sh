#!/bin/bash

# Update MVP Website with Price Oracle Integration
# This script updates the MVP website to include the price oracle functionality

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
MVP_DIR="$PROJECT_ROOT/mvp-website"

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

# Function to check if directory exists
check_mvp_directory() {
    if [ ! -d "$MVP_DIR" ]; then
        print_error "MVP website directory not found: $MVP_DIR"
        exit 1
    fi
    print_success "MVP website directory found"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    cd "$MVP_DIR"
    
    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        print_error "package.json not found in MVP directory"
        exit 1
    fi
    
    # Install dependencies
    if npm install; then
        print_success "Dependencies installed successfully"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
}

# Function to build the project
build_project() {
    print_status "Building MVP website..."
    
    cd "$MVP_DIR"
    
    # Build the project
    if npm run build; then
        print_success "MVP website built successfully"
    else
        print_error "Failed to build MVP website"
        exit 1
    fi
}

# Function to test the build
test_build() {
    print_status "Testing build..."
    
    cd "$MVP_DIR"
    
    # Check if build artifacts exist
    if [ -d ".next" ]; then
        print_success "Build artifacts found"
    else
        print_error "Build artifacts not found"
        exit 1
    fi
    
    # Test if the price oracle page exists
    if [ -f "app/price-oracle/page.tsx" ]; then
        print_success "Price oracle page found"
    else
        print_error "Price oracle page not found"
        exit 1
    fi
    
    # Test if the price oracle component exists
    if [ -f "components/PriceOracleWidget.tsx" ]; then
        print_success "Price oracle component found"
    else
        print_error "Price oracle component not found"
        exit 1
    fi
}

# Function to deploy to Google Cloud
deploy_to_gcp() {
    print_status "Deploying to Google Cloud..."
    
    cd "$PROJECT_ROOT"
    
    # Check if app.yaml exists
    if [ ! -f "app.yaml" ]; then
        print_error "app.yaml not found"
        exit 1
    fi
    
    # Deploy to App Engine
    if gcloud app deploy --quiet; then
        print_success "MVP website deployed to Google Cloud"
    else
        print_error "Failed to deploy to Google Cloud"
        exit 1
    fi
}

# Function to update environment variables
update_env_variables() {
    print_status "Updating environment variables..."
    
    # Check if .env file exists
    if [ -f "$PROJECT_ROOT/.env" ]; then
        # Add price oracle API URL if not present
        if ! grep -q "PRICE_ORACLE_API_URL" "$PROJECT_ROOT/.env"; then
            echo "" >> "$PROJECT_ROOT/.env"
            echo "# Price Oracle API Configuration" >> "$PROJECT_ROOT/.env"
            echo "PRICE_ORACLE_API_URL=https://api.defimon.highfunk.uk" >> "$PROJECT_ROOT/.env"
            print_success "Added price oracle API URL to .env"
        fi
    else
        print_warning ".env file not found, creating one..."
        cat > "$PROJECT_ROOT/.env" << EOF
# Price Oracle API Configuration
PRICE_ORACLE_API_URL=https://api.defimon.highfunk.uk

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=
DB_NAME=defimon

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379

# Kafka Configuration
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
EOF
        print_success "Created .env file with price oracle configuration"
    fi
}

# Function to create deployment script
create_deployment_script() {
    print_status "Creating deployment script..."
    
    cat > "$PROJECT_ROOT/scripts/deploy-mvp-with-oracle.sh" << 'EOF'
#!/bin/bash

# Deploy MVP Website with Price Oracle Integration
# This script deploys the updated MVP website to Google Cloud

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
MVP_DIR="$PROJECT_ROOT/mvp-website"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check GCP authentication
check_gcp_auth() {
    print_status "Checking GCP authentication..."
    
    if ! command -v gcloud >/dev/null 2>&1; then
        print_error "gcloud CLI is not installed"
        exit 1
    fi
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "Not authenticated with GCP. Please run 'gcloud auth login'"
        exit 1
    fi
    
    print_success "GCP authentication verified"
}

# Function to build and deploy
deploy() {
    print_status "Building and deploying MVP website..."
    
    # Build the project
    cd "$MVP_DIR"
    if ! npm run build; then
        print_error "Build failed"
        exit 1
    fi
    
    # Deploy to Google Cloud
    cd "$PROJECT_ROOT"
    if ! gcloud app deploy --quiet; then
        print_error "Deployment failed"
        exit 1
    fi
    
    print_success "MVP website deployed successfully"
}

# Main execution
main() {
    print_status "Starting MVP website deployment with price oracle integration..."
    
    check_gcp_auth
    deploy
    
    print_success "Deployment completed!"
    print_status "Visit: https://defimon.highfunk.uk"
    print_status "Price Oracle Dashboard: https://defimon.highfunk.uk/price-oracle"
}

# Run main function
main "$@"
EOF

    chmod +x "$PROJECT_ROOT/scripts/deploy-mvp-with-oracle.sh"
    print_success "Created deployment script: scripts/deploy-mvp-with-oracle.sh"
}

# Function to show integration info
show_integration_info() {
    print_status "Price Oracle Integration Information:"
    echo
    
    echo "New Features Added:"
    echo "  ✓ Price Oracle Widget component"
    echo "  ✓ Price Oracle Dashboard page"
    echo "  ✓ Integration with main dashboard"
    echo "  ✓ Real-time price updates"
    echo "  ✓ Multi-oracle data aggregation"
    echo "  ✓ L2 network data display"
    echo
    
    echo "New Pages:"
    echo "  • /price-oracle - Full price oracle dashboard"
    echo "  • Integrated widget in main dashboard"
    echo
    
    echo "API Endpoints Used:"
    echo "  • GET /prices - Current cryptocurrency prices"
    echo "  • GET /l2-networks - L2 network data"
    echo "  • GET /aggregations - Aggregated price data"
    echo "  • GET /history/{symbol} - Historical price data"
    echo
    
    echo "Next Steps:"
    echo "  1. Deploy price oracle API to Google Cloud"
    echo "  2. Deploy updated MVP website"
    echo "  3. Test all integrations"
    echo "  4. Monitor performance and usage"
    echo
}

# Main execution
main() {
    print_status "Starting MVP website update with price oracle integration..."
    echo
    
    # Check prerequisites
    check_mvp_directory
    
    # Update environment variables
    update_env_variables
    
    # Install dependencies
    install_dependencies
    
    # Build project
    build_project
    
    # Test build
    test_build
    
    # Create deployment script
    create_deployment_script
    
    # Show integration info
    show_integration_info
    
    print_success "MVP website update completed!"
    print_status "Run 'scripts/deploy-mvp-with-oracle.sh' to deploy to Google Cloud"
}

# Run main function
main "$@"
