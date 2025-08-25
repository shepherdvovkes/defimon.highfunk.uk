#!/usr/bin/env python3
"""
Database module for storing infrastructure monitoring data
"""

import sqlite3
import json
import logging
from datetime import datetime
from typing import Dict, List, Any, Optional
from pathlib import Path

logger = logging.getLogger(__name__)

class InfrastructureDatabase:
    def __init__(self, db_path: str = "infrastructure_data.db"):
        """Initialize database connection"""
        self.db_path = db_path
        self.init_database()
    
    def init_database(self):
        """Initialize database tables"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                # Clusters table
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS clusters (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT NOT NULL,
                        location TEXT NOT NULL,
                        status TEXT NOT NULL,
                        version TEXT,
                        node_count INTEGER,
                        network TEXT,
                        created_at TEXT,
                        last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        UNIQUE(name, location)
                    )
                """)
                
                # Compute instances table
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS compute_instances (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT NOT NULL,
                        zone TEXT NOT NULL,
                        status TEXT NOT NULL,
                        machine_type TEXT,
                        cpu_platform TEXT,
                        internal_ip TEXT,
                        external_ip TEXT,
                        last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        UNIQUE(name, zone)
                    )
                """)
                
                # Node pools table
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS node_pools (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        cluster_name TEXT NOT NULL,
                        cluster_location TEXT NOT NULL,
                        pool_name TEXT NOT NULL,
                        status TEXT NOT NULL,
                        version TEXT,
                        node_count INTEGER,
                        machine_type TEXT,
                        disk_size_gb INTEGER,
                        autoscaling_enabled BOOLEAN,
                        min_node_count INTEGER,
                        max_node_count INTEGER,
                        last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        UNIQUE(cluster_name, cluster_location, pool_name)
                    )
                """)
                
                # Resource usage table
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS resource_usage (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        cluster_name TEXT,
                        cluster_location TEXT,
                        cpu_usage_percent REAL,
                        memory_usage_percent REAL,
                        disk_usage_percent REAL,
                        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                
                # Monitoring events table
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS monitoring_events (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        event_type TEXT NOT NULL,
                        resource_type TEXT NOT NULL,
                        resource_name TEXT NOT NULL,
                        old_status TEXT,
                        new_status TEXT,
                        message TEXT,
                        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                
                # Infrastructure snapshots table
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS infrastructure_snapshots (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        snapshot_data TEXT NOT NULL,
                        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                
                conn.commit()
                logger.info("Database initialized successfully")
                
        except Exception as e:
            logger.error(f"Failed to initialize database: {e}")
            raise
    
    def store_cluster_data(self, cluster_data: Dict[str, Any]):
        """Store or update cluster data"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    INSERT OR REPLACE INTO clusters 
                    (name, location, status, version, node_count, network, created_at, last_updated)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    cluster_data.get('name'),
                    cluster_data.get('location'),
                    cluster_data.get('status'),
                    cluster_data.get('version'),
                    cluster_data.get('node_count'),
                    cluster_data.get('network'),
                    cluster_data.get('created_at'),
                    datetime.now()
                ))
                
                conn.commit()
                logger.info(f"Stored cluster data for {cluster_data.get('name')}")
                
        except Exception as e:
            logger.error(f"Failed to store cluster data: {e}")
    
    def store_compute_instance_data(self, instance_data: Dict[str, Any]):
        """Store or update compute instance data"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    INSERT OR REPLACE INTO compute_instances 
                    (name, zone, status, machine_type, cpu_platform, internal_ip, external_ip, last_updated)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    instance_data.get('name'),
                    instance_data.get('zone'),
                    instance_data.get('status'),
                    instance_data.get('machine_type'),
                    instance_data.get('cpu_platform'),
                    instance_data.get('internal_ip'),
                    instance_data.get('external_ip'),
                    datetime.now()
                ))
                
                conn.commit()
                logger.info(f"Stored compute instance data for {instance_data.get('name')}")
                
        except Exception as e:
            logger.error(f"Failed to store compute instance data: {e}")
    
    def store_node_pool_data(self, cluster_name: str, cluster_location: str, pool_data: Dict[str, Any]):
        """Store or update node pool data"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    INSERT OR REPLACE INTO node_pools 
                    (cluster_name, cluster_location, pool_name, status, version, node_count, 
                     machine_type, disk_size_gb, autoscaling_enabled, min_node_count, max_node_count, last_updated)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    cluster_name,
                    cluster_location,
                    pool_data.get('name'),
                    pool_data.get('status'),
                    pool_data.get('version'),
                    pool_data.get('node_count'),
                    pool_data.get('machine_type'),
                    pool_data.get('disk_size_gb'),
                    pool_data.get('autoscaling_enabled'),
                    pool_data.get('min_node_count'),
                    pool_data.get('max_node_count'),
                    datetime.now()
                ))
                
                conn.commit()
                logger.info(f"Stored node pool data for {pool_data.get('name')}")
                
        except Exception as e:
            logger.error(f"Failed to store node pool data: {e}")
    
    def store_resource_usage(self, cluster_name: str, cluster_location: str, usage_data: Dict[str, Any]):
        """Store resource usage data"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    INSERT INTO resource_usage 
                    (cluster_name, cluster_location, cpu_usage_percent, memory_usage_percent, disk_usage_percent)
                    VALUES (?, ?, ?, ?, ?)
                """, (
                    cluster_name,
                    cluster_location,
                    usage_data.get('cpu_usage_percent'),
                    usage_data.get('memory_usage_percent'),
                    usage_data.get('disk_usage_percent')
                ))
                
                conn.commit()
                logger.info(f"Stored resource usage for cluster {cluster_name}")
                
        except Exception as e:
            logger.error(f"Failed to store resource usage: {e}")
    
    def store_monitoring_event(self, event_type: str, resource_type: str, resource_name: str, 
                              old_status: str = None, new_status: str = None, message: str = None):
        """Store monitoring event"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    INSERT INTO monitoring_events 
                    (event_type, resource_type, resource_name, old_status, new_status, message)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (event_type, resource_type, resource_name, old_status, new_status, message))
                
                conn.commit()
                logger.info(f"Stored monitoring event: {event_type} for {resource_name}")
                
        except Exception as e:
            logger.error(f"Failed to store monitoring event: {e}")
    
    def store_infrastructure_snapshot(self, snapshot_data: Dict[str, Any]):
        """Store infrastructure snapshot"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    INSERT INTO infrastructure_snapshots (snapshot_data)
                    VALUES (?)
                """, (json.dumps(snapshot_data),))
                
                conn.commit()
                logger.info("Stored infrastructure snapshot")
                
        except Exception as e:
            logger.error(f"Failed to store infrastructure snapshot: {e}")
    
    def get_clusters(self) -> List[Dict[str, Any]]:
        """Get all clusters from database"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    SELECT name, location, status, version, node_count, network, created_at, last_updated
                    FROM clusters
                    ORDER BY last_updated DESC
                """)
                
                rows = cursor.fetchall()
                clusters = []
                
                for row in rows:
                    clusters.append({
                        'name': row[0],
                        'location': row[1],
                        'status': row[2],
                        'version': row[3],
                        'node_count': row[4],
                        'network': row[5],
                        'created_at': row[6],
                        'last_updated': row[7]
                    })
                
                return clusters
                
        except Exception as e:
            logger.error(f"Failed to get clusters: {e}")
            return []
    
    def get_compute_instances(self) -> List[Dict[str, Any]]:
        """Get all compute instances from database"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    SELECT name, zone, status, machine_type, cpu_platform, internal_ip, external_ip, last_updated
                    FROM compute_instances
                    ORDER BY last_updated DESC
                """)
                
                rows = cursor.fetchall()
                instances = []
                
                for row in rows:
                    instances.append({
                        'name': row[0],
                        'zone': row[1],
                        'status': row[2],
                        'machine_type': row[3],
                        'cpu_platform': row[4],
                        'internal_ip': row[5],
                        'external_ip': row[6],
                        'last_updated': row[7]
                    })
                
                return instances
                
        except Exception as e:
            logger.error(f"Failed to get compute instances: {e}")
            return []
    
    def get_node_pools(self, cluster_name: str, cluster_location: str) -> List[Dict[str, Any]]:
        """Get node pools for a specific cluster"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    SELECT pool_name, status, version, node_count, machine_type, disk_size_gb,
                           autoscaling_enabled, min_node_count, max_node_count, last_updated
                    FROM node_pools
                    WHERE cluster_name = ? AND cluster_location = ?
                    ORDER BY last_updated DESC
                """, (cluster_name, cluster_location))
                
                rows = cursor.fetchall()
                pools = []
                
                for row in rows:
                    pools.append({
                        'name': row[0],
                        'status': row[1],
                        'version': row[2],
                        'node_count': row[3],
                        'machine_type': row[4],
                        'disk_size_gb': row[5],
                        'autoscaling_enabled': bool(row[6]),
                        'min_node_count': row[7],
                        'max_node_count': row[8],
                        'last_updated': row[9]
                    })
                
                return pools
                
        except Exception as e:
            logger.error(f"Failed to get node pools: {e}")
            return []
    
    def get_latest_resource_usage(self, cluster_name: str, cluster_location: str) -> Optional[Dict[str, Any]]:
        """Get latest resource usage for a cluster"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    SELECT cpu_usage_percent, memory_usage_percent, disk_usage_percent, timestamp
                    FROM resource_usage
                    WHERE cluster_name = ? AND cluster_location = ?
                    ORDER BY timestamp DESC
                    LIMIT 1
                """, (cluster_name, cluster_location))
                
                row = cursor.fetchone()
                
                if row:
                    return {
                        'cpu_usage_percent': row[0],
                        'memory_usage_percent': row[1],
                        'disk_usage_percent': row[2],
                        'timestamp': row[3]
                    }
                
                return None
                
        except Exception as e:
            logger.error(f"Failed to get resource usage: {e}")
            return None
    
    def cleanup_old_data(self, days: int = 30):
        """Clean up old data"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                # Clean up old resource usage data
                cursor.execute("""
                    DELETE FROM resource_usage 
                    WHERE timestamp < datetime('now', '-{} days')
                """.format(days))
                
                # Clean up old monitoring events
                cursor.execute("""
                    DELETE FROM monitoring_events 
                    WHERE timestamp < datetime('now', '-{} days')
                """.format(days))
                
                # Clean up old snapshots
                cursor.execute("""
                    DELETE FROM infrastructure_snapshots 
                    WHERE timestamp < datetime('now', '-{} days')
                """.format(days))
                
                conn.commit()
                logger.info(f"Cleaned up data older than {days} days")
                
        except Exception as e:
            logger.error(f"Failed to cleanup old data: {e}")
    
    def get_database_stats(self) -> Dict[str, Any]:
        """Get database statistics"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                stats = {}
                
                # Count records in each table
                tables = ['clusters', 'compute_instances', 'node_pools', 'resource_usage', 'monitoring_events', 'infrastructure_snapshots']
                
                for table in tables:
                    cursor.execute(f"SELECT COUNT(*) FROM {table}")
                    stats[f'{table}_count'] = cursor.fetchone()[0]
                
                # Get database size
                cursor.execute("SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()")
                stats['database_size_bytes'] = cursor.fetchone()[0]
                
                return stats
                
        except Exception as e:
            logger.error(f"Failed to get database stats: {e}")
            return {}
