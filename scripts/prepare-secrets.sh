#!/bin/bash

# DEFIMON Secrets Preparation Script
# This script helps prepare base64 encoded secrets for Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SECRETS_FILE="$PROJECT_ROOT/secrets.env"

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

# Function to generate random secret
generate_random_secret() {
    local length="${1:-32}"
    openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
}

# Main function
main() {
    print_status "Preparing DEFIMON secrets..."
    
    # Create secrets file
    cat > "$SECRETS_FILE" << 'EOF'
# DEFIMON Secrets Configuration
# Plaintext secrets for Kubernetes (applied by scripts/apply-secrets.sh)
# DO NOT commit this file to version control!

# JWT Configuration
JWT_SECRET_KEY=$(generate_random_secret 64)

# Service Secret Keys
ADMIN_DASHBOARD_SECRET_KEY=$(generate_random_secret 32)
ANALYTICS_API_SECRET_KEY=$(generate_random_secret 32)
AI_ML_SERVICE_SECRET_KEY=$(generate_random_secret 32)

# Database Password (replace with your actual password)
GOOGLE_CLOUD_SQL_PASSWORD=your-secure-password

# External API Keys (replace with your actual keys)
# External API Keys (Optional - commented out as we use our own nodes)
# ETHERSCAN_API_KEY=your-etherscan-api-key
# POLYGONSCAN_API_KEY=your-polygonscan-api-key
# ARBISCAN_API_KEY=your-arbiscan-api-key
# OPTIMISTIC_ETHERSCAN_API_KEY=your-optimistic-etherscan-api-key

# Notification Services (optional)
SLACK_WEBHOOK_URL=your-slack-webhook-url
TELEGRAM_BOT_TOKEN=your-telegram-bot-token
TELEGRAM_CHAT_ID=your-telegram-chat-id

# Google Cloud Service Account Key (JSON path, optional)
# GOOGLE_CLOUD_SERVICE_ACCOUNT_KEY_JSON_PATH=./gcp-service-account-key.json
EOF

    print_success "Secrets file created at: $SECRETS_FILE"
    print_warning "Please edit the secrets file and replace placeholder values with your actual secrets"
    print_warning "DO NOT commit this file to version control!"
    
    # Add to .gitignore if not already there
    if ! grep -q "^secrets.env$" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
        echo "secrets.env" >> "$PROJECT_ROOT/.gitignore"
        print_success "Added secrets.env to .gitignore"
    fi
    
    print_status "Next steps:"
    echo "1. Edit $SECRETS_FILE and replace placeholder values"
    echo "2. Update your .env file with Google Cloud configuration"
    echo "3. Apply secrets: ./scripts/apply-secrets.sh"
    echo "4. Run the deployment script: ./scripts/deploy-google-cloud.sh"
}

# Run main function
main "$@"
