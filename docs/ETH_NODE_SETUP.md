# 🚀 Ethereum Full Node Setup for Linux Mint

## 📋 Обзор

Это руководство описывает полную настройку Ethereum ноды на Linux Mint, оптимизированную для работы на Lenovo ThinkPad и подобных системах.

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

### Минимальные требования
- **ОС**: Linux Mint 20+ или Ubuntu 20.04+
- **RAM**: 8GB
- **CPU**: 4 ядра
- **Диск**: 100GB свободного места
- **Сеть**: Стабильное интернет-соединение

### Рекомендуемые требования
- **ОС**: Linux Mint 21+ или Ubuntu 22.04+
- **RAM**: 16GB+
- **CPU**: 8+ ядер
- **Диск**: 1TB+ свободного места (SSD рекомендуется)
- **Сеть**: Высокоскоростное интернет-соединение

## 🚀 Быстрый старт

### 1. Подготовка системы

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
sudo apt install -y curl wget git htop iotop iftop
```

### 2. Клонирование репозитория

```bash
# Клонирование только нужной ветки
git clone --branch eth_full_node_lenovo --single-branch <repository-url> defimon-node
cd defimon-node
```

### 3. Запуск автоматического развертывания

```bash
# Запуск скрипта развертывания
sudo ./scripts/deploy-linux-mint-node.sh
```

### 4. Проверка статуса

```bash
# Проверка статуса ноды
sudo /opt/defimon/manage-node.sh status

# Просмотр логов
sudo /opt/defimon/manage-node.sh logs
```

## 🔧 Ручная настройка

### Установка Docker

```bash
# Удаление старых версий
sudo apt remove docker docker-engine docker.io containerd runc

# Установка зависимостей
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Добавление GPG ключа
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Добавление репозитория
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установка Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Добавление пользователя в группу docker
sudo usermod -aG docker $USER
```

### Установка Docker Compose

```bash
# Установка Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Оптимизация системы

```bash
# Настройка CPU для производительности
sudo cpupower frequency-set -g performance

# Настройка swappiness
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
echo 'vm.dirty_ratio=15' | sudo tee -a /etc/sysctl.conf
echo 'vm.dirty_background_ratio=5' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Настройка файрвола
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow from 127.0.0.1 to any port 8545
sudo ufw allow from 127.0.0.1 to any port 8546
```

## 🌐 Доступные интерфейсы

После развертывания:

- **Ethereum RPC**: http://localhost:8545
- **Ethereum WebSocket**: ws://localhost:8546
- **Grafana мониторинг**: http://localhost:3001 (admin/Cal1f0rn1a@2025)
- **Prometheus**: http://localhost:9090
- **Админ дашборд**: http://localhost:8080

## 📊 Мониторинг

### Автоматический мониторинг

```bash
# Проверка статуса системы
sudo /opt/defimon/monitor-node.sh

# Непрерывный мониторинг
watch -n 30 'sudo /opt/defimon/monitor-node.sh'
```

### Ручной мониторинг

```bash
# Проверка использования ресурсов
htop
iotop
iftop

# Проверка дискового пространства
df -h /opt/defimon

# Проверка логов
sudo journalctl -u defimon-node.service -f
```

## 🔧 Управление нодой

### Основные команды

```bash
# Запуск ноды
sudo /opt/defimon/manage-node.sh start

# Остановка ноды
sudo /opt/defimon/manage-node.sh stop

# Перезапуск ноды
sudo /opt/defimon/manage-node.sh restart

# Проверка статуса
sudo /opt/defimon/manage-node.sh status

# Просмотр логов
sudo /opt/defimon/manage-node.sh logs

# Обновление ноды
sudo /opt/defimon/manage-node.sh update

# Создание резервной копии
sudo /opt/defimon/manage-node.sh backup
```

### Диагностика

```bash
# Полная диагностика системы
sudo /opt/defimon/diagnose.sh

# Проверка синхронизации
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545
```

## 💾 Резервное копирование

### Автоматическое резервное копирование

Резервные копии создаются автоматически каждый день в 2:00 AM.

### Ручное резервное копирование

```bash
# Создание резервной копии
sudo /opt/defimon/manage-node.sh backup

# Список резервных копий
ls -la /opt/defimon/backup/

# Восстановление из резервной копии
sudo /opt/defimon/manage-node.sh stop
sudo rm -rf /opt/defimon/data/ethereum/*
sudo tar -xzf /opt/defimon/backup/ethereum-backup-YYYYMMDD-HHMMSS.tar.gz -C /opt/defimon/data/
sudo /opt/defimon/manage-node.sh start
```

## 🔍 Устранение неполадок

### Проблемы с Docker

```bash
# Проверка статуса Docker
sudo systemctl status docker

# Перезапуск Docker
sudo systemctl restart docker

# Проверка логов Docker
sudo journalctl -u docker.service -f
```

### Проблемы с дисковым пространством

```bash
# Проверка использования диска
df -h

# Очистка Docker
sudo docker system prune -f

# Очистка логов
sudo journalctl --vacuum-time=7d
```

### Проблемы с синхронизацией

```bash
# Проверка статуса синхронизации
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545

# Сброс ноды (если нужно)
sudo /opt/defimon/manage-node.sh stop
sudo rm -rf /opt/defimon/data/ethereum/*
sudo /opt/defimon/manage-node.sh start
```

### Проблемы с сетью

```bash
# Проверка сетевых подключений
netstat -tuln | grep -E ':(8545|8546|3001|9090|8080)'

# Проверка файрвола
sudo ufw status

# Проверка DNS
nslookup google.com
```

## 📈 Оптимизация производительности

### Настройка для Lenovo ThinkPad

```bash
# Отключение энергосбережения
sudo cpupower frequency-set -g performance

# Настройка термального управления
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils
sudo systemctl enable cpufrequtils

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

# Мониторинг температуры
sensors
```

## 🔒 Безопасность

### Настройка файрвола

```bash
# Базовая настройка UFW
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh

# Разрешение только локальных подключений
sudo ufw allow from 127.0.0.1 to any port 8545
sudo ufw allow from 127.0.0.1 to any port 8546
sudo ufw allow from 127.0.0.1 to any port 3001
sudo ufw allow from 127.0.0.1 to any port 9090
sudo ufw allow from 127.0.0.1 to any port 8080
```

### Настройка Fail2ban

```bash
# Установка Fail2ban
sudo apt install -y fail2ban

# Создание конфигурации
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Настройка для SSH
echo '[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600' | sudo tee -a /etc/fail2ban/jail.local

# Перезапуск Fail2ban
sudo systemctl restart fail2ban
```

### Обновление системы

```bash
# Регулярные обновления
sudo apt update && sudo apt upgrade -y

# Обновление Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
```

## 📚 Дополнительная документация

- **Мониторинг**: [docs/MONITORING.md](docs/MONITORING.md)
- **L2 настройка**: [L2_SETUP.md](L2_SETUP.md)
- **Административный дашборд**: [docs/ADMIN_DASHBOARD.md](docs/ADMIN_DASHBOARD.md)

## 🆘 Поддержка

### Логи

```bash
# Системные логи
sudo journalctl -u defimon-node.service -f

# Docker логи
sudo docker logs defimon-blockchain-service -f

# Логи мониторинга
tail -f /opt/defimon/logs/monitor.log
```

### Диагностика

```bash
# Полная диагностика
sudo /opt/defimon/diagnose.sh

# Проверка ресурсов
sudo /opt/defimon/monitor-node.sh
```

## 🎉 Готово!

После успешного развертывания у вас будет:

- ✅ Полная Ethereum нода
- ✅ Автоматический запуск при загрузке системы
- ✅ Мониторинг и алерты
- ✅ Резервное копирование
- ✅ Оптимизация для Linux Mint
- ✅ Готовность к работе с L2 сетями

Система готова к использованию!
