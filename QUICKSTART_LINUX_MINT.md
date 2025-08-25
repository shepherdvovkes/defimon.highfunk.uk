# Быстрый старт DEFIMON на Linux Mint

## 🚀 Одношаговое развертывание

```bash
# 1. Клонирование репозитория
git clone <repository-url>
cd DEFIMON

# 2. Запуск автоматического развертывания
./scripts/deploy-linux-mint.sh
```

## ✅ Что произойдет автоматически

1. **Проверка системы** - RAM, CPU, диск
2. **Установка зависимостей** - Docker, инструменты
3. **Поиск лучшего диска** - Автоматически найдет диск с 1TB+ места
4. **Создание структуры** - Все папки и конфигурации
5. **Развертывание сервисов** - Все микросервисы
6. **Health checks** - Проверка работоспособности
7. **Создание скриптов** - Мониторинг и резервное копирование

## 🌐 Доступные интерфейсы

После развертывания откройте:

- **Административный дашборд**: http://localhost:8080
- **Основной интерфейс**: http://localhost:3000
- **Grafana мониторинг**: http://localhost:3001 (admin/admin)
- **API Gateway**: http://localhost:8000

## 📊 Мониторинг

```bash
# Проверка системы
./scripts/system-monitor.sh

# Непрерывный мониторинг
./scripts/system-monitor.sh continuous

# Управление сервисами
./scripts/deploy-linux-mint.sh status
./scripts/deploy-linux-mint.sh logs
```

## 💾 Резервное копирование

```bash
# Создание резервной копии
./data/backup.sh

# Автоматическое резервное копирование (ежедневно в 2:00)
crontab -e
# Добавьте: 0 2 * * * /path/to/DEFIMON/data/backup.sh
```

## 🔧 Управление

```bash
# Остановка всех сервисов
./scripts/deploy-linux-mint.sh stop

# Перезапуск сервисов
./scripts/deploy-linux-mint.sh restart

# Очистка системы
./scripts/deploy-linux-mint.sh clean
```

## 📋 Системные требования

- **ОС**: Linux Mint 20+ или Ubuntu 20.04+
- **RAM**: 8GB+ (16GB рекомендуется)
- **CPU**: 4+ ядер (8+ рекомендуется)
- **Диск**: 100GB+ свободного места (1TB+ рекомендуется)
- **Сеть**: Стабильное интернет-соединение

## 🆘 Устранение неполадок

### Проблемы с Docker
```bash
sudo systemctl status docker
sudo systemctl restart docker
```

### Проблемы с дисковым пространством
```bash
df -h
docker system prune -f
```

### Просмотр логов
```bash
./scripts/deploy-linux-mint.sh logs
```

## 📚 Дополнительная документация

- **Полное руководство**: [docs/LINUX_MINT_DEPLOYMENT.md](docs/LINUX_MINT_DEPLOYMENT.md)
- **Административный дашборд**: [docs/ADMIN_DASHBOARD.md](docs/ADMIN_DASHBOARD.md)
- **L2 настройка**: [L2_SETUP.md](L2_SETUP.md)

## 🎉 Готово!

После успешного развертывания у вас будет:

- ✅ Полная Ethereum нода
- ✅ Мониторинг L2 сетей
- ✅ Административный дашборд
- ✅ Система мониторинга
- ✅ Автоматическое резервное копирование
- ✅ Оптимизация для Linux Mint

Система готова к использованию!
