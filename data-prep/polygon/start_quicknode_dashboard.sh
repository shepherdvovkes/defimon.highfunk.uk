#!/bin/bash

echo "🚀 Starting QuickNode Data Dashboard"
echo "===================================="

# Check if we're in the right directory
if [ ! -f "quicknode_dashboard.html" ]; then
    echo "❌ Error: quicknode_dashboard.html not found"
    echo "Please run: python3 create_data_dashboard.py first"
    exit 1
fi

echo "✅ Found dashboard file"

# Kill any existing server on port 8000
echo "🔄 Stopping any existing server on port 8000..."
pkill -f "python3 -m http.server 8000" 2>/dev/null || true

# Wait a moment
sleep 2

# Start the server
echo "🌐 Starting web server on port 8000..."
python3 -m http.server 8000 &
SERVER_PID=$!

echo "⏳ Waiting for server to start..."
sleep 3

# Check if server is running
if lsof -i :8000 > /dev/null 2>&1; then
    echo "✅ Server started successfully (PID: $SERVER_PID)"
    echo "📊 Dashboard available at: http://localhost:8000/quicknode_dashboard.html"
    
    # Open browser
    echo "🌐 Opening browser..."
    open http://localhost:8000/quicknode_dashboard.html
    
    echo ""
    echo "🎉 Dashboard is now running!"
    echo "📊 Features available:"
    echo "  • Network statistics for the last month"
    echo "  • Interactive charts and graphs"
    echo "  • Sample transaction data"
    echo "  • Real-time data visualization"
    echo ""
    echo "🔄 To stop the server:"
    echo "   pkill -f 'python3 -m http.server 8000'"
    echo ""
    echo "🔄 To refresh data:"
    echo "   1. Run: python3 quicknode_data_explorer.py"
    echo "   2. Run: python3 create_data_dashboard.py"
    echo "   3. Refresh browser"
    
    # Keep the script running
    wait $SERVER_PID
else
    echo "❌ Failed to start server"
    exit 1
fi
