# DEFIMON Ethereum Nodes GCP Production Deployment

Это руководство описывает процесс развертывания Ethereum нод (Geth + Lighthouse) на Google Cloud Platform с production-grade конфигурацией, включая NGINX reverse proxy, Let's Encrypt SSL сертификаты и мониторинг.

## 🚀 Быстрый старт

### 1. Подготовка окружения

```bash
# Установить Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Установить Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Установить jq для JSON обработки
sudo apt-get install jq
```

### 2. Настройка конфигурации

```bash
# Скопировать конфигурационный файл
cp scripts/gcp-production.env .env

# Отредактировать .env файл с вашими значениями
nano .env
```

### 3. Развертывание

```bash
# Сделать скрипт исполняемым
chmod +x scripts/deploy-ethereum-gcp-production.sh

# Запустить развертывание
./scripts/deploy-ethereum-gcp-production.sh
```

## 📋 Требования

### Системные требования
- **CPU**: Минимум 4 vCPU (рекомендуется 8+)
- **RAM**: Минимум 8GB (рекомендуется 16GB+)
- **Boot диск**: 100GB SSD (для ОС и приложений)
- **Data диск**: 2TB Standard Persistent Disk (для блокчейн данных)
- **Сеть**: Стабильное интернет-соединение

### Программные требования
- Google Cloud SDK
- Docker и Docker Compose
- jq (для JSON обработки)
- curl (для тестирования API)

## ⚙️ Конфигурация

### Основные параметры (.env файл)

```bash
# Google Cloud Configuration
GOOGLE_CLOUD_PROJECT_ID=your-project-id
GOOGLE_CLOUD_REGION=us-central1
GOOGLE_CLOUD_ZONE=us-central1-a

# Domain Configuration
DOMAIN=defimon.highfunk.uk
ADMIN_EMAIL=admin@highfunk.uk

# VM Configuration
VM_MACHINE_TYPE=e2-standard-4
VM_BOOT_DISK_SIZE=100GB
VM_BOOT_DISK_TYPE=pd-ssd
VM_DATA_DISK_SIZE=2048GB
VM_DATA_DISK_TYPE=pd-standard
```

### Рекомендуемые machine types

| Тип | vCPU | RAM | Цена/час | Рекомендация |
|-----|------|-----|----------|--------------|
| e2-standard-4 | 4 | 16GB | $0.134 | Минимум |
| e2-standard-8 | 8 | 32GB | $0.268 | Рекомендуется |
| e2-standard-16 | 16 | 64GB | $0.536 | Высокая нагрузка |
| e2-highmem-8 | 8 | 64GB | $0.428 | Больше RAM |

## 🏗️ Архитектура развертывания

```
Internet
    ↓
[Cloud Load Balancer] (опционально)
    ↓
[VM Instance: ethereum-production]
    ├── Boot Disk (100GB SSD) - ОС и приложения
    ├── Data Disk (2TB Standard) - Блокчейн данные
    │   ├── Geth chaindata (~1.5TB)
    │   └── Lighthouse beacon (~500GB)
    ├── NGINX (Reverse Proxy + SSL)
    ├── Geth (Execution Client)
    ├── Lighthouse (Consensus Client)
    ├── Prometheus (Мониторинг)
    ├── Grafana (Дашборды)
    └── Node Exporter (Системные метрики)
```

### Порты и сервисы

| Порт | Сервис | Описание |
|------|--------|----------|
| 80 | NGINX | HTTP (редирект на HTTPS) |
| 443 | NGINX | HTTPS (основной трафик) |
| 8545 | Geth | Ethereum RPC API |
| 5052 | Lighthouse | Beacon API |
| 3000 | Grafana | Дашборды мониторинга |
| 9090 | Prometheus | Метрики |
| 9100 | Node Exporter | Системные метрики |

## 🔐 Безопасность

### SSL/TLS конфигурация
- **Протоколы**: TLSv1.2, TLSv1.3
- **Шифры**: ECDHE-RSA с AES-GCM
- **HSTS**: Включен с max-age=31536000
- **OCSP Stapling**: Включен

### Rate Limiting
- **API endpoints**: 20 запросов/сек
- **Metrics**: 5 запросов/сек
- **Login**: 2 запроса/сек

### Security Headers
```nginx
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'self'
```

## 📊 Мониторинг

### Prometheus метрики
- **Geth**: Синхронизация, память, CPU, сеть
- **Lighthouse**: Beacon chain статус, peers
- **System**: CPU, RAM, диск, сеть
- **NGINX**: Запросы, ошибки, latency

### Grafana дашборды
- **Ethereum Node Overview**: Общий статус нод
- **System Resources**: Системные ресурсы
- **Network Performance**: Производительность сети
- **Sync Progress**: Прогресс синхронизации

### Алерты
- Нода не синхронизируется
- Высокое потребление ресурсов
- Ошибки NGINX
- Проблемы с SSL сертификатами

## 💾 Резервное копирование

### Автоматические бэкапы
- **Расписание**: Ежедневно в 2:00 AM
- **Хранение**: Google Cloud Storage
- **Удержание**: 30 дней
- **Данные**: Geth и Lighthouse блокчейн данные

### Ручные бэкапы
```bash
# Запустить бэкап вручную
./scripts/manage-ethereum-production.sh backup
```

### Снапшоты дисков
```bash
# Создать снапшот диска
./scripts/manage-ethereum-disks.sh snapshot ethereum-data-disk

# Список снапшотов
./scripts/manage-ethereum-disks.sh snapshots

# Восстановить из снапшота
./scripts/manage-ethereum-disks.sh restore ethereum-data-20241201-120000
```

## 🛠️ Управление

### Основные команды

```bash
# Проверить статус
./scripts/manage-ethereum-production.sh status

# Посмотреть логи
./scripts/manage-ethereum-production.sh logs geth
./scripts/manage-ethereum-production.sh logs lighthouse

# Перезапустить сервисы
./scripts/manage-ethereum-production.sh restart-services nginx

# Проверить синхронизацию
./scripts/manage-ethereum-production.sh sync

# Обновить SSL сертификат
./scripts/manage-ethereum-production.sh ssl

# Масштабировать VM
./scripts/manage-ethereum-production.sh scale e2-standard-8
```

### Управление дисками

```bash
# Информация о дисках
./scripts/manage-ethereum-disks.sh info

# Создание нового диска
./scripts/manage-ethereum-disks.sh create 4096 pd-ssd

# Изменение размера диска
./scripts/manage-ethereum-disks.sh resize ethereum-data-disk 4096

# Создание снапшота
./scripts/manage-ethereum-disks.sh snapshot ethereum-data-disk

# Восстановление из снапшота
./scripts/manage-ethereum-disks.sh restore ethereum-data-20241201-120000

# Проверка здоровья диска
./scripts/manage-ethereum-disks.sh health

# Оптимизация производительности
./scripts/manage-ethereum-disks.sh optimize
```

### SSH доступ
```bash
# Подключиться к VM
./scripts/manage-ethereum-production.sh ssh

# Или напрямую
gcloud compute ssh ethereum-production --zone=us-central1-a
```

## 🔍 Диагностика

### Проверка здоровья ноды
```bash
# Health check
curl https://defimon.highfunk.uk/health

# Status check
curl https://defimon.highfunk.uk/status

# Ethereum RPC
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  https://defimon.highfunk.uk/eth/

# Beacon API
curl https://defimon.highfunk.uk/beacon/syncing
```

### Просмотр логов
```bash
# NGINX access logs
./scripts/manage-ethereum-production.sh nginx-logs

# NGINX error logs
./scripts/manage-ethereum-production.sh nginx-errors

# Service logs
./scripts/manage-ethereum-production.sh logs geth
./scripts/manage-ethereum-production.sh logs lighthouse
```

## 📈 Масштабирование

### Вертикальное масштабирование
```bash
# Увеличить ресурсы VM
./scripts/manage-ethereum-production.sh scale e2-standard-8

# Проверить текущие ресурсы
./scripts/manage-ethereum-production.sh monitor
```

### Горизонтальное масштабирование
- Добавить дополнительные VM для балансировки нагрузки
- Использовать Cloud Load Balancer
- Настроить multiple Ethereum ноды

## 🚨 Troubleshooting

### Частые проблемы

#### 1. Нода не синхронизируется
```bash
# Проверить статус синхронизации
./scripts/manage-ethereum-production.sh sync

# Посмотреть логи Geth
./scripts/manage-ethereum-production.sh logs geth

# Проверить ресурсы
./scripts/manage-ethereum-production.sh monitor

# Проверить состояние дисков
./scripts/manage-ethereum-production.sh disk

#### 2. SSL сертификат истек
```bash
# Обновить сертификат
./scripts/manage-ethereum-production.sh ssl

# Проверить статус
./scripts/manage-ethereum-production.sh test
```

#### 3. Высокое потребление ресурсов
```bash
# Мониторинг ресурсов
./scripts/manage-ethereum-production.sh monitor

# Масштабирование
./scripts/manage-ethereum-production.sh scale e2-standard-8
```

#### 4. NGINX ошибки
```bash
# Проверить логи NGINX
./scripts/manage-ethereum-production.sh nginx-errors

# Перезапустить NGINX
./scripts/manage-ethereum-production.sh restart-services nginx
```

#### 5. Проблемы с диском
```bash
# Проверить состояние дисков
./scripts/manage-ethereum-production.sh disk

# Проверить монтирование
./scripts/manage-ethereum-production.sh monitor

# Перезапустить VM если диск не монтируется
./scripts/manage-ethereum-production.sh restart

# Расширенное управление дисками
./scripts/manage-ethereum-disks.sh health
./scripts/manage-ethereum-disks.sh optimize
```

## 💰 Стоимость

### Примерная стоимость (us-central1)

| Компонент | Стоимость/месяц | Описание |
|-----------|-----------------|----------|
| VM (e2-standard-4) | ~$97 | 4 vCPU, 16GB RAM |
| Boot диск (100GB SSD) | ~$17 | Persistent Disk SSD |
| Data диск (2TB Standard) | ~$34 | Persistent Disk Standard |
| Сеть | ~$10 | Egress трафик |
| **Итого** | **~$158** | Без учета скидок |

### Оптимизация затрат
- Использовать Preemptible VM для тестирования
- Применить committed use discounts
- Оптимизировать размер диска
- Использовать Cloud Storage для архивных данных

## 📚 Дополнительные ресурсы

### Документация
- [Google Cloud Compute Engine](https://cloud.google.com/compute/docs)
- [Ethereum Node Setup](https://ethereum.org/en/developers/docs/nodes-and-clients/)
- [Lighthouse Documentation](https://lighthouse-book.sigmaprime.io/)
- [NGINX Configuration](https://nginx.org/en/docs/)

### Полезные ссылки
- [Ethereum Mainnet Checkpoints](https://sync-mainnet.beaconcha.in/)
- [Ethereum Node Requirements](https://ethereum.org/en/developers/docs/nodes-and-clients/run-a-node/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

## 🤝 Поддержка

При возникновении проблем:

1. Проверить логи: `./scripts/manage-ethereum-production.sh logs`
2. Проверить статус: `./scripts/manage-ethereum-production.sh status`
3. Проверить мониторинг: `./scripts/manage-ethereum-production.sh metrics`
4. Создать issue в репозитории с логами и описанием проблемы

---

**Примечание**: Этот скрипт предназначен для production использования. Убедитесь, что у вас есть соответствующие права доступа и понимание рисков перед развертыванием в production среде.
