#!/bin/bash

# SSL Certificate Analysis Runner
# This script runs comprehensive SSL certificate analysis for QuickNode endpoints

set -e

echo "🔍 SSL Certificate Analysis Runner"
echo "=================================="

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

# Run the SSL certificate analysis
echo "🔍 Running SSL certificate analysis..."
echo "Analyzing SSL certificate issues for Polygon, Arbitrum, and Optimism networks..."
echo ""

python3 ssl_certificate_analyzer.py

echo ""
echo "✅ SSL certificate analysis completed!"
echo "📊 Generated files:"
echo "   - ssl_certificate_analysis.log (detailed analysis log)"
echo "   - ssl_certificate_analysis_*.json (analysis results in JSON format)"
echo ""
echo "🔍 Analysis includes:"
echo "   • Certificate details and validation"
echo "   • Alternative SSL configurations"
echo "   • Mitigation recommendations"
echo "   • Comparison with working networks"
