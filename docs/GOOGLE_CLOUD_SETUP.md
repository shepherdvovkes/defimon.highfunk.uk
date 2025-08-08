### Google Cloud: настройка и деплой DEFIMON

Ниже краткий чек-лист, что сделать в Google Cloud и какие данные положить в `.env` и `secrets.env`.

- Важно: используйте один проект GCP и один регион/зону для всех ресурсов.

## 1) Предусловия на локальной машине
- Установите Google Cloud SDK (`gcloud`), `kubectl`, `docker`.
- Выполните вход: `gcloud auth login`.

## 2) Что нужно создать/получить в Google Cloud
- **Project ID**: идентификатор проекта (например, `my-defimon-123`).
- **Region/Zone**: например, `us-central1` и `us-central1-a`.
- **Service Account**: email вида `defimon-service@<project-id>.iam.gserviceaccount.com` + JSON-ключ (файл `gcp-service-account-key.json`).
  - Роли минимум: `roles/editor`, `roles/storage.admin`, `roles/pubsub.admin`, `roles/redis.admin`, `roles/cloudsql.admin`, `roles/container.admin`.
- **Cloud Storage**: 2 бакета — для данных и резервных копий.
- **Cloud SQL (PostgreSQL)**: инстанс + БД + пользователь/пароль.
- **Memorystore (Redis)**: инстанс.
- (Опционально) **Pub/Sub**: топик и подписка, если планируете заменять Kafka.
- **GKE Cluster**: кластер Kubernetes.
- **Домены**: `app.defimon.com`, `admin.defimon.com`, `api.defimon.com`, `ai.defimon.com` — доступ к DNS для создания A-записей.

## 3) Что положить в `.env` (корень репо)
- Используйте обновлённый `env.example` как шаблон. Минимально заполните:
  - `GOOGLE_CLOUD_PROJECT_ID`, `GOOGLE_CLOUD_REGION`, `GOOGLE_CLOUD_ZONE`
  - `GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL`, `GOOGLE_CLOUD_SERVICE_ACCOUNT_KEY_FILE`
  - `GOOGLE_CLOUD_STORAGE_BUCKET`, `GOOGLE_CLOUD_STORAGE_BACKUP_BUCKET`
  - `GOOGLE_CLOUD_SQL_INSTANCE_NAME`, `GOOGLE_CLOUD_SQL_DATABASE_NAME`, `GOOGLE_CLOUD_SQL_USER`, `GOOGLE_CLOUD_SQL_PASSWORD`
  - Домены: `FRONTEND_DOMAIN`, `ADMIN_DASHBOARD_DOMAIN`, `ANALYTICS_API_DOMAIN`, `AI_ML_SERVICE_DOMAIN`

## 4) Что положить в `secrets.env` (будет создан скриптом)
- Хранит чувствительные значения в обычном виде (не base64). Примеры ключей:
  - `JWT_SECRET_KEY`, `ADMIN_DASHBOARD_SECRET_KEY`, `ANALYTICS_API_SECRET_KEY`, `AI_ML_SERVICE_SECRET_KEY`
  - `GOOGLE_CLOUD_SQL_PASSWORD` (должен совпадать с паролем пользователя Cloud SQL)
  - API-ключи сканеров/уведомлений: `ETHERSCAN_API_KEY`, `POLYGONSCAN_API_KEY`, `ARBISCAN_API_KEY`, `OPTIMISTIC_ETHERSCAN_API_KEY`, `SLACK_WEBHOOK_URL`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`

## 5) Подготовка секретов
- Сгенерировать файл секретов:
  - `./scripts/prepare-secrets.sh`
  - Отредактируйте `secrets.env`, замените плейсхолдеры на реальные значения.
- Применить секреты в Kubernetes:
  - `./scripts/apply-secrets.sh`

## 6) Деплой
- Запуск деплоя всех ресурсов и приложения:
  - `./scripts/deploy-google-cloud.sh`
- Скрипт:
  - включает нужные API
  - создаёт сервис-аккаунт и ключ
  - создаёт GCS бакеты, Cloud SQL, Redis, Pub/Sub
  - создаёт кластер GKE
  - собирает и пушит Docker-образы в `gcr.io/<project-id>`
  - применяет манифесты Kubernetes для `frontend`, `admin-dashboard`, `analytics-api`, `ai-ml-service`

## 7) DNS и HTTPS
- После создания Ingress получите внешние IP (GCE Ingress создаст балансировщик):
  - `kubectl get ingress -n defimon`
- В DNS провайдера создайте A-записи для доменов на указанные IP.
- Сертификаты управляются GKE (Managed Certificates) — будут выпущены автоматически после того, как DNS укажет на IP балансировщика.

## 8) Подключение к базе (замечание)
- Для продакшена рекомендуется Cloud SQL Auth Proxy sidecar в подах или Private IP + VPC peering. В текущем минимальном варианте используйте публичный IP инстанса и установите авторизованные сети или добавьте Cloud SQL Proxy.

## 9) Команды на проверку
- Кластер и namespace:
  - `kubectl get nodes`
  - `kubectl get ns`
  - `kubectl get all -n defimon`
- Ingress и IP:
  - `kubectl get ingress -n defimon`
- Логи подов:
  - `kubectl logs -n defimon deploy/defimon-analytics-api`

## 10) Точки входа
- Frontend: `https://app.defimon.com`
- Admin: `https://admin.defimon.com`
- API: `https://api.defimon.com`
- AI/ML: `https://ai.defimon.com`
