# DEFIMON Kafka Fix Guide

## Обзор

Этот документ описывает процесс исправления проблем с Kafka в DEFIMON путем замены его на Google Cloud Pub/Sub. Это решение устраняет ошибки Kafka и улучшает производительность системы.

## Проблемы с Kafka

### Известные проблемы:
1. **Сложность настройки** - Kafka требует сложной конфигурации кластера
2. **Высокое потребление ресурсов** - Kafka потребляет много RAM и CPU
3. **Проблемы с масштабированием** - Сложно масштабировать в небольших развертываниях
4. **Ошибки подключения** - Частые проблемы с подключением к брокерам
5. **Сложность мониторинга** - Трудно отслеживать состояние кластера

### Решение: Google Cloud Pub/Sub

Google Cloud Pub/Sub предоставляет:
- ✅ Простота настройки
- ✅ Автоматическое масштабирование
- ✅ Высокая надежность
- ✅ Встроенный мониторинг
- ✅ Интеграция с Google Cloud

## Архитектура решения

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              DEFIMON SERVICES                               │
├─────────────────────────────────────────────────────────────────────────────┤
│  Analytics API     │  AI/ML Service   │  Blockchain Node │  Data Ingestion │
│  (Python/FastAPI)  │  (Python)        │  (Rust)         │  (Python)       │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                ┌───────▼───────┐
                                │  Google Cloud │
                                │  Pub/Sub      │
                                │  (Topic)      │
                                └───────┬───────┘
                                        │
                                ┌───────▼───────┐
                                │  Google Cloud │
                                │  Pub/Sub      │
                                │  (Subscription)│
                                └───────┬───────┘
                                        │
┌─────────────────────────────────────────────────────────────────────────────┐
│                              DATA PROCESSING                               │
├─────────────────────────────────────────────────────────────────────────────┤
│  Stream Processing│  Batch Processing│  ML Pipeline    │  Event Indexer    │
│  (Python)         │  (Apache Airflow)│  (MLflow)       │  (Rust)          │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Установка и настройка

### Предварительные требования

1. **Google Cloud Project**
   ```bash
   # Создайте проект в Google Cloud Console
   # Или используйте существующий проект
   ```

2. **Google Cloud SDK**
   ```bash
   # Установка Google Cloud SDK
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL
   gcloud init
   ```

3. **Аутентификация**
   ```bash
   # Войдите в Google Cloud
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

### Автоматическая установка

Запустите скрипт исправления:

```bash
# Перейдите в директорию проекта
cd /path/to/defimon.highfunk.uk

# Сделайте скрипт исполняемым
chmod +x scripts/fix-kafka-issues.sh

# Запустите скрипт (требуются права root)
sudo ./scripts/fix-kafka-issues.sh
```

### Ручная установка

Если автоматический скрипт не подходит, выполните шаги вручную:

#### Шаг 1: Создание Pub/Sub ресурсов

```bash
# Создание топика
gcloud pubsub topics create defimon-events

# Создание подписки
gcloud pubsub subscriptions create defimon-events-sub \
    --topic=defimon-events \
    --ack-deadline=600 \
    --message-retention-duration=7d
```

#### Шаг 2: Обновление конфигурации

```bash
# Копирование новой конфигурации
cp config/defimon-kafka-fix.env .env

# Обновление конфигурации Geth
cp config/geth-optimized.toml config/geth-config.toml
```

#### Шаг 3: Установка зависимостей

```bash
# Python зависимости для Pub/Sub
pip3 install google-cloud-pubsub
pip3 install google-auth
pip3 install google-auth-oauthlib
pip3 install google-auth-httplib2
```

#### Шаг 4: Перезапуск сервисов

```bash
# Остановка существующих сервисов
docker-compose down

# Запуск с новой конфигурацией
docker-compose up -d
```

## Конфигурация

### Переменные окружения

```bash
# Google Cloud Pub/Sub Configuration
GOOGLE_CLOUD_PUBSUB_TOPIC=defimon-events
GOOGLE_CLOUD_PUBSUB_SUBSCRIPTION=defimon-events-sub
GOOGLE_CLOUD_PUBSUB_ACK_DEADLINE=600
GOOGLE_CLOUD_PUBSUB_MAX_MESSAGES=1000
GOOGLE_CLOUD_PUBSUB_RETRY_POLICY_MAX_ATTEMPTS=5
GOOGLE_CLOUD_PUBSUB_RETRY_POLICY_MIN_BACKOFF=1
GOOGLE_CLOUD_PUBSUB_RETRY_POLICY_MAX_BACKOFF=600

# Event Streaming Configuration
EVENT_STREAM_ENABLED=true
EVENT_STREAM_BATCH_SIZE=100
EVENT_STREAM_FLUSH_INTERVAL=5
EVENT_STREAM_MAX_CONCURRENT_PUBLISHERS=10
EVENT_STREAM_ERROR_RETRY_ATTEMPTS=3
EVENT_STREAM_ERROR_RETRY_DELAY=5
```

### Geth оптимизация

```toml
[Eth]
SyncMode = "full"
Cache = 8192
DatabaseCache = 4096
TrieCache = 256
SnapshotCache = 256
StateCache = 256

[Node]
MaxPeers = 50
HTTPPort = 8545
WSPort = 8546
P2P = 30303
HTTPEnabled = true
WSEnabled = true
HTTPCors = ["*"]
HTTPVirtualHosts = ["*"]
HTTPModules = ["eth", "net", "web3", "debug", "txpool", "personal", "admin"]
WSModules = ["eth", "net", "web3", "debug", "txpool", "personal", "admin"]
```

## Использование Pub/Sub API

### Python интеграция

```python
from scripts.pubsub_integration import PubSubManager

# Инициализация
pubsub = PubSubManager()

# Публикация события
event_data = {
    'network': 'ethereum',
    'block_number': 12345,
    'data': {...}
}

message_id = pubsub.publish_event('blockchain_event', event_data)
print(f"Published event with ID: {message_id}")

# Подписка на события
def handle_event(data):
    print(f"Received event: {data}")

pubsub.subscribe_to_events(handle_event)
```

### JavaScript интеграция

```javascript
// Установка зависимостей
npm install @google-cloud/pubsub

// Использование
const {PubSub} = require('@google-cloud/pubsub');

const pubsub = new PubSub();
const topicName = 'defimon-events';

// Публикация сообщения
async function publishMessage(data) {
    const messageBuffer = Buffer.from(JSON.stringify(data));
    const messageId = await pubsub.topic(topicName).publish(messageBuffer);
    console.log(`Message ${messageId} published.`);
}

// Подписка на сообщения
const subscriptionName = 'defimon-events-sub';

const subscription = pubsub.subscription(subscriptionName);

subscription.on('message', message => {
    console.log(`Received message ${message.id}:`);
    console.log(`\tData: ${message.data}`);
    console.log(`\tAttributes: ${message.attributes}`);
    
    // Обработка сообщения
    processMessage(message.data);
    
    // Подтверждение получения
    message.ack();
});
```

## Мониторинг и отладка

### Проверка состояния Pub/Sub

```bash
# Проверка топиков
gcloud pubsub topics list

# Проверка подписок
gcloud pubsub subscriptions list

# Просмотр сообщений
gcloud pubsub subscriptions pull defimon-events-sub --auto-ack
```

### Логи и мониторинг

```bash
# Просмотр логов сервисов
docker-compose logs -f analytics-api
docker-compose logs -f ai-ml-service
docker-compose logs -f geth

# Мониторинг метрик
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3002 (admin/Cal1f0rn1a@2025)
```

### Тестирование интеграции

```bash
# Запуск тестового скрипта
python3 scripts/pubsub-integration.py

# Проверка подключения
curl -X GET http://localhost:8000/health
curl -X GET http://localhost:8001/health
```

## Производительность

### Оптимизация настроек

```bash
# Настройки для высоконагруженных систем
GOOGLE_CLOUD_PUBSUB_MAX_MESSAGES=5000
EVENT_STREAM_BATCH_SIZE=500
EVENT_STREAM_MAX_CONCURRENT_PUBLISHERS=20

# Настройки для небольших систем
GOOGLE_CLOUD_PUBSUB_MAX_MESSAGES=100
EVENT_STREAM_BATCH_SIZE=50
EVENT_STREAM_MAX_CONCURRENT_PUBLISHERS=5
```

### Мониторинг производительности

```bash
# Проверка использования ресурсов
docker stats

# Мониторинг сети
iftop -i eth0

# Мониторинг диска
iotop
```

## Безопасность

### Аутентификация

```bash
# Настройка Service Account
gcloud iam service-accounts create defimon-service \
    --display-name="DEFIMON Service Account"

# Создание ключа
gcloud iam service-accounts keys create key.json \
    --iam-account=defimon-service@YOUR_PROJECT_ID.iam.gserviceaccount.com

# Настройка переменной окружения
export GOOGLE_APPLICATION_CREDENTIALS="key.json"
```

### Шифрование

```bash
# Включение шифрования в rest
GOOGLE_CLOUD_PUBSUB_ENCRYPTION_ENABLED=true
GOOGLE_CLOUD_PUBSUB_KMS_KEY_NAME=projects/YOUR_PROJECT/locations/global/keyRings/defimon/cryptoKeys/pubsub-key
```

## Резервное копирование и восстановление

### Создание резервной копии

```bash
# Резервное копирование конфигурации
BACKUP_DIR="/data/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

cp .env "$BACKUP_DIR/env.backup"
cp config/geth-config.toml "$BACKUP_DIR/geth-config.toml.backup"
cp secrets.env "$BACKUP_DIR/secrets.env.backup"
```

### Восстановление

```bash
# Восстановление из резервной копии
cp "$BACKUP_DIR/env.backup" .env
cp "$BACKUP_DIR/geth-config.toml.backup" config/geth-config.toml
cp "$BACKUP_DIR/secrets.env.backup" secrets.env

# Перезапуск сервисов
docker-compose down
docker-compose up -d
```

## Устранение неполадок

### Частые проблемы

#### 1. Ошибка аутентификации
```bash
# Решение: Проверьте аутентификацию
gcloud auth list
gcloud config get-value project
```

#### 2. Ошибка подключения к Pub/Sub
```bash
# Решение: Проверьте права доступа
gcloud pubsub topics list
gcloud pubsub subscriptions list
```

#### 3. Высокое потребление памяти
```bash
# Решение: Уменьшите размеры батчей
EVENT_STREAM_BATCH_SIZE=50
GOOGLE_CLOUD_PUBSUB_MAX_MESSAGES=100
```

#### 4. Медленная обработка событий
```bash
# Решение: Увеличьте количество параллельных обработчиков
EVENT_STREAM_MAX_CONCURRENT_PUBLISHERS=20
```

### Логи ошибок

```bash
# Просмотр логов с ошибками
docker-compose logs | grep -i error
docker-compose logs | grep -i exception
docker-compose logs | grep -i failed
```

## Заключение

Замена Kafka на Google Cloud Pub/Sub решает основные проблемы:

✅ **Упрощение настройки** - Не требуется сложная конфигурация кластера  
✅ **Улучшение производительности** - Автоматическое масштабирование  
✅ **Повышение надежности** - Встроенная отказоустойчивость  
✅ **Упрощение мониторинга** - Интеграция с Google Cloud Monitoring  
✅ **Снижение затрат** - Оплата только за использование  

Система DEFIMON теперь работает стабильно без зависимостей от Kafka и готова к масштабированию.
