#!/bin/bash

# DEFIMON Infrastructure Deployment Script using Terraform
# This script deploys the DEFIMON infrastructure to Google Cloud Platform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE} $1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first:"
        echo "https://www.terraform.io/downloads.html"
        exit 1
    fi
    
    if ! command -v gcloud &> /dev/null; then
        print_error "Google Cloud SDK is not installed. Please install it first:"
        echo "https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first:"
        echo "https://kubernetes.io/docs/tasks/tools/install-kubectl/"
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Function to check Terraform version
check_terraform_version() {
    print_status "Checking Terraform version..."
    
    local version=$(terraform version -json | jq -r '.terraform_version')
    local required_version="1.0.0"
    
    if [ "$(printf '%s\n' "$required_version" "$version" | sort -V | head -n1)" != "$required_version" ]; then
        print_error "Terraform version $version is too old. Required: $required_version or higher"
        exit 1
    fi
    
    print_success "Terraform version $version is compatible"
}

# Function to authenticate with Google Cloud
authenticate_gcp() {
    print_status "Authenticating with Google Cloud..."
    
    # Check if already authenticated
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_success "Already authenticated with Google Cloud"
        return 0
    fi
    
    gcloud auth login
    gcloud auth application-default login
    
    print_success "Authenticated with Google Cloud"
}

# Function to set Google Cloud project
set_gcp_project() {
    print_status "Setting Google Cloud project..."
    
    local project_id=$(grep '^project_id' terraform.tfvars | cut -d'=' -f2 | tr -d ' "')
    
    if [ -z "$project_id" ]; then
        print_error "Could not find project_id in terraform.tfvars"
        exit 1
    fi
    
    gcloud config set project "$project_id"
    print_success "Set project to $project_id"
}

# Function to create Terraform backend bucket
create_backend_bucket() {
    print_status "Creating Terraform backend bucket..."
    
    local bucket_name="defimon-terraform-state"
    local project_id=$(grep '^project_id' terraform.tfvars | cut -d'=' -f2 | tr -d ' "')
    
    # Check if bucket exists
    if gsutil ls -b "gs://$bucket_name" &>/dev/null; then
        print_success "Backend bucket $bucket_name already exists"
        return 0
    fi
    
    # Create bucket
    gsutil mb -l us-central1 "gs://$bucket_name"
    gsutil versioning set on "gs://$bucket_name"
    
    print_success "Created backend bucket $bucket_name"
}

# Function to initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    
    terraform init
    
    print_success "Terraform initialized"
}

# Function to validate Terraform configuration
validate_terraform() {
    print_status "Validating Terraform configuration..."
    
    terraform validate
    
    print_success "Terraform configuration is valid"
}

# Function to plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    
    terraform plan -out=tfplan
    
    print_success "Terraform plan created"
}

# Function to apply Terraform deployment
apply_terraform() {
    print_status "Applying Terraform deployment..."
    
    terraform apply tfplan
    
    print_success "Terraform deployment completed"
}

# Function to configure kubectl
configure_kubectl() {
    print_status "Configuring kubectl for GKE cluster..."
    
    local cluster_name=$(terraform output -raw gke_cluster_name 2>/dev/null || echo "ethereum-nodes-cluster")
    local region=$(grep '^region' terraform.tfvars | cut -d'=' -f2 | tr -d ' "')
    
    gcloud container clusters get-credentials "$cluster_name" --region="$region"
    
    print_success "kubectl configured for GKE cluster"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check GKE cluster
    kubectl cluster-info
    
    # Check nodes
    kubectl get nodes
    
    # Check namespaces
    kubectl get namespaces
    
    # Check pods in defimon namespace
    kubectl get pods -n defimon
    
    print_success "Deployment verification completed"
}

# Function to show outputs
show_outputs() {
    print_status "Infrastructure outputs:"
    
    terraform output
    
    print_success "Outputs displayed"
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up temporary files..."
    
    rm -f tfplan
    
    print_success "Cleanup completed"
}

# Main deployment function
main() {
    print_header "Starting DEFIMON Infrastructure Deployment"
    
    cd "$SCRIPT_DIR"
    
    check_prerequisites
    check_terraform_version
    authenticate_gcp
    set_gcp_project
    create_backend_bucket
    init_terraform
    validate_terraform
    plan_terraform
    
    echo
    print_warning "Review the plan above. Do you want to proceed with deployment? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        apply_terraform
        configure_kubectl
        verify_deployment
        show_outputs
        cleanup
        
        print_header "Deployment Completed Successfully!"
        print_status "Your infrastructure is now running on Google Cloud Platform"
        print_status "Next steps:"
        print_status "1. Deploy Ethereum nodes: kubectl apply -f ../infrastructure/kubernetes/"
        print_status "2. Access Grafana: kubectl port-forward -n defimon svc/grafana 3000:80"
        print_status "3. Access Prometheus: kubectl port-forward -n defimon svc/prometheus-server 9090:80"
    else
        print_warning "Deployment cancelled by user"
        cleanup
        exit 0
    fi
}

# Run main function
main "$@"
