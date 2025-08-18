# DEFIMON Deployment Guide

Краткое руководство по развертыванию всех пулов инфраструктуры DEFIMON.

## 🚀 Быстрый старт

### 1. Infrastructure Pool (Google Cloud Platform)

```bash
# Переходим в папку инфраструктурного пула
cd infrastructure/infrastructure-pool

# GKE развертывание (рекомендуется)
cd gke
./scripts/GKE/deploy-gke-ethereum.sh

# Или VM развертывание
cd vm-instances
./scripts/deploy-ethereum-gcp-production.sh
```

**Результат**: Ethereum ноды (Geth + Lighthouse) на GCP

### 2. Analytics Pool (Hetzner Cloud)

```bash
# Подключаемся к Hetzner серверу
ssh vovkes@kraken.highfunk.uk

# Клонируем репозиторий
git clone https://github.com/your-username/defimon.highfunk.uk.git
cd defimon.highfunk.uk

# Настраиваем переменные окружения
cp infrastructure/analytics-pool/deployment/hetzner.env .env
nano .env  # Настройте под ваши нужды

# Создаем кластер
cd infrastructure/analytics-pool/deployment
./create-analytics-cluster.sh

# Создаем секреты
./create-secrets.sh

# Развертываем сервисы
kubectl apply -f ../kubernetes/
```

**Результат**: Аналитические API, базы данных, мониторинг на Hetzner

### 3. ML Pool (TBD)

```bash
# Пока не реализовано
# Выбор провайдера в процессе
```

## 📋 Предварительные требования

### Для Infrastructure Pool (GCP)
- Google Cloud SDK
- kubectl
- Docker
- Доступ к GCP проекту

### Для Analytics Pool (Hetzner)
- Hetzner Cloud CLI (hcloud)
- kubectl
- SSH доступ к серверу kraken.highfunk.uk

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

## 📊 Проверка развертывания

### Infrastructure Pool
```bash
# Проверка GKE кластера
kubectl get nodes
kubectl get pods -n defimon

# Проверка Ethereum нод
kubectl get pods -n defimon -l app=ethereum-geth
kubectl get pods -n defimon -l app=ethereum-lighthouse
```

### Analytics Pool
```bash
# Проверка кластера
kubectl get nodes
kubectl get pods -n analytics

# Проверка сервисов
kubectl get services -n analytics
kubectl get ingress -n analytics
```

## 🌐 Доступ к сервисам

### Infrastructure Pool
- **Grafana**: http://infrastructure.highfunk.uk:3001
- **Prometheus**: http://infrastructure.highfunk.uk:9090
- **Ethereum Node**: http://infrastructure.highfunk.uk:8545

### Analytics Pool
- **Grafana**: http://analytics.highfunk.uk:3001
- **Prometheus**: http://analytics.highfunk.uk:9090
- **Analytics API**: http://analytics.highfunk.uk:8002/docs

## 🔐 Секреты и безопасность

### Создание секретов
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
```

## 🚨 Устранение неполадок

### Проблема: Сервисы не запускаются
```bash
# Проверяем логи
kubectl logs -f deployment/defimon-analytics-api -n analytics

# Проверяем статус подов
kubectl describe pod <pod-name> -n analytics

# Проверяем события
kubectl get events -n analytics --sort-by='.lastTimestamp'
```

### Проблема: База данных недоступна
```bash
# Проверяем подключение к PostgreSQL
kubectl exec -it deployment/postgresql -n analytics -- pg_isready -U postgres

# Проверяем подключение к ClickHouse
kubectl exec -it deployment/clickhouse -n analytics -- wget -qO- http://localhost:8123/ping
```

## 📈 Масштабирование

### Infrastructure Pool
```bash
# Автомасштабирование GKE
kubectl autoscale deployment ethereum-geth --min=1 --max=5 -n defimon
```

### Analytics Pool
```bash
# Автомасштабирование API
kubectl autoscale deployment defimon-analytics-api --min=3 --max=10 -n analytics
```

## 🔄 Обновления

### Обновление сервисов
```bash
# Обновление образа
kubectl set image deployment/defimon-analytics-api analytics-api=defimon/analytics-api:latest -n analytics

# Проверка обновления
kubectl rollout status deployment/defimon-analytics-api -n analytics
```

## 📞 Поддержка

При возникновении проблем:
1. Проверьте логи: `kubectl logs -f <pod-name> -n <namespace>`
2. Проверьте события: `kubectl get events -n <namespace>`
3. Создайте Issue в GitHub
4. Обратитесь к документации в папке `infrastructure/`

## 🎯 Следующие шаги

1. ✅ **Infrastructure Pool**: Развернут на GCP
2. ✅ **Analytics Pool**: Готов к развертыванию на Hetzner
3. 🚧 **ML Pool**: Выбор провайдера и реализация
4. 🔄 **Интеграция**: Настройка взаимодействия между пулами
5. 📊 **Мониторинг**: Единая система мониторинга всех пулов
