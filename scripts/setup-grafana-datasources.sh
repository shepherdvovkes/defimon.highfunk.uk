#!/bin/bash
set -e

# Скрипт для настройки источников данных в Grafana
# Использование: ./scripts/setup-grafana-datasources.sh

log() { echo -e "\033[0;32m[INFO]\033[0m $*"; }
warn() { echo -e "\033[0;33m[WARN]\033[0m $*"; }
err() { echo -e "\033[0;31m[ERROR]\033[0m $*" 1>&2; }

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"

# Ждем, пока Grafana запустится
log "Waiting for Grafana to start..."
until curl -s "$GRAFANA_URL/api/health" > /dev/null 2>&1; do
    sleep 2
done
log "Grafana is ready"

# Функция для добавления источника данных
add_datasource() {
    local name=$1
    local type=$2
    local url=$3
    local json_data=$4
    
    log "Adding datasource: $name"
    
    cat > /tmp/datasource.json << EOF
{
    "name": "$name",
    "type": "$type",
    "url": "$url",
    "access": "proxy",
    "isDefault": false,
    "editable": true,
    "jsonData": $json_data
}
EOF

    response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASS" \
        -d @/tmp/datasource.json \
        "$GRAFANA_URL/api/datasources")
    
    http_code="${response: -3}"
    response_body="${response%???}"
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "409" ]; then
        log "Datasource $name added successfully (HTTP $http_code)"
    else
        err "Failed to add datasource $name (HTTP $http_code): $response_body"
    fi
    
    rm -f /tmp/datasource.json
}

# Добавляем Prometheus
add_datasource "Prometheus" "prometheus" "http://prometheus-monitor:9090" '{
    "timeInterval": "15s",
    "queryTimeout": "60s",
    "httpMethod": "POST"
}'

# Добавляем PostgreSQL
add_datasource "PostgreSQL" "postgres" "defimon-postgres:5432" '{
    "sslmode": "disable",
    "maxOpenConns": 100,
    "maxIdleConns": 100,
    "maxIdleConnsAuto": true,
    "connMaxLifetime": 14400,
    "postgresVersion": 1500,
    "timescaledb": false,
    "database": "defi_analytics",
    "user": "postgres"
}'

# Добавляем ClickHouse (если плагин установлен)
add_datasource "ClickHouse" "grafana-clickhouse-datasource" "http://clickhouse:8123" '{
    "defaultDatabase": "analytics",
    "port": 8123,
    "server": "clickhouse",
    "username": "default",
    "secure": false,
    "tlsSkipVerify": false,
    "timeout": 60,
    "queryTimeout": 60,
    "dialTimeout": 30,
    "maxExecutionTime": 60,
    "maxIdleConns": 100,
    "maxOpenConns": 100,
    "connMaxLifetime": 14400
}'

log "All datasources configured successfully!"
log "Grafana is available at: $GRAFANA_URL"
log "Username: $GRAFANA_USER"
log "Password: $GRAFANA_PASS"
