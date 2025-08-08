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

print_header "Polkadot Networks Setup"

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

# Apply Polkadot schema
print_status "Applying Polkadot schema..."

if [ -f "infrastructure/polkadot_schema.sql" ]; then
    psql -h localhost -U postgres -d defi_analytics -f infrastructure/polkadot_schema.sql
    print_status "Polkadot schema applied successfully"
else
    print_error "Polkadot schema file not found: infrastructure/polkadot_schema.sql"
    exit 1
fi

# Check if tables were created
print_status "Verifying Polkadot tables..."

TABLES=$(psql -h localhost -U postgres -d defi_analytics -t -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE 'polkadot_%';")

if [ -z "$TABLES" ]; then
    print_error "Polkadot tables were not created properly"
    exit 1
else
    print_status "Polkadot tables created:"
    echo "$TABLES" | while read table; do
        if [ ! -z "$table" ]; then
            echo "  - $table"
        fi
    done
fi

# Update environment configuration
print_status "Updating environment configuration..."

if [ -f ".env" ]; then
    # Check if Polkadot config already exists
    if ! grep -q "POLKADOT_SYNC_ENABLED" .env; then
        echo "" >> .env
        echo "# Polkadot Networks Configuration" >> .env
        echo "POLKADOT_SYNC_ENABLED=true" >> .env
        echo "POLKADOT_NETWORKS=polkadot,kusama,westend,rococo" >> .env
        echo "POLKADOT_SYNC_INTERVAL=10" >> .env
        echo "POLKADOT_BATCH_SIZE=20" >> .env
        echo "POLKADOT_MAX_CONCURRENT_REQUESTS=5" >> .env
        echo "POLKADOT_DATA_RETENTION_DAYS=90" >> .env
        echo "POLKADOT_PRIORITY_THRESHOLD=5" >> .env
        print_status "Polkadot configuration added to .env"
    else
        print_status "Polkadot configuration already exists in .env"
    fi
else
    print_warning ".env file not found. Please copy from env.example and configure manually."
fi

# Test Polkadot RPC endpoints
print_status "Testing Polkadot RPC endpoints..."

POLKADOT_ENDPOINTS=(
    "https://rpc.polkadot.io"
    "https://kusama-rpc.polkadot.io"
    "https://westend-rpc.polkadot.io"
    "https://rococo-rpc.polkadot.io"
)

for endpoint in "${POLKADOT_ENDPOINTS[@]}"; do
    network_name=$(echo $endpoint | sed 's|https://||' | sed 's|-rpc.polkadot.io||')
    print_status "Testing $network_name..."
    
    if curl -s --max-time 10 -X POST "$endpoint" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"system_version","params":[],"id":1}' > /dev/null 2>&1; then
        print_status "✓ $network_name is accessible"
    else
        print_warning "✗ $network_name is not accessible"
    fi
done

# Build Rust components
print_status "Building Rust blockchain-node with Polkadot support..."

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
print_status "Creating Polkadot monitoring dashboard..."

cat > monitoring/polkadot_dashboard.json << 'EOF'
{
  "dashboard": {
    "title": "Polkadot Networks Monitoring",
    "panels": [
      {
        "title": "Polkadot Blocks Processed",
        "type": "stat",
        "targets": [
          {
            "expr": "polkadot_blocks_processed_total",
            "legendFormat": "{{network}}"
          }
        ]
      },
      {
        "title": "Polkadot Latest Block Number",
        "type": "stat",
        "targets": [
          {
            "expr": "polkadot_latest_block_number",
            "legendFormat": "{{network}}"
          }
        ]
      },
      {
        "title": "Polkadot Extrinsics Processed",
        "type": "stat",
        "targets": [
          {
            "expr": "polkadot_extrinsics_processed_total",
            "legendFormat": "{{network}}"
          }
        ]
      },
      {
        "title": "Polkadot Validators",
        "type": "stat",
        "targets": [
          {
            "expr": "polkadot_validators_total",
            "legendFormat": "{{network}}"
          }
        ]
      }
    ]
  }
}
EOF

print_status "Polkadot monitoring dashboard created"

# Final instructions
print_header "Setup Complete!"

print_status "Polkadot integration has been successfully configured."
print_status ""
print_status "Next steps:"
print_status "1. Start the services: docker-compose up -d"
print_status "2. Monitor logs: docker-compose logs -f blockchain-node"
print_status "3. Check Polkadot sync status in the admin dashboard"
print_status "4. View Polkadot data: http://localhost:8002/docs"
print_status ""
print_status "Documentation: docs/POLKADOT_SETUP.md"
print_status "Schema file: infrastructure/polkadot_schema.sql"

print_status ""
print_status "Happy monitoring! 🚀"
