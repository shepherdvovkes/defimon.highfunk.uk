#!/bin/bash

# Telegram Bot VM Deployment Script
# This script runs on the VM instance to deploy and start the Telegram bot

set -e

# Configuration
BOT_DIR="$HOME/telegram-bot"
LOG_DIR="$BOT_DIR/logs"
ENV_FILE="$BOT_DIR/.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as correct user
check_user() {
    if [ "$EUID" -eq 0 ]; then
        print_error "This script should not be run as root"
        exit 1
    fi
    
    print_status "Running as user: $(whoami)"
}

# Check if Docker is running
check_docker() {
    print_status "Checking Docker status..."
    
    if ! systemctl is-active --quiet docker; then
        print_error "Docker service is not running"
        exit 1
    fi
    
    if ! docker info &>/dev/null; then
        print_error "Docker is not accessible. User may not be in docker group"
        print_status "Adding user to docker group and restarting session..."
        sudo usermod -aG docker $USER
        print_warning "Please log out and log back in, or restart the VM"
        exit 1
    fi
    
    print_status "Docker is running and accessible"
}

# Create environment file
setup_environment() {
    print_status "Setting up environment configuration..."
    
    if [ ! -f "$ENV_FILE" ]; then
        print_warning "No .env file found. Creating from template..."
        cp env.example .env
        print_warning "Please edit .env file with your actual configuration before starting the bot"
        print_warning "Required variables: TELEGRAM_BOT_TOKEN, GOOGLE_CLOUD_PROJECT_ID"
        return 1
    fi
    
    # Validate required environment variables
    source "$ENV_FILE"
    
    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ "$TELEGRAM_BOT_TOKEN" = "your_telegram_bot_token_here" ]; then
        print_error "TELEGRAM_BOT_TOKEN is not set or is default value"
        return 1
    fi
    
    if [ -z "$GOOGLE_CLOUD_PROJECT_ID" ] || [ "$GOOGLE_CLOUD_PROJECT_ID" = "your_gcp_project_id_here" ]; then
        print_error "GOOGLE_CLOUD_PROJECT_ID is not set or is default value"
        return 1
    fi
    
    print_status "Environment configuration is valid"
    return 0
}

# Set up Google Cloud authentication
setup_gcloud_auth() {
    print_status "Setting up Google Cloud authentication..."
    
    # Check if already authenticated
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_status "Already authenticated with Google Cloud"
        return 0
    fi
    
    # Try to use application default credentials
    if gcloud auth application-default print-access-token &>/dev/null; then
        print_status "Using application default credentials"
        return 0
    fi
    
    print_warning "No Google Cloud authentication found"
    print_warning "You may need to authenticate manually or set up service account credentials"
    print_warning "Run: gcloud auth login"
    return 1
}

# Build and start the bot
deploy_bot() {
    print_status "Building and starting Telegram bot..."
    
    # Stop any existing containers
    if docker-compose ps | grep -q "gcloud-telegram-bot"; then
        print_status "Stopping existing bot containers..."
        docker-compose down
    fi
    
    # Build the image
    print_status "Building Docker image..."
    docker-compose build --no-cache
    
    # Start the bot
    print_status "Starting Telegram bot..."
    docker-compose up -d
    
    # Wait for bot to be ready
    print_status "Waiting for bot to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker ps --format "table {{.Names}}" | grep -q "gcloud-telegram-bot"; then
            if docker inspect gcloud-telegram-bot --format='{{.State.Status}}' | grep -q "running"; then
                print_status "Telegram bot is running successfully"
                return 0
            fi
        fi
        
        print_status "Waiting for bot to be ready... (attempt $attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    print_error "Bot did not start within expected time"
    return 1
}

# Verify bot is working
verify_bot() {
    print_status "Verifying bot functionality..."
    
    # Check container logs for any errors
    local logs=$(docker logs gcloud-telegram-bot 2>&1 | tail -20)
    
    if echo "$logs" | grep -i "error\|exception\|traceback" | head -5; then
        print_warning "Found potential errors in bot logs:"
        echo "$logs" | grep -i "error\|exception\|traceback" | head -5
    fi
    
    # Check if bot is responding to health check
    if docker exec gcloud-telegram-bot python -c "import sys; sys.exit(0)" 2>/dev/null; then
        print_status "Bot container is healthy"
    else
        print_warning "Bot container health check failed"
    fi
    
    print_status "Bot verification completed"
}

# Set up monitoring and logging
setup_monitoring() {
    print_status "Setting up monitoring and logging..."
    
    # Create log directory if it doesn't exist
    mkdir -p "$LOG_DIR"
    
    # Set up log rotation for application logs
    if [ ! -f /etc/logrotate.d/telegram-bot ]; then
        sudo tee /etc/logrotate.d/telegram-bot > /dev/null << EOF
$LOG_DIR/*.log {
    rotate 7
    daily
    compress
    size=10M
    missingok
    delaycompress
    copytruncate
    create 644 $USER $USER
}
EOF
        print_status "Log rotation configured"
    fi
    
    # Create a simple status monitoring script
    cat > "$BOT_DIR/monitor-bot.sh" << 'EOF'
#!/bin/bash
# Simple bot monitoring script

BOT_DIR="$(dirname "$0")"
LOG_FILE="$BOT_DIR/logs/monitor.log"

echo "$(date): Checking bot status..." >> "$LOG_FILE"

# Check if container is running
if ! docker ps --format "table {{.Names}}" | grep -q "gcloud-telegram-bot"; then
    echo "$(date): Bot container is not running, restarting..." >> "$LOG_FILE"
    cd "$BOT_DIR"
    docker-compose up -d
    exit 1
fi

# Check container health
if ! docker inspect gcloud-telegram-bot --format='{{.State.Health.Status}}' | grep -q "healthy"; then
    echo "$(date): Bot container is unhealthy, restarting..." >> "$LOG_FILE"
    cd "$BOT_DIR"
    docker-compose restart
    exit 1
fi

echo "$(date): Bot is healthy" >> "$LOG_FILE"
exit 0
EOF
    
    chmod +x "$BOT_DIR/monitor-bot.sh"
    
    # Add to crontab if not already there
    if ! crontab -l 2>/dev/null | grep -q "monitor-bot.sh"; then
        (crontab -l 2>/dev/null; echo "*/2 * * * * $BOT_DIR/monitor-bot.sh") | crontab -
        print_status "Monitoring cron job added"
    fi
    
    print_status "Monitoring setup completed"
}

# Show deployment status
show_status() {
    print_status "Deployment completed!"
    echo
    echo "Telegram Bot Status:"
    echo "===================="
    echo "Container Status: $(docker ps --format "table {{.Names}}\t{{.Status}}" | grep gcloud-telegram-bot || echo "Not running")"
    echo "Logs Location: $LOG_DIR"
    echo "Environment File: $ENV_FILE"
    echo
    echo "Useful Commands:"
    echo "================="
    echo "View logs: docker logs gcloud-telegram-bot"
    echo "Restart bot: docker-compose restart"
    echo "Stop bot: docker-compose down"
    echo "Start bot: docker-compose up -d"
    echo "Check status: docker-compose ps"
    echo
    echo "Monitoring:"
    echo "==========="
    echo "Health check: $BOT_DIR/health-check.sh"
    echo "Monitor script: $BOT_DIR/monitor-bot.sh"
    echo "Cron jobs: crontab -l"
}

# Main deployment flow
main() {
    print_status "Starting Telegram Bot deployment on VM..."
    echo
    
    check_user
    check_docker
    
    if ! setup_environment; then
        print_error "Environment setup failed. Please configure .env file and run again."
        exit 1
    fi
    
    setup_gcloud_auth
    deploy_bot
    verify_bot
    setup_monitoring
    show_status
}

# Run main function
main "$@"
