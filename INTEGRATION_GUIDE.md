# Интеграция инструмента L2 сетей в админ-дашборд

Это руководство описывает, как интегрировать инструмент синхронизации L2 сетей в существующий админ-дашборд DEFIMON.

## Обзор интеграции

Инструмент L2 сетей интегрируется в админ-дашборд как:
- Отдельная вкладка "Tools" в главном меню
- API эндпоинты для управления L2 сетями
- База данных PostgreSQL для хранения информации о сетях
- Frontend интерфейс для управления и мониторинга

## Структура интеграции

```
services/admin-dashboard/
├── config/
│   └── database.js          # Конфигурация PostgreSQL
├── routes/
│   └── l2-networks.js       # API маршруты для L2 сетей
├── scripts/
│   └── init-l2-networks.js  # Скрипт инициализации БД
├── server.js                 # Основной сервер с маршрутами
└── package.json              # Зависимости

frontend/app/
├── tools/
│   ├── page.tsx             # Страница инструментов
│   └── components/
│       └── NetworkModal.tsx # Модальное окно для сетей
└── page.tsx                 # Главная страница с навигацией
```

## Установка и настройка

### 1. Установка зависимостей

В папке `services/admin-dashboard`:
```bash
npm install pg dotenv
```

### 2. Настройка базы данных

Создайте файл `.env` в папке `services/admin-dashboard`:
```bash
# Database Configuration
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=admin_dashboard
POSTGRES_USER=admin_user
POSTGRES_PASSWORD=password
POSTGRES_SSL=false

# Server Configuration
PORT=8080
NODE_ENV=development
```

### 3. Инициализация базы данных

Запустите скрипт инициализации:
```bash
cd services/admin-dashboard
npm run init-l2-networks
```

Этот скрипт:
- Создает таблицу `l2_networks`
- Создает индексы для производительности
- Добавляет начальные данные о известных L2 сетях
- Создает представления для статистики

### 4. Запуск админ-дашборда

```bash
cd services/admin-dashboard
npm run dev
```

## API эндпоинты

### Получение списка L2 сетей
```
GET /api/l2-networks?page=1&limit=20&search=arbitrum&network_type=L2
```

### Получение сети по ID
```
GET /api/l2-networks/{id}
```

### Создание новой сети
```
POST /api/l2-networks
Content-Type: application/json

{
  "name": "New Network",
  "chain_id": 12345,
  "network_type": "L2",
  "rpc_url": "https://rpc.example.com",
  "explorer_url": "https://explorer.example.com",
  "native_currency": "ETH",
  "block_time": 12,
  "is_active": true
}
```

### Обновление сети
```
PUT /api/l2-networks/{id}
Content-Type: application/json

{
  "name": "Updated Network Name",
  "is_active": false
}
```

### Удаление сети
```
DELETE /api/l2-networks/{id}
```

### Запуск синхронизации
```
POST /api/l2-networks/sync
Content-Type: application/json

{
  "force": true
}
```

### Статистика
```
GET /api/l2-networks/stats/summary
GET /api/l2-networks/stats/sync-activity
```

## Frontend интеграция

### Навигация

В главном меню добавлена ссылка "Tools", которая ведет на страницу `/tools`.

### Страница инструментов

Страница `/tools` содержит:
- Вкладку "L2 Networks" для управления сетями
- Таблицу со списком всех сетей
- Поиск и фильтрацию
- Пагинацию результатов
- Кнопки для добавления, редактирования и удаления сетей
- Кнопку "Sync Networks" для запуска синхронизации

### Модальное окно

Модальное окно для добавления/редактирования сетей включает:
- Все поля из базы данных
- Валидацию обязательных полей
- Обработку ошибок
- Автоматическое обновление списка после сохранения

## База данных

### Таблица l2_networks

```sql
CREATE TABLE l2_networks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    chain_id BIGINT UNIQUE NOT NULL,
    network_type VARCHAR(50) NOT NULL DEFAULT 'L2',
    rpc_url TEXT,
    explorer_url TEXT,
    native_currency VARCHAR(100),
    block_time INTEGER,
    is_active BOOLEAN DEFAULT true,
    last_block_number BIGINT,
    last_sync_time TIMESTAMP WITH TIME ZONE,
    metadata JSONB,
    source VARCHAR(50) NOT NULL DEFAULT 'manual',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Представления

- `l2_networks_summary` - сводка по типам сетей
- `l2_networks_sync_activity` - активность синхронизации

### Индексы

Созданы индексы для:
- `name` - поиск по названию
- `chain_id` - уникальный ID цепочки
- `network_type` - фильтрация по типу
- `is_active` - фильтрация по статусу
- `source` - источник данных
- `last_sync_time` - время последней синхронизации

## Автоматизация

### Cron задачи

Для автоматической синхронизации добавьте в cron:
```bash
# Синхронизация каждые 6 часов
0 */6 * * * cd /path/to/tools/l2-networks-sync && node index.js sync >> /var/log/l2-sync.log 2>&1
```

### Docker интеграция

Инструмент может быть интегрирован в Docker Compose:
```yaml
services:
  l2-sync:
    build: ./tools/l2-networks-sync
    environment:
      - POSTGRES_HOST=postgres
      - POSTGRES_DB=admin_dashboard
    depends_on:
      - postgres
    volumes:
      - ./logs:/var/log
```

## Мониторинг и логирование

### Health checks

API предоставляет эндпоинты для проверки состояния:
- `/api/health` - общее состояние сервиса
- `/api/l2-networks/stats/summary` - статистика сетей

### Логирование

Все операции логируются в консоль. Для продакшена рекомендуется:
- Перенаправить логи в файл
- Использовать системный логгер (syslog)
- Интегрировать с ELK стеком

## Безопасность

### CORS

Настроен CORS для разрешения запросов с frontend.

### Валидация

Все входные данные валидируются:
- Обязательные поля проверяются
- Типы данных валидируются
- SQL инъекции предотвращаются через параметризованные запросы

### Аутентификация

Для продакшена рекомендуется добавить:
- JWT токены
- API ключи
- Rate limiting
- IP белые списки

## Тестирование

### API тесты

```bash
# Тест получения списка сетей
curl http://localhost:8080/api/l2-networks

# Тест создания сети
curl -X POST http://localhost:8080/api/l2-networks \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Network","chain_id":99999}'
```

### Frontend тесты

```bash
cd frontend
npm run build
npm run start
```

Откройте http://localhost:3000/tools для проверки интерфейса.

## Устранение неполадок

### Ошибки подключения к базе данных

1. Проверьте настройки в `.env` файле
2. Убедитесь, что PostgreSQL запущен
3. Проверьте права доступа пользователя
4. Проверьте сетевые настройки

### Пустой список сетей

1. Запустите `npm run init-l2-networks`
2. Проверьте логи на наличие ошибок
3. Убедитесь, что таблица создана

### Ошибки frontend

1. Проверьте консоль браузера
2. Убедитесь, что API доступен
3. Проверьте CORS настройки
4. Проверьте переменные окружения

## Расширение функциональности

### Новые поля

Для добавления новых полей:
1. Обновите SQL схему
2. Добавьте поля в API
3. Обновите frontend формы
4. Обновите типы TypeScript

### Новые типы сетей

Для добавления новых типов:
1. Обновите enum в базе данных
2. Добавьте опции в frontend
3. Обновите валидацию

### Интеграция с другими сервисами

Инструмент может быть интегрирован с:
- Prometheus для метрик
- Grafana для дашбордов
- AlertManager для уведомлений
- CI/CD пайплайнами

## Заключение

Интеграция инструмента L2 сетей в админ-дашборд предоставляет:
- Централизованное управление сетями
- API для интеграции с другими сервисами
- Современный web интерфейс
- Автоматизацию синхронизации
- Мониторинг и статистику

Это создает основу для расширенного управления блокчейн инфраструктурой в рамках экосистемы DEFIMON.
