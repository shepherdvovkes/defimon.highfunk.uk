#!/bin/bash

# QuickNode Multichain API Test Runner
# This script runs the multichain testing utility to test multiple blockchain networks

set -e

echo "🚀 QuickNode Multichain API Test Runner"
echo "========================================"

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

# Run the multichain tests
echo "🧪 Running QuickNode Multichain API tests..."
echo "Testing multiple blockchain networks through QuickNode's multichain endpoint structure..."
echo ""

python3 multichain_test.py

echo ""
echo "✅ Multichain tests completed! Check the generated report and log files."
echo "📊 Generated files:"
echo "   - multichain_test.log (detailed execution log)"
echo "   - multichain_test_results_*.json (test results in JSON format)"
