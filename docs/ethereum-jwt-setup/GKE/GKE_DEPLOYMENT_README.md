# Ethereum Nodes on Google Kubernetes Engine (GKE)

## 🎯 Overview

This guide explains how to deploy self-scaled Ethereum nodes (Geth + Lighthouse) on Google Kubernetes Engine with automatic scaling, monitoring, and proper JWT authentication.

## 🚀 Quick Start

### 1. Prepare JWT Secrets
```bash
# Generate JWT secrets locally
./scripts/generate-jwt-secrets.sh

# Verify JWT setup
./scripts/verify-jwt-setup.sh
```

### 2. Deploy to GKE
```bash
# Deploy Ethereum nodes to GKE
./scripts/deploy-gke-ethereum.sh
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
- **Geth (Execution Client)**
  - Ports: 8545 (HTTP), 8546 (WebSocket), 8551 (AuthRPC), 30303 (P2P)
  - Resources: 2-4 CPU, 4-8GB RAM
  - Storage: 2TB SSD
  
- **Lighthouse (Consensus Client)**
  - Ports: 5052 (HTTP), 9000 (P2P)
  - Resources: 1-2 CPU, 2-4GB RAM
  - Storage: 500GB SSD

### **Monitoring Stack**
- **Prometheus**: Metrics collection and storage
- **Grafana**: Dashboards and visualization
- **Custom Metrics**: Ethereum-specific metrics

## 🔧 Auto-scaling Configuration

### **Horizontal Pod Autoscaler (HPA)**
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

### **Vertical Pod Autoscaler (VPA)**
- **Mode**: Auto
- **CPU Range**: 100m - 8 cores
- **Memory Range**: 50Mi - 16Gi
- **Updates**: Automatic resource adjustment

### **Node Pool Auto-scaling**
- **Default Pool**: 1-5 nodes (e2-standard-4)
- **Ethereum Pool**: 1-3 nodes (e2-standard-8)
- **Scaling Policies**: CPU utilization based

## 📁 Kubernetes Manifests

### **Core Components**
- `ethereum-node-deployment.yml` - Geth and Lighthouse deployments
- `ethereum-node-services.yml` - Internal and external services
- `ethereum-node-autoscaling.yml` - HPA and VPA configurations
- `ethereum-node-storage.yml` - PVCs and ConfigMaps
- `ethereum-node-monitoring.yml` - Prometheus and Grafana

### **Deployment Order**
1. **Namespace** - Create defimon namespace
2. **Storage** - PVCs and ConfigMaps
3. **Secrets** - JWT authentication secrets
4. **Deployments** - Geth and Lighthouse pods
5. **Services** - Internal communication
6. **Autoscaling** - HPA and VPA
7. **Monitoring** - Prometheus and Grafana

## 🔐 JWT Authentication

### **Secret Management**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ethereum-jwt-secret
type: Opaque
data:
  jwtsecret.raw: <base64-encoded-geth-jwt>
  jwtsecret.hex: <base64-encoded-lighthouse-jwt>
```

### **Volume Mounts**
- **Geth**: `/root/.ethereum/jwtsecret` (subPath: jwtsecret.raw)
- **Lighthouse**: `/root/.lighthouse/jwtsecret` (subPath: jwtsecret.hex)
- **Permissions**: 0400 (read-only)

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

## 🚀 Deployment Process

### **Step 1: GKE Cluster Creation**
```bash
gcloud container clusters create ethereum-nodes-cluster \
  --region=us-central1 \
  --num-nodes=1 \
  --min-nodes=1 \
  --max-nodes=5 \
  --enable-autoscaling \
  --machine-type=e2-standard-4 \
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
kubectl apply -f infrastructure/kubernetes/

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
- [Ethereum JWT Setup](JWT_SETUP_GUIDE.md)

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

---

**Last Updated**: August 17, 2025  
**Version**: 1.0  
**Status**: ✅ Ready for GKE Deployment
