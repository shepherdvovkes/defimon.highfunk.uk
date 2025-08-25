# L2 Analytics Framework для Инвесторов

## Обзор

Данный документ описывает комплексную систему аналитики для L2 (Layer 2) решений, предназначенную для инвесторов. Система отслеживает 10 ключевых метрик, которые критически важны для оценки инвестиционной привлекательности L2 проектов.

## Архитектура системы

### Внешние IP и API Endpoints

**Основной внешний IP**: `185.199.108.153` (GitHub Pages)
**Альтернативные IP**: 
- `185.199.109.153`
- `185.199.110.153`
- `185.199.111.153`

### Структура API запросов

```bash
# Базовый URL для всех L2 метрик
https://defimon.highfunk.uk/api/l2-analytics/{metric}

# Примеры запросов
GET /api/l2-analytics/tvl-growth
GET /api/l2-analytics/daily-active-users
GET /api/l2-analytics/gas-savings
```

## Топ-10 метрик для инвестора L2

### 1. TVL Growth Rate - Темп роста заблокированной стоимости

#### Описание
TVL (Total Value Locked) - общая стоимость активов, заблокированных в протоколе. Показывает доверие пользователей и рост экосистемы.

#### Методы сбора данных
```python
# Источники данных
- DeFiLlama API: https://api.llama.fi/protocols
- DefiPulse API: https://api.defipulse.com/v1/defipulse/api/GetHistory
- Собственные RPC запросы к смарт-контрактам

# Метрики для расчета
- TVL текущий vs TVL за предыдущий период
- Процентное изменение TVL
- Скорость роста (абсолютные значения)
- Сезонность роста
```

#### Формулы расчета
```
TVL Growth Rate = ((TVL_current - TVL_previous) / TVL_previous) * 100
Compound Growth Rate = ((TVL_current / TVL_initial) ^ (1/n) - 1) * 100
```

#### API Endpoints
```bash
GET /api/l2-analytics/tvl-growth
GET /api/l2-analytics/tvl-growth/{protocol}
GET /api/l2-analytics/tvl-growth/history/{days}
```

### 2. Daily Active Users - Ежедневные активные пользователи

#### Описание
Количество уникальных адресов, совершивших транзакции в сети за последние 24 часа.

#### Методы сбора данных
```python
# Источники данных
- RPC запросы: eth_getLogs для событий транзакций
- Etherscan API: https://api.etherscan.io/api
- Собственные индексы транзакций
- WebSocket подписки на новые блоки

# Метрики для анализа
- Уникальные адреса за день
- Активные адреса за неделю/месяц
- Retention rate пользователей
- Новые vs возвращающиеся пользователи
```

#### Формулы расчета
```
DAU = COUNT(DISTINCT from_addresses) WHERE date = today
WAU = COUNT(DISTINCT from_addresses) WHERE date >= today - 7
MAU = COUNT(DISTINCT from_addresses) WHERE date >= today - 30
```

#### API Endpoints
```bash
GET /api/l2-analytics/daily-active-users
GET /api/l2-analytics/daily-active-users/{protocol}
GET /api/l2-analytics/user-retention
```

### 3. Gas Savings vs L1 - Экономия на комиссиях

#### Описание
Сравнение стоимости транзакций в L2 vs Ethereum L1, показывающее экономическую эффективность решения.

#### Методы сбора данных
```python
# Источники данных
- RPC запросы: eth_gasPrice для L1 и L2
- Gas tracking APIs
- Собственные тестовые транзакции
- Исторические данные о gas ценах

# Метрики для анализа
- Средняя стоимость транзакции L1 vs L2
- Процент экономии
- Динамика изменения экономии
- Сравнение по типам транзакций
```

#### Формулы расчета
```
Gas Savings % = ((L1_gas_cost - L2_gas_cost) / L1_gas_cost) * 100
Average Savings = MEAN(gas_savings_per_transaction)
```

#### API Endpoints
```bash
GET /api/l2-analytics/gas-savings
GET /api/l2-analytics/gas-savings/comparison
GET /api/l2-analytics/gas-savings/history
```

### 4. Security Score - Оценка безопасности

#### Описание
Комплексная оценка безопасности L2 решения, включающая аудит смарт-контрактов, механизмы защиты и историю инцидентов.

#### Методы сбора данных
```python
# Источники данных
- Аудиторские отчеты (Certik, Trail of Bits, Consensys Diligence)
- GitHub репозитории проектов
- Bug bounty программы
- Исторические данные об эксплойтах
- Социальные сети и форумы

# Метрики для анализа
- Количество аудитов
- Критичность найденных уязвимостей
- Время исправления уязвимостей
- Размер bug bounty фондов
- Активность разработки безопасности
```

#### Формулы расчета
```
Security Score = (Audit_Score * 0.4) + (Bug_Bounty_Score * 0.2) + 
                 (Code_Quality_Score * 0.2) + (Incident_History_Score * 0.2)
```

#### API Endpoints
```bash
GET /api/l2-analytics/security-score
GET /api/l2-analytics/security-score/{protocol}
GET /api/l2-analytics/security-audits
```

### 5. Protocol Count - Количество протоколов в экосистеме

#### Описание
Количество активных DeFi протоколов, развернутых в L2 сети, показывающее развитие экосистемы.

#### Методы сбора данных
```python
# Источники данных
- DeFiLlama API: https://api.llama.fi/protocols
- Собственные индексы контрактов
- GitHub репозитории проектов
- Социальные сети и анонсы

# Метрики для анализа
- Общее количество протоколов
- Активные протоколы (с TVL > 0)
- Новые протоколы за период
- Категории протоколов (DEX, Lending, Yield, etc.)
```

#### Формулы расчета
```
Total Protocols = COUNT(protocols)
Active Protocols = COUNT(protocols WHERE tvl > 0)
New Protocols = COUNT(protocols WHERE launch_date >= today - 30)
```

#### API Endpoints
```bash
GET /api/l2-analytics/protocol-count
GET /api/l2-analytics/protocol-count/categories
GET /api/l2-analytics/protocol-count/new
```

### 6. Developer Activity - Активность разработчиков

#### Описание
Метрики активности разработчиков, включающие коммиты, пулл-реквесты, звезды репозиториев и активность сообщества.

#### Методы сбора данных
```python
# Источники данных
- GitHub API: https://api.github.com
- GitLab API
- Discord/Telegram активности
- Stack Overflow теги
- NPM/CRATES.io статистика

# Метрики для анализа
- Количество коммитов за период
- Активные контрибьюторы
- Звезды и форки репозиториев
- Активность в социальных сетях
- Участие в конференциях
```

#### Формулы расчета
```
Developer Activity Score = (Commits_Score * 0.3) + (Contributors_Score * 0.2) + 
                          (Community_Score * 0.2) + (Social_Score * 0.3)
```

#### API Endpoints
```bash
GET /api/l2-analytics/developer-activity
GET /api/l2-analytics/developer-activity/github
GET /api/l2-analytics/developer-activity/community
```

### 7. Token Price Performance - Динамика цены токена

#### Описание
Анализ динамики цены нативного токена L2 решения, включая волатильность, корреляции и рыночные тренды.

#### Методы сбора данных
```python
# Источники данных
- CoinGecko API: https://api.coingecko.com/api/v3
- CoinMarketCap API
- DEX данные (Uniswap, SushiSwap)
- CEX данные через WebSocket

# Метрики для анализа
- Цена токена и изменение за период
- Волатильность (ATR, Bollinger Bands)
- Корреляция с BTC/ETH
- Объем торгов
- Market Cap и FDV
```

#### Формулы расчета
```
Price Change % = ((current_price - previous_price) / previous_price) * 100
Volatility = STD(price_changes) * SQRT(252)
Sharpe Ratio = (Return - Risk_Free_Rate) / Volatility
```

#### API Endpoints
```bash
GET /api/l2-analytics/token-price
GET /api/l2-analytics/token-price/performance
GET /api/l2-analytics/token-price/volatility
```

### 8. Finality Time - Время финализации транзакций

#### Описание
Время, необходимое для финализации транзакции в L2 сети, критически важный показатель для пользовательского опыта.

#### Методы сбора данных
```python
# Источники данных
- RPC запросы для отслеживания блоков
- WebSocket подписки на новые блоки
- Собственные тестовые транзакции
- Публичные RPC endpoints

# Метрики для анализа
- Время до финализации
- Размер блоков
- Частота блоков
- Время подтверждения
- Стабильность сети
```

#### Формулы расчета
```
Average Finality Time = MEAN(finality_times)
Finality Reliability = COUNT(finality_time <= target) / COUNT(total_transactions)
```

#### API Endpoints
```bash
GET /api/l2-analytics/finality-time
GET /api/l2-analytics/finality-time/stats
GET /api/l2-analytics/finality-time/reliability
```

### 9. Partnership Quality - Качество партнерств

#### Описание
Оценка качества и стратегической ценности партнерств L2 проекта с другими компаниями и протоколами.

#### Методы сбора данных
```python
# Источники данных
- Официальные анонсы проектов
- Социальные сети (Twitter, LinkedIn)
- Пресс-релизы
- GitHub интеграции
- Бизнес-аналитика

# Метрики для анализа
- Количество партнерств
- Качество партнеров (market cap, reputation)
- Активность партнерств
- Стратегическая ценность
- Техническая интеграция
```

#### Формулы расчета
```
Partnership Score = (Partner_Quality * 0.4) + (Integration_Depth * 0.3) + 
                   (Strategic_Value * 0.3)
```

#### API Endpoints
```bash
GET /api/l2-analytics/partnerships
GET /api/l2-analytics/partnerships/quality
GET /api/l2-analytics/partnerships/strategic
```

### 10. Market Share - Доля рынка среди L2 решений

#### Описание
Доля L2 решения в общем объеме L2 транзакций и TVL, показывающая конкурентную позицию.

#### Методы сбора данных
```python
# Источники данных
- L2Beat API: https://api.l2beat.com
- DeFiLlama L2 данные
- Собственные агрегаторы
- RPC запросы к различным L2

# Метрики для анализа
- Доля в общем L2 TVL
- Доля в транзакциях
- Доля в пользователях
- Тренды изменения доли
- Конкурентный анализ
```

#### Формулы расчета
```
Market Share % = (Protocol_TVL / Total_L2_TVL) * 100
Transaction Share % = (Protocol_Transactions / Total_L2_Transactions) * 100
```

#### API Endpoints
```bash
GET /api/l2-analytics/market-share
GET /api/l2-analytics/market-share/competitors
GET /api/l2-analytics/market-share/trends
```

## Реализация системы

### Структура папок

```
docs/
├── L2_ANALYTICS_FRAMEWORK.md (этот файл)
├── l2-analytics/
│   ├── data-collection/
│   │   ├── tvl-collector.py
│   │   ├── user-activity-collector.py
│   │   ├── gas-savings-collector.py
│   │   └── ...
│   ├── data-processing/
│   │   ├── metrics-calculator.py
│   │   ├── data-aggregator.py
│   │   └── report-generator.py
│   ├── api/
│   │   ├── l2-analytics-api.py
│   │   ├── endpoints/
│   │   └── middleware/
│   └── dashboards/
│       ├── investor-dashboard.html
│       ├── metrics-visualization.js
│       └── real-time-updates.js
```

### Технологический стек

```python
# Backend
- FastAPI для API endpoints
- PostgreSQL для хранения данных
- Redis для кэширования
- Celery для фоновых задач

# Data Collection
- aiohttp для асинхронных запросов
- websockets для real-time данных
- pandas для обработки данных
- numpy для вычислений

# Frontend
- React/Vue.js для дашбордов
- D3.js для визуализации
- WebSocket для real-time обновлений
```

### План развертывания

1. **Этап 1**: Настройка инфраструктуры
   - Развертывание базы данных
   - Настройка API сервера
   - Конфигурация мониторинга

2. **Этап 2**: Реализация коллекторов данных
   - TVL коллектор
   - User activity коллектор
   - Gas savings коллектор

3. **Этап 3**: API разработка
   - REST API endpoints
   - WebSocket для real-time данных
   - Аутентификация и авторизация

4. **Этап 4**: Дашборд разработка
   - Инвесторский дашборд
   - Интерактивные графики
   - Экспорт отчетов

5. **Этап 5**: Тестирование и оптимизация
   - Load testing
   - Performance optimization
   - Security audit

## Мониторинг и алерты

### Ключевые метрики для мониторинга

```python
# Системные метрики
- API response time < 200ms
- Data freshness < 5 minutes
- Error rate < 1%
- Database performance

# Бизнес метрики
- TVL изменения > 10%
- DAU падение > 20%
- Gas savings < 50%
- Security score < 7.0
```

### Система алертов

```python
# Каналы уведомлений
- Email для критических алертов
- Slack/Discord для оперативных
- SMS для emergency случаев
- Telegram bot для daily digest
```

## Заключение

Данная система аналитики предоставляет инвесторам комплексный инструмент для оценки L2 проектов. Регулярное обновление метрик и качественная визуализация данных позволят принимать обоснованные инвестиционные решения.

### Следующие шаги

1. Создание MVP для первых 3 метрик
2. Тестирование с реальными данными
3. Обратная связь от инвесторов
4. Итеративное улучшение системы
