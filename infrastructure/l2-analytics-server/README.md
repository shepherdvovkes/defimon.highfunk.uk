# L2 Analytics Server

Полнофункциональный сервер для мониторинга и аналитики L2 сетей Ethereum с поддержкой более 50 сетей.

## 🏗️ Архитектура

### Компоненты системы

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Admin Dashboard│    │   Grafana       │    │   Kong Gateway  │
│   (Port 3000)   │    │   (Port 3001)   │    │   (Port 8443)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   L2 Analytics  │
                    │   API (Port 8000)│
                    └─────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Blockchain Node│    │   AI/ML Service │    │  Data Ingestion │
│  (L2 Sync)      │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Stream Proc.  │
                    └─────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │   ClickHouse    │    │   Redis Cache   │
│   (Port 5432)   │    │   (Port 8123)   │    │   (Port 6379)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Kafka         │
                    │   (Port 9092)   │
                    └─────────────────┘
```

### Поддерживаемые L2 сети

#### Phase 1 (Priority 8-10) - 15 сетей
- **Optimism** (Priority 10) - $850M TVL
- **Arbitrum One** (Priority 10) - $2.1B TVL
- **Polygon zkEVM** (Priority 9) - $45M TVL
- **Base** (Priority 9) - $750M TVL
- **zkSync Era** (Priority 9) - $650M TVL
- **StarkNet** (Priority 8) - $180M TVL
- **Linea** (Priority 8) - $120M TVL
- **Scroll** (Priority 8) - $85M TVL
- **Polygon PoS** (Priority 9) - $850M TVL
- **BSC** (Priority 9) - $5.2B TVL
- **Avalanche** (Priority 8) - $1.1B TVL
- **Solana** (Priority 8) - $1.2B TVL
- **Mantle** (Priority 7) - $45M TVL
- **Metis** (Priority 6) - $35M TVL
- **Loopring** (Priority 7) - $120M TVL

#### Phase 2 (Priority 6-7) - 10 сетей
- **Fantom** (Priority 6) - $85M TVL
- **Cronos** (Priority 6) - $180M TVL
- **Celo** (Priority 5) - $45M TVL
- **Gnosis Chain** (Priority 5) - $35M TVL
- **Ronin** (Priority 6) - $25M TVL
- **Immutable X** (Priority 6) - $25M TVL
- **ConsenSys zkEVM** (Priority 7) - $25M TVL
- **Boba Network** (Priority 5) - $15M TVL
- **Arbitrum Nova** (Priority 5) - $15M TVL

#### Phase 3 (Priority 4-5) - 15+ сетей
- **Harmony** (Priority 4) - $15M TVL
- **Klaytn** (Priority 4) - $25M TVL
- **NEAR** (Priority 4) - $15M TVL
- И другие emerging сети

## 🚀 Быстрый старт

### Требования

- Docker & Docker Compose
- 32GB RAM (рекомендуется 64GB)
- 4TB SSD (рекомендуется NVMe)
- 10Gbps сеть
- Linux/Ubuntu 20.04+

### Развертывание

```bash
# Клонировать репозиторий
git clone https://github.com/your-org/defimon.highfunk.uk.git
cd defimon.highfunk.uk

# Переключиться на ветку L2analysis
git checkout L2analysis

# Запустить развертывание
./scripts/deploy-l2-analytics-server.sh
```

### Ручное развертывание

```bash
# Создать environment файл
cp .env.l2analytics.example .env.l2analytics
# Отредактировать .env.l2analytics

# Запустить сервисы
cd infrastructure/l2-analytics-server
docker-compose up -d

# Проверить статус
docker-compose ps
```

## 📊 Мониторинг

### Доступные интерфейсы

| Сервис | URL | Описание |
|--------|-----|----------|
| Admin Dashboard | http://localhost:3000 | Основной админский интерфейс |
| Grafana | http://localhost:3001 | Дашборды и метрики |
| API Gateway | http://localhost:8443 | Kong API Gateway |
| Prometheus | http://localhost:9090 | Метрики системы |
| Kong Admin | http://localhost:8002 | Управление API Gateway |

### API Endpoints

```bash
# L2 Networks
GET /api/v1/l2/networks                    # Список всех сетей
GET /api/v1/l2/networks/{network}/stats    # Статистика сети
GET /api/v1/l2/networks/{network}/blocks   # Последние блоки
GET /api/v1/l2/networks/{network}/txs      # Последние транзакции

# Analytics
GET /api/v1/analytics/overview             # Общий обзор
GET /api/v1/analytics/gas-fees             # Анализ комиссий
GET /api/v1/analytics/protocols            # Протоколы по сетям

# Health
GET /api/v1/health                         # Статус системы
GET /api/v1/health/networks                # Статус сетей
```

## 🔧 Конфигурация

### Переменные окружения

```bash
# Database
POSTGRES_PASSWORD=l2password_secure_xxx
CLICKHOUSE_PASSWORD=l2password_secure_xxx

# Grafana
GRAFANA_PASSWORD=admin_secure_xxx

# API
API_SECRET_KEY=xxx
JWT_SECRET=xxx

# L2 Networks
L2_NETWORKS=optimism,arbitrum_one,polygon_zkevm,base,zksync_era,starknet,linea,scroll,polygon_pos,bsc,avalanche,solana,mantle,metis,loopring

# Performance
L2_SYNC_INTERVAL=12
L2_BATCH_SIZE=100
L2_MAX_CONCURRENT_REQUESTS=20
L2_PRIORITY_THRESHOLD=6
```

### Настройка производительности

```bash
# Для высоконагруженной системы
L2_MAX_CONCURRENT_REQUESTS=50
L2_SYNC_INTERVAL=6
L2_BATCH_SIZE=200

# Для экономии ресурсов
L2_MAX_CONCURRENT_REQUESTS=10
L2_SYNC_INTERVAL=30
L2_BATCH_SIZE=50
```

## 📈 Метрики

### Основные метрики

- **Blocks Processed**: Количество обработанных блоков
- **Transactions Processed**: Количество обработанных транзакций
- **Sync Speed**: Скорость синхронизации (блоков/сек)
- **Error Rate**: Частота ошибок синхронизации
- **Gas Fees**: Средние комиссии L1/L2
- **Finality Time**: Время финализации
- **Compression Ratio**: Коэффициент сжатия данных

### Grafana Dashboards

1. **L2 Networks Overview** - Общий обзор всех сетей
2. **Network Performance** - Производительность по сетям
3. **Gas Fee Analysis** - Анализ комиссий
4. **Protocol Activity** - Активность протоколов
5. **System Health** - Здоровье системы

## 🔍 Troubleshooting

### Частые проблемы

#### Сервис не запускается
```bash
# Проверить логи
docker-compose logs <service_name>

# Проверить статус
docker-compose ps

# Перезапустить сервис
docker-compose restart <service_name>
```

#### Медленная синхронизация
```bash
# Увеличить количество параллельных запросов
L2_MAX_CONCURRENT_REQUESTS=30

# Уменьшить интервал синхронизации
L2_SYNC_INTERVAL=6

# Проверить ресурсы
docker stats
```

#### Проблемы с базой данных
```bash
# Проверить подключение
docker-compose exec postgres psql -U l2user -d l2_analytics -c "SELECT version();"

# Проверить размер базы
docker-compose exec postgres psql -U l2user -d l2_analytics -c "SELECT pg_size_pretty(pg_database_size('l2_analytics'));"
```

## 🛠️ Разработка

### Добавление новой L2 сети

1. Добавить сеть в `services/blockchain-node/src/l2_networks.rs`
2. Обновить схему базы данных при необходимости
3. Добавить сеть в переменную `L2_NETWORKS`
4. Перезапустить blockchain-node сервис

### Расширение API

1. Добавить новые endpoints в `services/analytics-api/routers/`
2. Обновить документацию API
3. Добавить тесты
4. Обновить Kong конфигурацию при необходимости

## 📚 Документация

- [L2 Networks Setup Guide](../L2_SETUP.md)
- [API Documentation](../docs/API.md)
- [Monitoring Guide](../docs/MONITORING.md)
- [Deployment Guide](../docs/DEPLOYMENT.md)

## 🤝 Поддержка

- Issues: [GitHub Issues](https://github.com/your-org/defimon.highfunk.uk/issues)
- Documentation: [Wiki](https://github.com/your-org/defimon.highfunk.uk/wiki)
- Community: [Discord](https://discord.gg/defimon)

## 📄 Лицензия

MIT License - см. [LICENSE](../LICENSE) файл для деталей.
