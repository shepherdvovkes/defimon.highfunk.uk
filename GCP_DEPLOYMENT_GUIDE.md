# Google Cloud Deployment Guide

Руководство по развертыванию системы оракулов цен в Google Cloud и интеграции с MVP сайтом.

## Обзор развертывания

Система развертывается в Google Cloud Platform и включает:

1. **Price Oracle System** - сервисы сбора и агрегации данных
2. **MVP Website Integration** - интеграция с существующим сайтом
3. **Infrastructure** - база данных, кэш, мониторинг

## Архитектура в Google Cloud

```
┌─────────────────────────────────────────────────────────────┐
│                    Google Cloud Platform                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   Cloud Run     │    │   Cloud Run     │                │
│  │ Price Oracle    │    │  Price API      │                │
│  │   Service       │    │   Service       │                │
│  └─────────────────┘    └─────────────────┘                │
│           │                       │                        │
│           └───────────────────────┼────────────────────────┘
│                                   │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   Cloud SQL     │    │  Memorystore    │                │
│  │  PostgreSQL     │    │     Redis       │                │
│  │   Database      │    │                 │                │
│  └─────────────────┘    └─────────────────┘                │
│                                   │                        │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   App Engine    │    │   Cloud Build   │                │
│  │   MVP Website   │    │   & Container   │                │
│  │                 │    │   Registry      │                │
│  └─────────────────┘    └─────────────────┘                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Предварительные требования

### 1. Google Cloud SDK
```bash
# Установка Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
```

### 2. Аутентификация
```bash
# Вход в Google Cloud
gcloud auth login

# Настройка проекта
gcloud config set project defimon-ethereum-node
```

### 3. Необходимые API
```bash
# Включение необходимых API
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable sql-component.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable redis.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable dns.googleapis.com
gcloud services enable certificatemanager.googleapis.com
```

## Быстрое развертывание

### Полное развертывание системы
```bash
# Запуск полного развертывания
./scripts/deploy-complete-system.sh
```

### Развертывание отдельных компонентов
```bash
# Только система оракулов
./scripts/deploy-complete-system.sh --oracle-only

# Только интеграция с MVP сайтом
./scripts/deploy-complete-system.sh --mvp-only

# Только тестирование
./scripts/deploy-complete-system.sh --test-only
```

## Пошаговое развертывание

### 1. Развертывание Price Oracle System

```bash
# Запуск скрипта развертывания оракулов
./scripts/deploy-price-oracle-gcp.sh
```

Этот скрипт:
- Создает Docker образы
- Развертывает сервисы в Cloud Run
- Инициализирует базу данных
- Настраивает мониторинг

### 2. Обновление MVP сайта

```bash
# Обновление MVP сайта с интеграцией
./scripts/update-mvp-with-oracle.sh
```

Этот скрипт:
- Добавляет компоненты оракула цен
- Создает новые страницы
- Обновляет зависимости
- Создает скрипт развертывания

### 3. Развертывание MVP сайта

```bash
# Развертывание обновленного MVP сайта
./scripts/deploy-mvp-with-oracle.sh
```

## Конфигурация сервисов

### Price Oracle Service (Cloud Run)
- **Сервис**: `price-oracle-service`
- **Регион**: `us-central1`
- **Порт**: `8081`
- **Ресурсы**: 1 CPU, 2GB RAM
- **Масштабирование**: 1-3 экземпляра

### Price API Service (Cloud Run)
- **Сервис**: `price-oracle-api`
- **Регион**: `us-central1`
- **Порт**: `8000`
- **Ресурсы**: 1 CPU, 2GB RAM
- **Масштабирование**: 1-5 экземпляров

### База данных (Cloud SQL)
- **Тип**: PostgreSQL 14
- **Регион**: `us-central1`
- **Размер**: db-f1-micro (для разработки)
- **База данных**: `defi_analytics`

### Кэш (Memorystore)
- **Тип**: Redis 6.x
- **Регион**: `us-central1`
- **Размер**: 1GB

## Переменные окружения

### Price Oracle Service
```bash
DB_HOST=/cloudsql/defimon-ethereum-node:us-central1:defimon-postgres-instance
DB_PORT=5432
DB_USER=defimon_user
DB_PASSWORD=defimon_secure_password_2024
DB_NAME=defi_analytics
REDIS_HOST=10.0.0.3
REDIS_PORT=6379
KAFKA_BOOTSTRAP_SERVERS=10.0.0.4:9092
```

### Price API Service
```bash
DB_HOST=/cloudsql/defimon-ethereum-node:us-central1:defimon-postgres-instance
DB_PORT=5432
DB_USER=defimon_user
DB_PASSWORD=defimon_secure_password_2024
DB_NAME=defi_analytics
REDIS_HOST=10.0.0.3
REDIS_PORT=6379
KAFKA_BOOTSTRAP_SERVERS=10.0.0.4:9092
```

## API Endpoints

### Основные эндпоинты
- `GET /prices` - текущие цены всех активов
- `GET /prices/{symbol}` - цены конкретного актива
- `GET /l2-networks` - данные L2 сетей
- `GET /aggregations` - агрегированные цены
- `GET /history/{symbol}` - исторические данные
- `GET /oracles/performance` - метрики оракулов
- `GET /health` - проверка здоровья сервиса
- `GET /docs` - документация API

### Примеры запросов
```bash
# Получение цен ETH
curl https://api.defimon.highfunk.uk/prices/ETH

# Получение данных L2 сетей
curl https://api.defimon.highfunk.uk/l2-networks

# Получение агрегированных цен
curl https://api.defimon.highfunk.uk/aggregations
```

## Мониторинг и метрики

### Prometheus метрики
- **Price Oracle Service**: `https://price-oracle-service-url/metrics`
- **Price API Service**: `https://price-oracle-api-url/metrics`

### Cloud Monitoring
- Дашборды для отслеживания производительности
- Алерты при сбоях сервисов
- Метрики использования ресурсов

### Логирование
- Cloud Logging для всех сервисов
- Структурированные логи с уровнем детализации
- Фильтрация и поиск по логам

## Масштабирование

### Автоматическое масштабирование
- Cloud Run автоматически масштабирует сервисы
- Настройка минимального и максимального количества экземпляров
- Масштабирование на основе CPU и запросов

### Ручное масштабирование
```bash
# Изменение количества экземпляров
gcloud run services update price-oracle-service \
  --min-instances=2 \
  --max-instances=5 \
  --region=us-central1
```

## Безопасность

### Аутентификация
- Cloud Run поддерживает IAM аутентификацию
- Настройка доступа через сервисные аккаунты
- Интеграция с Google Cloud IAM

### Сетевая безопасность
- VPC для изоляции ресурсов
- Firewall правила для контроля доступа
- SSL/TLS шифрование для всех соединений

### Шифрование данных
- Шифрование данных в покое
- Шифрование данных в движении
- Управление ключами через Cloud KMS

## Резервное копирование

### База данных
- Автоматические резервные копии Cloud SQL
- Настройка расписания резервного копирования
- Точки восстановления

### Конфигурация
- Версионирование конфигураций
- Backup конфигурационных файлов
- Документирование изменений

## Обновления и развертывание

### Обновление сервисов
```bash
# Обновление Price Oracle Service
gcloud run deploy price-oracle-service \
  --image gcr.io/defimon-ethereum-node/price-oracle-service:latest \
  --region us-central1

# Обновление Price API Service
gcloud run deploy price-oracle-api \
  --image gcr.io/defimon-ethereum-node/price-oracle-api:latest \
  --region us-central1
```

### Blue-Green развертывание
- Поддержка blue-green развертывания
- Плавное переключение между версиями
- Откат при проблемах

## Устранение неполадок

### Проверка статуса сервисов
```bash
# Проверка статуса Cloud Run сервисов
gcloud run services list --region=us-central1

# Просмотр логов
gcloud logs read "resource.type=cloud_run_revision"

# Проверка метрик
gcloud monitoring metrics list
```

### Частые проблемы
1. **Ошибки подключения к БД**
   - Проверка настроек Cloud SQL
   - Проверка сетевых правил

2. **Проблемы с аутентификацией**
   - Проверка сервисных аккаунтов
   - Проверка IAM разрешений

3. **Проблемы с масштабированием**
   - Проверка лимитов квот
   - Настройка автоматического масштабирования

## Стоимость и оптимизация

### Оценка стоимости
- **Cloud Run**: ~$50-100/месяц
- **Cloud SQL**: ~$30-50/месяц
- **Memorystore**: ~$20-30/месяц
- **App Engine**: ~$20-40/месяц
- **Общая стоимость**: ~$120-220/месяц

### Оптимизация затрат
- Использование бесплатного уровня
- Настройка автоматического масштабирования
- Мониторинг использования ресурсов
- Оптимизация запросов к БД

## Поддержка и обслуживание

### Регулярные задачи
- Мониторинг производительности
- Обновление зависимостей
- Резервное копирование данных
- Обновление сертификатов SSL

### Обновления системы
- Регулярные обновления безопасности
- Обновления версий сервисов
- Обновления инфраструктуры

## Контакты и поддержка

- **Документация**: [GitHub Repository](https://github.com/your-repo)
- **Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- **Поддержка**: support@defimon.highfunk.uk

---

**Примечание**: Это руководство предполагает, что у вас есть доступ к проекту Google Cloud `defimon-ethereum-node`. Если у вас другой проект, замените `defimon-ethereum-node` на ваш проект ID.
