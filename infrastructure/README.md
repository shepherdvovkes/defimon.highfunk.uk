# DEFIMON Infrastructure Architecture

Этот репозиторий содержит инфраструктуру для платформы DEFIMON, организованную в три пула для оптимального распределения ресурсов и масштабируемости.

## 🏗️ Архитектура пулов

### 1. **Infrastructure Pool** - Google Cloud Platform
- **Назначение**: Ethereum ноды (Geth + Lighthouse), блокчейн инфраструктура
- **Провайдер**: Google Cloud Platform (GKE + VM instances)
- **Ресурсы**: Высокопроизводительные серверы для блокчейн синхронизации
- **Хранение**: 2TB+ для блокчейн данных

### 2. **Analytics Pool** - Hetzner Cloud
- **Назначение**: Аналитические API, обработка данных, базы данных
- **Провайдер**: Hetzner Cloud (Kubernetes)
- **Ресурсы**: Оптимизированные для аналитики и хранения данных
- **Хранение**: PostgreSQL + ClickHouse + Redis

### 3. **ML Pool** - TBD
- **Назначение**: Машинное обучение, предсказания, ML модели
- **Провайдер**: Пока не выбран
- **Ресурсы**: GPU для обучения, CPU для инференса
- **Хранение**: Модели, эксперименты, feature store

## 📁 Структура репозитория

```
infrastructure/
├── infrastructure-pool/          # Google Cloud Platform
│   ├── gke/                     # Kubernetes конфигурации
│   ├── vm-instances/            # VM инстансы
│   ├── monitoring/              # Prometheus + Grafana
│   ├── storage/                 # Persistent Disks
│   └── networking/              # VPC, Load Balancers
├── analytics-pool/              # Hetzner Cloud
│   ├── kubernetes/              # K8s манифесты
│   ├── services/                # Конфигурации сервисов
│   ├── databases/               # Схемы БД
│   ├── monitoring/              # Мониторинг
│   └── deployment/              # Скрипты развертывания
└── ml-pool/                     # Machine Learning (TBD)
    ├── kubernetes/              # K8s манифесты
    ├── services/                # ML сервисы
    ├── models/                  # Архитектуры моделей
    ├── training/                # Pipeline обучения
    └── deployment/              # Скрипты развертывания
```

## 🚀 Быстрый старт

### Infrastructure Pool (GCP)
```bash
# GKE развертывание
cd infrastructure/infrastructure-pool/gke
./scripts/GKE/deploy-gke-ethereum.sh

# VM развертывание
cd infrastructure/infrastructure-pool/vm-instances
./scripts/deploy-ethereum-gcp-production.sh
```

### Analytics Pool (Hetzner)
```bash
# Подключение к Hetzner серверу
ssh vovkes@kraken.highfunk.uk

# Создание кластера
cd infrastructure/analytics-pool/deployment
./create-analytics-cluster.sh

# Развертывание сервисов
kubectl apply -f ../kubernetes/
```

### ML Pool (TBD)
```bash
# Пока не реализовано
# Выбор провайдера в процессе
```

## 🔧 Конфигурация

### Переменные окружения
Создайте `.env` файл в корне проекта:

```bash
# Google Cloud Platform
GOOGLE_CLOUD_PROJECT_ID=your-project-id
GOOGLE_CLOUD_REGION=us-central1
GOOGLE_CLOUD_ZONE=us-central1-a

# Hetzner Cloud
HETZNER_API_TOKEN=your-hetzner-token
CLUSTER_NAME=defimon-analytics
CLUSTER_REGION=nbg1

# Domains
INFRASTRUCTURE_DOMAIN=infrastructure.highfunk.uk
ANALYTICS_DOMAIN=analytics.highfunk.uk
ML_DOMAIN=ml.highfunk.uk
```

### Секреты
Создайте секреты для каждого пула:

```bash
# PostgreSQL
kubectl create secret generic postgresql-secrets \
  --from-literal=username=postgres \
  --from-literal=password=secure-password \
  -n analytics

# Redis
kubectl create secret generic redis-secrets \
  --from-literal=password=secure-password \
  -n analytics

# ClickHouse
kubectl create secret generic clickhouse-secrets \
  --from-literal=username=default \
  --from-literal=password=secure-password \
  -n analytics

# Grafana
kubectl create secret generic grafana-secrets \
  --from-literal=admin-password=admin123 \
  -n analytics
```

## 📊 Мониторинг

### Infrastructure Pool
- **Grafana**: http://infrastructure.highfunk.uk:3001
- **Prometheus**: http://infrastructure.highfunk.uk:9090
- **Ethereum Node**: http://infrastructure.highfunk.uk:8545

### Analytics Pool
- **Grafana**: http://analytics.highfunk.uk:3001
- **Prometheus**: http://analytics.highfunk.uk:9090
- **Analytics API**: http://analytics.highfunk.uk:8002/docs

### ML Pool
- **MLflow**: http://ml.highfunk.uk:5000 (TBD)
- **Grafana**: http://ml.highfunk.uk:3001 (TBD)
- **ML API**: http://ml.highfunk.uk:8001/docs (TBD)

## 🔐 Безопасность

- **JWT аутентификация** между сервисами
- **SSL/TLS сертификаты** (Let's Encrypt)
- **Private networks** для внутренних сервисов
- **Firewall правила** для ограничения доступа
- **IAM роли** с минимальными привилегиями

## 📈 Масштабирование

### Infrastructure Pool
- Автомасштабирование GKE кластера
- Горизонтальное масштабирование VM инстансов
- Load balancing для высоких нагрузок

### Analytics Pool
- Kubernetes HPA (Horizontal Pod Autoscaler)
- Автомасштабирование баз данных
- Репликация для высокой доступности

### ML Pool
- GPU node pools для обучения
- CPU node pools для инференса
- Автомасштабирование ML сервисов

## 🚧 Статус разработки

- ✅ **Infrastructure Pool**: Полностью реализован на GCP
- ✅ **Analytics Pool**: Реализован на Hetzner, готов к развертыванию
- 🚧 **ML Pool**: В разработке, провайдер не выбран

## 🤝 Вклад в проект

1. Форкните репозиторий
2. Создайте feature branch
3. Внесите изменения
4. Создайте Pull Request

## 📞 Поддержка

- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Email**: admin@highfunk.uk

## 📄 Лицензия

MIT License - см. файл LICENSE для деталей.
