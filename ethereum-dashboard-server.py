#!/usr/bin/env python3
"""
Ethereum Archive Node Dashboard Server
Serves the fixed dashboard with proper API endpoints
"""

import os
import json
import time
import psutil
import requests
from datetime import datetime, timedelta
from flask import Flask, render_template_string, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Configuration
GETH_PORT = 8545
LIGHTHOUSE_PORT = 5052

# Historical data storage (in production, use a proper database)
historical_data = []

def get_geth_sync_status():
    """Get geth sync status via JSON-RPC"""
    try:
        payload = {
            "jsonrpc": "2.0",
            "method": "eth_syncing",
            "params": [],
            "id": 1
        }
        response = requests.post(
            f"http://localhost:{GETH_PORT}",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=5
        )
        if response.status_code == 200:
            result = response.json()
            if "result" in result:
                return result["result"]
        return False
    except Exception as e:
        print(f"Geth sync status error: {e}")
        return False

def check_lighthouse_running():
    """Check if Lighthouse is running on the expected port"""
    try:
        response = requests.get(f"http://localhost:{LIGHTHOUSE_PORT}/eth/v1/node/syncing", timeout=2)
        return response.status_code == 200
    except:
        return False

def get_lighthouse_status():
    """Get lighthouse status"""
    try:
        response = requests.get(f"http://localhost:{LIGHTHOUSE_PORT}/eth/v1/node/syncing", timeout=5)
        if response.status_code == 200:
            return response.json()
        return None
    except Exception as e:
        print(f"Lighthouse status error: {e}")
        return None

def get_system_stats():
    """Get system statistics"""
    try:
        # CPU usage
        cpu_percent = psutil.cpu_percent(interval=1)
        
        # Memory usage
        memory = psutil.virtual_memory()
        mem_percent = memory.percent
        
        # Disk usage
        disk_usage = []
        for partition in psutil.disk_partitions():
            try:
                usage = psutil.disk_usage(partition.mountpoint)
                disk_usage.append({
                    "filesystem": partition.device,
                    "mount": partition.mountpoint,
                    "usage": round((usage.used / usage.total) * 100, 1)
                })
            except PermissionError:
                continue
        
        # Network stats
        network = psutil.net_io_counters()
        network_info = {
            "rx_bytes": network.bytes_recv,
            "tx_bytes": network.bytes_sent,
            "rx_rate": network.bytes_recv,
            "tx_rate": network.bytes_sent,
            "lastUpdate": int(time.time() * 1000)
        }
        
        return {
            "cpuPercent": cpu_percent,
            "memPercent": mem_percent,
            "diskUsage": disk_usage,
            "networkInfo": network_info,
            "timestamp": int(time.time() * 1000)
        }
    except Exception as e:
        print(f"System stats error: {e}")
        return {"error": str(e)}

def generate_historical_data(timeframe):
    """Generate mock historical data based on timeframe"""
    data_points = {
        '1h': 12,
        '6h': 6,
        '24h': 24,
        '7d': 7,
        '30d': 30
    }
    
    points = data_points.get(timeframe, 24)
    data = []
    
    for i in range(points):
        timestamp = int((time.time() - (points - i) * 3600) * 1000)
        data.append({
            "timestamp": timestamp,
            "cpu_percent": 20 + (i % 20),
            "memory_percent": 60 + (i % 30),
            "network_rx_rate": 1000000 + (i % 500000),
            "network_tx_rate": 500000 + (i % 200000)
        })
    
    return data

@app.route('/')
def dashboard():
    """Serve the main dashboard"""
    with open('ethereum-dashboard-fixed.html', 'r', encoding='utf-8') as f:
        return f.read()

@app.route('/api/stats')
def api_stats():
    """API endpoint for current stats"""
    try:
        geth_data = get_geth_sync_status()
        lighthouse_data = get_lighthouse_status()
        system_data = get_system_stats()
        
        # Check if Lighthouse is running
        lighthouse_running = check_lighthouse_running()
        
        # Prepare Lighthouse data with proper fallback
        if lighthouse_data and lighthouse_running:
            lighthouse_response = {
                "is_syncing": lighthouse_data.get("is_syncing", False),
                "is_optimistic": lighthouse_data.get("is_optimistic", False),
                "el_offline": lighthouse_data.get("el_offline", False),
                "head_slot": str(lighthouse_data.get("head_slot", "0")),
                "sync_distance": str(lighthouse_data.get("sync_distance", "0"))
            }
        else:
            lighthouse_response = {
                "is_syncing": False,
                "is_optimistic": False,
                "el_offline": True,  # Mark as offline since we can't connect
                "head_slot": "0",
                "sync_distance": "0"
            }
        
        return jsonify({
            "geth": {
                "jsonrpc": "2.0",
                "id": 1,
                "result": geth_data
            },
            "lighthouse": {
                "data": lighthouse_response
            },
            "system": system_data
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/history/system')
def api_history():
    """API endpoint for historical data"""
    try:
        timeframe = request.args.get('timeframe', '1h')
        data = generate_historical_data(timeframe)
        return jsonify(data)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/health')
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0"
    })

if __name__ == '__main__':
    print("🚀 Starting Ethereum Archive Node Dashboard Server...")
    print("📊 Dashboard will be available at: http://localhost:3000")
    print("🔧 API endpoints:")
    print("   - GET /api/stats - Current node statistics")
    print("   - GET /api/history/system - Historical data")
    print("   - GET /api/health - Health check")
    print("")
    
    app.run(host='0.0.0.0', port=3000, debug=True)
