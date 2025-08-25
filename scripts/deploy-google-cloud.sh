#!/bin/bash

# DEFIMON Google Cloud Deployment Script
# This script deploys the DEFIMON application to Google Cloud Platform

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
CONFIG_FILE="$PROJECT_ROOT/.env"

# Load configuration
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: .env file not found. Please copy env.example to .env and configure it.${NC}"
    exit 1
fi

source "$CONFIG_FILE"

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

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists gcloud; then
        print_error "Google Cloud SDK is not installed. Please install it first:"
        echo "https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    if ! command_exists kubectl; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Authenticate with Google Cloud
authenticate_gcp() {
    print_status "Authenticating with Google Cloud..."
    
    gcloud auth login
    gcloud config set project "$GOOGLE_CLOUD_PROJECT_ID"
    gcloud config set compute/region "$GOOGLE_CLOUD_REGION"
    gcloud config set compute/zone "$GOOGLE_CLOUD_ZONE"
    
    print_success "Authenticated with Google Cloud"
}

# Enable required APIs
enable_apis() {
    print_status "Enabling required Google Cloud APIs..."
    
    gcloud services enable \
        compute.googleapis.com \
        container.googleapis.com \
        cloudbuild.googleapis.com \
        cloudresourcemanager.googleapis.com \
        sqladmin.googleapis.com \
        storage-component.googleapis.com \
        pubsub.googleapis.com \
        redis.googleapis.com \
        monitoring.googleapis.com \
        logging.googleapis.com \
        secretmanager.googleapis.com \
        cloudkms.googleapis.com
    
    print_success "APIs enabled"
}

# Create service account
create_service_account() {
    print_status "Creating service account..."
    
    gcloud iam service-accounts create defimon-service \
        --display-name="DEFIMON Service Account" \
        --description="Service account for DEFIMON application"
    
    # Grant necessary roles
    gcloud projects add-iam-policy-binding "$GOOGLE_CLOUD_PROJECT_ID" \
        --member="serviceAccount:$GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL" \
        --role="roles/editor"
    
    gcloud projects add-iam-policy-binding "$GOOGLE_CLOUD_PROJECT_ID" \
        --member="serviceAccount:$GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL" \
        --role="roles/storage.admin"
    
    gcloud projects add-iam-policy-binding "$GOOGLE_CLOUD_PROJECT_ID" \
        --member="serviceAccount:$GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL" \
        --role="roles/pubsub.admin"
    
    gcloud projects add-iam-policy-binding "$GOOGLE_CLOUD_PROJECT_ID" \
        --member="serviceAccount:$GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL" \
        --role="roles/redis.admin"
    
    gcloud projects add-iam-policy-binding "$GOOGLE_CLOUD_PROJECT_ID" \
        --member="serviceAccount:$GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL" \
        --role="roles/cloudsql.admin"
    
    # Create and download service account key
    gcloud iam service-accounts keys create "$GOOGLE_CLOUD_SERVICE_ACCOUNT_KEY_FILE" \
        --iam-account="$GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL"
    
    print_success "Service account created and key downloaded"
}

# Create Cloud Storage buckets
create_storage_buckets() {
    print_status "Creating Cloud Storage buckets..."
    
    gsutil mb -l "$GOOGLE_CLOUD_REGION" "gs://$GOOGLE_CLOUD_STORAGE_BUCKET"
    gsutil mb -l "$GOOGLE_CLOUD_REGION" "gs://$GOOGLE_CLOUD_STORAGE_BACKUP_BUCKET"
    
    # Set bucket permissions
    gsutil iam ch serviceAccount:"$GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL":objectViewer "gs://$GOOGLE_CLOUD_STORAGE_BUCKET"
    gsutil iam ch serviceAccount:"$GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL":objectAdmin "gs://$GOOGLE_CLOUD_STORAGE_BACKUP_BUCKET"
    
    print_success "Storage buckets created"
}

# Create Cloud SQL instance
create_sql_instance() {
    print_status "Creating Cloud SQL instance..."
    
    gcloud sql instances create "$GOOGLE_CLOUD_SQL_INSTANCE_NAME" \
        --database-version=POSTGRES_14 \
        --tier=db-f1-micro \
        --region="$GOOGLE_CLOUD_REGION" \
        --storage-type=SSD \
        --storage-size=10GB \
        --backup-start-time="02:00" \
        --enable-backup
    
    # Create database
    gcloud sql databases create "$GOOGLE_CLOUD_SQL_DATABASE_NAME" \
        --instance="$GOOGLE_CLOUD_SQL_INSTANCE_NAME"
    
    # Create user
    gcloud sql users create "$GOOGLE_CLOUD_SQL_USER" \
        --instance="$GOOGLE_CLOUD_SQL_INSTANCE_NAME" \
        --password="$GOOGLE_CLOUD_SQL_PASSWORD"
    
    print_success "Cloud SQL instance created"
}

# Create Memorystore Redis instance
create_redis_instance() {
    print_status "Creating Memorystore Redis instance..."
    
    gcloud redis instances create "$GOOGLE_CLOUD_MEMORYSTORE_INSTANCE_NAME" \
        --size=1 \
        --region="$GOOGLE_CLOUD_REGION" \
        --redis-version=redis_6_x
    
    print_success "Redis instance created"
}

# Create Pub/Sub topics
create_pubsub_topics() {
    print_status "Creating Pub/Sub topics..."
    
    gcloud pubsub topics create "$GOOGLE_CLOUD_PUBSUB_TOPIC"
    gcloud pubsub subscriptions create "$GOOGLE_CLOUD_PUBSUB_SUBSCRIPTION" \
        --topic="$GOOGLE_CLOUD_PUBSUB_TOPIC"
    
    print_success "Pub/Sub topics created"
}

# Create GKE cluster
create_gke_cluster() {
    print_status "Creating GKE cluster..."
    
    gcloud container clusters create defimon-cluster \
        --zone="$GOOGLE_CLOUD_ZONE" \
        --num-nodes=3 \
        --machine-type=e2-standard-2 \
        --enable-autoscaling \
        --min-nodes=1 \
        --max-nodes=10 \
        --enable-autorepair \
        --enable-autoupgrade \
        --service-account="$GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL"
    
    # Get credentials
    gcloud container clusters get-credentials defimon-cluster --zone="$GOOGLE_CLOUD_ZONE"
    
    print_success "GKE cluster created"
}

# Build and push Docker images
build_and_push_images() {
    print_status "Building and pushing Docker images..."
    
    # Set up Docker to use gcloud as a credential helper
    gcloud auth configure-docker
    
    # Build and push frontend
    docker build -t "gcr.io/$GOOGLE_CLOUD_PROJECT_ID/defimon-frontend:latest" "$PROJECT_ROOT/frontend"
    docker push "gcr.io/$GOOGLE_CLOUD_PROJECT_ID/defimon-frontend:latest"
    
    # Build and push admin dashboard
    docker build -t "gcr.io/$GOOGLE_CLOUD_PROJECT_ID/defimon-admin:latest" "$PROJECT_ROOT/services/admin-dashboard"
    docker push "gcr.io/$GOOGLE_CLOUD_PROJECT_ID/defimon-admin:latest"
    
    # Build and push analytics API
    docker build -t "gcr.io/$GOOGLE_CLOUD_PROJECT_ID/defimon-analytics:latest" "$PROJECT_ROOT/services/analytics-api"
    docker push "gcr.io/$GOOGLE_CLOUD_PROJECT_ID/defimon-analytics:latest"
    
    # Build and push AI/ML service
    docker build -t "gcr.io/$GOOGLE_CLOUD_PROJECT_ID/defimon-ai:latest" "$PROJECT_ROOT/services/ai-ml-service"
    docker push "gcr.io/$GOOGLE_CLOUD_PROJECT_ID/defimon-ai:latest"
    
    print_success "Docker images built and pushed"
}

# Deploy to Kubernetes
deploy_to_kubernetes() {
    print_status "Deploying to Kubernetes..."
    
    # Create namespace
    kubectl create namespace defimon --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply static IP reservations and managed certificates
    kubectl apply -f "$PROJECT_ROOT/infrastructure/kubernetes/static-ips.yml" -n defimon
    kubectl apply -f "$PROJECT_ROOT/infrastructure/kubernetes/managed-certificates.yml" -n defimon

    # Apply secrets from secrets.env
    "$PROJECT_ROOT/scripts/apply-secrets.sh"

    # Apply Kubernetes manifests
    kubectl apply -f "$PROJECT_ROOT/infrastructure/kubernetes/" -n defimon
    
    print_success "Application deployed to Kubernetes"
}

# Setup monitoring
setup_monitoring() {
    print_status "Setting up monitoring..."
    
    # Deploy Prometheus
    kubectl apply -f "$PROJECT_ROOT/infrastructure/monitoring/prometheus.yml" -n defimon
    
    # Deploy Grafana
    kubectl apply -f "$PROJECT_ROOT/infrastructure/monitoring/grafana.yml" -n defimon
    
    print_success "Monitoring setup complete"
}

# Setup SSL certificates
setup_ssl() {
    print_status "Setting up SSL certificates..."
    
    # Create managed SSL certificate
    gcloud compute ssl-certificates create "$GOOGLE_CLOUD_SSL_CERTIFICATE_NAME" \
        --domains="$FRONTEND_DOMAIN,$ADMIN_DASHBOARD_DOMAIN,$ANALYTICS_API_DOMAIN"
    
    print_success "SSL certificates created"
}

# Main deployment function
main() {
    print_status "Starting DEFIMON Google Cloud deployment..."
    
    check_prerequisites
    authenticate_gcp
    enable_apis
    create_service_account
    create_storage_buckets
    create_sql_instance
    create_redis_instance
    create_pubsub_topics
    create_gke_cluster
    build_and_push_images
    deploy_to_kubernetes
    setup_monitoring
    setup_ssl
    
    print_success "DEFIMON deployment completed successfully!"
    print_status "Your application is now running on Google Cloud Platform"
    print_status "Frontend: https://$FRONTEND_DOMAIN"
    print_status "Admin Dashboard: https://$ADMIN_DASHBOARD_DOMAIN"
    print_status "API: https://$ANALYTICS_API_DOMAIN"
}

# Run main function
main "$@"
