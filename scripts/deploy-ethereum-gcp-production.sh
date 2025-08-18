#!/bin/bash

# DEFIMON Ethereum Nodes GCP Production Deployment Script
# This script deploys Ethereum nodes (Geth + Lighthouse) to Google Cloud Platform
# with production-grade NGINX reverse proxy and Let's Encrypt SSL certificates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/.env"

# Load configuration
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: .env file not found. Please copy env.example to .env and configure it.${NC}"
    exit 1
fi

source "$CONFIG_FILE"

# Function to print colored output
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists gcloud; then
        print_error "Google Cloud SDK is not installed. Please install it first:"
        echo "https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Authenticate with Google Cloud
authenticate_gcp() {
    print_status "Authenticating with Google Cloud..."
    
    gcloud auth login
    gcloud config set project "$GOOGLE_CLOUD_PROJECT_ID"
    gcloud config set compute/region "$GOOGLE_CLOUD_REGION"
    gcloud config set compute/zone "$GOOGLE_CLOUD_ZONE"
    
    print_success "Authenticated with Google Cloud"
}

# Enable required APIs
enable_apis() {
    print_status "Enabling required Google Cloud APIs..."
    
    gcloud services enable \
        compute.googleapis.com \
        cloudbuild.googleapis.com \
        cloudresourcemanager.googleapis.com \
        storage-component.googleapis.com \
        monitoring.googleapis.com \
        logging.googleapis.com \
        secretmanager.googleapis.com
    
    print_success "APIs enabled"
}

# Create production VM instance
create_production_vm() {
    print_status "Creating production VM instance for Ethereum nodes..."
    
    # Create VM instance with production specs
    gcloud compute instances create ethereum-production \
        --zone="$GOOGLE_CLOUD_ZONE" \
        --machine-type=e2-standard-4 \
        --min-cpu-platform="Intel Haswell" \
        --image-family=ubuntu-2004-lts \
        --image-project=ubuntu-os-cloud \
        --boot-disk-size=100GB \
        --boot-disk-type=pd-ssd \
        --boot-disk-device-name=ethereum-boot \
        --create-disk=name=ethereum-data,size=2048GB,type=pd-standard,device-name=ethereum-data \
        --tags=ethereum-node,http-server,https-server \
        --network-interface=network-tier=PREMIUM,subnet=default \
        --metadata=startup-script='#! /bin/bash
            # Update system
            apt-get update
            apt-get install -y docker.io docker-compose nginx certbot python3-certbot-nginx
            
            # Start Docker service
            systemctl start docker
            systemctl enable docker
            
            # Mount additional data disk
            echo "Mounting additional data disk..."
            lsblk
            # Find the additional disk (should be sdb)
            if [ -b /dev/sdb ]; then
                # Format disk if not already formatted
                if ! blkid /dev/sdb; then
                    mkfs.ext4 /dev/sdb
                fi
                # Create mount point and mount
                mkdir -p /mnt/ethereum-data
                echo "/dev/sdb /mnt/ethereum-data ext4 defaults 0 2" >> /etc/fstab
                mount /mnt/ethereum-data
                echo "Data disk mounted successfully"
            else
                echo "Warning: Additional data disk not found"
            fi
            
            # Create directories
            mkdir -p /opt/defimon/{geth-data,lighthouse-data,ssl,logs,grafana,dashboards,datasources}
            mkdir -p /mnt/ethereum-data/{geth,lighthouse}
            mkdir -p /mnt/gcs-ethereum /mnt/gcs-lighthouse
            
            # Set permissions
            chown -R 1000:1000 /opt/defimon/geth-data
            chown -R 1000:1000 /opt/defimon/lighthouse-data
            chown -R 1000:1000 /mnt/ethereum-data
            
            # Generate JWT secret (same for both clients)
            openssl rand -hex 32 > /opt/defimon/jwtsecret.hex
            openssl rand -hex 32 > /opt/defimon/jwtsecret.raw
            chmod 600 /opt/defimon/jwtsecret.*
            
            # Create production docker-compose
            cat > /opt/defimon/docker-compose.yml << "EOF"
            version: "3.8"
            services:
              nginx:
                image: nginx:alpine
                container_name: nginx-proxy
                restart: unless-stopped
                ports:
                  - "80:80"
                  - "443:443"
                volumes:
                  - ./nginx.conf:/etc/nginx/nginx.conf:ro
                  - ./ssl:/etc/nginx/ssl:ro
                  - ./logs:/var/log/nginx
                depends_on:
                  - geth
                  - lighthouse
                  - grafana
                healthcheck:
                  test: ["CMD", "curl", "-f", "http://localhost/health"]
                  interval: 30s
                  timeout: 10s
                  retries: 3
                  start_period: 60s
                networks:
                  - defimon-network
              
              geth:
                image: ethereum/client-go:latest
                container_name: geth
                restart: unless-stopped
                expose:
                  - "8545"
                  - "8546"
                  - "8551"
                  - "30303"
                volumes:
                  - /mnt/ethereum-data/geth:/root/.ethereum
                  - /opt/defimon/jwtsecret.raw:/root/.ethereum/jwtsecret:ro
                command: >
                  --datadir /root/.ethereum
                  --http
                  --http.addr 0.0.0.0
                  --http.port 8545
                  --http.corsdomain "https://defimon.highfunk.uk"
                  --http.vhosts "defimon.highfunk.uk"
                  --ws
                  --ws.addr 0.0.0.0
                  --ws.port 8546
                  --ws.origins "https://defimon.highfunk.uk"
                  --authrpc.addr 0.0.0.0
                  --authrpc.port 8551
                  --authrpc.vhosts "defimon.highfunk.uk"
                  --authrpc.jwtsecret /root/.ethereum/jwtsecret
                  --syncmode snap
                  --cache 4096
                  --maxpeers 100
                  --snapshot.verify
                  --snapshot.verification.workers 4
                  --snapshot.verification.rate 100
                  --metrics
                  --metrics.addr 0.0.0.0
                  --metrics.port 6060
                  --metrics.expensive
                  --metrics.influxdb
                  --metrics.influxdb.endpoint "http://prometheus:9090"
                  --pprof
                  --pprof.addr 0.0.0.0
                  --pprof.port 6061
                  --pprof.memprofilerate 1
                  --pprof.blockprofilerate 1
                  --verbosity 3
                  --txpool.globalslots 4096
                  --txpool.globalqueue 1024
                  --txpool.accountslots 16
                  --txpool.accountqueue 64
                  --txpool.lifetime 3h
                  --max-tx-fee 1000000000000000000
                  --rpc.allow-unprotected-txs
                  --rpc.gascap 50000000
                  --rpc.txfeecap 1000000000000000000
                  --http.api eth,net,web3,debug,txpool,personal,engine,admin,miner
                  --ws.api eth,net,web3,debug,txpool,personal,engine,admin
                  --authrpc.jwtsecret /root/.ethereum/jwtsecret
                  --discovery.port 30303
                  --discovery.v5
                  --nat extip:$(curl -s ifconfig.me)
                  --discovery.udp.port 30303
                  --discovery.udp.v5
                  --discovery.udp.ratelimit 5
                environment:
                  - TZ=UTC
                healthcheck:
                  test: ["CMD", "curl", "-f", "http://localhost:8545"]
                  interval: 30s
                  timeout: 10s
                  retries: 3
                  start_period: 60s
                networks:
                  - defimon-network
              
              lighthouse:
                image: sigp/lighthouse:latest
                container_name: lighthouse
                restart: unless-stopped
                expose:
                  - "5052"
                  - "9000"
                volumes:
                  - /mnt/ethereum-data/lighthouse:/root/.lighthouse
                  - /opt/defimon/jwtsecret.hex:/root/.lighthouse/jwtsecret:ro
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
                  --checkpoint-sync-timeout 300
                  --checkpoint-sync-verify
                  --metrics
                  --sync-committee-subnet-count 4
                  --attestation-cache-size 16384
                  --block-cache-size 16384
                  --state-cache-size 16384
                  --metrics-address 0.0.0.0
                  --metrics-port 5054
                  --metrics-bucket-size 64
                  --metrics-bucket-count 10
                  --metrics-address 0.0.0.0
                  --metrics-port 5054
                  --target-peers 100
                  --max-skip-slots 5
                  --sync-committee-subnet-count 4
                  --attestation-cache-size 16384
                  --block-cache-size 16384
                  --state-cache-size 16384
                  --disable-deposit-contract-sync
                  --validator-monitor-auto
                  --validator-monitor-pubkeys
                  --validator-monitor-indices
                  --validator-monitor-auto
                  --validator-monitor-pubkeys
                  --validator-monitor-indices
                  --http-allow-origin "https://defimon.highfunk.uk"
                  --http-allow-sync-checked
                  --enable-private-discovery
                  --http-allow-credentials
                  --http-allow-methods "GET,POST,OPTIONS"
                  --http-allow-headers "Content-Type,Authorization"
                  --disable-packet-filter
                  --disable-http
                  --disable-http-ssz
                  --disable-http-ssz-snappy
                  --network-dir /root/.lighthouse/network
                  --discovery-port 9000
                  --discovery-address 0.0.0.0
                  --discovery-udp-port 9000
                  --discovery-udp-address 0.0.0.0
                  --discovery-udp-v5
                  --discovery-udp-ratelimit 5
                  --http-allow-sync-checked
                  --http-allow-origin "https://defimon.highfunk.uk"
                  --http-allow-credentials
                  --http-allow-methods "GET,POST,OPTIONS"
                  --http-allow-headers "Content-Type,Authorization"
                  --http-allow-credentials
                  --http-allow-sync-checked
                  --http-allow-origin "https://defimon.highfunk.uk"
                  --logfile /root/.lighthouse/beacon.log
                  --logfile-max-size 100
                  --logfile-max-age 30
                  --log-level info
                  --log-format json
                environment:
                  - TZ=UTC
                healthcheck:
                  test: ["CMD", "curl", "-f", "http://localhost:5052/eth/v1/node/health"]
                  interval: 30s
                  timeout: 10s
                  retries: 3
                  start_period: 60s
                depends_on:
                  - geth
                networks:
                  - defimon-network
              
              prometheus:
                image: prom/prometheus:latest
                container_name: prometheus
                restart: unless-stopped
                expose:
                  - "9090"
                volumes:
                  - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
                  - prometheus_data:/prometheus
                command:
                  - "--config.file=/etc/prometheus/prometheus.yml"
                  - "--storage.tsdb.path=/prometheus"
                  - "--web.console.libraries=/etc/prometheus/console_libraries"
                  - "--web.console.templates=/etc/prometheus/consoles"
                  - "--storage.tsdb.retention.time=720h"
                  - "--web.enable-lifecycle"
                  - "--web.enable-admin-api"
                environment:
                  - TZ=UTC
                healthcheck:
                  test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:9090/-/healthy"]
                  interval: 30s
                  timeout: 10s
                  retries: 3
                  start_period: 60s
                networks:
                  - defimon-network
              
              grafana:
                image: grafana/grafana:latest
                container_name: grafana
                restart: unless-stopped
                expose:
                  - "3000"
                environment:
                  GF_SECURITY_ADMIN_PASSWORD: admin123
                  GF_INSTALL_PLUGINS: grafana-clock-panel,grafana-simple-json-datasource
                  GF_SERVER_ROOT_URL: https://defimon.highfunk.uk
                  GF_USERS_ALLOW_SIGN_UP: "false"
                  TZ: UTC
                volumes:
                  - grafana_data:/var/lib/grafana
                  - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
                  - ./grafana/datasources:/etc/grafana/provisioning/datasources
                depends_on:
                  - prometheus
                healthcheck:
                  test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
                  interval: 30s
                  timeout: 10s
                  retries: 3
                  start_period: 60s
                networks:
                  - defimon-network
              
              node-exporter:
                image: prom/node-exporter:latest
                container_name: node-exporter
                restart: unless-stopped
                expose:
                  - "9100"
                command:
                  - "--path.rootfs=/host"
                  - "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)"
                volumes:
                  - /:/host:ro,rslave
                environment:
                  - TZ=UTC
                healthcheck:
                  test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:9100/metrics"]
                  interval: 30s
                  timeout: 10s
                  retries: 3
                  start_period: 60s
                networks:
                  - defimon-network
            
            volumes:
              prometheus_data:
              grafana_data:
            
            networks:
              defimon-network:
                driver: bridge
            EOF
            
            # Create production NGINX config
            cat > /opt/defimon/nginx.conf << "EOF"
            events {
                worker_connections 2048;
                use epoll;
                multi_accept on;
            }
            
            http {
                include       /etc/nginx/mime.types;
                default_type  application/octet-stream;
                
                # Logging
                log_format main "$remote_addr - $remote_user [$time_local] \"$request\" "
                                "$status $body_bytes_sent \"$http_referer\" "
                                "\"$http_user_agent\" \"$http_x_forwarded_for\"";
                
                access_log /var/log/nginx/access.log main;
                error_log /var/log/nginx/error.log;
                
                # Basic settings
                sendfile on;
                tcp_nopush on;
                tcp_nodelay on;
                keepalive_timeout 65;
                types_hash_max_size 2048;
                client_max_body_size 100M;
                
                # Gzip compression
                gzip on;
                gzip_vary on;
                gzip_min_length 1024;
                gzip_proxied any;
                gzip_comp_level 6;
                gzip_types
                    text/plain
                    text/css
                    text/xml
                    text/javascript
                    application/json
                    application/javascript
                    application/xml+rss
                    application/atom+xml
                    image/svg+xml;
                
                # Rate limiting
                limit_req_zone $binary_remote_addr zone=api:10m rate=20r/s;
                limit_req_zone $binary_remote_addr zone=login:10m rate=2r/s;
                limit_req_zone $binary_remote_addr zone=metrics:10m rate=5r/s;
                
                # Upstream servers
                upstream geth {
                    server geth:8545;
                    keepalive 32;
                }
                
                upstream lighthouse {
                    server lighthouse:5052;
                    keepalive 32;
                }
                
                upstream grafana {
                    server grafana:3000;
                    keepalive 32;
                }
                
                upstream prometheus {
                    server prometheus:9090;
                    keepalive 32;
                }
                
                # HTTP to HTTPS redirect
                server {
                    listen 80;
                    server_name defimon.highfunk.uk;
                    return 301 https://$server_name$request_uri;
                }
                
                # Main HTTPS server
                server {
                    listen 443 ssl http2;
                    server_name defimon.highfunk.uk;
                    
                    # SSL configuration
                    ssl_certificate /etc/nginx/ssl/cert.pem;
                    ssl_certificate_key /etc/nginx/ssl/key.pem;
                    ssl_protocols TLSv1.2 TLSv1.3;
                    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
                    ssl_prefer_server_ciphers off;
                    ssl_session_cache shared:SSL:10m;
                    ssl_session_timeout 10m;
                    ssl_stapling on;
                    ssl_stapling_verify on;
                    
                    # Security headers
                    add_header X-Frame-Options DENY;
                    add_header X-Content-Type-Options nosniff;
                    add_header X-XSS-Protection "1; mode=block";
                    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
                    add_header Referrer-Policy "strict-origin-when-cross-origin";
                    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';";
                    
                    # Root location
                    location / {
                        proxy_pass http://grafana;
                        proxy_set_header Host $host;
                        proxy_set_header X-Real-IP $remote_addr;
                        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                        proxy_set_header X-Forwarded-Proto $scheme;
                        proxy_redirect off;
                        proxy_http_version 1.1;
                        proxy_set_header Connection "";
                        proxy_buffering off;
                        proxy_read_timeout 300s;
                        proxy_connect_timeout 75s;
                    }
                    
                    # Ethereum RPC API
                    location /eth/ {
                        limit_req zone=api burst=50 nodelay;
                        proxy_pass http://geth/;
                        proxy_set_header Host $host;
                        proxy_set_header X-Real-IP $remote_addr;
                        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                        proxy_set_header X-Forwarded-Proto $scheme;
                        proxy_redirect off;
                        proxy_http_version 1.1;
                        proxy_set_header Connection "";
                        proxy_buffering off;
                        proxy_read_timeout 300s;
                        proxy_connect_timeout 75s;
                        
                        # CORS headers for Ethereum API
                        add_header Access-Control-Allow-Origin *;
                        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
                        add_header Access-Control-Allow-Headers "Content-Type, Authorization";
                    }
                    
                    # Lighthouse Beacon API
                    location /beacon/ {
                        limit_req zone=api burst=50 nodelay;
                        proxy_pass http://lighthouse/;
                        proxy_set_header Host $host;
                        proxy_set_header X-Real-IP $remote_addr;
                        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                        proxy_set_header X-Forwarded-Proto $scheme;
                        proxy_redirect off;
                        proxy_http_version 1.1;
                        proxy_set_header Connection "";
                        proxy_buffering off;
                        proxy_read_timeout 300s;
                        proxy_connect_timeout 75s;
                    }
                    
                    # Prometheus metrics (protected)
                    location /metrics/ {
                        limit_req zone=metrics burst=10 nodelay;
                        auth_basic "Metrics Access";
                        auth_basic_user_file /etc/nginx/.htpasswd;
                        
                        proxy_pass http://prometheus/;
                        proxy_set_header Host $host;
                        proxy_set_header X-Real-IP $remote_addr;
                        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                        proxy_set_header X-Forwarded-Proto $scheme;
                        proxy_redirect off;
                        proxy_http_version 1.1;
                        proxy_set_header Connection "";
                        proxy_buffering off;
                        proxy_read_timeout 300s;
                        proxy_connect_timeout 75s;
                    }
                    
                    # Health check endpoint
                    location /health {
                        access_log off;
                        return 200 "healthy\n";
                        add_header Content-Type text/plain;
                    }
                    
                    # Status endpoint
                    location /status {
                        access_log off;
                        return 200 "Ethereum Node Status: OK\n";
                        add_header Content-Type text/plain;
                    }
                }
            }
            EOF
            
            # Create Prometheus config
            cat > /opt/defimon/prometheus.yml << "EOF"
            global:
              scrape_interval: 15s
              evaluation_interval: 15s
            
            rule_files:
              - "alert_rules.yml"
            
            alerting:
              alertmanagers:
                - static_configs:
                    - targets: []
            
            scrape_configs:
              - job_name: "prometheus"
                static_configs:
                  - targets: ["localhost:9090"]
            
              - job_name: "geth"
                static_configs:
                  - targets: ["geth:6060"]
                metrics_path: /debug/metrics/prometheus
            
              - job_name: "lighthouse"
                static_configs:
                  - targets: ["lighthouse:5052"]
                metrics_path: /metrics
            
              - job_name: "node-exporter"
                static_configs:
                  - targets: ["node-exporter:9100"]
            
              - job_name: "nginx"
                static_configs:
                  - targets: ["nginx:80"]
                metrics_path: /metrics
            EOF
            
            # Create basic auth for metrics
            echo "admin:$(openssl passwd -apr1 admin123)" > /opt/defimon/.htpasswd
            
            # Start services
            cd /opt/defimon
            docker-compose up -d
            
            # Wait for services to be ready
            sleep 30
            
            # Setup Let\'s Encrypt certificate
            certbot --nginx -d defimon.highfunk.uk --non-interactive --agree-tos --email admin@highfunk.uk
            
            # Restart NGINX to apply SSL
            docker restart nginx-proxy
            
            # Setup automatic renewal
            echo "0 12 * * * /usr/bin/certbot renew --quiet" | crontab -'
    
    print_success "Production VM instance created"
}

# Setup firewall rules
setup_firewall() {
    print_status "Setting up firewall rules..."
    
    # Create firewall rule for Ethereum node
    gcloud compute firewall-rules create ethereum-node \
        --direction=INGRESS \
        --priority=1000 \
        --network=default \
        --action=ALLOW \
        --rules=tcp:80,tcp:443,tcp:30303,udp:30303 \
        --source-ranges=0.0.0.0/0 \
        --target-tags=ethereum-node
    
    print_success "Firewall rules configured"
}

# Setup monitoring and alerting
setup_monitoring() {
    print_status "Setting up monitoring and alerting..."
    
    # Create uptime check
    gcloud monitoring uptime-checks create http ethereum-node-health \
        --display-name="Ethereum Node Health Check" \
        --uri="https://defimon.highfunk.uk/health" \
        --period=60s \
        --timeout=10s
    
    # Create alerting policy
    gcloud alpha monitoring policies create \
        --policy-from-file="$PROJECT_ROOT/infrastructure/monitoring/alert_rules.yml"
    
    print_success "Monitoring and alerting configured"
}

# Setup backup and disaster recovery
setup_backup() {
    print_status "Setting up backup and disaster recovery..."
    
    # Create Cloud Storage bucket for backups
    gsutil mb -l "$GOOGLE_CLOUD_REGION" "gs://$GOOGLE_CLOUD_PROJECT_ID-ethereum-backups"
    
    # Create backup script
    cat > /tmp/backup-ethereum.sh << 'EOF'
#!/bin/bash
# Backup Ethereum node data
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_BUCKET="gs://$GOOGLE_CLOUD_PROJECT_ID-ethereum-backups"

# Stop services
docker-compose stop

# Create backup
tar -czf /tmp/ethereum-backup-$DATE.tar.gz -C /mnt/ethereum-data geth lighthouse

# Upload to Cloud Storage
gsutil cp /tmp/ethereum-backup-$DATE.tar.gz $BACKUP_BUCKET/

# Cleanup
rm /tmp/ethereum-backup-$DATE.tar.gz

# Restart services
docker-compose start
EOF
    
    # Upload backup script to VM
    gcloud compute scp /tmp/backup-ethereum.sh ethereum-production:/opt/defimon/ --zone="$GOOGLE_CLOUD_ZONE"
    
    # Setup daily backup cron job
    gcloud compute ssh ethereum-production --zone="$GOOGLE_CLOUD_ZONE" --command="
        chmod +x /opt/defimon/backup-ethereum.sh
        echo '0 2 * * * /opt/defimon/backup-ethereum.sh' | crontab -
    "
    
    print_success "Backup and disaster recovery configured"
}

# Get VM external IP
get_vm_ip() {
    print_status "Getting VM external IP..."
    
    VM_IP=$(gcloud compute instances describe ethereum-production \
        --zone="$GOOGLE_CLOUD_ZONE" \
        --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
    
    print_success "VM external IP: $VM_IP"
    echo "$VM_IP" > /tmp/ethereum-vm-ip.txt
}

# Main deployment function
main() {
    print_status "Starting DEFIMON Ethereum nodes GCP production deployment..."
    
    check_prerequisites
    authenticate_gcp
    enable_apis
    create_production_vm
    setup_firewall
    setup_monitoring
    setup_backup
    get_vm_ip
    
    print_success "DEFIMON Ethereum nodes production deployment completed successfully!"
    print_status "Your Ethereum nodes are now running on Google Cloud Platform"
    print_status "VM IP: $(cat /tmp/ethereum-vm-ip.txt)"
    print_status "Dashboard: https://defimon.highfunk.uk"
    print_status "Ethereum RPC: https://defimon.highfunk.uk/eth/"
    print_status "Beacon API: https://defimon.highfunk.uk/beacon/"
    print_status "Metrics: https://defimon.highfunk.uk/metrics/ (admin/admin123)"
    
    # Cleanup
    rm -f /tmp/ethereum-vm-ip.txt /tmp/backup-ethereum.sh
    
    print_warning "Remember to:"
    print_warning "1. Update your DNS records to point to the VM IP"
    print_warning "2. Monitor the initial sync progress"
    print_warning "3. Set up monitoring alerts"
    print_warning "4. Test backup and restore procedures"
}

# Run main function
main "$@"
