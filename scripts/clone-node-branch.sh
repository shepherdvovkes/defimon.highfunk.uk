#!/bin/bash

set -euo pipefail

echo "🚀 DEFIMON Ethereum Node - Quick Clone Script"
echo "=============================================="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}[HEADER]${NC} $1"
}

# Проверка аргументов
if [ $# -eq 0 ]; then
    print_error "Usage: $0 <repository-url> [target-directory]"
    echo ""
    echo "Examples:"
    echo "  $0 https://github.com/your-username/defimon.git"
    echo "  $0 https://github.com/your-username/defimon.git my-node"
    exit 1
fi

REPO_URL="$1"
TARGET_DIR="${2:-defimon-node}"

print_header "Cloning DEFIMON Ethereum Node branch..."

# Проверка наличия git
if ! command -v git >/dev/null 2>&1; then
    print_error "Git is not installed. Please install git first:"
    echo "  sudo apt install git"
    exit 1
fi

# Проверка доступности репозитория
print_status "Checking repository availability..."
if ! git ls-remote "$REPO_URL" >/dev/null 2>&1; then
    print_error "Repository is not accessible. Please check the URL: $REPO_URL"
    exit 1
fi

# Проверка существования директории
if [ -d "$TARGET_DIR" ]; then
    print_warning "Directory '$TARGET_DIR' already exists."
    read -p "Do you want to remove it and clone fresh? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Removing existing directory..."
        rm -rf "$TARGET_DIR"
    else
        print_error "Aborted. Please choose a different directory name or remove the existing one."
        exit 1
    fi
fi

# Клонирование только нужной ветки
print_status "Cloning eth_full_node_lenovo branch..."
git clone --branch eth_full_node_lenovo --single-branch "$REPO_URL" "$TARGET_DIR"

if [ $? -eq 0 ]; then
    print_status "Repository cloned successfully!"
else
    print_error "Failed to clone repository. Please check the URL and try again."
    exit 1
fi

# Переход в директорию
cd "$TARGET_DIR"

print_status "Repository cloned to: $(pwd)"
print_status "Branch: eth_full_node_lenovo"

# Проверка содержимого
print_header "Checking repository contents..."
if [ -f "README_ETH_NODE_LENOVO.md" ]; then
    print_status "✓ README_ETH_NODE_LENOVO.md found"
else
    print_warning "README_ETH_NODE_LENOVO.md not found"
fi

if [ -f "scripts/deploy-linux-mint-node.sh" ]; then
    print_status "✓ deploy-linux-mint-node.sh found"
else
    print_warning "deploy-linux-mint-node.sh not found"
fi

if [ -f "docs/ETH_NODE_SETUP.md" ]; then
    print_status "✓ ETH_NODE_SETUP.md found"
else
    print_warning "ETH_NODE_SETUP.md not found"
fi

if [ -f ".env.infura" ]; then
    print_status "✓ .env.infura found (with real Infura keys)"
else
    print_warning ".env.infura not found - you'll need to add your Infura keys manually"
fi

if [ -f "env.infura.example" ]; then
    print_status "✓ env.infura.example found (template available)"
else
    print_warning "env.infura.example not found"
fi

# Показ следующих шагов
print_header "Next Steps:"
echo ""
echo "1. Navigate to the cloned directory:"
echo "   cd $TARGET_DIR"
echo ""
echo "2. Read the documentation:"
echo "   cat README_ETH_NODE_LENOVO.md"
echo ""
echo "3. Check Infura configuration:"
echo "   ./scripts/check-infura-config.sh"
echo ""
echo "4. Check system requirements:"
echo "   ./scripts/deploy-linux-mint-node.sh --check-only"
echo ""
echo "5. Deploy the node (requires sudo):"
echo "   sudo ./scripts/deploy-linux-mint-node.sh"
echo ""
echo "5. Monitor the deployment:"
echo "   sudo /opt/defimon/monitor-node.sh"
echo ""

print_status "Clone completed successfully!"
print_status "Repository URL: $REPO_URL"
print_status "Target directory: $TARGET_DIR"
print_status "Branch: eth_full_node_lenovo"

echo ""
echo "🎉 Ready to deploy your Ethereum full node!"
echo "📚 Read README_ETH_NODE_LENOVO.md for detailed instructions"
