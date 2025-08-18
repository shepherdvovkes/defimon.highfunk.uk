# Chainlist API Integration Guide

## Обзор

Инструмент L2 Networks Sync теперь интегрирован с официальным Chainlist API от Ethereum Foundation. Это обеспечивает:

- 🚀 **Автоматическое обнаружение** новых L2 сетей
- 📊 **Актуальные данные** о существующих сетях
- 🔄 **Регулярную синхронизацию** с официальным источником
- 🌐 **Поддержку тестовых сетей** (Goerli, Sepolia, Mumbai)

## Преимущества Chainlist API

### По сравнению с DefiLlama:
- ✅ **Официальный источник** от Ethereum Foundation
- ✅ **Быстрее** - оптимизированные эндпоинты
- ✅ **Надежнее** - стабильная инфраструктура
- ✅ **Актуальнее** - регулярные обновления
- ✅ **Стандартизированный** формат данных

### Поддерживаемые типы сетей:
- **L2 Rollups**: Optimistic (Arbitrum, Optimism, Base) и ZK (zkSync, Scroll, Linea)
- **Sidechains**: Polygon, BSC, Fantom, Avalanche C-Chain
- **Testnets**: Goerli, Sepolia, Mumbai, Fuji
- **EVM-совместимые**: Gnosis Chain, Celo, Harmony

## Быстрый старт

### 1. Установка зависимостей
```bash
cd tools/l2-networks-sync
npm install
```

### 2. Настройка окружения
```bash
cp env.example .env
```

Добавьте настройки Chainlist API:
```bash
# Chainlist API Configuration
CHAINLIST_TIMEOUT_MS=30000
CHAINLIST_RETRY_ATTEMPTS=3
CHAINLIST_ENABLE_CACHING=true
CHAINLIST_CACHE_TTL_MS=3600000
```

### 3. Тестирование интеграции
```bash
npm run test:chainlist
```

### 4. Запуск синхронизации
```bash
npm run sync
```

## API Endpoints

### Основные эндпоинты:
- **Mainnet**: `https://chainlist.org/api/v1/mainnet`
- **Testnet**: `https://chainlist.org/api/v1/testnet`
- **All Networks**: `https://chainlist.org/api/v1`

### Пример ответа:
```json
{
  "name": "Arbitrum One",
  "chainId": 42161,
  "rpc": ["https://arb1.arbitrum.io/rpc"],
  "explorers": [{"url": "https://arbiscan.io"}],
  "nativeCurrency": {"symbol": "ETH"},
  "features": ["eip1559"],
  "status": "active"
}
```

## Конфигурация

### Базовые настройки
```javascript
// chainlist-config.js
export const chainlistConfig = {
  api: {
    timeout: 30000,
    retryAttempts: 3
  },
  filtering: {
    priorityNetworks: [1, 137, 56, 42161, 10, 8453],
    l2Keywords: ['rollup', 'layer 2', 'l2', 'optimistic', 'zk']
  }
};
```

### Переменные окружения
```bash
# Таймаут API запросов (мс)
CHAINLIST_TIMEOUT_MS=30000

# Количество попыток повтора
CHAINLIST_RETRY_ATTEMPTS=3

# Включить кэширование
CHAINLIST_ENABLE_CACHING=true

# Время жизни кэша (мс)
CHAINLIST_CACHE_TTL_MS=3600000
```

## Фильтрация сетей

### Автоматическая фильтрация:
1. **Проверка обязательных полей**: chainId, name, rpc
2. **Определение типа сети**: L1/L2 по ключевым словам
3. **Приоритизация**: важные сети включаются автоматически
4. **Исключение**: нежелательные сети отфильтровываются

### Ключевые слова для L2:
- `rollup` - Rollup решения
- `layer 2` / `l2` - Слои второго уровня
- `optimistic` - Оптимистичные rollups
- `zk` - Zero-knowledge rollups
- `polygon`, `arbitrum`, `optimism` - Известные L2

## Обработка данных

### Преобразование формата:
```javascript
// Входные данные Chainlist API
{
  "chainId": "42161",
  "name": "Arbitrum One",
  "rpc": ["https://arb1.arbitrum.io/rpc"]
}

// Выходные данные инструмента
{
  "chain_id": 42161,
  "name": "Arbitrum One",
  "network_type": "L2",
  "rpc_url": "https://arb1.arbitrum.io/rpc",
  "metadata": {
    "rollup_type": "optimistic",
    "source": "chainlist_api"
  }
}
```

### Метаданные:
- `rollup_type`: optimistic/zk/unknown
- `data_availability`: ethereum/local
- `fraud_proof`: true/false
- `chainlist_id`: оригинальный ID из API
- `features`: список функций сети

## Мониторинг и логирование

### Уровни логирования:
```bash
LOG_LEVEL=debug  # Подробная информация
LOG_LEVEL=info   # Основная информация
LOG_LEVEL=warn   # Только предупреждения
LOG_LEVEL=error  # Только ошибки
```

### Примеры логов:
```
📡 Fetching networks from Ethereum Foundation Chainlist API...
✅ Found 150 mainnet networks and 45 testnet networks from Chainlist API
🔍 Processing 195 networks...
✅ Processed 89 valid L2 networks from Chainlist API
```

## Обработка ошибок

### Типичные ошибки:
1. **Сетевые проблемы**: таймауты, недоступность API
2. **Ошибки API**: неверные ответы, ограничения rate limit
3. **Ошибки данных**: некорректный формат, отсутствующие поля

### Стратегии восстановления:
- Автоматические повторы с экспоненциальной задержкой
- Fallback на статические данные при недоступности API
- Логирование ошибок для диагностики

## Производительность

### Оптимизации:
- **Параллельные запросы** к mainnet и testnet API
- **Кэширование** результатов для снижения нагрузки
- **Фильтрация** на стороне клиента
- **Batch processing** для больших объемов данных

### Метрики:
- Время ответа API: < 2 секунд
- Обработка 1000 сетей: < 30 секунд
- Использование памяти: < 100MB
- CPU нагрузка: < 10%

## Автоматизация

### Cron задачи:
```bash
# Синхронизация каждые 6 часов
0 */6 * * * cd /path/to/l2-networks-sync && npm run sync

# Ежедневная синхронизация в 2:00
0 2 * * * cd /path/to/l2-networks-sync && npm run sync
```

### Docker:
```yaml
# docker-compose.yml
services:
  l2-sync:
    build: .
    environment:
      - CHAINLIST_TIMEOUT_MS=30000
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped
```

## Устранение неполадок

### Проблема: API недоступен
```bash
# Проверка доступности
curl -I https://chainlist.org/api/v1/mainnet

# Проверка DNS
nslookup chainlist.org

# Проверка firewall
telnet chainlist.org 443
```

### Проблема: Медленные ответы
```bash
# Увеличьте таймаут
CHAINLIST_TIMEOUT_MS=60000

# Проверьте сетевую задержку
ping chainlist.org
```

### Проблема: Ошибки аутентификации
```bash
# Проверьте User-Agent
# Инструмент автоматически устанавливает корректный User-Agent
```

## Обновления и поддержка

### Регулярные обновления:
- API эндпоинты обновляются автоматически
- Новые сети добавляются без изменения кода
- Улучшения производительности через обновления зависимостей

### Поддержка:
- Документация обновляется при изменениях
- Примеры конфигурации для новых функций
- Обратная совместимость API

## Заключение

Интеграция с Chainlist API значительно улучшает возможности инструмента L2 Networks Sync:

- 🌟 **Автоматическое обнаружение** новых сетей
- 🚀 **Повышенная производительность** и надежность
- 🔄 **Актуальные данные** от официального источника
- 🛠️ **Простая настройка** и конфигурация

Инструмент теперь является полноценным решением для мониторинга и синхронизации Ethereum-совместимых сетей с использованием лучших доступных источников данных.
