# 📊 Ручная настройка дашборда в Grafana

## 🎯 Проблема
Автоматическая загрузка дашборда не работает из-за проблем с форматом JSON. Давайте настроим дашборд вручную.

## 📋 Пошаговая инструкция

### 1. Войдите в Grafana
- **URL**: http://192.168.0.153:3000
- **Логин**: `admin`
- **Пароль**: `Cal1f0rn1a@2025`

### 2. Проверьте источник данных
1. Перейдите в **Configuration** (⚙️) → **Data Sources**
2. Убедитесь, что **Prometheus** настроен и работает
3. URL должен быть: `http://prometheus-monitor:9090`

### 3. Создайте дашборд вручную

#### Вариант A: Импорт через JSON
1. Нажмите **+** (слева) → **Import**
2. Скопируйте содержимое файла `simple-dashboard.json` в поле "Import via panel json"
3. Нажмите **Load**
4. Выберите источник данных **Prometheus**
5. Нажмите **Import**

#### Вариант B: Создание с нуля
1. Нажмите **+** (слева) → **Dashboard**
2. Нажмите **Add new panel**
3. Создайте панели:

**Панель 1: Node Status**
- **Query**: `up{job="geth"}`
- **Visualization**: Stat
- **Field**: Добавьте mapping: 0→Offline (red), 1→Online (green)

**Панель 2: CPU Usage**
- **Query**: `100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
- **Visualization**: Stat
- **Unit**: Percent
- **Thresholds**: 0-70 (green), 70-90 (yellow), 90-100 (red)

**Панель 3: Memory Usage**
- **Query**: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`
- **Visualization**: Stat
- **Unit**: Percent

**Панель 4: Disk Usage**
- **Query**: `(1 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})) * 100`
- **Visualization**: Stat
- **Unit**: Percent

### 4. Сохраните дашборд
1. Нажмите **Save** (💾)
2. Введите название: **"Ethereum Node Monitoring"**
3. Добавьте теги: `ethereum`, `node`, `monitoring`
4. Нажмите **Save**

## 🔧 Проверка метрик

### Доступные метрики:
- **Ethereum Node**: `up{job="geth"}` - статус ноды
- **System CPU**: `node_cpu_seconds_total` - использование CPU
- **System Memory**: `node_memory_MemTotal_bytes` - память
- **System Disk**: `node_filesystem_size_bytes` - диск
- **Network**: `node_network_receive_bytes_total` - сетевой трафик

### Проверка Prometheus:
- **URL**: http://192.168.0.153:9091
- Проверьте, что метрики собираются

## 🚨 Устранение проблем

### Если нет данных:
1. Проверьте, что Prometheus работает: `docker ps | grep prometheus`
2. Проверьте конфигурацию Prometheus
3. Убедитесь, что метрики экспортируются

### Если дашборд не загружается:
1. Проверьте формат JSON
2. Убедитесь, что источник данных выбран правильно
3. Проверьте логи Grafana: `docker logs grafana-dashboard`

## 📊 Готовый дашборд

После настройки у вас будет дашборд с:
- ✅ Статус Ethereum ноды
- ✅ Использование CPU
- ✅ Использование памяти
- ✅ Использование диска
- ✅ Сетевой трафик

---
*Инструкция создана: 9 августа 2025*
*Статус: ✅ ГОТОВО К ИСПОЛЬЗОВАНИЮ*
