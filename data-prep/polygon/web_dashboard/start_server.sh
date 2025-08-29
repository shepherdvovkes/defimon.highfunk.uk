#!/bin/bash

echo "🚀 Starting Polygon Data Dashboard..."
echo "======================================"

# Check current directory
echo "📍 Current directory: $(pwd)"
echo "📁 Checking for app.py..."

if [ ! -f "app.py" ]; then
    echo "❌ Error: app.py not found in current directory"
    echo "💡 Please run this script from: /Users/vovkes/defimon.highfunk.uk/data-prep/polygon/web_dashboard"
    exit 1
fi

echo "✅ Found app.py"

# Check if Flask is installed
echo "📦 Checking Flask installation..."
if ! python3 -c "import flask" 2>/dev/null; then
    echo "📦 Installing Flask..."
    pip3 install flask
else
    echo "✅ Flask is installed"
fi

# Kill any existing processes on port 8000
echo "🔄 Stopping any existing processes on port 8000..."
lsof -ti:8000 | xargs kill -9 2>/dev/null || true

# Start the server
echo "🌐 Starting Flask server on port 8000..."
echo "📊 Dashboard will be available at: http://localhost:8000"
echo "🔄 Press Ctrl+C to stop the server"
echo ""

# Open browser after 3 seconds
(sleep 3 && open http://localhost:8000) &

# Start the Flask server
python3 app.py
