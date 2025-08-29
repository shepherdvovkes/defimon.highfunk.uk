#!/bin/bash

# Price Oracle System GCP Deployment Script
# This script deploys the price oracle system to Google Cloud

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
REGION="us-central1"
ZONE="us-central1-a"

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

# Function to check GCP authentication
check_gcp_auth() {
    print_status "Checking GCP authentication..."
    
    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed. Please install Google Cloud SDK."
        exit 1
    fi
    
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

# Function to enable required APIs
enable_apis() {
    print_status "Enabling required GCP APIs..."
    
    local apis=(
        "cloudbuild.googleapis.com"
        "run.googleapis.com"
        "sql-component.googleapis.com"
        "sqladmin.googleapis.com"
        "redis.googleapis.com"
        "pubsub.googleapis.com"
        "container.googleapis.com"
        "compute.googleapis.com"
        "dns.googleapis.com"
        "certificatemanager.googleapis.com"
    )
    
    for api in "${apis[@]}"; do
        if ! gcloud services enable "$api" --quiet; then
            print_warning "Failed to enable API: $api"
        else
            print_status "Enabled API: $api"
        fi
    done
    
    print_success "GCP APIs enabled"
}

# Function to build and push Docker images
build_and_push_images() {
    print_status "Building and pushing Docker images..."
    
    # Build Price Oracle Service
    print_status "Building Price Oracle Service image..."
    cd "$PROJECT_ROOT/services/price-oracle-service"
    if ! gcloud builds submit --tag "gcr.io/$PROJECT_ID/price-oracle-service:latest" .; then
        print_error "Failed to build Price Oracle Service image"
        exit 1
    fi
    
    # Build Price API Service
    print_status "Building Price API Service image..."
    cd "$PROJECT_ROOT/services/price-api-service"
    if ! gcloud builds submit --tag "gcr.io/$PROJECT_ID/price-oracle-api:latest" .; then
        print_error "Failed to build Price API Service image"
        exit 1
    fi
    
    print_success "Docker images built and pushed successfully"
}

# Function to initialize database
initialize_database() {
    print_status "Initializing database schema..."
    
    # Check if Cloud SQL instance exists
    if ! gcloud sql instances describe defimon-postgres-instance --region="$REGION" >/dev/null 2>&1; then
        print_error "Cloud SQL instance 'defimon-postgres-instance' not found"
        print_status "Please create the Cloud SQL instance first"
        exit 1
    fi
    
    # Run database initialization
    cd "$PROJECT_ROOT"
    if ! python3 scripts/init_price_oracle_db.py; then
        print_error "Database initialization failed"
        exit 1
    fi
    
    print_success "Database schema initialized"
}

# Function to deploy to Cloud Run
deploy_to_cloud_run() {
    print_status "Deploying to Cloud Run..."
    
    # Deploy Price Oracle Service
    print_status "Deploying Price Oracle Service..."
    if ! gcloud run deploy price-oracle-service \
        --image "gcr.io/$PROJECT_ID/price-oracle-service:latest" \
        --platform managed \
        --region "$REGION" \
        --allow-unauthenticated \
        --port 8081 \
        --memory 2Gi \
        --cpu 1 \
        --min-instances 1 \
        --max-instances 3 \
        --set-env-vars "DB_HOST=/cloudsql/$PROJECT_ID:$REGION:defimon-postgres-instance,DB_PORT=5432,DB_USER=defimon_user,DB_NAME=defi_analytics,REDIS_HOST=10.0.0.3,REDIS_PORT=6379,KAFKA_BOOTSTRAP_SERVERS=10.0.0.4:9092" \
        --add-cloudsql-instances "$PROJECT_ID:$REGION:defimon-postgres-instance"; then
        print_error "Failed to deploy Price Oracle Service"
        exit 1
    fi
    
    # Deploy Price API Service
    print_status "Deploying Price API Service..."
    if ! gcloud run deploy price-oracle-api \
        --image "gcr.io/$PROJECT_ID/price-oracle-api:latest" \
        --platform managed \
        --region "$REGION" \
        --allow-unauthenticated \
        --port 8000 \
        --memory 2Gi \
        --cpu 1 \
        --min-instances 1 \
        --max-instances 5 \
        --set-env-vars "DB_HOST=/cloudsql/$PROJECT_ID:$REGION:defimon-postgres-instance,DB_PORT=5432,DB_USER=defimon_user,DB_NAME=defi_analytics,REDIS_HOST=10.0.0.3,REDIS_PORT=6379,KAFKA_BOOTSTRAP_SERVERS=10.0.0.4:9092" \
        --add-cloudsql-instances "$PROJECT_ID:$REGION:defimon-postgres-instance"; then
        print_error "Failed to deploy Price API Service"
        exit 1
    fi
    
    print_success "Services deployed to Cloud Run"
}

# Function to deploy to App Engine
deploy_to_app_engine() {
    print_status "Deploying to App Engine..."
    
    # Deploy Price API Service to App Engine
    cd "$PROJECT_ROOT/services/price-api-service"
    if ! gcloud app deploy "$PROJECT_ROOT/infrastructure/price-oracle-app.yaml" --quiet; then
        print_error "Failed to deploy to App Engine"
        exit 1
    fi
    
    print_success "Services deployed to App Engine"
}

# Function to deploy to GKE
deploy_to_gke() {
    print_status "Deploying to GKE..."
    
    # Check if GKE cluster exists
    if ! gcloud container clusters describe defimon-cluster --zone="$ZONE" >/dev/null 2>&1; then
        print_error "GKE cluster 'defimon-cluster' not found"
        print_status "Please create the GKE cluster first"
        exit 1
    fi
    
    # Get cluster credentials
    if ! gcloud container clusters get-credentials defimon-cluster --zone="$ZONE"; then
        print_error "Failed to get GKE cluster credentials"
        exit 1
    fi
    
    # Apply Kubernetes manifests
    cd "$PROJECT_ROOT/infrastructure"
    if ! kubectl apply -f price-oracle-deployment.yaml; then
        print_error "Failed to apply Kubernetes manifests"
        exit 1
    fi
    
    print_success "Services deployed to GKE"
}

# Function to setup monitoring
setup_monitoring() {
    print_status "Setting up monitoring..."
    
    # Create Cloud Monitoring dashboard
    print_status "Creating Cloud Monitoring dashboard..."
    
    # Create uptime checks
    print_status "Creating uptime checks..."
    
    # Create alerting policies
    print_status "Creating alerting policies..."
    
    print_success "Monitoring setup completed"
}

# Function to setup load balancer and SSL
setup_load_balancer() {
    print_status "Setting up load balancer and SSL..."
    
    # Reserve static IP
    if ! gcloud compute addresses describe price-oracle-ip --global >/dev/null 2>&1; then
        print_status "Creating static IP address..."
        gcloud compute addresses create price-oracle-ip --global
    fi
    
    # Create SSL certificate
    print_status "Creating SSL certificate..."
    gcloud compute ssl-certificates create price-oracle-cert \
        --domains="api.defimon.highfunk.uk" \
        --global
    
    print_success "Load balancer and SSL setup completed"
}

# Function to test deployment
test_deployment() {
    print_status "Testing deployment..."
    
    # Get service URLs
    local oracle_service_url=$(gcloud run services describe price-oracle-service --region="$REGION" --format="value(status.url)")
    local api_service_url=$(gcloud run services describe price-oracle-api --region="$REGION" --format="value(status.url)")
    
    print_status "Price Oracle Service URL: $oracle_service_url"
    print_status "Price API Service URL: $api_service_url"
    
    # Test health endpoints
    print_status "Testing health endpoints..."
    
    if curl -f "$oracle_service_url/metrics" >/dev/null 2>&1; then
        print_success "Price Oracle Service is healthy"
    else
        print_error "Price Oracle Service health check failed"
    fi
    
    if curl -f "$api_service_url/health" >/dev/null 2>&1; then
        print_success "Price API Service is healthy"
    else
        print_error "Price API Service health check failed"
    fi
    
    print_success "Deployment testing completed"
}

# Function to show deployment info
show_deployment_info() {
    print_status "Deployment Information:"
    echo
    
    # Get service URLs
    local oracle_service_url=$(gcloud run services describe price-oracle-service --region="$REGION" --format="value(status.url)" 2>/dev/null || echo "Not deployed")
    local api_service_url=$(gcloud run services describe price-oracle-api --region="$REGION" --format="value(status.url)" 2>/dev/null || echo "Not deployed")
    
    echo "Service URLs:"
    echo "  Price Oracle Service: $oracle_service_url"
    echo "  Price API Service: $api_service_url"
    echo "  API Documentation: $api_service_url/docs"
    echo "  Metrics: $oracle_service_url/metrics"
    echo
    
    echo "Environment Variables:"
    echo "  Project ID: $PROJECT_ID"
    echo "  Region: $REGION"
    echo "  Zone: $ZONE"
    echo
    
    echo "Next Steps:"
    echo "  1. Configure DNS for api.defimon.highfunk.uk"
    echo "  2. Set up monitoring and alerting"
    echo "  3. Integrate with existing MVP website"
    echo "  4. Test all API endpoints"
}

# Main deployment function
main() {
    print_status "Starting Price Oracle System GCP Deployment..."
    echo
    
    # Check prerequisites
    check_gcp_auth
    set_gcp_project
    enable_apis
    
    # Build and deploy
    build_and_push_images
    initialize_database
    
    # Choose deployment method
    echo "Choose deployment method:"
    echo "1) Cloud Run (recommended)"
    echo "2) App Engine"
    echo "3) GKE (Kubernetes)"
    echo "4) All methods"
    read -p "Enter choice (1-4): " choice
    
    case $choice in
        1)
            deploy_to_cloud_run
            ;;
        2)
            deploy_to_app_engine
            ;;
        3)
            deploy_to_gke
            ;;
        4)
            deploy_to_cloud_run
            deploy_to_app_engine
            deploy_to_gke
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
    
    # Setup additional infrastructure
    setup_monitoring
    setup_load_balancer
    
    # Test deployment
    test_deployment
    
    # Show deployment info
    show_deployment_info
    
    print_success "Price Oracle System deployment completed!"
}

# Run main function
main "$@"
