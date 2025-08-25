# GKE Scripts

## 🎯 Overview

This directory contains all scripts related to deploying and managing Ethereum nodes on Google Kubernetes Engine (GKE).

## 📁 Scripts

### **`deploy-gke-ethereum.sh`**
Main deployment script for Ethereum nodes on GKE.

**Features:**
- ✅ Creates GKE cluster with auto-scaling
- ✅ Sets up dedicated node pool for Ethereum workloads
- ✅ Configures JWT authentication secrets
- ✅ Deploys all Kubernetes manifests
- ✅ Enables monitoring and auto-scaling
- ✅ Verifies deployment success

**Usage:**
```bash
./scripts/GKE/deploy-gke-ethereum.sh
```

**Prerequisites:**
- Google Cloud SDK (`gcloud`) installed
- `kubectl` installed
- JWT secrets generated locally
- GCP project configured

## 🚀 Deployment Process

### **1. GKE Cluster Creation**
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

### **2. Node Pool Setup**
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

### **3. Application Deployment**
- Namespace creation
- Storage setup (PVCs, ConfigMaps)
- JWT secrets configuration
- Ethereum node deployments
- Service configuration
- Auto-scaling setup
- Monitoring stack deployment

## 🔧 Configuration

### **GCP Settings**
The script automatically loads configuration from `gcp.env`:
- Project ID
- Region and Zone
- Service account details
- Storage bucket configuration

### **JWT Secrets**
- Automatically reads local JWT files
- Creates base64 encoded Kubernetes secrets
- Sets proper permissions (0400)
- Mounts secrets in pods

## 📊 Auto-scaling Features

### **Horizontal Pod Autoscaler (HPA)**
- **Geth**: 1-3 replicas based on CPU/memory/RPS
- **Lighthouse**: 1-2 replicas based on CPU/memory/RPS
- **Scaling Policies**: Configurable thresholds and behavior

### **Vertical Pod Autoscaler (VPA)**
- **Mode**: Auto
- **Resource Ranges**: CPU 100m-8 cores, Memory 50Mi-16Gi
- **Updates**: Automatic resource optimization

### **Node Pool Auto-scaling**
- **Default Pool**: 1-5 nodes (e2-standard-4)
- **Ethereum Pool**: 1-3 nodes (e2-standard-8)
- **Scaling**: Based on CPU utilization

## 🔍 Verification & Monitoring

### **Deployment Verification**
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

### **Monitoring Access**
```bash
# Prometheus
kubectl port-forward svc/prometheus-service 9090:9090 -n defimon

# Grafana
kubectl port-forward svc/grafana-service 3000:3000 -n defimon
```

## 🛠️ Troubleshooting

### **Common Issues**

1. **GKE Cluster Creation Fails**
   - Check GCP quotas and limits
   - Verify billing is enabled
   - Check region availability

2. **JWT Secrets Not Working**
   - Verify JWT files exist locally
   - Check secret creation in Kubernetes
   - Verify volume mounts in pods

3. **Auto-scaling Not Working**
   - Check metrics server installation
   - Verify HPA/VPA configurations
   - Check resource requests/limits

### **Debug Commands**
```bash
# Check cluster status
gcloud container clusters describe ethereum-nodes-cluster --region=us-central1

# Check node pool status
gcloud container node-pools describe ethereum-pool --cluster=ethereum-nodes-cluster --region=us-central1

# Check pod logs
kubectl logs -f deployment/ethereum-geth -n defimon
kubectl logs -f deployment/ethereum-lighthouse -n defimon
```

## 📚 Related Documentation

- **GKE Configuration**: [infrastructure/kubernetes/GKE/](../../infrastructure/kubernetes/GKE/)
- **JWT Setup**: [docs/ethereum-jwt-setup/](../../../docs/ethereum-jwt-setup/)
- **Main README**: [README.md](../../../README.md)

## 🔗 Dependencies

- **JWT Generation**: `scripts/generate-jwt-secrets.sh`
- **JWT Verification**: `scripts/verify-jwt-setup.sh`
- **GCP Configuration**: `gcp.env`
- **Kubernetes Manifests**: `infrastructure/kubernetes/GKE/`

---

**Last Updated**: August 17, 2025  
**Version**: 1.0  
**Status**: ✅ Ready for GKE Deployment
