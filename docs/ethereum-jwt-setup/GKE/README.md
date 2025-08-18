# GKE Documentation

## 🎯 Overview

This directory contains comprehensive documentation for deploying self-scaled Ethereum nodes on Google Kubernetes Engine (GKE) with proper JWT authentication and auto-scaling.

## 📁 Documentation Files

### **`GKE_DEPLOYMENT_README.md`**
Complete deployment guide for Ethereum nodes on GKE.

**Contents:**
- 🚀 Quick start guide
- 🏗️ Architecture overview
- 🔧 Auto-scaling configuration
- 📊 Monitoring setup
- 💰 Cost optimization
- 🛠️ Troubleshooting guide

## 🚀 Quick Start

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

## 📋 Prerequisites

- ✅ Google Cloud SDK (`gcloud`) installed
- ✅ `kubectl` installed
- ✅ JWT secrets generated locally
- ✅ GCP project configured
- ✅ Billing enabled on GCP project

## 🏗️ Architecture

### **GKE Cluster Structure**
```
ethereum-nodes-cluster (Regional)
├── default-pool (e2-standard-4, 1-5 nodes)
└── ethereum-pool (e2-standard-8, 1-3 nodes)
    ├── Dedicated for Ethereum workloads
    ├── SSD storage (200GB per node)
    └── Auto-scaling enabled
```

### **Ethereum Node Components**
- **Geth**: Execution client with JWT authentication
- **Lighthouse**: Consensus client with JWT authentication
- **Monitoring**: Prometheus + Grafana stack
- **Storage**: Persistent volumes with SSD

## 🔧 Auto-scaling Features

### **Horizontal Pod Autoscaler (HPA)**
- **Geth**: 1-3 replicas based on CPU/memory/RPS
- **Lighthouse**: 1-2 replicas based on CPU/memory/RPS
- **Scaling Policies**: Configurable thresholds and behavior

### **Vertical Pod Autoscaler (VPA)**
- **Mode**: Auto
- **CPU Range**: 100m - 8 cores
- **Memory Range**: 50Mi - 16Gi
- **Updates**: Automatic resource optimization

### **Node Pool Auto-scaling**
- **Default Pool**: 1-5 nodes (e2-standard-4)
- **Ethereum Pool**: 1-3 nodes (e2-standard-8)
- **Scaling**: Based on CPU utilization

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

### **Key Metrics**
- **Geth**: Block sync, peer count, memory usage
- **Lighthouse**: Beacon sync, validator count, network health
- **Infrastructure**: CPU, memory, disk I/O

## 🔐 JWT Authentication

### **Secret Management**
- **Secret Name**: `ethereum-jwt-secret`
- **Data Keys**: `jwtsecret.raw` (Geth), `jwtsecret.hex` (Lighthouse)
- **Permissions**: 0400 (read-only)
- **Volume Mounts**: Separate JWT files for each service

### **Security Features**
- **Read-only mounts**: Containers cannot modify JWT files
- **Proper permissions**: 0400 for security
- **Kubernetes secrets**: Encrypted at rest

## 💰 Cost Optimization

### **Resource Allocation**
- **Geth**: 2-4 CPU, 4-8GB RAM (production workload)
- **Lighthouse**: 1-2 CPU, 2-4GB RAM (consensus)
- **Storage**: SSD for performance, appropriate sizing

### **Auto-scaling Benefits**
- **Horizontal**: Scale pods based on demand
- **Vertical**: Optimize resource allocation
- **Node Pool**: Scale infrastructure efficiently

### **Estimated Monthly Cost**
- **Compute**: $150-300/month
- **Storage**: $50-100/month
- **Network**: $20-50/month
- **Total**: $220-450/month

## 🚀 Deployment Process

### **Step 1: GKE Cluster Creation**
```bash
gcloud container clusters create ethereum-nodes-cluster \
  --region=us-central1 \
  --num-nodes=1 \
  --min-nodes=1 \
  --max-nodes=5 \
  --enable-autoscaling \
  --enable-vertical-pod-autoscaling \
  --enable-horizontal-pod-autoscaling
```

### **Step 2: Node Pool Creation**
```bash
gcloud container node-pools create ethereum-pool \
  --cluster=ethereum-nodes-cluster \
  --region=us-central1 \
  --num-nodes=1 \
  --min-nodes=1 \
  --max-nodes=3 \
  --enable-autoscaling \
  --machine-type=e2-standard-8 \
  --disk-size=200 \
  --disk-type=pd-ssd
```

### **Step 3: Application Deployment**
```bash
# Apply all Kubernetes manifests
kubectl apply -f infrastructure/kubernetes/GKE/

# Wait for deployments
kubectl wait --for=condition=available deployment/ethereum-geth -n defimon
kubectl wait --for=condition=available deployment/ethereum-lighthouse -n defimon
```

## 🔍 Verification & Testing

### **Deployment Status**
```bash
# Check pod status
kubectl get pods -n defimon -o wide

# Check services
kubectl get services -n defimon

# Check autoscalers
kubectl get hpa,vpa -n defimon
```

### **Health Checks**
```bash
# Geth health
kubectl exec -n defimon deployment/ethereum-geth -- curl -s http://localhost:8545/health

# Lighthouse health
kubectl exec -n defimon deployment/ethereum-lighthouse -- curl -s http://localhost:5052/eth/v1/node/health
```

### **Monitoring Access**
```bash
# Prometheus
kubectl port-forward svc/prometheus-service 9090:9090 -n defimon

# Grafana
kubectl port-forward svc/grafana-service 3000:3000 -n defimon
```

## 🛠️ Troubleshooting

### **Common Issues**

1. **JWT Authentication Failures**
   ```bash
   # Check secret exists
   kubectl get secret ethereum-jwt-secret -n defimon
   
   # Verify secret content
   kubectl describe secret ethereum-jwt-secret -n defimon
   ```

2. **Storage Issues**
   ```bash
   # Check PVC status
   kubectl get pvc -n defimon
   
   # Check storage class
   kubectl get storageclass
   ```

3. **Auto-scaling Not Working**
   ```bash
   # Check HPA status
   kubectl describe hpa ethereum-geth-hpa -n defimon
   
   # Check metrics server
   kubectl get apiservice v1beta1.metrics.k8s.io
   ```

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

## 📚 References

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Kubernetes HPA](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Kubernetes VPA](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
- [Ethereum JWT Setup](../JWT_SETUP_GUIDE.md)

## 🆘 Support

### **Getting Help**
1. Check deployment logs
2. Verify Kubernetes resources
3. Review auto-scaling configuration
4. Check GCP quotas and limits

### **Escalation Path**
1. Review this documentation
2. Check GKE cluster status
3. Verify application logs
4. Contact GCP support if needed

## 🔗 Related Resources

- **GKE Configuration**: [infrastructure/kubernetes/GKE/](../../../../infrastructure/kubernetes/GKE/)
- **GKE Scripts**: [scripts/GKE/](../../../../scripts/GKE/)
- **JWT Setup Guide**: [JWT_SETUP_GUIDE.md](../JWT_SETUP_GUIDE.md)
- **Main Documentation**: [docs/ethereum-jwt-setup/](../../../)

---

**Last Updated**: August 17, 2025  
**Version**: 1.0  
**Status**: ✅ Ready for GKE Deployment
