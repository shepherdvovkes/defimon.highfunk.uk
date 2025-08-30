#!/bin/bash

# Polkadot Cthulhu Local Management Script
CTHULHU_HOST="cthulhu.local"
CTHULHU_USER="vovkes"
CTHULHU_SSH_KEY="~/.ssh/cthulhu"
CTHULHU_PORT=9944
CTHULHU_WS_PORT=9945
CTHULHU_PROMETHEUS_PORT=9090

case "$1" in
    status)
        echo "=== Polkadot Cthulhu Local Status ==="
        ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "docker ps --format 'table {{.Names}}\t{{.Status}}'"
        ;;
    
    start)
        echo "Starting Polkadot Cthulhu services..."
        ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "cd /root && docker-compose up -d"
        ;;
    
    stop)
        echo "Stopping Polkadot Cthulhu services..."
        ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "cd /root && docker-compose down"
        ;;
    
    restart)
        echo "Restarting Polkadot Cthulhu services..."
        ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "cd /root && docker-compose restart"
        ;;
    
    logs)
        echo "=== Polkadot Cthulhu Local Logs ==="
        ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "docker logs polkadot-cthulhu-archive --tail 50"
        ;;
    
    sync)
        echo "=== Polkadot Sync Status ==="
        ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"system_syncState\",\"params\":[],\"id\":1}' http://localhost:$CTHULHU_PORT"
        ;;
    
    resources)
        echo "=== Resource Usage ==="
        ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "df -h && echo '---' && free -h && echo '---' && docker stats --no-stream"
        ;;
    
    backup)
        echo "Creating backup..."
        ssh -i "$CTHULHU_SSH_KEY" "$CTHULHU_USER@$CTHULHU_HOST" "tar -czf /tmp/polkadot-backup-\$(date +%Y%m%d-%H%M%S).tar.gz /var/lib/polkadot"
        ;;
    
    test)
        echo "=== Testing Connectivity ==="
        echo "Testing RPC endpoint: http://$CTHULHU_HOST:$CTHULHU_PORT"
        curl -s -X POST -H 'Content-Type: application/json' \
            -d '{"jsonrpc":"2.0","method":"system_health","params":[],"id":1}' \
            "http://$CTHULHU_HOST:$CTHULHU_PORT"
        
        echo -e "\nTesting Prometheus: http://$CTHULHU_HOST:$CTHULHU_PROMETHEUS_PORT"
        curl -s "http://$CTHULHU_HOST:$CTHULHU_PROMETHEUS_PORT/-/healthy"
        ;;
    
    endpoints)
        echo "=== Polkadot Cthulhu Local Endpoints ==="
        echo "RPC Endpoint: http://$CTHULHU_HOST:$CTHULHU_PORT"
        echo "WebSocket Endpoint: ws://$CTHULHU_HOST:$CTHULHU_WS_PORT"
        echo "Prometheus: http://$CTHULHU_HOST:$CTHULHU_PROMETHEUS_PORT"
        ;;
    
    *)
        echo "Usage: $0 {status|start|stop|restart|logs|sync|resources|backup|test|endpoints}"
        exit 1
        ;;
esac
