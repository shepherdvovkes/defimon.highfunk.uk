# 🚀 Ethereum Full Node Optimization Guide

## 📋 Обзор

Это руководство описывает специальные настройки и оптимизации для полной Ethereum ноды, необходимые для эффективной работы.

## 🎯 Специальные требования для полной ноды

### Системные требования
- **RAM**: 16GB+ (рекомендуется 32GB)
- **CPU**: 8+ ядер (рекомендуется 16+)
- **Диск**: 2TB+ SSD (рекомендуется NVMe)
- **Сеть**: Высокоскоростное соединение (100Mbps+)

### Временные требования
- **Первоначальная синхронизация**: 1-2 недели
- **Ежедневная синхронизация**: Непрерывно
- **Обновления**: Еженедельно

## 🔧 Специальные настройки системы

### Оптимизация памяти
```bash
# Настройка swappiness для Ethereum
echo 'vm.swappiness=10' >> /etc/sysctl.conf
echo 'vm.dirty_ratio=15' >> /etc/sysctl.conf
echo 'vm.dirty_background_ratio=5' >> /etc/sysctl.conf
echo 'vm.max_map_count=262144' >> /etc/sysctl.conf
```

### Оптимизация сети
```bash
# Настройки TCP для высокой пропускной способности
echo 'net.core.rmem_max=134217728' >> /etc/sysctl.conf
echo 'net.core.wmem_max=134217728' >> /etc/sysctl.conf
echo 'net.core.rmem_default=67108864' >> /etc/sysctl.conf
echo 'net.core.wmem_default=67108864' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_rmem=4096 87380 67108864' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem=4096 65536 67108864' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf
echo 'net.core.netdev_max_backlog=5000' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_max_syn_backlog=65536' >> /etc/sysctl.conf
```

### Оптимизация файловой системы
```bash
# Настройки для больших файлов
echo 'fs.file-max=2097152' >> /etc/sysctl.conf
echo 'fs.nr_open=2097152' >> /etc/sysctl.conf
```

### Настройки для SSD
```bash
# Дополнительные настройки для SSD
echo 'vm.dirty_ratio=10' >> /etc/sysctl.conf
echo 'vm.dirty_background_ratio=3' >> /etc/sysctl.conf
```

## 🐳 Docker оптимизации

### Ограничения ресурсов
```yaml
deploy:
  resources:
    limits:
      memory: 12G
      cpus: '6.0'
    reservations:
      memory: 6G
      cpus: '3.0'
```

### Системные лимиты
```yaml
ulimits:
  nofile:
    soft: 65536
    hard: 65536
```

### Системные настройки
```yaml
sysctls:
  - net.core.rmem_max=134217728
  - net.core.wmem_max=134217728
  - net.core.rmem_default=67108864
  - net.core.wmem_default=67108864
  - vm.max_map_count=262144
```

## ⚙️ Geth конфигурация

### Основные параметры
```toml
[Eth]
SyncMode = "full"
Cache = 8192
DatabaseCache = 4096
TrieCache = 256
SnapshotCache = 256
StateCache = 256
```

### Сетевые настройки
```toml
[Node]
MaxPeers = 50
HTTPPort = 8545
WSPort = 8546
P2P = 30303
HTTPEnabled = true
WSEnabled = true
HTTPCors = ["*"]
HTTPVirtualHosts = ["*"]
HTTPModules = ["eth", "net", "web3", "debug", "txpool"]
WSModules = ["eth", "net", "web3", "debug", "txpool"]
```

### P2P настройки
```toml
[Node.P2P]
MaxPeers = 50
NAT = "any"
DiscoveryV5 = true
LightClient = false
```

### Метрики
```toml
[Metrics]
Enabled = true
HTTP = ":6060"
HTTPCors = ["*"]
```

## 📊 Мониторинг производительности

### Ключевые метрики
- **Синхронизация**: Скорость загрузки блоков
- **Память**: Использование RAM и кэша
- **Диск**: Скорость записи/чтения
- **Сеть**: Количество пиров и пропускная способность
- **CPU**: Загрузка процессора

### Команды мониторинга
```bash
# Проверка синхронизации
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545

# Проверка пиров
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  http://localhost:8545

# Проверка использования памяти
docker stats defimon-blockchain-service

# Проверка дискового пространства
df -h /data/ethereum
```

## 🔍 Диагностика проблем

### Проблемы с синхронизацией
```bash
# Проверка логов Geth
docker logs defimon-blockchain-service | grep -i sync

# Проверка сетевых подключений
netstat -tuln | grep 30303

# Проверка пиров
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
  http://localhost:8545
```

### Проблемы с памятью
```bash
# Проверка использования памяти
free -h
docker stats --no-stream defimon-blockchain-service

# Проверка кэша
docker exec defimon-blockchain-service geth --exec "eth.getBlock('latest')" attach
```

### Проблемы с диском
```bash
# Проверка свободного места
df -h /data/ethereum

# Проверка скорости диска
dd if=/dev/zero of=/data/ethereum/test bs=1M count=1000

# Проверка фрагментации (для HDD)
sudo e2fsck -f /dev/sdX
```

## 🚀 Оптимизация производительности

### Для высокопроизводительных систем
```bash
# Увеличение кэша для систем с 32GB+ RAM
CACHE_SIZE=16384
DATABASE_CACHE=8192
TRIE_CACHE=512
SNAPSHOT_CACHE=512
STATE_CACHE=512
```

### Для SSD систем
```bash
# Дополнительные настройки для SSD
--database.ancient /data/ethereum/chaindata/ancient
--cache 12288
```

### Для сетевых оптимизаций
```bash
# Настройки для высокоскоростного интернета
--maxpeers 100
--discovery.v5
--nat any
```

## 🔒 Безопасность

### Файрвол настройки
```bash
# Разрешение только необходимых портов
ufw allow 30303/tcp
ufw allow 30303/udp
ufw allow 8545/tcp
ufw allow 8546/tcp
ufw deny 8545/tcp from any to any
ufw deny 8546/tcp from any to any
```

### RPC безопасность
```bash
# Ограничение доступа к RPC
--http.addr 127.0.0.1
--ws.addr 127.0.0.1
--http.corsdomain "http://localhost:3000"
```

## 📈 Рекомендации по масштабированию

### Горизонтальное масштабирование
- Использование нескольких нод для балансировки нагрузки
- Разделение чтения и записи между нодами
- Использование кластеров для высокой доступности

### Вертикальное масштабирование
- Увеличение RAM до 64GB+
- Использование NVMe дисков
- Увеличение CPU до 32+ ядер

## 🎯 Заключение

Полная Ethereum нода требует значительных ресурсов и специальных настроек. Следуйте этим рекомендациям для оптимальной производительности и стабильности.

### Ключевые моменты:
1. **Достаточно ресурсов** - минимум 16GB RAM, 2TB SSD
2. **Оптимизация системы** - специальные настройки ядра
3. **Мониторинг** - постоянное отслеживание метрик
4. **Безопасность** - правильная настройка файрвола
5. **Резервное копирование** - регулярные бэкапы данных

Следуя этим рекомендациям, ваша полная Ethereum нода будет работать стабильно и эффективно! 🚀
