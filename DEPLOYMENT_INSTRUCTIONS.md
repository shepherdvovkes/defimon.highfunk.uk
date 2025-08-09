# Ethereum Node Deployment Instructions 🚀

## 📋 Предварительные требования

### Системные требования:
- **OS:** Linux (Ubuntu 20.04+ / Debian 11+)
- **RAM:** Минимум 16GB (рекомендуется 32GB)
- **CPU:** 4+ ядра
- **Диск:** Минимум 2TB SSD (рекомендуется 4TB+)
- **Сеть:** Стабильное интернет-соединение

### Программное обеспечение:
- **Docker:** 20.10+
- **Docker Compose:** 1.29+
- **Git:** Последняя версия

---

## 🔧 Установка и настройка

### 1. Клонирование репозитория
```bash
git clone https://github.com/shepherdvovkes/defimon.highfunk.uk.git
cd defimon.highfunk.uk
git checkout eth_full_node_lenovo
```

### 2. Настройка переменных окружения
```bash
# Скопировать пример конфигурации
cp env.infura.example .env.infura

# Отредактировать .env.infura
nano .env.infura
```

**Содержимое .env.infura:**
```
REQUEST_URL=https://mainnet.infura.io/v3/YOUR_INFURA_API_KEY
INFURA_API_KEY=YOUR_INFURA_API_KEY
CHECKPOINT_SYNC_URL=https://beaconstate-mainnet.chainsafe.io
```

### 3. Настройка JWT секретов
```bash
cd infrastructure/geth-monitoring
cp ../../.env.infura .env
```

---

## 🐳 Запуск контейнеров

### 1. Запуск всех сервисов
```bash
cd infrastructure/geth-monitoring
docker-compose --profile internal-geth up -d
```

### 2. Проверка статуса
```bash
docker-compose ps
```

### 3. Просмотр логов
```bash
# Geth
docker-compose logs -f geth

# Lighthouse
docker-compose logs -f lighthouse

# Все сервисы
docker-compose logs -f
```

---

## 📊 Мониторинг

### Доступные сервисы:

| Сервис | URL | Описание |
|--------|-----|----------|
| Grafana | http://YOUR_IP:3000 | Дашборды мониторинга |
| Prometheus | http://YOUR_IP:9091 | Метрики |
| Geth HTTP | http://YOUR_IP:8545 | Ethereum JSON-RPC |
| Geth WS | ws://YOUR_IP:8546 | WebSocket API |
| Lighthouse | http://YOUR_IP:5052 | Beacon API |
| Node Exporter | http://YOUR_IP:9100 | Системные метрики |

### Учетные данные Grafana:
- **Логин:** admin
- **Пароль:** Cal1f0rn1a@2025

---

## 🔄 Процесс синхронизации

### Этап 1: Checkpoint Sync (Lighthouse)
- Время: 5-10 минут
- Статус: Загрузка checkpoint с chainsafe.io
- Индикатор: "Loaded checkpoint block and state"

### Этап 2: Execution Sync (Geth)
- Время: 10-20 минут
- Статус: Синхронизация блоков
- Индикатор: "Syncing beacon headers"

### Этап 3: Финальная синхронизация
- Время: 15-30 минут
- Статус: Полная синхронизация
- Индикатор: "Syncing" -> "Synced"

---

## 🔍 Проверка статуса

### Проверка синхронизации Geth:
```bash
curl -X POST -H 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545
```

### Проверка статуса Lighthouse:
```bash
curl http://localhost:5052/eth/v1/node/syncing
```

### Проверка метрик Prometheus:
```bash
curl http://localhost:9091/api/v1/targets
```

---

## 🛠️ Устранение неполадок

### Проблема: JWT секрет не работает
**Решение:**
```bash
# Остановить контейнеры
docker-compose down

# Удалить старые данные
docker volume rm geth-monitoring_lighthouse_data
docker volume rm geth-monitoring_geth_data

# Перезапустить
docker-compose --profile internal-geth up -d
```

### Проблема: Lighthouse не может подключиться к Geth
**Решение:**
```bash
# Проверить, что Geth слушает на правильном порту
docker exec geth-full-node netstat -tlnp | grep 8551

# Перезапустить Geth
docker-compose restart geth
```

### Проблема: Медленная синхронизация
**Решение:**
- Увеличить лимиты Docker
- Проверить сетевое соединение
- Убедиться в достаточном количестве RAM

---

## 📈 Оптимизация производительности

### Настройки Docker:
```bash
# Увеличить лимиты памяти
docker update --memory=32g --memory-swap=64g geth-full-node
docker update --memory=16g --memory-swap=32g lighthouse-beacon
```

### Настройки Geth:
- `--cache=8192` (увеличить при наличии RAM)
- `--maxpeers=50` (настроить под сеть)

### Настройки Lighthouse:
- Автоматическая оптимизация
- Проверить логи на предупреждения

---

## 🔐 Безопасность

### Рекомендации:
1. **Файрвол:** Ограничить доступ к портам
2. **VPN:** Использовать VPN для удаленного доступа
3. **Обновления:** Регулярно обновлять контейнеры
4. **Мониторинг:** Настроить алерты в Grafana

### Портфолио:
- **8545:** HTTP API (ограничить доступ)
- **8546:** WebSocket API (ограничить доступ)
- **8551:** Engine API (только локально)
- **3000:** Grafana (защитить паролем)
- **9091:** Prometheus (ограничить доступ)

---

## 📝 Полезные команды

### Управление контейнерами:
```bash
# Остановить все
docker-compose down

# Перезапустить конкретный сервис
docker-compose restart geth

# Просмотр логов
docker-compose logs -f lighthouse

# Обновить образы
docker-compose pull
docker-compose up -d
```

### Резервное копирование:
```bash
# Создать бэкап данных
docker run --rm -v geth-monitoring_geth_data:/data -v $(pwd):/backup alpine tar czf /backup/geth-backup.tar.gz -C /data .

# Восстановить данные
docker run --rm -v geth-monitoring_geth_data:/data -v $(pwd):/backup alpine tar xzf /backup/geth-backup.tar.gz -C /data
```

---

## 🎯 Следующие шаги

1. **Дождаться завершения синхронизации**
2. **Настроить алерты в Grafana**
3. **Создать дашборды для Ethereum метрик**
4. **Настроить автоматические бэкапы**
5. **Добавить мониторинг сети**

---

*Инструкции созданы для версии конфигурации от 9 августа 2025*
