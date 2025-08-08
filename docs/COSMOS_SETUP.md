# Cosmos Networks Setup Guide

## Обзор

Этот документ описывает настройку и использование системы мониторинга Cosmos сетей в DEFIMON. Система поддерживает основные Cosmos Hub и популярные зоны экосистемы Cosmos.

## Поддерживаемые Cosmos Сети

### Top Tier Networks (Priority 9-10)
- **Cosmos Hub** - Основная сеть экосистемы Cosmos, $2.8B TVL
- **Osmosis** - DEX и ликвидность, $180M TVL
- **Injective** - Децентрализованная биржа, $45M TVL

### Emerging Networks (Priority 7-8)
- **Celestia** - Data availability layer, $120M TVL
- **Sei Network** - Специализированная DEX, $85M TVL
- **Neutron** - Interchain DeFi, $65M TVL
- **Evmos** - EVM-совместимая зона, $45M TVL

### Liquid Staking & DeFi (Priority 6-7)
- **Stride** - Liquid staking, $35M TVL
- **Quicksilver** - Liquid staking, $25M TVL
- **Persistence** - Liquid staking, $20M TVL

### Additional Networks (Priority 5-6)
- **Agoric** - Smart contracts, $15M TVL
- **Kava** - Lending & DeFi, $25M TVL

## Конфигурация

### Переменные окружения

```bash
# Включение Cosmos синхронизации
COSMOS_SYNC_ENABLED=true

# Список активных сетей (через запятую)
COSMOS_NETWORKS=cosmos_hub,osmosis,injective,celestia,sei,neutron,stride,quicksilver,persistence,agoric,evmos,kava

# Настройки синхронизации
COSMOS_SYNC_INTERVAL=15          # секунды между синхронизациями
COSMOS_BATCH_SIZE=50              # количество блоков за раз
COSMOS_MAX_CONCURRENT_REQUESTS=8  # максимальное количество параллельных запросов
COSMOS_DATA_RETENTION_DAYS=90     # дни хранения данных
COSMOS_PRIORITY_THRESHOLD=5       # минимальный приоритет для синхронизации
```

### Приоритеты сетей

- **10**: Cosmos Hub
- **9**: Osmosis, Injective
- **8**: Celestia, Sei Network, Neutron, Evmos
- **7**: Stride, Quicksilver, Persistence
- **6**: Agoric, Kava

## Структура данных

### Cosmos Block Data
```rust
pub struct CosmosBlockData {
    pub network: String,
    pub height: u64,
    pub hash: String,
    pub timestamp: DateTime<Utc>,
    pub proposer: String,
    pub transactions: Vec<CosmosTransactionData>,
    pub validators: Vec<CosmosValidatorData>,
    pub inflation_rate: Option<f64>,
    pub bonded_tokens: Option<u64>,
    pub total_supply: Option<u64>,
}
```

### Cosmos Transaction Data
```rust
pub struct CosmosTransactionData {
    pub hash: String,
    pub height: u64,
    pub fee: CosmosFee,
    pub gas_used: u64,
    pub gas_wanted: u64,
    pub memo: Option<String>,
    pub messages: Vec<CosmosMessage>,
    pub result: CosmosTxResult,
}
```

### Cosmos Validator Data
```rust
pub struct CosmosValidatorData {
    pub address: String,
    pub voting_power: u64,
    pub commission_rate: Option<f64>,
    pub jailed: bool,
    pub status: String,
}
```

## Запуск

### 1. Подготовка базы данных

```bash
# Применение схемы Cosmos
psql -h localhost -U postgres -d defi_analytics -f infrastructure/cosmos_schema.sql
```

### 2. Настройка переменных окружения

```bash
cp env.example .env
# Отредактируйте .env файл с вашими настройками
```

### 3. Запуск сервисов

```bash
# Запуск всех сервисов
docker-compose up -d

# Проверка статуса
docker-compose ps

# Просмотр логов
docker-compose logs -f blockchain-node
```

## API Endpoints

### Cosmos Analytics API

```bash
# Получение статистики сети
GET /api/v1/cosmos/networks/{network}/stats

# Получение блоков
GET /api/v1/cosmos/networks/{network}/blocks?height={height}&limit={limit}

# Получение транзакций
GET /api/v1/cosmos/networks/{network}/transactions?height={height}&limit={limit}

# Получение валидаторов
GET /api/v1/cosmos/networks/{network}/validators

# Получение IBC трансферов
GET /api/v1/cosmos/networks/{network}/ibc-transfers

# Получение governance предложений
GET /api/v1/cosmos/networks/{network}/governance/proposals
```

## Мониторинг

### Prometheus Metrics

- `cosmos_blocks_processed_total` - Общее количество обработанных блоков
- `cosmos_latest_block_height` - Последняя высота блока
- `cosmos_transactions_processed_total` - Общее количество обработанных транзакций
- `cosmos_validators_total` - Общее количество валидаторов
- `cosmos_sync_duration_seconds` - Время синхронизации

### Grafana Dashboards

Создайте дашборд для мониторинга:
- Количество блоков в секунду
- Количество транзакций в секунду
- Статистика валидаторов
- IBC трансферы
- Governance активность

## Особенности Cosmos

### IBC (Inter-Blockchain Communication)

Система отслеживает IBC трансферы между зонами:
- Источник и назначение
- Сумма и деноминация
- Статус трансфера
- Время выполнения

### Staking & Governance

- Отслеживание валидаторов
- Статистика стейкинга
- Governance предложения
- Результаты голосования

### Gas & Fees

- Gas used vs gas wanted
- Fee структура (multiple denoms)
- Средние комиссии
- Статистика по деноминациям

## Troubleshooting

### Частые проблемы

1. **Ошибки RPC подключения**
   ```bash
   # Проверьте доступность RPC endpoints
   curl https://rpc.cosmos.network:26657/status
   ```

2. **Ошибки синхронизации**
   ```bash
   # Проверьте логи
   docker-compose logs blockchain-node | grep cosmos
   ```

3. **Проблемы с базой данных**
   ```bash
   # Проверьте схему
   psql -h localhost -U postgres -d defi_analytics -c "\dt cosmos_*"
   ```

### Логирование

```bash
# Включение debug логов для Cosmos
RUST_LOG=cosmos_sync=debug docker-compose up blockchain-node
```

## Расширение

### Добавление новой Cosmos зоны

1. Добавьте сеть в `CosmosSyncManager::initialize_networks()`
2. Обновите `COSMOS_NETWORKS` в конфигурации
3. Добавьте специфичные для сети обработчики сообщений

### Кастомные обработчики сообщений

```rust
impl CosmosSyncManager {
    fn handle_custom_message(&self, msg: &CosmosMessage) -> Result<(), Box<dyn std::error::Error>> {
        match msg.type_url.as_str() {
            "/cosmos.bank.v1beta1.MsgSend" => self.handle_bank_transfer(msg),
            "/cosmos.staking.v1beta1.MsgDelegate" => self.handle_staking_delegate(msg),
            "/ibc.applications.transfer.v1.MsgTransfer" => self.handle_ibc_transfer(msg),
            _ => Ok(()),
        }
    }
}
```

## Производительность

### Оптимизации

- Batch processing блоков
- Параллельные запросы к RPC
- Кэширование валидаторов
- Индексы базы данных
- Materialized views для статистики

### Мониторинг производительности

```bash
# Проверка скорости синхронизации
SELECT network, blocks_per_second, total_blocks_processed 
FROM cosmos_sync_status;
```

## Безопасность

### RPC Endpoints

- Используйте HTTPS endpoints
- Ротация RPC providers
- Rate limiting
- Retry логика

### Валидация данных

- Проверка хешей блоков
- Валидация транзакций
- Проверка подписей
- Верификация chain ID
