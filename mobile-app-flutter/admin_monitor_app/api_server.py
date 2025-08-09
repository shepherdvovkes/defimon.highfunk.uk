#!/usr/bin/env python3
"""
API Server for Admin Monitor App
Предоставляет данные мониторинга для мобильного приложения
"""

import json
import time
import psutil
import subprocess
import requests
import hashlib
import sqlite3
import jwt
from datetime import datetime, timedelta
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Конфигурация
GETH_RPC_URL = "http://localhost:8545"
LIGHTHOUSE_URL = "http://localhost:5052"
PROMETHEUS_URL = "http://localhost:9090"
JWT_SECRET = "your-secret-key-change-in-production"

# Инициализация базы данных
def init_database():
    conn = sqlite3.connect('admin_monitor.db')
    cursor = conn.cursor()
    
    # Создаем таблицу пользователей
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            email TEXT,
            role TEXT DEFAULT 'admin',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_login TIMESTAMP
        )
    ''')
    
    # Проверяем, есть ли уже админ
    cursor.execute('SELECT * FROM users WHERE username = ?', ('admin',))
    if not cursor.fetchone():
        # Создаем админа с паролем admin123123
        password_hash = hashlib.sha256('admin123123'.encode()).hexdigest()
        cursor.execute('''
            INSERT INTO users (username, password_hash, email, role)
            VALUES (?, ?, ?, ?)
        ''', ('admin', password_hash, 'admin@defimon.com', 'admin'))
    
    conn.commit()
    conn.close()

# Инициализируем базу данных при запуске
init_database()

def get_system_metrics():
    """Получение системных метрик"""
    try:
        # CPU
        cpu_percent = psutil.cpu_percent(interval=1)
        
        # Memory
        memory = psutil.virtual_memory()
        memory_percent = memory.percent
        
        # Disk
        disk = psutil.disk_usage('/')
        disk_percent = (disk.used / disk.total) * 100
        
        # Network
        network = psutil.net_io_counters()
        network_in = network.bytes_recv
        network_out = network.bytes_sent
        
        # Temperature (если доступно)
        try:
            temp = psutil.sensors_temperatures()
            temperature = temp.get('coretemp', [{}])[0].current if temp.get('coretemp') else 0
        except:
            temperature = 0
        
        # Uptime
        uptime = int(time.time() - psutil.boot_time())
        
        # Disk info
        disks = []
        for partition in psutil.disk_partitions():
            try:
                usage = psutil.disk_usage(partition.mountpoint)
                disks.append({
                    "device": partition.device,
                    "mountPoint": partition.mountpoint,
                    "totalSpace": usage.total,
                    "usedSpace": usage.used,
                    "availableSpace": usage.free,
                    "usagePercentage": (usage.used / usage.total) * 100
                })
            except:
                continue
        
        # Network interfaces
        network_interfaces = []
        for interface, addresses in psutil.net_if_addrs().items():
            try:
                stats = psutil.net_if_stats()[interface]
                network_interfaces.append({
                    "name": interface,
                    "ipAddress": addresses[0].address if addresses else "N/A",
                    "bytesIn": 0,  # Требует дополнительного мониторинга
                    "bytesOut": 0,  # Требует дополнительного мониторинга
                    "isUp": stats.isup
                })
            except:
                continue
        
        return {
            "cpuUsage": cpu_percent,
            "memoryUsage": memory_percent,
            "diskUsage": disk_percent,
            "networkIn": network_in,
            "networkOut": network_out,
            "temperature": temperature,
            "uptime": uptime,
            "disks": disks,
            "networkInterfaces": network_interfaces,
            "lastUpdate": datetime.now().isoformat()
        }
    except Exception as e:
        print(f"Error getting system metrics: {e}")
        return None

def get_geth_status():
    """Получение статуса Geth ноды"""
    try:
        # Проверяем, запущен ли geth
        result = subprocess.run(['pgrep', 'geth'], capture_output=True, text=True)
        if result.returncode != 0:
            return None
        
        # Получаем метрики через RPC
        headers = {'Content-Type': 'application/json'}
        data = {
            "jsonrpc": "2.0",
            "method": "eth_blockNumber",
            "params": [],
            "id": 1
        }
        
        response = requests.post(GETH_RPC_URL, headers=headers, json=data, timeout=5)
        if response.status_code == 200:
            result = response.json()
            current_block = int(result.get('result', '0x0'), 16)
            
            # Получаем информацию о пирах
            data = {
                "jsonrpc": "2.0",
                "method": "net_peerCount",
                "params": [],
                "id": 1
            }
            
            response = requests.post(GETH_RPC_URL, headers=headers, json=data, timeout=5)
            peers = 0
            if response.status_code == 200:
                result = response.json()
                peers = int(result.get('result', '0x0'), 16)
            
            # Получаем системные метрики для geth процесса
            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
                if proc.info['name'] == 'geth':
                    cpu_usage = proc.info['cpu_percent']
                    memory_usage = proc.info['memory_percent']
                    break
            else:
                cpu_usage = 0
                memory_usage = 0
            
            return {
                "nodeId": "ethereum-mainnet",
                "nodeType": "ethereum",
                "status": "running",
                "isOnline": True,
                "currentBlock": current_block,
                "latestBlock": current_block,  # В реальности нужно получать из сети
                "syncProgress": 100.0,  # Упрощенно
                "peers": peers,
                "cpuUsage": cpu_usage,
                "memoryUsage": memory_usage,
                "diskUsage": psutil.disk_usage('/').percent,
                "lastUpdate": datetime.now().isoformat()
            }
    except Exception as e:
        print(f"Error getting Geth status: {e}")
        return None

def get_lighthouse_status():
    """Получение статуса Lighthouse ноды"""
    try:
        # Проверяем, запущен ли lighthouse
        result = subprocess.run(['pgrep', 'lighthouse'], capture_output=True, text=True)
        if result.returncode != 0:
            return None
        
        # Получаем метрики через API
        response = requests.get(f"{LIGHTHOUSE_URL}/eth/v1/node/syncing", timeout=5)
        if response.status_code == 200:
            data = response.json()
            is_syncing = data.get('data', {}).get('is_syncing', False)
            
            # Получаем системные метрики для lighthouse процесса
            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
                if proc.info['name'] == 'lighthouse':
                    cpu_usage = proc.info['cpu_percent']
                    memory_usage = proc.info['memory_percent']
                    break
            else:
                cpu_usage = 0
                memory_usage = 0
            
            return {
                "nodeId": "lighthouse-beacon",
                "nodeType": "lighthouse",
                "status": "syncing" if is_syncing else "running",
                "isOnline": True,
                "currentBlock": 0,  # Для beacon chain это slot
                "latestBlock": 0,
                "syncProgress": 50.0 if is_syncing else 100.0,  # Упрощенно
                "peers": 0,  # Требует дополнительного API вызова
                "cpuUsage": cpu_usage,
                "memoryUsage": memory_usage,
                "diskUsage": psutil.disk_usage('/').percent,
                "lastUpdate": datetime.now().isoformat()
            }
    except Exception as e:
        print(f"Error getting Lighthouse status: {e}")
        return None

def generate_mock_history(metric, hours=24):
    """Генерация моковых исторических данных"""
    data = []
    now = datetime.now()
    
    for i in range(hours):
        timestamp = now - timedelta(hours=i)
        value = 50 + (i % 20)  # Простая синусоида
        data.append({
            "timestamp": timestamp.isoformat(),
            metric: value
        })
    
    return list(reversed(data))

def verify_token(token):
    """Проверка JWT токена"""
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None

def require_auth(f):
    """Декоратор для защиты endpoints"""
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'No token provided'}), 401
        
        token = auth_header.split(' ')[1]
        payload = verify_token(token)
        if not payload:
            return jsonify({'error': 'Invalid token'}), 401
        
        return f(*args, **kwargs)
    return decorated_function

@app.route('/api/auth/login', methods=['POST'])
def login():
    """API endpoint для аутентификации"""
    try:
        data = request.get_json()
        username = data.get('username')
        password = data.get('password')
        
        if not username or not password:
            return jsonify({
                'success': False,
                'error': 'Username and password are required'
            }), 400
        
        # Проверяем пользователя в базе данных
        conn = sqlite3.connect('admin_monitor.db')
        cursor = conn.cursor()
        
        cursor.execute('SELECT * FROM users WHERE username = ?', (username,))
        user = cursor.fetchone()
        
        if user:
            user_id, db_username, password_hash, email, role, created_at, last_login = user
            
            # Проверяем пароль
            if hashlib.sha256(password.encode()).hexdigest() == password_hash:
                # Обновляем время последнего входа
                cursor.execute('UPDATE users SET last_login = ? WHERE id = ?', 
                             (datetime.now().isoformat(), user_id))
                conn.commit()
                
                # Создаем JWT токен
                token = jwt.encode({
                    'user_id': user_id,
                    'username': username,
                    'role': role,
                    'exp': datetime.utcnow() + timedelta(days=7)
                }, JWT_SECRET, algorithm='HS256')
                
                conn.close()
                
                return jsonify({
                    'success': True,
                    'token': token,
                    'user': {
                        'id': str(user_id),
                        'username': username,
                        'email': email,
                        'role': role,
                        'createdAt': created_at,
                        'lastLogin': datetime.now().isoformat()
                    }
                })
        
        conn.close()
        return jsonify({
            'success': False,
            'error': 'Invalid username or password'
        }), 401
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'Login error: {str(e)}'
        }), 500

@app.route('/api/auth/logout', methods=['POST'])
@require_auth
def logout():
    """API endpoint для выхода из системы"""
    return jsonify({'success': True, 'message': 'Logged out successfully'})

@app.route('/api/auth/verify', methods=['GET'])
@require_auth
def verify():
    """API endpoint для проверки токена"""
    return jsonify({'success': True, 'message': 'Token is valid'})

@app.route('/api/nodes/status')
@require_auth
def nodes_status():
    """API endpoint для получения статуса всех нод"""
    nodes = []
    
    # Geth
    geth_status = get_geth_status()
    if geth_status:
        nodes.append(geth_status)
    
    # Lighthouse
    lighthouse_status = get_lighthouse_status()
    if lighthouse_status:
        nodes.append(lighthouse_status)
    
    # Если нет реальных нод, добавляем моковые данные
    if not nodes:
        nodes = [
            {
                "nodeId": "ethereum-mainnet",
                "nodeType": "ethereum",
                "status": "running",
                "isOnline": True,
                "currentBlock": 18500000,
                "latestBlock": 18500000,
                "syncProgress": 100.0,
                "peers": 25,
                "cpuUsage": 45.2,
                "memoryUsage": 67.8,
                "diskUsage": 23.1,
                "lastUpdate": datetime.now().isoformat()
            },
            {
                "nodeId": "lighthouse-beacon",
                "nodeType": "lighthouse",
                "status": "syncing",
                "isOnline": True,
                "currentBlock": 8500000,
                "latestBlock": 8500000,
                "syncProgress": 75.5,
                "peers": 15,
                "cpuUsage": 32.1,
                "memoryUsage": 45.6,
                "diskUsage": 18.9,
                "lastUpdate": datetime.now().isoformat()
            }
        ]
    
    return jsonify(nodes)

@app.route('/api/system/metrics')
@require_auth
def system_metrics():
    """API endpoint для получения системных метрик"""
    metrics = get_system_metrics()
    if metrics:
        return jsonify(metrics)
    else:
        # Возвращаем моковые данные
        return jsonify({
            "cpuUsage": 45.2,
            "memoryUsage": 67.8,
            "diskUsage": 23.1,
            "networkIn": 1024000,
            "networkOut": 512000,
            "temperature": 65.5,
            "uptime": 86400,
            "disks": [
                {
                    "device": "/dev/sda1",
                    "mountPoint": "/",
                    "totalSpace": 1000000000000,
                    "usedSpace": 230000000000,
                    "availableSpace": 770000000000,
                    "usagePercentage": 23.0
                }
            ],
            "networkInterfaces": [
                {
                    "name": "eth0",
                    "ipAddress": "192.168.1.100",
                    "bytesIn": 1024000,
                    "bytesOut": 512000,
                    "isUp": True
                }
            ],
            "lastUpdate": datetime.now().isoformat()
        })

@app.route('/api/nodes/<node_id>')
@require_auth
def node_details(node_id):
    """API endpoint для получения детальной информации о ноде"""
    # Ищем ноду в списке
    nodes_response = nodes_status()
    nodes = nodes_response.json
    
    for node in nodes:
        if node['nodeId'] == node_id:
            return jsonify(node)
    
    return jsonify({"error": "Node not found"}), 404

@app.route('/api/nodes/<node_id>/history')
@require_auth
def node_history(node_id):
    """API endpoint для получения исторических данных"""
    metric = request.args.get('metric', 'cpu')
    hours = int(request.args.get('hours', 24))
    
    history = generate_mock_history(metric, hours)
    return jsonify(history)

@app.route('/api/alerts')
@require_auth
def alerts():
    """API endpoint для получения алертов"""
    # Простые моковые алерты
    alerts = []
    
    # Проверяем системные метрики
    metrics = get_system_metrics()
    if metrics:
        if metrics['cpuUsage'] > 80:
            alerts.append({
                "severity": "warning",
                "message": f"High CPU usage: {metrics['cpuUsage']:.1f}%",
                "timestamp": datetime.now().isoformat()
            })
        
        if metrics['memoryUsage'] > 85:
            alerts.append({
                "severity": "critical",
                "message": f"High memory usage: {metrics['memoryUsage']:.1f}%",
                "timestamp": datetime.now().isoformat()
            })
        
        if metrics['diskUsage'] > 90:
            alerts.append({
                "severity": "critical",
                "message": f"High disk usage: {metrics['diskUsage']:.1f}%",
                "timestamp": datetime.now().isoformat()
            })
    
    return jsonify(alerts)

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "timestamp": datetime.now().isoformat()})

if __name__ == '__main__':
    print("Starting DEFIMON Admin Monitor API Server...")
    print("API endpoints:")
    print("  POST /api/auth/login - Authentication")
    print("  POST /api/auth/logout - Logout")
    print("  GET  /api/auth/verify - Verify token")
    print("  GET  /api/nodes/status - Node status")
    print("  GET  /api/system/metrics - System metrics")
    print("  GET  /api/nodes/<id> - Node details")
    print("  GET  /api/nodes/<id>/history - Node history")
    print("  GET  /api/alerts - Alerts")
    print("  GET  /health - Health check")
    print("\nDefault admin credentials:")
    print("  Username: admin")
    print("  Password: admin123123")
    print("\nServer will start on http://0.0.0.0:3000")
    
    app.run(host='0.0.0.0', port=3000, debug=True)
