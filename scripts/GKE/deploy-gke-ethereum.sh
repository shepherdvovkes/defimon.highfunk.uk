#!/bin/bash

# DEFIMON Ethereum Nodes GKE Deployment Script
# This script deploys self-scaled Ethereum nodes to Google Kubernetes Engine

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
K8S_DIR="$PROJECT_ROOT/infrastructure/kubernetes"
ETHEREUM_DIR="$PROJECT_ROOT/infrastructure/ethereum-node"

# Load GCP configuration
if [ -f "$PROJECT_ROOT/gcp.env" ]; then
    source "$PROJECT_ROOT/gcp.env"
else
    print_error "gcp.env file not found. Please configure GCP settings first."
    exit 1
fi

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
    
    if ! command -v gcloud &> /dev/null; then
        print_error "Google Cloud SDK is not installed. Please install it first."
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    if ! command -v openssl &> /dev/null; then
        print_error "openssl is not installed. Please install it first."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Function to authenticate with GCP
authenticate_gcp() {
    print_status "Authenticating with Google Cloud..."
    
    gcloud auth login
    gcloud config set project "$GOOGLE_CLOUD_PROJECT_ID"
    gcloud config set compute/region "$GOOGLE_CLOUD_REGION"
    gcloud config set compute/zone "$GOOGLE_CLOUD_ZONE"
    
    print_success "Authenticated with Google Cloud"
}

# Function to create GKE cluster
create_gke_cluster() {
    print_status "Creating GKE cluster for Ethereum nodes..."
    
    # Check if cluster already exists
    if gcloud container clusters describe ethereum-nodes-cluster --region="$GOOGLE_CLOUD_REGION" &>/dev/null; then
        print_warning "Cluster 'ethereum-nodes-cluster' already exists. Skipping creation."
        return 0
    fi
    
    gcloud container clusters create ethereum-nodes-cluster \
        --region="$GOOGLE_CLOUD_REGION" \
        --num-nodes=1 \
        --min-nodes=1 \
        --max-nodes=5 \
        --enable-autoscaling \
        --machine-type=e2-standard-4 \
        --disk-size=100 \
        --disk-type=pd-ssd \
        --enable-network-policy \
        --enable-ip-alias \
        --enable-autorepair \
        --enable-autoupgrade \
        --enable-stackdriver-kubernetes \
        --enable-vertical-pod-autoscaling \
        --enable-horizontal-pod-autoscaling \
        --addons=HttpLoadBalancing,HorizontalPodAutoscaling,VerticalPodAutoscaling \
        --workload-pool="$GOOGLE_CLOUD_PROJECT_ID.svc.id.goog"
    
    print_success "GKE cluster created successfully"
}

# Function to create node pool for Ethereum nodes
create_ethereum_node_pool() {
    print_status "Creating dedicated node pool for Ethereum nodes..."
    
    # Check if node pool already exists
    if gcloud container node-pools describe ethereum-pool --cluster=ethereum-nodes-cluster --region="$GOOGLE_CLOUD_REGION" &>/dev/null; then
        print_warning "Node pool 'ethereum-pool' already exists. Skipping creation."
        return 0
    fi
    
    gcloud container node-pools create ethereum-pool \
        --cluster=ethereum-nodes-cluster \
        --region="$GOOGLE_CLOUD_REGION" \
        --num-nodes=1 \
        --min-nodes=1 \
        --max-nodes=3 \
        --enable-autoscaling \
        --machine-type=e2-standard-8 \
        --disk-size=200 \
        --disk-type=pd-ssd \
        --node-labels=ethereum-node=true,pool=ethereum \
        --node-taints=ethereum-node=true:NoSchedule \
        --enable-autorepair \
        --enable-autoupgrade
    
    print_success "Ethereum node pool created successfully"
}

# Function to get cluster credentials
get_cluster_credentials() {
    print_status "Getting GKE cluster credentials..."
    
    gcloud container clusters get-credentials ethereum-nodes-cluster --region="$GOOGLE_CLOUD_REGION"
    
    print_success "Cluster credentials obtained"
}

# Function to create JWT secrets
create_jwt_secrets() {
    print_status "Creating JWT secrets for Ethereum nodes..."
    
    # Check if JWT files exist
    if [ ! -f "$ETHEREUM_DIR/jwtsecret.raw" ] || [ ! -f "$ETHEREUM_DIR/jwtsecret.hex" ]; then
        print_error "JWT files not found. Please run ./scripts/generate-jwt-secrets.sh first."
        exit 1
    fi
    
    # Create base64 encoded secrets
    local geth_jwt=$(base64 -w 0 < "$ETHEREUM_DIR/jwtsecret.raw")
    local lighthouse_jwt=$(base64 -w 0 < "$ETHEREUM_DIR/jwtsecret.hex")
    
    # Create Kubernetes secret
    cat > /tmp/ethereum-jwt-secret.yml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: ethereum-jwt-secret
  namespace: defimon
  labels:
    app: ethereum-node
type: Opaque
data:
  jwtsecret.raw: $geth_jwt
  jwtsecret.hex: $lighthouse_jwt
EOF
    
    kubectl apply -f /tmp/ethereum-jwt-secret.yml
    rm -f /tmp/ethereum-jwt-secret.yml
    
    print_success "JWT secrets created in Kubernetes"
}

# Function to deploy Ethereum nodes
deploy_ethereum_nodes() {
    print_status "Deploying Ethereum nodes to GKE..."
    
    # Apply namespace
    kubectl apply -f "$K8S_DIR/namespace.yml"
    
    # Apply storage
    kubectl apply -f "$K8S_DIR/ethereum-node-storage.yml"
    
    # Apply deployments
    kubectl apply -f "$K8S_DIR/ethereum-node-deployment.yml"
    
    # Apply services
    kubectl apply -f "$K8S_DIR/ethereum-node-services.yml"
    
    # Apply autoscaling
    kubectl apply -f "$K8S_DIR/ethereum-node-autoscaling.yml"
    
    # Apply monitoring
    kubectl apply -f "$K8S_DIR/ethereum-node-monitoring.yml"
    
    print_success "Ethereum nodes deployed to GKE"
}

# Function to wait for deployment
wait_for_deployment() {
    print_status "Waiting for Ethereum nodes to be ready..."
    
    # Wait for Geth
    kubectl wait --for=condition=available --timeout=600s deployment/ethereum-geth -n defimon
    
    # Wait for Lighthouse
    kubectl wait --for=condition=available --timeout=600s deployment/ethereum-lighthouse -n defimon
    
    # Wait for monitoring
    kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n defimon
    kubectl wait --for=condition=available --timeout=300s deployment/grafana -n defimon
    
    print_success "All deployments are ready"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying Ethereum nodes deployment..."
    
    echo "=== Pod Status ==="
    kubectl get pods -n defimon -o wide
    
    echo ""
    echo "=== Services ==="
    kubectl get services -n defimon
    
    echo ""
    echo "=== PersistentVolumeClaims ==="
    kubectl get pvc -n defimon
    
    echo ""
    echo "=== HorizontalPodAutoscalers ==="
    kubectl get hpa -n defimon
    
    echo ""
    echo "=== VerticalPodAutoscalers ==="
    kubectl get vpa -n defimon
    
    print_success "Deployment verification completed"
}

# Function to show access information
show_access_info() {
    print_status "Ethereum Nodes Access Information:"
    echo "========================================="
    echo ""
    echo "GKE Cluster: ethereum-nodes-cluster"
    echo "Region: $GOOGLE_CLOUD_REGION"
    echo "Project: $GOOGLE_CLOUD_PROJECT_ID"
    echo ""
    echo "Access Commands:"
    echo "  kubectl get pods -n defimon"
    echo "  kubectl logs -f deployment/ethereum-geth -n defimon"
    echo "  kubectl logs -f deployment/ethereum-lighthouse -n defimon"
    echo ""
    echo "Monitoring:"
    echo "  Prometheus: kubectl port-forward svc/prometheus-service 9090:9090 -n defimon"
    echo "  Grafana: kubectl port-forward svc/grafana-service 3000:3000 -n defimon"
    echo ""
    echo "External Access:"
    echo "  kubectl get service ethereum-node-external -n defimon"
    echo ""
    print_success "Ethereum nodes are now running on GKE with auto-scaling!"
}

# Main function
main() {
    print_status "Starting Ethereum nodes deployment to Google Kubernetes Engine..."
    
    # Check prerequisites
    check_prerequisites
    
    # Authenticate with GCP
    authenticate_gcp
    
    # Create GKE cluster
    create_gke_cluster
    
    # Create node pool
    create_ethereum_node_pool
    
    # Get cluster credentials
    get_cluster_credentials
    
    # Create JWT secrets
    create_jwt_secrets
    
    # Deploy Ethereum nodes
    deploy_ethereum_nodes
    
    # Wait for deployment
    wait_for_deployment
    
    # Verify deployment
    verify_deployment
    
    # Show access information
    show_access_info
}

# Run main function
main "$@"
