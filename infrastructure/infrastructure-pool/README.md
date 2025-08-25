# Infrastructure Pool - Google Cloud Platform

Этот пул отвечает за развертывание и управление Ethereum нодами (Geth + Lighthouse) на Google Cloud Platform.

## 🏗️ Архитектура

```
Google Cloud Platform
├── GKE Cluster (ethereum-nodes-cluster)
│   ├── Ethereum Execution Client (Geth)
│   └── Ethereum Consensus Client (Lighthouse)
├── VM Instances (Production)
│   ├── High-performance nodes
│   └── Backup nodes
├── Storage
│   ├── Persistent Disks (2TB+ для блокчейн данных)
│   └── Cloud Storage (backups, snapshots)
├── Networking
│   ├── Load Balancers
│   ├── VPC Networks
│   └── Firewall Rules
└── Monitoring
    ├── Prometheus
    ├── Grafana
    └── Cloud Logging
```

## 📁 Структура

- **gke/** - Kubernetes конфигурации для GKE
- **vm-instances/** - Конфигурации VM инстансов
- **monitoring/** - Prometheus, Grafana, алерты
- **storage/** - Persistent Disks, Cloud Storage
- **networking/** - VPC, Load Balancers, Firewall

## 🚀 Развертывание

### GKE развертывание
```bash
# Создание кластера
./scripts/GKE/deploy-gke-ethereum.sh

# Развертывание Ethereum нод
kubectl apply -f gke/
```

### VM развертывание
```bash
# Production развертывание
./scripts/deploy-ethereum-gcp-production.sh

# Управление дисками
./scripts/manage-ethereum-disks.sh
```

## 🔧 Конфигурация

### Переменные окружения
- `GOOGLE_CLOUD_PROJECT_ID` - ID проекта GCP
- `GOOGLE_CLOUD_REGION` - Регион развертывания
- `GOOGLE_CLOUD_ZONE` - Зона развертывания

### Ресурсы
- **CPU**: 4-16 vCPU (в зависимости от нагрузки)
- **RAM**: 16-64GB
- **Storage**: 2TB+ SSD для блокчейн данных
- **Network**: 100Mbps+ стабильное соединение

## 📊 Мониторинг

- **Grafana**: http://localhost:3001 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Health Checks**: /health эндпоинты для всех сервисов

## 🔐 Безопасность

- JWT аутентификация между Geth и Lighthouse
- SSL/TLS сертификаты (Let's Encrypt)
- Firewall правила для ограничения доступа
- IAM роли для минимальных привилегий
