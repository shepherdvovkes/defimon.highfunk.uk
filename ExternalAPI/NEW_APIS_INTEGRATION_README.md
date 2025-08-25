# New APIs Integration Guide

Этот документ описывает интеграцию новых API сервисов в проект DeFiMon.

## Добавленные API Сервисы

### 1. QuickNode API
- **Ключ**: `QN_6a9c24b3a5fc491f88e8c24c3294ef36`
- **Описание**: Ethereum RPC провайдер для получения данных блокчейна
- **Возможности**: Получение номера блока, цены газа, баланса адресов

### 2. Blast API
- **Ключ**: `azoNgu3Cle2YBWFElUzVWNCXw-g_F31RvQjQKJmfVcg`
- **Описание**: API для работы с Blast L2 сетью
- **Возможности**: Получение данных блоков и транзакций

### 3. CoinGecko API
- **Ключ**: `CG-32UZHngR3w1V7u2vQ76tP3Fi`
- **Описание**: API для получения данных о криптовалютах
- **Возможности**: Цены, рыночные данные, топ монет

### 4. CoinCap API
- **Ключ**: `dbdbfe12346bb92d9dac28504e5fee49ee721659429345b8a8fd8da5bab9c715`
- **Описание**: Альтернативный API для криптовалютных данных
- **Возможности**: Данные активов, курсы валют

### 5. GitHub API
- **Токен**: `[GITHUB_TOKEN_PLACEHOLDER]`
- **Пользователь**: `shepherdvovkes`
- **Описание**: API для работы с GitHub репозиториями
- **Возможности**: Информация о пользователе, репозитории

## Структура Файлов

```
ExternalAPI/
├── config_new_apis.py              # Конфигурация новых API
├── test_new_apis.py                # Тесты для всех API
├── run_new_apis_test.sh            # Скрипт запуска тестов
└── NEW_APIS_INTEGRATION_README.md  # Этот файл

services/analytics-api/
├── routers/
│   └── external_apis.py            # Роутер для внешних API
├── test_external_apis_integration.py  # Тесты интеграции
└── run_integration_tests.sh        # Скрипт тестов интеграции
```

## Установка и Настройка

### 1. Установка зависимостей

```bash
# В директории ExternalAPI
pip3 install requests websocket-client

# В директории services/analytics-api
pip3 install requests fastapi uvicorn sqlalchemy python-dotenv
```

### 2. Настройка переменных окружения

Создайте файл `.env` в корне проекта или установите переменные окружения:

```bash
export QUICKNODE_API_KEY="QN_6a9c24b3a5fc491f88e8c24c3294ef36"
export BLAST_API_KEY="azoNgu3Cle2YBWFElUzVWNCXw-g_F31RvQjQKJmfVcg"
export COINGECKO_API_KEY="CG-32UZHngR3w1V7u2vQ76tP3Fi"
export COINCAP_API_KEY="dbdbfe12346bb92d9dac28504e5fee49ee721659429345b8a8fd8da5bab9c715"
export GITHUB_API_TOKEN="[GITHUB_TOKEN_PLACEHOLDER]"
export GITHUB_USERNAME="shepherdvovkes"
```

## Запуск Тестов

### 1. Тестирование отдельных API

```bash
cd ExternalAPI
chmod +x run_new_apis_test.sh
./run_new_apis_test.sh
```

Этот скрипт:
- Устанавливает переменные окружения
- Проверяет зависимости
- Запускает тесты всех API
- Генерирует отчеты

### 2. Тестирование интеграции в analytics-api

```bash
cd services/analytics-api
chmod +x run_integration_tests.sh
./run_integration_tests.sh
```

Этот скрипт:
- Запускает analytics-api сервис (если не запущен)
- Тестирует все эндпоинты интеграции
- Генерирует отчеты интеграции

## API Эндпоинты

После интеграции в analytics-api доступны следующие эндпоинты:

### QuickNode API
- `GET /api/external-apis/quicknode/block-number` - Номер последнего блока
- `GET /api/external-apis/quicknode/gas-price` - Текущая цена газа
- `GET /api/external-apis/quicknode/balance/{address}` - Баланс адреса

### CoinGecko API
- `GET /api/external-apis/coingecko/bitcoin-price` - Цена Bitcoin
- `GET /api/external-apis/coingecko/top-coins?limit=10` - Топ монет

### CoinCap API
- `GET /api/external-apis/coincap/assets` - Все активы
- `GET /api/external-apis/coincap/bitcoin` - Данные Bitcoin

### GitHub API
- `GET /api/external-apis/github/user` - Информация о пользователе
- `GET /api/external-apis/github/repos` - Репозитории пользователя

### Общие эндпоинты
- `GET /api/external-apis/health` - Проверка здоровья API
- `GET /api/external-apis/summary` - Сводка всех API

## Примеры Использования

### 1. Получение данных через curl

```bash
# Получить номер последнего блока
curl http://localhost:8002/api/external-apis/quicknode/block-number

# Получить цену Bitcoin
curl http://localhost:8002/api/external-apis/coingecko/bitcoin-price

# Получить сводку всех API
curl http://localhost:8002/api/external-apis/summary
```

### 2. Использование в Python

```python
import requests

# Получить данные QuickNode
response = requests.get("http://localhost:8002/api/external-apis/quicknode/block-number")
block_data = response.json()

# Получить данные CoinGecko
response = requests.get("http://localhost:8002/api/external-apis/coingecko/bitcoin-price")
btc_data = response.json()
```

## Мониторинг и Логирование

### Логи тестов
- Результаты тестов сохраняются в JSON формате
- Отчеты генерируются в текстовом формате
- Все файлы содержат временные метки

### Мониторинг API
- Health check эндпоинт для проверки состояния
- Логирование ошибок в analytics-api
- Метрики производительности

## Безопасность

### Рекомендации
1. **Не коммитьте API ключи** в репозиторий
2. **Используйте переменные окружения** для хранения ключей
3. **Регулярно ротируйте ключи** API
4. **Мониторьте использование** API лимитов

### Ограничения
- CoinGecko: 50 вызовов/минуту (с API ключом)
- GitHub: 5000 вызовов/час (с токеном)
- QuickNode: Зависит от плана подписки
- CoinCap: 200 вызовов/минуту

## Устранение Неполадок

### Частые проблемы

1. **API ключ недействителен**
   - Проверьте правильность ключа
   - Убедитесь, что ключ активен

2. **Превышен лимит запросов**
   - Проверьте текущее использование
   - Добавьте задержки между запросами

3. **Сервис недоступен**
   - Проверьте подключение к интернету
   - Убедитесь, что API сервис работает

### Логи для диагностики

```bash
# Проверить логи analytics-api
tail -f /var/log/analytics-api.log

# Проверить статус сервиса
curl http://localhost:8002/health
```

## Обновления и Поддержка

### Обновление API ключей
1. Получите новые ключи от провайдеров
2. Обновите переменные окружения
3. Перезапустите сервисы
4. Запустите тесты для проверки

### Добавление новых API
1. Создайте конфигурацию в `config_new_apis.py`
2. Добавьте класс сервиса в `external_apis.py`
3. Создайте эндпоинты в роутере
4. Добавьте тесты
5. Обновите документацию

## Контакты

Для вопросов по интеграции API обращайтесь к команде разработки DeFiMon.

---

**Дата создания**: $(date)
**Версия**: 1.0.0
**Автор**: DeFiMon Team
