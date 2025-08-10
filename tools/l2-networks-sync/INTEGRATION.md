# Интеграция L2 Networks Sync Tool

Этот документ описывает, как интегрировать инструмент синхронизации L2 сетей с существующей инфраструктурой проекта.

## Быстрая интеграция

### 1. Добавление в основной docker-compose.yml

Добавьте следующие сервисы в ваш основной `docker-compose.yml`:

```yaml
# Добавьте в секцию services:
l2-networks-sync:
  build: ./tools/l2-networks-sync
  container_name: l2-networks-sync
  restart: unless-stopped
  environment:
    - POSTGRES_HOST=${POSTGRES_HOST:-postgres}
    - POSTGRES_PORT=${POSTGRES_PORT:-5432}
    - POSTGRES_DB=${POSTGRES_DB:-admin_dashboard}
    - POSTGRES_USER=${POSTGRES_USER:-admin_user}
    - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-password}
    - GETH_RPC_URL=${GETH_RPC_URL:-http://geth:8545}
    - LIGHTHOUSE_RPC_URL=${LIGHTHOUSE_RPC_URL:-http://lighthouse:5052}
  volumes:
    - ./tools/l2-networks-sync/logs:/app/logs
  networks:
    - default
  depends_on:
    - postgres
  profiles:
    - tools
    - monitoring

# Опционально: автоматическая синхронизация
l2-networks-sync-cron:
  build: ./tools/l2-networks-sync
  container_name: l2-networks-sync-cron
  restart: unless-stopped
  command: >
    sh -c "
      while true; do
        node index.js sync &&
        sleep 86400
      done
    "
  environment:
    - POSTGRES_HOST=${POSTGRES_HOST:-postgres}
    - POSTGRES_PORT=${POSTGRES_PORT:-5432}
    - POSTGRES_DB=${POSTGRES_DB:-admin_dashboard}
    - POSTGRES_USER=${POSTGRES_USER:-admin_user}
    - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-password}
    - GETH_RPC_URL=${GETH_RPC_URL:-http://geth:8545}
    - LIGHTHOUSE_RPC_URL=${LIGHTHOUSE_RPC_URL:-http://lighthouse:5052}
  volumes:
    - ./tools/l2-networks-sync/logs:/app/logs
  networks:
    - default
  depends_on:
    - postgres
  profiles:
    - cron
    - monitoring
```

### 2. Обновление .env файла

Добавьте в ваш основной `.env` файл:

```bash
# L2 Networks Sync Configuration
GETH_RPC_URL=http://geth:8545
LIGHTHOUSE_RPC_URL=http://lighthouse:5052
GETH_JWT_SECRET_PATH=/path/to/jwtsecret
SYNC_INTERVAL_HOURS=24
```

### 3. Запуск с профилями

```bash
# Запуск основного инструмента
docker-compose --profile tools up -d

# Запуск с автоматической синхронизацией
docker-compose --profile tools --profile cron up -d

# Запуск всех сервисов
docker-compose --profile tools --profile cron --profile monitoring up -d
```

## Интеграция с существующими скриптами

### Добавление в init-database.sql

Добавьте содержимое файла `init-l2-networks-table.sql` в ваш основной скрипт инициализации базы данных.

### Добавление в health-checks.js

Добавьте проверку здоровья L2 сетей в ваш основной файл проверок:

```javascript
// Добавьте в существующий health-checks.js
async function checkL2NetworksHealth() {
  try {
    const db = require('./tools/l2-networks-sync/database.js');
    const result = await db.query('SELECT COUNT(*) as total FROM l2_networks');
    return {
      service: 'l2-networks',
      status: 'healthy',
      details: {
        total_networks: parseInt(result.rows[0].total)
      }
    };
  } catch (error) {
    return {
      service: 'l2-networks',
      status: 'unhealthy',
      error: error.message
    };
  }
}

// Добавьте в основной массив проверок
healthChecks.push(checkL2NetworksHealth);
```

## Интеграция с CI/CD

### GitHub Actions

Добавьте в ваш `.github/workflows/deploy.yml`:

```yaml
- name: Build L2 Networks Sync Tool
  run: |
    cd tools/l2-networks-sync
    docker build -t l2-networks-sync .
```

### GitLab CI

Добавьте в ваш `.gitlab-ci.yml`:

```yaml
build_l2_tool:
  stage: build
  script:
    - cd tools/l2-networks-sync
    - docker build -t l2-networks-sync .
```

## Мониторинг и логирование

### Добавление в Prometheus

Создайте метрики для мониторинга:

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'l2-networks-sync'
    static_configs:
      - targets: ['l2-networks-sync:3000']
    metrics_path: '/metrics'
```

### Добавление в Grafana

Создайте дашборд для мониторинга L2 сетей:

```json
{
  "dashboard": {
    "title": "L2 Networks Sync Dashboard",
    "panels": [
      {
        "title": "Total Networks",
        "type": "stat",
        "targets": [
          {
            "expr": "l2_networks_total",
            "legendFormat": "Networks"
          }
        ]
      }
    ]
  }
}
```

## Автоматизация

### Cron задачи

Добавьте в crontab сервера:

```bash
# Синхронизация каждые 6 часов
0 */6 * * * docker exec l2-networks-sync node index.js sync >> /var/log/l2-sync.log 2>&1
```

### Systemd сервис

Создайте `/etc/systemd/system/l2-networks-sync.service`:

```ini
[Unit]
Description=L2 Networks Sync Service
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/usr/bin/docker exec l2-networks-sync node index.js sync
User=root

[Install]
WantedBy=multi-user.target
```

## Безопасность

### JWT аутентификация

Убедитесь, что JWT секрет для geth ноды правильно настроен:

```bash
# Создайте JWT секрет
openssl rand -hex 32 > /path/to/jwtsecret
chmod 600 /path/to/jwtsecret
```

### Сетевая изоляция

Используйте Docker networks для изоляции:

```yaml
networks:
  l2-sync-network:
    driver: bridge
    internal: true
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

## Тестирование интеграции

### Проверка подключения

```bash
# Проверка подключения к базе данных
docker exec l2-networks-sync node index.js status

# Проверка синхронизации
docker exec l2-networks-sync node index.js sync

# Проверка списка сетей
docker exec l2-networks-sync node index.js list
```

### Проверка логов

```bash
# Просмотр логов
docker logs l2-networks-sync

# Слежение за логами
docker logs -f l2-networks-sync
```

## Устранение неполадок

### Проблемы с подключением к базе данных

1. Проверьте переменные окружения
2. Убедитесь, что PostgreSQL запущен
3. Проверьте права доступа пользователя

### Проблемы с подключением к нодам

1. Проверьте URL нод
2. Убедитесь, что ноды доступны
3. Проверьте JWT секрет

### Проблемы с Docker

1. Проверьте Docker Compose файл
2. Убедитесь, что образы собраны
3. Проверьте сетевые настройки

## Обновления

### Обновление инструмента

```bash
# Остановка сервиса
docker-compose stop l2-networks-sync

# Пересборка образа
docker-compose build l2-networks-sync

# Запуск обновленного сервиса
docker-compose up -d l2-networks-sync
```

### Обновление базы данных

```bash
# Запуск миграций
docker exec l2-networks-sync node index.js init

# Проверка статуса
docker exec l2-networks-sync node index.js status
```
