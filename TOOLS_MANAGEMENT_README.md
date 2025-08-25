# Tools Management System

Система управления инструментами для сервера Vovkes. Все инструменты развертываются и управляются через GitHub, без передачи файлов через SSH.

## 📋 Обзор

Система включает в себя:
- **L2 Networks Sync Tool** - инструмент синхронизации L2 сетей
- **Admin Dashboard** - административная панель
- **AI/ML Service** - сервис искусственного интеллекта
- **Analytics API** - API для аналитики
- **Blockchain Node** - блокчейн нода
- **Data Ingestion** - сервис сбора данных
- **Stream Processing** - потоковая обработка данных

## 🚀 Быстрый старт

### 1. Клонирование репозитория

```bash
# На сервере Vovkes
git clone <your-repo-url>
cd defimon.highfunk.uk
```

### 2. Развертывание всех инструментов

```bash
# Развернуть все инструменты
sudo ./scripts/deploy-all-tools.sh deploy

# Запустить все инструменты
sudo ./scripts/deploy-all-tools.sh start

# Проверить статус
./scripts/deploy-all-tools.sh status
```

### 3. Управление отдельными инструментами

```bash
# Установить конкретный инструмент
sudo ./scripts/manage-tools.sh install l2-networks-sync

# Запустить инструмент
./scripts/manage-tools.sh start l2-networks-sync

# Проверить статус
./scripts/manage-tools.sh status l2-networks-sync

# Показать логи
./scripts/manage-tools.sh logs l2-networks-sync
```

## 📁 Структура скриптов

### Основные скрипты управления

- **`scripts/deploy-all-tools.sh`** - автоматическое развертывание всех инструментов
- **`scripts/manage-tools.sh`** - управление отдельными инструментами
- **`scripts/start-l2-sync.sh`** - управление L2 networks sync инструментом
- **`scripts/monitor-tools-performance.sh`** - мониторинг производительности

### Скрипты мониторинга

- **`tools/l2-networks-sync/health-check.sh`** - проверка здоровья L2 sync инструмента
- **`scripts/system-monitor.sh`** - общий мониторинг системы

## 🔧 Управление инструментами

### Команды для deploy-all-tools.sh

```bash
# Развернуть все инструменты
sudo ./scripts/deploy-all-tools.sh deploy

# Запустить все инструменты
sudo ./scripts/deploy-all-tools.sh start

# Проверить статус развертывания
./scripts/deploy-all-tools.sh status

# Показать логи развертывания
./scripts/deploy-all-tools.sh logs

# Откатить конкретный инструмент
sudo ./scripts/deploy-all-tools.sh rollback l2-networks-sync

# Создать резервную копию всех инструментов
sudo ./scripts/deploy-all-tools.sh backup
```

### Команды для manage-tools.sh

```bash
# Список всех инструментов
./scripts/manage-tools.sh list

# Установить инструмент
sudo ./scripts/manage-tools.sh install l2-networks-sync

# Запустить инструмент
./scripts/manage-tools.sh start l2-networks-sync

# Остановить инструмент
./scripts/manage-tools.sh stop l2-networks-sync

# Перезапустить инструмент
./scripts/manage-tools.sh restart l2-networks-sync

# Проверить статус
./scripts/manage-tools.sh status l2-networks-sync

# Показать логи
./scripts/manage-tools.sh logs l2-networks-sync

# Обновить все инструменты из git
sudo ./scripts/manage-tools.sh update

# Показать системные ресурсы
./scripts/manage-tools.sh resources
```

### Команды для start-l2-sync.sh

```bash
# Установить и настроить L2 sync инструмент
sudo ./scripts/start-l2-sync.sh install

# Запустить сервис
sudo ./scripts/start-l2-sync.sh start

# Остановить сервис
sudo ./scripts/start-l2-sync.sh stop

# Перезапустить сервис
sudo ./scripts/start-l2-sync.sh restart

# Проверить статус
./scripts/start-l2-sync.sh status

# Показать логи
./scripts/start-l2-sync.sh logs
```

## 📊 Мониторинг производительности

### Команды для monitor-tools-performance.sh

```bash
# Сгенерировать отчет о производительности
./scripts/monitor-tools-performance.sh report

# Генерировать отчет каждые 5 минут
./scripts/monitor-tools-performance.sh report 300

# Запустить непрерывный мониторинг
./scripts/monitor-tools-performance.sh monitor

# Мониторинг с обновлением каждые 30 секунд
./scripts/monitor-tools-performance.sh monitor 30

# Показать исторические метрики для инструмента
./scripts/monitor-tools-performance.sh history l2-networks-sync

# Показать историю за последние 14 дней
./scripts/monitor-tools-performance.sh history l2-networks-sync 14

# Очистить старые метрики (старше 30 дней)
./scripts/monitor-tools-performance.sh cleanup

# Очистить метрики старше 14 дней
./scripts/monitor-tools-performance.sh cleanup 14
```

## 🏥 Проверка здоровья инструментов

### Команды для health-check.sh

```bash
# Запустить полную проверку здоровья
./tools/l2-networks-sync/health-check.sh

# Быстрая проверка статуса
./tools/l2-networks-sync/health-check.sh status

# Проверить только контейнеры
./tools/l2-networks-sync/health-check.sh containers

# Проверить только ресурсы
./tools/l2-networks-sync/health-check.sh resources

# Проверить только логи
./tools/l2-networks-sync/health-check.sh logs

# Проверить только базу данных
./tools/l2-networks-sync/health-check.sh database
```

## 🔄 Обновление инструментов

### Автоматическое обновление

```bash
# Обновить все инструменты из git репозитория
sudo ./scripts/manage-tools.sh update
```

### Ручное обновление

```bash
# На сервере
cd /opt/tools
git pull origin main

# Перезапустить обновленные инструменты
sudo ./scripts/manage-tools.sh restart l2-networks-sync
```

## 📁 Структура директорий на сервере

```
/opt/tools/                    # Основная директория инструментов
├── l2-networks-sync/         # L2 networks sync инструмент
├── admin-dashboard/          # Admin dashboard
├── ai-ml-service/            # AI/ML сервис
├── analytics-api/            # Analytics API
├── blockchain-node/          # Blockchain node
├── data-ingestion/           # Data ingestion
├── stream-processing/         # Stream processing
└── backups/                  # Резервные копии

/var/log/tools/               # Логи инструментов
├── l2-sync/                 # Логи L2 sync
└── metrics/                  # Метрики производительности

/etc/tools/                   # Конфигурация инструментов
```

## 🚨 Устранение неполадок

### Проблемы с развертыванием

1. **Проверить права доступа**
   ```bash
   sudo chmod +x scripts/*.sh
   sudo chmod +x tools/*/*.sh
   ```

2. **Проверить зависимости**
   ```bash
   # Docker
   docker --version
   docker-compose --version
   
   # Git
   git --version
   ```

3. **Проверить логи**
   ```bash
   ./scripts/manage-tools.sh logs l2-networks-sync
   journalctl -u l2_networks_sync -f
   ```

### Проблемы с производительностью

1. **Проверить системные ресурсы**
   ```bash
   ./scripts/manage-tools.sh resources
   ```

2. **Проверить здоровье инструментов**
   ```bash
   ./tools/l2-networks-sync/health-check.sh
   ```

3. **Сгенерировать отчет о производительности**
   ```bash
   ./scripts/monitor-tools-performance.sh report
   ```

## 🔒 Безопасность

- Все скрипты требуют root прав для установки и настройки
- Инструменты запускаются в изолированных Docker контейнерах
- Systemd сервисы используют ограничения безопасности
- Логи и метрики хранятся в защищенных директориях

## 📝 Логирование

### Логи инструментов

- **Systemd logs**: `journalctl -u service_name`
- **Docker logs**: `docker-compose logs`
- **Application logs**: `/var/log/tools/`

### Метрики производительности

- **Reports**: `/var/log/tools/metrics/`
- **Health checks**: `/var/log/l2-sync/health-check.log`

## 🔄 Автоматизация

### Cron задачи

```bash
# Добавить в crontab для автоматического мониторинга
# Генерировать отчет каждые 6 часов
0 */6 * * * /path/to/scripts/monitor-tools-performance.sh report

# Очищать старые метрики каждую неделю
0 0 * * 0 /path/to/scripts/monitor-tools-performance.sh cleanup 30
```

### Systemd таймеры

```bash
# Создать таймер для автоматических проверок здоровья
sudo systemctl enable l2-networks-sync.timer
sudo systemctl start l2-networks-sync.timer
```

## 📚 Дополнительные ресурсы

- [Docker Compose документация](https://docs.docker.com/compose/)
- [Systemd документация](https://systemd.io/)
- [L2 Networks Sync документация](tools/l2-networks-sync/README.md)

## 🤝 Поддержка

При возникновении проблем:

1. Проверьте логи инструмента
2. Запустите health check
3. Проверьте системные ресурсы
4. Обратитесь к документации конкретного инструмента

---

**Важно**: Все изменения в инструментах должны происходить через GitHub. Не передавайте файлы напрямую через SSH на сервер.
