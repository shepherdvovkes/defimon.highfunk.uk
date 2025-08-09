# DeFi Analytics Platform (DEFIMON)

Платформа для аналитики и мониторинга DeFi протоколов с интеграцией AI/ML для предсказаний и оценки рисков. Поддерживает мониторинг более 50 L2 сетей, Cosmos экосистемы, Polkadot парачейнов и других блокчейнов.

## 🌟 Основные возможности

- **Мультиблокчейн поддержка**: Ethereum, Cosmos, Polkadot, Bitcoin, Solana, StarkNet
- **L2 сети**: Optimism, Arbitrum, Base, zkSync, Polygon zkEVM, Linea, Scroll и другие
- **AI/ML аналитика**: Предсказание цен, оценка рисков, аномальное обнаружение
- **Реальное время**: WebSocket обновления, потоковая обработка данных
- **Мониторинг**: Prometheus, Grafana, административный дашборд
- **Масштабируемость**: Kubernetes, Google Cloud, микросервисная архитектура

## 🏗️ Архитектура

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              PRESENTATION LAYER                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  Web Dashboard     │  Mobile App      │  API Docs       │  Admin Dashboard  │
│  (Next.js)         │  (React Native)  │  (Swagger)      │  (Node.js)       │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                ┌───────▼───────┐
                                │  Load Balancer │
                                │  (Nginx/ALB)   │
                                └──────┬───────┘
                                        │
┌─────────────────────────────────────────────────────────────────────────────┐
│                               API GATEWAY LAYER                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                     API Gateway (Kong/AWS API Gateway)                      │
│  • Authentication & Authorization   • Rate Limiting   • Request Routing     │
│  • API Key Management              • Caching         • Monitoring           │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
┌─────────────────────────────────────────────────────────────────────────────┐
│                              MICROSERVICES LAYER                            │
├─────────────────────────────────────────────────────────────────────────────┤
│  Analytics API     │  AI/ML Service   │  Blockchain Node │  Data Ingestion │
│  (Python/FastAPI)  │  (Python)        │  (Rust)         │  (Python)       │
│  • Data queries    │  • Predictions   │  • Node sync     │  • Web3 APIs    │
│  • Aggregations    │  • Risk scoring  │  • Event parsing │  • Websockets   │
│  • Real-time API   │  • Model serving │  • RPC/WS API    │  • Rate limiting │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
┌─────────────────────────────────────────────────────────────────────────────┐
│                              DATA PROCESSING LAYER                          │
├─────────────────────────────────────────────────────────────────────────────┤
│  Stream Processing│  Batch Processing│  ML Pipeline    │  Event Indexer    │
│  (Python)         │  (Apache Airflow)│  (MLflow)       │  (Rust)          │
│  • Real-time      │  • Historical    │  • Training     │  • Event parsing │
│  • Event streams  │  • Aggregations  │  • Inference    │  • Log analysis  │
│  • Transformations│  • Model updates │  • Experiments  │  • ABI decoding  │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
┌─────────────────────────────────────────────────────────────────────────────┐
│                                DATA LAYER                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│  PostgreSQL        │  ClickHouse       │  Redis           │  S3/MinIO       │
│  • User data       │  • Time series    │  • Cache         │  • Model storage│
│  • Metadata        │  • Analytics      │  • Sessions      │  • Raw data     │
│  • Configurations  │  • Logs          │  • Rate limits   │  • Backups      │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🚀 Быстрый старт

### Предварительные требования

- **Docker & Docker Compose** (версия 2.0+)
- **Node.js 18+** (для разработки)
- **Python 3.9+** (для разработки)
- **Rust 1.70+** (для blockchain-node)
- **Git**
- **Минимум 8GB RAM** (16GB рекомендуется)
- **Минимум 50GB свободного места**

### Установка и запуск

1. **Клонирование репозитория**
```bash
git clone <repository-url>
cd defimon.highfunk.uk
```

2. **Настройка переменных окружения**
```bash
cp env.example .env
# Отредактируйте .env файл с вашими API ключами
```

3. **Запуск системы**

**Полное развертывание на Linux Mint (рекомендуется):**
```bash
chmod +x scripts/deploy-linux-mint.sh
./scripts/deploy-linux-mint.sh
```

**Быстрый запуск с L2 поддержкой:**
```bash
chmod +x scripts/setup_l2.sh
./scripts/setup_l2.sh
```

**Стандартный запуск:**
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

**Запуск только административного дашборда:**
```bash
chmod +x scripts/start-admin-dashboard.sh
./scripts/start-admin-dashboard.sh
```

4. **Проверка работоспособности**
- **Frontend**: http://localhost:3000
- **API Gateway**: http://localhost:8000
- **Analytics API**: http://localhost:8002/docs
- **AI/ML Service**: http://localhost:8001/docs
- **Admin Dashboard**: http://localhost:8080
- **Grafana**: http://localhost:3001 (admin/Cal1f0rn1a@2025)
- **Prometheus**: http://localhost:9090

## 🔗 Поддерживаемые блокчейны

### Ethereum & L2 сети
- **Ethereum Mainnet** - Основная сеть
- **Optimism** (Priority 10) - $850M TVL
- **Arbitrum One** (Priority 10) - $2.1B TVL
- **Base** (Priority 9) - $750M TVL
- **zkSync Era** (Priority 9) - $650M TVL
- **Polygon zkEVM** (Priority 9) - $45M TVL
- **StarkNet** (Priority 8) - $180M TVL
- **Linea** (Priority 8) - $120M TVL
- **Scroll** (Priority 8) - $85M TVL
- **Mantle** (Priority 7) - $45M TVL
- **И еще 40+ L2 сетей...**

### Cosmos экосистема
- **Cosmos Hub** - Основная сеть
- **Osmosis** - DEX протокол
- **Injective** - Финансовые приложения
- **Celestia** - Модульная блокчейн сеть
- **Sei** - Торговая сеть
- **Neutron** - Смарт-контракт платформа
- **Stride** - Liquid staking
- **Quicksilver** - Interchain DeFi
- **Persistence** - Enterprise DeFi
- **Agoric** - JavaScript смарт-контракты
- **Evmos** - EVM совместимость
- **Kava** - DeFi платформа

### Polkadot экосистема
- **Polkadot** - Relay Chain
- **Kusama** - Canary network
- **Westend** - Testnet
- **Rococo** - Parachain testnet
- **Moonbeam** - EVM совместимость
- **Astar** - Мульти-VM платформа

### Другие блокчейны
- **Bitcoin** - Основная сеть и Lightning Network
- **Solana** - Высокопроизводительная сеть
- **StarkNet** - ZK-rollup

## 📁 Структура проекта

```
defimon.highfunk.uk/
├── frontend/                 # Next.js веб-приложение
│   ├── app/                 # App Router (Next.js 14)
│   ├── package.json         # Зависимости
│   └── Dockerfile           # Контейнеризация
├── services/
│   ├── analytics-api/       # FastAPI аналитический сервис
│   │   ├── main.py         # Основное приложение
│   │   ├── routers/        # API роутеры
│   │   ├── models.py       # Pydantic модели
│   │   └── requirements.txt # Python зависимости
│   ├── ai-ml-service/      # Python AI/ML сервис
│   │   ├── main.py         # FastAPI приложение
│   │   ├── models/         # ML модели
│   │   ├── services/       # ML сервисы
│   │   └── requirements.txt # Python зависимости
│   ├── blockchain-node/     # Rust сервис для работы с блокчейнами
│   │   ├── src/            # Rust исходный код
│   │   │   ├── main.rs     # Точка входа
│   │   │   ├── modules/    # Модули для разных блокчейнов
│   │   │   └── services/   # Сервисы
│   │   ├── Cargo.toml      # Rust зависимости
│   │   └── Dockerfile      # Контейнеризация
│   ├── data-ingestion/     # Сервис сбора данных
│   │   ├── main.py         # Основной скрипт
│   │   └── requirements.txt # Python зависимости
│   ├── stream-processing/   # Обработка потоковых данных
│   │   ├── main.py         # Основной скрипт
│   │   └── requirements.txt # Python зависимости
│   └── admin-dashboard/    # Node.js административный дашборд
│       ├── server.js       # Express сервер
│       ├── package.json    # Node.js зависимости
│       └── Dockerfile      # Контейнеризация
├── infrastructure/          # Docker и конфигурации
│   ├── docker-compose.yml  # Основной compose файл
│   ├── kubernetes/         # K8s манифесты
│   ├── monitoring/         # Prometheus, Grafana
│   ├── *.sql              # Схемы баз данных
│   └── kong.yml           # API Gateway конфигурация
├── scripts/               # Скрипты развертывания
│   ├── deploy.sh          # Основной скрипт развертывания
│   ├── deploy-linux-mint.sh # Развертывание на Linux Mint
│   ├── deploy-google-cloud.sh # Google Cloud развертывание
│   ├── setup_l2.sh        # Настройка L2 сетей
│   ├── setup_cosmos.sh    # Настройка Cosmos сетей
│   ├── setup_polkadot.sh  # Настройка Polkadot сетей
│   ├── deploy-node.sh     # Развертывание ноды
│   ├── system-monitor.sh  # Системный мониторинг
│   └── start-admin-dashboard.sh # Запуск админ дашборда
├── docs/                  # Документация
│   ├── ADMIN_DASHBOARD.md # Документация админ дашборда
│   ├── COSMOS_SETUP.md    # Настройка Cosmos
│   ├── GOOGLE_CLOUD_SETUP.md # Google Cloud настройка
│   ├── LINUX_MINT_DEPLOYMENT.md # Linux Mint развертывание
│   └── ROADMAP_NETWORK_EXPANSION.md # План развития
├── env.example            # Пример переменных окружения
├── secrets.env            # Секретные переменные
├── README.md              # Основная документация
├── QUICKSTART.md          # Быстрый старт
├── QUICKSTART_LINUX_MINT.md # Linux Mint быстрый старт
└── L2_SETUP.md            # Настройка L2 сетей
```

## 🔧 Технологический стек

### Frontend
- **Next.js 14** - React фреймворк с App Router
- **TypeScript** - Типизированный JavaScript
- **Tailwind CSS** - Utility-first CSS фреймворк
- **Recharts** - React библиотека для графиков
- **Axios** - HTTP клиент
- **Headless UI** - Доступные UI компоненты
- **Heroicons** - SVG иконки

### Backend Services
- **FastAPI** - Современный Python веб-фреймворк
- **Uvicorn** - ASGI сервер
- **Pydantic** - Валидация данных
- **SQLAlchemy** - ORM для PostgreSQL
- **ClickHouse Connect** - Клиент для ClickHouse
- **Redis** - Кэширование и сессии
- **Prometheus Client** - Метрики

### AI/ML
- **TensorFlow 2.13** - Глубокое обучение
- **Scikit-learn 1.3** - Машинное обучение
- **NumPy 1.24** - Численные вычисления
- **Pandas 2.0** - Анализ данных
- **Matplotlib & Seaborn** - Визуализация
- **Joblib** - Параллельная обработка

### Blockchain Node (Rust)
- **Web3** - Ethereum клиент
- **Ethers** - Ethereum библиотека
- **Subxt** - Substrate клиент
- **Tokio** - Асинхронный runtime
- **SQLx** - Асинхронная ORM
- **Redis** - Кэширование
- **RDKafka** - Kafka клиент
- **Tracing** - Логирование

### Infrastructure
- **Docker & Docker Compose** - Контейнеризация
- **Kubernetes** - Оркестрация контейнеров
- **Kong** - API Gateway
- **PostgreSQL 15** - Основная БД
- **ClickHouse** - Аналитическая БД
- **Redis 7** - Кэш и очереди
- **Apache Kafka** - Потоковая обработка
- **Prometheus** - Мониторинг
- **Grafana** - Визуализация метрик

### DevOps & Deployment
- **Google Cloud Platform** - Облачная инфраструктура
- **Linux Mint** - Операционная система
- **Nginx** - Веб-сервер и балансировщик
- **SSL/TLS** - Шифрование
- **Git** - Система контроля версий

## 📊 API Документация

### Основные эндпоинты

**Analytics API** (порт 8002):
- `GET /api/protocols` - Список протоколов
- `GET /api/analytics/overview` - Обзор рынка
- `GET /api/protocols/{protocol}/metrics` - Метрики протокола
- `GET /api/protocols/{protocol}/risk` - Оценка риска
- `GET /api/networks/{network}/status` - Статус сети

**AI/ML Service** (порт 8001):
- `POST /api/predict/price` - Предсказание цен
- `POST /api/analyze/risk` - Анализ рисков
- `GET /api/models/status` - Статус ML моделей
- `POST /api/train/model` - Обучение модели

**Blockchain Node** (порт 8545):
- `POST /` - Ethereum RPC
- `GET /health` - Проверка здоровья
- `GET /metrics` - Метрики ноды

### Swagger UI
- **Analytics API**: http://localhost:8002/docs
- **AI/ML Service**: http://localhost:8001/docs

## 🔍 Мониторинг

### Административный дашборд
- **URL**: http://localhost:8080
- **Функции**: 
  - Мониторинг всех сервисов в реальном времени
  - Просмотр логов и метрик
  - Управление развертываниями
  - WebSocket обновления каждые 10 секунд
  - Экспорт данных

### Инструменты мониторинга
- **Grafana**: http://localhost:3001 (admin/Cal1f0rn1a@2025)
- **Prometheus**: http://localhost:9090
- **Kong Admin**: http://localhost:8001

### Мониторируемые сервисы
- **API Gateway** (Kong) - порт 8001
- **Analytics API** - порт 8002
- **AI/ML Service** - порт 8001
- **Blockchain Node** - порт 8545
- **PostgreSQL** - порт 5432
- **ClickHouse** - порт 8123
- **Redis** - порт 6379
- **Kafka** - порт 9092

## ⚡ Производительность

### Rust компоненты (blockchain-node)
- **Обработка блоков**: ~1000 блоков/сек
- **Парсинг событий**: ~5000 событий/сек
- **Запросы к ноде**: ~1000 RPC/сек
- **Память**: ~500MB для blockchain-node
- **CPU**: 2-4 ядра для полной синхронизации

### Python сервисы
- **FastAPI**: ~5000 запросов/сек
- **ML инференс**: ~100 предсказаний/сек
- **Потоковая обработка**: ~10000 событий/сек

### Системные требования
- **CPU**: 4+ ядра (8+ для продакшена)
- **RAM**: 8GB+ (16GB+ для продакшена)
- **Диск**: 100GB+ SSD (500GB+ для ноды)
- **Сеть**: 100Mbps+ стабильное соединение

## 🔐 Безопасность

- **Переменные окружения** - Все API ключи и секреты
- **JWT токены** - Аутентификация пользователей
- **Rate limiting** - Ограничение запросов на уровне API Gateway
- **HTTPS** - Шифрование для всех внешних соединений
- **Docker изоляция** - Изоляция контейнеров
- **Kubernetes RBAC** - Ролевой доступ в продакшене

## 🚀 Развертывание

### Локальная разработка

```bash
# Запуск только базовых сервисов
docker-compose -f infrastructure/docker-compose.yml up -d postgres redis kafka

# Запуск frontend в режиме разработки
cd frontend && npm run dev

# Запуск API сервисов
cd services/analytics-api && python -m uvicorn main:app --reload
cd services/ai-ml-service && python -m uvicorn main:app --reload

# Запуск Rust blockchain-node
cd services/blockchain-node && cargo run
```

### Продакшен развертывание

**Linux Mint (рекомендуется):**
```bash
./scripts/deploy-linux-mint.sh
```

**Google Cloud Platform:**
```bash
./scripts/deploy-google-cloud.sh
```

**Kubernetes:**
```bash
kubectl apply -f infrastructure/kubernetes/
```

### Управление нодой

```bash
# Развертывание ноды на отдельном сервере
sudo ./scripts/deploy-node.sh

# Управление L2 сетями
./scripts/setup_l2.sh status    # Проверка статуса
./scripts/setup_l2.sh logs      # Просмотр логов
./scripts/setup_l2.sh restart   # Перезапуск
./scripts/setup_l2.sh clean     # Очистка

# Системный мониторинг
./scripts/system-monitor.sh
```

## 🤝 Вклад в проект

1. Fork репозитория
2. Создайте feature branch (`git checkout -b feature/amazing-feature`)
3. Commit изменения (`git commit -m 'Add amazing feature'`)
4. Push в branch (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

## 📄 Лицензия

MIT License - см. файл [LICENSE](LICENSE) для деталей.

## 🆘 Поддержка

- **Issues**: Создайте Issue для багов или feature requests
- **Документация**: `/docs` - Подробная документация
- **Email**: support@defimon.com

## 📈 Roadmap

См. [ROADMAP_NETWORK_EXPANSION.md](docs/ROADMAP_NETWORK_EXPANSION.md) для планов развития платформы.

---

**DeFi Analytics Platform** - Мощная платформа для аналитики и мониторинга DeFi экосистемы с поддержкой мультиблокчейн архитектуры и AI/ML возможностями.
