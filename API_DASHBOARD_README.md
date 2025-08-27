# API Dashboard - Real-time External API Monitoring

## Обзор

API Dashboard - это веб-интерфейс для мониторинга всех внешних API, используемых в проекте DeFiMon. Дашборд предоставляет реальное время статуса, производительности и данных от всех интегрированных API.

## 🚀 Возможности

### ✅ Мониторинг в реальном времени
- **Статус API**: online/offline/error/loading
- **Время отклика**: измерение производительности каждого API
- **Последняя проверка**: timestamp последнего запроса
- **Автообновление**: обновление каждые 30 секунд

### 📊 Визуализация данных
- **Сводная статистика**: количество API по статусам
- **Группировка по категориям**: Blockchain RPC, Crypto Data, DeFi Analytics, etc.
- **Детальная информация**: полные данные от каждого API
- **Форматированный вывод**: читаемое отображение данных

### 🔐 Безопасность
- **Скрытие API ключей**: показ только первых 8 символов
- **Переключение видимости**: возможность показать/скрыть полные ключи
- **Безопасные запросы**: timeout и обработка ошибок

## 📱 Интерфейс

### Главная страница (`/api-dashboard`)
- **Заголовок**: название и описание дашборда
- **Контролы**: кнопка обновления, переключатель автообновления
- **Статистика**: карточки с количеством API по статусам
- **Категории**: группировка API по типам
- **Ссылки**: переход к детальным страницам API

### Детальная страница (`/api-dashboard/[api-name]`)
- **Полная информация**: все данные об API
- **Сырые данные**: возможность просмотра JSON
- **История**: последние проверки и ошибки
- **Конфигурация**: настройки и эндпоинты

## 🔧 Интегрированные API

### Blockchain RPC
1. **QuickNode** - Ethereum RPC провайдер
   - Эндпоинт: `/api/external-apis/quicknode/block-number`
   - Данные: номер блока, цена газа, баланс адресов

2. **Blast (Alchemy)** - Blast API через Alchemy
   - Эндпоинт: `/api/external-apis/blast/block-number`
   - Данные: блокчейн данные через Alchemy

### Crypto Data
3. **CoinGecko** - Криптовалютные данные
   - Эндпоинт: `/api/external-apis/coingecko/bitcoin-price`
   - Данные: цены, рыночная капитализация, изменения

4. **CoinCap** - Альтернативные криптоданные
   - Эндпоинт: `/api/external-apis/coincap/assets`
   - Данные: активы и рыночные данные

### DeFi Analytics
5. **DeFiLlama** - TVL и протоколы
   - Эндпоинт: `/api/external-apis/defillama/protocols`
   - Данные: общий TVL, топ протоколы

6. **The Graph** - Subgraph данные
   - Эндпоинт: `/api/external-apis/thegraph/uniswap`
   - Данные: данные пулов и транзакций

### Blockchain Explorer
7. **Etherscan** - Ethereum транзакции
   - Эндпоинт: `/api/external-apis/etherscan/transactions`
   - Данные: история транзакций

8. **Arbiscan** - Arbitrum транзакции
   - Эндпоинт: `/api/external-apis/arbiscan/transactions`
   - Данные: транзакции Arbitrum

9. **Polygonscan** - Polygon транзакции
   - Эндпоинт: `/api/external-apis/polygonscan/transactions`
   - Данные: транзакции Polygon

### Development
10. **GitHub** - Репозитории и пользователи
    - Эндпоинт: `/api/external-apis/github/user`
    - Данные: информация о пользователе и репозиториях

## 🛠 Техническая архитектура

### Frontend
- **Framework**: Next.js 14 с TypeScript
- **Styling**: Tailwind CSS
- **Icons**: Heroicons
- **State Management**: React Hooks
- **HTTP Client**: Fetch API

### Backend Integration
- **Base URL**: `http://localhost:8002`
- **Timeout**: 10 секунд на запрос
- **Error Handling**: полная обработка ошибок
- **CORS**: настроен для локальной разработки

### Компоненты
- `APIDashboard` - главная страница дашборда
- `APIDetailCard` - карточка с детальной информацией
- `APIDetailPage` - страница отдельного API

## 🚀 Запуск

### 1. Запуск Backend API
```bash
cd services/analytics-api
python3 test_server.py
```

### 2. Запуск Frontend
```bash
cd mvp-website
npm run dev
```

### 3. Открытие дашборда
```
http://localhost:3000/api-dashboard
```

## 📊 Примеры данных

### QuickNode Response
```json
{
  "success": true,
  "block_number": 23230184,
  "hex_block_number": "0x16276e8"
}
```

### CoinGecko Response
```json
{
  "success": true,
  "data": {
    "bitcoin": {
      "usd": 111636,
      "usd_24h_change": 1.40,
      "usd_market_cap": 2222888986277.15
    }
  }
}
```

### DeFiLlama Response
```json
{
  "success": true,
  "data": {
    "total_tvl": 45000000000,
    "protocols": [
      {"name": "Uniswap", "tvl": 3500000000},
      {"name": "Aave", "tvl": 2800000000}
    ]
  }
}
```

## 🔧 Настройка

### Добавление нового API
1. Добавить конфигурацию в `apiConfigs` массив
2. Создать эндпоинт в `test_server.py`
3. Добавить форматирование данных в `formatData` функцию

### Изменение интервала обновления
```typescript
// В APIDashboard компоненте
const interval = setInterval(fetchAllAPIStatuses, 30000) // 30 секунд
```

### Настройка API ключей
```bash
# В .env файле
ALCHEMY_API_KEY=your-alchemy-key
QUICKNODE_API_KEY=your-quicknode-key
COINGECKO_API_KEY=your-coingecko-key
```

## 📈 Мониторинг и алерты

### Статусы API
- 🟢 **Online**: API работает нормально
- 🔴 **Offline**: API недоступен
- 🟡 **Error**: API возвращает ошибку
- 🔵 **Loading**: проверка в процессе

### Метрики
- **Response Time**: время отклика в миллисекундах
- **Success Rate**: процент успешных запросов
- **Uptime**: время работы API
- **Error Rate**: частота ошибок

## 🔮 Планы развития

### Краткосрочные
- [ ] Добавление графиков производительности
- [ ] Настройка алертов при сбоях
- [ ] Экспорт данных в CSV/JSON
- [ ] Фильтрация и поиск API

### Долгосрочные
- [ ] Интеграция с Prometheus/Grafana
- [ ] WebSocket обновления в реальном времени
- [ ] Мобильная версия
- [ ] API для управления дашбордом

## 🐛 Troubleshooting

### Проблема: API показывает статус "offline"
**Решение**: Проверьте, запущен ли backend сервер на порту 8002

### Проблема: Ошибка CORS
**Решение**: Убедитесь, что backend настроен для работы с localhost:3000

### Проблема: API ключи не отображаются
**Решение**: Проверьте переменные окружения в .env файле

### Проблема: Медленное обновление
**Решение**: Уменьшите интервал обновления или отключите автообновление

## 📞 Поддержка

Для вопросов и предложений по API Dashboard обращайтесь к команде разработки DeFiMon.

---

**API Dashboard** - ваш надежный инструмент для мониторинга всех внешних API в проекте DeFiMon! 🚀
