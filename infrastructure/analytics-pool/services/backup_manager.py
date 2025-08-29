#!/usr/bin/env python3
"""
DeFi Analytics Backup Manager
Handles external storage backups for crypto analytics data
"""

import os
import json
import logging
import shutil
import tarfile
import gzip
import bz2
import lzma
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional
import schedule
import time
import threading
import subprocess
import hashlib
from dataclasses import dataclass

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class BackupConfig:
    """Backup configuration"""
    source_path: str
    destination_path: str
    compression: str
    retention_days: int
    frequency_hours: int
    include_patterns: List[str]
    exclude_patterns: List[str]

class DeFiBackupManager:
    """Manages backups for DeFi analytics data"""
    
    def __init__(self):
        self.config = self._load_config()
        self.backup_configs = self._setup_backup_configs()
        self.monitoring_enabled = True
        
    def _load_config(self) -> Dict:
        """Load configuration from environment"""
        return {
            'backup_frequency_hours': int(os.getenv('BACKUP_FREQUENCY', '6')),
            'compression_enabled': os.getenv('COMPRESSION_ENABLED', 'true').lower() == 'true',
            'gcs_bucket': os.getenv('GCS_BUCKET', 'defimon-analytics-backups'),
            'gcs_project': os.getenv('GCS_PROJECT', 'defimon-ethereum-node'),
            'local_backup_path': os.getenv('LOCAL_BACKUP_PATH', '/backups'),
            'external_storage_enabled': os.getenv('EXTERNAL_STORAGE_ENABLED', 'true').lower() == 'true',
        }
    
    def _setup_backup_configs(self) -> Dict[str, BackupConfig]:
        """Setup backup configurations for different data types"""
        return {
            'hot_data': BackupConfig(
                source_path='/data/hot',
                destination_path='/backups/hot',
                compression='gzip',
                retention_days=7,
                frequency_hours=2,
                include_patterns=['*.json', '*.csv'],
                exclude_patterns=['*.tmp', '*.lock']
            ),
            'warm_data': BackupConfig(
                source_path='/data/warm',
                destination_path='/backups/warm',
                compression='gzip',
                retention_days=30,
                frequency_hours=6,
                include_patterns=['*.json.gz', '*.csv.gz'],
                exclude_patterns=['*.tmp', '*.lock']
            ),
            'cold_data': BackupConfig(
                source_path='/data/cold',
                destination_path='/backups/cold',
                compression='lzma',
                retention_days=90,
                frequency_hours=24,
                include_patterns=['*.json.xz', '*.csv.xz'],
                exclude_patterns=['*.tmp', '*.lock']
            ),
            'archive_data': BackupConfig(
                source_path='/data/archive',
                destination_path='/backups/archive',
                compression='lzma',
                retention_days=365,
                frequency_hours=168,  # Weekly
                include_patterns=['*.json.xz', '*.csv.xz'],
                exclude_patterns=['*.tmp', '*.lock']
            ),
            'database_backup': BackupConfig(
                source_path='/var/lib/postgresql/data',
                destination_path='/backups/database',
                compression='gzip',
                retention_days=30,
                frequency_hours=12,
                include_patterns=['*'],
                exclude_patterns=['*.tmp', '*.lock', 'pg_wal/*']
            )
        }
    
    def create_backup(self, backup_name: str) -> str:
        """Create a backup for specified data type"""
        config = self.backup_configs[backup_name]
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        # Create backup filename
        backup_filename = f"{backup_name}_backup_{timestamp}.tar"
        if config.compression == 'gzip':
            backup_filename += '.gz'
        elif config.compression == 'lzma':
            backup_filename += '.xz'
        elif config.compression == 'bz2':
            backup_filename += '.bz2'
        
        backup_path = Path(config.destination_path) / backup_filename
        
        # Ensure destination directory exists
        backup_path.parent.mkdir(parents=True, exist_ok=True)
        
        try:
            logger.info(f"Creating backup: {backup_name} -> {backup_path}")
            
            # Create tar archive
            mode = 'w'
            if config.compression == 'gzip':
                mode += ':gz'
            elif config.compression == 'lzma':
                mode += ':xz'
            elif config.compression == 'bz2':
                mode += ':bz2'
            
            with tarfile.open(backup_path, mode) as tar:
                source_path = Path(config.source_path)
                
                if not source_path.exists():
                    logger.warning(f"Source path does not exist: {source_path}")
                    return ""
                
                # Add files to archive
                for pattern in config.include_patterns:
                    for file_path in source_path.rglob(pattern):
                        if file_path.is_file():
                            # Check if file should be excluded
                            should_exclude = False
                            for exclude_pattern in config.exclude_patterns:
                                if exclude_pattern in str(file_path):
                                    should_exclude = True
                                    break
                            
                            if not should_exclude:
                                arcname = file_path.relative_to(source_path)
                                tar.add(file_path, arcname=arcname)
                                logger.debug(f"Added to backup: {file_path}")
            
            # Calculate checksum
            checksum = self._calculate_checksum(backup_path)
            
            # Create metadata file
            metadata = {
                'backup_name': backup_name,
                'timestamp': timestamp,
                'filename': backup_filename,
                'checksum': checksum,
                'size_bytes': backup_path.stat().st_size,
                'compression': config.compression,
                'source_path': config.source_path,
                'files_count': self._count_files_in_archive(backup_path)
            }
            
            metadata_path = backup_path.with_suffix('.json')
            with open(metadata_path, 'w') as f:
                json.dump(metadata, f, indent=2)
            
            logger.info(f"Backup created successfully: {backup_path} ({metadata['size_bytes']} bytes)")
            return str(backup_path)
            
        except Exception as e:
            logger.error(f"Failed to create backup {backup_name}: {e}")
            return ""
    
    def _calculate_checksum(self, file_path: Path) -> str:
        """Calculate SHA256 checksum of a file"""
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                sha256_hash.update(chunk)
        return sha256_hash.hexdigest()
    
    def _count_files_in_archive(self, archive_path: Path) -> int:
        """Count files in tar archive"""
        count = 0
        try:
            with tarfile.open(archive_path, 'r:*') as tar:
                count = len(tar.getmembers())
        except Exception as e:
            logger.error(f"Failed to count files in archive: {e}")
        return count
    
    def upload_to_gcs(self, backup_path: str) -> bool:
        """Upload backup to Google Cloud Storage"""
        if not self.config['external_storage_enabled']:
            logger.info("External storage disabled, skipping GCS upload")
            return True
        
        try:
            backup_file = Path(backup_path)
            if not backup_file.exists():
                logger.error(f"Backup file not found: {backup_path}")
                return False
            
            # Upload using gsutil
            gcs_path = f"gs://{self.config['gcs_bucket']}/{backup_file.name}"
            cmd = [
                'gsutil', 'cp', 
                str(backup_file), 
                gcs_path
            ]
            
            logger.info(f"Uploading to GCS: {gcs_path}")
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                logger.info(f"Successfully uploaded to GCS: {gcs_path}")
                
                # Upload metadata file if exists
                metadata_file = backup_file.with_suffix('.json')
                if metadata_file.exists():
                    gcs_metadata_path = f"gs://{self.config['gcs_bucket']}/{metadata_file.name}"
                    metadata_cmd = ['gsutil', 'cp', str(metadata_file), gcs_metadata_path]
                    subprocess.run(metadata_cmd, capture_output=True, text=True)
                
                return True
            else:
                logger.error(f"GCS upload failed: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Failed to upload to GCS: {e}")
            return False
    
    def cleanup_old_backups(self, backup_name: str):
        """Clean up old backups based on retention policy"""
        config = self.backup_configs[backup_name]
        backup_dir = Path(config.destination_path)
        
        if not backup_dir.exists():
            return
        
        cutoff_date = datetime.now() - timedelta(days=config.retention_days)
        deleted_count = 0
        
        for backup_file in backup_dir.glob(f"{backup_name}_backup_*.tar*"):
            try:
                # Extract timestamp from filename
                filename = backup_file.name
                timestamp_str = filename.split('_backup_')[1].split('.')[0]
                backup_date = datetime.strptime(timestamp_str, '%Y%m%d_%H%M%S')
                
                if backup_date < cutoff_date:
                    backup_file.unlink()
                    
                    # Delete metadata file if exists
                    metadata_file = backup_file.with_suffix('.json')
                    if metadata_file.exists():
                        metadata_file.unlink()
                    
                    deleted_count += 1
                    logger.debug(f"Deleted old backup: {backup_file}")
                    
            except Exception as e:
                logger.error(f"Failed to process backup file {backup_file}: {e}")
        
        logger.info(f"Cleaned up {deleted_count} old backups for {backup_name}")
    
    def restore_backup(self, backup_path: str, restore_path: str) -> bool:
        """Restore backup to specified path"""
        try:
            backup_file = Path(backup_path)
            restore_dir = Path(restore_path)
            
            if not backup_file.exists():
                logger.error(f"Backup file not found: {backup_path}")
                return False
            
            # Create restore directory
            restore_dir.mkdir(parents=True, exist_ok=True)
            
            logger.info(f"Restoring backup: {backup_file} -> {restore_dir}")
            
            # Extract archive
            with tarfile.open(backup_file, 'r:*') as tar:
                tar.extractall(restore_dir)
            
            logger.info(f"Backup restored successfully to {restore_dir}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to restore backup: {e}")
            return False
    
    def get_backup_status(self) -> Dict:
        """Get status of all backups"""
        status = {
            'timestamp': datetime.now().isoformat(),
            'backups': {},
            'total_backups': 0,
            'total_size_gb': 0,
            'last_backup': None
        }
        
        for backup_name, config in self.backup_configs.items():
            backup_dir = Path(config.destination_path)
            
            if not backup_dir.exists():
                status['backups'][backup_name] = {
                    'backup_count': 0,
                    'total_size_gb': 0,
                    'last_backup': None,
                    'next_backup': None
                }
                continue
            
            # Find backup files
            backup_files = list(backup_dir.glob(f"{backup_name}_backup_*.tar*"))
            backup_files.sort(key=lambda x: x.stat().st_mtime, reverse=True)
            
            total_size = sum(f.stat().st_size for f in backup_files)
            last_backup = backup_files[0].stat().st_mtime if backup_files else None
            
            status['backups'][backup_name] = {
                'backup_count': len(backup_files),
                'total_size_gb': round(total_size / (1024**3), 2),
                'last_backup': datetime.fromtimestamp(last_backup).isoformat() if last_backup else None,
                'next_backup': self._calculate_next_backup(config.frequency_hours)
            }
            
            status['total_backups'] += len(backup_files)
            status['total_size_gb'] += total_size / (1024**3)
            
            if last_backup and (status['last_backup'] is None or last_backup > datetime.fromisoformat(status['last_backup'].replace('Z', '+00:00')).timestamp()):
                status['last_backup'] = datetime.fromtimestamp(last_backup).isoformat()
        
        return status
    
    def _calculate_next_backup(self, frequency_hours: int) -> str:
        """Calculate next backup time"""
        next_time = datetime.now() + timedelta(hours=frequency_hours)
        return next_time.isoformat()
    
    def start_backup_scheduler(self):
        """Start scheduled backup operations"""
        logger.info("Starting DeFi backup scheduler...")
        
        # Schedule backups for each data type
        for backup_name, config in self.backup_configs.items():
            schedule.every(config.frequency_hours).hours.do(
                self._scheduled_backup, backup_name
            )
        
        # Schedule cleanup operations
        schedule.every().day.at("03:00").do(self._scheduled_cleanup)
        
        # Schedule status reporting
        schedule.every(6).hours.do(self._log_backup_status)
        
        while self.monitoring_enabled:
            schedule.run_pending()
            time.sleep(60)
    
    def _scheduled_backup(self, backup_name: str):
        """Perform scheduled backup"""
        logger.info(f"Starting scheduled backup: {backup_name}")
        
        try:
            # Create backup
            backup_path = self.create_backup(backup_name)
            
            if backup_path:
                # Upload to external storage
                self.upload_to_gcs(backup_path)
                
                # Cleanup old backups
                self.cleanup_old_backups(backup_name)
                
                logger.info(f"Scheduled backup completed: {backup_name}")
            else:
                logger.error(f"Scheduled backup failed: {backup_name}")
                
        except Exception as e:
            logger.error(f"Error during scheduled backup {backup_name}: {e}")
    
    def _scheduled_cleanup(self):
        """Perform scheduled cleanup of all backups"""
        logger.info("Starting scheduled backup cleanup...")
        
        for backup_name in self.backup_configs.keys():
            self.cleanup_old_backups(backup_name)
        
        logger.info("Scheduled backup cleanup completed")
    
    def _log_backup_status(self):
        """Log backup status report"""
        status = self.get_backup_status()
        logger.info(f"Backup Status Report: {json.dumps(status, indent=2)}")

def main():
    """Main function"""
    logger.info("Starting DeFi Backup Manager...")
    
    # Create backup manager
    manager = DeFiBackupManager()
    
    # Ensure backup directories exist
    for config in manager.backup_configs.values():
        Path(config.destination_path).mkdir(parents=True, exist_ok=True)
    
    # Start backup scheduler in a separate thread
    scheduler_thread = threading.Thread(target=manager.start_backup_scheduler, daemon=True)
    scheduler_thread.start()
    
    # Keep main thread alive
    try:
        while True:
            time.sleep(60)
    except KeyboardInterrupt:
        logger.info("Shutting down DeFi Backup Manager...")
        manager.monitoring_enabled = False

if __name__ == "__main__":
    main()
