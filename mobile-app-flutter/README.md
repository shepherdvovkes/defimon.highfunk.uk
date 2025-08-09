# Mobile App Flutter - Admin Monitor

Мобильное приложение для администратора системы мониторинга блокчейн нод.

## Структура проекта

```
mobile-app-flutter/
├── admin_monitor_app/          # Основное приложение администратора
│   ├── lib/                   # Исходный код Flutter
│   ├── assets/                # Ресурсы приложения
│   ├── api_server.py          # API сервер для данных мониторинга
│   ├── requirements.txt       # Зависимости Python
│   ├── start_api_server.sh    # Скрипт запуска API сервера
│   └── README.md              # Документация приложения
└── README.md                  # Этот файл
```

## Быстрый старт

### 1. Запуск API сервера

```bash
cd admin_monitor_app
./start_api_server.sh
```

API сервер будет доступен по адресу: http://localhost:3000

### 2. Настройка Flutter приложения

```bash
cd admin_monitor_app
flutter pub get
flutter packages pub run build_runner build
```

### 3. Запуск приложения

```bash
flutter run
```

## Возможности

### 📊 Мониторинг нод
- Ethereum (Geth)
- Lighthouse (Beacon Chain)
- Cosmos
- Polkadot
- Другие блокчейн ноды

### 💻 Системные метрики
- CPU использование
- Память (RAM)
- Дисковое пространство
- Сетевая активность
- Температура
- Время работы системы

### 📈 Визуализация
- Графики производительности
- Статус нод в реальном времени
- Алерты и уведомления
- Детальная информация о каждой ноде

### 🔄 Автоматическое обновление
- Обновление данных каждые 30 секунд
- Pull-to-refresh
- Индикаторы загрузки

## API Endpoints

| Endpoint | Описание |
|----------|----------|
| `GET /api/nodes/status` | Статус всех нод |
| `GET /api/system/metrics` | Системные метрики |
| `GET /api/nodes/{id}` | Детали конкретной ноды |
| `GET /api/nodes/{id}/history` | Исторические данные |
| `GET /api/alerts` | Алерты системы |
| `GET /health` | Проверка здоровья API |

## Требования

### Для API сервера
- Python 3.7+
- Flask
- psutil
- requests

### Для Flutter приложения
- Flutter SDK 3.0.0+
- Dart SDK 3.0.0+
- Android Studio / VS Code

## Разработка

### Добавление новой ноды

1. Добавьте функцию получения статуса в `api_server.py`
2. Обновите модель `NodeStatus` если нужно
3. Добавьте иконку и стили для нового типа ноды

### Кастомизация метрик

1. Измените функцию `get_system_metrics()` в API сервере
2. Обновите модель `SystemMetrics` если нужно
3. Адаптируйте UI для отображения новых метрик

## Развертывание

### Продакшн сборка

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Docker развертывание API сервера

```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY api_server.py .
EXPOSE 3000
CMD ["python", "api_server.py"]
```

## Безопасность

- API сервер должен быть защищен в продакшене
- Используйте HTTPS для передачи данных
- Добавьте аутентификацию при необходимости
- Ограничьте доступ к API по IP адресам

## Поддержка

Для получения поддержки:
1. Проверьте документацию в папке `admin_monitor_app/`
2. Создайте issue в репозитории
3. Обратитесь к разработчикам

## Лицензия

MIT License
