#!/bin/bash

# DeFi Analytics Platform - Shrimp Server Local Storage Deployment
# This script deploys the local storage system on the shrimp server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_status() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Configuration
STORAGE_DIR="/Users/vovkes/defi-storage"
HOT_STORAGE_PATH="$STORAGE_DIR/hot"
WARM_STORAGE_PATH="$STORAGE_DIR/warm"
USB_STORAGE_PATH="/Volumes/USB_APFS/defi-warm"

print_header "DeFi Analytics Platform - Shrimp Server Storage Deployment"
echo "Timestamp: $(date)"
echo "Target Server: Shrimp (Local Domain Server)"
echo ""

# Check if we can connect to shrimp
check_connection() {
    print_status "Checking connection to shrimp server..."
    
    if ssh shrimp "echo 'Connection successful'" > /dev/null 2>&1; then
        print_success "Connected to shrimp server"
    else
        print_error "Cannot connect to shrimp server"
        exit 1
    fi
}

# Setup storage directories
setup_storage_directories() {
    print_status "Setting up storage directories on shrimp..."
    
    ssh shrimp << 'EOF'
        # Create storage directories
        mkdir -p /Users/vovkes/defi-storage/{hot,warm}
        mkdir -p /Volumes/USB_APFS/defi-warm
        
        # Set permissions
        chmod 755 /Users/vovkes/defi-storage
        chmod 755 /Users/vovkes/defi-storage/hot
        chmod 755 /Users/vovkes/defi-storage/warm
        chmod 755 /Volumes/USB_APFS/defi-warm
        
        # Create symbolic link for warm storage to USB
        ln -sf /Volumes/USB_APFS/defi-warm /Users/vovkes/defi-storage/warm
        
        echo "Storage directories created successfully"
EOF
    
    print_success "Storage directories setup completed"
}

# Install Python dependencies
install_dependencies() {
    print_status "Installing Python dependencies on shrimp..."
    
    ssh shrimp << 'EOF'
        # Check if Python 3 is available
        if ! command -v python3 &> /dev/null; then
            echo "Python 3 not found, installing..."
            # For macOS, we'll use pip3
            if ! command -v pip3 &> /dev/null; then
                echo "pip3 not found, please install Python 3 first"
                exit 1
            fi
        fi
        
        # Install required packages
        pip3 install --user schedule psutil
        
        echo "Dependencies installed successfully"
EOF
    
    print_success "Dependencies installation completed"
}

# Create configuration file
create_config() {
    print_status "Creating storage configuration..."
    
    ssh shrimp << 'EOF'
        cat > /Users/vovkes/defi-storage/config.json << 'CONFIG_EOF'
{
    "hot_storage_path": "/Users/vovkes/defi-storage/hot",
    "warm_storage_path": "/Users/vovkes/defi-storage/warm",
    "compression_enabled": true,
    "auto_cleanup_enabled": true,
    "hot_storage_size_gb": 500,
    "warm_storage_size_gb": 477,
    "hot_data_retention_days": 7,
    "warm_data_retention_days": 30
}
CONFIG_EOF
        
        echo "Configuration file created"
EOF
    
    print_success "Configuration created"
}

# Deploy storage manager service
deploy_storage_manager() {
    print_status "Deploying storage manager service..."
    
    ssh shrimp << 'EOF'
        cd /Users/vovkes/defi-storage
        
        # Create a simple startup script
        cat > start_storage_manager.sh << 'SCRIPT_EOF'
#!/bin/bash
cd /Users/vovkes/defi-storage
export HOT_STORAGE_PATH="/Users/vovkes/defi-storage/hot"
export WARM_STORAGE_PATH="/Users/vovkes/defi-storage/warm"
export COMPRESSION_ENABLED="true"
export AUTO_CLEANUP_ENABLED="true"

python3 storage_manager.py
SCRIPT_EOF
        
        chmod +x start_storage_manager.sh
        
        # Create a launchd service file
        cat > /Users/vovkes/Library/LaunchAgents/com.defimon.storage-manager.plist << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.defimon.storage-manager</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/vovkes/defi-storage/start_storage_manager.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/vovkes/defi-storage/storage-manager.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/vovkes/defi-storage/storage-manager-error.log</string>
</dict>
</plist>
PLIST_EOF
        
        echo "Storage manager service deployed"
EOF
    
    print_success "Storage manager service deployed"
}

# Deploy data manager service
deploy_data_manager() {
    print_status "Deploying data manager service..."
    
    ssh shrimp << 'EOF'
        cd /Users/vovkes/defi-storage
        
        # Create a simple startup script
        cat > start_data_manager.sh << 'SCRIPT_EOF'
#!/bin/bash
cd /Users/vovkes/defi-storage
export HOT_STORAGE_PATH="/Users/vovkes/defi-storage/hot"
export WARM_STORAGE_PATH="/Users/vovkes/defi-storage/warm"
export COMPRESSION_ENABLED="true"
export AUTO_CLEANUP_ENABLED="true"

python3 data_manager.py
SCRIPT_EOF
        
        chmod +x start_data_manager.sh
        
        # Create a launchd service file
        cat > /Users/vovkes/Library/LaunchAgents/com.defimon.data-manager.plist << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.defimon.data-manager</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/vovkes/defi-storage/start_data_manager.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/vovkes/defi-storage/data-manager.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/vovkes/defi-storage/data-manager-error.log</string>
</dict>
</plist>
PLIST_EOF
        
        echo "Data manager service deployed"
EOF
    
    print_success "Data manager service deployed"
}

# Start services
start_services() {
    print_status "Starting storage services..."
    
    ssh shrimp << 'EOF'
        # Load and start the services
        launchctl load ~/Library/LaunchAgents/com.defimon.storage-manager.plist
        launchctl load ~/Library/LaunchAgents/com.defimon.data-manager.plist
        
        echo "Services started successfully"
EOF
    
    print_success "Services started"
}

# Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    ssh shrimp << 'EOF'
        echo "=== Storage Directories ==="
        ls -la /Users/vovkes/defi-storage/
        
        echo ""
        echo "=== USB Storage ==="
        ls -la /Volumes/USB_APFS/defi-warm/
        
        echo ""
        echo "=== Service Status ==="
        launchctl list | grep defimon
        
        echo ""
        echo "=== Storage Usage ==="
        df -h /Users/vovkes/defi-storage/hot
        df -h /Volumes/USB_APFS/defi-warm
EOF
    
    print_success "Deployment verification completed"
}

# Main deployment function
main() {
    print_header "Starting DeFi Analytics Storage Deployment on Shrimp"
    
    check_connection
    setup_storage_directories
    install_dependencies
    create_config
    deploy_storage_manager
    deploy_data_manager
    start_services
    verify_deployment
    
    print_header "Deployment Summary"
    echo ""
    echo "✅ Local storage system deployed successfully on shrimp!"
    echo ""
    echo "📊 Storage Tiers (Shrimp Server):"
    echo "   🔥 Hot Storage: 500Gi (Internal NVME)"
    echo "   🌡️ Warm Storage: 477Gi (External USB Drive)"
    echo ""
    echo "🔄 Services Deployed:"
    echo "   • Storage Manager Service (launchd)"
    echo "   • Data Manager Service (launchd)"
    echo "   • Local Storage Optimization"
    echo ""
    echo "📈 Total Local Storage Capacity: 977 Gi"
    echo ""
    echo "🔗 Monitoring:"
    echo "   • Storage Manager Logs: /Users/vovkes/defi-storage/storage-manager.log"
    echo "   • Data Manager Logs: /Users/vovkes/defi-storage/data-manager.log"
    echo "   • Configuration: /Users/vovkes/defi-storage/config.json"
    echo ""
    echo "📋 Next Steps:"
    echo "   1. Configure data ingestion pipelines"
    echo "   2. Setup automated data migration policies"
    echo "   3. Monitor storage usage and performance"
    echo "   4. Test data storage and retrieval"
    echo ""
    print_success "DeFi Analytics Local Storage deployment on shrimp completed!"
}

# Run main function
main "$@"
