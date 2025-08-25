# Развертывание DEFIMON на Linux Mint

## Обзор

Это руководство описывает полное развертывание DEFIMON на Linux Mint с автоматическим определением диска с максимальным свободным местом и настройкой всех компонентов мониторинга.

## Системные требования

### Минимальные требования
- **ОС**: Linux Mint 20+ или Ubuntu 20.04+
- **RAM**: 8GB (16GB рекомендуется)
- **CPU**: 4 ядра (8+ рекомендуется)
- **Диск**: 100GB свободного места (1TB+ рекомендуется)
- **Сеть**: Стабильное интернет-соединение

### Рекомендуемые требования
- **RAM**: 16GB+
- **CPU**: 8+ ядер
- **Диск**: 1TB+ SSD
- **Сеть**: 100Mbps+ стабильное соединение

## Подготовка системы

### 1. Обновление системы

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Установка необходимых пакетов

```bash
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    bc \
    htop \
    iotop \
    nethogs \
    tree \
    unzip \
    zip \
    jq \
    postgresql-client \
    redis-tools
```

### 3. Установка Docker

```bash
# Удаление старых версий
sudo apt remove docker docker-engine docker.io containerd runc

# Установка зависимостей
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Добавление GPG ключа Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Добавление репозитория Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установка Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Добавление пользователя в группу docker
sudo usermod -aG docker $USER

# Запуск и включение Docker
sudo systemctl start docker
sudo systemctl enable docker
```

### 4. Перезагрузка системы

```bash
sudo reboot
```

## Развертывание

### Автоматическое развертывание

1. **Клонирование репозитория**

```bash
git clone <repository-url>
cd DEFIMON
```

2. **Запуск автоматического развертывания**

```bash
./scripts/deploy-linux-mint.sh
```

Скрипт автоматически:
- Проверит системные требования
- Установит зависимости
- Найдет диск с максимальным свободным местом
- Создаст структуру директорий
- Настроит переменные окружения
- Развернет все сервисы
- Проведет health checks
- Создаст скрипты мониторинга и резервного копирования

### Ручное развертывание

Если автоматическое развертывание не подходит, можно выполнить шаги вручную:

1. **Проверка системы**

```bash
./scripts/system-monitor.sh
```

2. **Настройка переменных окружения**

```bash
cp env.example .env
# Отредактируйте .env файл
```

3. **Запуск сервисов**

```bash
cd infrastructure
docker-compose up -d
```

## Структура данных

После развертывания данные будут размещены в следующей структуре:

```
/selected-disk/defimon/
├── data/
│   ├── postgres/          # PostgreSQL данные
│   ├── clickhouse/        # ClickHouse данные
│   ├── redis/            # Redis данные
│   ├── ethereum/         # Ethereum нода данные
│   ├── grafana/          # Grafana данные
│   └── prometheus/       # Prometheus данные
├── logs/                 # Логи системы
├── backups/              # Резервные копии
├── configs/              # Конфигурационные файлы
├── monitor.sh            # Скрипт мониторинга
└── backup.sh             # Скрипт резервного копирования
```

## Мониторинг и управление

### Административный дашборд

- **URL**: http://localhost:8080
- **Функции**: Мониторинг всех сервисов в реальном времени

### Системный мониторинг

```bash
# Одноразовая проверка
./scripts/system-monitor.sh

# Непрерывный мониторинг
./scripts/system-monitor.sh continuous

# JSON формат для API
./scripts/system-monitor.sh json
```

### Управление сервисами

```bash
# Остановка всех сервисов
./scripts/deploy-linux-mint.sh stop

# Перезапуск сервисов
./scripts/deploy-linux-mint.sh restart

# Просмотр логов
./scripts/deploy-linux-mint.sh logs

# Статус сервисов
./scripts/deploy-linux-mint.sh status

# Очистка системы
./scripts/deploy-linux-mint.sh clean
```

### Резервное копирование

```bash
# Создание резервной копии
./data/backup.sh

# Автоматическое резервное копирование (cron)
# Добавьте в crontab:
# 0 2 * * * /path/to/DEFIMON/data/backup.sh
```

## Доступные сервисы

### Веб-интерфейсы
- **Frontend**: http://localhost:3000
- **Admin Dashboard**: http://localhost:8080
- **API Gateway**: http://localhost:8000

### Мониторинг
- **Grafana**: http://localhost:3001 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Kong Admin**: http://localhost:8001

### API сервисы
- **Analytics API**: http://localhost:8002
- **AI/ML Service**: http://localhost:8001

### Базы данных
- **PostgreSQL**: localhost:5432
- **ClickHouse**: http://localhost:8123
- **Redis**: localhost:6379
- **Kafka**: localhost:9092

## Устранение неполадок

### Проблемы с Docker

```bash
# Проверка статуса Docker
sudo systemctl status docker

# Перезапуск Docker
sudo systemctl restart docker

# Очистка Docker
docker system prune -f
```

### Проблемы с дисковым пространством

```bash
# Проверка использования диска
df -h

# Очистка Docker образов
docker image prune -f

# Очистка неиспользуемых томов
docker volume prune -f
```

### Проблемы с памятью

```bash
# Проверка использования памяти
free -h

# Очистка кэша
sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
```

### Проблемы с сетью

```bash
# Проверка сетевых соединений
netstat -tulpn

# Проверка портов
sudo lsof -i -P -n | grep LISTEN
```

### Логи сервисов

```bash
# Просмотр логов всех сервисов
docker-compose -f infrastructure/docker-compose.yml logs -f

# Логи конкретного сервиса
docker-compose -f infrastructure/docker-compose.yml logs -f analytics-api

# Логи blockchain ноды
docker-compose -f infrastructure/docker-compose.yml logs -f blockchain-node
```

## Оптимизация производительности

### Настройка Docker

```bash
# Создание файла конфигурации Docker
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

# Перезапуск Docker
sudo systemctl restart docker
```

### Настройка системы

```bash
# Увеличение лимитов файлов
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Настройка swappiness
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Мониторинг производительности

```bash
# Установка дополнительных инструментов мониторинга
sudo apt install -y \
    iotop \
    htop \
    nethogs \
    iftop \
    nload

# Запуск мониторинга в реальном времени
./scripts/system-monitor.sh continuous
```

## Безопасность

### Настройка файрвола

```bash
# Установка UFW
sudo apt install -y ufw

# Настройка правил
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 3000/tcp  # Frontend
sudo ufw allow 8080/tcp  # Admin Dashboard
sudo ufw allow 8000/tcp  # API Gateway

# Включение файрвола
sudo ufw enable
```

### Обновление системы

```bash
# Настройка автоматических обновлений
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

### Резервное копирование

```bash
# Создание скрипта автоматического резервного копирования
crontab -e

# Добавьте строку для ежедневного резервного копирования в 2:00
0 2 * * * /path/to/DEFIMON/data/backup.sh
```

## Расширенная настройка

### Настройка SSL/TLS

```bash
# Установка Certbot
sudo apt install -y certbot

# Получение SSL сертификата
sudo certbot certonly --standalone -d your-domain.com

# Настройка автоматического обновления
sudo crontab -e
# Добавьте строку:
0 12 * * * /usr/bin/certbot renew --quiet
```

### Настройка обратного прокси

```bash
# Установка Nginx
sudo apt install -y nginx

# Создание конфигурации
sudo tee /etc/nginx/sites-available/defimon <<EOF
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
    
    location /admin {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Включение сайта
sudo ln -s /etc/nginx/sites-available/defimon /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Поддержка

### Полезные команды

```bash
# Проверка статуса всех сервисов
docker-compose -f infrastructure/docker-compose.yml ps

# Перезапуск конкретного сервиса
docker-compose -f infrastructure/docker-compose.yml restart analytics-api

# Просмотр ресурсов Docker
docker stats

# Очистка системы
docker system prune -f
docker volume prune -f
docker image prune -f
```

### Логи и отладка

```bash
# Просмотр логов в реальном времени
docker-compose -f infrastructure/docker-compose.yml logs -f

# Логи конкретного сервиса
docker-compose -f infrastructure/docker-compose.yml logs -f blockchain-node

# Проверка конфигурации
docker-compose -f infrastructure/docker-compose.yml config
```

### Мониторинг производительности

```bash
# Системный мониторинг
./scripts/system-monitor.sh

# Непрерывный мониторинг
./scripts/system-monitor.sh continuous

# Мониторинг через веб-интерфейс
# Откройте http://localhost:8080
```

## Заключение

После успешного развертывания у вас будет полностью функциональная система DEFIMON с:

- ✅ Полной нодой Ethereum
- ✅ Мониторингом L2 сетей
- ✅ Административным дашбордом
- ✅ Системой мониторинга
- ✅ Автоматическим резервным копированием
- ✅ Оптимизацией для Linux Mint

Система готова к использованию и дальнейшему развитию!
