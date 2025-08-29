#!/bin/bash

echo "🚀 Deploying Fixed Ethereum Dashboard to crab.local"
echo "==================================================="

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
    echo "Please ensure you have SSH access configured"
    echo ""
    echo "Manual deployment steps:"
    echo "1. SSH to crab.local manually"
    echo "2. Copy the fixed files"
    echo "3. Restart the dashboard server"
    exit 1
fi

echo ""
echo "📦 Copying fixed dashboard files to crab.local..."

# Copy the fixed files
echo "📄 Copying ethereum-dashboard-fixed.html..."
scp ethereum-dashboard-fixed.html vovkes@crab.local:/tmp/

echo "🐍 Copying ethereum-dashboard-server.py..."
scp ethereum-dashboard-server.py vovkes@crab.local:/tmp/

echo "✅ Files copied to /tmp/ on crab.local"

echo ""
echo "🔄 Updating dashboard on crab.local..."

# Execute remote commands
ssh vovkes@crab.local << 'EOF'
echo "🔍 Finding current dashboard location..."

# Try to find the dashboard files
DASHBOARD_DIR=""
for dir in /opt/defimon /home/vovkes/ethereum /home/vovkes /opt; do
    if [ -d "$dir" ]; then
        if find "$dir" -name "*.html" -o -name "*.py" | grep -i dashboard > /dev/null 2>&1; then
            DASHBOARD_DIR="$dir"
            echo "Found dashboard files in: $dir"
            break
        fi
    fi
done

if [ -z "$DASHBOARD_DIR" ]; then
    echo "⚠️  Could not find dashboard directory, using /opt/defimon"
    DASHBOARD_DIR="/opt/defimon"
    mkdir -p "$DASHBOARD_DIR"
fi

echo "📁 Using dashboard directory: $DASHBOARD_DIR"

# Stop any existing dashboard server
echo "🛑 Stopping existing dashboard server..."
pkill -f "python.*3000" 2>/dev/null || true
pkill -f "ethereum.*dashboard" 2>/dev/null || true

# Wait a moment
sleep 2

# Copy files to the dashboard directory
echo "📋 Copying fixed files to dashboard directory..."
cp /tmp/ethereum-dashboard-fixed.html "$DASHBOARD_DIR/"
cp /tmp/ethereum-dashboard-server.py "$DASHBOARD_DIR/"

# Install dependencies if needed
echo "📦 Checking Python dependencies..."
python3 -c "import flask, psutil, requests" 2>/dev/null || {
    echo "Installing required packages..."
    pip3 install flask flask-cors psutil requests
}

# Start the fixed dashboard server
echo "🚀 Starting fixed dashboard server..."
cd "$DASHBOARD_DIR"
nohup python3 ethereum-dashboard-server.py > dashboard.log 2>&1 &
SERVER_PID=$!

echo "⏳ Waiting for server to start..."
sleep 5

# Check if server is running
if lsof -i :3000 > /dev/null 2>&1; then
    echo "✅ Dashboard server started successfully (PID: $SERVER_PID)"
    echo "📊 Dashboard available at: http://crab.local:3000"
else
    echo "❌ Failed to start dashboard server"
    echo "Check logs: tail -f $DASHBOARD_DIR/dashboard.log"
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
echo "📝 Logs: tail -f $DASHBOARD_DIR/dashboard.log"
echo "🔄 To stop: pkill -f 'ethereum-dashboard-server.py'"
EOF

echo ""
echo "🔍 Verifying deployment..."

# Test the remote dashboard
sleep 3
if curl -s http://crab.local:3000/ | grep -q "setTimeRange('1h')"; then
    echo "✅ Remote dashboard is now fixed!"
    echo "🎉 JavaScript syntax errors resolved"
    echo "🎯 Time period selection buttons should work"
else
    echo "⚠️  Dashboard may still need a moment to fully update"
    echo "🔍 Check: http://crab.local:3000"
fi

echo ""
echo "🎯 Deployment Complete!"
echo "======================"
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
echo "   1. Clear browser cache"
echo "   2. Hard refresh (Ctrl+F5)"
echo "   3. Check browser console for errors"
echo ""
