#!/bin/bash

# DEFIMON Unified Data Server Deployment Script
# This script deploys the unified data collection and API server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_status() {
    echo -e "${BLUE}→ $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root"
    exit 1
fi

# Configuration
SERVER_NAME="unified-data-server"
SERVER_HOME="/home/vovkes/$SERVER_NAME"
SERVICE_NAME="defimon-unified-data-server"
API_PORT="8002"

print_header "DEFIMON Unified Data Server Deployment"
echo "============================================="

# Check system requirements
print_status "Checking system requirements..."

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    print_error "Rust/Cargo is not installed. Please install Rust first:"
    echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi

# Check if PostgreSQL is running
if ! pg_isready -h localhost -p 5432 &> /dev/null; then
    print_warning "PostgreSQL is not running. Please start PostgreSQL first."
    exit 1
fi

print_success "System requirements verified"

# Create server directory
print_status "Creating server directory..."
mkdir -p "$SERVER_HOME"
cd "$SERVER_HOME"

# Copy server files
print_status "Copying server files..."
cp -r /home/vovkes/defimon.highfunk.uk/services/unified-data-server/* .

# Build the server
print_status "Building unified data server..."
cargo build --release

if [ $? -ne 0 ]; then
    print_error "Failed to build the server"
    exit 1
fi

print_success "Server built successfully"

# Create environment configuration
print_status "Creating environment configuration..."

cat > .env << 'EOF'
# Database Configuration
DATABASE_URL=postgresql://postgres:password@localhost:5432/defi_analytics

# API Configuration
API_PORT=8002

# Ethereum Configuration
ETHEREUM_SYNC_ENABLED=true
ETHEREUM_NODE_URL=http://localhost:8545
ETHEREUM_SYNC_INTERVAL=12

# L2 Networks Configuration
L2_SYNC_ENABLED=true
L2_NETWORKS=polygon,arbitrum,optimism,base,zksync,linea,scroll
L2_SYNC_INTERVAL=10
L2_BATCH_SIZE=50
L2_MAX_CONCURRENT_REQUESTS=8
L2_PRIORITY_THRESHOLD=5

# Cosmos Networks Configuration
COSMOS_SYNC_ENABLED=true
COSMOS_NETWORKS=cosmos,osmosis,injective,celestia,sei,neutron
COSMOS_SYNC_INTERVAL=15
COSMOS_BATCH_SIZE=50
COSMOS_MAX_CONCURRENT_REQUESTS=8
COSMOS_DATA_RETENTION_DAYS=90
COSMOS_PRIORITY_THRESHOLD=5

# Polkadot Networks Configuration
POLKADOT_SYNC_ENABLED=true
POLKADOT_NETWORKS=polkadot,kusama,moonbeam,moonriver,astar,acala
POLKADOT_SYNC_INTERVAL=10
POLKADOT_BATCH_SIZE=20
POLKADOT_MAX_CONCURRENT_REQUESTS=5
POLKADOT_DATA_RETENTION_DAYS=90
POLKADOT_PRIORITY_THRESHOLD=5

# Price Oracle Configuration
PRICE_SYNC_ENABLED=true
PRICE_SYNC_INTERVAL=60
PRICE_ORACLE_SOURCES=coingecko,coinmarketcap,binance

# Monitoring Configuration
METRICS_ENABLED=true
LOG_LEVEL=info
EOF

print_success "Environment configuration created"

# Create systemd service
print_status "Creating systemd service..."

sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
[Unit]
Description=DEFIMON Unified Data Server
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=vovkes
WorkingDirectory=$SERVER_HOME
Environment=RUST_LOG=info
ExecStart=$SERVER_HOME/target/release/unified-data-server
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME

print_success "Systemd service created and enabled"

# Create monitoring script
print_status "Creating monitoring script..."

cat > monitor.sh << 'EOF'
#!/bin/bash

# DEFIMON Unified Data Server Monitor

echo "=== DEFIMON Unified Data Server Status ==="
echo ""

# Check service status
echo "=== Service Status ==="
if systemctl is-active --quiet defimon-unified-data-server; then
    echo "✓ Service is running"
else
    echo "✗ Service is not running"
fi

# Check API endpoint
echo ""
echo "=== API Health Check ==="
if curl -s http://localhost:8002/health > /dev/null; then
    echo "✓ API is responding"
else
    echo "✗ API is not responding"
fi

# Check database connection
echo ""
echo "=== Database Connection ==="
if pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
    echo "✓ Database is accessible"
else
    echo "✗ Database is not accessible"
fi

# Check recent logs
echo ""
echo "=== Recent Logs ==="
journalctl -u defimon-unified-data-server --no-pager -n 10

# Check resource usage
echo ""
echo "=== Resource Usage ==="
ps aux | grep unified-data-server | grep -v grep || echo "Process not found"

# Check network connections
echo ""
echo "=== Network Connections ==="
netstat -tlnp | grep :8002 || echo "No connections on port 8002"
EOF

chmod +x monitor.sh
print_success "Monitoring script created"

# Start the service
print_status "Starting unified data server..."
sudo systemctl start $SERVICE_NAME

# Wait a moment for the service to start
sleep 5

# Check if service started successfully
if systemctl is-active --quiet $SERVICE_NAME; then
    print_success "Unified data server started successfully"
else
    print_error "Failed to start unified data server"
    sudo systemctl status $SERVICE_NAME
    exit 1
fi

# Test API endpoint
print_status "Testing API endpoint..."
if curl -s http://localhost:$API_PORT/health > /dev/null; then
    print_success "API endpoint is responding"
else
    print_warning "API endpoint is not responding yet (may take a moment to start)"
fi

# Show setup summary
echo ""
print_header "Unified Data Server Setup Summary"
echo "====================================="
echo "✓ System requirements verified"
echo "✓ Server built successfully"
echo "✓ Environment configuration created"
echo "✓ Systemd service created and enabled"
echo "✓ Monitoring script created"
echo "✓ Server started successfully"
echo ""
print_success "DEFIMON Unified Data Server is now running!"
echo ""
echo "Important Information:"
echo "====================="
echo "• Server directory: $SERVER_HOME"
echo "• API endpoint: http://localhost:$API_PORT"
echo "• Environment file: $SERVER_HOME/.env"
echo "• Monitoring script: $SERVER_HOME/monitor.sh"
echo "• Service name: $SERVICE_NAME"
echo ""
echo "Useful Commands:"
echo "==============="
echo "• Monitor status: $SERVER_HOME/monitor.sh"
echo "• View logs: sudo journalctl -u $SERVICE_NAME -f"
echo "• Restart service: sudo systemctl restart $SERVICE_NAME"
echo "• Stop service: sudo systemctl stop $SERVICE_NAME"
echo "• Check API: curl http://localhost:$API_PORT/health"
echo ""
echo "API Endpoints:"
echo "============="
echo "• Health check: GET /health"
echo "• Networks: GET /api/v1/networks"
echo "• Blocks: GET /api/v1/networks/{network}/blocks"
echo "• Transactions: GET /api/v1/networks/{network}/transactions"
echo "• Network stats: GET /api/v1/networks/{network}/stats"
echo "• Protocols: GET /api/v1/protocols"
echo "• Prices: GET /api/v1/prices"
echo "• Dashboard: GET /api/v1/dashboard"
echo ""
print_warning "The server will automatically collect data from all configured networks!"
print_warning "Monitor the logs to ensure data collection is working properly."
