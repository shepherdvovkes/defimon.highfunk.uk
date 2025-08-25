#!/bin/bash

echo "🚀 Deploying Ethereum Tiered Storage Configuration..."

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ kubectl not configured. Please run: gcloud container clusters get-credentials ethereum-nodes-cluster --region=europe-west1"
    exit 1
fi

# Create namespace if it doesn't exist
kubectl create namespace defimon --dry-run=client -o yaml | kubectl apply -f -

echo "📦 Applying storage classes..."
kubectl apply -f storage-classes.yaml

echo "💾 Creating tiered storage PVCs..."
kubectl apply -f ethereum-tiered-storage.yaml

echo "⏳ Waiting for PVCs to be bound..."
kubectl wait --for=condition=Bound pvc/ethereum-hot-data -n defimon --timeout=300s
kubectl wait --for=condition=Bound pvc/ethereum-cold-data -n defimon --timeout=300s

echo "📊 Storage Status:"
kubectl get pvc -n defimon
kubectl get storageclass

echo "✅ Tiered storage deployment complete!"
echo ""
echo "📁 Storage Layout:"
echo "  🔥 Hot Data (SSD): 100Gi for last 200k blocks"
echo "  ❄️  Cold Data (HDD): 2Ti for archive blocks"
echo ""
echo "🔧 Next steps:"
echo "  1. Deploy Ethereum nodes with these PVCs mounted"
echo "  2. Configure Geth/Lighthouse to use tiered paths"
echo "  3. Set up data migration between hot/cold storage"
