#!/usr/bin/env python3
"""
Polygon Data Dashboard - Web Interface
"""

import os
import json
import asyncio
from datetime import datetime
from flask import Flask, render_template, jsonify, request
from dotenv import load_dotenv
import sys

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.quicknode_config import PolygonQuickNodeConfig
from storage.database_manager import PolygonDatabaseManager

# Load environment variables
load_dotenv()

app = Flask(__name__)

class PolygonDataAnalyzer:
    """Analyze collected Polygon data"""
    
    def __init__(self):
        self.data_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    def get_collected_files(self):
        """Get list of collected data files"""
        files = []
        for file in os.listdir(self.data_dir):
            if file.endswith('.json') and file.startswith('polygon_data_'):
                file_path = os.path.join(self.data_dir, file)
                file_size = os.path.getsize(file_path)
                file_time = datetime.fromtimestamp(os.path.getmtime(file_path))
                
                files.append({
                    'name': file,
                    'size': file_size,
                    'size_mb': round(file_size / 1024 / 1024, 2),
                    'modified': file_time.strftime('%Y-%m-%d %H:%M:%S'),
                    'path': file_path
                })
        return sorted(files, key=lambda x: x['modified'], reverse=True)
    
    def analyze_data_file(self, file_path):
        """Analyze a specific data file"""
        try:
            with open(file_path, 'r') as f:
                data = json.load(f)
            
            analysis = {
                'file_info': {
                    'path': file_path,
                    'size_mb': round(os.path.getsize(file_path) / 1024 / 1024, 2)
                },
                'summary': {
                    'total_blocks': len(data.get('blocks', [])),
                    'total_transactions': len(data.get('transactions', [])),
                    'total_receipts': len(data.get('receipts', [])),
                    'errors': len(data.get('errors', [])),
                    'collection_time': data.get('collection_time', 'Unknown')
                },
                'block_range': {
                    'start': min([b['block_number'] for b in data.get('blocks', [])]) if data.get('blocks') else None,
                    'end': max([b['block_number'] for b in data.get('blocks', [])]) if data.get('blocks') else None
                },
                'sample_data': {
                    'blocks': data.get('blocks', [])[:3],  # First 3 blocks
                    'transactions': data.get('transactions', [])[:5],  # First 5 transactions
                    'receipts': data.get('receipts', [])[:3]  # First 3 receipts
                }
            }
            
            return analysis
        except Exception as e:
            return {'error': str(e)}
    
    def get_network_stats(self):
        """Get current network statistics"""
        try:
            endpoint_name = os.getenv('QUICKNODE_ENDPOINT_NAME', 'hidden-holy-seed')
            token_id = os.getenv('QUICKNODE_TOKEN_ID', '97d6d8e7659b49b126c43455edc4607949bfb52b')
            
            config = PolygonQuickNodeConfig(endpoint_name, token_id)
            
            # Get current block number
            async def get_current_block():
                try:
                    from utils.api_client import PolygonAPIClient
                    client = PolygonAPIClient(config.get_endpoint("polygon_mainnet").http_url)
                    await client.initialize()
                    block_number = await client.get_block_number()
                    await client.cleanup()
                    return block_number
                except Exception as e:
                    return None
            
            # Run async function
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            current_block = loop.run_until_complete(get_current_block())
            loop.close()
            
            return {
                'current_block': current_block,
                'endpoint': endpoint_name,
                'status': 'Connected' if current_block else 'Disconnected'
            }
        except Exception as e:
            return {'error': str(e)}

class PostgreSQLConfig:
    """PostgreSQL configuration and status"""
    
    def __init__(self):
        self.config = self.load_config()
    
    def load_config(self):
        """Load PostgreSQL configuration from environment"""
        return {
            'instance_name': os.getenv('GOOGLE_CLOUD_SQL_INSTANCE_NAME', 'defimon-postgres-instance'),
            'database_name': os.getenv('GOOGLE_CLOUD_SQL_DATABASE_NAME', 'defi_analytics'),
            'user': os.getenv('GOOGLE_CLOUD_SQL_USER', 'defimon_user'),
            'project_id': os.getenv('GOOGLE_CLOUD_PROJECT_ID', 'defimon-project'),
            'region': os.getenv('GOOGLE_CLOUD_REGION', 'us-central1'),
            'connection_string': os.getenv('DATABASE_URL', 'Not configured')
        }
    
    def test_connection(self):
        """Test database connection"""
        try:
            async def test_db():
                db_manager = PolygonDatabaseManager()
                await db_manager.initialize()
                
                # Get basic stats
                block_count = await db_manager.get_block_count()
                tx_count = await db_manager.get_transaction_count()
                latest_block = await db_manager.get_latest_block()
                
                await db_manager.cleanup()
                
                return {
                    'connected': True,
                    'block_count': block_count,
                    'transaction_count': tx_count,
                    'latest_block': latest_block
                }
            
            # Run async function
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            result = loop.run_until_complete(test_db())
            loop.close()
            
            return result
        except Exception as e:
            return {
                'connected': False,
                'error': str(e)
            }

# Initialize analyzers
analyzer = PolygonDataAnalyzer()
db_config = PostgreSQLConfig()

@app.route('/')
def dashboard():
    """Main dashboard page"""
    return render_template('dashboard.html')

@app.route('/api/data-files')
def get_data_files():
    """API endpoint to get collected data files"""
    files = analyzer.get_collected_files()
    return jsonify(files)

@app.route('/api/analyze-file')
def analyze_file():
    """API endpoint to analyze a specific file"""
    file_path = request.args.get('file')
    if not file_path:
        return jsonify({'error': 'No file specified'})
    
    analysis = analyzer.analyze_data_file(file_path)
    return jsonify(analysis)

@app.route('/api/network-stats')
def get_network_stats():
    """API endpoint to get network statistics"""
    stats = analyzer.get_network_stats()
    return jsonify(stats)

@app.route('/api/db-config')
def get_db_config():
    """API endpoint to get database configuration"""
    return jsonify(db_config.config)

@app.route('/api/db-test')
def test_db_connection():
    """API endpoint to test database connection"""
    result = db_config.test_connection()
    return jsonify(result)

@app.route('/api/setup-database')
def setup_database():
    """API endpoint to set up database schema"""
    try:
        async def setup():
            db_manager = PolygonDatabaseManager()
            await db_manager.initialize()
            await db_manager.create_polygon_database()
            await db_manager.create_tables()
            await db_manager.cleanup()
            return {'success': True, 'message': 'Database schema created successfully'}
        
        # Run async function
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        result = loop.run_until_complete(setup())
        loop.close()
        
        return jsonify(result)
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
