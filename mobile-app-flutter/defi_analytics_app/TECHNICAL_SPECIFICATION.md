# Техническое задание: DeFi Analytics Mobile App (Flutter)

## 1. Общие сведения

### 1.1 Назначение приложения
Мобильное приложение для мониторинга и аналитики DeFi протоколов с интеграцией AI/ML для предсказаний и оценки рисков. Приложение предоставляет доступ к данным о более чем 50 L2 сетях, Cosmos экосистеме, Polkadot парачейнах и других блокчейнах.

### 1.2 Целевая аудитория
- **DeFi инвесторы** - для мониторинга портфеля и принятия инвестиционных решений
- **Трейдеры** - для анализа рыночных трендов и возможностей арбитража
- **Аналитики** - для глубокого анализа протоколов и сетей
- **Разработчики** - для мониторинга смарт-контрактов и сетевой активности

### 1.3 Платформы
- **iOS** (версия 13.0+)
- **Android** (версия 8.0+)

## 2. Архитектура приложения

### 2.1 Clean Architecture с BLoC Pattern

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                      │
├─────────────────────────────────────────────────────────────┤
│  Screens/Pages     │  Widgets        │  BLoC/Cubit        │
│  • Dashboard       │  • Charts       │  • AuthBloc        │
│  • Analytics       │  • Cards        │  • AnalyticsBloc   │
│  • Portfolio       │  • Forms        │  • PortfolioBloc   │
│  • Settings        │  • Navigation   │  • NetworksBloc    │
└─────────────────────────────────────────────────────────────┘
                                        │
┌─────────────────────────────────────────────────────────────┐
│                    DOMAIN LAYER                            │
├─────────────────────────────────────────────────────────────┤
│  Use Cases         │  Entities       │  Repository        │
│  • Get Protocols   │  • Protocol     │  • AnalyticsRepo   │
│  • Get Predictions │  • Network      │  • PortfolioRepo   │
│  • Get Portfolio   │  • Portfolio    │  • AuthRepo        │
│  • Get Networks    │  • User         │  • StorageRepo     │
└─────────────────────────────────────────────────────────────┘
                                        │
┌─────────────────────────────────────────────────────────────┐
│                    DATA LAYER                              │
├─────────────────────────────────────────────────────────────┤
│  API Clients       │  Local Storage  │  External Services │
│  • Analytics API   │  • Hive         │  • Firebase        │
│  • AI/ML Service   │  • SharedPrefs  │  • WebSocket       │
│  • Blockchain API  │  • SecureStore  │  • Push Notifications│
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Структура проекта

```
lib/
├── core/                    # Основная логика
│   ├── config/             # Конфигурация приложения
│   ├── constants/          # Константы
│   ├── errors/             # Обработка ошибок
│   ├── network/            # Сетевая логика
│   ├── storage/            # Локальное хранение
│   └── utils/              # Утилиты
├── features/               # Функциональные модули
│   ├── auth/              # Аутентификация
│   ├── dashboard/         # Главный дашборд
│   ├── analytics/         # Аналитика протоколов
│   ├── portfolio/         # Управление портфелем
│   ├── networks/          # Мониторинг сетей
│   ├── predictions/       # AI/ML предсказания
│   └── settings/          # Настройки
├── shared/                # Общие компоненты
│   ├── widgets/           # Переиспользуемые виджеты
│   ├── models/            # Общие модели
│   └── services/          # Общие сервисы
└── main.dart              # Точка входа
```

## 3. Функциональные требования

### 3.1 Основные модули

#### 3.1.1 Аутентификация (Auth Feature)
- **Биометрическая аутентификация** - Face ID, Touch ID, отпечаток пальца
- **JWT токены** - безопасное хранение и обновление
- **Двухфакторная аутентификация** - 2FA через SMS/email
- **Автоматический выход** - по истечении сессии

#### 3.1.2 Дашборд (Dashboard Feature)
- **Обзор рынка** - общая статистика DeFi экосистемы
- **Топ протоколов** - рейтинг по TVL, объему торгов, доходам
- **Персонализированные виджеты** - настраиваемые карточки
- **Уведомления** - push-уведомления о важных событиях
- **Быстрые действия** - добавление в портфель, сравнение

#### 3.1.3 Аналитика (Analytics Feature)
- **Список протоколов** - с фильтрацией и поиском
- **Детальная информация** - TVL, объемы, доходы, пользователи
- **Исторические данные** - графики за 1д, 7д, 30д, 1г
- **Сравнение протоколов** - side-by-side анализ
- **Экспорт данных** - выгрузка отчетов в PDF/CSV

#### 3.1.4 Портфель (Portfolio Feature)
- **Управление позициями** - добавление, редактирование, удаление
- **Отслеживание P&L** - прибыль/убыток в реальном времени
- **Распределение активов** - круговые диаграммы
- **История транзакций** - детальная информация
- **Настройка уведомлений** - алерты по ценам, рискам

#### 3.1.5 Сети (Networks Feature)
- **Мониторинг L2 сетей** - Optimism, Arbitrum, Base, zkSync
- **Cosmos экосистема** - Cosmos Hub, Osmosis, Injective
- **Polkadot парачейны** - Moonbeam, Astar, Polkadot
- **Статус нод** - мониторинг синхронизации
- **Метрики сети** - блоки, транзакции, комиссии

#### 3.1.6 Предсказания (Predictions Feature)
- **AI предсказания цен** - для токенов и протоколов
- **Оценка рисков** - автоматическая оценка рисков
- **Аномальное обнаружение** - выявление подозрительной активности
- **Рекомендации** - персонализированные советы
- **Историческая точность** - статистика предсказаний

#### 3.1.7 Настройки (Settings Feature)
- **Профиль пользователя** - личная информация
- **Безопасность** - настройки аутентификации
- **Уведомления** - типы и частота уведомлений
- **Внешний вид** - темная/светлая тема
- **Язык** - русский и английский

### 3.2 Дополнительные функции

#### 3.2.1 Офлайн режим
- **Кэширование данных** - работа без интернета
- **Синхронизация** - автоматическая при подключении
- **Локальные уведомления** - в офлайн режиме

#### 3.2.2 Персонализация
- **Настройка дашборда** - перестановка виджетов
- **Избранные протоколы** - быстрый доступ
- **Пользовательские алерты** - настройка уведомлений

## 4. Технические требования

### 4.1 Зависимости

#### 4.1.1 UI & Navigation
```yaml
cupertino_icons: ^1.0.2
flutter_svg: ^2.0.9
cached_network_image: ^3.3.0
shimmer: ^3.0.0
lottie: ^2.7.0
go_router: ^12.1.3
```

#### 4.1.2 State Management
```yaml
flutter_bloc: ^8.1.3
equatable: ^2.0.5
```

#### 4.1.3 Network & API
```yaml
dio: ^5.3.2
retrofit: ^4.0.3
json_annotation: ^4.8.1
web_socket_channel: ^2.4.0
```

#### 4.1.4 Charts & Analytics
```yaml
fl_chart: ^0.65.0
syncfusion_flutter_charts: ^23.1.44
syncfusion_flutter_gauges: ^23.1.44
```

#### 4.1.5 Storage & Security
```yaml
shared_preferences: ^2.2.2
hive: ^2.2.3
hive_flutter: ^1.1.0
flutter_secure_storage: ^9.0.0
local_auth: ^2.1.7
```

#### 4.1.6 Notifications
```yaml
firebase_messaging: ^14.7.10
firebase_core: ^2.24.2
```

### 4.2 API интеграция

#### 4.2.1 Analytics API
```dart
// Базовый URL
const String analyticsApiBase = 'https://api.defimon.com/analytics';

// Основные эндпоинты
class AnalyticsEndpoints {
  static const String overview = '/api/analytics/overview';
  static const String trends = '/api/analytics/trends';
  static const String protocols = '/api/protocols';
  static const String protocolMetrics = '/api/protocols/{protocol}/metrics';
  static const String compare = '/api/analytics/compare';
  static const String realTime = '/api/analytics/real-time';
}
```

#### 4.2.2 AI/ML Service
```dart
// Базовый URL
const String aiMlApiBase = 'https://api.defimon.com/ai-ml';

// AI/ML эндпоинты
class AIMLEndpoints {
  static const String predict = '/predict';
  static const String riskAssessment = '/risk-assessment';
  static const String modelStatus = '/models/status';
  static const String retrain = '/models/retrain';
}
```

#### 4.2.3 WebSocket
```dart
// WebSocket для реального времени
const String websocketUrl = 'wss://api.defimon.com/ws';

// События WebSocket
enum WebSocketEvents {
  tvlUpdate,
  priceUpdate,
  riskAlert,
  networkStatus,
}
```

### 4.3 Дизайн-система

#### 4.3.1 Цветовая палитра
```dart
class AppColors {
  // Основные цвета
  static const Color primary = Color(0xFF6366F1);      // Индиго
  static const Color secondary = Color(0xFF8B5CF6);    // Фиолетовый
  static const Color success = Color(0xFF10B981);      // Зеленый
  static const Color warning = Color(0xFFF59E0B);      // Оранжевый
  static const Color error = Color(0xFFEF4444);        // Красный
  
  // Нейтральные цвета
  static const Color background = Color(0xFFFFFFFF);    // Белый
  static const Color surface = Color(0xFFF8FAFC);      // Светло-серый
  static const Color textPrimary = Color(0xFF1E293B);  // Темно-серый
  static const Color textSecondary = Color(0xFF64748B); // Средне-серый
  static const Color textDisabled = Color(0xFF94A3B8); // Светло-серый
  
  // Темная тема
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
}
```

#### 4.3.2 Типографика
```dart
class AppTypography {
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    fontFamily: 'Inter',
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: 'Inter',
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontFamily: 'Inter',
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    fontFamily: 'Inter',
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    fontFamily: 'Inter',
  );
}
```

## 5. Экраны приложения

### 5.1 Auth Screens
- **LoginScreen** - экран входа
- **RegisterScreen** - экран регистрации
- **ForgotPasswordScreen** - восстановление пароля
- **BiometricAuthScreen** - биометрическая аутентификация

### 5.2 Dashboard Screens
- **DashboardScreen** - главный дашборд
- **MarketOverviewScreen** - обзор рынка
- **TopProtocolsScreen** - топ протоколов
- **QuickActionsScreen** - быстрые действия

### 5.3 Analytics Screens
- **ProtocolsListScreen** - список протоколов
- **ProtocolDetailScreen** - детали протокола
- **ComparisonScreen** - сравнение протоколов
- **TrendsScreen** - тренды и графики

### 5.4 Portfolio Screens
- **PortfolioOverviewScreen** - обзор портфеля
- **AddPositionScreen** - добавление позиции
- **TransactionHistoryScreen** - история транзакций
- **PerformanceScreen** - производительность

### 5.5 Networks Screens
- **NetworksListScreen** - список сетей
- **NetworkDetailScreen** - детали сети
- **NodeStatusScreen** - статус нод
- **NetworkMetricsScreen** - метрики сети

### 5.6 Predictions Screens
- **AIPredictionsScreen** - AI предсказания
- **RiskAssessmentScreen** - оценка рисков
- **ModelStatusScreen** - статус моделей
- **RecommendationsScreen** - рекомендации

### 5.7 Settings Screens
- **ProfileScreen** - профиль пользователя
- **SecurityScreen** - настройки безопасности
- **NotificationsScreen** - настройки уведомлений
- **AppearanceScreen** - внешний вид
- **AboutScreen** - о приложении

## 6. BLoC/Cubit структура

### 6.1 Auth BLoC
```dart
// Auth Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  
  const LoginRequested({required this.email, required this.password});
}

class BiometricAuthRequested extends AuthEvent {}

class LogoutRequested extends AuthEvent {}

// Auth States
abstract class AuthState extends Equatable {
  const AuthState();
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {
  final User user;
  const AuthSuccess(this.user);
}
class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
}
```

### 6.2 Analytics BLoC
```dart
// Analytics Events
abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();
}

class LoadProtocols extends AnalyticsEvent {
  final String? category;
  final String? search;
  
  const LoadProtocols({this.category, this.search});
}

class LoadProtocolDetails extends AnalyticsEvent {
  final String protocolId;
  const LoadProtocolDetails(this.protocolId);
}

class CompareProtocols extends AnalyticsEvent {
  final List<String> protocolIds;
  const CompareProtocols(this.protocolIds);
}

// Analytics States
abstract class AnalyticsState extends Equatable {
  const AnalyticsState();
}

class AnalyticsInitial extends AnalyticsState {}
class AnalyticsLoading extends AnalyticsState {}
class AnalyticsLoaded extends AnalyticsState {
  final List<Protocol> protocols;
  const AnalyticsLoaded(this.protocols);
}
class AnalyticsError extends AnalyticsState {
  final String message;
  const AnalyticsError(this.message);
}
```

## 7. Модели данных

### 7.1 Protocol Model
```dart
@JsonSerializable()
class Protocol extends Equatable {
  final String id;
  final String name;
  final String displayName;
  final String category;
  final String network;
  final double totalValueLocked;
  final double volume24h;
  final double fees24h;
  final int users;
  final double apy;
  final String riskLevel;
  final DateTime lastUpdated;
  
  const Protocol({
    required this.id,
    required this.name,
    required this.displayName,
    required this.category,
    required this.network,
    required this.totalValueLocked,
    required this.volume24h,
    required this.fees24h,
    required this.users,
    required this.apy,
    required this.riskLevel,
    required this.lastUpdated,
  });
  
  factory Protocol.fromJson(Map<String, dynamic> json) =>
      _$ProtocolFromJson(json);
  
  Map<String, dynamic> toJson() => _$ProtocolToJson(this);
  
  @override
  List<Object?> get props => [
    id, name, displayName, category, network,
    totalValueLocked, volume24h, fees24h, users, apy,
    riskLevel, lastUpdated,
  ];
}
```

### 7.2 Network Model
```dart
@JsonSerializable()
class Network extends Equatable {
  final String id;
  final String name;
  final String type; // L2, Cosmos, Polkadot, etc.
  final String status; // online, offline, syncing
  final int blockHeight;
  final double totalValueLocked;
  final double transactionVolume;
  final double gasPrice;
  final DateTime lastBlockTime;
  
  const Network({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.blockHeight,
    required this.totalValueLocked,
    required this.transactionVolume,
    required this.gasPrice,
    required this.lastBlockTime,
  });
  
  factory Network.fromJson(Map<String, dynamic> json) =>
      _$NetworkFromJson(json);
  
  Map<String, dynamic> toJson() => _$NetworkToJson(this);
  
  @override
  List<Object?> get props => [
    id, name, type, status, blockHeight,
    totalValueLocked, transactionVolume, gasPrice, lastBlockTime,
  ];
}
```

### 7.3 Portfolio Model
```dart
@JsonSerializable()
class PortfolioPosition extends Equatable {
  final String id;
  final String protocolId;
  final String tokenAddress;
  final double amount;
  final double value;
  final double pnl;
  final double pnlPercentage;
  final DateTime addedAt;
  final DateTime? lastUpdated;
  
  const PortfolioPosition({
    required this.id,
    required this.protocolId,
    required this.tokenAddress,
    required this.amount,
    required this.value,
    required this.pnl,
    required this.pnlPercentage,
    required this.addedAt,
    this.lastUpdated,
  });
  
  factory PortfolioPosition.fromJson(Map<String, dynamic> json) =>
      _$PortfolioPositionFromJson(json);
  
  Map<String, dynamic> toJson() => _$PortfolioPositionToJson(this);
  
  @override
  List<Object?> get props => [
    id, protocolId, tokenAddress, amount, value,
    pnl, pnlPercentage, addedAt, lastUpdated,
  ];
}
```

## 8. Сервисы

### 8.1 Analytics Service
```dart
@RestApi(baseUrl: "https://api.defimon.com/analytics")
abstract class AnalyticsService {
  factory AnalyticsService(Dio dio, {String baseUrl}) = _AnalyticsService;
  
  @GET('/api/analytics/overview')
  Future<MarketOverview> getMarketOverview();
  
  @GET('/api/analytics/trends')
  Future<List<TrendData>> getMarketTrends({
    @Query('timeframe') String timeframe = '7d',
  });
  
  @GET('/api/protocols')
  Future<List<Protocol>> getProtocols({
    @Query('category') String? category,
    @Query('search') String? search,
    @Query('limit') int limit = 50,
  });
  
  @GET('/api/protocols/{protocolId}/metrics')
  Future<ProtocolMetrics> getProtocolMetrics(
    @Path('protocolId') String protocolId,
  );
  
  @GET('/api/analytics/compare')
  Future<ComparisonData> compareProtocols({
    @Query('protocols') List<String> protocols,
    @Query('metric') String metric = 'tvl',
  });
}
```

### 8.2 AI/ML Service
```dart
@RestApi(baseUrl: "https://api.defimon.com/ai-ml")
abstract class AIMLService {
  factory AIMLService(Dio dio, {String baseUrl}) = _AIMLService;
  
  @POST('/predict')
  Future<PredictionResult> getPrediction(
    @Body() PredictionRequest request,
  );
  
  @POST('/risk-assessment')
  Future<RiskAssessment> getRiskAssessment(
    @Body() RiskAssessmentRequest request,
  );
  
  @GET('/models/status')
  Future<List<ModelStatus>> getModelStatus();
  
  @POST('/models/retrain')
  Future<void> retrainModels();
}
```

### 8.3 Storage Service
```dart
class StorageService {
  static const String _hiveBoxName = 'defi_analytics';
  static const String _userKey = 'user';
  static const String _settingsKey = 'settings';
  static const String _portfolioKey = 'portfolio';
  
  late Box _box;
  
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_hiveBoxName);
  }
  
  Future<void> saveUser(User user) async {
    await _box.put(_userKey, user.toJson());
  }
  
  User? getUser() {
    final data = _box.get(_userKey);
    return data != null ? User.fromJson(data) : null;
  }
  
  Future<void> saveSettings(AppSettings settings) async {
    await _box.put(_settingsKey, settings.toJson());
  }
  
  AppSettings getSettings() {
    final data = _box.get(_settingsKey);
    return data != null ? AppSettings.fromJson(data) : AppSettings.defaults();
  }
  
  Future<void> savePortfolio(List<PortfolioPosition> positions) async {
    final data = positions.map((p) => p.toJson()).toList();
    await _box.put(_portfolioKey, data);
  }
  
  List<PortfolioPosition> getPortfolio() {
    final data = _box.get(_portfolioKey, defaultValue: <Map<String, dynamic>>[]);
    return data.map((json) => PortfolioPosition.fromJson(json)).toList();
  }
}
```

## 9. Навигация

### 9.1 Router Configuration
```dart
class AppRouter {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String biometricAuth = '/biometric-auth';
  
  static const String dashboard = '/dashboard';
  static const String marketOverview = '/market-overview';
  static const String topProtocols = '/top-protocols';
  
  static const String analytics = '/analytics';
  static const String protocolDetail = '/protocol-detail';
  static const String comparison = '/comparison';
  static const String trends = '/trends';
  
  static const String portfolio = '/portfolio';
  static const String addPosition = '/add-position';
  static const String transactionHistory = '/transaction-history';
  static const String performance = '/performance';
  
  static const String networks = '/networks';
  static const String networkDetail = '/network-detail';
  static const String nodeStatus = '/node-status';
  
  static const String predictions = '/predictions';
  static const String riskAssessment = '/risk-assessment';
  static const String modelStatus = '/model-status';
  
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String security = '/security';
  static const String notifications = '/notifications';
  static const String appearance = '/appearance';
  static const String about = '/about';
  
  static final GoRouter router = GoRouter(
    initialLocation: login,
    routes: [
      // Auth routes
      GoRoute(path: login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: register, builder: (context, state) => const RegisterScreen()),
      GoRoute(path: forgotPassword, builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: biometricAuth, builder: (context, state) => const BiometricAuthScreen()),
      
      // Main app routes
      ShellRoute(
        builder: (context, state, child) => MainAppShell(child: child),
        routes: [
          GoRoute(path: dashboard, builder: (context, state) => const DashboardScreen()),
          GoRoute(path: analytics, builder: (context, state) => const AnalyticsScreen()),
          GoRoute(path: portfolio, builder: (context, state) => const PortfolioScreen()),
          GoRoute(path: networks, builder: (context, state) => const NetworksScreen()),
          GoRoute(path: predictions, builder: (context, state) => const PredictionsScreen()),
          GoRoute(path: settings, builder: (context, state) => const SettingsScreen()),
        ],
      ),
    ],
  );
}
```

## 10. Производительность и оптимизация

### 10.1 Оптимизация изображений
- **Кэширование** - использование cached_network_image
- **Сжатие** - оптимизация размера изображений
- **Lazy Loading** - загрузка по требованию

### 10.2 Оптимизация списков
- **ListView.builder** - для больших списков
- **Pagination** - постраничная загрузка
- **Virtual Scrolling** - виртуальная прокрутка

### 10.3 Кэширование данных
- **Hive** - для локального кэширования
- **SharedPreferences** - для настроек
- **SecureStorage** - для чувствительных данных

### 10.4 Мониторинг производительности
- **Flutter Inspector** - для отладки UI
- **Performance Overlay** - для мониторинга FPS
- **Memory Profiler** - для анализа памяти

## 11. Безопасность

### 11.1 Аутентификация
- **JWT токены** - безопасное хранение
- **Biometric Auth** - биометрическая аутентификация
- **Secure Storage** - шифрованное хранение
- **Certificate Pinning** - привязка сертификатов

### 11.2 Защита данных
- **Шифрование** - для чувствительных данных
- **Network Security** - HTTPS для всех запросов
- **Input Validation** - валидация входных данных
- **Error Handling** - безопасная обработка ошибок

## 12. Тестирование

### 12.1 Unit Tests
```dart
void main() {
  group('AnalyticsService Tests', () {
    late AnalyticsService analyticsService;
    late MockDio mockDio;
    
    setUp(() {
      mockDio = MockDio();
      analyticsService = AnalyticsService(mockDio);
    });
    
    test('getMarketOverview returns MarketOverview', () async {
      // Arrange
      when(mockDio.get('/api/analytics/overview'))
          .thenAnswer((_) async => Response(
                data: {'total_tvl': 1000000, 'protocol_count': 50},
                statusCode: 200,
              ));
      
      // Act
      final result = await analyticsService.getMarketOverview();
      
      // Assert
      expect(result.totalTvl, 1000000);
      expect(result.protocolCount, 50);
    });
  });
}
```

### 12.2 Widget Tests
```dart
void main() {
  group('DashboardScreen Tests', () {
    testWidgets('displays market overview card', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => DashboardBloc(),
            child: const DashboardScreen(),
          ),
        ),
      );
      
      // Assert
      expect(find.byType(MarketOverviewCard), findsOneWidget);
    });
  });
}
```

### 12.3 Integration Tests
```dart
void main() {
  group('App Integration Tests', () {
    testWidgets('complete user flow', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const MyApp());
      
      // Login
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      
      // Navigate to dashboard
      expect(find.byType(DashboardScreen), findsOneWidget);
      
      // Navigate to analytics
      await tester.tap(find.byIcon(Icons.analytics));
      await tester.pumpAndSettle();
      expect(find.byType(AnalyticsScreen), findsOneWidget);
    });
  });
}
```

## 13. Развертывание

### 13.1 Android
```yaml
# android/app/build.gradle
android {
  compileSdkVersion 34
  defaultConfig {
    applicationId "com.defimon.analytics"
    minSdkVersion 21
    targetSdkVersion 34
    versionCode 1
    versionName "1.0.0"
  }
  
  signingConfigs {
    release {
      keyAlias keystoreProperties['keyAlias']
      keyPassword keystoreProperties['keyPassword']
      storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
      storePassword keystoreProperties['storePassword']
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

### 13.2 iOS
```xml
<!-- ios/Runner/Info.plist -->
<key>CFBundleDisplayName</key>
<string>DeFi Analytics</string>
<key>CFBundleIdentifier</key>
<string>com.defimon.analytics</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>CFBundleVersion</key>
<string>1</string>
<key>NSFaceIDUsageDescription</key>
<string>Use Face ID to securely access your DeFi Analytics account</string>
```

### 13.3 Firebase Configuration
```yaml
# firebase_options.dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
  
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'your-api-key',
    appId: 'your-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'your-project-id',
  );
  
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'your-api-key',
    appId: 'your-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'your-project-id',
  );
}
```

## 14. Временные рамки

### 14.1 Этапы разработки

**Этап 1 (4 недели) - MVP**
- Базовая архитектура Flutter
- Основные экраны (Dashboard, Analytics)
- API интеграция
- Базовая навигация

**Этап 2 (3 недели) - Core Features**
- Портфель и уведомления
- AI/ML интеграция
- Офлайн режим
- Безопасность

**Этап 3 (2 недели) - Polish**
- UI/UX улучшения
- Производительность
- Тестирование
- Документация

**Этап 4 (1 неделя) - Deployment**
- App Store подготовка
- Beta тестирование
- Развертывание
- Мониторинг

### 14.2 Команда
- **1 Flutter Developer** - основная разработка
- **1 UI/UX Designer** - дизайн и прототипирование
- **1 Backend Developer** - API интеграция
- **1 QA Engineer** - тестирование
- **1 DevOps Engineer** - развертывание и мониторинг

## 15. Бюджет и ресурсы

### 15.1 Инфраструктура
- **Firebase** - $25/месяц
- **App Store Developer Account** - $99/год
- **Google Play Developer Account** - $25/одноразово
- **Sentry** - $26/месяц

### 15.2 Инструменты разработки
- **Figma** - дизайн и прототипирование
- **GitHub Pro** - репозиторий и CI/CD
- **VS Code** - разработка
- **Android Studio** - Android разработка
- **Xcode** - iOS разработка

## 16. Риски и митигация

### 16.1 Технические риски
- **API изменения** - версионирование API
- **Производительность** - оптимизация и мониторинг
- **Совместимость** - тестирование на разных устройствах
- **Безопасность** - регулярные аудиты безопасности

### 16.2 Бизнес риски
- **Конкуренция** - уникальные функции и UX
- **Регулятивные изменения** - адаптация к новым требованиям
- **Пользовательская база** - маркетинг и поддержка
- **Техническая поддержка** - документация и обучение

---

**DeFi Analytics Mobile App (Flutter)** - Мощное мобильное приложение для аналитики и мониторинга DeFi экосистемы с поддержкой мультиблокчейн архитектуры и AI/ML возможностями.
