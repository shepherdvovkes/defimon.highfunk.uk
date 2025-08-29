#!/bin/bash

echo "⚡ Quick Fix for Remote Dashboard"
echo "================================"

echo "🛑 Killing everything on port 3000..."
ssh vovkes@crab.local "sudo lsof -ti :3000 | xargs sudo kill -9 2>/dev/null || true"
ssh vovkes@crab.local "pkill -f 'node.*3000' 2>/dev/null || true"
ssh vovkes@crab.local "pkill -f 'python.*3000' 2>/dev/null || true"

echo "⏳ Waiting for port to be free..."
sleep 3

echo "📦 Copying fixed files..."
scp ethereum-dashboard-fixed.html vovkes@crab.local:~/dashboard.html
scp ethereum-dashboard-server.py vovkes@crab.local:~/server.py

echo "🚀 Starting fixed dashboard..."
ssh vovkes@crab.local << 'EOF'
cd ~
python3 -c "import flask" 2>/dev/null || pip3 install --user flask flask-cors
nohup python3 server.py > dashboard.log 2>&1 &
sleep 5
echo "✅ Dashboard started!"
echo "📊 Check: http://crab.local:3000"
EOF

echo "🔍 Testing dashboard..."
sleep 3
curl -s http://crab.local:3000/api/health

echo ""
echo "🎯 Dashboard should now be fixed!"
echo "📊 Visit: http://crab.local:3000"
echo ""
echo "💡 If you still see errors:"
echo "   1. Clear browser cache (Ctrl+F5)"
echo "   2. Try incognito/private mode"
echo "   3. Disable browser extensions"
echo ""
