# DeFi Analytics Mobile App (Flutter)

Мобильное приложение для аналитики и мониторинга DeFi протоколов с интеграцией AI/ML для предсказаний и оценки рисков.

## 🚀 Быстрый старт

### Предварительные требования

- **Flutter SDK** (версия 3.0.0+)
- **Dart** (версия 2.17.0+)
- **Android Studio** или **VS Code**
- **Android SDK** (для Android разработки)
- **Xcode** (для iOS разработки, только на macOS)

### Установка

1. **Клонирование репозитория**
```bash
git clone <repository-url>
cd defi_analytics_app
```

2. **Установка зависимостей**
```bash
flutter pub get
```

3. **Генерация кода**
```bash
flutter packages pub run build_runner build
```

4. **Запуск приложения**
```bash
flutter run
```

## 📱 Функциональность

### Основные модули

- **🔐 Аутентификация** - Безопасный вход с биометрией
- **📊 Дашборд** - Обзор рынка и ключевые метрики
- **📈 Аналитика** - Детальный анализ протоколов
- **💼 Портфель** - Управление инвестициями
- **🌐 Сети** - Мониторинг блокчейн сетей
- **🤖 AI/ML** - Предсказания и оценка рисков
- **⚙️ Настройки** - Персонализация приложения

### Поддерживаемые блокчейны

- **Ethereum & L2** - Optimism, Arbitrum, Base, zkSync
- **Cosmos** - Cosmos Hub, Osmosis, Injective
- **Polkadot** - Moonbeam, Astar, Polkadot
- **Другие** - Bitcoin, Solana, StarkNet

## 🏗️ Архитектура

### Clean Architecture + BLoC Pattern

```
lib/
├── core/                    # Основная логика
│   ├── config/             # Конфигурация
│   ├── constants/          # Константы
│   ├── errors/             # Обработка ошибок
│   ├── network/            # Сетевая логика
│   ├── storage/            # Локальное хранение
│   └── utils/              # Утилиты
├── features/               # Функциональные модули
│   ├── auth/              # Аутентификация
│   ├── dashboard/         # Дашборд
│   ├── analytics/         # Аналитика
│   ├── portfolio/         # Портфель
│   ├── networks/          # Сети
│   ├── predictions/       # AI/ML
│   └── settings/          # Настройки
├── shared/                # Общие компоненты
│   ├── widgets/           # Виджеты
│   ├── models/            # Модели
│   └── services/          # Сервисы
└── main.dart              # Точка входа
```

## 🛠️ Разработка

### Команды разработки

```bash
# Запуск в режиме разработки
flutter run

# Запуск на конкретном устройстве
flutter run -d <device-id>

# Сборка для Android
flutter build apk

# Сборка для iOS
flutter build ios

# Анализ кода
flutter analyze

# Тестирование
flutter test

# Генерация кода
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Структура проекта

```
defi_analytics_app/
├── android/               # Android специфичные файлы
├── ios/                   # iOS специфичные файлы
├── lib/                   # Dart код
│   ├── core/             # Основная логика
│   ├── features/         # Функциональные модули
│   ├── shared/           # Общие компоненты
│   └── main.dart         # Точка входа
├── assets/               # Ресурсы
│   ├── images/           # Изображения
│   ├── icons/            # Иконки
│   ├── animations/       # Анимации
│   └── fonts/            # Шрифты
├── test/                 # Тесты
├── pubspec.yaml          # Зависимости
└── README.md             # Документация
```

## 📦 Зависимости

### Основные пакеты

- **flutter_bloc** - Управление состоянием
- **go_router** - Навигация
- **dio** - HTTP клиент
- **retrofit** - API клиент
- **hive** - Локальная база данных
- **flutter_secure_storage** - Безопасное хранение
- **local_auth** - Биометрическая аутентификация
- **fl_chart** - Графики
- **syncfusion_flutter_charts** - Продвинутые диаграммы

### UI пакеты

- **flutter_svg** - SVG изображения
- **cached_network_image** - Кэширование изображений
- **shimmer** - Эффекты загрузки
- **lottie** - Анимации

## 🔧 Конфигурация

### Переменные окружения

Создайте файл `.env` в корне проекта:

```env
# API URLs
ANALYTICS_API_BASE_URL=https://api.defimon.com/analytics
AI_ML_API_BASE_URL=https://api.defimon.com/ai-ml
BLOCKCHAIN_API_BASE_URL=https://api.defimon.com/blockchain

# Firebase
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_APP_ID=your_firebase_app_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_PROJECT_ID=your_project_id

# Sentry
SENTRY_DSN=your_sentry_dsn
```

### Настройка Firebase

1. Создайте проект в Firebase Console
2. Добавьте Android и iOS приложения
3. Скачайте конфигурационные файлы:
   - `google-services.json` для Android
   - `GoogleService-Info.plist` для iOS
4. Разместите файлы в соответствующих папках

## 🧪 Тестирование

### Запуск тестов

```bash
# Все тесты
flutter test

# Конкретный тест
flutter test test/widget_test.dart

# Тесты с покрытием
flutter test --coverage
```

### Типы тестов

- **Unit Tests** - Модульные тесты
- **Widget Tests** - Тесты виджетов
- **Integration Tests** - Интеграционные тесты

## 📱 Сборка

### Android

```bash
# Debug сборка
flutter build apk --debug

# Release сборка
flutter build apk --release

# App Bundle
flutter build appbundle
```

### iOS

```bash
# Debug сборка
flutter build ios --debug

# Release сборка
flutter build ios --release
```

## 🚀 Развертывание

### Google Play Store

1. Создайте keystore для подписи
2. Настройте `android/app/build.gradle`
3. Соберите APK или App Bundle
4. Загрузите в Google Play Console

### App Store

1. Настройте сертификаты в Xcode
2. Соберите приложение
3. Загрузите через App Store Connect

## 📊 Мониторинг

### Firebase Analytics

- Отслеживание событий
- Аналитика пользователей
- Crash reporting

### Sentry

- Мониторинг ошибок
- Performance tracking
- Release tracking

## 🤝 Вклад в проект

1. Fork репозитория
2. Создайте feature branch
3. Внесите изменения
4. Добавьте тесты
5. Создайте Pull Request

## 📄 Лицензия

MIT License - см. файл [LICENSE](LICENSE) для деталей.

## 🆘 Поддержка

- **Issues**: Создайте Issue для багов или feature requests
- **Email**: support@defimon.com
- **Документация**: `/docs` - Подробная документация

## 📈 Roadmap

- [ ] WebSocket для реального времени
- [ ] Push уведомления
- [ ] Офлайн режим
- [ ] Экспорт данных
- [ ] Темная тема
- [ ] Мультиязычность
- [ ] Виджеты для главного экрана
- [ ] Apple Watch поддержка

---

**DeFi Analytics Mobile App** - Мощное мобильное приложение для аналитики и мониторинга DeFi экосистемы с поддержкой мультиблокчейн архитектуры и AI/ML возможностями.
