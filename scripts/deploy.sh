#!/bin/bash

set -e

echo "🚀 Deploying DeFi Analytics Platform..."

# Environment variables
export COMPOSE_PROJECT_NAME=defi-analytics
export DOCKER_BUILDKIT=1

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

# Check if .env file exists
if [ ! -f .env ]; then
    print_warning ".env file not found. Creating from template..."
    cp env.example .env
    print_status "Please edit .env file with your API keys and configuration"
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p data/postgres data/clickhouse data/redis data/grafana logs

# Build and start services
print_status "Building Docker images..."
docker-compose -f infrastructure/docker-compose.yml build

print_status "Starting databases..."
docker-compose -f infrastructure/docker-compose.yml up -d postgres clickhouse redis kafka zookeeper

# Wait for databases to be ready
print_status "Waiting for databases to be ready..."
sleep 30

# Check database health
print_status "Checking database health..."
if ! docker-compose -f infrastructure/docker-compose.yml exec -T postgres pg_isready -U postgres; then
    print_error "PostgreSQL is not ready"
    exit 1
fi

if ! curl -f http://localhost:8123/ping > /dev/null 2>&1; then
    print_error "ClickHouse is not ready"
    exit 1
fi

if ! docker-compose -f infrastructure/docker-compose.yml exec -T redis redis-cli ping > /dev/null 2>&1; then
    print_error "Redis is not ready"
    exit 1
fi

print_status "All databases are healthy"

# Run database migrations
print_status "Running database migrations..."
docker-compose -f infrastructure/docker-compose.yml exec -T postgres psql -U postgres -d defi_analytics -f /docker-entrypoint-initdb.d/init.sql

print_status "Setting up ClickHouse schema..."
docker-compose -f infrastructure/docker-compose.yml exec -T clickhouse clickhouse-client --multiquery < infrastructure/clickhouse_schema.sql

# Start application services
print_status "Starting application services..."
docker-compose -f infrastructure/docker-compose.yml up -d data-ingestion stream-processor ai-ml-service analytics-api

# Start frontend and monitoring
print_status "Starting frontend and monitoring..."
docker-compose -f infrastructure/docker-compose.yml up -d frontend api-gateway prometheus grafana

# Health checks
print_status "Running health checks..."
sleep 10

# Check API Gateway
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    print_status "✅ API Gateway is healthy"
else
    print_warning "⚠️ API Gateway health check failed (may need more time to start)"
fi

# Check Analytics API
if curl -f http://localhost:8002/health > /dev/null 2>&1; then
    print_status "✅ Analytics API is healthy"
else
    print_warning "⚠️ Analytics API health check failed (may need more time to start)"
fi

# Check ML Service
if curl -f http://localhost:8001/health > /dev/null 2>&1; then
    print_status "✅ ML Service is healthy"
else
    print_warning "⚠️ ML Service health check failed (may need more time to start)"
fi

# Check Frontend
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    print_status "✅ Frontend is healthy"
else
    print_warning "⚠️ Frontend health check failed (may need more time to start)"
fi

print_status "🎉 Deployment completed!"
echo ""
echo "📱 Services:"
echo "   Frontend: http://localhost:3000"
echo "   API Gateway: http://localhost:8000"
echo "   Analytics API: http://localhost:8002"
echo "   ML Service: http://localhost:8001"
echo ""
echo "📊 Monitoring:"
echo "   Grafana: http://localhost:3001 (admin/admin)"
echo "   Prometheus: http://localhost:9090"
echo "   Kong Admin: http://localhost:8001"
echo ""
echo "🗄️ Databases:"
echo "   PostgreSQL: localhost:5432"
echo "   ClickHouse: localhost:8123"
echo "   Redis: localhost:6379"
echo "   Kafka: localhost:9092"
echo ""

# Show logs
print_status "📝 Showing recent logs..."
docker-compose -f infrastructure/docker-compose.yml logs --tail=20 analytics-api ai-ml-service data-ingestion

echo ""
print_status "To view all logs: docker-compose -f infrastructure/docker-compose.yml logs -f"
print_status "To stop services: docker-compose -f infrastructure/docker-compose.yml down"
print_status "To restart services: docker-compose -f infrastructure/docker-compose.yml restart"
