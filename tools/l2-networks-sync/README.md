# L2 Networks Sync Tool

Инструмент для синхронизации списка сетей, построенных поверх Ethereum (L2 сети), с нодами geth и lighthouse, развернутыми на сервере Vovkes.

## Возможности

- 🔄 Автоматическая синхронизация с geth и lighthouse нодами
- 📊 Хранение информации о сетях в PostgreSQL базе данных
- 🔍 Поиск по названию сети
- 📄 Пагинация результатов
- 📱 Текстовый интерфейс без графики
- 🚀 Поддержка известных L2 сетей (Arbitrum, Optimism, Base, zkSync и др.)

## Установка

1. Перейдите в папку инструмента:
```bash
cd tools/l2-networks-sync
```

2. Установите зависимости:
```bash
npm install
```

3. Скопируйте файл конфигурации:
```bash
cp env.example .env
```

4. Отредактируйте `.env` файл с вашими настройками:
```bash
# Database Configuration
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=admin_dashboard
POSTGRES_USER=admin_user
POSTGRES_PASSWORD=password
POSTGRES_SSL=false

# Node Configuration
GETH_RPC_URL=http://localhost:8545
LIGHTHOUSE_RPC_URL=http://localhost:5052
GETH_JWT_SECRET_PATH=/path/to/jwtsecret
```

## Использование

### Инициализация базы данных

```bash
npm run init
# или
node index.js init
```

### Синхронизация сетей

```bash
npm run sync
# или
node index.js sync
```

Опции:
- `-f, --force` - Принудительная синхронизация
- `-v, --verbose` - Подробный вывод

### Просмотр списка сетей

```bash
npm run list
# или
node index.js list
```

Опции:
- `-p, --page <number>` - Номер страницы (по умолчанию: 1)
- `-l, --limit <number>` - Количество элементов на странице (по умолчанию: 20)
- `-s, --search <term>` - Поиск по названию
- `--raw` - Сырой JSON вывод

### Поиск сетей

```bash
npm run search <term>
# или
node index.js search <term>
```

Опции:
- `-p, --page <number>` - Номер страницы
- `-l, --limit <number>` - Количество элементов на странице
- `--raw` - Сырой JSON вывод

### Проверка статуса

```bash
npm run status
# или
node index.js status
```

## Структура базы данных

Инструмент создает таблицу `l2_networks` со следующими полями:

- `id` - Уникальный идентификатор
- `name` - Название сети
- `chain_id` - ID цепочки (уникальный)
- `network_type` - Тип сети (L1/L2)
- `rpc_url` - URL RPC эндпоинта
- `explorer_url` - URL блокчейн эксплорера
- `native_currency` - Нативная валюта
- `block_time` - Время блока в секундах
- `is_active` - Активна ли сеть
- `last_block_number` - Номер последнего блока
- `last_sync_time` - Время последней синхронизации
- `metadata` - Дополнительные метаданные (JSON)
- `source` - Источник данных
- `created_at` - Время создания записи
- `updated_at` - Время последнего обновления

## Поддерживаемые сети

### L1 Сети
- Ethereum Mainnet (geth)
- Ethereum Beacon Chain (lighthouse)

### L2 Сети
- Arbitrum One
- Optimism
- Base
- zkSync Era
- Polygon zkEVM
- Scroll
- Mantle
- Linea

## Интеграция с существующей инфраструктурой

Инструмент интегрируется с существующей базой данных `admin_dashboard` и может быть добавлен в:

- Docker Compose файлы
- Kubernetes манифесты
- CI/CD пайплайны
- Cron задачи для автоматической синхронизации

## Автоматизация

Для автоматической синхронизации добавьте в cron:

```bash
# Синхронизация каждые 6 часов
0 */6 * * * cd /path/to/tools/l2-networks-sync && node index.js sync >> /var/log/l2-sync.log 2>&1
```

## Логирование

Инструмент выводит логи в консоль. Для продакшена рекомендуется перенаправить вывод в файл или использовать системный логгер.

## Устранение неполадок

### Ошибка подключения к базе данных
- Проверьте настройки в `.env` файле
- Убедитесь, что PostgreSQL запущен
- Проверьте права доступа пользователя

### Ошибка подключения к нодам
- Проверьте URL нод в `.env` файле
- Убедитесь, что ноды доступны
- Проверьте JWT секрет для geth

### Пустой список сетей
- Запустите `npm run init` для создания таблиц
- Запустите `npm run sync` для синхронизации
- Проверьте логи на наличие ошибок

## Разработка

### Структура проекта
```
l2-networks-sync/
├── index.js          # Основной CLI интерфейс
├── database.js       # Работа с базой данных
├── node-sync.js      # Синхронизация с нодами
├── package.json      # Зависимости и скрипты
├── env.example       # Пример конфигурации
└── README.md         # Документация
```

### Добавление новых сетей
Для добавления новых сетей отредактируйте массив `knownNetworks` в файле `node-sync.js`.

### Тестирование
```bash
npm test
```

## Лицензия

MIT
