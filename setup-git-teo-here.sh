#!/bin/bash

# Скрипт для настройки Git с пользователем teo_here
# Используется для работы с веткой teo_here в GitHub

echo "🔑 Настройка Git для пользователя teo_here..."

# Проверяем, что SSH ключ существует
if [ ! -f ~/.ssh/id_ed25519_teo_here ]; then
    echo "❌ SSH ключ не найден: ~/.ssh/id_ed25519_teo_here"
    echo "Сначала сгенерируйте SSH ключ:"
    echo "ssh-keygen -t ed25519 -C 'teo_here@defimon.highfunk.uk' -f ~/.ssh/id_ed25519_teo_here"
    exit 1
fi

# Показываем публичный ключ для добавления в GitHub
echo "📋 Публичный SSH ключ для добавления в GitHub:"
echo "================================================"
cat ~/.ssh/id_ed25519_teo_here.pub
echo "================================================"
echo ""
echo "📝 Инструкции:"
echo "1. Скопируйте публичный ключ выше"
echo "2. Перейдите в GitHub → Settings → SSH and GPG keys"
echo "3. Нажмите 'New SSH key'"
echo "4. Вставьте ключ и дайте название 'teo_here@defimon.highfunk.uk'"
echo "5. Нажмите 'Add SSH key'"
echo ""

# Настраиваем Git для текущего репозитория
echo "⚙️  Настройка Git для текущего репозитория..."

# Проверяем, что мы в Git репозитории
if [ ! -d .git ]; then
    echo "❌ Текущая папка не является Git репозиторием"
    exit 1
fi

# Настраиваем Git пользователя
git config user.name "teo_here"
git config user.email "teo_here@defimon.highfunk.uk"

echo "✅ Git пользователь настроен:"
echo "   Имя: $(git config user.name)"
echo "   Email: $(git config user.email)"

# Настраиваем remote origin для использования SSH
echo "🔗 Настройка remote origin для SSH..."

# Получаем текущий remote URL
CURRENT_REMOTE=$(git remote get-url origin)
echo "Текущий remote: $CURRENT_REMOTE"

# Если remote использует HTTPS, конвертируем в SSH
if [[ $CURRENT_REMOTE == https://* ]]; then
    # Извлекаем username и repository из HTTPS URL
    REPO_PATH=$(echo $CURRENT_REMOTE | sed 's|https://github.com/||')
    SSH_URL="git@github-teo-here:$REPO_PATH"
    
    echo "🔄 Конвертируем HTTPS в SSH..."
    git remote set-url origin "$SSH_URL"
    echo "✅ Remote origin обновлен: $SSH_URL"
elif [[ $CURRENT_REMOTE == git@github.com:* ]]; then
    # Если уже SSH, обновляем для использования нашего алиаса
    REPO_PATH=$(echo $CURRENT_REMOTE | sed 's|git@github.com:||')
    SSH_URL="git@github-teo-here:$REPO_PATH"
    
    echo "🔄 Обновляем SSH URL для использования алиаса github-teo-here..."
    git remote set-url origin "$SSH_URL"
    echo "✅ Remote origin обновлен: $SSH_URL"
else
    echo "ℹ️  Remote origin уже настроен правильно"
fi

echo ""
echo "🚀 Настройка завершена!"
echo ""
echo "📋 Следующие шаги:"
echo "1. Добавьте SSH ключ в GitHub (см. инструкции выше)"
echo "2. Протестируйте соединение: ssh -T github-teo-here"
echo "3. Создайте ветку teo_here: git checkout -b teo_here"
echo "4. Работайте с репозиторием: git push origin teo_here"
echo ""
echo "🔧 Полезные команды:"
echo "   git status                    # Статус репозитория"
echo "   git branch                    # Список веток"
echo "   git checkout teo_here        # Переключиться на ветку teo_here"
echo "   git add .                     # Добавить все изменения"
echo "   git commit -m 'message'      # Сделать коммит"
echo "   git push origin teo_here     # Отправить изменения в GitHub"
