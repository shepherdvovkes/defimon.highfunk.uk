#!/usr/bin/env python3
"""
Polygon Database Manager
Manages PostgreSQL database operations for Polygon network data
"""

import asyncio
import asyncpg
import logging
from typing import Dict, List, Optional, Any, Union
from datetime import datetime
import json
import os
from dataclasses import asdict
import sys

# Add parent directory to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from collectors.block_collector import BlockData, TransactionData, TransactionReceiptData

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class PolygonDatabaseManager:
    """Database manager for Polygon network data"""
    
    def __init__(self, connection_string: str = None):
        self.connection_string = connection_string or self._get_connection_string()
        self.pool = None
        
    def _get_connection_string(self) -> str:
        """Get database connection string from environment"""
        # Read from gcp.env file
        env_file = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), 'gcp.env')
        
        if os.path.exists(env_file):
            with open(env_file, 'r') as f:
                for line in f:
                    if line.strip() and not line.startswith('#'):
                        key, value = line.strip().split('=', 1)
                        os.environ[key] = value
        
        # Get connection parameters
        project_id = os.getenv('GOOGLE_CLOUD_PROJECT_ID', 'defimon-ethereum-node')
        region = os.getenv('GOOGLE_CLOUD_REGION', 'us-central1')
        instance_name = os.getenv('GOOGLE_CLOUD_SQL_INSTANCE_NAME', 'defimon-postgres-instance')
        database_name = os.getenv('GOOGLE_CLOUD_SQL_DATABASE_NAME', 'defi_analytics')
        user = os.getenv('GOOGLE_CLOUD_SQL_USER', 'defimon_user')
        password = os.getenv('GOOGLE_CLOUD_SQL_PASSWORD', 'defimon_secure_password_2024')
        
        # Create connection string
        connection_string = f"postgresql://{user}:{password}@/{database_name}?host=/cloudsql/{project_id}:{region}:{instance_name}"
        
        logger.info(f"Using database: {database_name} on instance: {instance_name}")
        return connection_string
    
    async def initialize(self):
        """Initialize database connection pool"""
        try:
            self.pool = await asyncpg.create_pool(
                self.connection_string,
                min_size=5,
                max_size=20,
                command_timeout=60
            )
            logger.info("Database connection pool initialized")
            
            # Create Polygon-specific database and tables
            await self.create_polygon_database()
            await self.create_tables()
            
        except Exception as e:
            logger.error(f"Failed to initialize database: {e}")
            raise
    
    async def cleanup(self):
        """Cleanup database connections"""
        if self.pool:
            await self.pool.close()
            logger.info("Database connection pool closed")
    
    async def create_polygon_database(self):
        """Create Polygon-specific database schema"""
        try:
            async with self.pool.acquire() as conn:
                # Create schema for Polygon data
                await conn.execute("""
                    CREATE SCHEMA IF NOT EXISTS polygon_data;
                """)
                
                logger.info("Created polygon_data schema")
                
        except Exception as e:
            logger.error(f"Failed to create Polygon database schema: {e}")
            raise
    
    async def create_tables(self):
        """Create all necessary tables for Polygon data"""
        try:
            async with self.pool.acquire() as conn:
                
                # Create blocks table
                await conn.execute("""
                    CREATE TABLE IF NOT EXISTS polygon_data.blocks (
                        block_number BIGINT PRIMARY KEY,
                        block_hash VARCHAR(66) UNIQUE NOT NULL,
                        parent_hash VARCHAR(66) NOT NULL,
                        timestamp BIGINT NOT NULL,
                        gas_limit BIGINT NOT NULL,
                        gas_used BIGINT NOT NULL,
                        miner VARCHAR(42) NOT NULL,
                        difficulty VARCHAR(100) NOT NULL,
                        total_difficulty VARCHAR(100) NOT NULL,
                        size INTEGER NOT NULL,
                        extra_data TEXT,
                        nonce VARCHAR(18) NOT NULL,
                        base_fee_per_gas VARCHAR(100),
                        transactions_count INTEGER DEFAULT 0,
                        logs_bloom TEXT,
                        state_root VARCHAR(66),
                        receipts_root VARCHAR(66),
                        transactions_root VARCHAR(66),
                        uncle_hash VARCHAR(66),
                        mix_hash VARCHAR(66),
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    );
                """)
                
                # Create transactions table
                await conn.execute("""
                    CREATE TABLE IF NOT EXISTS polygon_data.transactions (
                        hash VARCHAR(66) PRIMARY KEY,
                        block_number BIGINT NOT NULL,
                        block_hash VARCHAR(66) NOT NULL,
                        from_address VARCHAR(42) NOT NULL,
                        to_address VARCHAR(42),
                        value VARCHAR(100) NOT NULL,
                        gas BIGINT NOT NULL,
                        gas_price VARCHAR(100) NOT NULL,
                        nonce BIGINT NOT NULL,
                        input_data TEXT,
                        transaction_index INTEGER NOT NULL,
                        timestamp BIGINT NOT NULL,
                        max_fee_per_gas VARCHAR(100),
                        max_priority_fee_per_gas VARCHAR(100),
                        type INTEGER,
                        access_list JSONB,
                        chain_id INTEGER,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        FOREIGN KEY (block_number) REFERENCES polygon_data.blocks(block_number)
                    );
                """)
                
                # Create transaction receipts table
                await conn.execute("""
                    CREATE TABLE IF NOT EXISTS polygon_data.transaction_receipts (
                        transaction_hash VARCHAR(66) PRIMARY KEY,
                        block_number BIGINT NOT NULL,
                        block_hash VARCHAR(66) NOT NULL,
                        transaction_index INTEGER NOT NULL,
                        from_address VARCHAR(42) NOT NULL,
                        to_address VARCHAR(42),
                        cumulative_gas_used BIGINT NOT NULL,
                        gas_used BIGINT NOT NULL,
                        contract_address VARCHAR(42),
                        logs JSONB NOT NULL,
                        status INTEGER NOT NULL,
                        effective_gas_price VARCHAR(100) NOT NULL,
                        type INTEGER,
                        logs_bloom TEXT,
                        root VARCHAR(66),
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        FOREIGN KEY (transaction_hash) REFERENCES polygon_data.transactions(hash),
                        FOREIGN KEY (block_number) REFERENCES polygon_data.blocks(block_number)
                    );
                """)
                
                # Create DeFi protocols table
                await conn.execute("""
                    CREATE TABLE IF NOT EXISTS polygon_data.defi_protocols (
                        id SERIAL PRIMARY KEY,
                        name VARCHAR(100) NOT NULL,
                        category VARCHAR(50) NOT NULL,
                        contract_address VARCHAR(42) UNIQUE NOT NULL,
                        description TEXT,
                        tvl_usd DECIMAL(20, 2),
                        volume_24h DECIMAL(20, 2),
                        enabled BOOLEAN DEFAULT TRUE,
                        priority INTEGER DEFAULT 5,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    );
                """)
                
                # Create protocol interactions table
                await conn.execute("""
                    CREATE TABLE IF NOT EXISTS polygon_data.protocol_interactions (
                        id SERIAL PRIMARY KEY,
                        protocol_id INTEGER NOT NULL,
                        transaction_hash VARCHAR(66) NOT NULL,
                        block_number BIGINT NOT NULL,
                        interaction_type VARCHAR(50) NOT NULL,
                        user_address VARCHAR(42) NOT NULL,
                        amount DECIMAL(30, 18),
                        token_address VARCHAR(42),
                        gas_used BIGINT,
                        gas_price VARCHAR(100),
                        timestamp BIGINT NOT NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        FOREIGN KEY (protocol_id) REFERENCES polygon_data.defi_protocols(id),
                        FOREIGN KEY (transaction_hash) REFERENCES polygon_data.transactions(hash),
                        FOREIGN KEY (block_number) REFERENCES polygon_data.blocks(block_number)
                    );
                """)
                
                # Create token transfers table
                await conn.execute("""
                    CREATE TABLE IF NOT EXISTS polygon_data.token_transfers (
                        id SERIAL PRIMARY KEY,
                        transaction_hash VARCHAR(66) NOT NULL,
                        block_number BIGINT NOT NULL,
                        log_index INTEGER NOT NULL,
                        contract_address VARCHAR(42) NOT NULL,
                        from_address VARCHAR(42) NOT NULL,
                        to_address VARCHAR(42) NOT NULL,
                        value VARCHAR(100) NOT NULL,
                        token_name VARCHAR(100),
                        token_symbol VARCHAR(20),
                        token_decimals INTEGER,
                        timestamp BIGINT NOT NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        FOREIGN KEY (transaction_hash) REFERENCES polygon_data.transactions(hash),
                        FOREIGN KEY (block_number) REFERENCES polygon_data.blocks(block_number)
                    );
                """)
                
                # Create bridge transactions table
                await conn.execute("""
                    CREATE TABLE IF NOT EXISTS polygon_data.bridge_transactions (
                        id SERIAL PRIMARY KEY,
                        transaction_hash VARCHAR(66) NOT NULL,
                        block_number BIGINT NOT NULL,
                        bridge_name VARCHAR(100) NOT NULL,
                        bridge_contract VARCHAR(42) NOT NULL,
                        from_chain VARCHAR(50) NOT NULL,
                        to_chain VARCHAR(50) NOT NULL,
                        from_address VARCHAR(42) NOT NULL,
                        to_address VARCHAR(42) NOT NULL,
                        amount DECIMAL(30, 18) NOT NULL,
                        token_address VARCHAR(42),
                        status VARCHAR(20) NOT NULL,
                        timestamp BIGINT NOT NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        FOREIGN KEY (transaction_hash) REFERENCES polygon_data.transactions(hash),
                        FOREIGN KEY (block_number) REFERENCES polygon_data.blocks(block_number)
                    );
                """)
                
                # Create network metrics table
                await conn.execute("""
                    CREATE TABLE IF NOT EXISTS polygon_data.network_metrics (
                        id SERIAL PRIMARY KEY,
                        block_number BIGINT NOT NULL,
                        timestamp BIGINT NOT NULL,
                        gas_price VARCHAR(100) NOT NULL,
                        gas_used BIGINT NOT NULL,
                        gas_limit BIGINT NOT NULL,
                        transactions_count INTEGER NOT NULL,
                        active_addresses INTEGER,
                        daily_volume_usd DECIMAL(20, 2),
                        tvl_usd DECIMAL(20, 2),
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        UNIQUE(block_number)
                    );
                """)
                
                # Create indexes for better performance
                await conn.execute("""
                    CREATE INDEX IF NOT EXISTS idx_blocks_timestamp ON polygon_data.blocks(timestamp);
                    CREATE INDEX IF NOT EXISTS idx_blocks_miner ON polygon_data.blocks(miner);
                    CREATE INDEX IF NOT EXISTS idx_transactions_block_number ON polygon_data.transactions(block_number);
                    CREATE INDEX IF NOT EXISTS idx_transactions_from_address ON polygon_data.transactions(from_address);
                    CREATE INDEX IF NOT EXISTS idx_transactions_to_address ON polygon_data.transactions(to_address);
                    CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON polygon_data.transactions(timestamp);
                    CREATE INDEX IF NOT EXISTS idx_receipts_block_number ON polygon_data.transaction_receipts(block_number);
                    CREATE INDEX IF NOT EXISTS idx_receipts_status ON polygon_data.transaction_receipts(status);
                    CREATE INDEX IF NOT EXISTS idx_token_transfers_contract ON polygon_data.token_transfers(contract_address);
                    CREATE INDEX IF NOT EXISTS idx_token_transfers_from ON polygon_data.token_transfers(from_address);
                    CREATE INDEX IF NOT EXISTS idx_token_transfers_to ON polygon_data.token_transfers(to_address);
                    CREATE INDEX IF NOT EXISTS idx_bridge_transactions_bridge ON polygon_data.bridge_transactions(bridge_name);
                    CREATE INDEX IF NOT EXISTS idx_bridge_transactions_chains ON polygon_data.bridge_transactions(from_chain, to_chain);
                    CREATE INDEX IF NOT EXISTS idx_network_metrics_timestamp ON polygon_data.network_metrics(timestamp);
                """)
                
                logger.info("Created all Polygon data tables and indexes")
                
        except Exception as e:
            logger.error(f"Failed to create tables: {e}")
            raise
    
    async def insert_block(self, block: BlockData) -> bool:
        """Insert block data into database"""
        try:
            async with self.pool.acquire() as conn:
                await conn.execute("""
                    INSERT INTO polygon_data.blocks (
                        block_number, block_hash, parent_hash, timestamp, gas_limit, gas_used,
                        miner, difficulty, total_difficulty, size, extra_data, nonce,
                        base_fee_per_gas, transactions_count, logs_bloom, state_root,
                        receipts_root, transactions_root, uncle_hash, mix_hash
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
                    ON CONFLICT (block_number) DO UPDATE SET
                        updated_at = CURRENT_TIMESTAMP
                """, block.block_number, block.block_hash, block.parent_hash, block.timestamp,
                     block.gas_limit, block.gas_used, block.miner, block.difficulty,
                     block.total_difficulty, block.size, block.extra_data, block.nonce,
                     block.base_fee_per_gas, block.transactions_count, block.logs_bloom,
                     block.state_root, block.receipts_root, block.transactions_root,
                     block.uncle_hash, block.mix_hash)
                
                return True
                
        except Exception as e:
            logger.error(f"Failed to insert block {block.block_number}: {e}")
            return False
    
    async def insert_transaction(self, transaction: TransactionData) -> bool:
        """Insert transaction data into database"""
        try:
            async with self.pool.acquire() as conn:
                await conn.execute("""
                    INSERT INTO polygon_data.transactions (
                        hash, block_number, block_hash, from_address, to_address, value,
                        gas, gas_price, nonce, input_data, transaction_index, timestamp,
                        max_fee_per_gas, max_priority_fee_per_gas, type, access_list, chain_id
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
                    ON CONFLICT (hash) DO UPDATE SET
                        updated_at = CURRENT_TIMESTAMP
                """, transaction.hash, transaction.block_number, transaction.block_hash,
                     transaction.from_address, transaction.to_address, transaction.value,
                     transaction.gas, transaction.gas_price, transaction.nonce,
                     transaction.input_data, transaction.transaction_index, transaction.timestamp,
                     transaction.max_fee_per_gas, transaction.max_priority_fee_per_gas,
                     transaction.type, json.dumps(transaction.access_list) if transaction.access_list else None,
                     transaction.chain_id)
                
                return True
                
        except Exception as e:
            logger.error(f"Failed to insert transaction {transaction.hash}: {e}")
            return False
    
    async def insert_transaction_receipt(self, receipt: TransactionReceiptData) -> bool:
        """Insert transaction receipt data into database"""
        try:
            async with self.pool.acquire() as conn:
                await conn.execute("""
                    INSERT INTO polygon_data.transaction_receipts (
                        transaction_hash, block_number, block_hash, transaction_index,
                        from_address, to_address, cumulative_gas_used, gas_used,
                        contract_address, logs, status, effective_gas_price, type,
                        logs_bloom, root
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
                    ON CONFLICT (transaction_hash) DO UPDATE SET
                        updated_at = CURRENT_TIMESTAMP
                """, receipt.transaction_hash, receipt.block_number, receipt.block_hash,
                     receipt.transaction_index, receipt.from_address, receipt.to_address,
                     receipt.cumulative_gas_used, receipt.gas_used, receipt.contract_address,
                     json.dumps(receipt.logs), receipt.status, receipt.effective_gas_price,
                     receipt.type, receipt.logs_bloom, receipt.root)
                
                return True
                
        except Exception as e:
            logger.error(f"Failed to insert receipt for {receipt.transaction_hash}: {e}")
            return False
    
    async def insert_blocks_batch(self, blocks: List[BlockData]) -> int:
        """Insert multiple blocks in batch"""
        if not blocks:
            return 0
        
        try:
            async with self.pool.acquire() as conn:
                # Prepare data for batch insert
                data = []
                for block in blocks:
                    data.append((
                        block.block_number, block.block_hash, block.parent_hash, block.timestamp,
                        block.gas_limit, block.gas_used, block.miner, block.difficulty,
                        block.total_difficulty, block.size, block.extra_data, block.nonce,
                        block.base_fee_per_gas, block.transactions_count, block.logs_bloom,
                        block.state_root, block.receipts_root, block.transactions_root,
                        block.uncle_hash, block.mix_hash
                    ))
                
                # Batch insert
                await conn.executemany("""
                    INSERT INTO polygon_data.blocks (
                        block_number, block_hash, parent_hash, timestamp, gas_limit, gas_used,
                        miner, difficulty, total_difficulty, size, extra_data, nonce,
                        base_fee_per_gas, transactions_count, logs_bloom, state_root,
                        receipts_root, transactions_root, uncle_hash, mix_hash
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
                    ON CONFLICT (block_number) DO NOTHING
                """, data)
                
                logger.info(f"Inserted {len(blocks)} blocks in batch")
                return len(blocks)
                
        except Exception as e:
            logger.error(f"Failed to insert blocks batch: {e}")
            return 0
    
    async def get_block_count(self) -> int:
        """Get total number of blocks in database"""
        try:
            async with self.pool.acquire() as conn:
                result = await conn.fetchval("SELECT COUNT(*) FROM polygon_data.blocks")
                return result or 0
        except Exception as e:
            logger.error(f"Failed to get block count: {e}")
            return 0
    
    async def get_transaction_count(self) -> int:
        """Get total number of transactions in database"""
        try:
            async with self.pool.acquire() as conn:
                result = await conn.fetchval("SELECT COUNT(*) FROM polygon_data.transactions")
                return result or 0
        except Exception as e:
            logger.error(f"Failed to get transaction count: {e}")
            return 0
    
    async def get_latest_block(self) -> Optional[int]:
        """Get latest block number in database"""
        try:
            async with self.pool.acquire() as conn:
                result = await conn.fetchval("SELECT MAX(block_number) FROM polygon_data.blocks")
                return result
        except Exception as e:
            logger.error(f"Failed to get latest block: {e}")
            return None

# Example usage
async def main():
    """Example usage of Polygon database manager"""
    
    # Initialize database manager
    db_manager = PolygonDatabaseManager()
    
    try:
        await db_manager.initialize()
        
        # Get database statistics
        block_count = await db_manager.get_block_count()
        tx_count = await db_manager.get_transaction_count()
        latest_block = await db_manager.get_latest_block()
        
        print(f"Database Statistics:")
        print(f"  Total blocks: {block_count}")
        print(f"  Total transactions: {tx_count}")
        print(f"  Latest block: {latest_block}")
        
    finally:
        await db_manager.cleanup()

if __name__ == "__main__":
    asyncio.run(main())
