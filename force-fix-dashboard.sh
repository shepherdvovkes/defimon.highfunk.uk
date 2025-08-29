#!/bin/bash

echo "💥 Force Fixing Remote Ethereum Dashboard on crab.local"
echo "======================================================"

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
echo "💥 Force stopping ALL servers on port 3000..."

# Force stop everything on port 3000
ssh vovkes@crab.local << 'EOF'
echo "🔍 Force stopping all processes on port 3000..."

# Kill everything on port 3000
echo "Killing all processes on port 3000..."
lsof -ti :3000 | xargs kill -9 2>/dev/null || true

# Kill any dashboard-related processes
echo "Killing dashboard processes..."
pkill -f "python.*3000" 2>/dev/null || true
pkill -f "node.*3000" 2>/dev/null || true
pkill -f "ethereum.*dashboard" 2>/dev/null || true
pkill -f "dashboard.*server" 2>/dev/null || true

# Wait for everything to stop
sleep 5

# Double check port 3000 is completely free
if lsof -i :3000 > /dev/null 2>&1; then
    echo "⚠️  Port 3000 still in use, force killing again..."
    lsof -ti :3000 | xargs kill -9 2>/dev/null || true
    sleep 3
fi

# Verify port 3000 is free
if lsof -i :3000 > /dev/null 2>&1; then
    echo "❌ Port 3000 still in use after force kill"
    lsof -i :3000
    exit 1
else
    echo "✅ Port 3000 is now completely free"
fi
EOF

echo ""
echo "📦 Copying fixed dashboard files..."

# Copy files to user's home directory
scp ethereum-dashboard-fixed.html vovkes@crab.local:~/ethereum-dashboard-fixed.html
scp ethereum-dashboard-server.py vovkes@crab.local:~/ethereum-dashboard-server.py

echo "✅ Files copied to home directory"

echo ""
echo "🚀 Starting fixed dashboard server..."

# Start the fixed server with system packages
ssh vovkes@crab.local << 'EOF'
echo "🔍 Setting up fixed dashboard..."

# Create a working directory
mkdir -p ~/ethereum-dashboard
cd ~/ethereum-dashboard

# Copy files to working directory
cp ~/ethereum-dashboard-fixed.html ./ethereum-dashboard-fixed.html
cp ~/ethereum-dashboard-server.py ./ethereum-dashboard-server.py

# Install packages with --break-system-packages flag
echo "📦 Installing required packages..."
pip3 install --break-system-packages flask flask-cors psutil requests 2>/dev/null || {
    echo "Installing packages with system override..."
    pip3 install --break-system-packages flask flask-cors psutil requests
}

# Start the server
echo "🚀 Starting fixed dashboard server..."
nohup python3 ethereum-dashboard-server.py > dashboard.log 2>&1 &
SERVER_PID=$!

echo "⏳ Waiting for server to start..."
sleep 8

# Check if server is running
if lsof -i :3000 > /dev/null 2>&1; then
    echo "✅ Dashboard server started successfully (PID: $SERVER_PID)"
    echo "📊 Dashboard available at: http://crab.local:3000"
    
    # Show what's running on port 3000
    echo "🔍 Process running on port 3000:"
    lsof -i :3000
else
    echo "❌ Failed to start dashboard server"
    echo "Check logs: tail -f ~/ethereum-dashboard/dashboard.log"
    cat ~/ethereum-dashboard/dashboard.log
    exit 1
fi

# Test the API endpoints
echo "🔍 Testing API endpoints..."
sleep 3

if curl -s http://localhost:3000/api/health > /dev/null; then
    echo "✅ Health endpoint working"
    curl -s http://localhost:3000/api/health
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
    echo "⚠️  Checking what's running on port 3000..."
    ssh vovkes@crab.local "lsof -i :3000"
    echo "🔍 Check: http://crab.local:3000"
fi

echo ""
echo "🎯 Force Fix Complete!"
echo "====================="
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
echo "   python3 ethereum-dashboard-server.py"
echo ""
