#!/bin/bash

# QuickNode Multichain API Test Runner with SSL Fix
# This script runs the multichain testing utility with SSL certificate issue mitigation

set -e

echo "🚀 QuickNode Multichain API Test Runner (SSL Fix)"
echo "================================================="

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Please run ./run_quicknode_test.sh first to set up dependencies."
    exit 1
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Run the SSL-fixed multichain tests
echo "🧪 Running QuickNode Multichain API tests with SSL handling..."
echo "Testing multiple blockchain networks with SSL certificate issue mitigation..."
echo ""

python3 multichain_test_ssl_fix.py

echo ""
echo "✅ SSL-fixed multichain tests completed! Check the generated report and log files."
echo "📊 Generated files:"
echo "   - multichain_test_ssl_fix.log (detailed execution log)"
echo "   - multichain_test_ssl_fix_results_*.json (test results in JSON format)"
echo ""
echo "🔒 SSL Status Indicators:"
echo "   🔒 = SSL Verified (Secure)"
echo "   ⚠️  = SSL Not Verified (Working but with certificate issues)"
