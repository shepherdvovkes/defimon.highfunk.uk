#!/bin/bash

# Deploy Telegram Bot to Google Cloud Container (GKE)
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Configuration
PROJECT_ID="defimon-ethereum-node"
CLUSTER_NAME="telegram-bot-cluster"
ZONE="us-central1-a"
IMAGE_NAME="gcr.io/${PROJECT_ID}/telegram-bot"
TAG="latest"

echo "🚀 Deploying Telegram Bot to Google Cloud Container (GKE)"
echo "=========================================================="

# Step 1: Configure Docker to use gcloud as a credential helper
print_status "Configuring Docker authentication..."
gcloud auth configure-docker

# Step 2: Build the Docker image
print_status "Building Docker image..."
docker build -t ${IMAGE_NAME}:${TAG} .

# Step 3: Push the image to Google Container Registry
print_status "Pushing image to Google Container Registry..."
docker push ${IMAGE_NAME}:${TAG}

# Step 4: Apply Kubernetes deployment
print_status "Deploying to Kubernetes cluster..."
kubectl apply -f k8s-deployment.yaml

# Step 5: Wait for deployment to be ready
print_status "Waiting for deployment to be ready..."
kubectl rollout status deployment/telegram-bot

# Step 6: Check deployment status
print_status "Checking deployment status..."
kubectl get pods -l app=telegram-bot

# Step 7: Show service information
print_status "Service information:"
kubectl get service telegram-bot-service

# Step 8: Show logs
print_status "Recent logs from the bot:"
kubectl logs -l app=telegram-bot --tail=20

echo ""
print_success "🎉 Telegram Bot deployed successfully to GKE!"
echo ""
echo "📱 Your bot is now running in the cloud!"
echo "🔍 Monitor with: kubectl logs -f deployment/telegram-bot"
echo "📊 Check status: kubectl get pods -l app=telegram-bot"
echo "🛑 Stop with: kubectl delete -f k8s-deployment.yaml"
echo ""
echo "💡 The bot will automatically restart if it crashes"
echo "💡 Scale up/down with: kubectl scale deployment telegram-bot --replicas=2"
