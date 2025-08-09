# Admin Monitor App

Мобильное приложение для администратора для мониторинга Ethereum нод и системных метрик сервера.

## Возможности

- 📊 Мониторинг статуса всех нод (Ethereum, Cosmos, Polkadot и др.)
- 💻 Отслеживание системных метрик (CPU, RAM, Disk, Network)
- 📈 Графики производительности в реальном времени
- 🔔 Уведомления об алертах
- 📱 Адаптивный дизайн для мобильных устройств
- 🔄 Автоматическое обновление данных каждые 30 секунд

## Требования

- Flutter SDK 3.0.0 или выше
- Dart SDK 3.0.0 или выше
- Android Studio / VS Code
- Сервер с API для получения метрик мониторинга

## Установка

1. Клонируйте репозиторий:
```bash
git clone <repository-url>
cd admin_monitor_app
```

2. Установите зависимости:
```bash
flutter pub get
```

3. Настройте API сервер:
   - Откройте `lib/services/api_service.dart`
   - Измените `baseUrl` на IP адрес вашего сервера
   - Убедитесь, что API endpoints доступны

4. Сгенерируйте код для JSON сериализации:
```bash
flutter packages pub run build_runner build
```

5. Запустите приложение:
```bash
flutter run
```

## Структура проекта

```
lib/
├── main.dart                 # Главный файл приложения
├── models/                   # Модели данных
│   ├── node_status.dart     # Статус ноды
│   └── system_metrics.dart  # Системные метрики
├── services/                # Сервисы
│   ├── api_service.dart     # API клиент
│   └── monitoring_provider.dart # Провайдер состояния
├── screens/                 # Экраны приложения
│   ├── dashboard_screen.dart    # Главный дашборд
│   ├── node_details_screen.dart # Детали ноды
│   └── system_details_screen.dart # Системные детали
└── widgets/                 # Виджеты
    ├── node_status_card.dart    # Карточка статуса ноды
    ├── system_metrics_card.dart # Карточка системных метрик
    ├── stats_overview.dart      # Обзор статистики
    └── alerts_widget.dart       # Виджет алертов
```

## API Endpoints

Приложение ожидает следующие API endpoints:

### GET /api/nodes/status
Возвращает статус всех нод:
```json
[
  {
    "nodeId": "ethereum-mainnet",
    "nodeType": "ethereum",
    "status": "running",
    "isOnline": true,
    "currentBlock": 18500000,
    "latestBlock": 18500000,
    "syncProgress": 100.0,
    "peers": 25,
    "cpuUsage": 45.2,
    "memoryUsage": 67.8,
    "diskUsage": 23.1,
    "lastUpdate": "2024-01-15T10:30:00Z"
  }
]
```

### GET /api/system/metrics
Возвращает системные метрики:
```json
{
  "cpuUsage": 45.2,
  "memoryUsage": 67.8,
  "diskUsage": 23.1,
  "networkIn": 1024000,
  "networkOut": 512000,
  "temperature": 65.5,
  "uptime": 86400,
  "disks": [
    {
      "device": "/dev/sda1",
      "mountPoint": "/",
      "totalSpace": 1000000000000,
      "usedSpace": 230000000000,
      "availableSpace": 770000000000,
      "usagePercentage": 23.0
    }
  ],
  "networkInterfaces": [
    {
      "name": "eth0",
      "ipAddress": "192.168.1.100",
      "bytesIn": 1024000,
      "bytesOut": 512000,
      "isUp": true
    }
  ],
  "lastUpdate": "2024-01-15T10:30:00Z"
}
```

### GET /api/nodes/{nodeId}
Возвращает детальную информацию о конкретной ноде.

### GET /api/nodes/{nodeId}/history?metric={metric}&hours={hours}
Возвращает исторические данные для графиков.

### GET /api/alerts
Возвращает список алертов:
```json
[
  {
    "severity": "warning",
    "message": "High CPU usage on ethereum-mainnet",
    "timestamp": "2024-01-15T10:25:00Z"
  }
]
```

## Настройка сервера

Для работы приложения необходимо настроить API сервер, который будет предоставлять метрики мониторинга. Рекомендуется использовать:

- Prometheus для сбора метрик
- Grafana для визуализации
- Node Exporter для системных метрик
- Geth Exporter для метрик Ethereum ноды

## Сборка для продакшена

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Лицензия

MIT License

## Поддержка

Для получения поддержки создайте issue в репозитории проекта.
