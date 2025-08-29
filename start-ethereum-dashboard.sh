#!/bin/bash

echo "🚀 Starting Fixed Ethereum Archive Node Dashboard"
echo "=================================================="

# Check if required files exist
if [ ! -f "ethereum-dashboard-fixed.html" ]; then
    echo "❌ Error: ethereum-dashboard-fixed.html not found"
    exit 1
fi

if [ ! -f "ethereum-dashboard-server.py" ]; then
    echo "❌ Error: ethereum-dashboard-server.py not found"
    exit 1
fi

echo "✅ Found required files"

# Check if Python dependencies are installed
echo "🔍 Checking Python dependencies..."
python3 -c "import flask, psutil, requests" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "📦 Installing required Python packages..."
    pip3 install flask flask-cors psutil requests
fi

# Kill any existing server on port 3000
echo "🔄 Stopping any existing server on port 3000..."
pkill -f "ethereum-dashboard-server.py" 2>/dev/null || true
pkill -f "python3.*3000" 2>/dev/null || true

# Wait a moment
sleep 2

# Start the server
echo "🌐 Starting dashboard server on port 3000..."
python3 ethereum-dashboard-server.py &
SERVER_PID=$!

echo "⏳ Waiting for server to start..."
sleep 5

# Check if server is running
if lsof -i :3000 > /dev/null 2>&1; then
    echo "✅ Server started successfully (PID: $SERVER_PID)"
    echo "📊 Dashboard available at: http://localhost:3000"
    echo "📊 Dashboard available at: http://crab.local:3000"
    
    # Test the API endpoints
    echo "🔍 Testing API endpoints..."
    sleep 2
    
    # Test health endpoint
    if curl -s http://localhost:3000/api/health > /dev/null; then
        echo "✅ Health endpoint working"
    else
        echo "⚠️  Health endpoint not responding"
    fi
    
    # Test stats endpoint
    if curl -s http://localhost:3000/api/stats > /dev/null; then
        echo "✅ Stats endpoint working"
    else
        echo "⚠️  Stats endpoint not responding"
    fi
    
    echo ""
    echo "🎉 Fixed Dashboard is now running!"
    echo "📊 Features available:"
    echo "  • Fixed JavaScript syntax errors"
    echo "  • Working time period selection buttons"
    echo "  • Proper Chart.js integration"
    echo "  • Real-time Ethereum node monitoring"
    echo "  • System performance charts"
    echo "  • Network bandwidth monitoring"
    echo ""
    echo "🔧 API Endpoints:"
    echo "   - GET /api/stats - Current node statistics"
    echo "   - GET /api/history/system - Historical data"
    echo "   - GET /api/health - Health check"
    echo ""
    echo "🔄 To stop the server:"
    echo "   pkill -f 'ethereum-dashboard-server.py'"
    echo ""
    echo "🔄 To restart the server:"
    echo "   ./start-ethereum-dashboard.sh"
    
    # Keep the script running
    wait $SERVER_PID
else
    echo "❌ Failed to start server"
    echo "🔍 Checking for errors..."
    tail -n 20 /tmp/ethereum-dashboard.log 2>/dev/null || echo "No log file found"
    exit 1
fi
