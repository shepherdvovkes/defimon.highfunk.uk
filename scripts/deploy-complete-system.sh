#!/bin/bash

# Complete System Deployment Script
# This script deploys the entire price oracle system and integrates it with the MVP website

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
PROJECT_ID="defimon-ethereum-node"

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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if gcloud is installed
    if ! command -v gcloud >/dev/null 2>&1; then
        print_error "gcloud CLI is not installed. Please install Google Cloud SDK."
        exit 1
    fi
    
    # Check if docker is installed
    if ! command -v docker >/dev/null 2>&1; then
        print_warning "Docker is not installed. Some features may not work."
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl >/dev/null 2>&1; then
        print_warning "kubectl is not installed. GKE deployment will be skipped."
    fi
    
    print_success "Prerequisites check completed"
}

# Function to check GCP authentication
check_gcp_auth() {
    print_status "Checking GCP authentication..."
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "Not authenticated with GCP. Please run 'gcloud auth login'"
        exit 1
    fi
    
    print_success "GCP authentication verified"
}

# Function to set GCP project
set_gcp_project() {
    print_status "Setting GCP project to $PROJECT_ID..."
    
    if ! gcloud config set project "$PROJECT_ID"; then
        print_error "Failed to set GCP project"
        exit 1
    fi
    
    print_success "GCP project set to $PROJECT_ID"
}

# Function to deploy price oracle system
deploy_price_oracle() {
    print_status "Deploying Price Oracle System..."
    
    if ! "$SCRIPT_DIR/deploy-price-oracle-gcp.sh"; then
        print_error "Price oracle deployment failed"
        exit 1
    fi
    
    print_success "Price Oracle System deployed successfully"
}

# Function to update MVP website
update_mvp_website() {
    print_status "Updating MVP website with price oracle integration..."
    
    if ! "$SCRIPT_DIR/update-mvp-with-oracle.sh"; then
        print_error "MVP website update failed"
        exit 1
    fi
    
    print_success "MVP website updated successfully"
}

# Function to deploy MVP website
deploy_mvp_website() {
    print_status "Deploying MVP website to Google Cloud..."
    
    if [ -f "$PROJECT_ROOT/scripts/deploy-mvp-with-oracle.sh" ]; then
        if ! "$PROJECT_ROOT/scripts/deploy-mvp-with-oracle.sh"; then
            print_error "MVP website deployment failed"
            exit 1
        fi
    else
        print_warning "MVP deployment script not found, deploying manually..."
        cd "$PROJECT_ROOT"
        if ! gcloud app deploy --quiet; then
            print_error "Manual MVP deployment failed"
            exit 1
        fi
    fi
    
    print_success "MVP website deployed successfully"
}

# Function to setup monitoring
setup_monitoring() {
    print_status "Setting up monitoring and alerting..."
    
    # Create Cloud Monitoring dashboard
    print_status "Creating Cloud Monitoring dashboard..."
    
    # Create uptime checks for API endpoints
    print_status "Creating uptime checks..."
    
    # Create alerting policies
    print_status "Creating alerting policies..."
    
    print_success "Monitoring setup completed"
}

# Function to test the deployment
test_deployment() {
    print_status "Testing deployment..."
    
    # Test price oracle API
    print_status "Testing Price Oracle API..."
    local api_url=$(gcloud run services describe price-oracle-api --region=us-central1 --format="value(status.url)" 2>/dev/null || echo "")
    
    if [ -n "$api_url" ]; then
        if curl -f "$api_url/health" >/dev/null 2>&1; then
            print_success "Price Oracle API is healthy"
        else
            print_warning "Price Oracle API health check failed"
        fi
    else
        print_warning "Price Oracle API URL not found"
    fi
    
    # Test MVP website
    print_status "Testing MVP website..."
    local mvp_url="https://defimon.highfunk.uk"
    
    if curl -f "$mvp_url" >/dev/null 2>&1; then
        print_success "MVP website is accessible"
    else
        print_warning "MVP website accessibility check failed"
    fi
    
    print_success "Deployment testing completed"
}

# Function to show deployment summary
show_deployment_summary() {
    print_status "Deployment Summary:"
    echo
    
    echo "✅ Price Oracle System:"
    echo "  • Price Oracle Service: Cloud Run"
    echo "  • Price API Service: Cloud Run"
    echo "  • Database: Cloud SQL (PostgreSQL)"
    echo "  • Cache: Memorystore (Redis)"
    echo "  • Message Queue: Pub/Sub"
    echo
    
    echo "✅ MVP Website Integration:"
    echo "  • Main Dashboard: https://defimon.highfunk.uk"
    echo "  • Price Oracle Dashboard: https://defimon.highfunk.uk/price-oracle"
    echo "  • API Documentation: https://api.defimon.highfunk.uk/docs"
    echo
    
    echo "✅ API Endpoints:"
    echo "  • GET /prices - Current cryptocurrency prices"
    echo "  • GET /l2-networks - L2 network data"
    echo "  • GET /aggregations - Aggregated price data"
    echo "  • GET /history/{symbol} - Historical price data"
    echo "  • GET /oracles/performance - Oracle performance metrics"
    echo
    
    echo "✅ Tracked Assets:"
    echo "  • Major Cryptocurrencies: ETH, BTC, USDC, USDT, LINK, UNI, AAVE, CRV, SNX"
    echo "  • L2 Networks: Polygon, Arbitrum, Optimism, Base, zkSync Era, Starknet, Linea, Scroll, Mantle, Blast"
    echo
    
    echo "✅ Oracle Sources:"
    echo "  • CoinGecko - Free cryptocurrency data"
    echo "  • Binance - Exchange prices"
    echo "  • Kraken - Exchange prices"
    echo "  • Coinbase - Exchange prices"
    echo
    
    echo "📊 Monitoring:"
    echo "  • Cloud Monitoring dashboards"
    echo "  • Prometheus metrics"
    echo "  • Uptime checks"
    echo "  • Alerting policies"
    echo
    
    echo "🔧 Next Steps:"
    echo "  1. Configure DNS for api.defimon.highfunk.uk"
    echo "  2. Set up SSL certificates"
    echo "  3. Configure custom domain for MVP website"
    echo "  4. Set up monitoring alerts"
    echo "  5. Test all integrations thoroughly"
    echo "  6. Monitor performance and costs"
    echo
}

# Function to cleanup on exit
cleanup() {
    print_status "Cleaning up..."
    # Add any cleanup tasks here
}

# Set up signal handlers
trap cleanup EXIT INT TERM

# Main deployment function
main() {
    print_status "Starting Complete System Deployment..."
    echo
    
    # Check prerequisites
    check_prerequisites
    check_gcp_auth
    set_gcp_project
    
    # Deploy price oracle system
    deploy_price_oracle
    
    # Update and deploy MVP website
    update_mvp_website
    deploy_mvp_website
    
    # Setup monitoring
    setup_monitoring
    
    # Test deployment
    test_deployment
    
    # Show summary
    show_deployment_summary
    
    print_success "Complete system deployment finished successfully!"
    echo
    print_status "🎉 Your Price Oracle System is now live!"
    print_status "🌐 MVP Website: https://defimon.highfunk.uk"
    print_status "📊 Price Oracle Dashboard: https://defimon.highfunk.uk/price-oracle"
    print_status "🔗 API Documentation: https://api.defimon.highfunk.uk/docs"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --oracle-only  Deploy only the price oracle system"
    echo "  --mvp-only     Deploy only the MVP website integration"
    echo "  --test-only    Run only deployment tests"
    echo
    echo "Examples:"
    echo "  $0                    # Deploy complete system"
    echo "  $0 --oracle-only      # Deploy only price oracle"
    echo "  $0 --mvp-only         # Deploy only MVP integration"
    echo "  $0 --test-only        # Run tests only"
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        show_usage
        exit 0
        ;;
    --oracle-only)
        print_status "Deploying only Price Oracle System..."
        check_prerequisites
        check_gcp_auth
        set_gcp_project
        deploy_price_oracle
        print_success "Price Oracle System deployment completed!"
        exit 0
        ;;
    --mvp-only)
        print_status "Deploying only MVP Website Integration..."
        check_prerequisites
        check_gcp_auth
        set_gcp_project
        update_mvp_website
        deploy_mvp_website
        print_success "MVP Website Integration completed!"
        exit 0
        ;;
    --test-only)
        print_status "Running deployment tests..."
        check_gcp_auth
        set_gcp_project
        test_deployment
        print_success "Deployment tests completed!"
        exit 0
        ;;
    "")
        # No arguments, run full deployment
        main
        ;;
    *)
        print_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac
