#!/bin/bash

set -e

echo "🔧 System Setup for DeFi Analytics Platform"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка прав root
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

print_status "Configuring system parameters for ClickHouse/Elasticsearch..."

# Настройка параметров ядра
print_status "Setting kernel parameters..."

# Увеличиваем vm.max_map_count для ClickHouse
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

# Увеличиваем лимит файлов
sysctl -w fs.file-max=65536
echo "fs.file-max=65536" >> /etc/sysctl.conf

# Оптимизируем swappiness
sysctl -w vm.swappiness=1
echo "vm.swappiness=1" >> /etc/sysctl.conf

# Дополнительные оптимизации для производительности
sysctl -w vm.dirty_ratio=15
echo "vm.dirty_ratio=15" >> /etc/sysctl.conf

sysctl -w vm.dirty_background_ratio=5
echo "vm.dirty_background_ratio=5" >> /etc/sysctl.conf

print_status "Kernel parameters configured successfully"

# Настройка лимитов для пользователя
print_status "Configuring user limits..."

# Создаем конфигурацию для лимитов
cat > /etc/security/limits.d/defimon.conf << EOF
# DeFi Analytics Platform limits
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
EOF

print_status "User limits configured"

# Проверка Docker
print_status "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_status "Docker and Docker Compose are available"

# Настройка Docker daemon
print_status "Configuring Docker daemon..."

# Создаем конфигурацию Docker daemon
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65536,
      "Soft": 65536
    }
  }
}
EOF

print_status "Docker daemon configured"

# Перезапуск Docker
print_status "Restarting Docker service..."
systemctl restart docker

print_status "✅ System setup completed successfully!"
echo ""
echo "📋 Summary of changes:"
echo "   - vm.max_map_count: 262144"
echo "   - fs.file-max: 65536"
echo "   - vm.swappiness: 1"
echo "   - User limits: 65536 files, 32768 processes"
echo "   - Docker daemon optimized"
echo ""
echo "🚀 You can now run the deployment script:"
echo "   ./scripts/deploy.sh"
echo ""
echo "📝 To make kernel changes permanent after reboot:"
echo "   sudo sysctl -p"
