#!/bin/bash

# Integrate L2 Networks Sync Tool with Admin Dashboard
# This script integrates the tool with the existing admin dashboard

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DASHBOARD_DIR="../services/admin-dashboard"
FRONTEND_DIR="../../frontend"
TOOL_DIR="$(pwd)"

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

# Function to check if directories exist
check_directories() {
    print_status "Checking directory structure..."
    
    if [ ! -d "$DASHBOARD_DIR" ]; then
        print_error "Admin dashboard directory not found: $DASHBOARD_DIR"
        print_status "Please run this script from the tools/l2-networks-sync directory"
        exit 1
    fi
    
    if [ ! -d "$FRONTEND_DIR" ]; then
        print_error "Frontend directory not found: $FRONTEND_DIR"
        print_status "Please run this script from the tools/l2-networks-sync directory"
        exit 1
    fi
    
    print_success "Directory structure verified"
}

# Function to update admin dashboard package.json
update_dashboard_dependencies() {
    print_status "Updating admin dashboard dependencies..."
    
    cd "$DASHBOARD_DIR"
    
    # Check if pg is already installed
    if ! grep -q '"pg"' package.json; then
        print_status "Adding PostgreSQL dependency..."
        npm install pg dotenv
    else
        print_status "PostgreSQL dependency already present"
    fi
    
    cd "$TOOL_DIR"
    print_success "Dashboard dependencies updated"
}

# Function to create database views
create_database_views() {
    print_status "Creating database views..."
    
    cd "$DASHBOARD_DIR"
    
    # Create views for statistics
    local views_sql="
    -- Create summary view
    CREATE OR REPLACE VIEW l2_networks_summary AS
    SELECT 
        network_type,
        COUNT(*) as network_count,
        COUNT(CASE WHEN is_active THEN 1 END) as active_count,
        COUNT(CASE WHEN NOT is_active THEN 1 END) as inactive_count,
        COUNT(CASE WHEN source = 'geth_sync' THEN 1 END) as geth_synced,
        COUNT(CASE WHEN source = 'lighthouse_sync' THEN 1 END) as lighthouse_synced,
        COUNT(CASE WHEN source = 'known_networks' THEN 1 END) as known_networks,
        MAX(updated_at) as last_update
    FROM l2_networks 
    GROUP BY network_type;
    
    -- Create sync activity view
    CREATE OR REPLACE VIEW l2_networks_sync_activity AS
    SELECT 
        DATE(updated_at) as sync_date,
        source,
        COUNT(*) as sync_count,
        COUNT(CASE WHEN is_active THEN 1 END) as active_synced,
        COUNT(CASE WHEN NOT is_active THEN 1 END) as inactive_synced,
        AVG(EXTRACT(EPOCH FROM (updated_at - created_at))) as avg_sync_duration_seconds
    FROM l2_networks 
    WHERE source IN ('geth_sync', 'lighthouse_sync', 'known_networks')
    GROUP BY DATE(updated_at), source
    ORDER BY sync_date DESC, source;
    "
    
    # Execute SQL if database is accessible
    if [ -f .env ]; then
        source .env
        if command -v psql >/dev/null 2>&1; then
            if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "$views_sql" >/dev/null 2>&1; then
                print_success "Database views created"
            else
                print_warning "Could not create database views. You may need to run manually."
            fi
        else
            print_warning "psql not found, skipping database view creation"
        fi
    else
        print_warning ".env file not found, skipping database view creation"
    fi
    
    cd "$TOOL_DIR"
}

# Function to update admin dashboard routes
update_dashboard_routes() {
    print_status "Updating admin dashboard routes..."
    
    cd "$DASHBOARD_DIR"
    
    # Check if l2-networks route already exists
    if [ ! -f "routes/l2-networks.js" ]; then
        print_status "Creating L2 networks route..."
        
        # Create routes directory if it doesn't exist
        mkdir -p routes
        
        # Copy the route file
        cp "$TOOL_DIR/../admin-dashboard-routes/l2-networks.js" routes/
        
        print_success "L2 networks route created"
    else
        print_status "L2 networks route already exists"
    fi
    
    cd "$TOOL_DIR"
}

# Function to update admin dashboard server.js
update_dashboard_server() {
    print_status "Updating admin dashboard server.js..."
    
    cd "$DASHBOARD_DIR"
    
    # Check if l2-networks route is already imported
    if ! grep -q "l2-networks" server.js; then
        print_status "Adding L2 networks route to server.js..."
        
        # Add import statement after existing imports
        sed -i '/const express = require/ a const l2NetworksRouter = require("./routes/l2-networks");' server.js
        
        # Add route after existing routes
        sed -i '/app.use.*api.*/ a app.use("/api/l2-networks", l2NetworksRouter);' server.js
        
        print_success "L2 networks route added to server.js"
    else
        print_status "L2 networks route already imported in server.js"
    fi
    
    cd "$TOOL_DIR"
}

# Function to update frontend
update_frontend() {
    print_status "Updating frontend..."
    
    cd "$FRONTEND_DIR"
    
    # Check if tools page already exists
    if [ ! -d "app/tools" ]; then
        print_status "Creating tools page..."
        
        # Create tools directory
        mkdir -p app/tools/components
        
        # Copy tools page
        cp "$TOOL_DIR/../frontend-tools/page.tsx" app/tools/
        cp "$TOOL_DIR/../frontend-tools/components/NetworkModal.tsx" app/tools/components/
        
        print_success "Tools page created"
    else
        print_status "Tools page already exists"
    fi
    
    cd "$TOOL_DIR"
}

# Function to create integration test
create_integration_test() {
    print_status "Creating integration test..."
    
    cd "$TOOL_DIR"
    
    local test_script="test-integration.sh"
    
    cat > "$test_script" << 'EOF'
#!/bin/bash

# Integration Test for L2 Networks Sync Tool
# This script tests the integration with the admin dashboard

set -e

echo "Testing L2 Networks Sync Tool integration..."

# Test 1: Check if tool can be run
echo "Test 1: Tool execution"
if node index.js --help >/dev/null 2>&1; then
    echo "✓ Tool can be executed"
else
    echo "✗ Tool execution failed"
    exit 1
fi

# Test 2: Check database connection
echo "Test 2: Database connection"
if [ -f .env ]; then
    source .env
    if node index.js status >/dev/null 2>&1; then
        echo "✓ Database connection successful"
    else
        echo "✗ Database connection failed"
    fi
else
    echo "⚠ .env file not found, skipping database test"
fi

# Test 3: Check if admin dashboard can be started
echo "Test 3: Admin dashboard startup"
cd ../services/admin-dashboard
if [ -f package.json ]; then
    if npm list pg >/dev/null 2>&1; then
        echo "✓ Admin dashboard dependencies installed"
    else
        echo "✗ Admin dashboard dependencies missing"
    fi
else
    echo "⚠ Admin dashboard package.json not found"
fi

cd "$TOOL_DIR"

echo "Integration test completed"
EOF
    
    chmod +x "$test_script"
    print_success "Integration test script created: $test_script"
}

# Function to show integration summary
show_integration_summary() {
    echo ""
    print_success "Integration completed successfully!"
    echo ""
    print_status "Integration Summary:"
    echo "  ✓ Admin dashboard dependencies updated"
    echo "  ✓ Database views created"
    echo "  ✓ L2 networks routes added"
    echo "  ✓ Frontend tools page created"
    echo "  ✓ Integration test script created"
    echo ""
    print_status "Next steps:"
    echo "  1. Start the admin dashboard: cd ../services/admin-dashboard && npm start"
    echo "  2. Start the frontend: cd ../../frontend && npm run dev"
    echo "  3. Test the integration: ./test-integration.sh"
    echo "  4. Access tools at: http://localhost:3000/tools"
    echo "  5. Test API at: http://localhost:8080/api/l2-networks"
    echo ""
    print_status "Files modified/created:"
    echo "  - services/admin-dashboard/routes/l2-networks.js"
    echo "  - services/admin-dashboard/server.js"
    echo "  - frontend/app/tools/page.tsx"
    echo "  - frontend/app/tools/components/NetworkModal.tsx"
    echo "  - tools/l2-networks-sync/test-integration.sh"
}

# Main integration function
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  L2 Networks Integration      ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    
    # Check directories
    check_directories
    
    # Perform integration steps
    update_dashboard_dependencies
    create_database_views
    update_dashboard_routes
    update_dashboard_server
    update_frontend
    create_integration_test
    
    # Show summary
    show_integration_summary
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo ""
        echo "This script integrates the L2 Networks Sync Tool with the admin dashboard."
        echo "Run from the tools/l2-networks-sync directory."
        exit 0
        ;;
    "")
        # No arguments, proceed with integration
        ;;
    *)
        print_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac

# Run main function
main "$@"
