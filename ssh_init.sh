#!/bin/bash

# ==============================================================================
# Скрипт для генерации SSH-ключа, его копирования на удаленный сервер
# и добавления записи в локальный файл ~/.ssh/config.
# ==============================================================================

# --- НАСТРОЙКИ ---
REMOTE_USER="vovkes"
REMOTE_HOST="192.168.0.153"
# Псевдоним (алиас), который вы будете использовать для подключения, например: ssh vovkes-server
SSH_ALIAS="vovkes-server"

# Пути к файлам
PRIVATE_KEY_PATH="$HOME/.ssh/id_rsa"
PUBLIC_KEY_PATH="${PRIVATE_KEY_PATH}.pub"
SSH_CONFIG_PATH="$HOME/.ssh/config"

echo "Начинаю процесс настройки SSH-ключа для ${REMOTE_USER}@${REMOTE_HOST}"
echo "---"

# --- ШАГ 1: Проверка и генерация SSH-ключа ---
if [ ! -f "$PRIVATE_KEY_PATH" ]; then
    echo "SSH-ключ не найден. Генерирую новый ключ..."
    ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY_PATH" -N ""
    if [ $? -eq 0 ]; then
        echo "✅ Новый SSH-ключ успешно сгенерирован."
    else
        echo "❌ Ошибка при генерации ключа. Прерываю выполнение."
        exit 1
    fi
else
    echo "ℹ️  SSH-ключ уже существует в '$PRIVATE_KEY_PATH'. Пропускаю генерацию."
fi

echo "---"

# --- ШАГ 2: Копирование публичного ключа на сервер ---
if ! command -v ssh-copy-id &> /dev/null; then
    echo "❌ Ошибка: команда 'ssh-copy-id' не найдена."
    echo "Пожалуйста, установите ее (обычно пакет 'openssh-clients') или скопируйте ключ вручную."
    exit 1
fi

echo "Сейчас я попытаюсь скопировать публичный ключ на сервер."
echo "Вам нужно будет ввести пароль для пользователя '${REMOTE_USER}' на сервере ${REMOTE_HOST}."
ssh-copy-id -i "$PUBLIC_KEY_PATH" "${REMOTE_USER}@${REMOTE_HOST}"

# --- ШАГ 3: Проверка результата и обновление конфигурации ---
if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Успешно! Публичный ключ скопирован на ${REMOTE_HOST}."
    echo "---"
    echo "Обновляю локальный файл конфигурации SSH (${SSH_CONFIG_PATH})..."

    # --- ШАГ 4: Добавление записи в ~/.ssh/config ---
    CONFIG_BLOCK="
Host ${SSH_ALIAS}
    HostName ${REMOTE_HOST}
    User ${REMOTE_USER}
    IdentityFile ${PRIVATE_KEY_PATH}
"
    # Убедимся, что директория .ssh существует
    mkdir -p "$(dirname "${SSH_CONFIG_PATH}")"
    chmod 700 "$(dirname "${SSH_CONFIG_PATH}")"

    # Убедимся, что файл config существует и имеет правильные права
    touch "${SSH_CONFIG_PATH}"
    chmod 600 "${SSH_CONFIG_PATH}"

    # Проверяем, не существует ли уже такая запись
    if grep -q "Host ${SSH_ALIAS}" "${SSH_CONFIG_PATH}"; then
        echo "ℹ️  Запись для хоста '${SSH_ALIAS}' уже существует в файле конфигурации. Пропускаю."
    else
        # Добавляем новую запись в конец файла
        echo "${CONFIG_BLOCK}" >> "${SSH_CONFIG_PATH}"
        echo "✅ Новая конфигурация для '${SSH_ALIAS}' добавлена."
    fi

    echo ""
    echo "🎉 Готово! Теперь вы можете подключаться к серверу командой:"
    echo ""
    echo "  ssh ${SSH_ALIAS}"
    echo ""
else
    echo ""
    echo "❌ Ошибка! Не удалось скопировать ключ."
    echo "Попробуйте запустить скрипт еще раз, проверив данные."
fi
