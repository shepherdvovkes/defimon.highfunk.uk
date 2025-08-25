#!/bin/bash

# Ethereum Node Startup Script for GCP
# This script sets up and starts a complete Ethereum full node (Lighthouse + Geth)

set -e

echo "=== Starting Ethereum Node Setup ==="
echo "Timestamp: $(date)"
echo "Hostname: $(hostname)"
echo ""

# Update system packages
echo "Updating system packages..."
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
    lsb-release

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

# Set proper permissions
chown -R ubuntu:ubuntu /data /opt/defimon

echo "✅ Directories created"

# Create JWT secret for Geth-Lighthouse communication
echo "Creating JWT secret..."
openssl rand -hex 32 > /opt/defimon/geth-jwtsecret
chmod 600 /opt/defimon/geth-jwtsecret
chown ubuntu:ubuntu /opt/defimon/geth-jwtsecret

echo "✅ JWT secret created"

# Create docker-compose configuration
echo "Creating Docker Compose configuration..."
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
      - /data/ethereum:/root/.ethereum
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
      - /data/lighthouse:/root/.lighthouse
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
      geth:
        condition: service_healthy
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

echo "✅ Docker Compose configuration created"

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

# Recording rules
recording_rules:
  - record: ethereum:sync_status
    expr: ethereum_sync_status
  - record: ethereum:peers_total
    expr: ethereum_peers_total
  - record: ethereum:block_height
    expr: ethereum_block_height
EOF

echo "✅ Prometheus configuration created"

# Create Ethereum alerting rules
echo "Creating Ethereum alerting rules..."
cat > /opt/defimon/ethereum_rules.yml << 'EOF'
groups:
  - name: ethereum_node_alerts
    rules:
      # Sync status alerts
      - alert: EthereumNodeOutOfSync
        expr: ethereum_sync_status == 0
        for: 5m
        labels:
          severity: critical
          service: ethereum
        annotations:
          summary: "Ethereum node is out of sync"
          description: "Ethereum node has been out of sync for more than 5 minutes"

      # Peer count alerts
      - alert: EthereumLowPeerCount
        expr: ethereum_peers_total < 5
        for: 10m
        labels:
          severity: warning
          service: ethereum
        annotations:
          summary: "Ethereum node has low peer count"
          description: "Ethereum node has fewer than 5 peers for more than 10 minutes"

      # Block height alerts
      - alert: EthereumBlockHeightStale
        expr: (time() - ethereum_block_height) > 300
        for: 5m
        labels:
          severity: critical
          service: ethereum
        annotations:
          summary: "Ethereum block height is stale"
          description: "Ethereum node has not received new blocks for more than 5 minutes"

      # Memory usage alerts
      - alert: EthereumHighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.9
        for: 5m
        labels:
          severity: warning
          service: ethereum
        annotations:
          summary: "Ethereum node high memory usage"
          description: "Ethereum node memory usage is above 90%"

      # Disk usage alerts
      - alert: EthereumHighDiskUsage
        expr: (node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes > 0.85
        for: 5m
        labels:
          severity: warning
          service: ethereum
        annotations:
          summary: "Ethereum node high disk usage"
          description: "Ethereum node disk usage is above 85%"

      # Network alerts
      - alert: EthereumNetworkDown
        expr: up{job="geth"} == 0
        for: 1m
        labels:
          severity: critical
          service: ethereum
        annotations:
          summary: "Ethereum node network down"
          description: "Ethereum node is not responding to network requests"
EOF

echo "✅ Alerting rules created"

# Create Grafana datasource
echo "Creating Grafana datasource..."
cat > /opt/defimon/grafana/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

echo "✅ Grafana datasource created"

# Create basic Grafana dashboard
echo "Creating Grafana dashboard..."
cat > /opt/defimon/grafana/dashboards/ethereum-node-dashboard.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Ethereum Node Dashboard",
    "tags": ["ethereum", "node", "gcp"],
    "style": "dark",
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Sync Status",
        "type": "stat",
        "targets": [
          {
            "expr": "ethereum_sync_status",
            "legendFormat": "Sync Status"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "green", "value": 1}
              ]
            }
          }
        }
      },
      {
        "id": 2,
        "title": "Peer Count",
        "type": "stat",
        "targets": [
          {
            "expr": "ethereum_peers_total",
            "legendFormat": "Peers"
          }
        ]
      },
      {
        "id": 3,
        "title": "Block Height",
        "type": "stat",
        "targets": [
          {
            "expr": "ethereum_block_height",
            "legendFormat": "Block Height"
          }
        ]
      },
      {
        "id": 4,
        "title": "CPU Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{container=\"geth\"}[5m])",
            "legendFormat": "Geth CPU Usage"
          },
          {
            "expr": "rate(container_cpu_usage_seconds_total{container=\"lighthouse\"}[5m])",
            "legendFormat": "Lighthouse CPU Usage"
          }
        ],
        "yAxes": [
          {
            "unit": "percentunit",
            "min": 0,
            "max": 1
          }
        ]
      },
      {
        "id": 5,
        "title": "Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "container_memory_usage_bytes{container=\"geth\"} / container_spec_memory_limit_bytes{container=\"geth\"}",
            "legendFormat": "Geth Memory Usage"
          },
          {
            "expr": "container_memory_usage_bytes{container=\"lighthouse\"} / container_spec_memory_limit_bytes{container=\"lighthouse\"}",
            "legendFormat": "Lighthouse Memory Usage"
          }
        ],
        "yAxes": [
          {
            "unit": "percentunit",
            "min": 0,
            "max": 1
          }
        ]
      },
      {
        "id": 6,
        "title": "Network I/O",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(container_network_receive_bytes_total{container=\"geth\"}[5m])",
            "legendFormat": "Geth Network Receive"
          },
          {
            "expr": "rate(container_network_transmit_bytes_total{container=\"geth\"}[5m])",
            "legendFormat": "Geth Network Transmit"
          }
        ],
        "yAxes": [
          {
            "unit": "bytes"
          }
        ]
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
EOF

echo "✅ Grafana dashboard created"

# Set proper ownership for all files
chown -R ubuntu:ubuntu /opt/defimon

# Start services
echo "Starting Ethereum node services..."
cd /opt/defimon

# Pull Docker images first
echo "Pulling Docker images..."
docker-compose pull

# Start services
echo "Starting services with Docker Compose..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# Check service health
echo "Checking service health..."
docker-compose ps

# Show logs for debugging
echo "Recent logs from services:"
docker-compose logs --tail=20

echo ""
echo "=== Ethereum Node Setup Complete! ==="
echo "Services are now running:"
echo "  - Geth (Ethereum execution client): http://localhost:8545"
echo "  - Lighthouse (Consensus client): http://localhost:5052"
echo "  - Prometheus (Monitoring): http://localhost:9090"
echo "  - Grafana (Dashboards): http://localhost:3000 (admin/admin)"
echo "  - Node Exporter (System metrics): http://localhost:9100"
echo ""
echo "To view logs: docker-compose logs -f [service_name]"
echo "To restart services: docker-compose restart"
echo "To stop services: docker-compose down"
echo ""
echo "Setup completed at: $(date)"
