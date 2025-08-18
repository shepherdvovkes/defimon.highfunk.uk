# Настройка GitHub для пользователя teo_here

## 🎯 Цель
Настроить SSH ключ и Git конфигурацию для работы с GitHub на ветке `teo_here` в проекте DEFIMON.

## 🔑 SSH ключ уже сгенерирован

SSH ключ типа ed25519 уже создан:
- **Приватный ключ**: `~/.ssh/id_ed25519_teo_here`
- **Публичный ключ**: `~/.ssh/id_ed25519_teo_here.pub`

### Публичный ключ:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOdOzpKkDj7c5r6cBv4m0HiWdo07D1NHMNjubymIwiOv teo_here@defimon.highfunk.uk
```

## 📋 Шаг 1: Добавьте SSH ключ в GitHub

1. **Перейдите в GitHub** → Settings → SSH and GPG keys
2. **Нажмите** "New SSH key"
3. **Вставьте** публичный ключ выше
4. **Дайте название**: `teo_here@defimon.highfunk.uk`
5. **Нажмите** "Add SSH key"

## ⚙️ Шаг 2: Настройка Git

### Автоматическая настройка:
```bash
./setup-git-teo-here.sh
```

### Ручная настройка:
```bash
# Настройка пользователя Git
git config user.name "teo_here"
git config user.email "teo_here@defimon.highfunk.uk"

# Настройка remote origin для SSH
git remote set-url origin git@github-teo-here:username/defimon.highfunk.uk.git
```

## 🔧 SSH конфигурация

В файле `~/.ssh/config` уже добавлен алиас:
```
Host github-teo-here
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_teo_here
  IdentitiesOnly yes
```

## 🧪 Тестирование SSH соединения

После добавления ключа в GitHub:
```bash
ssh -T github-teo-here
```

Ожидаемый результат:
```
Hi teo_here! You've successfully authenticated, but GitHub does not provide shell access.
```

## 🌿 Работа с веткой teo_here

### Создание ветки:
```bash
git checkout -b teo_here
```

### Проверка статуса:
```bash
git status
git branch
```

### Добавление и коммит изменений:
```bash
git add .
git commit -m "Update: описание изменений"
```

### Отправка в GitHub:
```bash
git push origin teo_here
```

## 📁 Структура проекта

После настройки вы сможете работать с:
- **Основная ветка**: `main` или `master`
- **Ваша ветка**: `teo_here`
- **Архитектурная документация**: `architecture/`
- **Торговые стратегии**: `architecture/trade-strategies/`

## 🚀 Полезные команды

```bash
# Проверка remote URL
git remote -v

# Изменение remote URL
git remote set-url origin git@github-teo-here:username/defimon.highfunk.uk.git

# Создание и переключение на ветку
git checkout -b teo_here

# Просмотр всех веток
git branch -a

# Синхронизация с основной веткой
git fetch origin
git merge origin/main

# Отправка изменений
git push origin teo_here

# Создание Pull Request (через GitHub веб-интерфейс)
```

## 🔍 Проверка настроек

```bash
# Проверка Git конфигурации
git config --list | grep user

# Проверка SSH ключей
ls -la ~/.ssh/id_ed25519_teo_here*

# Проверка SSH конфигурации
cat ~/.ssh/config | grep -A 4 "github-teo-here"

# Проверка remote URL
git remote get-url origin
```

## ⚠️ Важные замечания

1. **SSH ключ** должен быть добавлен в GitHub до тестирования соединения
2. **Remote URL** должен использовать алиас `github-teo-here`
3. **Пользователь Git** должен быть настроен как `teo_here`
4. **Ветка** должна быть создана локально перед push

## 🆘 Решение проблем

### Ошибка "Permission denied (publickey)":
- Проверьте, что SSH ключ добавлен в GitHub
- Убедитесь, что используется правильный алиас `github-teo-here`

### Ошибка "fatal: remote origin already exists":
- Используйте `git remote set-url origin` вместо `git remote add origin`

### Ошибка "fatal: refusing to merge unrelated histories":
- Используйте `git pull origin main --allow-unrelated-histories`

---

**Настройка завершена!** 🎉
Теперь вы можете работать с GitHub на ветке `teo_here` используя SSH аутентификацию.
