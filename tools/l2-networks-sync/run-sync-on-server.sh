#!/bin/bash

# Script to run L2 network synchronization on Vovkes server
# This script connects to the server and runs the sync process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVER_USER="vovkes"
SERVER_HOST="vovkes-server"
PROJECT_DIR="/home/vovkes/defimon.highfunk.uk"
L2_SYNC_DIR="$PROJECT_DIR/tools/l2-networks-sync"
OUTPUT_DIR="$L2_SYNC_DIR/output"
LOG_FILE="$L2_SYNC_DIR/sync-$(date +%Y%m%d-%H%M%S).log"

echo -e "${BLUE}🚀 Starting L2 Network Synchronization on Vovkes Server${NC}"
echo -e "${BLUE}==================================================${NC}"
echo -e "Server: ${GREEN}$SERVER_HOST${NC}"
echo -e "Project: ${GREEN}$PROJECT_DIR${NC}"
echo -e "Log file: ${GREEN}$LOG_FILE${NC}"
echo ""

# Function to run command on server
run_on_server() {
    local cmd="$1"
    echo -e "${YELLOW}Running on server:${NC} $cmd"
    ssh "$SERVER_USER@$SERVER_HOST" "$cmd"
}

# Function to check if server is accessible
check_server() {
    echo -e "${BLUE}Checking server connectivity...${NC}"
    if ! ping -c 1 "$SERVER_HOST" > /dev/null 2>&1; then
        echo -e "${RED}❌ Cannot reach server $SERVER_HOST${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Server is reachable${NC}"
}

# Function to check if project directory exists
check_project() {
    echo -e "${BLUE}Checking project directory...${NC}"
    if ! run_on_server "[ -d '$PROJECT_DIR' ]"; then
        echo -e "${RED}❌ Project directory $PROJECT_DIR does not exist on server${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Project directory exists${NC}"
}

# Function to check if L2 sync directory exists
check_l2_sync() {
    echo -e "${BLUE}Checking L2 sync directory...${NC}"
    if ! run_on_server "[ -d '$L2_SYNC_DIR' ]"; then
        echo -e "${RED}❌ L2 sync directory $L2_SYNC_DIR does not exist on server${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ L2 sync directory exists${NC}"
}

# Function to check dependencies
check_dependencies() {
    echo -e "${BLUE}Checking dependencies...${NC}"
    
    # Check Node.js
    if ! run_on_server "command -v node >/dev/null 2>&1"; then
        echo -e "${RED}❌ Node.js is not installed on server${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Node.js is available${NC}"
    
    # Check npm
    if ! run_on_server "command -v npm >/dev/null 2>&1"; then
        echo -e "${RED}❌ npm is not installed on server${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ npm is available${NC}"
    
    # Check if package.json exists and has dependencies
    if ! run_on_server "[ -f '$L2_SYNC_DIR/package.json' ]"; then
        echo -e "${RED}❌ package.json not found in L2 sync directory${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ package.json found${NC}"
}

# Function to install dependencies
install_dependencies() {
    echo -e "${BLUE}Installing dependencies...${NC}"
    run_on_server "cd '$L2_SYNC_DIR' && npm install"
    echo -e "${GREEN}✅ Dependencies installed${NC}"
}

# Function to create output directory
create_output_dir() {
    echo -e "${BLUE}Creating output directory...${NC}"
    run_on_server "mkdir -p '$OUTPUT_DIR'"
    echo -e "${GREEN}✅ Output directory created${NC}"
}

# Function to run synchronization
run_sync() {
    echo -e "${BLUE}Running L2 network synchronization...${NC}"
    echo -e "${YELLOW}This may take several minutes...${NC}"
    
    # Set environment variables for the sync
    local env_vars="BEACON_API_URL=http://localhost:5052 OUTPUT_DIR=$OUTPUT_DIR RUN_VALIDATION=true"
    
    # Run the sync with logging
    run_on_server "cd '$L2_SYNC_DIR' && $env_vars node sync-l2-networks.js" 2>&1 | tee "$LOG_FILE"
    
    # Check exit status
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "${GREEN}✅ Synchronization completed successfully${NC}"
    else
        echo -e "${RED}❌ Synchronization failed${NC}"
        exit 1
    fi
}

# Function to download results
download_results() {
    echo -e "${BLUE}Downloading results from server...${NC}"
    
    local local_output_dir="./output"
    mkdir -p "$local_output_dir"
    
    # Download all result files
    scp -r "$SERVER_USER@$SERVER_HOST:$OUTPUT_DIR/*" "$local_output_dir/"
    
    echo -e "${GREEN}✅ Results downloaded to $local_output_dir${NC}"
}

# Function to show results summary
show_results() {
    echo -e "${BLUE}Results Summary:${NC}"
    echo -e "${BLUE}===============${NC}"
    
    if [ -f "./output/latest-sync-report.json" ]; then
        echo -e "${GREEN}📊 Latest sync report:${NC}"
        cat "./output/latest-sync-report.json" | jq '.sync_info' 2>/dev/null || echo "Report available but jq not installed for pretty printing"
    fi
    
    if [ -f "./output/latest-l2-networks.json" ]; then
        local l2_count=$(cat "./output/latest-l2-networks.json" | jq 'length' 2>/dev/null || echo "unknown")
        echo -e "${GREEN}🔗 L2 Networks found: $l2_count${NC}"
    fi
    
    echo -e "${BLUE}📁 All results saved to: ./output/${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting L2 Network Synchronization Process${NC}"
    echo ""
    
    # Pre-flight checks
    check_server
    check_project
    check_l2_sync
    check_dependencies
    
    # Setup
    install_dependencies
    create_output_dir
    
    # Run synchronization
    run_sync
    
    # Download and show results
    download_results
    show_results
    
    echo ""
    echo -e "${GREEN}🎉 L2 Network Synchronization completed successfully!${NC}"
    echo -e "${BLUE}Check the output directory for detailed results.${NC}"
}

# Run main function
main "$@"
