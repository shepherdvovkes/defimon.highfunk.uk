#!/bin/bash

echo "🗄️ Setting up PostgreSQL Database Connection"
echo "=============================================="

# Check if we're in the right directory
if [ ! -f "test_database_connection.py" ]; then
    echo "❌ Error: Please run this script from the polygon directory"
    echo "Current directory: $(pwd)"
    exit 1
fi

echo "✅ Found database test script"

# Check if Cloud SQL Proxy is installed
if [ ! -f "cloud_sql_proxy" ]; then
    echo "📦 Installing Cloud SQL Proxy..."
    curl -o cloud_sql_proxy https://dl.google.com/cloudsql/cloud_sql_proxy.darwin.amd64
    chmod +x cloud_sql_proxy
    echo "✅ Cloud SQL Proxy installed"
else
    echo "✅ Cloud SQL Proxy already installed"
fi

# Check if proxy is running
if lsof -i :5432 > /dev/null 2>&1; then
    echo "✅ Cloud SQL Proxy is already running on port 5432"
else
    echo "🔄 Starting Cloud SQL Proxy..."
    echo "📊 Instance: defimon-ethereum-node:us-central1:defimon-postgres-instance"
    echo "🔄 This will run in the background..."
    
    # Start proxy in background
    ./cloud_sql_proxy -instances=defimon-ethereum-node:us-central1:defimon-postgres-instance=tcp:5432 &
    PROXY_PID=$!
    
    echo "⏳ Waiting for proxy to start..."
    sleep 5
    
    # Check if proxy started successfully
    if lsof -i :5432 > /dev/null 2>&1; then
        echo "✅ Cloud SQL Proxy started successfully (PID: $PROXY_PID)"
    else
        echo "❌ Failed to start Cloud SQL Proxy"
        echo "💡 You may need to:"
        echo "1. Check your Google Cloud credentials"
        echo "2. Verify the instance name is correct"
        echo "3. Ensure you have access to the project"
        exit 1
    fi
fi

echo ""
echo "🧪 Testing database connection..."
python3 test_database_connection.py

echo ""
echo "📋 Next Steps:"
echo "1. If connection fails, you may need to create the database user"
echo "2. Run: python3 setup_database_schema.py"
echo "3. Check the web dashboard at http://localhost:8000"
echo ""
echo "🔄 To stop the Cloud SQL Proxy:"
echo "   pkill -f cloud_sql_proxy"
