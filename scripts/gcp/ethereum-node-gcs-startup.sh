#!/bin/bash

# Ethereum Node Startup Script for GCP with Google Cloud Storage
# This script sets up an Ethereum full node using GCS for data storage

set -e

echo "=== Starting Ethereum Node Setup with GCS Storage ==="
echo "Timestamp: $(date)"
echo "Hostname: $(hostname)"
echo ""

# Update system packages
echo "Updating system packages..."
apt-get update

# Add Google Cloud Storage FUSE repository
echo "deb https://packages.cloud.google.com/apt gcsfuse-$(lsb_release -c -s) main" | tee /etc/apt/sources.list.d/gcsfuse.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

# Update package list and install packages
apt-get update
apt-get install -y \
    docker.io \
    docker-compose \
    jq \
    curl \
    wget \
    htop \
    iotop \
    nethogs \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    gcsfuse \
    fuse

echo "✅ System packages installed"

# Start and enable Docker service
echo "Starting Docker service..."
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Wait for Docker to be ready
echo "Waiting for Docker to be ready..."
until docker info > /dev/null 2>&1; do
    echo "Waiting for Docker..."
    sleep 2
done
echo "✅ Docker is ready"

# Create necessary directories
echo "Creating directories..."
mkdir -p /data/ethereum
mkdir -p /data/lighthouse
mkdir -p /opt/defimon
mkdir -p /opt/defimon/grafana/dashboards
mkdir -p /opt/defimon/grafana/datasources
mkdir -p /mnt/gcs-ethereum
mkdir -p /mnt/gcs-lighthouse

# Set proper permissions
chown -R ubuntu:ubuntu /data /opt/defimon /mnt

echo "✅ Directories created"

# Mount Google Cloud Storage buckets
echo "Mounting Google Cloud Storage buckets..."
echo "defimon-ethereum-data-bucket /mnt/gcs-ethereum gcsfuse rw,user,uid=1000,gid=1000,file_mode=600,dir_mode=700,key_file=/opt/defimon/gcp-key.json" >> /etc/fstab
echo "defimon-ethereum-backups /mnt/gcs-backups gcsfuse rw,user,uid=1000,gid=1000,file_mode=600,dir_mode=700,key_file=/opt/defimon/gcp-key.json" >> /etc/fstab

# Create JWT secret for Geth-Lighthouse communication
echo "Creating JWT secret..."
openssl rand -hex 32 | tr -d '\n' > /opt/defimon/geth-jwtsecret
chmod 600 /opt/defimon/geth-jwtsecret
chown ubuntu:ubuntu /opt/defimon/geth-jwtsecret

echo "✅ JWT secret created"

# Create docker-compose configuration with GCS storage
echo "Creating Docker Compose configuration with GCS storage..."
cat > /opt/defimon/docker-compose.yml << 'EOF'
version: '3.8'

services:
  geth:
    image: ethereum/client-go:latest
    container_name: geth
    restart: unless-stopped
    ports:
      - "8545:8545"
      - "8546:8546"
      - "30303:30303"
      - "30303:30303/udp"
    volumes:
      - /mnt/gcs-ethereum:/root/.ethereum
      - /opt/defimon/geth-jwtsecret:/root/.ethereum/jwtsecret
    command: >
      --datadir /root/.ethereum
      --http
      --http.addr 0.0.0.0
      --http.port 8545
      --http.corsdomain "*"
      --http.vhosts "*"
      --ws
      --ws.addr 0.0.0.0
      --ws.port 8546
      --ws.origins "*"
      --authrpc.addr 0.0.0.0
      --authrpc.port 8551
      --authrpc.vhosts "*"
      --authrpc.jwtsecret /root/.ethereum/jwtsecret
      --syncmode snap
      --cache 2048
      --maxpeers 50
      --metrics
      --metrics.addr 0.0.0.0
      --metrics.port 6060
      --pprof
      --pprof.addr 0.0.0.0
      --pprof.port 6061
      --verbosity 3
    environment:
      - TZ=UTC
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8545"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  lighthouse:
    image: sigp/lighthouse:latest
    container_name: lighthouse
    restart: unless-stopped
    ports:
      - "5052:5052"
      - "9000:9000"
      - "9000:9000/udp"
    volumes:
      - /mnt/gcs-lighthouse:/root/.lighthouse
      - /opt/defimon/geth-jwtsecret:/root/.lighthouse/jwtsecret
    command: >
      lighthouse beacon_node
      --datadir /root/.lighthouse
      --network mainnet
      --http
      --http-address 0.0.0.0
      --http-port 5052
      --execution-jwt /root/.lighthouse/jwtsecret
      --execution-endpoint http://geth:8551
      --checkpoint-sync-url https://sync-mainnet.beaconcha.in
      --metrics
      --validator-monitor-auto
      --target-peers 50
      --max-skip-slots 5
    environment:
      - TZ=UTC
    depends_on:
      - geth
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5052/eth/v1/node/syncing"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 120s

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - /opt/defimon/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
    environment:
      - TZ=UTC
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:9090/-/healthy"]
      interval: 30s
      timeout: 10s
      retries: 3

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
      GF_INSTALL_PLUGINS: grafana-clock-panel,grafana-simple-json-datasource
      GF_SERVER_ROOT_URL: http://localhost:3000
      GF_USERS_ALLOW_SIGN_UP: "false"
      TZ: UTC
    volumes:
      - grafana_data:/var/lib/grafana
      - /opt/defimon/grafana/dashboards:/etc/grafana/provisioning/dashboards
      - /opt/defimon/grafana/datasources:/etc/grafana/provisioning/datasources
    depends_on:
      prometheus:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:3000/api/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    command:
      - '--path.rootfs=/host'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - /:/host:ro,rslave
    environment:
      - TZ=UTC
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:9100/-/healthy"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  prometheus_data:
  grafana_data:

networks:
  default:
    name: defimon-network
EOF

echo "✅ Docker Compose configuration created with GCS storage"

# Create Prometheus configuration
echo "Creating Prometheus configuration..."
cat > /opt/defimon/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'gcp-ethereum-node'
    job: 'ethereum-node'

rule_files:
  - "ethereum_rules.yml"

scrape_configs:
  # Ethereum Node Metrics
  - job_name: 'geth'
    static_configs:
      - targets: ['geth:6060']
    metrics_path: /debug/metrics/prometheus
    scrape_interval: 15s
    honor_labels: true

  - job_name: 'lighthouse'
    static_configs:
      - targets: ['lighthouse:5052']
    metrics_path: /metrics
    scrape_interval: 15s
    honor_labels: true

  # Node Exporter
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
    scrape_interval: 30s

  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
    scrape_interval: 30s

# Alerting configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - localhost:9093
EOF

echo "✅ Prometheus configuration created"

# Create Ethereum alerting rules
echo "Creating Ethereum alerting rules..."
cat > /opt/defimon/ethereum_rules.yml << 'EOF'
groups:
  - name: ethereum
    rules:
      - alert: GethDown
        expr: up{job="geth"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Geth execution client is down"
          description: "Geth has been down for more than 1 minute"

      - alert: LighthouseDown
        expr: up{job="lighthouse"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Lighthouse consensus client is down"
          description: "Lighthouse has been down for more than 1 minute"

      - alert: HighPeerCount
        expr: ethereum_peers_total > 100
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High peer count detected"
          description: "Ethereum node has more than 100 peers"

      - alert: LowPeerCount
        expr: ethereum_peers_total < 5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Low peer count detected"
          description: "Ethereum node has fewer than 5 peers"
EOF

echo "✅ Alerting rules created"

# Create Grafana datasource
echo "Creating Grafana datasource..."
mkdir -p /opt/defimon/grafana/datasources
cat > /opt/defimon/grafana/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

echo "✅ Grafana datasource created"

# Create Grafana dashboard
echo "Creating Grafana dashboard..."
mkdir -p /opt/defimon/grafana/dashboards
cat > /opt/defimon/grafana/dashboards/ethereum-node.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Ethereum Node Dashboard",
    "tags": ["ethereum", "blockchain"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Geth Status",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=\"geth\"}",
            "legendFormat": "Geth"
          }
        ]
      },
      {
        "id": 2,
        "title": "Lighthouse Status",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=\"lighthouse\"}",
            "legendFormat": "Lighthouse"
          }
        ]
      }
    ]
  }
}
EOF

echo "✅ Grafana dashboard created"

# Start Ethereum node services
echo "Starting Ethereum node services with GCS storage..."

# First, mount the GCS buckets
echo "Mounting GCS buckets..."
gcsfuse --implicit-dirs defimon-ethereum-data-bucket /mnt/gcs-ethereum
gcsfuse --implicit-dirs defimon-ethereum-backups /mnt/gcs-backups

# Set proper permissions for mounted directories
chown -R ubuntu:ubuntu /mnt/gcs-ethereum /mnt/gcs-lighthouse

echo "✅ GCS buckets mounted"

# Start services
cd /opt/defimon
docker-compose up -d

echo "✅ Ethereum node services started with GCS storage"

# Show final status
echo ""
echo "=== Ethereum Node Setup Complete ==="
echo "External IP: $(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H 'Metadata-Flavor: Google')"
echo "Geth RPC: http://localhost:8545"
echo "Lighthouse API: http://localhost:5052"
echo "Prometheus: http://localhost:9090"
echo "Grafana: http://localhost:3000 (admin/admin)"
echo ""
echo "Data is now stored in Google Cloud Storage:"
echo "- Ethereum data: gs://defimon-ethereum-data-bucket"
echo "- Backups: gs://defimon-ethereum-backups"
echo ""
echo "Check logs with: docker-compose logs -f"
echo "Stop with: docker-compose down"
