#!/bin/bash

echo "🛑 Killing All Web Servers"
echo "=========================="

echo "🔍 Checking for running web servers..."

# Kill processes on common web server ports
echo "📡 Killing processes on web server ports..."
lsof -ti :3000,8000,8002,8080,5000,4000,9000 | xargs kill -9 2>/dev/null || echo "No processes found on web ports"

# Kill Python web servers
echo "🐍 Killing Python web servers..."
pkill -f "python.*server" 2>/dev/null || echo "No Python servers found"
pkill -f "flask" 2>/dev/null || echo "No Flask servers found"
pkill -f "ethereum-dashboard" 2>/dev/null || echo "No Ethereum dashboard servers found"
pkill -f "start-ethereum-dashboard" 2>/dev/null || echo "No Ethereum dashboard startup scripts found"

# Kill Node.js servers
echo "🟢 Killing Node.js servers..."
pkill -f "node.*server" 2>/dev/null || echo "No Node.js servers found"
pkill -f "npm.*start" 2>/dev/null || echo "No npm start processes found"

# Kill any remaining Python processes that might be servers
echo "🔍 Checking for remaining Python processes..."
ps aux | grep -E "(python.*server|flask|django)" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || echo "No additional Python servers found"

# Check what's still running
echo ""
echo "📊 Current status:"
echo "=================="
lsof -i :3000,8000,8002,8080,5000,4000,9000 2>/dev/null || echo "✅ All web server ports are free"

echo ""
echo "🎯 All web servers have been stopped!"
echo "✅ Ports 3000, 8000, 8002, 8080, 5000 are now available"
echo ""
echo "💡 To start servers again:"
echo "   - Ethereum Dashboard: ./start-ethereum-dashboard.sh"
echo "   - Other servers: Check their respective startup scripts"
echo ""
