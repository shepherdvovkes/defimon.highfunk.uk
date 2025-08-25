#!/bin/bash

# DEFIMON Consensus Layer Monitor
# This script helps diagnose and fix consensus layer issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "🔍 DEFIMON Consensus Layer Status Check"
echo "======================================"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop first."
    exit 1
fi

print_success "Docker is running"

# Check if JWT secrets exist
if [ ! -f "infrastructure/ethereum-node/jwtsecret.raw" ] || [ ! -f "infrastructure/ethereum-node/jwtsecret.hex" ]; then
    print_warning "JWT secrets not found. Generating new ones..."
    bash scripts/generate-jwt-secrets.sh
fi

print_success "JWT secrets are available"

# Check if Ethereum nodes are running
print_status "Checking Ethereum node status..."

# Check Geth (Execution Layer)
if curl -s http://localhost:8545 >/dev/null 2>&1; then
    print_success "Geth (Execution Layer) is running on port 8545"
    GETH_STATUS="✅ RUNNING"
else
    print_error "Geth (Execution Layer) is NOT running on port 8545"
    GETH_STATUS="❌ NOT RUNNING"
fi

# Check Lighthouse (Consensus Layer)
if curl -s http://localhost:5052/eth/v1/node/syncing >/dev/null 2>&1; then
    print_success "Lighthouse (Consensus Layer) is running on port 5052"
    LIGHTHOUSE_STATUS="✅ RUNNING"
    
    # Get sync status
    SYNC_RESPONSE=$(curl -s http://localhost:5052/eth/v1/node/syncing)
    if echo "$SYNC_RESPONSE" | grep -q '"is_syncing":true'; then
        print_warning "Lighthouse is currently syncing..."
    else
        print_success "Lighthouse is synced and ready"
    fi
else
    print_error "Lighthouse (Consensus Layer) is NOT running on port 5052"
    LIGHTHOUSE_STATUS="❌ NOT RUNNING"
fi

echo ""
echo "📊 Current Status Summary"
echo "========================"
echo "Execution Layer (Geth):     $GETH_STATUS"
echo "Consensus Layer (Lighthouse): $LIGHTHOUSE_STATUS"

echo ""
echo "🔧 Next Steps:"
echo "=============="

if [[ "$GETH_STATUS" == "❌ NOT RUNNING" ]] || [[ "$LIGHTHOUSE_STATUS" == "❌ NOT RUNNING" ]]; then
    print_warning "Consensus Layer Critical Issue Detected!"
    echo ""
    echo "To fix this issue:"
    echo "1. Start the Ethereum nodes:"
    echo "   cd infrastructure/infrastructure-pool/geth-monitoring"
    echo "   docker-compose -f docker-compose.simple.yml up -d"
    echo ""
    echo "2. Wait for nodes to sync (this may take several hours)"
    echo ""
    echo "3. Monitor progress:"
    echo "   docker logs lighthouse-beacon -f"
    echo "   docker logs geth-full-node -f"
    echo ""
    echo "4. Check sync status:"
    echo "   curl http://localhost:5052/eth/v1/node/syncing"
    echo "   curl http://localhost:8545"
else
    print_success "All systems are running! The consensus layer issue has been resolved."
    echo ""
    echo "You can now run the enhanced monitor:"
    echo "python3 ethereum-sync-monitor-enhanced.py --simple"
fi

echo ""
echo "📚 For more information, see:"
echo "- docs/ethereum-jwt-setup/"
echo "- infrastructure/infrastructure-pool/geth-monitoring/"
echo "- scripts/generate-jwt-secrets.sh"
