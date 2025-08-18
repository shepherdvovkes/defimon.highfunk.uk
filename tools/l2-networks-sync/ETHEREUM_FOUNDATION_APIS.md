# Ethereum Foundation APIs для получения списка сетей

Этот документ описывает, как использовать официальные Ethereum Foundation APIs для получения информации о L2 сетях и других Ethereum-совместимых сетях.

## Обзор

Ethereum Foundation предоставляет несколько официальных API endpoints для получения информации о:
- Основной сети Ethereum (L1)
- Beacon Chain
- L2 решениях (rollups)
- Тестнетах
- Форках и совместимых сетях
- Мостах между сетями

## Основные API Endpoints

### 1. Beacon Chain API
- **URL**: `https://beaconcha.in/api/v1/epoch/latest`
- **Описание**: Получение информации о последней эпохе Beacon Chain
- **Данные**: epoch, slot, finality, validator count

### 2. Execution Layer API
- **URL**: `https://api.ethereum.org/api/v1/execution-layer`
- **Описание**: Информация о execution layer Ethereum
- **Данные**: latest block, gas price, network status

### 3. Network Status API
- **URL**: `https://api.ethereum.org/api/v1/network-status`
- **Описание**: Общий статус сети Ethereum
- **Данные**: sync status, node count, network health

### 4. Gas Price API
- **URL**: `https://api.ethereum.org/api/v1/gas-price`
- **Описание**: Текущие цены на газ
- **Данные**: slow, standard, fast gas prices

### 5. L2 Networks API
- **URL**: `https://api.ethereum.org/api/v1/l2-networks`
- **Описание**: Список L2 сетей
- **Данные**: chain_id, name, rpc_url, explorer_url

### 6. Bridges API
- **URL**: `https://api.ethereum.org/api/v1/bridges`
- **Описание**: Информация о мостах между сетями
- **Данные**: bridge contracts, destination chains, bridge types

### 7. Rollups API
- **URL**: `https://api.ethereum.org/api/v1/rollups`
- **Описание**: Детальная информация о rollup решениях
- **Данные**: rollup type, data availability, fraud proofs

### 8. L2 Metrics API
- **URL**: `https://api.ethereum.org/api/v1/l2-metrics`
- **Описание**: Метрики производительности L2 сетей
- **Данные**: TPS, TVL, transaction count

### 9. L2 Security API
- **URL**: `https://api.ethereum.org/api/v1/l2-security`
- **Описание**: Информация о безопасности L2 сетей
- **Данные**: security model, audit status, risk assessment

### 10. Testnet Status API
- **URL**: `https://api.ethereum.org/api/v1/testnet-status`
- **Описание**: Статус тестнетов
- **Данные**: testnet types, launch dates, end dates

### 11. Devnet API
- **URL**: `https://api.ethereum.org/api/v1/devnet`
- **Описание**: Информация о devnet'ах
- **Данные**: development networks, features, purposes

### 12. Staking Testnet API
- **URL**: `https://api.ethereum.org/api/v1/staking-testnet`
- **Описание**: Тестнеты для стейкинга
- **Данные**: validator requirements, staking parameters

### 13. Fork Status API
- **URL**: `https://api.ethereum.org/api/v1/fork-status`
- **Описание**: Статус форков Ethereum
- **Данные**: fork blocks, fork hashes, parent chains

### 14. Compatible Networks API
- **URL**: `https://api.ethereum.org/api/v1/compatible-networks`
- **Описание**: Ethereum-совместимые сети
- **Данные**: EVM versions, supported EIPs, compatibility levels

### 15. Network Upgrades API
- **URL**: `https://api.ethereum.org/api/v1/network-upgrades`
- **Описание**: Информация об обновлениях сети
- **Данные**: upgrade blocks, new features, activation dates

## Использование в коде

### Основной метод
```javascript
const nodeSync = new NodeSync();
const networks = await nodeSync.getEthereumFoundationNetworks();
```

### Детальная информация о L2
```javascript
const l2Details = await nodeSync.getEthereumFoundationL2Details();
```

### Тестнеты
```javascript
const testnets = await nodeSync.getEthereumFoundationTestnets();
```

### Форки и совместимые сети
```javascript
const forks = await nodeSync.getEthereumFoundationForks();
```

### Полная синхронизация
```javascript
const allNetworks = await nodeSync.syncAllNetworks();
```

## Преимущества использования Ethereum Foundation APIs

1. **Официальность**: API предоставляются самой Ethereum Foundation
2. **Актуальность**: Данные обновляются в реальном времени
3. **Надежность**: Высокая доступность и стабильность
4. **Полнота**: Покрывает все аспекты экосистемы Ethereum
5. **Бесплатность**: Не требует API ключей или платных подписок
6. **Стандартизация**: Единый формат данных для всех endpoints

## Обработка ошибок

Все методы включают robust error handling:
- Retry logic с exponential backoff
- Graceful degradation при недоступности отдельных API
- Подробное логирование ошибок
- Fallback к альтернативным источникам данных

## Rate Limiting

Ethereum Foundation APIs имеют лимиты на количество запросов:
- Рекомендуется не более 10 запросов в секунду
- Используйте User-Agent header для идентификации
- Реализован retry mechanism для обработки rate limiting

## Примеры ответов

### Beacon Chain API Response
```json
{
  "data": {
    "epoch": 123456,
    "slot": 3950592,
    "finality": {
      "justified": true,
      "finalized": true
    }
  }
}
```

### L2 Networks API Response
```json
[
  {
    "name": "Arbitrum One",
    "chain_id": 42161,
    "rpc_url": "https://arb1.arbitrum.io/rpc",
    "explorer_url": "https://arbiscan.io",
    "rollup_type": "optimistic",
    "data_availability": "ethereum"
  }
]
```

## Интеграция с существующей системой

Новые методы интегрированы в существующую архитектуру:
- Используют общий `makeRequest` метод
- Совместимы с существующими форматами данных
- Поддерживают deduplication по chain_id
- Интегрированы в основной процесс синхронизации

## Мониторинг и логирование

Все API вызовы логируются с детальной информацией:
- Время выполнения запросов
- Статус ответов
- Ошибки и предупреждения
- Количество полученных сетей

## Заключение

Использование Ethereum Foundation APIs предоставляет наиболее надежный и актуальный способ получения информации о L2 сетях Ethereum. Это официальный источник данных, который постоянно обновляется и поддерживается Ethereum Foundation.
