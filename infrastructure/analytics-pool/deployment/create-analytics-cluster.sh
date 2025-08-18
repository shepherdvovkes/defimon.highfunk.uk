#!/bin/bash

# DEFIMON Analytics Pool - Hetzner Cloud Cluster Creation Script
# Этот скрипт создает Kubernetes кластер на Hetzner Cloud для аналитических сервисов

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")/../.."
K8S_DIR="$PROJECT_ROOT/infrastructure/analytics-pool/kubernetes"

# Load configuration
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
else
    echo -e "${YELLOW}Warning: .env file not found. Using default values.${NC}"
fi

# Default values
HETZNER_API_TOKEN=${HETZNER_API_TOKEN:-""}
CLUSTER_NAME=${CLUSTER_NAME:-"defimon-analytics"}
CLUSTER_REGION=${CLUSTER_REGION:-"nbg1"}
CLUSTER_VERSION=${CLUSTER_VERSION:-"1.28"}
NODE_POOL_NAME=${NODE_POOL_NAME:-"analytics-pool"}
NODE_COUNT=${NODE_COUNT:-3}
MACHINE_TYPE=${MACHINE_TYPE:-"cx31"}

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
    
    if ! command -v hcloud &> /dev/null; then
        print_error "Hetzner Cloud CLI is not installed. Please install it first:"
        echo "https://github.com/hetznercloud/cli"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    if [ -z "$HETZNER_API_TOKEN" ]; then
        print_error "HETZNER_API_TOKEN is not set. Please set it in .env file or export it."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Function to authenticate with Hetzner Cloud
authenticate_hetzner() {
    print_status "Authenticating with Hetzner Cloud..."
    
    export HCLOUD_TOKEN="$HETZNER_API_TOKEN"
    
    # Test authentication
    if ! hcloud context list &>/dev/null; then
        print_error "Failed to authenticate with Hetzner Cloud. Please check your API token."
        exit 1
    fi
    
    print_success "Authenticated with Hetzner Cloud"
}

# Function to create Kubernetes cluster
create_kubernetes_cluster() {
    print_status "Creating Kubernetes cluster '$CLUSTER_NAME' in region '$CLUSTER_REGION'..."
    
    # Check if cluster already exists
    if hcloud k8s cluster list | grep -q "$CLUSTER_NAME"; then
        print_warning "Cluster '$CLUSTER_NAME' already exists. Skipping creation."
        return 0
    fi
    
    # Create cluster
    hcloud k8s cluster create \
        --name "$CLUSTER_NAME" \
        --region "$CLUSTER_REGION" \
        --version "$CLUSTER_VERSION" \
        --ssh-key "$(hcloud ssh-key list -o columns=name,id | head -2 | tail -1 | awk '{print $2}')" \
        --network "$(hcloud network list -o columns=name,id | head -2 | tail -1 | awk '{print $2}')" \
        --subnet "$(hcloud network list -o columns=name,id | head -2 | tail -1 | awk '{print $2}')/24"
    
    print_success "Kubernetes cluster created"
}

# Function to create node pool
create_node_pool() {
    print_status "Creating node pool '$NODE_POOL_NAME'..."
    
    # Check if node pool already exists
    if hcloud k8s node-pool list --cluster "$CLUSTER_NAME" | grep -q "$NODE_POOL_NAME"; then
        print_warning "Node pool '$NODE_POOL_NAME' already exists. Skipping creation."
        return 0
    fi
    
    # Create node pool
    hcloud k8s node-pool create \
        --cluster "$CLUSTER_NAME" \
        --name "$NODE_POOL_NAME" \
        --count "$NODE_COUNT" \
        --type "$MACHINE_TYPE" \
        --location "$CLUSTER_REGION"
    
    print_success "Node pool created"
}

# Function to configure kubectl
configure_kubectl() {
    print_status "Configuring kubectl for cluster '$CLUSTER_NAME'..."
    
    # Download kubeconfig
    hcloud k8s kubeconfig save "$CLUSTER_NAME"
    
    # Set context
    kubectl config use-context "$CLUSTER_NAME"
    
    print_success "kubectl configured"
}

# Function to install required components
install_components() {
    print_status "Installing required components..."
    
    # Install NGINX Ingress Controller
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
    
    # Install cert-manager for SSL certificates
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
    
    # Wait for components to be ready
    print_status "Waiting for components to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx --timeout=300s
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager -n cert-manager --timeout=300s
    
    print_success "Components installed"
}

# Function to create cluster issuer for Let's Encrypt
create_cluster_issuer() {
    print_status "Creating Let's Encrypt cluster issuer..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@highfunk.uk
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
    
    print_success "Cluster issuer created"
}

# Function to deploy analytics services
deploy_analytics_services() {
    print_status "Deploying analytics services..."
    
    # Create namespace
    kubectl apply -f "$K8S_DIR/namespace.yml"
    
    # Create config maps and secrets (you'll need to configure these)
    print_warning "Please configure config maps and secrets before deploying services"
    
    # Deploy services
    kubectl apply -f "$K8S_DIR/"
    
    print_success "Analytics services deployed"
}

# Main execution
main() {
    print_status "Starting DEFIMON Analytics Cluster creation on Hetzner Cloud..."
    
    check_prerequisites
    authenticate_hetzner
    create_kubernetes_cluster
    create_node_pool
    configure_kubectl
    install_components
    create_cluster_issuer
    deploy_analytics_services
    
    print_success "Analytics cluster setup completed!"
    print_status "Next steps:"
    echo "1. Configure your domain DNS to point to the cluster IP"
    echo "2. Update config maps and secrets with your configuration"
    echo "3. Monitor the deployment: kubectl get pods -n analytics"
    echo "4. Access your services at: https://analytics.highfunk.uk"
}

# Run main function
main "$@"
