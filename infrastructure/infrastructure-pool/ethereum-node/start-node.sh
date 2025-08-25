#!/bin/bash

# Ethereum Node Startup Script
set -e

echo "Starting Ethereum Full Node..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    echo "Please copy .env.example to .env and configure your Infura API key"
    exit 1
fi

# Load environment variables
source .env

# Check if JWT secret exists
if [ ! -f jwtsecret ]; then
    echo "Generating new JWT secret..."
    openssl rand -hex 32 > jwtsecret
    chmod 600 jwtsecret
fi

# Create data directories
mkdir -p geth-data lighthouse-data

# Start the services
echo "Starting Docker Compose services..."
docker-compose up -d

echo "Ethereum node is starting up..."
echo "Geth RPC: http://localhost:${GETH_HTTP_PORT}"
echo "Lighthouse API: http://localhost:${LIGHTHOUSE_HTTP_PORT}"
echo ""
echo "Check logs with: docker-compose logs -f"
echo "Stop with: docker-compose down"
