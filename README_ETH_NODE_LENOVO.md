# 🚀 DEFIMON Ethereum Full Node - Linux Mint Setup

## 📋 Описание

Эта ветка содержит все необходимое для развертывания полной Ethereum ноды на Linux Mint. 
Оптимизирована для работы на Lenovo ThinkPad и подобных системах.

## 🎯 Что включено

- ✅ Полная Ethereum нода (Geth)
- ✅ Rust приложение для обработки блоков
- ✅ PostgreSQL база данных
- ✅ Redis кэширование
- ✅ Kafka для потоковой обработки
- ✅ Prometheus + Grafana мониторинг
- ✅ Автоматическое резервное копирование
- ✅ Systemd сервисы
- ✅ Скрипты управления

## 🖥️ Системные требования

- **ОС**: Linux Mint 20+ или Ubuntu 20.04+
- **RAM**: 16GB+ (рекомендуется)
- **CPU**: 8+ ядер (рекомендуется)
- **Диск**: 1TB+ свободного места
- **Сеть**: Стабильное интернет-соединение

## 🚀 Быстрый старт

### 1. Клонирование только этой ветки

```bash
# Клонируем только нужную ветку
git clone --branch eth_full_node_lenovo --single-branch <repository-url> defimon-node
cd defimon-node
```

### 2. Настройка Infura (обязательно)

Для синхронизации ноды через Infura необходимо создать файл `.env.infura` с вашими ключами:

```bash
# Скопируйте шаблон
cp env.infura.example .env.infura

# Отредактируйте файл и добавьте ваш Infura Project ID
nano .env.infura
```

**Важно**: Замените `your-infura-project-id` на ваш реальный Project ID от Infura.

### 3. Проверка конфигурации

```bash
# Проверка Infura конфигурации
./scripts/check-infura-config.sh

# Проверка системных требований
./scripts/deploy-linux-mint-node.sh --check-only
```

### 4. Автоматическое развертывание

```bash
# Запуск автоматического развертывания
sudo ./scripts/deploy-linux-mint-node.sh
```

### 3. Проверка статуса

```bash
# Проверка статуса ноды
sudo /opt/defimon/manage-node.sh status

# Просмотр логов
sudo /opt/defimon/manage-node.sh logs
```

## 🌐 Доступные интерфейсы

После развертывания:

- **Ethereum RPC**: http://localhost:8545
- **Ethereum WebSocket**: ws://localhost:8546
- **Grafana мониторинг**: http://localhost:3001 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Админ дашборд**: http://localhost:8080

## 📊 Мониторинг

```bash
# Проверка статуса системы
sudo /opt/defimon/monitor-node.sh

# Непрерывный мониторинг
watch -n 30 'sudo /opt/defimon/monitor-node.sh'
```

## 🔧 Управление нодой

```bash
# Запуск ноды
sudo /opt/defimon/manage-node.sh start

# Остановка ноды
sudo /opt/defimon/manage-node.sh stop

# Перезапуск ноды
sudo /opt/defimon/manage-node.sh restart

# Обновление ноды
sudo /opt/defimon/manage-node.sh update

# Создание резервной копии
sudo /opt/defimon/manage-node.sh backup
```

## 💾 Резервное копирование

```bash
# Ручное создание резервной копии
sudo /opt/defimon/manage-node.sh backup

# Автоматическое резервное копирование (ежедневно в 2:00)
sudo crontab -e
# Добавьте: 0 2 * * * /opt/defimon/manage-node.sh backup
```

## 🔍 Диагностика

### Проверка синхронизации

```bash
# Проверка статуса синхронизации
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545
```

### Проверка ресурсов

```bash
# Использование диска
df -h /opt/defimon

# Использование памяти
free -h

# Использование CPU
top -p $(pgrep -f "blockchain-service")
```

## 🆘 Устранение неполадок

### Проблемы с Docker
```bash
sudo systemctl status docker
sudo systemctl restart docker
```

### Проблемы с дисковым пространством
```bash
df -h
sudo docker system prune -f
```

### Просмотр логов
```bash
sudo /opt/defimon/manage-node.sh logs
```

### Сброс ноды (если нужно)
```bash
sudo /opt/defimon/manage-node.sh stop
sudo rm -rf /opt/defimon/data/ethereum/*
sudo /opt/defimon/manage-node.sh start
```

## 📈 Оптимизация производительности

### Настройка для Lenovo ThinkPad

```bash
# Отключение энергосбережения
sudo cpupower frequency-set -g performance

# Настройка swappiness
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Мониторинг производительности

```bash
# Мониторинг в реальном времени
htop

# Мониторинг диска
iotop

# Мониторинг сети
iftop
```

## 🔒 Безопасность

### Настройка файрвола

```bash
# Разрешение только локальных подключений
sudo ufw allow from 127.0.0.1 to any port 8545
sudo ufw allow from 127.0.0.1 to any port 8546
sudo ufw enable
```

### Обновление системы

```bash
# Регулярные обновления
sudo apt update && sudo apt upgrade -y
```

## 🌐 Infura Integration

### Что такое Infura?

Infura - это инфраструктурная платформа, которая предоставляет доступ к Ethereum и другим блокчейнам через API. Использование Infura позволяет:

- ✅ Быстрая синхронизация ноды
- ✅ Надежное подключение к сети
- ✅ Поддержка множественных сетей
- ✅ Высокая доступность

### Настройка Infura

1. **Получите Project ID**:
   - Зарегистрируйтесь на [https://infura.io/](https://infura.io/)
   - Создайте новый проект
   - Скопируйте Project ID

2. **Настройте .env.infura**:
   ```bash
   # Скопируйте шаблон
   cp env.infura.example .env.infura
   
   # Отредактируйте файл
   nano .env.infura
   
   # Замените your-infura-project-id на ваш реальный ID
   INFURA_PROJECT_ID=your-real-project-id
   ```

3. **Проверьте конфигурацию**:
   ```bash
   # Проверка подключения к Infura
   curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
     https://mainnet.infura.io/v3/YOUR_PROJECT_ID
   ```

### Поддерживаемые сети через Infura

- ✅ Ethereum Mainnet
- ✅ Arbitrum One
- ✅ Optimism
- ✅ Polygon
- ✅ Avalanche C-Chain
- ✅ Linea
- ✅ И многие другие

## 📚 Дополнительная документация

- **Полное руководство**: [docs/ETH_NODE_SETUP.md](docs/ETH_NODE_SETUP.md)
- **Infura настройка**: [docs/INFURA_SETUP.md](docs/INFURA_SETUP.md)
- **Мониторинг**: [docs/MONITORING.md](docs/MONITORING.md)
- **L2 настройка**: [L2_SETUP.md](L2_SETUP.md)

## 🎉 Готово!

После успешного развертывания у вас будет:

- ✅ Полная Ethereum нода
- ✅ Автоматический запуск при загрузке системы
- ✅ Мониторинг и алерты
- ✅ Резервное копирование
- ✅ Оптимизация для Linux Mint
- ✅ Готовность к работе с L2 сетями

Система готова к использованию!

---

**Примечание**: Эта ветка оптимизирована для автономной работы. Все необходимые файлы и конфигурации включены в репозиторий.
