#!/usr/bin/env python3
"""
DeFi Analytics Storage Manager - Local Storage Only
Handles tiered storage for crypto analytics data using local NVME and USB drives
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
import psutil

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class StorageTier:
    """Storage tier configuration"""
    name: str
    path: str
    max_size_gb: int
    retention_days: int
    compression: str
    priority: int
    drive_type: str

class LocalDeFiStorageManager:
    """Manages local tiered storage for DeFi analytics data"""
    
    def __init__(self):
        self.config = self._load_config()
        self.storage_tiers = self._setup_storage_tiers()
        self.monitoring_enabled = True
        
    def _load_config(self) -> Dict:
        """Load configuration from environment and config files"""
        config = {
            'hot_storage_path': os.getenv('HOT_STORAGE_PATH', '/data/hot'),
            'warm_storage_path': os.getenv('WARM_STORAGE_PATH', '/data/warm'),
            'compression_enabled': os.getenv('COMPRESSION_ENABLED', 'true').lower() == 'true',
            'auto_cleanup_enabled': os.getenv('AUTO_CLEANUP_ENABLED', 'true').lower() == 'true',
        }
        
        # Load additional config from file if exists
        config_path = '/app/config/defi-storage-config.json'
        if os.path.exists(config_path):
            with open(config_path, 'r') as f:
                file_config = json.load(f)
                config.update(file_config)
                
        return config
    
    def _setup_storage_tiers(self) -> Dict[str, StorageTier]:
        """Setup storage tiers with local drive configurations"""
        return {
            'hot': StorageTier(
                name='hot',
                path=self.config['hot_storage_path'],
                max_size_gb=500,
                retention_days=7,
                compression='none',
                priority=1,
                drive_type='nvme'
            ),
            'warm': StorageTier(
                name='warm',
                path=self.config['warm_storage_path'],
                max_size_gb=2048,  # 2TB USB drive
                retention_days=30,
                compression='gzip',
                priority=2,
                drive_type='usb'
            )
        }
    
    def get_storage_usage(self, tier_name: str) -> Dict:
        """Get storage usage statistics for a tier"""
        tier = self.storage_tiers[tier_name]
        path = Path(tier.path)
        
        if not path.exists():
            return {'used_gb': 0, 'available_gb': tier.max_size_gb, 'usage_percent': 0}
        
        # Get disk usage
        total, used, free = shutil.disk_usage(path)
        
        # Calculate directory size
        dir_size = sum(f.stat().st_size for f in path.rglob('*') if f.is_file())
        
        return {
            'used_gb': round(dir_size / (1024**3), 2),
            'available_gb': round(free / (1024**3), 2),
            'usage_percent': round((dir_size / (1024**3)) / tier.max_size_gb * 100, 2),
            'total_files': len(list(path.rglob('*'))),
            'drive_type': tier.drive_type,
            'last_updated': datetime.now().isoformat()
        }
    
    def compress_file(self, file_path: Path, compression_type: str) -> Path:
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
    
    def decompress_file(self, file_path: Path) -> Path:
        """Decompress a file"""
        if file_path.suffix.endswith('.gz'):
            decompressed_path = file_path.with_suffix(file_path.suffix[:-3])
            with gzip.open(file_path, 'rb') as f_in:
                with open(decompressed_path, 'wb') as f_out:
                    shutil.copyfileobj(f_in, f_out)
            return decompressed_path
        elif file_path.suffix.endswith('.xz'):
            decompressed_path = file_path.with_suffix(file_path.suffix[:-3])
            with lzma.open(file_path, 'rb') as f_in:
                with open(decompressed_path, 'wb') as f_out:
                    shutil.copyfileobj(f_in, f_out)
            return decompressed_path
        elif file_path.suffix.endswith('.bz2'):
            decompressed_path = file_path.with_suffix(file_path.suffix[:-4])
            with bz2.open(file_path, 'rb') as f_in:
                with open(decompressed_path, 'wb') as f_out:
                    shutil.copyfileobj(f_in, f_out)
            return decompressed_path
        
        return file_path
    
    def migrate_data(self, source_tier: str, target_tier: str, file_pattern: str = "*"):
        """Migrate data between storage tiers"""
        source = self.storage_tiers[source_tier]
        target = self.storage_tiers[target_tier]
        
        source_path = Path(source.path)
        target_path = Path(target.path)
        
        if not source_path.exists():
            logger.warning(f"Source tier {source_tier} path does not exist: {source_path}")
            return
        
        target_path.mkdir(parents=True, exist_ok=True)
        
        # Find files matching pattern
        files = list(source_path.rglob(file_pattern))
        logger.info(f"Found {len(files)} files to migrate from {source_tier} to {target_tier}")
        
        migrated_count = 0
        for file_path in files:
            if file_path.is_file():
                try:
                    # Calculate relative path
                    relative_path = file_path.relative_to(source_path)
                    target_file = target_path / relative_path
                    
                    # Create target directory
                    target_file.parent.mkdir(parents=True, exist_ok=True)
                    
                    # Copy file
                    shutil.copy2(file_path, target_file)
                    
                    # Apply compression if needed
                    if target.compression != 'none':
                        target_file = self.compress_file(target_file, target.compression)
                    
                    # Remove source file
                    file_path.unlink()
                    
                    migrated_count += 1
                    logger.debug(f"Migrated: {file_path} -> {target_file}")
                    
                except Exception as e:
                    logger.error(f"Failed to migrate {file_path}: {e}")
        
        logger.info(f"Successfully migrated {migrated_count} files from {source_tier} to {target_tier}")
    
    def cleanup_expired_data(self, tier_name: str):
        """Remove expired data based on retention policy"""
        tier = self.storage_tiers[tier_name]
        tier_path = Path(tier.path)
        
        if not tier_path.exists():
            return
        
        cutoff_date = datetime.now() - timedelta(days=tier.retention_days)
        deleted_count = 0
        
        for file_path in tier_path.rglob('*'):
            if file_path.is_file():
                try:
                    # Get file modification time
                    mtime = datetime.fromtimestamp(file_path.stat().st_mtime)
                    
                    if mtime < cutoff_date:
                        file_path.unlink()
                        deleted_count += 1
                        logger.debug(f"Deleted expired file: {file_path}")
                        
                except Exception as e:
                    logger.error(f"Failed to delete {file_path}: {e}")
        
        logger.info(f"Cleaned up {deleted_count} expired files from {tier_name} tier")
    
    def optimize_storage(self):
        """Optimize storage by migrating data between tiers"""
        logger.info("Starting local storage optimization...")
        
        # Check hot tier usage (NVME)
        hot_usage = self.get_storage_usage('hot')
        if hot_usage['usage_percent'] > 80:
            logger.info("Hot tier (NVME) usage high, migrating to warm tier (USB)")
            self.migrate_data('hot', 'warm', '*.json')
            self.migrate_data('hot', 'warm', '*.csv')
        
        # Check warm tier usage (USB)
        warm_usage = self.get_storage_usage('warm')
        if warm_usage['usage_percent'] > 90:
            logger.warning("Warm tier (USB) usage critical! Consider manual cleanup or data export")
        
        # Cleanup expired data
        for tier_name in self.storage_tiers.keys():
            self.cleanup_expired_data(tier_name)
        
        logger.info("Local storage optimization completed")
    
    def get_storage_health_report(self) -> Dict:
        """Generate comprehensive storage health report"""
        report = {
            'timestamp': datetime.now().isoformat(),
            'tiers': {},
            'total_usage_gb': 0,
            'total_available_gb': 0,
            'alerts': []
        }
        
        for tier_name, tier in self.storage_tiers.items():
            usage = self.get_storage_usage(tier_name)
            report['tiers'][tier_name] = {
                'usage': usage,
                'config': {
                    'max_size_gb': tier.max_size_gb,
                    'retention_days': tier.retention_days,
                    'compression': tier.compression,
                    'drive_type': tier.drive_type
                }
            }
            
            report['total_usage_gb'] += usage['used_gb']
            report['total_available_gb'] += usage['available_gb']
            
            # Check for alerts
            if usage['usage_percent'] > 95:
                report['alerts'].append(f"CRITICAL: {tier_name} tier ({tier.drive_type}) usage at {usage['usage_percent']}%")
            elif usage['usage_percent'] > 80:
                report['alerts'].append(f"WARNING: {tier_name} tier ({tier.drive_type}) usage at {usage['usage_percent']}%")
        
        return report
    
    def start_monitoring(self):
        """Start continuous monitoring and optimization"""
        logger.info("Starting local DeFi storage monitoring...")
        
        # Schedule regular tasks
        schedule.every(1).hours.do(self.optimize_storage)
        schedule.every(6).hours.do(self._log_storage_report)
        schedule.every().day.at("02:00").do(self._full_cleanup)
        
        while self.monitoring_enabled:
            schedule.run_pending()
            time.sleep(60)
    
    def _log_storage_report(self):
        """Log storage health report"""
        report = self.get_storage_health_report()
        logger.info(f"Local Storage Health Report: {json.dumps(report, indent=2)}")
        
        # Send alerts if any
        if report['alerts']:
            for alert in report['alerts']:
                logger.warning(alert)
    
    def _full_cleanup(self):
        """Perform full cleanup of all tiers"""
        logger.info("Starting full local storage cleanup...")
        
        for tier_name in self.storage_tiers.keys():
            self.cleanup_expired_data(tier_name)
        
        logger.info("Full local storage cleanup completed")

def main():
    """Main function"""
    logger.info("Starting Local DeFi Storage Manager...")
    
    # Create storage manager
    manager = LocalDeFiStorageManager()
    
    # Ensure storage directories exist
    for tier in manager.storage_tiers.values():
        Path(tier.path).mkdir(parents=True, exist_ok=True)
    
    # Start monitoring in a separate thread
    monitor_thread = threading.Thread(target=manager.start_monitoring, daemon=True)
    monitor_thread.start()
    
    # Keep main thread alive
    try:
        while True:
            time.sleep(60)
    except KeyboardInterrupt:
        logger.info("Shutting down Local DeFi Storage Manager...")
        manager.monitoring_enabled = False

if __name__ == "__main__":
    main()
