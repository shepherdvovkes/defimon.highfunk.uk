#!/bin/bash

# L2 Analytics Runner Script
# Запуск системы аналитики L2 протоколов

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода
print_info() {
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

# Проверка зависимостей
check_dependencies() {
    print_info "Проверка зависимостей..."
    
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 не установлен"
        exit 1
    fi
    
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 не установлен"
        exit 1
    fi
    
    print_success "Зависимости проверены"
}

# Создание виртуального окружения
setup_venv() {
    print_info "Настройка виртуального окружения..."
    
    if [ ! -d "venv" ]; then
        print_info "Создание виртуального окружения..."
        python3 -m venv venv
    fi
    
    print_info "Активация виртуального окружения..."
    source venv/bin/activate
    
    print_info "Установка зависимостей..."
    pip install -r requirements.txt
    
    print_success "Виртуальное окружение настроено"
}

# Проверка конфигурации
check_config() {
    print_info "Проверка конфигурации..."
    
    if [ ! -f ".env" ]; then
        print_warning "Файл .env не найден. Создание примера..."
        cat > .env << EOF
# Etherscan API Keys
ETHERSCAN_API_KEY=your_etherscan_api_key
ARBISCAN_API_KEY=your_arbiscan_api_key
OPTIMISTIC_ETHERSCAN_API_KEY=your_optimistic_etherscan_api_key
POLYGONSCAN_API_KEY=your_polygonscan_api_key
BASESCAN_API_KEY=your_basescan_api_key

# Alchemy API Key (для Ethereum L1)
ALCHEMY_API_KEY=your_alchemy_api_key

# Настройки безопасности
SECRET_KEY=your_secret_key_here
ALLOWED_HOSTS=localhost,127.0.0.1
CORS_ORIGINS=http://localhost:3000,https://yourdomain.com
EOF
        print_warning "Пожалуйста, отредактируйте файл .env и добавьте ваши API ключи"
    fi
    
    print_success "Конфигурация проверена"
}

# Запуск тестовых коллекторов
test_collectors() {
    print_info "Тестирование коллекторов данных..."
    
    # Тест TVL коллектора
    print_info "Тестирование TVL коллектора..."
    python data-collection/tvl-collector.py &
    TVL_PID=$!
    
    # Тест User Activity коллектора
    print_info "Тестирование User Activity коллектора..."
    python data-collection/user-activity-collector.py &
    USER_PID=$!
    
    # Тест Gas Savings коллектора
    print_info "Тестирование Gas Savings коллектора..."
    python data-collection/gas-savings-collector.py &
    GAS_PID=$!
    
    # Ждем завершения тестов
    wait $TVL_PID $USER_PID $GAS_PID
    
    print_success "Тестирование коллекторов завершено"
}

# Запуск API сервера
start_api_server() {
    print_info "Запуск API сервера..."
    
    cd api
    python l2-analytics-api.py &
    API_PID=$!
    cd ..
    
    # Ждем запуска сервера
    sleep 5
    
    # Проверяем доступность
    if curl -s http://localhost:8000/health > /dev/null; then
        print_success "API сервер запущен на http://localhost:8000"
        print_info "DEFIMON Dashboard: http://localhost:8000"
        print_info "API Documentation: http://localhost:8000/docs"
    else
        print_error "API сервер не запустился"
        exit 1
    fi
}

# Открытие дашборда
open_dashboard() {
    print_info "Открытие DEFIMON дашборда..."
    
    # Открываем дашборд в браузере
    if command -v xdg-open &> /dev/null; then
        xdg-open "http://localhost:8000"
    elif command -v open &> /dev/null; then
        open "http://localhost:8000"
    else
        print_info "DEFIMON Dashboard доступен по адресу: http://localhost:8000"
    fi
    
    print_success "DEFIMON дашборд открыт"
}

# Сбор данных
collect_data() {
    print_info "Запуск сбора данных..."
    
    curl -X POST http://localhost:8000/api/l2-analytics/collect
    
    print_success "Сбор данных запущен"
}

# Мониторинг системы
monitor_system() {
    print_info "Мониторинг системы..."
    
    while true; do
        echo "=== Статус системы DEFIMON ==="
        echo "Время: $(date)"
        
        # Проверка API сервера
        if curl -s http://localhost:8000/health > /dev/null; then
            echo "API сервер: ✅ Работает"
        else
            echo "API сервер: ❌ Не отвечает"
        fi
        
        # Проверка дашборда
        if curl -s http://localhost:8000/ > /dev/null; then
            echo "DEFIMON Dashboard: ✅ Доступен"
        else
            echo "DEFIMON Dashboard: ❌ Недоступен"
        fi
        
        # Проверка файлов данных
        if [ -f "tvl_data_*.json" ]; then
            echo "TVL данные: ✅ Доступны"
        else
            echo "TVL данные: ❌ Отсутствуют"
        fi
        
        if [ -f "user_activity_data_*.json" ]; then
            echo "User Activity данные: ✅ Доступны"
        else
            echo "User Activity данные: ❌ Отсутствуют"
        fi
        
        if [ -f "gas_savings_data_*.json" ]; then
            echo "Gas Savings данные: ✅ Доступны"
        else
            echo "Gas Savings данные: ❌ Отсутствуют"
        fi
        
        echo "==============================="
        echo ""
        
        sleep 60
    done
}

# Очистка при завершении
cleanup() {
    print_info "Очистка ресурсов..."
    
    if [ ! -z "$API_PID" ]; then
        kill $API_PID 2>/dev/null || true
    fi
    
    print_success "Очистка завершена"
}

# Обработка сигналов
trap cleanup EXIT INT TERM

# Главная функция
main() {
    print_info "Запуск DEFIMON L2 Analytics Framework..."
    
    # Проверяем, что мы в правильной директории
    if [ ! -f "requirements.txt" ]; then
        print_error "Запустите скрипт из директории docs/l2-analytics/"
        exit 1
    fi
    
    check_dependencies
    setup_venv
    check_config
    
    # Парсим аргументы командной строки
    case "${1:-start}" in
        "start")
            start_api_server
            open_dashboard
            collect_data
            print_success "DEFIMON L2 Analytics Framework запущен!"
            print_info "Нажмите Ctrl+C для остановки"
            monitor_system
            ;;
        "test")
            test_collectors
            ;;
        "collect")
            start_api_server
            collect_data
            ;;
        "dashboard")
            start_api_server
            open_dashboard
            ;;
        "help"|"-h"|"--help")
            echo "Использование: $0 [команда]"
            echo ""
            echo "Команды:"
            echo "  start     - Запуск всей системы (по умолчанию)"
            echo "  test      - Тестирование коллекторов"
            echo "  collect   - Только сбор данных"
            echo "  dashboard - Только дашборд"
            echo "  help      - Показать эту справку"
            echo ""
            echo "После запуска:"
            echo "  DEFIMON Dashboard: http://localhost:8000"
            echo "  API Documentation: http://localhost:8000/docs"
            ;;
        *)
            print_error "Неизвестная команда: $1"
            echo "Используйте '$0 help' для справки"
            exit 1
            ;;
    esac
}

# Запуск главной функции
main "$@"
