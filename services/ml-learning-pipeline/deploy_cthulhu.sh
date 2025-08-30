#!/bin/bash

# ML Learning Pipeline Deployment Script for cthulhu.local
# Optimized for Apple M4 Neural Engine

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CTHULHU_HOST="vovkes@cthulhu.local"
PROJECT_DIR="/home/vovkes/ml-learning-pipeline"
SERVICE_NAME="ml-learning-pipeline"
PYTHON_VERSION="3.11"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if we're on macOS with Apple Silicon
check_apple_silicon() {
    if [[ "$(uname)" == "Darwin" ]] && [[ "$(uname -m)" == "arm64" ]]; then
        log "Detected Apple Silicon Mac - optimizing for M4 Neural Engine"
        return 0
    else
        warn "Not running on Apple Silicon - some optimizations may not be available"
        return 1
    fi
}

# Check system requirements
check_requirements() {
    log "Checking system requirements..."
    
    # Check if we can connect to cthulhu.local
    if ! ping -c 1 cthulhu.local > /dev/null 2>&1; then
        error "Cannot reach cthulhu.local. Please ensure the host is accessible."
    fi
    
    # Check SSH access
    if ! ssh -o ConnectTimeout=5 $CTHULHU_HOST "echo 'SSH connection successful'" > /dev/null 2>&1; then
        error "Cannot SSH to cthulhu.local. Please check SSH configuration."
    fi
    
    log "System requirements check passed"
}

# Setup Python environment on cthulhu.local
setup_python_environment() {
    log "Setting up Python environment on cthulhu.local..."
    
    ssh $CTHULHU_HOST << 'EOF'
        # Update system packages
        sudo apt update && sudo apt upgrade -y
        
        # Install Python and pip
        sudo apt install -y python3.11 python3.11-pip python3.11-venv python3.11-dev
        
        # Install system dependencies for ML libraries
        sudo apt install -y build-essential cmake pkg-config
        sudo apt install -y libopenblas-dev liblapack-dev libatlas-base-dev
        sudo apt install -y libhdf5-dev libhdf5-serial-dev
        sudo apt install -y libjpeg-dev libpng-dev libtiff-dev
        sudo apt install -y libavcodec-dev libavformat-dev libswscale-dev
        sudo apt install -y libgtk-3-dev libcanberra-gtk3-dev
        sudo apt install -y libboost-all-dev
        sudo apt install -y redis-server postgresql postgresql-contrib
        
        # Start Redis
        sudo systemctl enable redis-server
        sudo systemctl start redis-server
        
        # Start PostgreSQL
        sudo systemctl enable postgresql
        sudo systemctl start postgresql
        
        # Create database
        sudo -u postgres createdb defi_analytics || true
        
        log "Python environment setup completed"
EOF
}

# Create project directory and copy files
setup_project_directory() {
    log "Setting up project directory on cthulhu.local..."
    
    # Create project directory
    ssh $CTHULHU_HOST "mkdir -p $PROJECT_DIR"
    
    # Copy project files
    log "Copying project files to cthulhu.local..."
    scp -r . $CTHULHU_HOST:$PROJECT_DIR/
    
    # Set proper permissions
    ssh $CTHULHU_HOST "chmod +x $PROJECT_DIR/*.py $PROJECT_DIR/*.sh"
}

# Setup virtual environment and install dependencies
setup_virtual_environment() {
    log "Setting up virtual environment and installing dependencies..."
    
    ssh $CTHULHU_HOST << EOF
        cd $PROJECT_DIR
        
        # Create virtual environment
        python3.11 -m venv venv
        source venv/bin/activate
        
        # Upgrade pip
        pip install --upgrade pip
        
        # Install Apple Silicon optimized packages if available
        if [[ "\$(uname -m)" == "arm64" ]]; then
            log "Installing Apple Silicon optimized packages..."
            pip install tensorflow-macos tensorflow-metal
            pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
        else
            log "Installing standard packages..."
            pip install tensorflow
            pip install torch torchvision
        fi
        
        # Install other dependencies
        pip install -r requirements.txt
        
        # Install additional system packages
        pip install coremltools
        pip install metal-performance-shaders
        
        log "Virtual environment setup completed"
EOF
}

# Create systemd service
create_systemd_service() {
    log "Creating systemd service for ML Learning Pipeline..."
    
    ssh $CTHULHU_HOST << EOF
        sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << 'SERVICE_EOF'
[Unit]
Description=ML Learning Pipeline for Apple M4 Neural Engine
After=network.target redis-server.service postgresql.service
Wants=redis-server.service postgresql.service

[Service]
Type=simple
User=vovkes
Group=vovkes
WorkingDirectory=$PROJECT_DIR
Environment=PATH=$PROJECT_DIR/venv/bin
Environment=PYTHONPATH=$PROJECT_DIR
Environment=APPLE_NEURAL_ENGINE=true
Environment=METAL_ACCELERATION=true
Environment=CORE_ML_OPTIMIZATION=true
ExecStart=$PROJECT_DIR/venv/bin/python main.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Resource limits for ML workloads
LimitNOFILE=65536
LimitNPROC=32768

# Memory and CPU limits
MemoryMax=16G
CPUQuota=400%

[Install]
WantedBy=multi-user.target
SERVICE_EOF

        # Reload systemd and enable service
        sudo systemctl daemon-reload
        sudo systemctl enable $SERVICE_NAME
        
        log "Systemd service created and enabled"
EOF
}

# Create environment file
create_environment_file() {
    log "Creating environment configuration file..."
    
    ssh $CTHULHU_HOST << 'EOF'
        cd $PROJECT_DIR
        
        # Create .env file with QuickNode credentials
        cat > .env << 'ENV_EOF'
# QuickNode Configuration (using existing credentials)
QUICKNODE_ENDPOINT_NAME=hidden-holy-seed
QUICKNODE_TOKEN_ID=97d6d8e7659b49b126c43455edc4607949bfb52b
QUICKNODE_API_KEY=QN_6a9c24b3a5fc491f88e8c24c3294ef36

# Apple M4 Neural Engine Configuration
APPLE_NEURAL_ENGINE=true
METAL_ACCELERATION=true
CORE_ML_OPTIMIZATION=true

# Database Configuration
DATABASE_URL=postgresql://postgres:password@localhost:5432/defi_analytics
REDIS_URL=redis://localhost:6379

# API Configuration
API_HOST=0.0.0.0
API_PORT=8003
API_WORKERS=4

# Logging
LOG_LEVEL=INFO
LOG_FILE=logs/ml-pipeline.log

# Monitoring
PROMETHEUS_ENABLED=true
PROMETHEUS_PORT=9091

# Security
API_KEY_REQUIRED=true
RATE_LIMIT_PER_MINUTE=100

# Data Collection
DATA_COLLECTION_INTERVAL=60
HISTORICAL_DATA_DAYS=365
REAL_TIME_ENABLED=true

# Networks to monitor
NETWORKS=["ethereum", "polygon", "arbitrum", "optimism", "base", "bsc", "avalanche"]
ENV_EOF

        log "Environment file created"
EOF
}

# Create logs directory
create_logs_directory() {
    log "Creating logs directory..."
    
    ssh $CTHULHU_HOST << EOF
        mkdir -p $PROJECT_DIR/logs
        chmod 755 $PROJECT_DIR/logs
EOF
}

# Test the installation
test_installation() {
    log "Testing the installation..."
    
    ssh $CTHULHU_HOST << EOF
        cd $PROJECT_DIR
        
        # Activate virtual environment
        source venv/bin/activate
        
        # Test Python imports
        python -c "
import tensorflow as tf
import torch
import numpy as np
import pandas as pd
import redis
import structlog
print('All imports successful')
print(f'TensorFlow version: {tf.__version__}')
print(f'PyTorch version: {torch.__version__}')
print(f'NumPy version: {np.__version__}')
print(f'Pandas version: {pd.__version__}')
"
        
        # Test QuickNode connection
        python -c "
import asyncio
from data_collector import QuickNodeDataCollector

async def test_connection():
    async with QuickNodeDataCollector() as collector:
        data = await collector.collect_price_data('ethereum')
        print(f'QuickNode connection successful: {len(data)} data points collected')

asyncio.run(test_connection())
"
        
        log "Installation test completed successfully"
EOF
}

# Start the service
start_service() {
    log "Starting ML Learning Pipeline service..."
    
    ssh $CTHULHU_HOST << EOF
        sudo systemctl start $SERVICE_NAME
        sudo systemctl status $SERVICE_NAME
        
        # Wait a moment for service to start
        sleep 5
        
        # Check if service is running
        if sudo systemctl is-active --quiet $SERVICE_NAME; then
            log "Service started successfully"
        else
            error "Service failed to start"
        fi
EOF
}

# Show service status
show_status() {
    log "Showing service status..."
    
    ssh $CTHULHU_HOST << EOF
        echo "=== Service Status ==="
        sudo systemctl status $SERVICE_NAME --no-pager
        
        echo "=== Service Logs ==="
        sudo journalctl -u $SERVICE_NAME -n 20 --no-pager
        
        echo "=== API Health Check ==="
        curl -s http://localhost:8003/health | python -m json.tool
        
        echo "=== Available Endpoints ==="
        echo "Health Check: http://cthulhu.local:8003/health"
        echo "API Documentation: http://cthulhu.local:8003/docs"
        echo "Price Prediction: POST http://cthulhu.local:8003/api/v1/predict/price"
        echo "Gas Optimization: POST http://cthulhu.local:8003/api/v1/optimize/gas"
        echo "DeFi Risk Assessment: POST http://cthulhu.local:8003/api/v1/analyze/defi-risk"
        echo "Network Congestion: GET http://cthulhu.local:8003/api/v1/network/congestion"
        echo "Contract Analysis: POST http://cthulhu.local:8003/api/v1/analyze/contract"
        echo "Dashboard: GET http://cthulhu.local:8003/api/v1/dashboard"
EOF
}

# Main deployment function
main() {
    log "Starting ML Learning Pipeline deployment for cthulhu.local"
    log "Optimized for Apple M4 Neural Engine"
    
    # Check if we're on Apple Silicon
    check_apple_silicon
    
    # Check requirements
    check_requirements
    
    # Setup steps
    setup_python_environment
    setup_project_directory
    setup_virtual_environment
    create_environment_file
    create_logs_directory
    create_systemd_service
    
    # Test installation
    test_installation
    
    # Start service
    start_service
    
    # Show status
    show_status
    
    log "Deployment completed successfully!"
    log "ML Learning Pipeline is now running on cthulhu.local"
    log "Access the API at: http://cthulhu.local:8003"
    log "View documentation at: http://cthulhu.local:8003/docs"
}

# Run main function
main "$@"
