# Google Kubernetes Engine (GKE) Configuration

## 🎯 Overview

This directory contains all Kubernetes manifests and configurations for deploying self-scaled Ethereum nodes on Google Kubernetes Engine.

## 📁 File Structure

### **Core Deployments**
- **`ethereum-node-deployment.yml`** - Geth and Lighthouse deployments with proper JWT configuration
- **`ethereum-node-services.yml`** - Internal services and external LoadBalancer
- **`ethereum-node-storage.yml`** - PersistentVolumeClaims, ConfigMaps, and JWT Secrets
- **`ethereum-node-autoscaling.yml`** - HorizontalPodAutoscaler (HPA) and VerticalPodAutoscaler (VPA)
- **`ethereum-node-monitoring.yml`** - Prometheus and Grafana monitoring stack

## 🚀 Quick Deployment

### **1. Prepare JWT Secrets**
```bash
# Generate JWT secrets locally
./scripts/generate-jwt-secrets.sh

# Verify JWT setup
./scripts/verify-jwt-setup.sh
```

### **2. Deploy to GKE**
```bash
# Deploy Ethereum nodes to GKE
./scripts/GKE/deploy-gke-ethereum.sh
```

## 🔧 Configuration Details

### **Ethereum Node Deployments**
- **Geth**: Execution client with JWT authentication
- **Lighthouse**: Consensus client with JWT authentication
- **Resource Management**: CPU and memory limits with auto-scaling
- **Health Checks**: Liveness, readiness, and startup probes

### **Auto-scaling Configuration**
- **HPA**: Horizontal scaling based on CPU, memory, and RPS
- **VPA**: Vertical scaling for resource optimization
- **Node Pool**: Infrastructure auto-scaling

### **Storage Configuration**
- **Geth Data**: 2TB SSD persistent storage
- **Lighthouse Data**: 500GB SSD persistent storage
- **JWT Secrets**: Kubernetes secrets with proper permissions

### **Monitoring Stack**
- **Prometheus**: Metrics collection and storage
- **Grafana**: Dashboards and visualization
- **Custom Metrics**: Ethereum-specific monitoring

## 📊 Resource Requirements

### **Geth (Execution Client)**
- **CPU**: 2-4 cores (request/limit)
- **Memory**: 4-8GB (request/limit)
- **Storage**: 2TB SSD
- **Replicas**: 1-3 (auto-scaling)

### **Lighthouse (Consensus Client)**
- **CPU**: 1-2 cores (request/limit)
- **Memory**: 2-4GB (request/limit)
- **Storage**: 500GB SSD
- **Replicas**: 1-2 (auto-scaling)

### **Monitoring**
- **Prometheus**: 512MB-1GB RAM, 500m-1 CPU
- **Grafana**: 256MB-512MB RAM, 250m-500m CPU

## 🔐 JWT Authentication

### **Secret Management**
- **Secret Name**: `ethereum-jwt-secret`
- **Data Keys**: `jwtsecret.raw` (Geth), `jwtsecret.hex` (Lighthouse)
- **Permissions**: 0400 (read-only)
- **Mount Paths**: 
  - Geth: `/root/.ethereum/jwtsecret`
  - Lighthouse: `/root/.lighthouse/jwtsecret`

### **Volume Mounts**
- **Type**: Kubernetes Secrets
- **Mode**: Read-only
- **SubPath**: Separate JWT files for each service

## 📈 Auto-scaling Policies

### **Horizontal Pod Autoscaler**
```yaml
# Geth HPA
minReplicas: 1
maxReplicas: 3
targetCPUUtilization: 70%
targetMemoryUtilization: 80%
targetRPS: 100

# Lighthouse HPA
minReplicas: 1
maxReplicas: 2
targetCPUUtilization: 70%
targetMemoryUtilization: 80%
targetRPS: 50
```

### **Vertical Pod Autoscaler**
- **Mode**: Auto
- **CPU Range**: 100m - 8 cores
- **Memory Range**: 50Mi - 16Gi
- **Updates**: Automatic resource adjustment

## 🌐 Network Configuration

### **Services**
- **Internal Services**: ClusterIP for inter-pod communication
- **External Service**: LoadBalancer for external access
- **Ports**: HTTP (80), WebSocket (443), P2P (30303, 9000)

### **Load Balancer**
- **Type**: External (Google Cloud Load Balancer)
- **Static IP**: Configurable via annotation
- **Health Checks**: Automatic health monitoring

## 📊 Monitoring & Metrics

### **Prometheus Configuration**
- **Scrape Interval**: 15s (global), 30s (Ethereum)
- **Targets**: Geth metrics, Lighthouse metrics, Kubernetes pods
- **Storage**: 100GB SSD with 200h retention

### **Grafana Dashboards**
- **Ethereum Node Health**
- **Resource Utilization**
- **Network Performance**
- **Sync Status**

## 🚀 Deployment Process

### **Order of Operations**
1. **Namespace** - Create defimon namespace
2. **Storage** - PVCs and ConfigMaps
3. **Secrets** - JWT authentication secrets
4. **Deployments** - Geth and Lighthouse pods
5. **Services** - Internal communication
6. **Autoscaling** - HPA and VPA
7. **Monitoring** - Prometheus and Grafana

### **Verification Steps**
```bash
# Check pod status
kubectl get pods -n defimon -o wide

# Check services
kubectl get services -n defimon

# Check autoscalers
kubectl get hpa,vpa -n defimon

# Check storage
kubectl get pvc -n defimon
```

## 🛠️ Troubleshooting

### **Common Issues**

1. **JWT Authentication Failures**
   - Check secret exists: `kubectl get secret ethereum-jwt-secret -n defimon`
   - Verify secret content: `kubectl describe secret ethereum-jwt-secret -n defimon`

2. **Storage Issues**
   - Check PVC status: `kubectl get pvc -n defimon`
   - Verify storage class: `kubectl get storageclass`

3. **Auto-scaling Not Working**
   - Check HPA status: `kubectl describe hpa ethereum-geth-hpa -n defimon`
   - Verify metrics server: `kubectl get apiservice v1beta1.metrics.k8s.io`

### **Debug Commands**
```bash
# Pod logs
kubectl logs -f deployment/ethereum-geth -n defimon
kubectl logs -f deployment/ethereum-lighthouse -n defimon

# Pod description
kubectl describe pod -l app=ethereum-geth -n defimon

# Resource usage
kubectl top pods -n defimon
```

## 📚 Documentation

- **GKE Deployment Guide**: [GKE_DEPLOYMENT_README.md](../GKE_DEPLOYMENT_README.md)
- **JWT Setup Guide**: [JWT_SETUP_GUIDE.md](../../../docs/ethereum-jwt-setup/JWT_SETUP_GUIDE.md)
- **Main Documentation**: [docs/ethereum-jwt-setup/](../../../docs/ethereum-jwt-setup/)

## 🔗 Related Scripts

- **Deployment Script**: [scripts/GKE/deploy-gke-ethereum.sh](../../../scripts/GKE/deploy-gke-ethereum.sh)
- **JWT Generation**: [scripts/generate-jwt-secrets.sh](../../../scripts/generate-jwt-secrets.sh)
- **JWT Verification**: [scripts/verify-jwt-setup.sh](../../../scripts/verify-jwt-setup.sh)

---

**Last Updated**: August 17, 2025  
**Version**: 1.0  
**Status**: ✅ Ready for GKE Deployment
