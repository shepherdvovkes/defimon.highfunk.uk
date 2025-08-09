# 🌐 Infura Setup Guide for DEFIMON Ethereum Node

## 📋 Обзор

Это руководство описывает настройку Infura для синхронизации Ethereum ноды в ветке `eth_full_node_lenovo`.

## 🎯 Что такое Infura?

Infura - это инфраструктурная платформа, которая предоставляет:
- ✅ Высоконадежный доступ к Ethereum и другим блокчейнам
- ✅ Быстрая синхронизация ноды
- ✅ Поддержка множественных сетей
- ✅ Масштабируемость и отказоустойчивость

## 🚀 Быстрая настройка

### 1. Регистрация на Infura

1. Перейдите на [https://infura.io/](https://infura.io/)
2. Создайте аккаунт
3. Создайте новый проект
4. Скопируйте Project ID

### 2. Настройка .env.infura

```bash
# Скопируйте шаблон
cp env.infura.example .env.infura

# Отредактируйте файл
nano .env.infura
```

Замените в файле:
```bash
INFURA_PROJECT_ID=your-infura-project-id
```
на ваш реальный Project ID:
```bash
INFURA_PROJECT_ID=abc123def456ghi789
```

### 3. Проверка конфигурации

```bash
# Запустите проверку
./scripts/check-infura-config.sh
```

## 🔧 Подробная настройка

### Структура .env.infura

Файл `.env.infura` содержит следующие секции:

#### Infura Project Settings
```bash
INFURA_PROJECT_ID=your-project-id
INFURA_PROJECT_SECRET=your-project-secret
```

#### Ethereum Network Configuration
```bash
ETHEREUM_NETWORK=mainnet
ETHEREUM_NODE_URL=https://mainnet.infura.io/v3/${INFURA_PROJECT_ID}
ETHEREUM_WS_URL=wss://mainnet.infura.io/ws/v3/${INFURA_PROJECT_ID}
```

#### RPC URL Overrides
```bash
RPC_URL_ETHEREUM=https://mainnet.infura.io/v3/${INFURA_PROJECT_ID}
RPC_URL_ARBITRUM_ONE=https://arbitrum-mainnet.infura.io/v3/${INFURA_PROJECT_ID}
RPC_URL_OP_MAINNET=https://optimism-mainnet.infura.io/v3/${INFURA_PROJECT_ID}
# ... и другие сети
```

## 🌐 Поддерживаемые сети

### Основные сети
- ✅ **Ethereum Mainnet** - Основная сеть Ethereum
- ✅ **Arbitrum One** - L2 решение для масштабирования
- ✅ **Optimism** - L2 решение с оптимистичными роллапами
- ✅ **Polygon** - L2 решение с сайдчейнами
- ✅ **Avalanche C-Chain** - EVM-совместимая сеть
- ✅ **Linea** - L2 решение от ConsenSys

### Тестовые сети
- ✅ **Goerli** - Тестовая сеть Ethereum
- ✅ **Sepolia** - Новая тестовая сеть Ethereum

## 🔍 Проверка подключения

### Автоматическая проверка
```bash
./scripts/check-infura-config.sh
```

### Ручная проверка
```bash
# Проверка Ethereum Mainnet
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  https://mainnet.infura.io/v3/YOUR_PROJECT_ID

# Проверка Arbitrum One
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  https://arbitrum-mainnet.infura.io/v3/YOUR_PROJECT_ID
```

## ⚠️ Ограничения и лимиты

### Бесплатный план
- 100,000 запросов в день
- 25 запросов в секунду
- Поддержка основных сетей

### Платные планы
- Увеличенные лимиты
- Приоритетная поддержка
- Дополнительные сети

## 🔒 Безопасность

### Рекомендации
1. **Не публикуйте Project ID** в публичных репозиториях
2. **Используйте .gitignore** для файлов с ключами
3. **Регулярно ротируйте ключи**
4. **Мониторьте использование** через Infura Dashboard

### .gitignore настройка
```bash
# Добавьте в .gitignore
.env.infura
secrets.env
```

## 🛠️ Устранение неполадок

### Ошибка "Project ID not found"
```bash
# Проверьте правильность Project ID
grep INFURA_PROJECT_ID .env.infura

# Убедитесь, что файл существует
ls -la .env.infura
```

### Ошибка "Rate limit exceeded"
- Проверьте лимиты в Infura Dashboard
- Рассмотрите переход на платный план
- Оптимизируйте количество запросов

### Ошибка "Network not supported"
- Проверьте список поддерживаемых сетей
- Убедитесь, что используете правильные URL

## 📊 Мониторинг

### Infura Dashboard
- Отслеживание использования
- Статистика запросов
- Алерты и уведомления

### Локальный мониторинг
```bash
# Проверка статуса ноды
sudo /opt/defimon/manage-node.sh status

# Просмотр логов
sudo /opt/defimon/manage-node.sh logs
```

## 🔄 Обновление конфигурации

### Изменение Project ID
```bash
# Отредактируйте файл
nano .env.infura

# Перезапустите ноду
sudo /opt/defimon/manage-node.sh restart
```

### Добавление новых сетей
```bash
# Добавьте новые RPC_URL в .env.infura
RPC_URL_NEW_NETWORK=https://new-network.infura.io/v3/${INFURA_PROJECT_ID}

# Обновите список сетей
EVM_NETWORKS=ethereum,arbitrum_one,...,new_network
```

## 📚 Дополнительные ресурсы

- [Infura Documentation](https://docs.infura.io/)
- [Ethereum JSON-RPC API](https://ethereum.org/en/developers/docs/apis/json-rpc/)
- [DEFIMON Node Setup](README_ETH_NODE_LENOVO.md)

## 🎉 Готово!

После настройки Infura ваша нода будет:
- ✅ Быстро синхронизироваться с сетью
- ✅ Поддерживать множественные сети
- ✅ Обеспечивать высокую доступность
- ✅ Готова к работе с DEFIMON

---

**Примечание**: Эта конфигурация оптимизирована для ветки `eth_full_node_lenovo` и обеспечивает максимальную производительность при работе с Infura.
