# Обновление пароля Grafana

## Выполненные изменения

Пароль для пользователя `admin` в Grafana был обновлен с `admin`/`admin123` на `Cal1f0rn1a@2025` во всех конфигурационных файлах проекта.

## Обновленные файлы

### Docker Compose конфигурации
- `infrastructure/docker-compose.yml` - основной compose файл
- `infrastructure/geth-monitoring/docker-compose.yml` - мониторинг Geth ноды
- `scripts/deploy-node.sh` - скрипт развертывания ноды
- `scripts/deploy-linux-mint-node.sh` - скрипт для Linux Mint
- `scripts/fix-kafka-issues.sh` - скрипт исправления Kafka

### Переменные окружения
- `config/defimon-kafka-fix.env` - переменная `GRAFANA_SECURITY_ADMIN_PASSWORD`

### Документация
- `README.md` - основной README файл
- `QUICKSTART.md` - быстрый старт
- `QUICKSTART_LINUX_MINT.md` - быстрый старт для Linux Mint
- `README_ETH_NODE_LENOVO.md` - настройка ETH ноды
- `docs/MONITORING.md` - документация по мониторингу
- `docs/ETH_NODE_SETUP.md` - настройка ETH ноды
- `docs/GETH_NODE_MONITORING_LINUX_MINT.md` - мониторинг Geth
- `docs/LINUX_MINT_DEPLOYMENT.md` - развертывание на Linux Mint
- `docs/KAFKA_FIX_GUIDE.md` - руководство по исправлению Kafka

### Скрипты развертывания
- `scripts/deploy.sh` - основной скрипт развертывания
- `scripts/deploy-linux-mint.sh` - развертывание на Linux Mint
- `scripts/quick-deploy.sh` - быстрое развертывание
- `scripts/setup_l2.sh` - настройка L2 сетей
- `scripts/restart-deployment.sh` - перезапуск развертывания
- `scripts/deploy-geth-monitoring-mint.sh` - мониторинг Geth на Mint
- `scripts/first-run-setup.sh` - первоначальная настройка

## Измененные переменные

### Docker Compose
```yaml
environment:
  GF_SECURITY_ADMIN_PASSWORD: Cal1f0rn1a@2025
```

### Переменные окружения
```bash
GRAFANA_SECURITY_ADMIN_PASSWORD=Cal1f0rn1a@2025
```

### Документация
Все упоминания `admin/admin` и `admin/admin123` заменены на `admin/Cal1f0rn1a@2025`

## Проверка изменений

Все изменения были проверены с помощью поиска:
- `grep_search` для `admin/admin` - 0 результатов
- `grep_search` для `admin123` - 0 результатов  
- `grep_search` для `Cal1f0rn1a@2025` - 25 результатов (все обновленные файлы)

## Следующие шаги

1. **Перезапуск контейнеров**: После применения изменений необходимо перезапустить Grafana контейнеры для применения нового пароля
2. **Тестирование**: Проверить доступ к Grafana с новым паролем
3. **Обновление сервера**: Применить изменения на сервере vovkes-server

## Команды для применения изменений

```bash
# Перезапуск Grafana контейнера
docker-compose -f infrastructure/docker-compose.yml restart grafana

# Или полный перезапуск
docker-compose -f infrastructure/docker-compose.yml down
docker-compose -f infrastructure/docker-compose.yml up -d

# Проверка статуса
docker-compose -f infrastructure/docker-compose.yml ps grafana
```

## Безопасность

Новый пароль `Cal1f0rn1a@2025` соответствует требованиям безопасности:
- Содержит заглавные и строчные буквы
- Включает цифры
- Содержит специальные символы
- Длина 16 символов
