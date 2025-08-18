# L2 Networks Synchronization Tool

Инструмент для синхронизации L2 сетей Ethereum через Beacon Chain API. Этот инструмент собирает информацию о L2 сетях из различных источников и предоставляет единый интерфейс для мониторинга.

## 🚀 Особенности

- **Beacon Chain Integration**: Подключение к Ethereum Beacon Chain для получения L1 информации
- **L2 Networks Discovery**: Автоматическое обнаружение L2 сетей из Ethereum Foundation APIs
- **Chainlist Integration**: Интеграция с Chainlist.org для получения актуальных данных о сетях
- **Known Networks**: Предустановленные данные о популярных L2 сетях
- **Validation**: Валидация данных и проверка целостности
- **Export**: Экспорт результатов в JSON формате

## 📋 Требования

- Node.js 18+ 
- npm 8+
- Доступ к серверу с запущенным Lighthouse (Beacon Chain)
- SSH доступ к серверу Вовке

## 🛠️ Установка

1. **Клонируйте репозиторий** (если еще не сделано):
```bash
git clone https://github.com/defimon/defimon.highfunk.uk.git
cd defimon.highfunk.uk/tools/l2-networks-sync
```

2. **Установите зависимости**:
```bash
npm install
```

3. **Настройте переменные окружения**:
```bash
cp env.example .env
# Отредактируйте .env файл под ваши настройки
```

## 🔧 Конфигурация

### Переменные окружения

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `BEACON_API_URL` | URL Beacon Chain API | `http://localhost:5052` |
| `OUTPUT_DIR` | Директория для результатов | `./output` |
| `SYNC_TIMEOUT_MS` | Таймаут запросов (мс) | `30000` |
| `RUN_VALIDATION` | Запускать валидацию | `true` |

### Источники данных

Инструмент собирает данные из следующих источников:

1. **Ethereum Foundation APIs**
   - Rollups API
   - Bridges API  
   - L2 Metrics API
   - L2 Security API

2. **Chainlist.org**
   - Mainnet networks
   - Testnet networks

3. **Known L2 Networks**
   - Polygon, Arbitrum, Optimism, Base
   - zkSync Era, Scroll, Mantle, Linea
   - И другие популярные L2 сети

## 🚀 Использование

### Локальный запуск

```bash
# Запуск синхронизации
npm start

# Или напрямую
node sync-l2-networks.js

# С валидацией
RUN_VALIDATION=true node sync-l2-networks.js
```

### Запуск на сервере Вовке

Используйте скрипт для автоматического запуска на сервере:

```bash
# Сделайте скрипт исполняемым
chmod +x run-sync-on-server.sh

# Запустите синхронизацию на сервере
./run-sync-on-server.sh
```

Этот скрипт:
- Подключается к серверу Вовке
- Проверяет зависимости
- Запускает синхронизацию
- Скачивает результаты локально

## 📊 Результаты

После выполнения синхронизации создаются следующие файлы:

- `all-networks-YYYY-MM-DD.json` - Все сети (L1 + L2)
- `l2-networks-YYYY-MM-DD.json` - Только L2 сети
- `l1-networks-YYYY-MM-DD.json` - Только L1 сети
- `sync-report-YYYY-MM-DD.json` - Отчет о синхронизации
- `latest-*.json` - Последние результаты (без даты)

### Структура данных сети

```json
{
  "name": "Polygon",
  "chain_id": 137,
  "network_type": "L2",
  "rpc_url": "https://polygon-rpc.com",
  "explorer_url": "https://polygonscan.com",
  "native_currency": "ETH",
  "block_time": 2,
  "is_active": true,
  "last_block_number": null,
  "last_sync_time": "2024-01-01T00:00:00.000Z",
  "metadata": {
    "rollup_type": "rollup",
    "data_availability": "ethereum",
    "fraud_proof": true,
    "sequencer": "centralized",
    "verifier": "ethereum"
  },
  "source": "known_l2_networks"
}
```

## 🔍 Валидация

Инструмент автоматически валидирует полученные данные:

- Проверка обязательных полей
- Валидация chain_id
- Проверка RPC URLs для L2 сетей
- Удаление дубликатов

## 📝 Логирование

Все операции логируются с временными метками:

- Информация о подключении к API
- Количество найденных сетей
- Ошибки и предупреждения
- Результаты валидации

## 🚨 Устранение неполадок

### Ошибки подключения к Beacon Chain

```bash
# Проверьте статус Lighthouse
ssh vovkes-server "docker ps | grep lighthouse"

# Проверьте логи
ssh vovkes-server "docker logs lighthouse"
```

### Проблемы с зависимостями

```bash
# Переустановите зависимости
rm -rf node_modules package-lock.json
npm install
```

### Ошибки API

- Проверьте доступность внешних API
- Увеличьте таймауты в `.env`
- Проверьте rate limiting

## 🤝 Вклад в проект

1. Fork репозитория
2. Создайте feature branch
3. Внесите изменения
4. Создайте Pull Request

## 📄 Лицензия

MIT License - см. файл LICENSE для деталей.

## 🆘 Поддержка

При возникновении проблем:

1. Проверьте логи синхронизации
2. Убедитесь в корректности конфигурации
3. Создайте issue в GitHub
4. Обратитесь к команде Defimon

---

**Примечание**: Этот инструмент предназначен для работы с Ethereum L2 сетями и требует доступа к Beacon Chain API через Lighthouse.
