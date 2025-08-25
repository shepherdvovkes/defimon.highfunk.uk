#!/bin/bash

set -e

echo "🚀 Deploying DEFIMON MVP Website to Google Cloud Platform..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="defimon-ethereum-node"
REGION="us-central1"
SERVICE_NAME="defimon-mvp-website"
IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVICE_NAME"

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

# Check if gcloud is installed and authenticated
check_gcloud() {
    print_status "Checking gcloud configuration..."
    
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "No active gcloud account found. Please run 'gcloud auth login' first."
        exit 1
    fi
    
    # Check if project is set
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
    if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
        print_warning "Current project is $CURRENT_PROJECT, switching to $PROJECT_ID..."
        gcloud config set project $PROJECT_ID
    fi
    
    print_success "gcloud configuration verified"
}

# Enable required APIs
enable_apis() {
    print_status "Enabling required Google Cloud APIs..."
    
    gcloud services enable cloudbuild.googleapis.com
    gcloud services enable run.googleapis.com
    gcloud services enable containerregistry.googleapis.com
    
    print_success "APIs enabled successfully"
}

# Build and deploy using Cloud Build
deploy_with_cloudbuild() {
    print_status "Building and deploying with Cloud Build..."
    
    # Submit build to Cloud Build
    gcloud builds submit \
        --tag $IMAGE_NAME \
        --project $PROJECT_ID \
        --region $REGION
    
    # Deploy to Cloud Run
    gcloud run deploy $SERVICE_NAME \
        --image $IMAGE_NAME \
        --region $REGION \
        --platform managed \
        --allow-unauthenticated \
        --port 3000 \
        --memory 512Mi \
        --cpu 1 \
        --max-instances 10 \
        --min-instances 0 \
        --set-env-vars NODE_ENV=production
    
    print_success "Deployment completed successfully"
}

# Get the service URL
get_service_url() {
    print_status "Getting service URL..."
    
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
        --region $REGION \
        --format="value(status.url)")
    
    print_success "Service deployed at: $SERVICE_URL"
    echo ""
    echo "🌐 Your DEFIMON MVP website is now live!"
    echo "📍 URL: $SERVICE_URL"
    echo ""
    echo "📊 To monitor your service:"
    echo "   gcloud run services describe $SERVICE_NAME --region $REGION"
    echo ""
    echo "📝 To view logs:"
    echo "   gcloud logs tail --service=$SERVICE_NAME --region=$REGION"
}

# Main deployment process
main() {
    echo "=========================================="
    echo "  DEFIMON MVP Website - GCP Deployment"
    echo "=========================================="
    echo ""
    
    # Check prerequisites
    check_gcloud
    
    # Enable APIs
    enable_apis
    
    # Deploy
    deploy_with_cloudbuild
    
    # Get service URL
    get_service_url
    
    echo "=========================================="
    print_success "Deployment completed successfully!"
    echo "=========================================="
}

# Run main function
main "$@"
