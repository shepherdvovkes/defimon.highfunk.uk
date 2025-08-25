# 🚀 Быстрый старт - Google Cloud Infrastructure Monitor Bot

## 📋 Что нужно для запуска

1. **Telegram Bot Token** - получите у @BotFather
2. **Google Cloud Project ID** - ID вашего GCP проекта
3. **Telegram Chat ID** - ID чата для уведомлений
4. **Google Cloud аутентификация** - Service Account или Application Default Credentials

## ⚡ Быстрый запуск

### 1. Клонирование и настройка
```bash
cd telegrambot

# Скопировать и настроить переменные окружения
cp env.example .env
# Отредактируйте .env файл и заполните:
# - TELEGRAM_BOT_TOKEN
# - GOOGLE_CLOUD_PROJECT_ID  
# - TELEGRAM_CHAT_ID
```

### 2. Запуск через скрипт (рекомендуется)
```bash
./start-monitoring.sh
```

### 3. Или запуск вручную
```bash
# Сборка и запуск
docker-compose up -d

# Проверка статуса
docker-compose ps
```

## 🔧 Настройка Google Cloud

### Включение API
```bash
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable billing.googleapis.com
```

### Аутентификация
```bash
# Вариант 1: Application Default Credentials
gcloud auth application-default login

# Вариант 2: Service Account
gcloud iam service-accounts create bot-monitor \
    --display-name="Bot Monitor"
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:bot-monitor@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/container.admin"
```

## 📱 Использование бота

### Основные команды
- `/start` - Начало работы
- `/infrastructure` - Обзор инфраструктуры
- `/clusters` - Список кластеров
- `/execute container clusters list` - Выполнить команду
- `/scale my-cluster us-central1 5` - Масштабировать кластер

### Примеры
```bash
# Получить список кластеров
/execute container clusters list

# Масштабировать кластер
/scale my-cluster us-central1 5

# Получить логи
/logs my-cluster us-central1 100
```

## 🐛 Устранение проблем

### Проверка логов
```bash
# Логи бота
docker-compose logs telegram-bot

# Логи мониторинга
docker-compose logs infrastructure-monitor
```

### Частые проблемы
- **Ошибка аутентификации**: `gcloud auth application-default login`
- **API не включен**: Включите необходимые API
- **Неправильный chat ID**: Проверьте через getUpdates

## 📖 Подробная документация

Полная документация: [README_INFRASTRUCTURE_MONITORING.md](README_INFRASTRUCTURE_MONITORING.md)

## 🆘 Поддержка

- Проверьте логи: `docker-compose logs -f`
- Убедитесь, что все переменные в .env заполнены
- Проверьте Google Cloud аутентификацию
- Убедитесь, что необходимые API включены

---

**Готово!** 🎉 Отправьте `/start` боту в Telegram для начала работы.
