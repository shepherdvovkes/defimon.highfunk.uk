#!/bin/bash

echo "🚀 Starting Polygon Monthly Data Collection"
echo "==========================================="

# Check if we're in the right directory
if [ ! -f "collect_monthly_data.py" ]; then
    echo "❌ Error: collect_monthly_data.py not found"
    exit 1
fi

echo "✅ Found collection script"

# Check if Cloud SQL Proxy is running
if ! lsof -i :5432 > /dev/null 2>&1; then
    echo "⚠️ Cloud SQL Proxy not running. Starting it..."
    ./cloud_sql_proxy -instances=defimon-ethereum-node:us-central1:defimon-postgres-instance=tcp:5432 &
    sleep 5
fi

echo "✅ Database connection ready"

# Show current database stats
echo ""
echo "📊 Current Database Statistics:"
psql -h localhost -U defimon_user -d defi_analytics -c "
SELECT 
    'blocks' as table_name, COUNT(*) as count FROM polygon_data.blocks
UNION ALL
SELECT 
    'transactions' as table_name, COUNT(*) as count FROM polygon_data.transactions
UNION ALL
SELECT 
    'receipts' as table_name, COUNT(*) as count FROM polygon_data.receipts;"

echo ""
echo "🎯 Ready to collect monthly data!"
echo "📊 This will collect approximately 5,184,000 blocks"
echo "⏱️ Estimated time: 2-4 hours"
echo "💾 Data will be stored in PostgreSQL"

# Confirm collection
read -p "🤔 Proceed with monthly collection? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Starting collection..."
    python3 collect_monthly_data.py
else
    echo "❌ Collection cancelled"
fi
