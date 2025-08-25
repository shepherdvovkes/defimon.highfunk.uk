# DEFIMON L2 Analytics Framework

Комплексная система аналитики для L2 (Layer 2) протоколов, предназначенная для инвесторов. Система отслеживает 10 ключевых метрик, критически важных для оценки инвестиционной привлекательности L2 проектов.

## 🎯 Топ-10 метрик для инвестора L2

1. **TVL Growth Rate** - Темп роста заблокированной стоимости
2. **Daily Active Users** - Ежедневные активные пользователи
3. **Gas Savings vs L1** - Экономия на комиссиях
4. **Security Score** - Оценка безопасности
5. **Protocol Count** - Количество протоколов в экосистеме
6. **Developer Activity** - Активность разработчиков
7. **Token Price Performance** - Динамика цены токена
8. **Finality Time** - Время финализации транзакций
9. **Partnership Quality** - Качество партнерств
10. **Market Share** - Доля рынка среди L2 решений

## 🏗️ Архитектура системы

```
docs/l2-analytics/
├── data-collection/          # Коллекторы данных
│   ├── tvl-collector.py      # ✅ Реализован
│   ├── user-activity-collector.py  # ✅ Реализован
│   └── gas-savings-collector.py    # ✅ Реализован
├── data-processing/          # Обработка данных
├── api/                      # FastAPI сервер
│   ├── l2-analytics-api.py   # ✅ Реализован
│   └── endpoints/            # API endpoints
├── dashboards/               # Дашборды
│   ├── defimon-dashboard.html  # ✅ Новый DEFIMON дашборд
│   └── investor-dashboard.html  # Старый дашборд
├── requirements.txt          # ✅ Зависимости
├── README.md                 # ✅ Документация
└── run-l2-analytics.sh      # ✅ Скрипт запуска
```

## 🚀 Быстрый старт

### 1. Установка зависимостей

```bash
cd docs/l2-analytics
python3 -m venv venv
source venv/bin/activate  # На Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Настройка API ключей

Создайте файл `.env` в папке `docs/l2-analytics/`:

```bash
# Etherscan API Keys
ETHERSCAN_API_KEY=your_etherscan_api_key
ARBISCAN_API_KEY=your_arbiscan_api_key
OPTIMISTIC_ETHERSCAN_API_KEY=your_optimistic_etherscan_api_key
POLYGONSCAN_API_KEY=your_polygonscan_api_key
BASESCAN_API_KEY=your_basescan_api_key

# Alchemy API Key (для Ethereum L1)
ALCHEMY_API_KEY=your_alchemy_api_key
```

### 3. Запуск системы

```bash
# Автоматический запуск
./run-l2-analytics.sh

# Или ручной запуск
cd api
python l2-analytics-api.py
```

### 4. Доступ к системе

- **DEFIMON Dashboard**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

## 🎨 DEFIMON Dashboard

Новый дашборд в стиле DEFIMON предоставляет:

### ✨ Особенности дизайна
- **Темная тема** - Современный темный интерфейс
- **Responsive design** - Адаптация под все устройства
- **Интерактивные элементы** - Hover эффекты и анимации
- **Phosphor Icons** - Красивые иконки
- **Tailwind CSS** - Современная стилизация

### 📊 Функциональность
- **Ключевые метрики** - TVL, прибыль, пользователи, затраты
- **Инвестиционный профиль** - Оценка DEFIMON для каждого протокола
- **Интерактивные графики** - Chart.js с темной темой
- **Сравнительная таблица** - Анализ всех L2 сетей
- **Фильтрация по протоколам** - Детальный анализ
- **Real-time обновления** - Автообновление каждые 5 минут

### 🎯 Основные секции
1. **Ключевые метрики L2** - Общий обзор рынка
2. **Инвестиционный профиль** - Детальный анализ выбранного протокола
3. **Анализ ончейн-активности** - TPS, комиссии, удержание
4. **Сравнительный анализ** - Таблица всех L2 решений

## 📊 API Endpoints

### Основные endpoints
- `GET /` - DEFIMON Dashboard (главная страница)
- `GET /health` - Проверка здоровья системы
- `GET /docs` - Swagger документация
- `GET /redoc` - ReDoc документация

### TVL endpoints
- `GET /api/l2-analytics/tvl-growth` - TVL данные
- `GET /api/l2-analytics/tvl-growth/{protocol}` - TVL для протокола

### User Activity endpoints
- `GET /api/l2-analytics/daily-active-users` - DAU данные
- `GET /api/l2-analytics/user-retention` - Retention метрики

### Gas Savings endpoints
- `GET /api/l2-analytics/gas-savings` - Gas savings данные
- `GET /api/l2-analytics/gas-savings/comparison` - Детальное сравнение

### Управление данными
- `POST /api/l2-analytics/collect` - Запуск сбора данных

## 🔧 Конфигурация

### Поддерживаемые L2 протоколы

- **Arbitrum One** (chain_id: 42161) ✅
- **Optimism** (chain_id: 10) ✅
- **Polygon** (chain_id: 137) ✅
- **Base** (chain_id: 8453) ✅
- **zkSync Era** (chain_id: 324) ✅
- **Starknet** (chain_id: 0x534e5f474f45524c49) ✅

### Источники данных

- **DeFiLlama API** - TVL данные
- **L2Beat API** - L2 метрики
- **Etherscan APIs** - Транзакционные данные
- **RPC endpoints** - Прямые запросы к блокчейнам
- **CoinGecko API** - Цены токенов

## 📈 Метрики и формулы

### TVL Growth Rate

```
TVL Growth Rate = ((TVL_current - TVL_previous) / TVL_previous) * 100
Compound Growth Rate = ((TVL_current / TVL_initial) ^ (1/n) - 1) * 100
```

### Daily Active Users

```
DAU = COUNT(DISTINCT from_addresses) WHERE date = today
WAU = COUNT(DISTINCT from_addresses) WHERE date >= today - 7
MAU = COUNT(DISTINCT from_addresses) WHERE date >= today - 30
```

### Gas Savings

```
Gas Savings % = ((L1_gas_cost - L2_gas_cost) / L1_gas_cost) * 100
Average Savings = MEAN(gas_savings_per_transaction)
```

## 🔄 Автоматизация

### Скрипт запуска

```bash
# Запуск всей системы
./run-l2-analytics.sh

# Только тестирование
./run-l2-analytics.sh test

# Только сбор данных
./run-l2-analytics.sh collect

# Только дашборд
./run-l2-analytics.sh dashboard
```

### Планировщик задач

Для автоматического сбора данных создайте cron job:

```bash
# Сбор данных каждый час
0 * * * * cd /path/to/docs/l2-analytics && python -c "import asyncio; from api.l2_analytics_api import collect_all_metrics; asyncio.run(collect_all_metrics())"

# Сбор данных каждый день в полночь
0 0 * * * cd /path/to/docs/l2-analytics && python -c "import asyncio; from api.l2_analytics_api import collect_all_metrics; asyncio.run(collect_all_metrics())"
```

## 🛠️ Разработка

### Добавление нового коллектора

1. Создайте новый файл в `data-collection/`
2. Реализуйте класс коллектора с методами:
   - `collect_data()` - сбор данных
   - `process_data()` - обработка данных
   - `save_data()` - сохранение данных
3. Добавьте endpoint в API
4. Обновите дашборд

### Добавление новой метрики

1. Определите формулу расчета
2. Создайте коллектор данных
3. Добавьте API endpoint
4. Обновите дашборд
5. Добавьте в документацию

## 📝 Логирование

Система использует структурированное логирование:

```python
import logging

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
```

Логи сохраняются в файлы:
- `tvl_collector.log`
- `user_activity_collector.log`
- `gas_savings_collector.log`
- `api_server.log`

## 🔒 Безопасность

### Реализованные меры
- ✅ Environment variables для API ключей
- ✅ Input validation
- ✅ Error handling без утечки данных
- ✅ CORS configuration

### Рекомендации для продакшена
- 🔄 Rate limiting
- 🔄 Authentication/Authorization
- 🔄 HTTPS/TLS
- 🔄 Database security
- 🔄 API key rotation

## 🚀 Развертывание

### Локальное развертывание
- ✅ Virtual environment
- ✅ Dependency management
- ✅ Configuration files
- ✅ Service scripts

### Продакшен развертывание
- 🔄 Docker containers
- 🔄 Kubernetes manifests
- 🔄 CI/CD pipeline
- 🔄 Monitoring stack

## 📞 Поддержка

### Полезные команды

```bash
# Проверка здоровья системы
curl http://localhost:8000/health

# Получение TVL данных
curl http://localhost:8000/api/l2-analytics/tvl-growth

# Запуск сбора данных
curl -X POST http://localhost:8000/api/l2-analytics/collect

# Просмотр логов
tail -f tvl_collector.log
```

### Отладка

```bash
# Запуск в режиме отладки
python -m uvicorn api.l2_analytics_api:app --reload --log-level debug

# Тестирование коллекторов
python data-collection/tvl-collector.py
python data-collection/user-activity-collector.py
python data-collection/gas-savings-collector.py
```

## 📚 Дополнительные ресурсы

- [Документация API](http://localhost:8000/docs)
- [ReDoc документация](http://localhost:8000/redoc)
- [Основная документация проекта](../L2_ANALYTICS_FRAMEWORK.md)

## 🤝 Вклад в проект

1. Fork репозитория
2. Создайте feature branch
3. Внесите изменения
4. Добавьте тесты
5. Создайте Pull Request

## 📄 Лицензия

Этот проект является частью DefiMon и следует тем же условиям лицензирования.
