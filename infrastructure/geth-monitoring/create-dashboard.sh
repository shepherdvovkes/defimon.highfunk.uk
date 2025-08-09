#!/bin/bash

# Скрипт для создания дашборда в Grafana
GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="Cal1f0rn1a@2025"
DASHBOARD_FILE="system-metrics-dashboard.json"

echo "Создание дашборда в Grafana..."

# Получаем API ключ
API_KEY=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"dashboard-api\",\"role\":\"Admin\"}" \
  -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
  "$GRAFANA_URL/api/auth/keys" | jq -r '.key')

if [ "$API_KEY" = "null" ] || [ -z "$API_KEY" ]; then
    echo "Ошибка получения API ключа. Попробуем создать дашборд напрямую..."
    
    # Создаем дашборд напрямую
    RESPONSE=$(curl -s -X POST \
      -H "Content-Type: application/json" \
      -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
      -d @$DASHBOARD_FILE \
      "$GRAFANA_URL/api/dashboards/db")
    
    if echo "$RESPONSE" | jq -e '.id' > /dev/null; then
        DASHBOARD_ID=$(echo "$RESPONSE" | jq -r '.id')
        echo "✅ Дашборд успешно создан! ID: $DASHBOARD_ID"
        echo "🌐 Доступен по адресу: $GRAFANA_URL/d/$DASHBOARD_ID"
    else
        echo "❌ Ошибка создания дашборда:"
        echo "$RESPONSE" | jq -r '.message // .error // "Неизвестная ошибка"'
    fi
else
    echo "API ключ получен. Создаем дашборд..."
    
    # Создаем дашборд с API ключом
    RESPONSE=$(curl -s -X POST \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $API_KEY" \
      -d @$DASHBOARD_FILE \
      "$GRAFANA_URL/api/dashboards/db")
    
    if echo "$RESPONSE" | jq -e '.id' > /dev/null; then
        DASHBOARD_ID=$(echo "$RESPONSE" | jq -r '.id')
        echo "✅ Дашборд успешно создан! ID: $DASHBOARD_ID"
        echo "🌐 Доступен по адресу: $GRAFANA_URL/d/$DASHBOARD_ID"
    else
        echo "❌ Ошибка создания дашборда:"
        echo "$RESPONSE" | jq -r '.message // .error // "Неизвестная ошибка"'
    fi
fi
