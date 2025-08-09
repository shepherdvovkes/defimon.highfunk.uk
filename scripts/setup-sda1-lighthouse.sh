#!/usr/bin/env bash
set -euo pipefail

# Скрипт для настройки lighthouse на диске sda1
# Использование: ./scripts/setup-sda1-lighthouse.sh

log() { echo -e "\033[0;32m[INFO]\033[0m $*"; }
warn() { echo -e "\033[0;33m[WARN]\033[0m $*"; }
err() { echo -e "\033[0;31m[ERROR]\033[0m $*" 1>&2; }

# Проверяем, что скрипт запущен от root
if [[ $EUID -ne 0 ]]; then
   err "Этот скрипт должен быть запущен от имени root"
   exit 1
fi

# Проверяем наличие диска sda1
if [[ ! -b /dev/sda1 ]]; then
    err "Диск /dev/sda1 не найден"
    echo "Доступные диски:"
    lsblk 2>/dev/null || fdisk -l 2>/dev/null || echo "Не удалось получить список дисков"
    exit 1
fi

log "Найден диск /dev/sda1"

# Проверяем, смонтирован ли диск
if ! mountpoint -q /mnt/sda1 2>/dev/null; then
    log "Создаем точку монтирования /mnt/sda1"
    mkdir -p /mnt/sda1
    
    log "Монтируем /dev/sda1 в /mnt/sda1"
    mount /dev/sda1 /mnt/sda1
    
    if [[ $? -ne 0 ]]; then
        err "Не удалось смонтировать /dev/sda1"
        exit 1
    fi
else
    log "Диск /dev/sda1 уже смонтирован в /mnt/sda1"
fi

# Создаем директорию для lighthouse
log "Создаем директорию для lighthouse"
mkdir -p /mnt/sda1/lighthouse

# Устанавливаем правильные права доступа
log "Устанавливаем права доступа"
chown -R 1000:1000 /mnt/sda1/lighthouse
chmod -R 755 /mnt/sda1/lighthouse

# Проверяем свободное место
AVAILABLE_SPACE=$(df -h /mnt/sda1 | awk 'NR==2 {print $4}')
log "Доступно места на sda1: $AVAILABLE_SPACE"

# Добавляем монтирование в fstab для автоматического монтирования при перезагрузке
if ! grep -q "/dev/sda1.*/mnt/sda1" /etc/fstab; then
    log "Добавляем монтирование в /etc/fstab"
    echo "/dev/sda1 /mnt/sda1 ext4 defaults 0 2" >> /etc/fstab
    log "Строка добавлена в /etc/fstab"
else
    log "Монтирование уже настроено в /etc/fstab"
fi

# Создаем файл с переменными окружения для docker-compose
log "Создаем файл с переменными окружения"
ENV_FILE="/mnt/sda1/lighthouse.env"
cat > "$ENV_FILE" << EOF
# Lighthouse data path for sda1
LIGHTHOUSE_DATA_PATH=/mnt/sda1/lighthouse
EOF

log "Файл переменных окружения создан: $ENV_FILE"

log "Настройка завершена успешно!"
log "Lighthouse будет использовать /mnt/sda1/lighthouse для хранения данных"
log "Для применения изменений перезапустите контейнеры:"
echo "  export LIGHTHOUSE_DATA_PATH=/mnt/sda1/lighthouse"
echo "  docker-compose -f infrastructure/geth-monitoring/docker-compose.yml down"
echo "  docker-compose -f infrastructure/geth-monitoring/docker-compose.yml --profile internal-geth up -d"
echo ""
echo "Или используйте файл переменных окружения:"
echo "  docker-compose --env-file /mnt/sda1/lighthouse.env -f infrastructure/geth-monitoring/docker-compose.yml --profile internal-geth up -d"
