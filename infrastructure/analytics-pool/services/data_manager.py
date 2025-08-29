#!/usr/bin/env python3
"""
DeFi Analytics Data Manager - Local Storage
Handles data operations for crypto analytics using local NVME and USB drives
"""

import os
import json
import logging
import shutil
import gzip
import bz2
import lzma
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional
import schedule
import time
import threading
from dataclasses import dataclass
import hashlib

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class DataType:
    """Data type configuration"""
    name: str
    retention_days: int
    compression: str
    priority: str
    file_patterns: List[str]

class LocalDeFiDataManager:
    """Manages DeFi data operations on local storage"""
    
    def __init__(self):
        self.config = self._load_config()
        self.data_types = self._setup_data_types()
        self.monitoring_enabled = True
        
    def _load_config(self) -> Dict:
        """Load configuration from environment"""
        return {
            'hot_storage_path': os.getenv('HOT_STORAGE_PATH', '/data/hot'),
            'warm_storage_path': os.getenv('WARM_STORAGE_PATH', '/data/warm'),
            'compression_enabled': os.getenv('COMPRESSION_ENABLED', 'true').lower() == 'true',
            'auto_cleanup_enabled': os.getenv('AUTO_CLEANUP_ENABLED', 'true').lower() == 'true',
        }
    
    def _setup_data_types(self) -> Dict[str, DataType]:
        """Setup DeFi data types with retention policies"""
        return {
            'protocol_metrics': DataType(
                name='protocol_metrics',
                retention_days=30,
                compression='gzip',
                priority='high',
                file_patterns=['*.json', '*.csv']
            ),
            'transaction_data': DataType(
                name='transaction_data',
                retention_days=30,
                compression='gzip',
                priority='high',
                file_patterns=['*.json', '*.csv']
            ),
            'price_data': DataType(
                name='price_data',
                retention_days=30,
                compression='gzip',
                priority='medium',
                file_patterns=['*.json', '*.csv']
            ),
            'tvl_data': DataType(
                name='tvl_data',
                retention_days=30,
                compression='gzip',
                priority='high',
                file_patterns=['*.json', '*.csv']
            ),
            'user_analytics': DataType(
                name='user_analytics',
                retention_days=30,
                compression='gzip',
                priority='medium',
                file_patterns=['*.json', '*.csv']
            )
        }
    
    def store_data(self, data_type: str, data: Dict, filename: str = None) -> str:
        """Store DeFi data in appropriate storage tier"""
        if data_type not in self.data_types:
            raise ValueError(f"Unknown data type: {data_type}")
        
        data_config = self.data_types[data_type]
        
        # Determine storage tier based on data age and priority
        storage_tier = self._determine_storage_tier(data_type, data)
        
        # Generate filename if not provided
        if not filename:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f"{data_type}_{timestamp}.json"
        
        # Create storage path
        if storage_tier == 'hot':
            storage_path = Path(self.config['hot_storage_path']) / data_type
        else:
            storage_path = Path(self.config['warm_storage_path']) / data_type
        
        storage_path.mkdir(parents=True, exist_ok=True)
        file_path = storage_path / filename
        
        try:
            # Write data to file
            with open(file_path, 'w') as f:
                json.dump(data, f, indent=2)
            
            # Apply compression if enabled
            if self.config['compression_enabled'] and data_config.compression != 'none':
                file_path = self._compress_file(file_path, data_config.compression)
            
            logger.info(f"Stored {data_type} data: {file_path}")
            return str(file_path)
            
        except Exception as e:
            logger.error(f"Failed to store {data_type} data: {e}")
            raise
    
    def _determine_storage_tier(self, data_type: str, data: Dict) -> str:
        """Determine which storage tier to use for data"""
        data_config = self.data_types[data_type]
        
        # Check if data has timestamp
        timestamp = data.get('timestamp') or data.get('created_at') or data.get('date')
        
        if timestamp:
            try:
                if isinstance(timestamp, str):
                    data_time = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                else:
                    data_time = datetime.fromtimestamp(timestamp)
                
                # If data is older than 7 days, store in warm tier
                if datetime.now() - data_time > timedelta(days=7):
                    return 'warm'
            except Exception as e:
                logger.warning(f"Could not parse timestamp for {data_type}: {e}")
        
        # Default to hot tier for recent data
        return 'hot'
    
    def _compress_file(self, file_path: Path, compression_type: str) -> Path:
        """Compress a file using specified compression"""
        if compression_type == 'none':
            return file_path
            
        compressed_path = file_path.with_suffix(file_path.suffix + f'.{compression_type}')
        
        if compression_type == 'gzip':
            with open(file_path, 'rb') as f_in:
                with gzip.open(compressed_path, 'wb') as f_out:
                    shutil.copyfileobj(f_in, f_out)
        elif compression_type == 'lzma':
            with open(file_path, 'rb') as f_in:
                with lzma.open(compressed_path, 'wb') as f_out:
                    shutil.copyfileobj(f_in, f_out)
        elif compression_type == 'bz2':
            with open(file_path, 'rb') as f_in:
                with bz2.open(compressed_path, 'wb') as f_out:
                    shutil.copyfileobj(f_in, f_out)
        
        # Remove original file
        file_path.unlink()
        return compressed_path
    
    def retrieve_data(self, data_type: str, filters: Dict = None, limit: int = 100) -> List[Dict]:
        """Retrieve DeFi data from storage"""
        if data_type not in self.data_types:
            raise ValueError(f"Unknown data type: {data_type}")
        
        data_config = self.data_types[data_type]
        results = []
        
        # Search in both storage tiers
        for tier in ['hot', 'warm']:
            if tier == 'hot':
                storage_path = Path(self.config['hot_storage_path']) / data_type
            else:
                storage_path = Path(self.config['warm_storage_path']) / data_type
            
            if not storage_path.exists():
                continue
            
            # Find matching files
            for pattern in data_config.file_patterns:
                for file_path in storage_path.rglob(pattern):
                    if file_path.is_file():
                        try:
                            # Decompress if needed
                            if file_path.suffix.endswith('.gz'):
                                data = self._decompress_and_load(file_path, 'gzip')
                            elif file_path.suffix.endswith('.xz'):
                                data = self._decompress_and_load(file_path, 'lzma')
                            elif file_path.suffix.endswith('.bz2'):
                                data = self._decompress_and_load(file_path, 'bz2')
                            else:
                                with open(file_path, 'r') as f:
                                    data = json.load(f)
                            
                            # Apply filters if provided
                            if self._matches_filters(data, filters):
                                results.append(data)
                                
                                # Check limit
                                if len(results) >= limit:
                                    return results
                                    
                        except Exception as e:
                            logger.error(f"Failed to load data from {file_path}: {e}")
        
        return results
    
    def _decompress_and_load(self, file_path: Path, compression_type: str) -> Dict:
        """Decompress and load data from file"""
        if compression_type == 'gzip':
            with gzip.open(file_path, 'rt') as f:
                return json.load(f)
        elif compression_type == 'lzma':
            with lzma.open(file_path, 'rt') as f:
                return json.load(f)
        elif compression_type == 'bz2':
            with bz2.open(file_path, 'rt') as f:
                return json.load(f)
        else:
            with open(file_path, 'r') as f:
                return json.load(f)
    
    def _matches_filters(self, data: Dict, filters: Dict) -> bool:
        """Check if data matches provided filters"""
        if not filters:
            return True
        
        for key, value in filters.items():
            if key not in data:
                return False
            
            if isinstance(value, dict):
                if not self._matches_filters(data[key], value):
                    return False
            elif data[key] != value:
                return False
        
        return True
    
    def cleanup_expired_data(self):
        """Clean up expired data based on retention policies"""
        logger.info("Starting data cleanup...")
        
        for data_type, data_config in self.data_types.items():
            cutoff_date = datetime.now() - timedelta(days=data_config.retention_days)
            deleted_count = 0
            
            # Clean up from both storage tiers
            for tier in ['hot', 'warm']:
                if tier == 'hot':
                    storage_path = Path(self.config['hot_storage_path']) / data_type
                else:
                    storage_path = Path(self.config['warm_storage_path']) / data_type
                
                if not storage_path.exists():
                    continue
                
                for file_path in storage_path.rglob('*'):
                    if file_path.is_file():
                        try:
                            # Get file modification time
                            mtime = datetime.fromtimestamp(file_path.stat().st_mtime)
                            
                            if mtime < cutoff_date:
                                file_path.unlink()
                                deleted_count += 1
                                logger.debug(f"Deleted expired {data_type} file: {file_path}")
                                
                        except Exception as e:
                            logger.error(f"Failed to delete {file_path}: {e}")
            
            logger.info(f"Cleaned up {deleted_count} expired {data_type} files")
    
    def get_data_statistics(self) -> Dict:
        """Get statistics about stored data"""
        stats = {
            'timestamp': datetime.now().isoformat(),
            'data_types': {},
            'total_files': 0,
            'total_size_gb': 0
        }
        
        for data_type, data_config in self.data_types.items():
            type_stats = {
                'files_count': 0,
                'size_gb': 0,
                'hot_tier_files': 0,
                'warm_tier_files': 0
            }
            
            # Count files in both tiers
            for tier in ['hot', 'warm']:
                if tier == 'hot':
                    storage_path = Path(self.config['hot_storage_path']) / data_type
                else:
                    storage_path = Path(self.config['warm_storage_path']) / data_type
                
                if storage_path.exists():
                    for file_path in storage_path.rglob('*'):
                        if file_path.is_file():
                            type_stats['files_count'] += 1
                            type_stats['size_gb'] += file_path.stat().st_size / (1024**3)
                            
                            if tier == 'hot':
                                type_stats['hot_tier_files'] += 1
                            else:
                                type_stats['warm_tier_files'] += 1
            
            stats['data_types'][data_type] = type_stats
            stats['total_files'] += type_stats['files_count']
            stats['total_size_gb'] += type_stats['size_gb']
        
        return stats
    
    def start_data_monitoring(self):
        """Start continuous data monitoring and cleanup"""
        logger.info("Starting DeFi data monitoring...")
        
        # Schedule regular tasks
        schedule.every(1).hours.do(self._log_data_statistics)
        schedule.every().day.at("03:00").do(self.cleanup_expired_data)
        
        while self.monitoring_enabled:
            schedule.run_pending()
            time.sleep(60)
    
    def _log_data_statistics(self):
        """Log data statistics"""
        stats = self.get_data_statistics()
        logger.info(f"Data Statistics: {json.dumps(stats, indent=2)}")

def main():
    """Main function"""
    logger.info("Starting Local DeFi Data Manager...")
    
    # Create data manager
    manager = LocalDeFiDataManager()
    
    # Ensure storage directories exist
    for tier in ['hot', 'warm']:
        for data_type in manager.data_types.keys():
            if tier == 'hot':
                storage_path = Path(manager.config['hot_storage_path']) / data_type
            else:
                storage_path = Path(manager.config['warm_storage_path']) / data_type
            storage_path.mkdir(parents=True, exist_ok=True)
    
    # Start monitoring in a separate thread
    monitor_thread = threading.Thread(target=manager.start_data_monitoring, daemon=True)
    monitor_thread.start()
    
    # Keep main thread alive
    try:
        while True:
            time.sleep(60)
    except KeyboardInterrupt:
        logger.info("Shutting down Local DeFi Data Manager...")
        manager.monitoring_enabled = False

if __name__ == "__main__":
    main()
