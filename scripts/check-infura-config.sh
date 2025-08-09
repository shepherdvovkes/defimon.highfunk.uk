#!/bin/bash

set -euo pipefail

echo "🔍 Checking Infura Configuration..."
echo "=================================="

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

# Определяем корень репозитория
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)

print_header "Checking Infura configuration files..."

# Проверка наличия .env.infura
if [ -f "$REPO_ROOT/.env.infura" ]; then
    print_status "✓ .env.infura found"
    
    # Проверка Project ID
    INFURA_PROJECT_ID=$(grep "^INFURA_PROJECT_ID=" "$REPO_ROOT/.env.infura" | cut -d'=' -f2)
    if [ -n "$INFURA_PROJECT_ID" ] && [ "$INFURA_PROJECT_ID" != "your-infura-project-id" ]; then
        print_status "✓ INFURA_PROJECT_ID configured: $INFURA_PROJECT_ID"
        
        # Проверка подключения к Infura
        print_header "Testing Infura connection..."
        
        # Тест подключения к Ethereum Mainnet
        RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            "https://mainnet.infura.io/v3/$INFURA_PROJECT_ID" 2>/dev/null || echo "ERROR")
        
        if echo "$RESPONSE" | grep -q '"result"' && ! echo "$RESPONSE" | grep -q "ERROR"; then
            BLOCK_NUMBER=$(echo "$RESPONSE" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)
            print_status "✓ Infura connection successful"
            print_status "✓ Current block number: $BLOCK_NUMBER"
        else
            print_error "✗ Failed to connect to Infura"
            print_error "Response: $RESPONSE"
        fi
        
        # Проверка других сетей
        print_header "Testing other networks..."
        
        # Arbitrum One
        ARB_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            "https://arbitrum-mainnet.infura.io/v3/$INFURA_PROJECT_ID" 2>/dev/null || echo "ERROR")
        
        if echo "$ARB_RESPONSE" | grep -q '"result"' && ! echo "$ARB_RESPONSE" | grep -q "ERROR"; then
            print_status "✓ Arbitrum One connection successful"
        else
            print_warning "⚠ Arbitrum One connection failed"
        fi
        
        # Polygon
        POLY_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            "https://polygon-mainnet.infura.io/v3/$INFURA_PROJECT_ID" 2>/dev/null || echo "ERROR")
        
        if echo "$POLY_RESPONSE" | grep -q '"result"' && ! echo "$POLY_RESPONSE" | grep -q "ERROR"; then
            print_status "✓ Polygon connection successful"
        else
            print_warning "⚠ Polygon connection failed"
        fi
        
    else
        print_error "✗ INFURA_PROJECT_ID not properly configured"
        print_error "Please update .env.infura with your real Project ID"
    fi
else
    print_warning "⚠ .env.infura not found"
    
    # Проверка наличия шаблона
    if [ -f "$REPO_ROOT/env.infura.example" ]; then
        print_status "✓ env.infura.example found"
        echo ""
        echo "To configure Infura:"
        echo "1. Copy the template: cp env.infura.example .env.infura"
        echo "2. Edit the file: nano .env.infura"
        echo "3. Replace 'your-infura-project-id' with your real Project ID"
        echo "4. Run this script again: ./scripts/check-infura-config.sh"
    else
        print_error "✗ Neither .env.infura nor env.infura.example found"
    fi
fi

echo ""
print_header "Configuration Summary:"

# Проверка переменных окружения
if [ -f "$REPO_ROOT/.env.infura" ]; then
    echo "Environment variables in .env.infura:"
    grep -E "^(INFURA_|ETHEREUM_|RPC_URL_)" "$REPO_ROOT/.env.infura" | while read -r line; do
        if [[ "$line" == *"INFURA_PROJECT_ID"* ]]; then
            # Скрываем Project ID для безопасности
            echo "  INFURA_PROJECT_ID=***"
        else
            echo "  $line"
        fi
    done
fi

echo ""
print_status "Infura configuration check completed!"
