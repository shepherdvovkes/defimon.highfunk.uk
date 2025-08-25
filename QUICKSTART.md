# 🚀 Быстрый старт DeFi Analytics Platform

## Предварительные требования

- Docker & Docker Compose
- Git
- Минимум 4GB RAM
- Минимум 10GB свободного места

## Шаг 1: Клонирование и настройка

```bash
# Клонируйте репозиторий
git clone <repository-url>
cd DEFIMON

# Создайте файл с переменными окружения
cp env.example .env

# Отредактируйте .env файл (опционально)
# Добавьте ваши API ключи для внешних сервисов
```

## Шаг 2: Запуск системы

```bash
# Сделайте скрипт исполняемым
chmod +x scripts/deploy.sh

# Запустите полное развертывание
./scripts/deploy.sh
```

Или запустите вручную:

```bash
# Перейдите в директорию инфраструктуры
cd infrastructure

# Запустите все сервисы
docker-compose up -d

# Проверьте статус
docker-compose ps
```

## Шаг 3: Проверка работоспособности

После запуска проверьте доступность сервисов:

- **Frontend**: http://localhost:3000
- **API Gateway**: http://localhost:8000
- **Analytics API**: http://localhost:8002/docs
- **ML Service**: http://localhost:8001/docs
- **Grafana**: http://localhost:3001 (admin/admin)
- **Prometheus**: http://localhost:9090

## Шаг 4: Тестирование API

```bash
# Получить список протоколов
curl http://localhost:8000/api/protocols

# Получить обзор рынка
curl http://localhost:8000/api/analytics/overview

# Получить метрики для Uniswap
curl http://localhost:8000/api/protocols/uniswap_v3/metrics

# Получить оценку риска
curl http://localhost:8000/api/protocols/uniswap_v3/risk
```

## Структура проекта

```
DEFIMON/
├── frontend/                 # Next.js веб-приложение
├── services/
│   ├── analytics-api/        # FastAPI аналитический сервис
│   ├── ai-ml-service/        # Python AI/ML сервис
│   ├── data-ingestion/       # Сервис сбора данных
│   └── stream-processing/    # Обработка потоковых данных
├── infrastructure/           # Docker и конфигурации
├── monitoring/              # Prometheus, Grafana
├── scripts/                 # Скрипты развертывания
└── docs/                    # Документация
```

## Полезные команды

```bash
# Просмотр логов
docker-compose -f infrastructure/docker-compose.yml logs -f

# Остановка всех сервисов
docker-compose -f infrastructure/docker-compose.yml down

# Перезапуск конкретного сервиса
docker-compose -f infrastructure/docker-compose.yml restart analytics-api

# Просмотр использования ресурсов
docker stats

# Очистка данных
docker-compose -f infrastructure/docker-compose.yml down -v
```

## Устранение неполадок

### Проблема: Сервисы не запускаются

```bash
# Проверьте логи
docker-compose -f infrastructure/docker-compose.yml logs

# Проверьте статус контейнеров
docker-compose -f infrastructure/docker-compose.yml ps

# Перезапустите с пересборкой
docker-compose -f infrastructure/docker-compose.yml up -d --build
```

### Проблема: База данных недоступна

```bash
# Проверьте подключение к PostgreSQL
docker-compose -f infrastructure/docker-compose.yml exec postgres pg_isready -U postgres

# Проверьте подключение к ClickHouse
curl http://localhost:8123/ping
```

### Проблема: Kafka не работает

```bash
# Проверьте статус Kafka
docker-compose -f infrastructure/docker-compose.yml exec kafka kafka-topics --bootstrap-server localhost:9092 --list
```

## Разработка

### Локальная разработка

```bash
# Запустите только базы данных
docker-compose -f infrastructure/docker-compose.yml up -d postgres redis kafka

# Запустите frontend в режиме разработки
cd frontend && npm install && npm run dev

# Запустите API сервисы локально
cd services/analytics-api && python -m uvicorn main:app --reload --port 8002
cd services/ai-ml-service && python -m uvicorn main:app --reload --port 8001
```

### Добавление новых протоколов

1. Добавьте протокол в `infrastructure/init.sql`
2. Обновите data ingestion в `services/data-ingestion/main.py`
3. Добавьте обработку в `services/stream-processing/main.py`

## Мониторинг

- **Grafana**: http://localhost:3001 (admin/admin)
  - Дашборды для всех сервисов
  - Метрики производительности
  - Алерты

- **Prometheus**: http://localhost:9090
  - Метрики всех сервисов
  - Правила алертов

## Следующие шаги

1. **Настройка API ключей**: Добавьте реальные API ключи в `.env`
2. **Расширение данных**: Добавьте больше протоколов и источников данных
3. **ML модели**: Обучите и разверните реальные ML модели
4. **Масштабирование**: Настройте горизонтальное масштабирование
5. **Безопасность**: Добавьте аутентификацию и авторизацию

## Поддержка

- Создайте Issue для багов или feature requests
- Документация: `/docs`
- Email: support@defimon.com
