# 📊 Мониторинг Ethereum Full Node

## 📋 Обзор

Это руководство описывает систему мониторинга для Ethereum полной ноды, включающую Prometheus, Grafana и дополнительные инструменты мониторинга.

## 🎯 Компоненты мониторинга

- ✅ **Prometheus** - сбор метрик
- ✅ **Grafana** - визуализация и дашборды
- ✅ **Node Exporter** - системные метрики
- ✅ **Custom Metrics** - специфичные для Ethereum метрики
- ✅ **Алерты** - уведомления о проблемах
- ✅ **Логирование** - централизованные логи

## 🌐 Доступные интерфейсы

- **Grafana**: http://localhost:3001 (admin/Cal1f0rn1a@2025)
- **Prometheus**: http://localhost:9090
- **Node Exporter**: http://localhost:9100/metrics

## 📊 Основные метрики

### Системные метрики

```bash
# CPU использование
node_cpu_seconds_total

# Память
node_memory_MemAvailable_bytes
node_memory_MemTotal_bytes

# Диск
node_filesystem_avail_bytes
node_filesystem_size_bytes

# Сеть
node_network_receive_bytes_total
node_network_transmit_bytes_total
```

### Ethereum метрики

```bash
# Синхронизация
eth_syncing

# Блоки
eth_blockNumber

# Пирсы
eth_peerCount

# Газ
eth_gasPrice
```

### Docker метрики

```bash
# Контейнеры
container_cpu_usage_seconds_total
container_memory_usage_bytes
container_network_receive_bytes_total
container_network_transmit_bytes_total
```

## 🔧 Настройка мониторинга

### Prometheus конфигурация

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "ethereum_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - localhost:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'ethereum-node'
    static_configs:
      - targets: ['localhost:8545']
    metrics_path: '/'
    scrape_interval: 30s

  - job_name: 'docker'
    static_configs:
      - targets: ['localhost:9323']
```

### Grafana дашборды

#### Основной дашборд

```json
{
  "dashboard": {
    "title": "Ethereum Node Overview",
    "panels": [
      {
        "title": "Sync Status",
        "type": "stat",
        "targets": [
          {
            "expr": "eth_syncing",
            "legendFormat": "Syncing"
          }
        ]
      },
      {
        "title": "Block Height",
        "type": "graph",
        "targets": [
          {
            "expr": "eth_blockNumber",
            "legendFormat": "Current Block"
          }
        ]
      },
      {
        "title": "Peer Count",
        "type": "stat",
        "targets": [
          {
            "expr": "eth_peerCount",
            "legendFormat": "Peers"
          }
        ]
      }
    ]
  }
}
```

#### Системный дашборд

```json
{
  "dashboard": {
    "title": "System Resources",
    "panels": [
      {
        "title": "CPU Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "CPU %"
          }
        ]
      },
      {
        "title": "Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100)",
            "legendFormat": "Memory %"
          }
        ]
      },
      {
        "title": "Disk Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100)",
            "legendFormat": "Disk %"
          }
        ]
      }
    ]
  }
}
```

## 🚨 Алерты

### Основные алерты

```yaml
groups:
  - name: ethereum_alerts
    rules:
      - alert: NodeDown
        expr: up{job="ethereum-node"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Ethereum node is down"
          description: "Ethereum node has been down for more than 1 minute"

      - alert: NodeNotSyncing
        expr: eth_syncing == 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Node is not syncing"
          description: "Ethereum node is not syncing for more than 5 minutes"

      - alert: HighCPUUsage
        expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage"
          description: "CPU usage is above 80% for more than 5 minutes"

      - alert: HighMemoryUsage
        expr: 100 - ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100) > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage"
          description: "Memory usage is above 85% for more than 5 minutes"

      - alert: LowDiskSpace
        expr: 100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100) > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space"
          description: "Disk usage is above 90% for more than 5 minutes"

      - alert: LowPeerCount
        expr: eth_peerCount < 5
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Low peer count"
          description: "Peer count is below 5 for more than 10 minutes"
```

## 📈 Мониторинг в реальном времени

### Команды мониторинга

```bash
# Проверка статуса системы
sudo /opt/defimon/monitor-node.sh

# Непрерывный мониторинг
watch -n 30 'sudo /opt/defimon/monitor-node.sh'

# Мониторинг ресурсов
htop
iotop
iftop

# Мониторинг сети
nethogs
vnstat

# Мониторинг температуры
sensors
```

### Скрипт мониторинга

```bash
#!/bin/bash
set -euo pipefail

echo "=== DEFIMON Node Status ==="
echo "Timestamp: $(date)"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime)"

# Проверка Docker контейнеров
echo -e "\n--- Docker Containers ---"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | (sed -u 1q; sort -u)

# Использование ресурсов
echo -e "\n--- Resource Usage ---"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Статус синхронизации
echo -e "\n--- Node Sync Status ---"
if curl -fsS http://localhost:8545 >/dev/null; then
  echo "Node is responding on port 8545"
  SYNC_STATUS=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
    http://localhost:8545 | jq -r '.result')
  if [ "$SYNC_STATUS" = "false" ]; then
    echo "Node is fully synced"
  else
    echo "Node is syncing: $SYNC_STATUS"
  fi
else
  echo "Node is not responding on port 8545"
fi

# Использование диска
echo -e "\n--- Disk Usage ---"
df -h /opt/defimon

# Использование памяти
echo -e "\n--- Memory Usage ---"
free -h

# Использование CPU
echo -e "\n--- CPU Usage ---"
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1

# Последние логи
echo -e "\n--- Recent Logs (blockchain-service) ---"
(docker compose -f /opt/defimon/docker-compose.node.yml logs --tail=20 blockchain-service 2>/dev/null) || echo "No logs available"
```

## 🔍 Диагностика

### Проверка синхронизации

```bash
# Проверка статуса синхронизации
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545

# Проверка текущего блока
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545

# Проверка количества пиров
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  http://localhost:8545
```

### Проверка ресурсов

```bash
# Использование диска
df -h /opt/defimon

# Использование памяти
free -h

# Использование CPU
top -bn1 | grep "Cpu(s)"

# Температура
sensors

# Сетевые подключения
netstat -tuln | grep -E ':(8545|8546|3001|9090|8080)'
```

## 📊 Настройка дашбордов

### Импорт дашбордов в Grafana

1. Откройте Grafana: http://localhost:3001
2. Войдите с учетными данными: admin/Cal1f0rn1a@2025
3. Перейдите в Settings → Data Sources
4. Добавьте Prometheus как источник данных
5. Перейдите в Dashboards → Import
6. Импортируйте JSON файлы дашбордов

### Создание пользовательских дашбордов

```json
{
  "dashboard": {
    "title": "Custom Ethereum Dashboard",
    "panels": [
      {
        "title": "Custom Metric",
        "type": "graph",
        "targets": [
          {
            "expr": "your_custom_metric",
            "legendFormat": "Custom Metric"
          }
        ]
      }
    ]
  }
}
```

## 🚨 Настройка алертов

### Email уведомления

```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alertmanager@yourdomain.com'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'your-app-password'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
  - name: 'web.hook'
    email_configs:
      - to: 'admin@yourdomain.com'
        send_resolved: true
```

### Slack уведомления

```yaml
global:
  slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'slack-notifications'

receivers:
  - name: 'slack-notifications'
    slack_configs:
      - channel: '#alerts'
        send_resolved: true
```

## 📈 Оптимизация производительности

### Настройка Prometheus

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

storage:
  tsdb:
    retention.time: 15d
    retention.size: 50GB

scrape_configs:
  - job_name: 'ethereum-node'
    scrape_interval: 30s
    scrape_timeout: 10s
    static_configs:
      - targets: ['localhost:8545']
```

### Настройка Grafana

```ini
[server]
http_port = 3000
domain = localhost

[database]
type = sqlite3
path = /var/lib/grafana/grafana.db

[security]
admin_user = admin
admin_password = admin

[users]
allow_sign_up = false

[log]
mode = console
level = info
```

## 🔒 Безопасность мониторинга

### Настройка аутентификации

```ini
[auth.anonymous]
enabled = false

[auth.basic]
enabled = true

[security]
allow_embedding = false
cookie_secure = true
```

### Настройка файрвола

```bash
# Разрешение только локальных подключений
sudo ufw allow from 127.0.0.1 to any port 3001
sudo ufw allow from 127.0.0.1 to any port 9090
sudo ufw allow from 127.0.0.1 to any port 9100
```

## 📚 Дополнительные ресурсы

- **Prometheus документация**: https://prometheus.io/docs/
- **Grafana документация**: https://grafana.com/docs/
- **Ethereum метрики**: https://geth.ethereum.org/docs/
- **Node Exporter**: https://github.com/prometheus/node_exporter

## 🎉 Готово!

После настройки мониторинга у вас будет:

- ✅ Полный мониторинг системы
- ✅ Визуализация метрик в Grafana
- ✅ Алерты о проблемах
- ✅ Исторические данные
- ✅ Диагностические инструменты

Система мониторинга готова к использованию!
