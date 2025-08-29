#!/usr/bin/env python3
"""
Database initialization script for Price Oracle system
This script creates the necessary database schema and initial data
"""

import asyncio
import os
import sys
import logging
from pathlib import Path
import asyncpg
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class DatabaseInitializer:
    def __init__(self):
        self.db_config = {
            'host': os.getenv('DB_HOST', 'localhost'),
            'port': int(os.getenv('DB_PORT', '5432')),
            'user': os.getenv('DB_USER', 'postgres'),
            'password': os.getenv('DB_PASSWORD', ''),
            'database': os.getenv('DB_NAME', 'defimon')
        }
        self.conn = None
    
    async def connect(self):
        """Connect to database"""
        try:
            self.conn = await asyncpg.connect(**self.db_config)
            logger.info(f"Connected to database: {self.db_config['database']}")
        except Exception as e:
            logger.error(f"Failed to connect to database: {e}")
            raise
    
    async def close(self):
        """Close database connection"""
        if self.conn:
            await self.conn.close()
            logger.info("Database connection closed")
    
    async def create_schema(self):
        """Create database schema"""
        try:
            # Read schema file
            schema_file = Path(__file__).parent.parent / "infrastructure" / "price_oracle_schema.sql"
            
            if not schema_file.exists():
                logger.error(f"Schema file not found: {schema_file}")
                return False
            
            with open(schema_file, 'r') as f:
                schema_sql = f.read()
            
            # Execute schema creation
            await self.conn.execute(schema_sql)
            logger.info("Database schema created successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to create schema: {e}")
            return False
    
    async def verify_schema(self):
        """Verify that schema was created correctly"""
        try:
            # Check if main tables exist
            tables = [
                'oracle_sources',
                'crypto_assets', 
                'price_feeds',
                'l2_network_prices',
                'oracle_feed_history',
                'price_aggregations',
                'oracle_performance',
                'price_alerts'
            ]
            
            for table in tables:
                exists = await self.conn.fetchval(
                    "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = $1)",
                    table
                )
                if exists:
                    logger.info(f"✓ Table {table} exists")
                else:
                    logger.error(f"✗ Table {table} missing")
                    return False
            
            # Check if initial data was inserted
            oracle_count = await self.conn.fetchval("SELECT COUNT(*) FROM oracle_sources")
            asset_count = await self.conn.fetchval("SELECT COUNT(*) FROM crypto_assets")
            
            logger.info(f"✓ {oracle_count} oracle sources found")
            logger.info(f"✓ {asset_count} crypto assets found")
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to verify schema: {e}")
            return False
    
    async def create_indexes(self):
        """Create additional indexes for performance"""
        try:
            indexes = [
                # Composite indexes for common queries
                "CREATE INDEX IF NOT EXISTS idx_price_feeds_asset_oracle_timestamp ON price_feeds(asset_id, oracle_source_id, last_updated)",
                "CREATE INDEX IF NOT EXISTS idx_oracle_feed_history_asset_oracle_timestamp ON oracle_feed_history(asset_id, oracle_source_id, timestamp)",
                
                # Indexes for time-based queries
                "CREATE INDEX IF NOT EXISTS idx_price_feeds_last_updated ON price_feeds(last_updated)",
                "CREATE INDEX IF NOT EXISTS idx_oracle_feed_history_timestamp ON oracle_feed_history(timestamp)",
                "CREATE INDEX IF NOT EXISTS idx_l2_network_prices_last_updated ON l2_network_prices(last_updated)",
                
                # Indexes for aggregation queries
                "CREATE INDEX IF NOT EXISTS idx_price_aggregations_timestamp ON price_aggregations(timestamp)",
                "CREATE INDEX IF NOT EXISTS idx_price_aggregations_asset_timestamp ON price_aggregations(asset_id, timestamp)",
            ]
            
            for index_sql in indexes:
                await self.conn.execute(index_sql)
            
            logger.info("Additional indexes created successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to create indexes: {e}")
            return False
    
    async def setup_partitions(self):
        """Setup table partitioning for better performance"""
        try:
            # Create partitions for current year and next year
            partitions = [
                # Price feeds partitions
                "CREATE TABLE IF NOT EXISTS price_feeds_2025 PARTITION OF price_feeds FOR VALUES FROM ('2025-01-01') TO ('2026-01-01')",
                
                # Oracle feed history partitions
                "CREATE TABLE IF NOT EXISTS oracle_feed_history_2025 PARTITION OF oracle_feed_history FOR VALUES FROM ('2025-01-01') TO ('2026-01-01')",
            ]
            
            for partition_sql in partitions:
                await self.conn.execute(partition_sql)
            
            logger.info("Table partitions created successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to create partitions: {e}")
            return False
    
    async def create_views(self):
        """Create additional views for common queries"""
        try:
            views = [
                # View for latest prices from each oracle
                """
                CREATE OR REPLACE VIEW latest_prices AS
                SELECT DISTINCT ON (ca.symbol, os.name)
                    ca.symbol,
                    ca.name,
                    ca.network,
                    pf.price_usd,
                    pf.volume_24h_usd,
                    pf.market_cap_usd,
                    pf.price_change_24h_percent,
                    pf.last_updated,
                    os.name as oracle_source
                FROM price_feeds pf
                JOIN crypto_assets ca ON pf.asset_id = ca.id
                JOIN oracle_sources os ON pf.oracle_source_id = os.id
                WHERE pf.last_updated >= NOW() - INTERVAL '1 hour'
                ORDER BY ca.symbol, os.name, pf.last_updated DESC
                """,
                
                # View for price comparison across oracles
                """
                CREATE OR REPLACE VIEW price_comparison AS
                SELECT 
                    ca.symbol,
                    os.name as oracle_source,
                    pf.price_usd,
                    pf.last_updated,
                    ROW_NUMBER() OVER (PARTITION BY ca.symbol ORDER BY pf.last_updated DESC) as recency_rank
                FROM price_feeds pf
                JOIN crypto_assets ca ON pf.asset_id = ca.id
                JOIN oracle_sources os ON pf.oracle_source_id = os.id
                WHERE pf.last_updated >= NOW() - INTERVAL '1 hour'
                """,
                
                # View for L2 network summary
                """
                CREATE OR REPLACE VIEW l2_network_summary AS
                SELECT 
                    network,
                    network_token_symbol,
                    price_usd,
                    tvl_usd,
                    total_transactions_24h,
                    last_updated,
                    ROW_NUMBER() OVER (PARTITION BY network ORDER BY last_updated DESC) as recency_rank
                FROM l2_network_prices
                WHERE last_updated >= NOW() - INTERVAL '1 hour'
                """
            ]
            
            for view_sql in views:
                await self.conn.execute(view_sql)
            
            logger.info("Additional views created successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to create views: {e}")
            return False
    
    async def setup_monitoring(self):
        """Setup monitoring and alerting tables"""
        try:
            monitoring_sql = [
                # Price deviation alerts
                """
                CREATE TABLE IF NOT EXISTS price_deviation_alerts (
                    id SERIAL PRIMARY KEY,
                    asset_id INTEGER NOT NULL REFERENCES crypto_assets(id),
                    oracle_source_id INTEGER NOT NULL REFERENCES oracle_sources(id),
                    deviation_percent DECIMAL(10,4) NOT NULL,
                    threshold_percent DECIMAL(10,4) NOT NULL,
                    alert_type VARCHAR(20) NOT NULL, -- high_deviation, stale_data, etc.
                    message TEXT,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                )
                """,
                
                # Oracle health monitoring
                """
                CREATE TABLE IF NOT EXISTS oracle_health_log (
                    id SERIAL PRIMARY KEY,
                    oracle_source_id INTEGER NOT NULL REFERENCES oracle_sources(id),
                    status VARCHAR(20) NOT NULL, -- healthy, degraded, down
                    response_time_ms INTEGER,
                    error_message TEXT,
                    checked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                )
                """,
                
                # Data quality metrics
                """
                CREATE TABLE IF NOT EXISTS data_quality_metrics (
                    id SERIAL PRIMARY KEY,
                    metric_name VARCHAR(100) NOT NULL,
                    metric_value DECIMAL(15,6) NOT NULL,
                    threshold_value DECIMAL(15,6),
                    status VARCHAR(20) NOT NULL, -- good, warning, critical
                    measured_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                )
                """
            ]
            
            for sql in monitoring_sql:
                await self.conn.execute(sql)
            
            logger.info("Monitoring tables created successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to create monitoring tables: {e}")
            return False

async def main():
    """Main initialization function"""
    initializer = DatabaseInitializer()
    
    try:
        logger.info("Starting database initialization...")
        
        # Connect to database
        await initializer.connect()
        
        # Create schema
        if not await initializer.create_schema():
            logger.error("Schema creation failed")
            return 1
        
        # Create additional indexes
        if not await initializer.create_indexes():
            logger.error("Index creation failed")
            return 1
        
        # Setup partitions
        if not await initializer.setup_partitions():
            logger.error("Partition setup failed")
            return 1
        
        # Create views
        if not await initializer.create_views():
            logger.error("View creation failed")
            return 1
        
        # Setup monitoring
        if not await initializer.setup_monitoring():
            logger.error("Monitoring setup failed")
            return 1
        
        # Verify schema
        if not await initializer.verify_schema():
            logger.error("Schema verification failed")
            return 1
        
        logger.info("Database initialization completed successfully!")
        return 0
        
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
        return 1
        
    finally:
        await initializer.close()

if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
