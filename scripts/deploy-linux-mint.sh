#!/bin/bash

# DEFIMON Full Node Deployment Script for Linux Mint
# Автоматическое развертывание полной ноды с мониторингом L2 сетей

set -e

echo "🚀 DEFIMON Full Node Deployment for Linux Mint"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_header() {
    echo -e "${PURPLE}[HEADER]${NC} $1"
}

print_system() {
    echo -e "${CYAN}[SYSTEM]${NC} $1"
}

# Function to find disk with most free space
find_best_disk() {
    print_system "Analyzing available disks..."
    
    # Get disk usage information
    local best_disk=""
    local max_space=0
    
    # Parse df output to find disk with most free space
    while IFS= read -r line; do
        # Skip header and non-local filesystems
        if [[ $line =~ ^/dev/ ]] && ! [[ $line =~ tmpfs|devtmpfs|proc ]]; then
            local filesystem=$(echo "$line" | awk '{print $1}')
            local available=$(echo "$line" | awk '{print $4}')
            local mountpoint=$(echo "$line" | awk '{print $6}')
            
            # Convert to GB for comparison
            local available_gb=$(echo "scale=2; $available / 1024 / 1024" | bc -l 2>/dev/null || echo "0")
            
            print_system "Disk: $filesystem, Available: ${available_gb}GB, Mount: $mountpoint"
            
            if (( $(echo "$available_gb > $max_space" | bc -l) )); then
                max_space=$available_gb
                best_disk=$mountpoint
            fi
        fi
    done < <(df -h)
    
    if [ -z "$best_disk" ]; then
        print_warning "Could not determine best disk, using current directory"
        best_disk="."
    fi
    
    print_success "Selected disk: $best_disk (${max_space}GB available)"
    echo "$best_disk"
}

# Function to check system requirements
check_system_requirements() {
    print_header "Checking system requirements..."
    
    # Check OS
    if ! grep -q "Linux Mint" /etc/os-release 2>/dev/null; then
        print_warning "This script is optimized for Linux Mint, but will continue..."
    fi
    
    # Check available memory
    local total_mem=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$total_mem" -lt 8 ]; then
        print_error "Insufficient RAM: ${total_mem}GB. Minimum required: 8GB"
        exit 1
    fi
    print_success "RAM: ${total_mem}GB"
    
    # Check available disk space
    local free_space=$(df -BG . | awk 'NR==2{print $4}' | sed 's/G//')
    if [ "$free_space" -lt 100 ]; then
        print_error "Insufficient disk space: ${free_space}GB. Minimum required: 100GB"
        exit 1
    fi
    print_success "Disk space: ${free_space}GB"
    
    # Check CPU cores
    local cpu_cores=$(nproc)
    if [ "$cpu_cores" -lt 4 ]; then
        print_warning "Low CPU cores: ${cpu_cores}. Recommended: 4+ cores"
    else
        print_success "CPU cores: ${cpu_cores}"
    fi
}

# Function to install dependencies
install_dependencies() {
    print_header "Installing system dependencies..."
    
    # Update package list
    print_status "Updating package list..."
    sudo apt update
    
    # Install required packages
    local packages=(
        "docker.io"
        "docker-compose"
        "curl"
        "wget"
        "git"
        "build-essential"
        "bc"
        "htop"
        "iotop"
        "nethogs"
        "tree"
        "unzip"
        "zip"
        "jq"
        "postgresql-client"
        "redis-tools"
    )
    
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            print_status "Installing $package..."
            sudo apt install -y "$package"
        else
            print_success "$package already installed"
        fi
    done
    
    # Start and enable Docker
    print_status "Starting Docker service..."
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add user to docker group
    if ! groups $USER | grep -q docker; then
        print_status "Adding user to docker group..."
        sudo usermod -aG docker $USER
        print_warning "Please log out and log back in for docker group changes to take effect"
    fi
}

# Function to setup data directory on best disk
setup_data_directory() {
    local data_disk=$1
    print_header "Setting up data directory on $data_disk..."
    
    # Create DEFIMON data directory
    local defimon_dir="$data_disk/defimon"
    print_status "Creating DEFIMON data directory: $defimon_dir"
    
    sudo mkdir -p "$defimon_dir"
    sudo chown $USER:$USER "$defimon_dir"
    
    # Create subdirectories
    local subdirs=(
        "data/postgres"
        "data/clickhouse" 
        "data/redis"
        "data/ethereum"
        "data/grafana"
        "data/prometheus"
        "logs"
        "backups"
        "configs"
    )
    
    for dir in "${subdirs[@]}"; do
        mkdir -p "$defimon_dir/$dir"
        print_success "Created: $defimon_dir/$dir"
    done
    
    # Create symlink to current directory
    if [ ! -L "data" ]; then
        ln -sf "$defimon_dir/data" data
        print_success "Created symlink: data -> $defimon_dir/data"
    fi
    
    echo "$defimon_dir"
}

# Function to setup environment
setup_environment() {
    print_header "Setting up environment..."
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        print_status "Creating .env file from template..."
        cp env.example .env
        
        # Generate random passwords
        local postgres_password=$(openssl rand -base64 32)
        local redis_password=$(openssl rand -base64 32)
        
        # Update .env file with generated passwords
        sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$postgres_password/" .env
        sed -i "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=$redis_password/" .env
        
        print_success "Created .env file with secure passwords"
    else
        print_warning ".env file already exists"
    fi
    
    # Set environment variables
    export COMPOSE_PROJECT_NAME=defimon
    export DOCKER_BUILDKIT=1
}

# Function to build and start services
deploy_services() {
    print_header "Deploying services..."
    
    # Build images
    print_status "Building Docker images..."
    docker-compose -f infrastructure/docker-compose.yml build --parallel
    
    # Start databases first
    print_status "Starting databases..."
    docker-compose -f infrastructure/docker-compose.yml up -d postgres clickhouse redis kafka zookeeper
    
    # Wait for databases
    print_status "Waiting for databases to be ready..."
    sleep 30
    
    # Check database health
    print_status "Checking database health..."
    
    # PostgreSQL
    if docker-compose -f infrastructure/docker-compose.yml exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
        print_success "PostgreSQL is healthy"
    else
        print_error "PostgreSQL health check failed"
        return 1
    fi
    
    # ClickHouse
    if curl -f http://localhost:8123/ping > /dev/null 2>&1; then
        print_success "ClickHouse is healthy"
    else
        print_error "ClickHouse health check failed"
        return 1
    fi
    
    # Redis
    if docker-compose -f infrastructure/docker-compose.yml exec -T redis redis-cli ping > /dev/null 2>&1; then
        print_success "Redis is healthy"
    else
        print_error "Redis health check failed"
        return 1
    fi
    
    # Start application services
    print_status "Starting application services..."
    docker-compose -f infrastructure/docker-compose.yml up -d data-ingestion stream-processor ai-ml-service analytics-api blockchain-node
    
    # Start monitoring and admin dashboard
    print_status "Starting monitoring and admin dashboard..."
    docker-compose -f infrastructure/docker-compose.yml up -d frontend api-gateway prometheus grafana admin-dashboard
    
    # Wait for services
    print_status "Waiting for services to be ready..."
    sleep 30
}

# Function to run health checks
run_health_checks() {
    print_header "Running health checks..."
    
    local services=(
        "http://localhost:8000/health:API Gateway"
        "http://localhost:8002/health:Analytics API"
        "http://localhost:8001/health:AI/ML Service"
        "http://localhost:3000:Frontend"
        "http://localhost:8080:Admin Dashboard"
        "http://localhost:9090/-/healthy:Prometheus"
        "http://localhost:3001/api/health:Grafana"
    )
    
    for service in "${services[@]}"; do
        local url=$(echo "$service" | cut -d: -f1)
        local name=$(echo "$service" | cut -d: -f2)
        
        if curl -f "$url" > /dev/null 2>&1; then
            print_success "✅ $name is healthy"
        else
            print_warning "⚠️ $name health check failed (may need more time)"
        fi
    done
}

# Function to show system information
show_system_info() {
    print_header "System Information"
    
    echo "OS: $(lsb_release -d | cut -f2)"
    echo "Kernel: $(uname -r)"
    echo "CPU: $(nproc) cores"
    echo "RAM: $(free -h | awk '/^Mem:/{print $2}')"
    echo "Disk Usage:"
    df -h | grep -E "^/dev/"
    echo ""
}

# Function to show service URLs
show_service_urls() {
    print_header "Service URLs"
    
    echo "🌐 Web Interfaces:"
    echo "   Frontend: http://localhost:3000"
    echo "   Admin Dashboard: http://localhost:8080"
    echo "   API Gateway: http://localhost:8000"
    echo ""
    
    echo "📊 Monitoring:"
    echo "   Grafana: http://localhost:3001 (admin/Cal1f0rn1a@2025)"
    echo "   Prometheus: http://localhost:9090"
    echo "   Kong Admin: http://localhost:8001"
    echo ""
    
    echo "🔧 APIs:"
    echo "   Analytics API: http://localhost:8002"
    echo "   AI/ML Service: http://localhost:8001"
    echo ""
    
    echo "🗄️ Databases:"
    echo "   PostgreSQL: localhost:5432"
    echo "   ClickHouse: http://localhost:8123"
    echo "   Redis: localhost:6379"
    echo "   Kafka: localhost:9092"
    echo ""
}

# Function to create monitoring script
create_monitoring_script() {
    local data_dir=$1
    print_header "Creating monitoring script..."
    
    cat > "$data_dir/monitor.sh" << 'EOF'
#!/bin/bash

# DEFIMON Monitoring Script

echo "🔍 DEFIMON System Monitor"
echo "=========================="

# System resources
echo "📊 System Resources:"
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "Memory Usage: $(free | awk '/Mem:/ {printf("%.1f%%", $3/$2 * 100.0)}')"
echo "Disk Usage: $(df -h / | awk 'NR==2{print $5}')"

echo ""
echo "🐳 Docker Services:"
docker-compose -f infrastructure/docker-compose.yml ps

echo ""
echo "📈 Service Health:"
curl -s http://localhost:8080/api/health | jq '.services[] | "\(.name): \(.status)"' 2>/dev/null || echo "Admin dashboard not available"

echo ""
echo "💾 Database Status:"
docker-compose -f infrastructure/docker-compose.yml exec -T postgres pg_isready -U postgres && echo "PostgreSQL: ✅" || echo "PostgreSQL: ❌"
docker-compose -f infrastructure/docker-compose.yml exec -T redis redis-cli ping > /dev/null && echo "Redis: ✅" || echo "Redis: ❌"
curl -f http://localhost:8123/ping > /dev/null && echo "ClickHouse: ✅" || echo "ClickHouse: ❌"
EOF
    
    chmod +x "$data_dir/monitor.sh"
    print_success "Created monitoring script: $data_dir/monitor.sh"
}

# Function to create backup script
create_backup_script() {
    local data_dir=$1
    print_header "Creating backup script..."
    
    cat > "$data_dir/backup.sh" << EOF
#!/bin/bash

# DEFIMON Backup Script

BACKUP_DIR="$data_dir/backups"
DATE=\$(date +%Y%m%d_%H%M%S)

echo "💾 Creating backup: \$DATE"

# Create backup directory
mkdir -p "\$BACKUP_DIR"

# Backup PostgreSQL
echo "📦 Backing up PostgreSQL..."
docker-compose -f infrastructure/docker-compose.yml exec -T postgres pg_dumpall -U postgres > "\$BACKUP_DIR/postgres_\$DATE.sql"

# Backup ClickHouse
echo "📦 Backing up ClickHouse..."
docker-compose -f infrastructure/docker-compose.yml exec -T clickhouse clickhouse-client --query "BACKUP TABLE defi_analytics.* TO '\$BACKUP_DIR/clickhouse_\$DATE'"

# Backup configuration
echo "📦 Backing up configuration..."
tar -czf "\$BACKUP_DIR/config_\$DATE.tar.gz" .env infrastructure/

# Create archive
echo "📦 Creating backup archive..."
tar -czf "\$BACKUP_DIR/defimon_backup_\$DATE.tar.gz" -C "\$BACKUP_DIR" .

echo "✅ Backup completed: \$BACKUP_DIR/defimon_backup_\$DATE.tar.gz"
EOF
    
    chmod +x "$data_dir/backup.sh"
    print_success "Created backup script: $data_dir/backup.sh"
}

# Main deployment function
main() {
    echo "🚀 Starting DEFIMON Full Node Deployment..."
    echo ""
    
    # Check system requirements
    check_system_requirements
    
    # Install dependencies
    install_dependencies
    
    # Find best disk for data
    local best_disk=$(find_best_disk)
    
    # Setup data directory
    local data_dir=$(setup_data_directory "$best_disk")
    
    # Setup environment
    setup_environment
    
    # Deploy services
    deploy_services
    
    # Run health checks
    run_health_checks
    
    # Create utility scripts
    create_monitoring_script "$data_dir"
    create_backup_script "$data_dir"
    
    # Show information
    show_system_info
    show_service_urls
    
    echo "=========================================="
    print_success "🎉 DEFIMON Full Node Deployment Completed!"
    echo ""
    print_status "Next steps:"
    echo "  1. Open Admin Dashboard: http://localhost:8080"
    echo "  2. Check Grafana: http://localhost:3001 (admin/Cal1f0rn1a@2025)"
    echo "  3. Monitor logs: docker-compose -f infrastructure/docker-compose.yml logs -f"
    echo "  4. Run monitoring: $data_dir/monitor.sh"
    echo "  5. Create backup: $data_dir/backup.sh"
    echo ""
    print_status "Useful commands:"
    echo "  Stop services: docker-compose -f infrastructure/docker-compose.yml down"
    echo "  Restart services: docker-compose -f infrastructure/docker-compose.yml restart"
    echo "  View logs: docker-compose -f infrastructure/docker-compose.yml logs -f"
    echo "  System monitor: $data_dir/monitor.sh"
    echo "=========================================="
}

# Handle command line arguments
case "${1:-}" in
    "stop")
        print_status "Stopping all services..."
        docker-compose -f infrastructure/docker-compose.yml down
        print_success "Services stopped"
        ;;
    "restart")
        print_status "Restarting services..."
        docker-compose -f infrastructure/docker-compose.yml restart
        print_success "Services restarted"
        ;;
    "logs")
        print_status "Showing logs..."
        docker-compose -f infrastructure/docker-compose.yml logs -f
        ;;
    "status")
        print_status "Service status:"
        docker-compose -f infrastructure/docker-compose.yml ps
        ;;
    "clean")
        print_status "Cleaning up..."
        docker-compose -f infrastructure/docker-compose.yml down -v
        docker system prune -f
        print_success "Cleanup completed"
        ;;
    "backup")
        print_status "Creating backup..."
        if [ -f "data/backup.sh" ]; then
            ./data/backup.sh
        else
            print_error "Backup script not found"
        fi
        ;;
    "monitor")
        print_status "Running system monitor..."
        if [ -f "data/monitor.sh" ]; then
            ./data/monitor.sh
        else
            print_error "Monitor script not found"
        fi
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no args)  - Deploy full node with monitoring"
        echo "  stop       - Stop all services"
        echo "  restart    - Restart all services"
        echo "  logs       - Show logs"
        echo "  status     - Show service status"
        echo "  clean      - Clean up all containers and volumes"
        echo "  backup     - Create backup"
        echo "  monitor    - Run system monitor"
        echo "  help       - Show this help"
        ;;
    *)
        main
        ;;
esac
