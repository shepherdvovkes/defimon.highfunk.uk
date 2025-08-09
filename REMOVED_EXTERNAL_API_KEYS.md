# Удаление внешних API ключей

## Обзор изменений

Удалены все внешние API ключи от сторонних сервисов, так как система использует собственные ноды.

## Удаленные API ключи

### 1. Etherscan API Keys
- `ETHERSCAN_API_KEY`
- `POLYGONSCAN_API_KEY` 
- `ARBISCAN_API_KEY`
- `OPTIMISTIC_ETHERSCAN_API_KEY`

### 2. External Data Sources
- `THE_GRAPH_API_KEY`
- `ALCHEMY_API_KEY`
- `COINGECKO_API_KEY`
- `DEFILLAMA_API_KEY`

### 3. API Authentication
- `API_KEY_SECRET` (в скриптах развертывания)

## Измененные файлы

### Конфигурационные файлы
- `env.example` - удалены секции с внешними API ключами
- `scripts/deploy.sh` - закомментированы внешние API ключи
- `scripts/prepare-secrets.sh` - закомментированы внешние API ключи
- `scripts/apply-secrets.sh` - закомментированы внешние API ключи
- `scripts/deploy-linux-mint-node.sh` - закомментирован API_KEY_SECRET
- `scripts/deploy-node.sh` - закомментирован API_KEY_SECRET

### Docker конфигурация
- `infrastructure/docker-compose.yml` - закомментированы переменные окружения для внешних API
- `infrastructure/kong.yml` - закомментирована аутентификация по API ключам

### Сервисы
- `services/data-ingestion/main.py` - закомментированы внешние источники данных

### Документация
- `docs/GOOGLE_CLOUD_SETUP.md` - обновлено описание секретов

## Примечания

1. **Уведомления остались** - Slack и Telegram webhooks остались как опциональные
2. **Firebase ключи** - в мобильном приложении остались, так как нужны для push-уведомлений
3. **Собственные ноды** - система теперь полностью полагается на собственные ноды для получения данных
4. **Возможность включения** - все внешние API закомментированы, но могут быть легко включены при необходимости

## Восстановление внешних API (при необходимости)

Если потребуется использовать внешние API, нужно:

1. Раскомментировать соответствующие строки в файлах
2. Добавить реальные API ключи в переменные окружения
3. Раскомментировать источники данных в `services/data-ingestion/main.py`
4. Обновить docker-compose.yml для передачи переменных окружения
