#!/bin/bash

# DEFIMON L2 Networks Setup Script
# Этот скрипт настраивает и запускает мониторинг L2 сетей

set -e

echo "🚀 Starting DEFIMON L2 Networks Setup..."

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

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Check if Docker Compose is available
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install it and try again."
        exit 1
    fi
    print_success "Docker Compose is available"
}

# Create .env file if it doesn't exist
setup_env() {
    if [ ! -f .env ]; then
        print_status "Creating .env file from template..."
        cp env.example .env
        print_success "Created .env file"
    else
        print_warning ".env file already exists"
    fi
}

# Apply database schema
setup_database() {
    print_status "Setting up database schema..."
    
    # Wait for PostgreSQL to be ready
    print_status "Waiting for PostgreSQL to be ready..."
    docker-compose up -d postgres
    
    # Wait for PostgreSQL
    for i in {1..30}; do
        if docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
            break
        fi
        sleep 2
    done
    
    # Apply schema
    print_status "Applying database schema..."
    docker-compose exec -T postgres psql -U postgres -d defi_analytics -f /docker-entrypoint-initdb.d/l2_schema.sql || {
        print_warning "Could not apply schema via Docker. Trying direct connection..."
        # Try direct connection
        PGPASSWORD=password psql -h localhost -U postgres -d defi_analytics -f infrastructure/l2_schema.sql || {
            print_error "Failed to apply database schema"
            exit 1
        }
    }
    
    print_success "Database schema applied"
}

# Start all services
start_services() {
    print_status "Starting all services..."
    docker-compose up -d
    
    print_status "Waiting for services to be ready..."
    sleep 30
    
    print_success "All services started"
}

# Check service health
check_health() {
    print_status "Checking service health..."
    
    # Check PostgreSQL
    if docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
        print_success "PostgreSQL is healthy"
    else
        print_error "PostgreSQL is not healthy"
    fi
    
    # Check Redis
    if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        print_success "Redis is healthy"
    else
        print_error "Redis is not healthy"
    fi
    
    # Check Kafka
    if docker-compose exec -T kafka kafka-topics --bootstrap-server localhost:9092 --list > /dev/null 2>&1; then
        print_success "Kafka is healthy"
    else
        print_error "Kafka is not healthy"
    fi
    
    # Check blockchain node
    if docker-compose ps blockchain-node | grep -q "Up"; then
        print_success "Blockchain node is running"
    else
        print_error "Blockchain node is not running"
    fi
}

# Show service URLs
show_urls() {
    echo ""
    print_status "Service URLs:"
    echo "  📊 Grafana Dashboard: http://localhost:3001 (admin/admin)"
    echo "  📈 Prometheus: http://localhost:9090"
    echo "  🔗 API Gateway: http://localhost:8000"
    echo "  🌐 Frontend: http://localhost:3000"
    echo "  🗄️  PostgreSQL: localhost:5432"
    echo "  📊 ClickHouse: http://localhost:8123"
    echo ""
}

# Show logs
show_logs() {
    print_status "Recent blockchain node logs:"
    docker-compose logs --tail=20 blockchain-node
    echo ""
}

# Main setup function
main() {
    echo "=========================================="
    echo "  DEFIMON L2 Networks Setup"
    echo "=========================================="
    echo ""
    
    # Check prerequisites
    check_docker
    check_docker_compose
    
    # Setup environment
    setup_env
    
    # Setup database
    setup_database
    
    # Start services
    start_services
    
    # Check health
    check_health
    
    # Show information
    show_urls
    show_logs
    
    echo "=========================================="
    print_success "Setup completed successfully!"
    echo ""
    print_status "Next steps:"
    echo "  1. Open Grafana dashboard to view metrics"
    echo "  2. Check logs for any errors: docker-compose logs -f"
    echo "  3. Monitor L2 sync progress in logs"
    echo "  4. Configure additional networks in .env file"
    echo ""
    print_status "To stop services: docker-compose down"
    print_status "To view logs: docker-compose logs -f"
    echo ""
    print_status "To add Cosmos support, run: ./scripts/setup_cosmos.sh"
    echo "=========================================="
}

# Handle command line arguments
case "${1:-}" in
    "stop")
        print_status "Stopping all services..."
        docker-compose down
        print_success "Services stopped"
        ;;
    "restart")
        print_status "Restarting services..."
        docker-compose restart
        print_success "Services restarted"
        ;;
    "logs")
        print_status "Showing logs..."
        docker-compose logs -f
        ;;
    "status")
        print_status "Service status:"
        docker-compose ps
        ;;
    "clean")
        print_status "Cleaning up..."
        docker-compose down -v
        docker system prune -f
        print_success "Cleanup completed"
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no args)  - Setup and start all services"
        echo "  stop       - Stop all services"
        echo "  restart    - Restart all services"
        echo "  logs       - Show logs"
        echo "  status     - Show service status"
        echo "  clean      - Clean up all containers and volumes"
        echo "  help       - Show this help"
        ;;
    *)
        main
        ;;
esac
