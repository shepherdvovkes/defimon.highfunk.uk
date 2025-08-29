# Price Oracle System

Система для сбора и агрегации данных о ценах криптовалют с использованием множественных оракулов, включая ETH и популярные L2 сети.

## Обзор системы

Система состоит из следующих компонентов:

1. **Price Oracle Service** - сервис для сбора данных с оракулов
2. **Price API Service** - REST API для доступа к данным
3. **PostgreSQL Database** - хранение данных о ценах
4. **Redis** - кэширование и очереди
5. **Kafka** - потоковая обработка данных

## Поддерживаемые оракулы

- **CoinGecko** - бесплатный API с данными о криптовалютах
- **Binance** - данные с биржи Binance
- **Kraken** - данные с биржи Kraken
- **Coinbase** - данные с биржи Coinbase

## Отслеживаемые активы

### Основные криптовалюты
- ETH (Ethereum)
- BTC (Bitcoin)
- USDC (USD Coin)
- USDT (Tether)

### L2 сети и их токены
- Polygon (MATIC)
- Arbitrum (ARB)
- Optimism (OP)
- Base (ETH)
- zkSync Era (ETH)
- Starknet (ETH)
- Linea (ETH)
- Scroll (ETH)
- Mantle (MNT)
- Blast (ETH)

## Архитектура базы данных

### Основные таблицы

1. **oracle_sources** - источники данных (оракулы)
2. **crypto_assets** - криптовалютные активы
3. **price_feeds** - данные о ценах от оракулов
4. **l2_network_prices** - данные о L2 сетях
5. **oracle_feed_history** - исторические данные
6. **price_aggregations** - агрегированные цены
7. **oracle_performance** - метрики производительности оракулов

### Представления (Views)

- **current_prices** - текущие цены
- **l2_network_overview** - обзор L2 сетей
- **latest_prices** - последние цены от каждого оракула
- **price_comparison** - сравнение цен между оракулами

## Установка и запуск

### Предварительные требования

- Python 3.11+
- PostgreSQL 12+
- Redis 6+
- Kafka 2.8+
- Docker (опционально)

### Быстрый старт

1. **Клонируйте репозиторий:**
```bash
git clone <repository-url>
cd defimon.highfunk.uk
```

2. **Настройте переменные окружения:**
```bash
cp env.example .env
# Отредактируйте .env файл с вашими настройками
```

3. **Запустите систему:**
```bash
chmod +x scripts/start_price_oracle_system.sh
./scripts/start_price_oracle_system.sh
```

### Ручная установка

1. **Инициализируйте базу данных:**
```bash
python3 scripts/init_price_oracle_db.py
```

2. **Установите зависимости:**
```bash
# Для Price Oracle Service
pip install -r services/price-oracle-service/requirements.txt

# Для Price API Service
pip install -r services/price-api-service/requirements.txt
```

3. **Запустите сервисы:**
```bash
# Price Oracle Service
cd services/price-oracle-service
python3 main.py

# Price API Service (в другом терминале)
cd services/price-api-service
python3 main.py
```

## Использование API

### Основные эндпоинты

#### Получение текущих цен
```bash
# Все активы
curl http://localhost:8000/prices

# Конкретные активы
curl "http://localhost:8000/prices?symbols=ETH,BTC,MATIC"
```

#### Получение цены конкретного актива
```bash
curl http://localhost:8000/prices/ETH
```

#### Данные L2 сетей
```bash
curl http://localhost:8000/l2-networks
```

#### Агрегированные цены
```bash
curl http://localhost:8000/aggregations
```

#### Исторические данные
```bash
# Последние 24 часа
curl http://localhost:8000/history/ETH

# Последние 48 часов
curl http://localhost:8000/history/ETH?hours=48
```

#### Метрики производительности оракулов
```bash
curl http://localhost:8000/oracles/performance
```

### Примеры ответов

#### Текущие цены
```json
[
  {
    "symbol": "ETH",
    "price_usd": 2456.78,
    "volume_24h_usd": 1234567890.12,
    "market_cap_usd": 295678901234.56,
    "price_change_24h_percent": 2.45,
    "last_updated": "2024-01-15T10:30:00Z",
    "oracle_source": "CoinGecko"
  }
]
```

#### Данные L2 сетей
```json
[
  {
    "network": "Polygon",
    "network_token_symbol": "MATIC",
    "price_usd": 0.85,
    "volume_24h_usd": 123456789.01,
    "market_cap_usd": 8765432109.87,
    "price_change_24h_percent": 1.23,
    "tvl_usd": 1234567890.12,
    "total_transactions_24h": 1234567,
    "avg_gas_price_gwei": 30.5,
    "last_updated": "2024-01-15T10:30:00Z"
  }
]
```

## Мониторинг

### Prometheus метрики

- **Price Oracle Service:** http://localhost:8081/metrics
- **Price API Service:** http://localhost:8082/metrics

### Основные метрики

- `oracle_requests_total` - общее количество запросов к оракулам
- `oracle_errors_total` - количество ошибок оракулов
- `oracle_response_time_seconds` - время отклика оракулов
- `price_updates_total` - количество обновлений цен
- `api_requests_total` - количество API запросов

### Логи

- **Price Oracle Service:** `logs/price_oracle_service.log`
- **Price API Service:** `logs/price_api_service.log`

## Конфигурация

### Переменные окружения

```bash
# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=defimon

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Kafka
KAFKA_BOOTSTRAP_SERVERS=localhost:9092

# API Keys (опционально)
COINGECKO_API_KEY=your_key
COINMARKETCAP_API_KEY=your_key
```

### Настройка оракулов

Оракулы можно настроить в файле `services/price-oracle-service/main.py`:

```python
def _load_oracles(self) -> Dict[str, OracleConfig]:
    return {
        'coingecko': OracleConfig(
            name='CoinGecko',
            endpoint='https://api.coingecko.com/api/v3',
            rate_limit_per_minute=50,
            timeout=30
        ),
        # Добавьте другие оракулы
    }
```

## Добавление новых активов

1. **Добавьте актив в базу данных:**
```sql
INSERT INTO crypto_assets (symbol, name, coingecko_id, network, decimals)
VALUES ('NEW', 'New Token', 'new-token', 'ethereum', 18);
```

2. **Обновите конфигурацию в сервисе:**
```python
def _load_assets(self) -> List[Dict]:
    return [
        # ... существующие активы
        {'symbol': 'NEW', 'coingecko_id': 'new-token', 'network': 'ethereum'},
    ]
```

## Добавление новых оракулов

1. **Добавьте оракул в базу данных:**
```sql
INSERT INTO oracle_sources (name, description, endpoint_url, api_key_required, rate_limit_per_minute)
VALUES ('NewOracle', 'New Oracle Description', 'https://api.neworacle.com', false, 60);
```

2. **Реализуйте метод получения данных:**
```python
async def _fetch_neworacle_data(self, oracle_config: OracleConfig, asset: Dict) -> Optional[PriceData]:
    # Реализация получения данных
    pass
```

3. **Добавьте в конфигурацию:**
```python
def _load_oracles(self) -> Dict[str, OracleConfig]:
    return {
        # ... существующие оракулы
        'neworacle': OracleConfig(
            name='NewOracle',
            endpoint='https://api.neworacle.com',
            rate_limit_per_minute=60,
            timeout=30
        ),
    }
```

## Производительность

### Оптимизации базы данных

- Партиционирование таблиц по времени
- Индексы для быстрых запросов
- Материализованные представления для агрегаций

### Кэширование

- Redis для кэширования часто запрашиваемых данных
- Локальное кэширование в сервисах

### Масштабирование

- Горизонтальное масштабирование сервисов
- Репликация базы данных
- Балансировка нагрузки

## Безопасность

### API безопасность

- Rate limiting
- Валидация входных данных
- Логирование запросов

### Данные

- Шифрование чувствительных данных
- Резервное копирование
- Мониторинг целостности данных

## Устранение неполадок

### Частые проблемы

1. **Оракул не отвечает:**
   - Проверьте подключение к интернету
   - Убедитесь, что API ключи корректны
   - Проверьте лимиты запросов

2. **База данных недоступна:**
   - Проверьте подключение к PostgreSQL
   - Убедитесь, что схема создана
   - Проверьте права доступа

3. **API не отвечает:**
   - Проверьте, что сервис запущен
   - Проверьте логи на ошибки
   - Убедитесь, что порт не занят

### Логи и отладка

```bash
# Просмотр логов Oracle Service
tail -f logs/price_oracle_service.log

# Просмотр логов API Service
tail -f logs/price_api_service.log

# Проверка статуса сервисов
curl http://localhost:8000/health
curl http://localhost:8081/metrics
```

## Разработка

### Структура проекта

```
services/
├── price-oracle-service/     # Сервис сбора данных
│   ├── main.py
│   ├── requirements.txt
│   └── Dockerfile
└── price-api-service/        # REST API
    ├── main.py
    ├── requirements.txt
    └── Dockerfile

infrastructure/
├── price_oracle_schema.sql   # Схема базы данных
└── docker-compose.yml        # Docker конфигурация

scripts/
├── init_price_oracle_db.py   # Инициализация БД
└── start_price_oracle_system.sh  # Скрипт запуска
```

### Добавление новых функций

1. Создайте новую ветку для разработки
2. Реализуйте функциональность
3. Добавьте тесты
4. Обновите документацию
5. Создайте pull request

## Лицензия

MIT License

## Поддержка

Для получения поддержки:
- Создайте issue в репозитории
- Обратитесь к документации
- Проверьте логи системы
