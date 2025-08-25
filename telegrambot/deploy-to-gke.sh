#!/bin/bash

# Deploy Telegram Bot to GKE
set -e

echo "🚀 Deploying Telegram Bot to GKE..."

# Configuration
PROJECT_ID="defimon-ethereum-node"
CLUSTER_NAME="telegram-bot-cluster"
CLUSTER_ZONE="us-central1-a"
REGISTRY="gcr.io"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}📋 Configuration:${NC}"
echo "   Project ID: $PROJECT_ID"
echo "   Cluster: $CLUSTER_NAME"
echo "   Zone: $CLUSTER_ZONE"
echo "   Registry: $REGISTRY"
echo ""

# Step 1: Configure Docker for GCR
echo -e "${YELLOW}🔐 Configuring Docker for Google Container Registry...${NC}"
gcloud auth configure-docker --project=$PROJECT_ID

# Step 2: Build and tag Docker images
echo -e "${YELLOW}🔨 Building Docker images...${NC}"

# Build telegram-bot image
echo "Building telegram-bot image..."
docker build -t $REGISTRY/$PROJECT_ID/telegram-bot:latest .

# Build infrastructure-monitor image
echo "Building infrastructure-monitor image..."
docker build -t $REGISTRY/$PROJECT_ID/infrastructure-monitor:latest .

echo -e "${GREEN}✅ Images built successfully${NC}"

# Step 3: Push images to GCR
echo -e "${YELLOW}📤 Pushing images to Google Container Registry...${NC}"

echo "Pushing telegram-bot image..."
docker push $REGISTRY/$PROJECT_ID/telegram-bot:latest

echo "Pushing infrastructure-monitor image..."
docker push $REGISTRY/$PROJECT_ID/infrastructure-monitor:latest

echo -e "${GREEN}✅ Images pushed successfully${NC}"

# Step 4: Connect to GKE cluster
echo -e "${YELLOW}🔗 Connecting to GKE cluster...${NC}"
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$CLUSTER_ZONE --project=$PROJECT_ID

echo -e "${GREEN}✅ Connected to cluster successfully${NC}"

# Step 5: Create namespace and deploy
echo -e "${YELLOW}🚀 Deploying to Kubernetes...${NC}"

# Create namespace
kubectl create namespace telegram-bot --dry-run=client -o yaml | kubectl apply -f -

# Apply the deployment
kubectl apply -f k8s-deployment.yaml

echo -e "${GREEN}✅ Deployment applied successfully${NC}"

# Step 6: Wait for deployment
echo -e "${YELLOW}⏳ Waiting for deployment to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/telegram-bot -n telegram-bot
kubectl wait --for=condition=available --timeout=300s deployment/infrastructure-monitor -n telegram-bot

echo -e "${GREEN}✅ All deployments are ready!${NC}"

# Step 7: Show status
echo -e "${YELLOW}📊 Deployment Status:${NC}"
kubectl get pods -n telegram-bot
kubectl get services -n telegram-bot

echo ""
echo -e "${GREEN}🎉 Telegram Bot successfully deployed to GKE!${NC}"
echo ""
echo -e "${YELLOW}📱 Your bot is now running in the cloud with:${NC}"
echo "   • Better performance (closer to GCP APIs)"
echo "   • Higher availability (24/7 uptime)"
echo "   • Automatic scaling and recovery"
echo "   • Built-in monitoring and logging"
echo ""
echo -e "${YELLOW}🔍 To check logs:${NC}"
echo "   kubectl logs -f deployment/telegram-bot -n telegram-bot"
echo "   kubectl logs -f deployment/infrastructure-monitor -n telegram-bot"
echo ""
echo -e "${YELLOW}🔄 To update deployment:${NC}"
echo "   ./deploy-to-gke.sh"
echo ""
echo -e "${YELLOW}🗑️  To remove deployment:${NC}"
echo "   kubectl delete -f k8s-deployment.yaml"
