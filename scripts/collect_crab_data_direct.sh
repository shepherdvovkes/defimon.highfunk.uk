#!/bin/bash

# DEFIMON Crab Data Collector - Direct Collection Script
# This script runs directly on the crab server to collect data

set -e

# Configuration
API_BASE="http://localhost:8002"
OUTPUT_DIR="/home/vovkes/crab_data_collection"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "=== DEFIMON Crab Data Collection ==="
echo "Timestamp: $TIMESTAMP"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Function to make API calls and save results
collect_data() {
    local endpoint="$1"
    local filename="$2"
    local full_url="$API_BASE$endpoint"
    
    echo "Collecting: $endpoint"
    
    if curl -s "$full_url" > "$OUTPUT_DIR/${filename}_${TIMESTAMP}.json"; then
        echo "  ✓ Success: $filename"
        # Pretty print for display
        cat "$OUTPUT_DIR/${filename}_${TIMESTAMP}.json" | jq . 2>/dev/null || echo "  (Raw data saved)"
    else
        echo "  ✗ Failed: $filename"
    fi
    echo ""
}

# Check server health first
echo "Checking server health..."
if curl -s "$API_BASE/health" > /dev/null; then
    echo "✓ Server is healthy"
    echo ""
else
    echo "✗ Server is not responding"
    exit 1
fi

# Collect all available data
echo "Starting data collection..."

# Health check
collect_data "/health" "health"

# Networks
collect_data "/api/v1/networks" "networks"

# Dashboard
collect_data "/api/v1/dashboard" "dashboard"

# Prices
collect_data "/api/v1/prices" "prices"

# Protocols
collect_data "/api/v1/protocols" "protocols"

# Get list of networks for detailed collection
echo "Getting network list..."
NETWORKS=$(curl -s "$API_BASE/api/v1/networks" | jq -r '.networks[]' 2>/dev/null || echo "ethereum polygon arbitrum optimism base")

echo "Networks found: $NETWORKS"
echo ""

# Collect data for each network
for network in $NETWORKS; do
    echo "=== Collecting data for $network ==="
    
    # Network stats
    collect_data "/api/v1/networks/$network/stats" "${network}_stats"
    
    # Recent blocks (limit to 5)
    collect_data "/api/v1/networks/$network/blocks?limit=5" "${network}_blocks"
    
    # Recent transactions (limit to 5)
    collect_data "/api/v1/networks/$network/transactions?limit=5" "${network}_transactions"
    
    echo ""
done

# Create summary
echo "=== Collection Summary ==="
echo "Files collected in $OUTPUT_DIR:"
ls -la "$OUTPUT_DIR"/*"$TIMESTAMP"*.json 2>/dev/null || echo "No files found"

echo ""
echo "=== Data Summary ==="

# Show some key data
if [ -f "$OUTPUT_DIR/dashboard_$TIMESTAMP.json" ]; then
    echo "Dashboard Summary:"
    cat "$OUTPUT_DIR/dashboard_$TIMESTAMP.json" | jq '.dashboard | {total_networks, total_blocks, total_transactions, total_protocols, total_volume_24h}' 2>/dev/null || echo "  (Could not parse dashboard data)"
fi

if [ -f "$OUTPUT_DIR/networks_$TIMESTAMP.json" ]; then
    echo ""
    echo "Available Networks:"
    cat "$OUTPUT_DIR/networks_$TIMESTAMP.json" | jq -r '.networks[]' 2>/dev/null || echo "  (Could not parse networks data)"
fi

echo ""
echo "=== Collection Complete ==="
echo "All data saved to: $OUTPUT_DIR"
echo "Timestamp: $TIMESTAMP"
