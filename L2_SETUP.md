# L2 Networks Setup Guide

## Обзор

Этот документ описывает настройку и использование системы мониторинга L2 сетей в DEFIMON. Система поддерживает более 50 популярных L2 решений и протоколов.

## Поддерживаемые L2 Сети

### Top Tier Networks (Priority 9-10)
- **Optimism** - Optimistic Rollup, $850M TVL
- **Arbitrum One** - Optimistic Rollup, $2.1B TVL  
- **Polygon zkEVM** - ZK Rollup, $45M TVL
- **Base** - Optimistic Rollup, $750M TVL
- **zkSync Era** - ZK Rollup, $650M TVL
- **Polygon PoS** - Sidechain, $850M TVL
- **BSC** - Sidechain, $5.2B TVL

### Emerging ZK Rollups (Priority 8)
- **StarkNet** - ZK Rollup, $180M TVL
- **Linea** - ZK Rollup, $120M TVL
- **Scroll** - ZK Rollup, $85M TVL
- **Avalanche** - Sidechain, $1.1B TVL

### Optimistic Rollups (Priority 5-7)
- **Mantle** - Optimistic Rollup, $45M TVL
- **Metis** - Optimistic Rollup, $35M TVL
- **Boba Network** - Optimistic Rollup, $15M TVL
- **Arbitrum Nova** - Optimistic Rollup, $15M TVL

### Gaming & NFT Focused (Priority 6-7)
- **Immutable X** - Validium, $25M TVL
- **Loopring** - ZK Rollup, $120M TVL
- **Ronin** - Sidechain, $25M TVL

### Additional Networks (Priority 4-6)
- **Cronos** - Sidechain, $180M TVL
- **Harmony** - Sidechain, $15M TVL
- **Celo** - Sidechain, $45M TVL
- **Gnosis Chain** - Sidechain, $35M TVL
- **Klaytn** - Sidechain, $25M TVL
- **NEAR** - Sidechain, $15M TVL
- **Solana** - L1, $1.2B TVL

## Конфигурация

### Переменные окружения

```bash
# Включение L2 синхронизации
L2_SYNC_ENABLED=true

# Список активных сетей (через запятую)
L2_NETWORKS=optimism,arbitrum_one,polygon_zkevm,base,zksync_era,starknet,linea,scroll

# Настройки синхронизации
L2_SYNC_INTERVAL=12          # секунды между синхронизациями
L2_BATCH_SIZE=100            # количество блоков за раз
L2_MAX_CONCURRENT_REQUESTS=10 # максимальное количество параллельных запросов
L2_DATA_RETENTION_DAYS=90    # дни хранения данных
L2_PRIORITY_THRESHOLD=5      # минимальный приоритет для синхронизации
```

### Приоритеты сетей

- **10**: Optimism, Arbitrum One
- **9**: Polygon zkEVM, Base, zkSync Era, Polygon PoS, BSC
- **8**: StarkNet, Linea, Scroll, Avalanche
- **7**: Mantle, Loopring
- **6**: Metis, Immutable X, Ronin, Cronos
- **5**: Boba, Arbitrum Nova, Celo, Gnosis Chain
- **4**: Harmony, Klaytn, NEAR

## Структура данных

### L2 Block Data
```rust
pub struct L2BlockData {
    pub network: String,
    pub chain_id: u64,
    pub number: u64,
    pub hash: H256,
    pub timestamp: u64,
    pub transactions: Vec<L2TransactionData>,
    pub logs: Vec<L2LogData>,
    pub l2_specific_data: L2SpecificData,
}
```

### L2 Specific Data
```rust
pub struct L2SpecificData {
    pub l1_batch_submissions: u64,
    pub l1_batch_size: u64,
    pub finality_time: u64, // seconds
    pub gas_fees_l2: U256,
    pub gas_fees_l1: Option<U256>,
    pub sequencer_fees: Option<U256>,
    pub compression_ratio: Option<f64>,
    pub proof_generation_time: Option<u64>,
}
```

## Запуск

### 1. Подготовка базы данных

```bash
# Применение схемы L2
psql -h localhost -U postgres -d defi_analytics -f infrastructure/l2_schema.sql
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

## Мониторинг

### Метрики L2 сетей

- **Blocks Processed**: Количество обработанных блоков
- **Transactions Processed**: Количество обработанных транзакций
- **Sync Speed**: Скорость синхронизации (блоков/сек)
- **Error Rate**: Частота ошибок синхронизации
- **Gas Fees**: Средние комиссии L1/L2
- **Finality Time**: Время финализации
- **Compression Ratio**: Коэффициент сжатия данных

### Grafana Dashboard

Доступен по адресу: http://localhost:3001
- Логин: admin
- Пароль: admin

### API Endpoints

```bash
# Статистика по сети
GET /api/v1/l2/networks/{network}/stats

# Последние блоки
GET /api/v1/l2/networks/{network}/blocks

# Транзакции
GET /api/v1/l2/networks/{network}/transactions

# Протоколы
GET /api/v1/l2/networks/{network}/protocols
```

## Производительность

### Рекомендуемые настройки

Для высоконагруженной системы:

```bash
# Увеличить количество параллельных запросов
L2_MAX_CONCURRENT_REQUESTS=20

# Уменьшить интервал синхронизации
L2_SYNC_INTERVAL=6

# Увеличить размер батча
L2_BATCH_SIZE=200
```

### Мониторинг ресурсов

```bash
# Использование CPU
docker stats blockchain-node

# Использование памяти
docker exec blockchain-node ps aux

# Логи синхронизации
docker-compose logs -f blockchain-node | grep "L2 sync"
```

## Troubleshooting

### Частые проблемы

1. **Ошибки подключения к RPC**
   ```bash
   # Проверьте доступность RPC
   curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
     https://mainnet.optimism.io
   ```

2. **Медленная синхронизация**
   ```bash
   # Увеличьте количество параллельных запросов
   L2_MAX_CONCURRENT_REQUESTS=15
   ```

3. **Высокое потребление памяти**
   ```bash
   # Уменьшите размер батча
   L2_BATCH_SIZE=50
   ```

### Логи

```bash
# Просмотр логов L2 синхронизации
docker-compose logs blockchain-node | grep "L2"

# Просмотр ошибок
docker-compose logs blockchain-node | grep "ERROR"

# Статистика синхронизации
docker-compose logs blockchain-node | grep "processed"
```

## Расширение

### Добавление новой L2 сети

1. Добавьте конфигурацию в `l2_networks.rs`:
```rust
networks.insert("new_network".to_string(), L2Network {
    name: "New Network".to_string(),
    chain_id: 12345,
    rpc_url: "https://rpc.new-network.com".to_string(),
    // ... остальные поля
});
```

2. Добавьте сеть в переменную окружения:
```bash
L2_NETWORKS=optimism,arbitrum_one,new_network
```

3. Перезапустите сервис:
```bash
docker-compose restart blockchain-node
```

### Кастомные протоколы

Для добавления поддержки новых протоколов:

1. Создайте новый модуль в `protocols.rs`
2. Добавьте логику обработки в `process_l2_block`
3. Обновите схему базы данных при необходимости

## Безопасность

### Рекомендации

1. **Ограничение доступа к RPC**
   - Используйте приватные RPC endpoints
   - Настройте rate limiting
   - Мониторьте использование API

2. **Защита базы данных**
   - Используйте сильные пароли
   - Ограничьте доступ к базе данных
   - Регулярно делайте бэкапы

3. **Мониторинг безопасности**
   - Логируйте все API запросы
   - Мониторьте аномальную активность
   - Регулярно обновляйте зависимости

## Поддержка

Для получения поддержки:

1. Проверьте документацию
2. Просмотрите логи ошибок
3. Создайте issue в репозитории
4. Обратитесь к команде разработки

## Лицензия

MIT License - см. файл LICENSE для деталей.
