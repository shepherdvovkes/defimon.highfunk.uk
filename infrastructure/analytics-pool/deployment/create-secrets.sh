#!/bin/bash

# DEFIMON Analytics Pool - Secrets Creation Script
# Этот скрипт создает необходимые секреты для аналитического пула

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")/../.."

# Load configuration
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
else
    echo -e "${YELLOW}Warning: .env file not found. Using default values.${NC}"
fi

# Default values
POSTGRES_USER=${POSTGRES_USER:-"postgres"}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-"password"}
CLICKHOUSE_USER=${CLICKHOUSE_USER:-"default"}
CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD:-"password"}
REDIS_PASSWORD=${REDIS_PASSWORD:-"password"}
GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-"admin123"}
JWT_SECRET_KEY=${JWT_SECRET_KEY:-"your-jwt-secret-key-here"}

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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    # Check if we're connected to a cluster
    if ! kubectl cluster-info &>/dev/null; then
        print_error "Not connected to a Kubernetes cluster. Please connect first."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Function to create namespace if it doesn't exist
create_namespace() {
    print_status "Creating analytics namespace..."
    
    if ! kubectl get namespace analytics &>/dev/null; then
        kubectl create namespace analytics
        print_success "Namespace 'analytics' created"
    else
        print_warning "Namespace 'analytics' already exists"
    fi
}

# Function to create PostgreSQL secrets
create_postgresql_secrets() {
    print_status "Creating PostgreSQL secrets..."
    
    kubectl create secret generic postgresql-secrets \
        --from-literal=username="$POSTGRES_USER" \
        --from-literal=password="$POSTGRES_PASSWORD" \
        -n analytics --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "PostgreSQL secrets created"
}

# Function to create ClickHouse secrets
create_clickhouse_secrets() {
    print_status "Creating ClickHouse secrets..."
    
    kubectl create secret generic clickhouse-secrets \
        --from-literal=username="$CLICKHOUSE_USER" \
        --from-literal=password="$CLICKHOUSE_PASSWORD" \
        -n analytics --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "ClickHouse secrets created"
}

# Function to create Redis secrets
create_redis_secrets() {
    print_status "Creating Redis secrets..."
    
    kubectl create secret generic redis-secrets \
        --from-literal=password="$REDIS_PASSWORD" \
        -n analytics --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Redis secrets created"
}

# Function to create Grafana secrets
create_grafana_secrets() {
    print_status "Creating Grafana secrets..."
    
    kubectl create secret generic grafana-secrets \
        --from-literal=admin-password="$GRAFANA_ADMIN_PASSWORD" \
        -n analytics --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Grafana secrets created"
}

# Function to create analytics secrets
create_analytics_secrets() {
    print_status "Creating analytics service secrets..."
    
    kubectl create secret generic analytics-secrets \
        --from-literal=JWT_SECRET_KEY="$JWT_SECRET_KEY" \
        -n analytics --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Analytics secrets created"
}

# Function to create config maps
create_config_maps() {
    print_status "Creating config maps..."
    
    # Analytics API config
    kubectl create configmap analytics-config \
        --from-literal=DATABASE_URL="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@postgresql-service:5432/$POSTGRES_DB" \
        --from-literal=CLICKHOUSE_URL="http://$CLICKHOUSE_USER:$CLICKHOUSE_PASSWORD@clickhouse-service:8123" \
        --from-literal=REDIS_URL="redis://:$REDIS_PASSWORD@redis-service:6379" \
        -n analytics --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Config maps created"
}

# Function to verify secrets
verify_secrets() {
    print_status "Verifying created secrets..."
    
    echo -e "\n${BLUE}Created secrets:${NC}"
    kubectl get secrets -n analytics
    
    echo -e "\n${BLUE}Created config maps:${NC}"
    kubectl get configmaps -n analytics
    
    print_success "Secrets verification completed"
}

# Function to display next steps
display_next_steps() {
    print_success "All secrets and config maps created successfully!"
    echo -e "\n${BLUE}Next steps:${NC}"
    echo "1. Deploy the analytics services:"
    echo "   kubectl apply -f ../kubernetes/"
    echo ""
    echo "2. Check the deployment status:"
    echo "   kubectl get pods -n analytics"
    echo ""
    echo "3. Access your services:"
    echo "   - Analytics API: http://analytics.highfunk.uk:8002/docs"
    echo "   - Grafana: http://analytics.highfunk.uk:3001 (admin/$GRAFANA_ADMIN_PASSWORD)"
    echo "   - Prometheus: http://analytics.highfunk.uk:9090"
    echo ""
    echo "4. Monitor the deployment:"
    echo "   kubectl logs -f deployment/defimon-analytics-api -n analytics"
}

# Main execution
main() {
    print_status "Starting DEFIMON Analytics Pool secrets creation..."
    
    check_prerequisites
    create_namespace
    create_postgresql_secrets
    create_clickhouse_secrets
    create_redis_secrets
    create_grafana_secrets
    create_analytics_secrets
    create_config_maps
    verify_secrets
    display_next_steps
    
    print_success "Secrets creation completed!"
}

# Run main function
main "$@"
