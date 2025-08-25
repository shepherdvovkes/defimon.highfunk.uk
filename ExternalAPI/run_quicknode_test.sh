#!/bin/bash

# QuickNode API Test Runner
# This script installs dependencies and runs the QuickNode API tests

set -e

echo "🚀 QuickNode API Test Runner"
echo "=============================="

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed"
    exit 1
fi

# Check if pip is available
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is required but not installed"
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
pip install -r requirements.txt

# Run the tests
echo "🧪 Running QuickNode API tests..."
python3 quicknode_test.py

echo "✅ Tests completed! Check the generated report and log files."
