# DEFIMON Infrastructure - Terraform Configuration

Этот каталог содержит Terraform конфигурацию для развертывания инфраструктуры DEFIMON на Google Cloud Platform.

## 🏗️ Архитектура

Terraform создает следующую инфраструктуру:

- **VPC Network** с подсетью для изоляции ресурсов
- **GKE Cluster** для Ethereum нод с автоскейлингом
- **Cloud SQL** (PostgreSQL) для основной базы данных
- **Memorystore Redis** для кэширования
- **Cloud Storage** бакеты для данных и бэкапов
- **Pub/Sub** для асинхронной обработки событий
- **Firewall Rules** для безопасности
- **Kubernetes Resources** для Ethereum нод и мониторинга

## 📁 Структура файлов

- `main.tf` - Основная конфигурация инфраструктуры
- `variables.tf` - Определение переменных
- `terraform.tfvars` - Значения переменных
- `k8s.tf` - Kubernetes ресурсы
- `README.md` - Этот файл

## 🚀 Быстрый старт

### 1. Установка Terraform

```bash
# macOS
brew install terraform

# Linux
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs)"
sudo apt-get update && sudo apt-get install terraform
```

### 2. Аутентификация в Google Cloud

```bash
gcloud auth application-default login
gcloud config set project defimon-ethereum-node
```

### 3. Инициализация Terraform

```bash
cd terraform
terraform init
```

### 4. Планирование развертывания

```bash
terraform plan
```

### 5. Развертывание инфраструктуры

```bash
terraform apply
```

### 6. Получение информации о кластере

```bash
terraform output
gcloud container clusters get-credentials ethereum-nodes-cluster --region=us-central1
```

## 🔧 Конфигурация

### Переменные

Основные переменные в `terraform.tfvars`:

- `project_id` - ID проекта Google Cloud
- `region` - Регион развертывания
- `zone` - Зона развертывания
- `machine_type` - Тип машины для GKE нод
- `node_count` - Количество нод
- `max_node_count` - Максимальное количество нод для автоскейлинга

### Модули

Инфраструктура разделена на логические блоки:

1. **Сеть** - VPC, подсети, firewall правила
2. **Вычисления** - GKE кластер с нодами
3. **Хранилище** - Cloud Storage, Cloud SQL, Redis
4. **Мониторинг** - Prometheus, Grafana
5. **Kubernetes** - Namespace, Secrets, ConfigMaps

## 📊 Мониторинг

После развертывания доступны:

- **Grafana**: http://[LOAD_BALANCER_IP]:3000 (admin/admin)
- **Prometheus**: http://[LOAD_BALANCER_IP]:9090
- **GKE Dashboard**: через Google Cloud Console

## 🔐 Безопасность

- Приватный GKE кластер
- VPC с изолированными подсетями
- Firewall правила для ограничения доступа
- IAM роли с минимальными привилегиями
- JWT аутентификация для Ethereum нод

## 💰 Стоимость

Ориентировочная стоимость в месяц:

- **GKE Cluster**: $50-100
- **Cloud SQL**: $25-50
- **Memorystore Redis**: $15-30
- **Cloud Storage**: $10-25
- **Network**: $5-15

**Итого**: $105-220/месяц

## 🧹 Очистка

Для удаления всей инфраструктуры:

```bash
terraform destroy
```

⚠️ **Внимание**: Эта команда удалит ВСЕ ресурсы, включая данные!

## 📝 Логи и отладка

```bash
# Просмотр логов Terraform
terraform plan -detailed-exitcode

# Просмотр состояния
terraform show

# Просмотр графа зависимостей
terraform graph | dot -Tsvg > infrastructure.svg
```

## 🔄 Обновление

Для обновления инфраструктуры:

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

## 📚 Дополнительные ресурсы

- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GKE Terraform Examples](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine)
- [Google Cloud Architecture Framework](https://cloud.google.com/architecture/framework)
