# 🚀 Руководство разработчика - DeFi Analytics Mobile App

## 📋 Содержание

1. [Быстрый старт](#быстрый-старт)
2. [Архитектура](#архитектура)
3. [Стандарты кодирования](#стандарты-кодирования)
4. [Рабочий процесс](#рабочий-процесс)
5. [Отладка и тестирование](#отладка-и-тестирование)
6. [Развертывание](#развертывание)

## 🚀 Быстрый старт

### Предварительные требования

- **Flutter SDK**: 3.16.0+
- **Dart SDK**: 3.2.0+
- **Android Studio** / **VS Code**
- **Git**
- **Node.js** (для генерации кода)

### Установка и настройка

```bash
# 1. Клонирование репозитория
git clone <repository-url>
cd defi_analytics_app

# 2. Установка зависимостей
flutter pub get

# 3. Генерация кода
flutter packages pub run build_runner build --delete-conflicting-outputs

# 4. Запуск приложения
flutter run
```

### Настройка окружения

#### Android
```bash
# Проверка Android SDK
flutter doctor --android-licenses

# Настройка эмулятора
flutter emulators --create --name pixel_6_api_34
flutter emulators --launch pixel_6_api_34
```

#### iOS
```bash
# Установка CocoaPods
sudo gem install cocoapods

# Установка зависимостей iOS
cd ios && pod install && cd ..
```

### Конфигурация Firebase

1. Создайте проект в [Firebase Console](https://console.firebase.google.com/)
2. Добавьте приложения для Android и iOS
3. Скачайте конфигурационные файлы:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

4. Обновите `lib/core/config/firebase_options.dart`:

```dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Замените на ваши настройки
    return const FirebaseOptions(
      apiKey: 'your-api-key',
      appId: 'your-app-id',
      messagingSenderId: 'your-sender-id',
      projectId: 'your-project-id',
    );
  }
}
```

## 🏗️ Архитектура

### Clean Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                      │
│  (UI, BLoC, Widgets)                                      │
├─────────────────────────────────────────────────────────────┤
│                    DOMAIN LAYER                            │
│  (Use Cases, Entities, Repository Interfaces)             │
├─────────────────────────────────────────────────────────────┤
│                    DATA LAYER                              │
│  (Repository Implementations, API, Local Storage)         │
└─────────────────────────────────────────────────────────────┘
```

### Структура проекта

```
lib/
├── core/                    # Основная логика
│   ├── config/             # Конфигурация
│   │   ├── app_config.dart
│   │   ├── firebase_options.dart
│   │   └── environment.dart
│   ├── constants/          # Константы
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_constants.dart
│   ├── errors/             # Обработка ошибок
│   │   ├── app_exception.dart
│   │   ├── network_exception.dart
│   │   └── validation_exception.dart
│   ├── network/            # Сетевая логика
│   │   ├── dio_client.dart
│   │   ├── interceptors/
│   │   └── api_endpoints.dart
│   ├── storage/            # Локальное хранение
│   │   ├── hive_storage.dart
│   │   ├── secure_storage.dart
│   │   └── shared_preferences.dart
│   └── utils/              # Утилиты
│       ├── date_utils.dart
│       ├── number_utils.dart
│       └── validation_utils.dart
├── features/               # Функциональные модули
│   ├── auth/              # Аутентификация
│   │   ├── bloc/
│   │   │   ├── auth_bloc.dart
│   │   │   ├── auth_event.dart
│   │   │   └── auth_state.dart
│   │   ├── repository/
│   │   │   └── auth_repository.dart
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── biometric_auth_screen.dart
│   │   └── widgets/
│   │       ├── login_form.dart
│   │       └── biometric_button.dart
│   ├── dashboard/         # Главный дашборд
│   │   ├── bloc/
│   │   ├── screens/
│   │   └── widgets/
│   ├── analytics/         # Аналитика
│   ├── portfolio/         # Портфель
│   ├── networks/          # Сети
│   ├── predictions/       # Предсказания
│   └── settings/          # Настройки
├── shared/                # Общие компоненты
│   ├── widgets/           # Переиспользуемые виджеты
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   ├── loading_widget.dart
│   │   └── error_widget.dart
│   ├── models/            # Общие модели
│   │   ├── user.dart
│   │   ├── app_settings.dart
│   │   └── api_response.dart
│   └── services/          # Общие сервисы
│       ├── analytics_service.dart
│       ├── error_reporting_service.dart
│       └── performance_service.dart
└── main.dart              # Точка входа
```

### BLoC Pattern

#### Структура BLoC

```dart
// 1. Events (события)
abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  
  const LoginRequested({required this.email, required this.password});
  
  @override
  List<Object?> get props => [email, password];
}

// 2. States (состояния)
abstract class AuthState extends Equatable {
  const AuthState();
}

class AuthInitial extends AuthState {
  @override
  List<Object?> get props => [];
}

class AuthLoading extends AuthState {
  @override
  List<Object?> get props => [];
}

class AuthSuccess extends AuthState {
  final User user;
  const AuthSuccess(this.user);
  
  @override
  List<Object?> get props => [user];
}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  
  @override
  List<Object?> get props => [message];
}

// 3. BLoC (бизнес-логика)
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  
  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
  }
  
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
```

#### Использование BLoC

```dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(
        context.read<AuthRepository>(),
      ),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Scaffold(
          body: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return LoginForm();
            },
          ),
        ),
      ),
    );
  }
}
```

## 📝 Стандарты кодирования

### Именование

#### Файлы и папки
```dart
// ✅ Правильно
auth_bloc.dart
user_model.dart
analytics_service.dart
login_screen.dart

// ❌ Неправильно
AuthBloc.dart
userModel.dart
AnalyticsService.dart
LoginScreen.dart
```

#### Классы
```dart
// ✅ Правильно
class UserRepository {}
class AuthBloc {}
class LoginScreen {}

// ❌ Неправильно
class userRepository {}
class authBloc {}
class loginScreen {}
```

#### Переменные и методы
```dart
// ✅ Правильно
String userName;
int totalValue;
Future<void> getUserData() {}
void calculateTotal() {}

// ❌ Неправильно
String UserName;
int TotalValue;
Future<void> get_user_data() {}
void CalculateTotal() {}
```

### Структура кода

#### Импорты
```dart
// 1. Dart imports
import 'dart:async';
import 'dart:io';

// 2. Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Third-party imports
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';

// 4. Local imports
import '../models/user.dart';
import '../services/auth_service.dart';
```

#### Документация
```dart
/// Сервис для работы с аутентификацией пользователей.
/// 
/// Предоставляет методы для входа, регистрации и управления сессией.
/// Использует JWT токены для безопасной аутентификации.
class AuthService {
  final Dio _dio;
  final SecureStorage _storage;
  
  /// Создает новый экземпляр [AuthService].
  /// 
  /// [dio] - HTTP клиент для API запросов
  /// [storage] - безопасное хранилище для токенов
  AuthService(this._dio, this._storage);
  
  /// Выполняет вход пользователя в систему.
  /// 
  /// [email] - email пользователя
  /// [password] - пароль пользователя
  /// 
  /// Возвращает [User] объект при успешном входе.
  /// 
  /// Выбрасывает [AuthException] при ошибке аутентификации.
  Future<User> login({
    required String email,
    required String password,
  }) async {
    // Реализация
  }
}
```

### Обработка ошибок

#### Иерархия исключений
```dart
abstract class AppException implements Exception {
  final String message;
  final String? code;
  
  const AppException(this.message, [this.code]);
  
  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  final int? statusCode;
  
  const NetworkException(String message, {this.statusCode}) 
    : super(message, 'NETWORK_ERROR');
}

class ValidationException extends AppException {
  const ValidationException(String message) 
    : super(message, 'VALIDATION_ERROR');
}

class AuthException extends AppException {
  const AuthException(String message) 
    : super(message, 'AUTH_ERROR');
}
```

#### Обработка в BLoC
```dart
Future<void> _onLoginRequested(
  LoginRequested event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());
  
  try {
    final user = await _authRepository.login(
      email: event.email,
      password: event.password,
    );
    emit(AuthSuccess(user));
  } on ValidationException catch (e) {
    emit(AuthFailure('Неверный формат данных: ${e.message}'));
  } on NetworkException catch (e) {
    emit(AuthFailure('Ошибка сети: ${e.message}'));
  } on AuthException catch (e) {
    emit(AuthFailure('Ошибка аутентификации: ${e.message}'));
  } catch (e) {
    emit(AuthFailure('Неизвестная ошибка: $e'));
  }
}
```

## 🔄 Рабочий процесс

### Git Flow

```bash
# 1. Создание feature ветки
git checkout -b feature/user-authentication

# 2. Разработка
# ... работа над кодом ...

# 3. Коммиты
git add .
git commit -m "feat: add user authentication with biometric support"

# 4. Push и создание Pull Request
git push origin feature/user-authentication
```

### Коммиты

#### Conventional Commits
```bash
# Типы коммитов
feat:     новая функция
fix:      исправление бага
docs:     документация
style:    форматирование кода
refactor: рефакторинг
test:     тесты
chore:    настройка проекта
```

#### Примеры
```bash
feat: add user authentication with biometric support
fix: resolve memory leak in image caching
docs: update API documentation
style: format code according to style guide
refactor: extract common widgets to shared components
test: add unit tests for auth repository
chore: update dependencies to latest versions
```

### Code Review

#### Чек-лист для ревьюера
- [ ] Код соответствует стандартам проекта
- [ ] Нет дублирования кода
- [ ] Правильная обработка ошибок
- [ ] Добавлены тесты для новой функциональности
- [ ] Документация обновлена
- [ ] Производительность не ухудшена
- [ ] Безопасность соблюдена

#### Чек-лист для автора
- [ ] Код протестирован локально
- [ ] Все тесты проходят
- [ ] Документация обновлена
- [ ] Коммиты логично разделены
- [ ] Описание PR понятное и полное

## 🐛 Отладка и тестирование

### Отладка

#### Flutter Inspector
```bash
# Запуск с включенным Inspector
flutter run --debug
```

#### Логирование
```dart
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );
  
  static void debug(String message) => _logger.d(message);
  static void info(String message) => _logger.i(message);
  static void warning(String message) => _logger.w(message);
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
```

#### Performance Overlay
```dart
// Включение в debug режиме
void main() {
  runApp(
    MaterialApp(
      home: MyApp(),
      showPerformanceOverlay: kDebugMode,
    ),
  );
}
```

### Тестирование

#### Unit Tests
```dart
// test/features/auth/repository/auth_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('AuthRepository', () {
    late AuthRepository authRepository;
    late MockAuthService mockAuthService;
    late MockStorageService mockStorageService;
    
    setUp(() {
      mockAuthService = MockAuthService();
      mockStorageService = MockStorageService();
      authRepository = AuthRepository(mockAuthService, mockStorageService);
    });
    
    test('login returns user on successful authentication', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      const user = User(id: '1', email: email, name: 'Test User');
      
      when(mockAuthService.login(email: email, password: password))
          .thenAnswer((_) async => user);
      
      // Act
      final result = await authRepository.login(email: email, password: password);
      
      // Assert
      expect(result, equals(user));
      verify(mockStorageService.saveUser(user)).called(1);
    });
    
    test('login throws AuthException on invalid credentials', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'wrongpassword';
      
      when(mockAuthService.login(email: email, password: password))
          .thenThrow(AuthException('Invalid credentials'));
      
      // Act & Assert
      expect(
        () => authRepository.login(email: email, password: password),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
```

#### Widget Tests
```dart
// test/features/auth/screens/login_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  group('LoginScreen', () {
    late MockAuthBloc mockAuthBloc;
    
    setUp(() {
      mockAuthBloc = MockAuthBloc();
    });
    
    testWidgets('displays login form', (WidgetTester tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthInitial());
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: LoginScreen(),
          ),
        ),
      );
      
      // Assert
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
    
    testWidgets('shows loading indicator when authenticating', (WidgetTester tester) async {
      // Arrange
      when(mockAuthBloc.state).thenReturn(AuthLoading());
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: LoginScreen(),
          ),
        ),
      );
      
      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
```

#### Integration Tests
```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('App Integration Tests', () {
    testWidgets('complete user authentication flow', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      
      // Login screen should be displayed
      expect(find.byType(LoginScreen), findsOneWidget);
      
      // Enter credentials
      await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'password123');
      
      // Tap login button
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();
      
      // Dashboard should be displayed
      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });
}
```

## 🚀 Развертывание

### Подготовка к релизу

#### Android
```bash
# Создание keystore
keytool -genkey -v -keystore android/app/keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Настройка подписи в android/app/build.gradle
android {
  signingConfigs {
    release {
      keyAlias 'upload'
      keyPassword 'your-key-password'
      storeFile file('keystore.jks')
      storePassword 'your-store-password'
    }
  }
  
  buildTypes {
    release {
      signingConfig signingConfigs.release
      minifyEnabled true
      proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
  }
}
```

#### iOS
```bash
# Настройка подписи в Xcode
# 1. Откройте ios/Runner.xcworkspace
# 2. Выберите Runner target
# 3. В Signing & Capabilities настройте Team и Bundle Identifier
# 4. Создайте App Store provisioning profile
```

### Сборка релиза

#### Android
```bash
# Сборка APK
flutter build apk --release

# Сборка AAB (рекомендуется для Play Store)
flutter build appbundle --release
```

#### iOS
```bash
# Сборка для симулятора
flutter build ios --debug

# Сборка для устройства
flutter build ios --release

# Сборка для App Store
flutter build ios --release --no-codesign
```

### Автоматизация с Fastlane

```bash
# Установка Fastlane
gem install fastlane

# Инициализация для Android
cd android && fastlane init

# Инициализация для iOS
cd ios && fastlane init
```

#### Android Fastfile
```ruby
# android/fastlane/Fastfile
default_platform(:android)

platform :android do
  desc "Build and upload to Play Store"
  lane :release do
    gradle(
      task: "clean bundleRelease",
      project_dir: "."
    )
    
    upload_to_play_store(
      track: 'production',
      aab: '../build/app/outputs/bundle/release/app-release.aab'
    )
  end
end
```

#### iOS Fastfile
```ruby
# ios/fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Build and upload to App Store"
  lane :release do
    build_ios_app(
      scheme: "Runner",
      export_method: "app-store",
      configuration: "Release"
    )
    
    upload_to_app_store(
      force: true,
      skip_metadata: true,
      skip_screenshots: true
    )
  end
end
```

### Мониторинг после релиза

#### Firebase Analytics
```dart
// Отслеживание событий
await FirebaseAnalytics.instance.logEvent(
  name: 'app_opened',
  parameters: {
    'user_id': userId,
    'app_version': appVersion,
  },
);
```

#### Crashlytics
```dart
// Отслеживание ошибок
await FirebaseCrashlytics.instance.recordError(
  error,
  stackTrace,
  reason: 'User authentication failed',
);
```

---

**🎉 Руководство разработчика готово!**

Теперь у вас есть полное руководство для эффективной разработки DeFi Analytics Mobile App с соблюдением всех лучших практик и стандартов.
