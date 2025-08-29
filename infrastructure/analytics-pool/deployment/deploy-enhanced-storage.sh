#!/bin/bash

# DeFi Analytics Platform - Local Storage Deployment Script
# This script deploys the tiered storage system for crypto analytics data using local NVME and USB drives

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_status() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Configuration
NAMESPACE="analytics"
STORAGE_CONFIG_NAME="defi-storage-config"
COMPRESSION_ENABLED="true"
AUTO_CLEANUP_ENABLED="true"

# Local Storage Configuration (Shrimp Server)
HOT_STORAGE_SIZE="500Gi"    # Internal NVME
WARM_STORAGE_SIZE="2Ti"     # External USB Drive

print_header "DeFi Analytics Platform - Local Storage Deployment"
echo "Timestamp: $(date)"
echo "Target Server: Shrimp (Local Domain Server)"
echo ""

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if namespace exists
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        print_error "Namespace $NAMESPACE does not exist"
        exit 1
    fi
    
    # Check if local storage classes exist
    if ! kubectl get storageclass local-nvme &> /dev/null; then
        print_warning "Storage class 'local-nvme' not found - will create"
    fi
    
    if ! kubectl get storageclass local-usb &> /dev/null; then
        print_warning "Storage class 'local-usb' not found - will create"
    fi
    
    print_success "Prerequisites check completed"
}

# Create local storage classes
create_storage_classes() {
    print_status "Creating local storage classes..."
    
    # NVME Storage Class
    cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-nvme
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Retain
EOF
    
    # USB Storage Class
    cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-usb
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Retain
EOF
    
    print_success "Local storage classes created"
}

# Create storage configuration
create_storage_config() {
    print_status "Creating storage configuration..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: $STORAGE_CONFIG_NAME
  namespace: $NAMESPACE
data:
  # Local Storage Configuration (Shrimp Server)
  hot-storage-size: "$HOT_STORAGE_SIZE"
  warm-storage-size: "$WARM_STORAGE_SIZE"
  
  # Data retention policies
  hot-data-retention: "7d"
  warm-data-retention: "30d"
  
  # Storage optimization
  compression-enabled: "$COMPRESSION_ENABLED"
  auto-cleanup-enabled: "$AUTO_CLEANUP_ENABLED"
  
  # DeFi specific configurations
  protocol-metrics-retention: "30d"
  transaction-data-retention: "30d"
  price-data-retention: "30d"
  tvl-data-retention: "30d"
EOF
    
    print_success "Storage configuration created"
}

# Create storage tiers
create_storage_tiers() {
    print_status "Creating storage tiers..."
    
    # Hot Storage (NVME)
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: defi-hot-storage
  namespace: $NAMESPACE
  labels:
    app: defi-analytics
    storage-tier: hot
    location: local-shrimp
    drive-type: nvme
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: $HOT_STORAGE_SIZE
  storageClassName: local-nvme
EOF
    
    # Warm Storage (USB)
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: defi-warm-storage
  namespace: $NAMESPACE
  labels:
    app: defi-analytics
    storage-tier: warm
    location: local-shrimp
    drive-type: usb
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: $WARM_STORAGE_SIZE
  storageClassName: local-usb
EOF
    
    print_success "Storage tiers created"
}

# Deploy storage manager service
deploy_storage_manager() {
    print_status "Deploying storage manager service..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: defi-storage-manager
  namespace: $NAMESPACE
  labels:
    app: defi-storage-manager
    pool: analytics
    location: local-shrimp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: defi-storage-manager
  template:
    metadata:
      labels:
        app: defi-storage-manager
        pool: analytics
        location: local-shrimp
    spec:
      containers:
      - name: storage-manager
        image: python:3.11-slim
        command: ["python", "/app/storage_manager.py"]
        env:
        - name: HOT_STORAGE_PATH
          value: "/data/hot"
        - name: WARM_STORAGE_PATH
          value: "/data/warm"
        - name: COMPRESSION_ENABLED
          valueFrom:
            configMapKeyRef:
              name: $STORAGE_CONFIG_NAME
              key: compression-enabled
        - name: AUTO_CLEANUP_ENABLED
          valueFrom:
            configMapKeyRef:
              name: $STORAGE_CONFIG_NAME
              key: auto-cleanup-enabled
        volumeMounts:
        - name: hot-storage
          mountPath: /data/hot
        - name: warm-storage
          mountPath: /data/warm
        - name: storage-config
          mountPath: /app/config
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
      volumes:
      - name: hot-storage
        persistentVolumeClaim:
          claimName: defi-hot-storage
      - name: warm-storage
        persistentVolumeClaim:
          claimName: defi-warm-storage
      - name: storage-config
        configMap:
          name: $STORAGE_CONFIG_NAME
EOF
    
    print_success "Storage manager service deployed"
}

# Deploy data manager service
deploy_data_manager() {
    print_status "Deploying data manager service..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: defi-data-manager
  namespace: $NAMESPACE
  labels:
    app: defi-data-manager
    pool: analytics
    location: local-shrimp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: defi-data-manager
  template:
    metadata:
      labels:
        app: defi-data-manager
        pool: analytics
        location: local-shrimp
    spec:
      containers:
      - name: data-manager
        image: python:3.11-slim
        command: ["python", "/app/data_manager.py"]
        env:
        - name: HOT_STORAGE_PATH
          value: "/data/hot"
        - name: WARM_STORAGE_PATH
          value: "/data/warm"
        - name: COMPRESSION_ENABLED
          valueFrom:
            configMapKeyRef:
              name: $STORAGE_CONFIG_NAME
              key: compression-enabled
        - name: AUTO_CLEANUP_ENABLED
          valueFrom:
            configMapKeyRef:
              name: $STORAGE_CONFIG_NAME
              key: auto-cleanup-enabled
        volumeMounts:
        - name: hot-storage
          mountPath: /data/hot
        - name: warm-storage
          mountPath: /data/warm
        - name: data-config
          mountPath: /app/config
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
      volumes:
      - name: hot-storage
        persistentVolumeClaim:
          claimName: defi-hot-storage
      - name: warm-storage
        persistentVolumeClaim:
          claimName: defi-warm-storage
      - name: data-config
        configMap:
          name: $STORAGE_CONFIG_NAME
EOF
    
    print_success "Data manager service deployed"
}

# Create services
create_services() {
    print_status "Creating services..."
    
    # Storage Manager Service
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: defi-storage-manager-service
  namespace: $NAMESPACE
spec:
  selector:
    app: defi-storage-manager
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
  type: ClusterIP
EOF
    
    # Data Manager Service
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: defi-data-manager-service
  namespace: $NAMESPACE
spec:
  selector:
    app: defi-data-manager
  ports:
  - protocol: TCP
    port: 8081
    targetPort: 8081
  type: ClusterIP
EOF
    
    print_success "Services created"
}

# Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check PVCs
    echo "Checking Persistent Volume Claims..."
    kubectl get pvc -n $NAMESPACE | grep defi-
    
    # Check pods
    echo ""
    echo "Checking pods..."
    kubectl get pods -n $NAMESPACE | grep defi-
    
    # Check services
    echo ""
    echo "Checking services..."
    kubectl get svc -n $NAMESPACE | grep defi-
    
    # Check config maps
    echo ""
    echo "Checking config maps..."
    kubectl get configmap -n $NAMESPACE | grep defi-
    
    print_success "Deployment verification completed"
}

# Setup monitoring
setup_monitoring() {
    print_status "Setting up monitoring..."
    
    # Create monitoring config
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: defi-storage-monitoring
  namespace: $NAMESPACE
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    
    scrape_configs:
    - job_name: 'defi-storage-manager'
      static_configs:
      - targets: ['defi-storage-manager-service:8080']
    
    - job_name: 'defi-data-manager'
      static_configs:
      - targets: ['defi-data-manager-service:8081']
EOF
    
    print_success "Monitoring setup completed"
}

# Main deployment function
main() {
    print_header "Starting DeFi Analytics Local Storage Deployment"
    
    check_prerequisites
    create_storage_classes
    create_storage_config
    create_storage_tiers
    deploy_storage_manager
    deploy_data_manager
    create_services
    setup_monitoring
    verify_deployment
    
    print_header "Deployment Summary"
    echo ""
    echo "✅ Local storage system deployed successfully!"
    echo ""
    echo "📊 Storage Tiers (Shrimp Server):"
    echo "   🔥 Hot Storage: $HOT_STORAGE_SIZE (Internal NVME)"
    echo "   🌡️ Warm Storage: $WARM_STORAGE_SIZE (External USB Drive)"
    echo ""
    echo "🔄 Services Deployed:"
    echo "   • Storage Manager Service"
    echo "   • Data Manager Service"
    echo "   • Local Storage Optimization"
    echo ""
    echo "📈 Total Local Storage Capacity: $((${HOT_STORAGE_SIZE%Gi} + ${WARM_STORAGE_SIZE%Ti}*1024)) Gi"
    echo ""
    echo "🔗 Monitoring:"
    echo "   • Grafana Dashboard: http://analytics.highfunk.uk:3001"
    echo "   • Storage Manager API: http://defi-storage-manager-service:8080"
    echo "   • Data Manager API: http://defi-data-manager-service:8081"
    echo ""
    echo "📋 Next Steps:"
    echo "   1. Configure data ingestion pipelines"
    echo "   2. Setup automated data migration policies"
    echo "   3. Configure storage monitoring alerts"
    echo "   4. Test data storage and retrieval"
    echo ""
    print_success "DeFi Analytics Local Storage deployment completed!"
}

# Run main function
main "$@"
