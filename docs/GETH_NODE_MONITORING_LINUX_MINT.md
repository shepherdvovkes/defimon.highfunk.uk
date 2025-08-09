# Развертывание полной ноды Geth с мониторингом на Linux Mint

Этот документ описывает, как развернуть полную ноду Ethereum (Geth) с системой мониторинга (Prometheus + Grafana) на Linux Mint с помощью Docker.

## Требования

- **ОС**: Linux Mint 20 или новее
- **Процессор**: 4+ ядер
- **ОЗУ**: 16+ ГБ
- **Диск**: 2+ ТБ свободного места (SSD рекомендуется)
- **Интернет**: Стабильное и быстрое подключение

## 1. Клонирование репозитория

```bash
git clone https://github.com/your-repo/defimon.highfunk.uk.git
cd defimon.highfunk.uk
```

## 2. Запуск скрипта развертывания

Для запуска полной ноды Geth и системы мониторинга выполните следующую команду:

```bash
chmod +x scripts/deploy-geth-monitoring-mint.sh
./scripts/deploy-geth-monitoring-mint.sh
```

Скрипт выполнит следующие действия:

1.  **Проверит и установит Docker и Docker Compose**, если они отсутствуют.
2.  **Создаст необходимые директории** для хранения данных Geth.
3.  **Запустит Docker контейнеры**, определенные в `infrastructure/geth-monitoring/docker-compose.yml`:
    *   **Geth**: полная нода Ethereum.
    *   **Prometheus**: для сбора метрик с Geth.
    *   **Grafana**: для визуализации метрик.

## 3. Проверка статуса

После запуска скрипта, вы можете проверить статус контейнеров:

```bash
docker ps
```

Вы должны увидеть три запущенных контейнера: `geth-full-node`, `prometheus-monitor`, `grafana-dashboard`.

## 4. Доступ к сервисам

- **Geth RPC**: `http://localhost:8545`
- **Geth WebSocket**: `ws://localhost:8546`
- **Prometheus**: `http://localhost:9090`
- **Grafana**: `http://localhost:3000`
  - **Логин**: `admin`
  - **Пароль**: `Cal1f0rn1a@2025`

## 5. Мониторинг в Grafana

1.  **Откройте Grafana** в вашем браузере: `http://localhost:3000`.
2.  **Войдите**, используя `admin`/`Cal1f0rn1a@2025`.
3.  **Добавьте Prometheus** как источник данных:
    *   **Configuration** (шестеренка) -> **Data Sources**.
    *   **Add data source** -> **Prometheus**.
    *   **URL**: `http://prometheus:9090`.
    *   **Save & Test**.
4.  **Импортируйте дашборд** для Geth. Вы можете использовать готовый дашборд, например [Geth Dashboard](https://grafana.com/grafana/dashboards/9974).
    *   **+** (слева) -> **Import**.
    *   Вставьте ID `9974` и нажмите **Load**.
    *   Выберите ваш источник данных Prometheus.
    *   **Import**.

Теперь у вас будет полноценный дашборд для мониторинга вашей Geth ноды.
