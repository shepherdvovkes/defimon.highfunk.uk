# Blast API Setup Guide - Updated for Alchemy Integration

## Обзор

Blast API теперь использует Alchemy в качестве провайдера. Это означает, что для работы с Blast API вам нужно использовать ваш Alchemy API ключ.

## Настройка

### 1. Получение Alchemy API ключа

1. Перейдите на [Alchemy Dashboard](https://dashboard.alchemy.com/)
2. Создайте новый проект или используйте существующий
3. Скопируйте ваш API ключ из настроек проекта

### 2. Настройка переменных окружения

Добавьте ваш Alchemy API ключ в файл `.env`:

```bash
# Blast API теперь использует Alchemy
ALCHEMY_API_KEY=your-alchemy-api-key-here
```

### 3. Конфигурация

Blast API теперь использует следующие настройки:

- **Base URL**: `https://eth-mainnet.g.alchemy.com/v2`
- **API Key**: Ваш Alchemy API ключ
- **Headers**: `Content-Type: application/json`

## Использование

### RPC методы

Blast API поддерживает все стандартные Ethereum RPC методы через Alchemy:

```python
# Пример получения номера блока
payload = {
    "jsonrpc": "2.0",
    "method": "eth_blockNumber",
    "params": [],
    "id": 1
}

url = f"https://eth-mainnet.g.alchemy.com/v2/{your_alchemy_api_key}"
response = requests.post(url, json=payload, headers={"Content-Type": "application/json"})
```

### Доступные эндпоинты

После интеграции в analytics-api доступны следующие эндпоинты:

- `GET /api/external-apis/blast/block-number` - Номер последнего блока
- `GET /api/external-apis/blast/gas-price` - Текущая цена газа
- `GET /api/external-apis/blast/balance/{address}` - Баланс адреса

## Тестирование

### Проверка подключения

```bash
# Получить номер последнего блока
curl http://localhost:8002/api/external-apis/blast/block-number

# Получить цену газа
curl http://localhost:8002/api/external-apis/blast/gas-price

# Получить сводку всех API
curl http://localhost:8002/api/external-apis/summary
```

### Примеры ответов

```json
{
  "success": true,
  "block_number": 18500000,
  "hex_block_number": "0x11a5e00",
  "provider": "Alchemy (Blast)"
}
```

## Преимущества использования Alchemy

1. **Надежность**: Alchemy предоставляет высоконадежную инфраструктуру
2. **Производительность**: Быстрые ответы и высокая пропускная способность
3. **Поддержка**: Отличная документация и поддержка
4. **Масштабируемость**: Поддержка высоких нагрузок
5. **Дополнительные возможности**: WebSocket, NFT API, и другие сервисы

## Миграция с Blast API

Если вы ранее использовали Blast API напрямую, обновите ваши запросы:

### Старый формат (Blast API)
```python
url = "https://api.blast.io"
headers = {"Authorization": f"Bearer {blast_api_key}"}
```

### Новый формат (Alchemy)
```python
url = f"https://eth-mainnet.g.alchemy.com/v2/{alchemy_api_key}"
headers = {"Content-Type": "application/json"}
```

## Поддержка

- [Alchemy Documentation](https://docs.alchemy.com/)
- [Alchemy Dashboard](https://dashboard.alchemy.com/)
- [Alchemy Discord](https://discord.gg/alchemy)

## Примечания

- Blast API теперь полностью интегрирован с Alchemy
- Все существующие функции сохранены
- Улучшена производительность и надежность
- Добавлена поддержка дополнительных Alchemy сервисов
