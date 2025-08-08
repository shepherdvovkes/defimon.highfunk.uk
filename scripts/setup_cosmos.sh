#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_header "Cosmos Networks Setup"

# Check if PostgreSQL is running
print_status "Checking PostgreSQL connection..."

if ! pg_isready -h localhost -p 5432 -U postgres > /dev/null 2>&1; then
    print_error "PostgreSQL is not running. Please start PostgreSQL first."
    print_status "You can start it with: docker-compose up -d postgres"
    exit 1
fi

print_status "PostgreSQL is running"

# Check if database exists
print_status "Checking database..."

if ! psql -h localhost -U postgres -lqt | cut -d \| -f 1 | grep -qw defi_analytics; then
    print_warning "Database 'defi_analytics' does not exist. Creating..."
    createdb -h localhost -U postgres defi_analytics
    print_status "Database created successfully"
else
    print_status "Database 'defi_analytics' exists"
fi

# Apply Cosmos schema
print_status "Applying Cosmos schema..."

if [ -f "infrastructure/cosmos_schema.sql" ]; then
    psql -h localhost -U postgres -d defi_analytics -f infrastructure/cosmos_schema.sql
    print_status "Cosmos schema applied successfully"
else
    print_error "Cosmos schema file not found: infrastructure/cosmos_schema.sql"
    exit 1
fi

# Check if tables were created
print_status "Verifying Cosmos tables..."

TABLES=$(psql -h localhost -U postgres -d defi_analytics -t -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE 'cosmos_%';")

if [ -z "$TABLES" ]; then
    print_error "Cosmos tables were not created properly"
    exit 1
else
    print_status "Cosmos tables created:"
    echo "$TABLES" | while read table; do
        if [ ! -z "$table" ]; then
            echo "  - $table"
        fi
    done
fi

# Update environment configuration
print_status "Updating environment configuration..."

if [ -f ".env" ]; then
    # Check if Cosmos config already exists
    if ! grep -q "COSMOS_SYNC_ENABLED" .env; then
        echo "" >> .env
        echo "# Cosmos Networks Configuration" >> .env
        echo "COSMOS_SYNC_ENABLED=true" >> .env
        echo "COSMOS_NETWORKS=cosmos_hub,osmosis,injective,celestia,sei,neutron,stride,quicksilver,persistence,agoric,evmos,kava" >> .env
        echo "COSMOS_SYNC_INTERVAL=15" >> .env
        echo "COSMOS_BATCH_SIZE=50" >> .env
        echo "COSMOS_MAX_CONCURRENT_REQUESTS=8" >> .env
        echo "COSMOS_DATA_RETENTION_DAYS=90" >> .env
        echo "COSMOS_PRIORITY_THRESHOLD=5" >> .env
        print_status "Cosmos configuration added to .env"
    else
        print_status "Cosmos configuration already exists in .env"
    fi
else
    print_warning ".env file not found. Please copy from env.example and configure manually."
fi

# Test Cosmos RPC endpoints
print_status "Testing Cosmos RPC endpoints..."

COSMOS_ENDPOINTS=(
    "https://rpc.cosmos.network:26657"
    "https://rpc.osmosis.zone:26657"
    "https://rpc.injective.network:26657"
)

for endpoint in "${COSMOS_ENDPOINTS[@]}"; do
    network_name=$(echo $endpoint | sed 's|https://rpc\.||' | sed 's|:26657||')
    print_status "Testing $network_name..."
    
    if curl -s --max-time 10 "$endpoint/status" > /dev/null 2>&1; then
        print_status "✓ $network_name is accessible"
    else
        print_warning "✗ $network_name is not accessible"
    fi
done

# Build Rust components
print_status "Building Rust blockchain-node with Cosmos support..."

cd services/blockchain-node

if command -v cargo > /dev/null 2>&1; then
    cargo build --release
    print_status "Rust components built successfully"
else
    print_warning "Rust/Cargo not found. Please install Rust first:"
    echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
fi

cd ../..

# Create monitoring dashboard
print_status "Creating Cosmos monitoring dashboard..."

cat > monitoring/cosmos_dashboard.json << 'EOF'
{
  "dashboard": {
    "title": "Cosmos Networks Monitoring",
    "panels": [
      {
        "title": "Cosmos Blocks Processed",
        "type": "stat",
        "targets": [
          {
            "expr": "cosmos_blocks_processed_total",
            "legendFormat": "{{network}}"
          }
        ]
      },
      {
        "title": "Cosmos Latest Block Height",
        "type": "stat",
        "targets": [
          {
            "expr": "cosmos_latest_block_height",
            "legendFormat": "{{network}}"
          }
        ]
      },
      {
        "title": "Cosmos Transactions Processed",
        "type": "stat",
        "targets": [
          {
            "expr": "cosmos_transactions_processed_total",
            "legendFormat": "{{network}}"
          }
        ]
      },
      {
        "title": "Cosmos Validators",
        "type": "stat",
        "targets": [
          {
            "expr": "cosmos_validators_total",
            "legendFormat": "{{network}}"
          }
        ]
      }
    ]
  }
}
EOF

print_status "Cosmos monitoring dashboard created"

# Final instructions
print_header "Setup Complete!"

print_status "Cosmos integration has been successfully configured."
print_status ""
print_status "Next steps:"
print_status "1. Start the services: docker-compose up -d"
print_status "2. Monitor logs: docker-compose logs -f blockchain-node"
print_status "3. Check Cosmos sync status in the admin dashboard"
print_status "4. View Cosmos data: http://localhost:8002/docs"
print_status ""
print_status "Documentation: docs/COSMOS_SETUP.md"
print_status "Schema file: infrastructure/cosmos_schema.sql"

print_status ""
print_status "Happy monitoring! 🚀"
