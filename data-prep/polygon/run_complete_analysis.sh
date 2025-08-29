#!/bin/bash

echo "🚀 Complete QuickNode Data Analysis & Dashboard"
echo "==============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "quicknode_data_explorer.py" ]; then
    print_error "Please run this script from the polygon directory"
    exit 1
fi

print_status "Starting complete QuickNode data analysis..."

# Step 1: Data Exploration
echo ""
print_status "Step 1: Extracting data from QuickNode API..."
if python3 quicknode_data_explorer.py; then
    print_success "Data extraction completed"
else
    print_error "Data extraction failed"
    exit 1
fi

# Step 2: Create Dashboard
echo ""
print_status "Step 2: Creating web dashboard..."
if python3 create_data_dashboard.py; then
    print_success "Dashboard creation completed"
else
    print_error "Dashboard creation failed"
    exit 1
fi

# Step 3: Start Server and Open Browser
echo ""
print_status "Step 3: Starting web server and opening browser..."

# Kill any existing server on port 8000
pkill -f "python3 -m http.server 8000" 2>/dev/null || true
sleep 2

# Start the server
python3 -m http.server 8000 &
SERVER_PID=$!

# Wait for server to start
sleep 3

# Check if server is running
if lsof -i :8000 > /dev/null 2>&1; then
    print_success "Web server started successfully (PID: $SERVER_PID)"
    
    # Open browser
    print_status "Opening browser..."
    open http://localhost:8000/quicknode_dashboard.html
    
    echo ""
    echo "🎉 Complete Analysis Finished!"
    echo "=============================="
    echo ""
    print_success "Dashboard is now available at: http://localhost:8000/quicknode_dashboard.html"
    echo ""
    echo "📊 What you can see:"
    echo "  • Network statistics for the last month"
    echo "  • Interactive charts and graphs"
    echo "  • Sample transaction data"
    echo "  • Real-time data visualization"
    echo ""
    echo "📁 Generated files:"
    echo "  • quicknode_data_analysis.json - Raw data analysis"
    echo "  • quicknode_dashboard.html - Web dashboard"
    echo "  • QUICKNODE_DASHBOARD_SUMMARY.md - Detailed report"
    echo ""
    echo "🔄 To stop the server:"
    echo "   pkill -f 'python3 -m http.server 8000'"
    echo ""
    echo "🔄 To refresh data:"
    echo "   ./run_complete_analysis.sh"
    echo ""
    
    # Keep the script running
    wait $SERVER_PID
else
    print_error "Failed to start web server"
    exit 1
fi
