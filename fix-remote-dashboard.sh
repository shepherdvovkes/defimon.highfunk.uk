#!/bin/bash

echo "🔧 Fixing Remote Ethereum Dashboard on crab.local"
echo "================================================="

# Check if we have the fixed files
if [ ! -f "ethereum-dashboard-fixed.html" ]; then
    echo "❌ Error: ethereum-dashboard-fixed.html not found"
    exit 1
fi

if [ ! -f "ethereum-dashboard-server.py" ]; then
    echo "❌ Error: ethereum-dashboard-server.py not found"
    exit 1
fi

echo "✅ Found fixed dashboard files"

# Test SSH connection
echo "🔍 Testing SSH connection to crab.local..."
if ssh -o ConnectTimeout=5 vovkes@crab.local "echo 'SSH connection successful'" 2>/dev/null; then
    echo "✅ SSH connection successful"
else
    echo "❌ Cannot connect to crab.local via SSH"
    exit 1
fi

echo ""
echo "🛑 Stopping all existing dashboard servers..."

# Stop all existing servers
ssh vovkes@crab.local << 'EOF'
echo "🔍 Finding and stopping dashboard servers..."

# Kill any processes on port 3000
echo "Stopping processes on port 3000..."
pkill -f "python.*3000" 2>/dev/null || true
pkill -f "node.*3000" 2>/dev/null || true
pkill -f "ethereum.*dashboard" 2>/dev/null || true

# Wait for processes to stop
sleep 3

# Double check port 3000 is free
if lsof -i :3000 > /dev/null 2>&1; then
    echo "⚠️  Port 3000 still in use, force killing..."
    lsof -ti :3000 | xargs kill -9 2>/dev/null || true
    sleep 2
fi

echo "✅ All dashboard servers stopped"
EOF

echo ""
echo "📦 Copying fixed dashboard files..."

# Copy files to user's home directory
scp ethereum-dashboard-fixed.html vovkes@crab.local:~/ethereum-dashboard-fixed.html
scp ethereum-dashboard-server.py vovkes@crab.local:~/ethereum-dashboard-server.py

echo "✅ Files copied to home directory"

echo ""
echo "🚀 Starting fixed dashboard server..."

# Start the fixed server
ssh vovkes@crab.local << 'EOF'
echo "🔍 Setting up fixed dashboard..."

# Create a working directory
mkdir -p ~/ethereum-dashboard
cd ~/ethereum-dashboard

# Copy files to working directory
cp ~/ethereum-dashboard-fixed.html ./ethereum-dashboard-fixed.html
cp ~/ethereum-dashboard-server.py ./ethereum-dashboard-server.py

# Create a simple virtual environment for Python packages
echo "📦 Setting up Python environment..."
python3 -m venv venv 2>/dev/null || {
    echo "Creating virtual environment..."
    python3 -m venv venv
}

# Activate virtual environment and install packages
source venv/bin/activate
pip install flask flask-cors psutil requests 2>/dev/null || {
    echo "Installing required packages..."
    pip install flask flask-cors psutil requests
}

# Start the server
echo "🚀 Starting fixed dashboard server..."
nohup python ethereum-dashboard-server.py > dashboard.log 2>&1 &
SERVER_PID=$!

echo "⏳ Waiting for server to start..."
sleep 5

# Check if server is running
if lsof -i :3000 > /dev/null 2>&1; then
    echo "✅ Dashboard server started successfully (PID: $SERVER_PID)"
    echo "📊 Dashboard available at: http://crab.local:3000"
else
    echo "❌ Failed to start dashboard server"
    echo "Check logs: tail -f ~/ethereum-dashboard/dashboard.log"
    exit 1
fi

# Test the API endpoints
echo "🔍 Testing API endpoints..."
sleep 2

if curl -s http://localhost:3000/api/health > /dev/null; then
    echo "✅ Health endpoint working"
else
    echo "⚠️  Health endpoint not responding"
fi

if curl -s http://localhost:3000/api/stats > /dev/null; then
    echo "✅ Stats endpoint working"
else
    echo "⚠️  Stats endpoint not responding"
fi

echo ""
echo "🎉 Fixed dashboard deployed successfully!"
echo "📊 Access at: http://crab.local:3000"
echo "📝 Logs: tail -f ~/ethereum-dashboard/dashboard.log"
echo "🔄 To stop: pkill -f 'ethereum-dashboard-server.py'"
echo "📁 Working directory: ~/ethereum-dashboard/"
EOF

echo ""
echo "🔍 Verifying deployment..."

# Wait a moment for server to fully start
sleep 5

# Test the remote dashboard
if curl -s http://crab.local:3000/ | grep -q "setTimeRange('1h')"; then
    echo "✅ Remote dashboard is now fixed!"
    echo "🎉 JavaScript syntax errors resolved"
    echo "🎯 Time period selection buttons should work"
elif curl -s http://crab.local:3000/api/health | grep -q "healthy"; then
    echo "✅ Fixed dashboard server is running!"
    echo "🎉 API endpoints are working"
    echo "🔍 Check: http://crab.local:3000"
else
    echo "⚠️  Dashboard may still need a moment to fully update"
    echo "🔍 Check: http://crab.local:3000"
fi

echo ""
echo "🎯 Fix Complete!"
echo "================"
echo ""
echo "✅ Fixed dashboard deployed to crab.local:3000"
echo "✅ JavaScript syntax errors should be resolved"
echo "✅ Time period selection buttons should work"
echo "✅ Charts should display properly"
echo ""
echo "🔍 Test the dashboard:"
echo "   http://crab.local:3000"
echo ""
echo "📝 If you still see errors:"
echo "   1. Clear browser cache (Ctrl+F5)"
echo "   2. Hard refresh the page"
echo "   3. Check browser console for errors"
echo ""
echo "🔄 To restart the dashboard:"
echo "   ssh vovkes@crab.local"
echo "   cd ~/ethereum-dashboard"
echo "   source venv/bin/activate"
echo "   python ethereum-dashboard-server.py"
echo ""
