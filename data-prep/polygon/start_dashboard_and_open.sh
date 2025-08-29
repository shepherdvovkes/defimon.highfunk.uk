#!/bin/bash

echo "🚀 Starting Polygon Data Dashboard..."
echo "======================================"

# Check if we're in the right directory
if [ ! -f "web_dashboard/app.py" ]; then
    echo "❌ Error: Please run this script from the polygon directory"
    echo "Current directory: $(pwd)"
    echo "Expected location: data-prep/polygon/"
    exit 1
fi

# Check if Flask is installed
if ! python3 -c "import flask" 2>/dev/null; then
    echo "📦 Installing Flask..."
    pip3 install flask
fi

# Start the dashboard and open browser
echo "🌐 Starting web server on port 8000..."
echo "📊 Dashboard will be available at: http://localhost:8000"
echo "🔄 Press Ctrl+C to stop the server"
echo ""

# Open browser after 3 seconds
(sleep 3 && open http://localhost:8000) &

# Start the Flask server
cd web_dashboard
python3 app.py
