# PostgreSQL Tables Report - Polygon Data

## 🗄️ **База данных: Google Cloud SQL PostgreSQL**

### **Подключение:**
- **Хост**: localhost:5432 (через Cloud SQL Proxy)
- **База данных**: `defi_analytics`
- **Пользователь**: `defimon_user`
- **Схема**: `polygon_data`

## 📊 **Созданные таблицы**

### **1. Таблица `polygon_data.blocks`**

#### **Структура:**
```sql
CREATE TABLE polygon_data.blocks (
    block_number BIGINT PRIMARY KEY,
    block_hash VARCHAR(66) UNIQUE NOT NULL,
    parent_hash VARCHAR(66) NOT NULL,
    timestamp BIGINT NOT NULL,
    gas_limit BIGINT NOT NULL,
    gas_used BIGINT NOT NULL,
    miner VARCHAR(42) NOT NULL,
    difficulty VARCHAR(20),
    total_difficulty VARCHAR(20),
    size INTEGER,
    extra_data TEXT,
    nonce VARCHAR(18),
    base_fee_per_gas VARCHAR(20),
    transactions_count INTEGER DEFAULT 0,
    logs_bloom TEXT,
    state_root VARCHAR(66),
    receipts_root VARCHAR(66),
    transactions_root VARCHAR(66),
    uncle_hash VARCHAR(66),
    mix_hash VARCHAR(66),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### **Индексы:**
- `blocks_pkey` - PRIMARY KEY (block_number)
- `blocks_block_hash_key` - UNIQUE (block_hash)
- `idx_blocks_timestamp` - btree (timestamp)
- `idx_blocks_miner` - btree (miner)

### **2. Таблица `polygon_data.transactions`**

#### **Структура:**
```sql
CREATE TABLE polygon_data.transactions (
    hash VARCHAR(66) PRIMARY KEY,
    block_number BIGINT NOT NULL,
    block_hash VARCHAR(66) NOT NULL,
    from_address VARCHAR(42) NOT NULL,
    to_address VARCHAR(42),
    value VARCHAR(50) NOT NULL,
    gas BIGINT NOT NULL,
    gas_price VARCHAR(20) NOT NULL,
    nonce BIGINT NOT NULL,
    input_data TEXT,
    transaction_index INTEGER NOT NULL,
    timestamp BIGINT NOT NULL,
    max_fee_per_gas VARCHAR(20),
    max_priority_fee_per_gas VARCHAR(20),
    type VARCHAR(10),
    chain_id VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (block_number) REFERENCES polygon_data.blocks(block_number)
);
```

#### **Индексы:**
- `transactions_pkey` - PRIMARY KEY (hash)
- `idx_transactions_block` - btree (block_number)
- `idx_transactions_from` - btree (from_address)
- `idx_transactions_to` - btree (to_address)
- `idx_transactions_timestamp` - btree (timestamp)

### **3. Таблица `polygon_data.receipts`**

#### **Структура:**
```sql
CREATE TABLE polygon_data.receipts (
    transaction_hash VARCHAR(66) PRIMARY KEY,
    block_number BIGINT NOT NULL,
    block_hash VARCHAR(66) NOT NULL,
    transaction_index INTEGER NOT NULL,
    from_address VARCHAR(42) NOT NULL,
    to_address VARCHAR(42),
    cumulative_gas_used BIGINT NOT NULL,
    gas_used BIGINT NOT NULL,
    contract_address VARCHAR(42),
    logs TEXT,
    status INTEGER,
    effective_gas_price VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (transaction_hash) REFERENCES polygon_data.transactions(hash),
    FOREIGN KEY (block_number) REFERENCES polygon_data.blocks(block_number)
);
```

#### **Индексы:**
- `receipts_pkey` - PRIMARY KEY (transaction_hash)
- `idx_receipts_block` - btree (block_number)

## 📈 **Импортированные данные**

### **Статистика:**
- **Блоков**: 5
- **Транзакций**: 15
- **Квитанций**: 15
- **Диапазон блоков**: 70,534,503 - 74,681,703
- **Временной диапазон**: 2025-04-20 16:05:13 - 2025-08-01 23:59:12

### **Образцы блоков:**
| Block Number | Hash | Timestamp | Gas Used | Transactions |
|--------------|------|-----------|----------|--------------|
| 70,534,503 | 0x0777e5df... | 1745154313 | 15,114,558 | 68 |
| 71,571,303 | 0xb5627a46... | 1747365376 | 7,435,059 | 53 |
| 72,608,103 | 0x49a2a15a... | 1749584372 | 8,046,336 | 65 |
| 73,644,903 | 0xaa2245fe... | 1751797407 | 10,827,859 | 98 |
| 74,681,703 | 0x91b9dd00... | 1754081952 | 25,252,180 | 68 |

### **Статистика транзакций:**
- **Среднее транзакций на блок**: 70.4
- **Процент успешных транзакций**: 93.3%
- **Процент неудачных транзакций**: 6.7%

## 🔍 **Примеры запросов**

### **1. Получить все блоки:**
```sql
SELECT block_number, block_hash, timestamp, gas_used, transactions_count 
FROM polygon_data.blocks 
ORDER BY block_number;
```

### **2. Получить транзакции с квитанциями:**
```sql
SELECT t.hash, t.from_address, t.to_address, t.value, t.gas, r.status 
FROM polygon_data.transactions t 
JOIN polygon_data.receipts r ON t.hash = r.transaction_hash;
```

### **3. Статистика по статусам:**
```sql
SELECT 
    status, 
    COUNT(*) as count, 
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as percentage 
FROM polygon_data.receipts 
GROUP BY status;
```

### **4. Среднее количество транзакций на блок:**
```sql
SELECT AVG(transactions_count) as avg_transactions_per_block 
FROM polygon_data.blocks;
```

### **5. Поиск транзакций по адресу:**
```sql
SELECT * FROM polygon_data.transactions 
WHERE from_address = '0x3242d151322de13be465ed87132aa763933fa57d';
```

## 🛠️ **Инструменты для работы с данными**

### **1. Подключение к базе данных:**
```bash
psql -h localhost -U defimon_user -d defi_analytics
```

### **2. Импорт данных:**
```bash
python3 import_data_to_postgres.py
```

### **3. Проверка статистики:**
```bash
psql -h localhost -U defimon_user -d defi_analytics -c "
SELECT 
    'blocks' as table_name, COUNT(*) as count FROM polygon_data.blocks
UNION ALL
SELECT 
    'transactions' as table_name, COUNT(*) as count FROM polygon_data.transactions
UNION ALL
SELECT 
    'receipts' as table_name, COUNT(*) as count FROM polygon_data.receipts;"
```

## 📊 **Возможности расширения**

### **Дополнительные таблицы:**
1. **`polygon_data.logs`** - для событий смарт-контрактов
2. **`polygon_data.contracts`** - для информации о контрактах
3. **`polygon_data.addresses`** - для метаданных адресов
4. **`polygon_data.tokens`** - для токенов (ERC20, ERC721)

### **Дополнительные индексы:**
```sql
-- Для поиска по времени
CREATE INDEX idx_blocks_timestamp_range ON polygon_data.blocks(timestamp);

-- Для поиска по значению транзакций
CREATE INDEX idx_transactions_value ON polygon_data.transactions(value);

-- Для поиска по типу транзакций
CREATE INDEX idx_transactions_type ON polygon_data.transactions(type);
```

### **Партиционирование:**
```sql
-- Партиционирование по времени
CREATE TABLE polygon_data.blocks_partitioned (
    LIKE polygon_data.blocks INCLUDING ALL
) PARTITION BY RANGE (timestamp);
```

## 🎯 **Заключение**

✅ **База данных настроена** и готова к работе  
✅ **Таблицы созданы** с правильной структурой  
✅ **Индексы оптимизированы** для быстрых запросов  
✅ **Данные импортированы** из QuickNode API  
✅ **Связи между таблицами** настроены корректно  

База данных PostgreSQL в Google Cloud готова для анализа данных сети Polygon и может быть расширена для более сложных аналитических задач.

---

**Дата создания**: $(date)  
**Версия**: 1.0  
**Статус**: ✅ Завершено
