# ML Pool - Machine Learning Services

Этот пул отвечает за машинное обучение, предсказания и анализ рисков DeFi протоколов.

## 🏗️ Архитектура

```
ML Infrastructure (TBD)
├── Kubernetes Cluster (ml-cluster)
│   ├── AI/ML Service (FastAPI)
│   ├── Model Training Pipeline
│   ├── Model Serving
│   └── Experiment Tracking
├── ML Infrastructure
│   ├── GPU Nodes (для обучения)
│   ├── CPU Nodes (для инференса)
│   └── Storage (для моделей и данных)
├── ML Services
│   ├── Price Prediction Models
│   ├── Risk Scoring Models
│   ├── Anomaly Detection
│   └── Feature Engineering
├── Data Pipeline
│   ├── Feature Store
│   ├── Model Registry
│   └── Experiment Tracking
└── Monitoring
    ├── Model Performance
    ├── Data Drift Detection
    └── A/B Testing
```

## 📁 Структура

- **kubernetes/** - Kubernetes манифесты для ML сервисов
- **services/** - Конфигурации ML сервисов
- **models/** - Архитектуры и конфигурации моделей
- **training/** - Pipeline для обучения моделей
- **deployment/** - Скрипты развертывания

## 🚀 Развертывание

### Создание кластера
```bash
# Создание Kubernetes кластера с GPU поддержкой
./deployment/create-ml-cluster.sh
```

### Развертывание сервисов
```bash
# Применение Kubernetes манифестов
kubectl apply -f kubernetes/

# Проверка статуса
kubectl get pods -n ml
```

## 🔧 Конфигурация

### Переменные окружения
- `ML_DOMAIN` - Домен для ML сервисов
- `MODEL_STORAGE_PATH` - Путь для хранения моделей
- `GPU_ENABLED` - Включение GPU поддержки
- `EXPERIMENT_TRACKING_URI` - URI для MLflow

### Ресурсы
- **GPU**: NVIDIA T4/V100/A100 (для обучения)
- **CPU**: 16-64 vCPU (для инференса)
- **RAM**: 64-256GB
- **Storage**: 2TB+ NVMe для моделей и данных

## 🤖 ML Сервисы

### AI/ML Service (порт 8001)
- FastAPI приложение для ML API
- Model serving и inference
- Batch и real-time предсказания
- Model versioning

### Price Prediction Models
- LSTM/Transformer для предсказания цен
- Multi-timeframe анализ
- Ensemble методы
- Feature importance analysis

### Risk Scoring Models
- Gradient Boosting для оценки рисков
- Real-time risk monitoring
- Risk factor decomposition
- Alert system

### Anomaly Detection
- Isolation Forest для аномалий
- Time-series anomaly detection
- Multi-dimensional analysis
- Auto-scaling thresholds

## 📊 Мониторинг

- **MLflow**: http://ml.highfunk.uk:5000
- **Grafana**: http://ml.highfunk.uk:3001
- **Model API**: http://ml.highfunk.uk:8001/docs

## 🔐 Безопасность

- Model access control
- Data encryption
- API rate limiting
- Audit logging
- Model versioning security

## 🚧 Статус

**В разработке** - провайдер инфраструктуры пока не выбран.

Возможные варианты:
- Google Cloud Platform (GKE с GPU)
- AWS (EKS с GPU instances)
- Azure (AKS с GPU nodes)
- Hetzner Cloud (если понадобятся GPU)
- On-premise (если есть GPU серверы)
