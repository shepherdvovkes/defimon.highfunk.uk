# Lighthouse SDA1 Setup Guide

## Обзор

Этот гайд описывает, как настроить lighthouse для синхронизации на внешнем диске sda1 вместо использования Docker volumes.

## Преимущества использования sda1

- Больше места для хранения данных
- Лучшая производительность I/O
- Возможность использования SSD для ускорения синхронизации
- Данные сохраняются при пересоздании контейнеров

## Требования

- Linux Mint или другая Linux система
- Доступ к диску sda1
- Права root для монтирования диска

## Быстрая настройка

### Вариант 1: Автоматическая настройка

```bash
# Запуск с поддержкой sda1
sudo ./scripts/first-run-setup.sh --sda1
```

### Вариант 2: Ручная настройка

```bash
# 1. Настройка диска sda1
sudo ./scripts/setup-sda1-lighthouse.sh

# 2. Запуск с переменной окружения
export LIGHTHOUSE_DATA_PATH=/mnt/sda1/lighthouse
docker-compose -f infrastructure/geth-monitoring/docker-compose.yml --profile internal-geth up -d
```

### Вариант 3: Использование файла переменных окружения

```bash
# 1. Настройка диска sda1
sudo ./scripts/setup-sda1-lighthouse.sh

# 2. Запуск с файлом переменных окружения
docker-compose --env-file /mnt/sda1/lighthouse.env -f infrastructure/geth-monitoring/docker-compose.yml --profile internal-geth up -d
```

## Что делает скрипт setup-sda1-lighthouse.sh

1. **Проверяет наличие диска sda1**
2. **Создает точку монтирования** `/mnt/sda1`
3. **Монтирует диск** если он не смонтирован
4. **Создает директорию** `/mnt/sda1/lighthouse`
5. **Устанавливает права доступа** для Docker контейнера
6. **Добавляет монтирование в fstab** для автоматического монтирования при перезагрузке
7. **Создает файл переменных окружения** `/mnt/sda1/lighthouse.env`

## Проверка настройки

### Проверка монтирования диска
```bash
df -h /mnt/sda1
```

### Проверка прав доступа
```bash
ls -la /mnt/sda1/lighthouse
```

### Проверка статуса lighthouse
```bash
docker logs lighthouse-beacon
```

### Проверка использования диска
```bash
docker exec lighthouse-beacon df -h /root/.lighthouse
```

## Устранение неполадок

### Диск sda1 не найден
```bash
# Проверьте доступные диски
lsblk
fdisk -l
```

### Проблемы с правами доступа
```bash
# Исправьте права доступа
sudo chown -R 1000:1000 /mnt/sda1/lighthouse
sudo chmod -R 755 /mnt/sda1/lighthouse
```

### Проблемы с монтированием
```bash
# Проверьте файловую систему
sudo fsck /dev/sda1

# Принудительно смонтируйте
sudo mount -o defaults /dev/sda1 /mnt/sda1
```

## Возврат к стандартной конфигурации

Если вы хотите вернуться к использованию Docker volumes:

```bash
# Остановите контейнеры
docker-compose -f infrastructure/geth-monitoring/docker-compose.yml down

# Удалите переменную окружения
unset LIGHTHOUSE_DATA_PATH

# Запустите снова
docker-compose -f infrastructure/geth-monitoring/docker-compose.yml --profile internal-geth up -d
```

## Мониторинг

### Проверка места на диске
```bash
watch -n 5 'df -h /mnt/sda1'
```

### Проверка синхронизации lighthouse
```bash
docker logs -f lighthouse-beacon | grep -E "(synced|head|slot)"
```

### Проверка метрик
```bash
curl http://localhost:5054/metrics | grep lighthouse
```

## Безопасность

- Убедитесь, что диск sda1 не содержит важных данных
- Регулярно делайте резервные копии данных lighthouse
- Мониторьте использование диска
- Проверяйте целостность файловой системы

## Производительность

Для оптимальной производительности:

1. Используйте SSD диск для sda1
2. Убедитесь, что диск подключен через SATA III или NVMe
3. Мониторьте I/O статистику
4. Настройте правильные параметры файловой системы

```bash
# Проверка I/O статистики
iostat -x 1
```
