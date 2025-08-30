#!/bin/bash

# =============================================================================
# DIGITALOCEAN ML TRAINING DEPLOYMENT SCRIPT
# Multi-Source ML Fine-Tuning on DigitalOcean GPU Instances
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DROPLET_NAME="defimon-ml-training"
REGION="nyc1"
SIZE="s-8vcpu-16gb-gpu"  # GPU instance with NVIDIA T4
IMAGE="ubuntu-20-04-x64"
SSH_KEY_ID=""
DO_TOKEN=""

# ML Training Configuration
ML_CONFIG_DIR="/opt/defimon-ml"
DATA_DIR="/opt/defimon-ml/data"
MODELS_DIR="/opt/defimon-ml/models"
LOGS_DIR="/opt/defimon-ml/logs"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if doctl is installed
    if ! command -v doctl &> /dev/null; then
        print_error "doctl CLI is not installed. Please install it first:"
        echo "https://docs.digitalocean.com/reference/doctl/how-to/install/"
        exit 1
    fi
    
    # Check if DO_TOKEN is set
    if [ -z "$DO_TOKEN" ]; then
        print_error "DO_TOKEN environment variable is not set"
        echo "Please set it: export DO_TOKEN=your_digitalocean_token"
        exit 1
    fi
    
    # Check if SSH_KEY_ID is set
    if [ -z "$SSH_KEY_ID" ]; then
        print_error "SSH_KEY_ID environment variable is not set"
        echo "Please set it: export SSH_KEY_ID=your_ssh_key_id"
        exit 1
    fi
    
    print_status "Prerequisites check passed"
}

# Create DigitalOcean droplet
create_droplet() {
    print_header "Creating DigitalOcean GPU Droplet"
    
    print_status "Creating droplet: $DROPLET_NAME"
    print_status "Region: $REGION"
    print_status "Size: $SIZE"
    print_status "Image: $IMAGE"
    
    # Create the droplet
    DROPLET_ID=$(doctl compute droplet create $DROPLET_NAME \
        --size $SIZE \
        --image $IMAGE \
        --region $REGION \
        --ssh-keys $SSH_KEY_ID \
        --format ID,Name,Status \
        --no-header | awk '{print $1}')
    
    if [ -z "$DROPLET_ID" ]; then
        print_error "Failed to create droplet"
        exit 1
    fi
    
    print_status "Droplet created with ID: $DROPLET_ID"
    
    # Wait for droplet to be active
    print_status "Waiting for droplet to become active..."
    while true; do
        STATUS=$(doctl compute droplet get $DROPLET_ID --format Status --no-header)
        if [ "$STATUS" = "active" ]; then
            break
        fi
        echo "Status: $STATUS"
        sleep 10
    done
    
    # Get droplet IP
    DROPLET_IP=$(doctl compute droplet get $DROPLET_ID --format PublicIPv4 --no-header)
    print_status "Droplet IP: $DROPLET_IP"
    
    # Wait for SSH to be available
    print_status "Waiting for SSH to be available..."
    while ! nc -z $DROPLET_IP 22; do
        sleep 5
    done
    
    print_status "Droplet is ready for SSH connection"
}

# Setup the ML environment
setup_ml_environment() {
    print_header "Setting Up ML Environment"
    
    # Create setup script
    cat > setup_ml_environment.sh << 'EOF'
#!/bin/bash

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install system dependencies
sudo apt-get install -y \
    python3.9 \
    python3.9-dev \
    python3-pip \
    git \
    curl \
    wget \
    htop \
    nvtop \
    nvidia-cuda-toolkit \
    nvidia-driver-470 \
    build-essential \
    cmake \
    pkg-config \
    libssl-dev \
    libffi-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libxft-dev \
    libblas-dev \
    liblapack-dev \
    libatlas-base-dev \
    gfortran \
    libhdf5-dev \
    libhdf5-serial-dev \
    libhdf5-103 \
    libqtgui4 \
    libqtwebkit4 \
    libqt4-test \
    python3-pyqt5 \
    libgtk-3-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libatlas-base-dev \
    gfortran \
    libpq-dev \
    redis-server \
    postgresql \
    postgresql-contrib

# Create ML directories
sudo mkdir -p /opt/defimon-ml/{data,models,logs,config}
sudo chown -R $USER:$USER /opt/defimon-ml

# Install Python dependencies
pip3 install --upgrade pip
pip3 install setuptools wheel

# Install PyTorch with CUDA support
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Install ML dependencies
pip3 install \
    transformers==4.30.0 \
    datasets==2.12.0 \
    accelerate==0.20.0 \
    wandb==0.15.0 \
    mlflow==2.4.0 \
    optuna==3.1.0 \
    scikit-learn==1.3.0 \
    xgboost==1.7.0 \
    lightgbm==3.3.0 \
    pandas==2.0.0 \
    numpy==1.24.0 \
    scipy==1.11.0 \
    matplotlib==3.7.0 \
    seaborn==0.12.0 \
    plotly==5.15.0 \
    fastapi==0.100.0 \
    uvicorn==0.23.0 \
    redis==4.6.0 \
    psycopg2-binary==2.9.6 \
    sqlalchemy==2.0.0 \
    alembic==1.11.0 \
    python-dotenv==1.0.0 \
    pydantic==2.0.0 \
    loguru==0.7.0 \
    tqdm==4.65.0 \
    requests==2.31.0 \
    aiohttp==3.8.5 \
    asyncio-mqtt==0.11.0 \
    prometheus-client==0.17.0 \
    grafana-api==1.0.3 \
    ta==0.10.0 \
    yfinance==0.2.0 \
    ccxt==4.0.0 \
    statsmodels==0.14.0 \
    arch==6.2.0 \
    pyod==1.1.0 \
    hyperopt==0.2.7 \
    black==23.7.0 \
    flake8==6.0.0 \
    mypy==1.5.0 \
    pytest==7.4.0

# Install monitoring tools
sudo apt-get install -y prometheus grafana

# Configure Grafana
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

# Configure Prometheus
sudo systemctl enable prometheus
sudo systemctl start prometheus

# Setup firewall
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8000/tcp
sudo ufw allow 8001/tcp
sudo ufw allow 9090/tcp
sudo ufw allow 3000/tcp
sudo ufw --force enable

# Create systemd service for ML training
sudo tee /etc/systemd/system/defimon-ml.service > /dev/null << 'SERVICEEOF'
[Unit]
Description=DeFiMon ML Training Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/defimon-ml
Environment=PATH=/usr/local/bin:/usr/bin:/bin
ExecStart=/usr/bin/python3 /opt/defimon-ml/train_multi_source_model.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICEEOF

sudo systemctl daemon-reload
sudo systemctl enable defimon-ml

# Create monitoring dashboard
sudo tee /etc/grafana/provisioning/dashboards/defimon-ml.json > /dev/null << 'DASHBOARDEOF'
{
  "dashboard": {
    "title": "DeFiMon ML Training Dashboard",
    "panels": [
      {
        "title": "GPU Utilization",
        "type": "graph",
        "targets": [
          {
            "expr": "nvidia_gpu_utilization",
            "legendFormat": "GPU {{gpu}}"
          }
        ]
      },
      {
        "title": "Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "nvidia_gpu_memory_used_bytes",
            "legendFormat": "GPU {{gpu}}"
          }
        ]
      },
      {
        "title": "Training Loss",
        "type": "graph",
        "targets": [
          {
            "expr": "ml_training_loss_total",
            "legendFormat": "{{task}}"
          }
        ]
      }
    ]
  }
}
DASHBOARDEOF

print_status "ML environment setup completed"
EOF

    # Copy setup script to droplet
    scp -o StrictHostKeyChecking=no setup_ml_environment.sh root@$DROPLET_IP:/tmp/
    
    # Execute setup script
    ssh -o StrictHostKeyChecking=no root@$DROPLET_IP "chmod +x /tmp/setup_ml_environment.sh && /tmp/setup_ml_environment.sh"
    
    print_status "ML environment setup completed"
}

# Deploy ML code
deploy_ml_code() {
    print_header "Deploying ML Code"
    
    # Create deployment directory
    ssh -o StrictHostKeyChecking=no root@$DROPLET_IP "mkdir -p $ML_CONFIG_DIR"
    
    # Copy ML models and training code
    scp -r -o StrictHostKeyChecking=no \
        services/ai-ml-service/models/ \
        root@$DROPLET_IP:$ML_CONFIG_DIR/
    
    # Copy configuration files
    scp -o StrictHostKeyChecking=no \
        services/ai-ml-service/requirements_m4.txt \
        root@$DROPLET_IP:$ML_CONFIG_DIR/requirements.txt
    
    # Create training script
    cat > train_multi_source_model.py << 'EOF'
#!/usr/bin/env python3
"""
Multi-Source ML Training Script for DigitalOcean GPU
"""

import os
import sys
import torch
import logging
from datetime import datetime
from pathlib import Path

# Add the models directory to Python path
sys.path.append('/opt/defimon-ml/models')

from multi_source_transformer import create_multi_source_model, create_multi_source_loss
from m4_optimized_models import M4OptimizedModels

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/opt/defimon-ml/logs/training.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

def main():
    """Main training function"""
    logger.info("Starting Multi-Source ML Training on DigitalOcean GPU")
    
    # Check GPU availability
    if torch.cuda.is_available():
        logger.info(f"GPU available: {torch.cuda.get_device_name(0)}")
        device = torch.device('cuda')
    else:
        logger.warning("No GPU available, using CPU")
        device = torch.device('cpu')
    
    # Model configuration
    config = {
        'blockchain_dim': 512,
        'blockchain_heads': 8,
        'blockchain_layers': 6,
        'blockchain_input_dim': 50,
        'github_dim': 256,
        'github_heads': 4,
        'github_layers': 4,
        'github_input_dim': 20,
        'social_dim': 256,
        'social_heads': 4,
        'social_layers': 4,
        'social_input_dim': 30,
        'news_dim': 256,
        'news_heads': 4,
        'news_layers': 4,
        'news_input_dim': 25,
        'fusion_dim': 512,
        'fusion_heads': 8,
        'dropout': 0.1,
        'use_positional_encoding': True,
        'price_loss_weight': 1.0,
        'risk_loss_weight': 1.0,
        'sentiment_loss_weight': 1.0,
        'trend_loss_weight': 1.0
    }
    
    # Create model
    logger.info("Creating multi-source transformer model")
    model = create_multi_source_model(config)
    model = model.to(device)
    
    # Create loss function
    loss_fn = create_multi_source_loss(config)
    loss_fn = loss_fn.to(device)
    
    # Create optimizer
    optimizer = torch.optim.AdamW(model.parameters(), lr=1e-4, weight_decay=0.01)
    
    # Create scheduler
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=50)
    
    logger.info("Model setup completed")
    logger.info(f"Total parameters: {sum(p.numel() for p in model.parameters()):,}")
    
    # Training loop (placeholder for now)
    logger.info("Training loop placeholder - implement data loading and training")
    
    # Save model
    model_path = Path('/opt/defimon-ml/models/multi_source_transformer.pth')
    torch.save({
        'model_state_dict': model.state_dict(),
        'config': config,
        'timestamp': datetime.now().isoformat()
    }, model_path)
    
    logger.info(f"Model saved to {model_path}")

if __name__ == "__main__":
    main()
EOF

    # Copy training script
    scp -o StrictHostKeyChecking=no train_multi_source_model.py root@$DROPLET_IP:$ML_CONFIG_DIR/
    
    # Install Python dependencies
    ssh -o StrictHostKeyChecking=no root@$DROPLET_IP "cd $ML_CONFIG_DIR && pip3 install -r requirements.txt"
    
    print_status "ML code deployment completed"
}

# Setup data collection
setup_data_collection() {
    print_header "Setting Up Data Collection"
    
    # Create data collection script
    cat > data_collector.py << 'EOF'
#!/usr/bin/env python3
"""
Multi-Source Data Collector for ML Training
"""

import asyncio
import aiohttp
import json
import logging
from datetime import datetime, timedelta
from pathlib import Path
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MultiSourceDataCollector:
    def __init__(self):
        self.session = None
        self.data_dir = Path('/opt/defimon-ml/data')
        self.data_dir.mkdir(exist_ok=True)
        
        # API configurations
        self.apis = {
            'quicknode': {
                'base_url': 'https://hidden-holy-seed.ethereum.discover.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b/',
                'headers': {'Content-Type': 'application/json'}
            },
            'coingecko': {
                'base_url': 'https://api.coingecko.com/api/v3',
                'headers': {'Accept': 'application/json'}
            },
            'github': {
                'base_url': 'https://api.github.com',
                'headers': {'Authorization': f"token {os.getenv('GITHUB_TOKEN', '')}"}
            }
        }
    
    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    async def collect_blockchain_data(self):
        """Collect blockchain data from QuickNode"""
        logger.info("Collecting blockchain data...")
        
        # Ethereum data
        ethereum_data = await self._fetch_ethereum_data()
        
        # Save data
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        blockchain_file = self.data_dir / f'blockchain_data_{timestamp}.json'
        
        with open(blockchain_file, 'w') as f:
            json.dump(ethereum_data, f, indent=2)
        
        logger.info(f"Blockchain data saved to {blockchain_file}")
        return ethereum_data
    
    async def collect_github_data(self):
        """Collect GitHub development activity data"""
        logger.info("Collecting GitHub data...")
        
        # Repository data
        repos_data = await self._fetch_github_repos()
        
        # Save data
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        github_file = self.data_dir / f'github_data_{timestamp}.json'
        
        with open(github_file, 'w') as f:
            json.dump(repos_data, f, indent=2)
        
        logger.info(f"GitHub data saved to {github_file}")
        return repos_data
    
    async def _fetch_ethereum_data(self):
        """Fetch Ethereum blockchain data"""
        payload = {
            "jsonrpc": "2.0",
            "method": "eth_getBlockByNumber",
            "params": ["latest", False],
            "id": 1
        }
        
        async with self.session.post(
            self.apis['quicknode']['base_url'],
            json=payload,
            headers=self.apis['quicknode']['headers']
        ) as response:
            return await response.json()
    
    async def _fetch_github_repos(self):
        """Fetch GitHub repository data"""
        async with self.session.get(
            f"{self.apis['github']['base_url']}/user/repos",
            headers=self.apis['github']['headers']
        ) as response:
            return await response.json()

async def main():
    """Main data collection function"""
    async with MultiSourceDataCollector() as collector:
        # Collect data from all sources
        blockchain_data = await collector.collect_blockchain_data()
        github_data = await collector.collect_github_data()
        
        logger.info("Data collection completed")

if __name__ == "__main__":
    asyncio.run(main())
EOF

    # Copy data collector
    scp -o StrictHostKeyChecking=no data_collector.py root@$DROPLET_IP:$ML_CONFIG_DIR/
    
    # Create cron job for data collection
    ssh -o StrictHostKeyChecking=no root@$DROPLET_IP "echo '*/15 * * * * cd $ML_CONFIG_DIR && python3 data_collector.py >> /opt/defimon-ml/logs/data_collection.log 2>&1' | crontab -"
    
    print_status "Data collection setup completed"
}

# Start ML training
start_ml_training() {
    print_header "Starting ML Training"
    
    # Start the ML training service
    ssh -o StrictHostKeyChecking=no root@$DROPLET_IP "systemctl start defimon-ml"
    
    # Check service status
    ssh -o StrictHostKeyChecking=no root@$DROPLET_IP "systemctl status defimon-ml"
    
    print_status "ML training service started"
}

# Display connection information
display_info() {
    print_header "Deployment Complete"
    
    echo -e "${GREEN}DigitalOcean Droplet Information:${NC}"
    echo "Droplet Name: $DROPLET_NAME"
    echo "IP Address: $DROPLET_IP"
    echo "Region: $REGION"
    echo "Size: $SIZE"
    
    echo -e "\n${GREEN}Access Information:${NC}"
    echo "SSH: ssh root@$DROPLET_IP"
    echo "ML Training Logs: ssh root@$DROPLET_IP 'tail -f /opt/defimon-ml/logs/training.log'"
    echo "Data Collection Logs: ssh root@$DROPLET_IP 'tail -f /opt/defimon-ml/logs/data_collection.log'"
    
    echo -e "\n${GREEN}Monitoring URLs:${NC}"
    echo "Grafana Dashboard: http://$DROPLET_IP:3000 (admin/admin)"
    echo "Prometheus: http://$DROPLET_IP:9090"
    
    echo -e "\n${GREEN}Service Management:${NC}"
    echo "Check ML service: ssh root@$DROPLET_IP 'systemctl status defimon-ml'"
    echo "Restart ML service: ssh root@$DROPLET_IP 'systemctl restart defimon-ml'"
    echo "Stop ML service: ssh root@$DROPLET_IP 'systemctl stop defimon-ml'"
    
    echo -e "\n${GREEN}GPU Monitoring:${NC}"
    echo "GPU status: ssh root@$DROPLET_IP 'nvidia-smi'"
    echo "GPU monitoring: ssh root@$DROPLET_IP 'nvtop'"
}

# Main execution
main() {
    print_header "DigitalOcean ML Training Deployment"
    
    check_prerequisites
    create_droplet
    setup_ml_environment
    deploy_ml_code
    setup_data_collection
    start_ml_training
    display_info
    
    print_status "Deployment completed successfully!"
}

# Run main function
main
