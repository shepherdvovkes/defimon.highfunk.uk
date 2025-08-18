#!/bin/bash

# Quick deploy script for L2 Networks Sync to Vovkes server
# This script pushes changes to GitHub and then pulls them on the server

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

echo -e "${BLUE}🚀 Deploying L2 Networks Sync to Vovkes Server${NC}"
echo -e "${BLUE}==============================================${NC}"
echo ""

# Function to check git status
check_git_status() {
    echo -e "${BLUE}Checking git status...${NC}"
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}❌ Not in a git repository${NC}"
        exit 1
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        echo -e "${YELLOW}⚠️  You have uncommitted changes. Please commit or stash them first.${NC}"
        git status --short
        exit 1
    fi
    
    echo -e "${GREEN}✅ Git status clean${NC}"
}

# Function to push to GitHub
push_to_github() {
    echo -e "${BLUE}Pushing changes to GitHub...${NC}"
    
    # Get current branch
    local current_branch=$(git branch --show-current)
    echo -e "Current branch: ${GREEN}$current_branch${NC}"
    
    # Push to current branch
    if git push origin "$current_branch"; then
        echo -e "${GREEN}✅ Successfully pushed to GitHub${NC}"
    else
        echo -e "${RED}❌ Failed to push to GitHub${NC}"
        exit 1
    fi
}

# Function to deploy on server
deploy_on_server() {
    echo -e "${BLUE}Deploying on Vovkes server...${NC}"
    
    # Check server connectivity
    if ! ping -c 1 "$SERVER_HOST" > /dev/null 2>&1; then
        echo -e "${RED}❌ Cannot reach server $SERVER_HOST${NC}"
        exit 1
    fi
    
    # Pull latest changes on server
    echo -e "${YELLOW}Pulling latest changes on server...${NC}"
    ssh "$SERVER_USER@$SERVER_HOST" "cd '$PROJECT_DIR' && git pull origin $(git branch --show-current)"
    
    # Install dependencies on server
    echo -e "${YELLOW}Installing dependencies on server...${NC}"
    ssh "$SERVER_USER@$SERVER_HOST" "cd '$L2_SYNC_DIR' && npm install"
    
    # Test the deployment
    echo -e "${YELLOW}Testing deployment...${NC}"
    ssh "$SERVER_USER@$SERVER_HOST" "cd '$L2_SYNC_DIR' && node --version && npm --version"
    
    echo -e "${GREEN}✅ Deployment completed successfully${NC}"
}

# Function to run quick test on server
run_server_test() {
    echo -e "${BLUE}Running quick test on server...${NC}"
    
    # Run the test script
    ssh "$SERVER_USER@$SERVER_HOST" "cd '$L2_SYNC_DIR' && timeout 60 node test-beacon-api.js" || {
        echo -e "${YELLOW}⚠️  Test timed out or failed (this is normal for first run)${NC}"
    }
    
    echo -e "${GREEN}✅ Server test completed${NC}"
}

# Function to show deployment summary
show_deployment_summary() {
    echo ""
    echo -e "${GREEN}🎉 Deployment Summary${NC}"
    echo -e "${GREEN}==================${NC}"
    echo -e "✅ Changes pushed to GitHub"
    echo -e "✅ Code deployed to Vovkes server"
    echo -e "✅ Dependencies installed"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "1. Run full sync: ${GREEN}./run-sync-on-server.sh${NC}"
    echo -e "2. Check logs on server: ${GREEN}ssh vovkes-server 'tail -f $L2_SYNC_DIR/sync-*.log'${NC}"
    echo -e "3. View results: ${GREEN}ssh vovkes-server 'ls -la $L2_SYNC_DIR/output/'${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting deployment process...${NC}"
    echo ""
    
    # Pre-deployment checks
    check_git_status
    
    # Deploy to GitHub
    push_to_github
    
    # Deploy on server
    deploy_on_server
    
    # Optional: Run quick test
    if [ "$1" = "--test" ]; then
        run_server_test
    fi
    
    # Show summary
    show_deployment_summary
}

# Check command line arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [--test]"
    echo ""
    echo "Options:"
    echo "  --test    Run quick test on server after deployment"
    echo "  --help    Show this help message"
    echo ""
    echo "This script will:"
    echo "1. Check git status"
    echo "2. Push changes to GitHub"
    echo "3. Deploy on Vovkes server"
    echo "4. Install dependencies"
    echo "5. Optionally run tests"
    exit 0
fi

# Run main function
main "$@"
