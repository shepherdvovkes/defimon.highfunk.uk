# DEFIMON Admin Dashboard

Административный интерфейс для мониторинга всех микросервисов в системе DEFIMON.

## Возможности

- **Мониторинг в реальном времени**: Отслеживание статуса всех сервисов
- **Визуализация**: Графики производительности и статистики
- **Логирование**: Просмотр и экспорт системных логов
- **WebSocket**: Обновления в реальном времени
- **Адаптивный дизайн**: Работает на всех устройствах

## Мониторируемые сервисы

- **API Gateway** (Kong) - порт 8001
- **Analytics API** - порт 8002
- **AI/ML Service** - порт 8001
- **Blockchain Node** - порт 8545
- **PostgreSQL** - порт 5432
- **ClickHouse** - порт 8123
- **Redis** - порт 6379
- **Kafka** - порт 9092
- **Prometheus** - порт 9090
- **Grafana** - порт 3001

## Запуск

### Локально

```bash
cd services/admin-dashboard
npm install
npm start
```

### В Docker

```bash
cd infrastructure
docker-compose up admin-dashboard
```

## Доступ

После запуска дашборд будет доступен по адресу:
- **Локально**: http://localhost:8080
- **Через API Gateway**: http://localhost:8000/admin

## API Endpoints

- `GET /api/health` - Статус всех сервисов
- `GET /api/services` - Список конфигураций сервисов
- `GET /api/metrics` - Метрики Prometheus

## WebSocket Events

- `health-update` - Обновление статуса сервисов
- `request-health` - Запрос обновления статуса

## Структура проекта

```
admin-dashboard/
├── Dockerfile
├── package.json
├── server.js          # Основной сервер
├── public/
│   ├── index.html     # Главная страница
│   └── app.js         # Клиентский JavaScript
└── README.md
```

## Конфигурация

Основные настройки в `server.js`:

```javascript
const services = {
  'service-name': { 
    port: 8080, 
    health: '/health' 
  }
};
```

## Разработка

Для разработки с автоматической перезагрузкой:

```bash
npm run dev
```

## Безопасность

- Все запросы проходят через API Gateway
- Используется CORS для защиты
- Helmet для безопасности HTTP заголовков
- Rate limiting для защиты от DDoS
