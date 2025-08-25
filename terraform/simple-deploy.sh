#!/bin/bash

# Simple DEFIMON Infrastructure Deployment Script
# This script deploys basic infrastructure using gcloud commands

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if GKE cluster exists and is running
check_gke_cluster() {
    print_status "Checking GKE cluster status..."
    
    if gcloud container clusters describe ethereum-nodes-cluster --region=europe-west1 &>/dev/null; then
        local status=$(gcloud container clusters describe ethereum-nodes-cluster --region=europe-west1 --format="value(status)")
        if [ "$status" = "RUNNING" ]; then
            print_success "GKE cluster is running"
            return 0
        else
            print_warning "GKE cluster exists but status is: $status"
            return 1
        fi
    else
        print_status "GKE cluster does not exist"
        return 1
    fi
}

# Create GKE cluster if it doesn't exist
create_gke_cluster() {
    print_status "Creating GKE cluster..."
    
    gcloud container clusters create ethereum-nodes-cluster \
        --region=europe-west1 \
        --num-nodes=1 \
        --min-nodes=1 \
        --max-nodes=3 \
        --enable-autoscaling \
        --machine-type=e2-standard-2 \
        --disk-size=50 \
        --disk-type=pd-standard \
        --enable-network-policy \
        --enable-ip-alias \
        --enable-autorepair \
        --enable-autoupgrade \
        --logging=SYSTEM,WORKLOAD \
        --monitoring=SYSTEM \
        --network=defimon-vpc \
        --subnetwork=defimon-subnet
    
    print_success "GKE cluster created"
}

# Get GKE credentials
get_gke_credentials() {
    print_status "Getting GKE credentials..."
    
    gcloud container clusters get-credentials ethereum-nodes-cluster --region=europe-west1
    
    print_success "GKE credentials obtained"
}

# Create namespace
create_namespace() {
    print_status "Creating Kubernetes namespace..."
    
    kubectl create namespace defimon --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Namespace created"
}

# Deploy basic monitoring
deploy_monitoring() {
    print_status "Deploying basic monitoring..."
    
    # Create Prometheus ConfigMap
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: defimon
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
EOF
    
    # Deploy Prometheus
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: defimon
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
      volumes:
      - name: config
        configMap:
          name: prometheus-config
EOF
    
    # Create Prometheus service
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: defimon
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
  type: LoadBalancer
EOF
    
    print_success "Monitoring deployed"
}

# Deploy Ethereum node configuration
deploy_ethereum_config() {
    print_status "Deploying Ethereum node configuration..."
    
    # Create JWT secret
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ethereum-jwt-secret
  namespace: defimon
type: Opaque
data:
  jwtsecret.raw: $(echo -n "placeholder-jwt-secret-raw-32-bytes-long" | base64)
  jwtsecret.hex: $(echo -n "placeholder-jwt-secret-hex-64-chars-long" | base64)
EOF
    
    # Create ConfigMap
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: ethereum-node-config
  namespace: defimon
data:
  geth.conf: |
    {
      "network_id": 1,
      "sync_mode": "snap",
      "cache_size": 2048,
      "max_peers": 50,
      "rpc_port": 8545,
      "ws_port": 8546,
      "p2p_port": 30303
    }
  lighthouse.conf: |
    {
      "network": "mainnet",
      "http_port": 5052,
      "p2p_port": 9000,
      "checkpoint_sync_url": "https://sync-mainnet.beaconcha.in"
    }
EOF
    
    print_success "Ethereum configuration deployed"
}

# Show cluster information
show_cluster_info() {
    print_status "Cluster information:"
    
    echo "GKE Cluster: ethereum-nodes-cluster"
    echo "Region: us-central1"
    echo "Namespace: defimon"
    
    echo ""
    echo "Services:"
    kubectl get services -n defimon
    
    echo ""
    echo "Pods:"
    kubectl get pods -n defimon
    
    echo ""
    echo "To access Prometheus:"
    echo "kubectl port-forward -n defimon svc/prometheus 9090:9090"
}

# Main function
main() {
    print_status "Starting simple DEFIMON infrastructure deployment..."
    
    if check_gke_cluster; then
        print_success "GKE cluster is already running"
    else
        create_gke_cluster
    fi
    
    get_gke_credentials
    create_namespace
    deploy_monitoring
    deploy_ethereum_config
    
    print_success "Basic infrastructure deployed successfully!"
    show_cluster_info
}

# Run main function
main "$@"
