# Google Cloud Infrastructure Monitor Bot

Этот Telegram бот предоставляет комплексный мониторинг и управление инфраструктурой Google Cloud Platform (GCP). Бот может отслеживать кластеры, выполнять команды, отправлять уведомления и предоставлять детальную информацию о состоянии вашей инфраструктуры.

## 🚀 Возможности

### Мониторинг инфраструктуры
- **GKE кластеры**: Статус, версии, количество узлов
- **Compute Instances**: Состояние, типы машин, сетевые интерфейсы
- **Сети**: VPC, подсети, маршрутизация
- **Хранилище**: Buckets, диски, квоты
- **IAM**: Роли, политики, участники

### Управление кластерами
- **Масштабирование**: Изменение количества узлов
- **Перезапуск**: Rolling update для node pools
- **Логи**: Получение логов кластеров
- **Выполнение команд**: Безопасное выполнение gcloud команд

### Автоматический мониторинг
- **Проверка здоровья**: Автоматический мониторинг статуса кластеров
- **Алерты**: Уведомления об изменениях и проблемах
- **Квоты**: Мониторинг использования ресурсов
- **Автоскейлинг**: Отслеживание пороговых значений

## 📋 Требования

- Python 3.8+
- Google Cloud SDK
- Telegram Bot Token
- Доступ к Google Cloud Project
- Service Account с необходимыми правами

## 🔧 Установка и настройка

### 1. Клонирование репозитория
```bash
git clone <your-repo>
cd telegrambot
```

### 2. Установка зависимостей
```bash
pip install -r requirements.txt
```

### 3. Настройка Google Cloud

#### Аутентификация
```bash
# Использование Application Default Credentials
gcloud auth application-default login

# Или создание Service Account
gcloud iam service-accounts create bot-monitor \
    --display-name="Bot Monitor Service Account"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:bot-monitor@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/container.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:bot-monitor@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.viewer"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:bot-monitor@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/monitoring.viewer"

# Создание ключа
gcloud iam service-accounts keys create key.json \
    --iam-account=bot-monitor@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

#### Включение API
```bash
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable billing.googleapis.com
gcloud services enable resourcemanager.googleapis.com
```

### 4. Настройка Telegram Bot

#### Создание бота
1. Найдите @BotFather в Telegram
2. Отправьте `/newbot`
3. Следуйте инструкциям для создания бота
4. Сохраните полученный токен

#### Получение Chat ID
1. Добавьте бота в чат или группу
2. Отправьте сообщение боту
3. Откройте в браузере: `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
4. Найдите `chat.id` в ответе

### 5. Настройка переменных окружения

Скопируйте `env.example` в `.env` и заполните:

```bash
# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here

# Google Cloud Configuration
GOOGLE_CLOUD_PROJECT_ID=your_gcp_project_id_here

# Telegram Chat Configuration
TELEGRAM_CHAT_ID=your_chat_id_here
ADDITIONAL_CHAT_IDS=chat_id1,chat_id2

# Optional: Restrict bot access
ALLOWED_TELEGRAM_USERS=user_id1,user_id2

# Google Cloud Authentication
GOOGLE_APPLICATION_CREDENTIALS=/path/to/your/service-account-key.json

# Infrastructure Monitoring Configuration
ENABLE_CLUSTER_MONITORING=true
ENABLE_NODE_MONITORING=true
ENABLE_BILLING_MONITORING=true
ENABLE_RESOURCE_MONITORING=true
ENABLE_ALERTING=true

# Monitoring Intervals (in seconds)
CLUSTER_CHECK_INTERVAL=300
NODE_CHECK_INTERVAL=600
BILLING_CHECK_INTERVAL=3600
RESOURCE_CHECK_INTERVAL=300

# Alert Thresholds
CPU_USAGE_THRESHOLD=80
MEMORY_USAGE_THRESHOLD=85
DISK_USAGE_THRESHOLD=90
NODE_ERROR_THRESHOLD=3
```

## 🚀 Запуск

### Запуск через Docker Compose (рекомендуется)
```bash
# Запуск всех сервисов
docker-compose up -d

# Просмотр логов
docker-compose logs -f

# Остановка
docker-compose down
```

### Запуск вручную
```bash
# Запуск Telegram бота
python bot.py

# Запуск мониторинга инфраструктуры (в отдельном терминале)
python infrastructure_monitor.py
```

## 📱 Использование бота

### Основные команды

#### Информация об инфраструктуре
- `/infrastructure` - Полный обзор инфраструктуры
- `/clusters` - Список GKE кластеров
- `/instances` - Compute instances
- `/nodes` - Информация об узлах кластеров
- `/status` - Общий статус системы

#### Управление
- `/execute <command>` - Выполнение gcloud команд
- `/scale <cluster> <location> <nodes>` - Масштабирование кластера
- `/restart <cluster> <location> <pool>` - Перезапуск node pool
- `/logs <cluster> <location> [lines]` - Получение логов

#### Анализ
- `/billing` - Информация о биллинге
- `/costs` - Анализ затрат

### Примеры использования

```bash
# Получить список кластеров
/execute container clusters list

# Масштабировать кластер до 5 узлов
/scale my-cluster us-central1 5

# Получить логи кластера
/logs my-cluster us-central1 100

# Перезапустить node pool
/restart my-cluster us-central1 default-pool
```

## 🔒 Безопасность

### Разрешенные команды
Бот выполняет только безопасные команды:
- **Чтение**: `list`, `describe`, `get-iam-policy`
- **Управление**: `resize`, `rolling-update`

### Ограничения доступа
- Настройка `ALLOWED_TELEGRAM_USERS` для ограничения доступа
- Использование Service Account с минимальными правами
- Валидация всех входящих команд

## 📊 Мониторинг и алерты

### Автоматические проверки
- **Кластеры**: Каждые 5 минут
- **Узлы**: Каждые 10 минут
- **Ресурсы**: Каждые 5 минут
- **Биллинг**: Каждый час

### Типы алертов
- 🔄 Изменение статуса кластера
- 🚨 Критические ошибки
- 📈 Изменение количества узлов
- ⚠️ Пороговые значения ресурсов
- 💳 Проблемы с биллингом

### Настройка алертов
```bash
# Отключение определенных типов мониторинга
ENABLE_CLUSTER_MONITORING=false
ENABLE_BILLING_MONITORING=false

# Настройка интервалов
CLUSTER_CHECK_INTERVAL=600  # 10 минут
NODE_CHECK_INTERVAL=1200    # 20 минут

# Пороговые значения
CPU_USAGE_THRESHOLD=70      # Предупреждение при 70% CPU
MEMORY_USAGE_THRESHOLD=80   # Предупреждение при 80% памяти
```

## 🐛 Устранение неполадок

### Частые проблемы

#### Ошибка аутентификации
```bash
# Проверка учетных данных
gcloud auth list
gcloud config list

# Обновление Application Default Credentials
gcloud auth application-default login
```

#### Ошибки API
```bash
# Проверка включенных API
gcloud services list --enabled

# Включение необходимых API
gcloud services enable container.googleapis.com
```

#### Проблемы с Telegram
```bash
# Проверка токена бота
curl "https://api.telegram.org/bot<YOUR_TOKEN>/getMe"

# Проверка chat ID
curl "https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates"
```

### Логи
```bash
# Просмотр логов бота
docker-compose logs telegram-bot

# Просмотр логов мониторинга
docker-compose logs infrastructure-monitor

# Просмотр всех логов
docker-compose logs -f
```

## 🔧 Расширение функциональности

### Добавление новых команд
1. Создайте метод в `BotHandlers` классе
2. Добавьте обработчик в `TelegramBot` класс
3. Обновите help сообщения

### Добавление новых метрик
1. Расширьте `GCloudClient` класс
2. Добавьте проверки в `InfrastructureMonitor`
3. Настройте алерты и уведомления

### Интеграция с внешними системами
- **Prometheus**: Экспорт метрик
- **Grafana**: Визуализация
- **Slack**: Дополнительные уведомления
- **Email**: Критические алерты

## 📈 Производительность

### Оптимизация
- Настройка интервалов мониторинга
- Кэширование результатов API вызовов
- Асинхронная обработка уведомлений
- Ограничение размера сообщений

### Масштабирование
- Запуск нескольких экземпляров мониторинга
- Разделение мониторинга по проектам
- Использование очередей сообщений

## 🤝 Поддержка

### Полезные ссылки
- [Google Cloud Container API](https://cloud.google.com/kubernetes-engine/docs/reference/rest)
- [Google Cloud Compute API](https://cloud.google.com/compute/docs/reference/rest)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [Python Telegram Bot](https://python-telegram-bot.readthedocs.io/)

### Сообщество
- GitHub Issues для багов
- Pull Requests для улучшений
- Документация и примеры

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. См. файл LICENSE для подробностей.

---

**Примечание**: Этот бот предназначен для мониторинга и управления инфраструктурой. Используйте с осторожностью в продакшн средах и всегда тестируйте команды перед выполнением.
