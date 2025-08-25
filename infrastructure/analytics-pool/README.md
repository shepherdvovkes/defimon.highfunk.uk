# Analytics Pool - Hetzner Cloud

Этот пул отвечает за аналитические сервисы, API и обработку данных DeFi протоколов на Hetzner Cloud.

## 🏗️ Архитектура

```
Hetzner Cloud
├── Kubernetes Cluster (analytics-cluster)
│   ├── Analytics API (FastAPI)
│   ├── Data Ingestion Service
│   ├── Stream Processing Service
│   └── Blockchain Node Service (Rust)
├── Databases
│   ├── PostgreSQL (основные данные)
│   ├── ClickHouse (аналитика, time-series)
│   └── Redis (кэш, сессии)
├── Storage
│   ├── Block Storage (для баз данных)
│   └── Object Storage (backups, exports)
├── Networking
│   ├── Load Balancer
│   ├── Private Network
│   └── Firewall Rules
└── Monitoring
    ├── Prometheus
    ├── Grafana
    └── Loki (логи)
```

## 📁 Структура

- **kubernetes/** - Kubernetes манифесты для аналитических сервисов
- **services/** - Конфигурации сервисов
- **databases/** - Схемы и миграции БД
- **monitoring/** - Prometheus, Grafana, алерты
- **deployment/** - Скрипты развертывания

## 🚀 Развертывание

### Создание кластера
```bash
# Подключение к Hetzner серверу
ssh vovkes@kraken.highfunk.uk

# Создание Kubernetes кластера
./deployment/create-analytics-cluster.sh
```

### Развертывание сервисов
```bash
# Применение Kubernetes манифестов
kubectl apply -f kubernetes/

# Проверка статуса
kubectl get pods -n analytics
```

## 🔧 Конфигурация

### Переменные окружения
- `HETZNER_API_TOKEN` - API токен для Hetzner Cloud
- `ANALYTICS_DOMAIN` - Домен для аналитических сервисов
- `DATABASE_URL` - URL подключения к PostgreSQL
- `CLICKHOUSE_URL` - URL подключения к ClickHouse

### Ресурсы
- **CPU**: 8-32 vCPU (в зависимости от нагрузки)
- **RAM**: 32-128GB
- **Storage**: 1TB+ SSD для баз данных
- **Network**: 1Gbps+ стабильное соединение

## 📊 Сервисы

### Analytics API (порт 8002)
- FastAPI приложение
- REST API для аналитики
- WebSocket для real-time данных
- Swagger документация

### Data Ingestion
- Сбор данных с Web3 APIs
- Парсинг блокчейн событий
- Rate limiting и retry логика

### Stream Processing
- Обработка потоковых данных
- Apache Kafka интеграция
- Real-time агрегации

### Blockchain Node Service
- Rust сервис для работы с блокчейнами
- Поддержка Ethereum, Cosmos, Polkadot
- Высокая производительность

## 📊 Мониторинг

- **Grafana**: http://analytics.highfunk.uk:3001
- **Prometheus**: http://analytics.highfunk.uk:9090
- **API Docs**: http://analytics.highfunk.uk:8002/docs

## 🔐 Безопасность

- JWT аутентификация
- Rate limiting на уровне API Gateway
- SSL/TLS сертификаты
- Firewall правила
- Private networks для внутренних сервисов
