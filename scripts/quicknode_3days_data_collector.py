#!/usr/bin/env python3
"""
QuickNode 3-Day Data Collection Script
Fetches blockchain data from QuickNode API for the last 3 days across multiple networks
"""

import os
import asyncio
import aiohttp
import asyncpg
import json
import time
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from dotenv import load_dotenv
import argparse

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('quicknode_3days_collection.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class NetworkConfig:
    """Network configuration for QuickNode"""
    name: str
    chain_id: int
    network_key: str
    blocks_per_second: float
    enabled: bool = True
    priority: int = 1

class QuickNode3DaysCollector:
    """QuickNode 3-day data collector for multiple networks"""
    
    def __init__(self, networks: Optional[List[str]] = None):
        # QuickNode configuration
        self.endpoint_name = os.getenv('QUICKNODE_ENDPOINT_NAME', 'hidden-holy-seed')
        self.token_id = os.getenv('QUICKNODE_TOKEN_ID', '97d6d8e7659b49b126c43455edc4607949bfb52b')
        self.api_key = os.getenv('QUICKNODE_API_KEY', 'QN_6a9c24b3a5fc491f88e8c24c3294ef36')
        
        # Database configuration
        self.db_config = {
            'host': os.getenv('POSTGRES_HOST', 'localhost'),
            'port': os.getenv('POSTGRES_PORT', '5432'),
            'database': os.getenv('POSTGRES_DB', 'defi_analytics'),
            'user': os.getenv('POSTGRES_USER', 'postgres'),
            'password': os.getenv('POSTGRES_PASSWORD', 'password')
        }
        
        # Collection settings
        self.batch_size = int(os.getenv('QUICKNODE_BATCH_SIZE', '200'))
        self.max_concurrent_requests = int(os.getenv('QUICKNODE_MAX_CONCURRENT', '15'))
        self.rate_limit_delay = float(os.getenv('QUICKNODE_RATE_LIMIT', '0.05'))
        self.retry_attempts = int(os.getenv('QUICKNODE_RETRY_ATTEMPTS', '3'))
        
        # Network configurations
        self.networks = self._setup_networks()
        
        # Filter networks if specified
        if networks:
            self.networks = {k: v for k, v in self.networks.items() if k in networks}
        
        # Statistics
        self.stats = {
            'start_time': None,
            'total_blocks': 0,
            'total_transactions': 0,
            'total_receipts': 0,
            'errors': 0,
            'network_stats': {}
        }
    
    def _setup_networks(self) -> Dict[str, NetworkConfig]:
        """Setup network configurations"""
        return {
            'ethereum': NetworkConfig(
                name='Ethereum',
                chain_id=1,
                network_key='ethereum',
                blocks_per_second=12.0,
                priority=1
            ),
            'polygon': NetworkConfig(
                name='Polygon',
                chain_id=137,
                network_key='matic',
                blocks_per_second=2.0,
                priority=2
            ),
            'arbitrum': NetworkConfig(
                name='Arbitrum One',
                chain_id=42161,
                network_key='arbitrum-one',
                blocks_per_second=0.5,
                priority=3
            ),
            'optimism': NetworkConfig(
                name='Optimism',
                chain_id=10,
                network_key='optimism',
                blocks_per_second=2.0,
                priority=4
            ),
            'base': NetworkConfig(
                name='Base',
                chain_id=8453,
                network_key='base',
                blocks_per_second=2.0,
                priority=5
            ),
            'bsc': NetworkConfig(
                name='Binance Smart Chain',
                chain_id=56,
                network_key='bsc-mainnet',
                blocks_per_second=3.0,
                priority=6
            ),
            'avalanche': NetworkConfig(
                name='Avalanche C-Chain',
                chain_id=43114,
                network_key='avalanche-mainnet',
                blocks_per_second=2.0,
                priority=7
            )
        }
    
    def _get_network_url(self, network_key: str) -> str:
        """Get QuickNode URL for specific network"""
        if network_key == 'ethereum':
            return f"https://{self.endpoint_name}.quiknode.pro/{self.token_id}/"
        else:
            return f"https://{self.endpoint_name}.{network_key}.quiknode.pro/{self.token_id}/"
    
    async def make_request(self, session: aiohttp.ClientSession, url: str, method: str, params: List = None, retries: int = 0) -> Optional[Dict]:
        """Make request to QuickNode API with retry logic"""
        headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {self.api_key}'
        }
        
        payload = {
            'jsonrpc': '2.0',
            'id': 1,
            'method': method,
            'params': params or []
        }
        
        for attempt in range(retries + 1):
            try:
                async with session.post(url, json=payload, headers=headers, timeout=30) as response:
                    if response.status == 200:
                        result = await response.json()
                        if 'error' in result:
                            logger.error(f"QuickNode API error: {result['error']}")
                            return None
                        return result
                    else:
                        logger.warning(f"HTTP {response.status}: {await response.text()}")
                        
            except asyncio.TimeoutError:
                logger.warning(f"Request timeout (attempt {attempt + 1}/{retries + 1})")
            except Exception as e:
                logger.error(f"Request failed (attempt {attempt + 1}/{retries + 1}): {e}")
            
            if attempt < retries:
                await asyncio.sleep(2 ** attempt)  # Exponential backoff
        
        return None
    
    async def connect_database(self) -> bool:
        """Connect to PostgreSQL database"""
        try:
            self.conn = await asyncpg.connect(**self.db_config)
            logger.info("✅ Connected to PostgreSQL successfully")
            return True
        except Exception as e:
            logger.error(f"❌ Failed to connect to PostgreSQL: {e}")
            return False
    
    async def get_latest_block(self, session: aiohttp.ClientSession, network: NetworkConfig) -> Optional[int]:
        """Get latest block number for network"""
        url = self._get_network_url(network.network_key)
        result = await self.make_request(session, url, 'eth_blockNumber', retries=self.retry_attempts)
        
        if result and 'result' in result:
            block_number = int(result['result'], 16)
            logger.info(f"✅ {network.name} latest block: {block_number:,}")
            return block_number
        
        logger.error(f"❌ Failed to get latest block for {network.name}")
        return None
    
    def calculate_3days_ago_block(self, latest_block: int, blocks_per_second: float) -> int:
        """Calculate approximate block number from 3 days ago"""
        seconds_per_3days = 3 * 24 * 60 * 60  # 259,200 seconds
        blocks_per_3days = int(seconds_per_3days * blocks_per_second)
        three_days_ago_block = max(0, latest_block - blocks_per_3days)
        return three_days_ago_block
    
    def hex_to_int(self, hex_value) -> int:
        """Convert hex string to integer"""
        if isinstance(hex_value, str) and hex_value.startswith('0x'):
            return int(hex_value, 16)
        return int(hex_value) if hex_value else 0
    
    async def get_block_data(self, session: aiohttp.ClientSession, url: str, block_number: int) -> Optional[Dict]:
        """Get block data by number"""
        hex_block = hex(block_number)
        result = await self.make_request(session, url, 'eth_getBlockByNumber', [hex_block, True], retries=self.retry_attempts)
        return result.get('result') if result else None
    
    async def get_transaction_receipt(self, session: aiohttp.ClientSession, url: str, tx_hash: str) -> Optional[Dict]:
        """Get transaction receipt"""
        result = await self.make_request(session, url, 'eth_getTransactionReceipt', [tx_hash], retries=self.retry_attempts)
        return result.get('result') if result else None
    
    async def create_tables_if_not_exist(self):
        """Create database tables if they don't exist"""
        try:
            # Create schema for each network
            for network_key, network in self.networks.items():
                schema_name = f"{network_key}_data"
                
                # Create schema
                await self.conn.execute(f"CREATE SCHEMA IF NOT EXISTS {schema_name}")
                
                # Create blocks table
                await self.conn.execute(f"""
                    CREATE TABLE IF NOT EXISTS {schema_name}.blocks (
                        block_number BIGINT PRIMARY KEY,
                        block_hash VARCHAR(66) NOT NULL,
                        parent_hash VARCHAR(66) NOT NULL,
                        timestamp BIGINT NOT NULL,
                        gas_limit BIGINT,
                        gas_used BIGINT,
                        miner VARCHAR(42),
                        difficulty VARCHAR(66),
                        total_difficulty VARCHAR(66),
                        size BIGINT,
                        extra_data TEXT,
                        nonce VARCHAR(18),
                        base_fee_per_gas VARCHAR(66),
                        transactions_count INTEGER,
                        logs_bloom TEXT,
                        state_root VARCHAR(66),
                        receipts_root VARCHAR(66),
                        transactions_root VARCHAR(66),
                        uncle_hash VARCHAR(66),
                        mix_hash VARCHAR(66),
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                
                # Create transactions table
                await self.conn.execute(f"""
                    CREATE TABLE IF NOT EXISTS {schema_name}.transactions (
                        hash VARCHAR(66) PRIMARY KEY,
                        block_number BIGINT NOT NULL,
                        block_hash VARCHAR(66) NOT NULL,
                        from_address VARCHAR(42) NOT NULL,
                        to_address VARCHAR(42),
                        value VARCHAR(66) NOT NULL,
                        gas BIGINT NOT NULL,
                        gas_price VARCHAR(66) NOT NULL,
                        nonce BIGINT NOT NULL,
                        input_data TEXT,
                        transaction_index INTEGER NOT NULL,
                        timestamp BIGINT,
                        max_fee_per_gas VARCHAR(66),
                        max_priority_fee_per_gas VARCHAR(66),
                        type VARCHAR(4),
                        chain_id VARCHAR(66),
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                
                # Create receipts table
                await self.conn.execute(f"""
                    CREATE TABLE IF NOT EXISTS {schema_name}.receipts (
                        transaction_hash VARCHAR(66) PRIMARY KEY,
                        block_number BIGINT NOT NULL,
                        block_hash VARCHAR(66) NOT NULL,
                        transaction_index INTEGER NOT NULL,
                        from_address VARCHAR(42) NOT NULL,
                        to_address VARCHAR(42),
                        cumulative_gas_used BIGINT NOT NULL,
                        gas_used BIGINT NOT NULL,
                        contract_address VARCHAR(42),
                        logs JSONB,
                        status INTEGER NOT NULL,
                        effective_gas_price VARCHAR(66),
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                
                # Create indexes
                await self.conn.execute(f"CREATE INDEX IF NOT EXISTS idx_{schema_name}_blocks_timestamp ON {schema_name}.blocks(timestamp)")
                await self.conn.execute(f"CREATE INDEX IF NOT EXISTS idx_{schema_name}_transactions_block ON {schema_name}.transactions(block_number)")
                await self.conn.execute(f"CREATE INDEX IF NOT EXISTS idx_{schema_name}_receipts_block ON {schema_name}.receipts(block_number)")
                
                logger.info(f"✅ Created tables for {network.name}")
        
        except Exception as e:
            logger.error(f"❌ Error creating tables: {e}")
            raise
    
    async def import_block_to_db(self, network_key: str, block_data: Dict) -> bool:
        """Import block data to database"""
        try:
            schema_name = f"{network_key}_data"
            
            # Convert hex values
            block_number = self.hex_to_int(block_data['number'])
            timestamp = self.hex_to_int(block_data['timestamp'])
            gas_limit = self.hex_to_int(block_data['gasLimit'])
            gas_used = self.hex_to_int(block_data['gasUsed'])
            
            await self.conn.execute(f"""
                INSERT INTO {schema_name}.blocks (
                    block_number, block_hash, parent_hash, timestamp,
                    gas_limit, gas_used, miner, difficulty, total_difficulty,
                    size, extra_data, nonce, base_fee_per_gas, transactions_count,
                    logs_bloom, state_root, receipts_root, transactions_root,
                    uncle_hash, mix_hash
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
                ON CONFLICT (block_number) DO UPDATE SET
                    gas_used = EXCLUDED.gas_used,
                    transactions_count = EXCLUDED.transactions_count,
                    updated_at = CURRENT_TIMESTAMP
            """, 
                block_number,
                block_data['hash'],
                block_data['parentHash'],
                timestamp,
                gas_limit,
                gas_used,
                block_data['miner'],
                str(block_data.get('difficulty', '')),
                str(block_data.get('totalDifficulty', '')),
                self.hex_to_int(block_data.get('size')),
                block_data.get('extraData'),
                block_data.get('nonce'),
                str(block_data.get('baseFeePerGas', '')),
                len(block_data.get('transactions', [])),
                block_data.get('logsBloom'),
                block_data.get('stateRoot'),
                block_data.get('receiptsRoot'),
                block_data.get('transactionsRoot'),
                block_data.get('sha3Uncles'),
                block_data.get('mixHash')
            )
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Error importing block {block_data.get('number', 'unknown')}: {e}")
            return False
    
    async def import_transaction_to_db(self, network_key: str, tx_data: Dict, receipt_data: Optional[Dict] = None) -> bool:
        """Import transaction data to database"""
        try:
            schema_name = f"{network_key}_data"
            
            # Convert hex values
            block_number = self.hex_to_int(tx_data['blockNumber'])
            gas = self.hex_to_int(tx_data['gas'])
            nonce = self.hex_to_int(tx_data['nonce'])
            transaction_index = self.hex_to_int(tx_data['transactionIndex'])
            
            # Insert transaction
            await self.conn.execute(f"""
                INSERT INTO {schema_name}.transactions (
                    hash, block_number, block_hash, from_address, to_address,
                    value, gas, gas_price, nonce, input_data, transaction_index,
                    timestamp, max_fee_per_gas, max_priority_fee_per_gas, type, chain_id
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
                ON CONFLICT (hash) DO UPDATE SET
                    gas = EXCLUDED.gas,
                    gas_price = EXCLUDED.gas_price,
                    updated_at = CURRENT_TIMESTAMP
            """,
                tx_data['hash'],
                block_number,
                tx_data['blockHash'],
                tx_data['from'],
                tx_data.get('to'),
                tx_data['value'],
                gas,
                tx_data['gasPrice'],
                nonce,
                tx_data.get('input'),
                transaction_index,
                self.hex_to_int(tx_data.get('timestamp', 0)),
                str(tx_data.get('maxFeePerGas', '')),
                str(tx_data.get('maxPriorityFeePerGas', '')),
                str(tx_data.get('type', '')),
                str(tx_data.get('chainId', ''))
            )
            
            # Insert receipt if available
            if receipt_data:
                gas_used = self.hex_to_int(receipt_data['gasUsed'])
                cumulative_gas_used = self.hex_to_int(receipt_data['cumulativeGasUsed'])
                status = self.hex_to_int(receipt_data.get('status', 0))
                
                await self.conn.execute(f"""
                    INSERT INTO {schema_name}.receipts (
                        transaction_hash, block_number, block_hash, transaction_index,
                        from_address, to_address, cumulative_gas_used, gas_used,
                        contract_address, logs, status, effective_gas_price
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
                    ON CONFLICT (transaction_hash) DO UPDATE SET
                        gas_used = EXCLUDED.gas_used,
                        status = EXCLUDED.status,
                        updated_at = CURRENT_TIMESTAMP
                """,
                    receipt_data['transactionHash'],
                    block_number,
                    receipt_data['blockHash'],
                    self.hex_to_int(receipt_data['transactionIndex']),
                    receipt_data['from'],
                    receipt_data.get('to'),
                    cumulative_gas_used,
                    gas_used,
                    receipt_data.get('contractAddress'),
                    json.dumps(receipt_data.get('logs', [])),
                    status,
                    str(receipt_data.get('effectiveGasPrice', ''))
                )
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Error importing transaction {tx_data.get('hash', 'unknown')[:10]}...: {e}")
            return False
    
    async def process_block_batch(self, session: aiohttp.ClientSession, network: NetworkConfig, block_numbers: List[int]) -> tuple:
        """Process a batch of blocks for a network"""
        url = self._get_network_url(network.network_key)
        tasks = []
        semaphore = asyncio.Semaphore(self.max_concurrent_requests)
        
        async def process_block(block_number: int) -> tuple:
            async with semaphore:
                try:
                    # Get block data
                    block_data = await self.get_block_data(session, url, block_number)
                    if not block_data:
                        return 0, 0
                    
                    # Import block
                    block_success = await self.import_block_to_db(network.network_key, block_data)
                    if not block_success:
                        return 0, 0
                    
                    # Process transactions
                    transactions = block_data.get('transactions', [])
                    tx_count = 0
                    receipt_count = 0
                    
                    for tx in transactions:
                        # Get receipt
                        receipt = await self.get_transaction_receipt(session, url, tx['hash'])
                        
                        # Import transaction and receipt
                        tx_success = await self.import_transaction_to_db(network.network_key, tx, receipt)
                        if tx_success:
                            tx_count += 1
                            if receipt:
                                receipt_count += 1
                        
                        # Rate limiting
                        await asyncio.sleep(self.rate_limit_delay)
                    
                    return tx_count, receipt_count
                    
                except Exception as e:
                    logger.error(f"❌ Error processing block {block_number}: {e}")
                    return 0, 0
        
        # Create tasks for all blocks in batch
        for block_number in block_numbers:
            task = asyncio.create_task(process_block(block_number))
            tasks.append(task)
        
        # Wait for all tasks to complete
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Count results
        total_txs = sum(r[0] for r in results if isinstance(r, tuple))
        total_receipts = sum(r[1] for r in results if isinstance(r, tuple))
        
        return total_txs, total_receipts
    
    async def collect_network_data(self, session: aiohttp.ClientSession, network: NetworkConfig) -> Dict[str, Any]:
        """Collect 3 days of data for a specific network"""
        logger.info(f"🚀 Starting {network.name} data collection")
        
        network_stats = {
            'network': network.name,
            'blocks_processed': 0,
            'transactions': 0,
            'receipts': 0,
            'errors': 0,
            'start_time': time.time()
        }
        
        try:
            # Get latest block
            latest_block = await self.get_latest_block(session, network)
            if not latest_block:
                network_stats['errors'] += 1
                return network_stats
            
            # Calculate 3 days ago block
            three_days_ago_block = self.calculate_3days_ago_block(latest_block, network.blocks_per_second)
            total_blocks = latest_block - three_days_ago_block
            
            logger.info(f"📊 {network.name} Collection Plan:")
            logger.info(f"  Latest block: {latest_block:,}")
            logger.info(f"  3 days ago block: {three_days_ago_block:,}")
            logger.info(f"  Total blocks to collect: {total_blocks:,}")
            
            # Process blocks in batches
            for batch_start in range(three_days_ago_block, latest_block, self.batch_size):
                batch_end = min(batch_start + self.batch_size, latest_block)
                batch_blocks = list(range(batch_start, batch_end))
                
                logger.info(f"📦 {network.name} Processing batch: {batch_start:,} - {batch_end:,}")
                
                # Process batch
                txs, receipts = await self.process_block_batch(session, network, batch_blocks)
                
                network_stats['blocks_processed'] += len(batch_blocks)
                network_stats['transactions'] += txs
                network_stats['receipts'] += receipts
                
                # Progress update
                elapsed_time = time.time() - network_stats['start_time']
                blocks_per_second = network_stats['blocks_processed'] / elapsed_time if elapsed_time > 0 else 0
                estimated_remaining = (total_blocks - network_stats['blocks_processed']) / blocks_per_second if blocks_per_second > 0 else 0
                
                logger.info(f"✅ {network.name} Batch completed: {len(batch_blocks)} blocks, {txs} transactions, {receipts} receipts")
                logger.info(f"📈 {network.name} Progress: {network_stats['blocks_processed']:,}/{total_blocks:,} ({network_stats['blocks_processed']/total_blocks*100:.1f}%)")
                logger.info(f"⏱️ {network.name} Speed: {blocks_per_second:.1f} blocks/sec, ETA: {estimated_remaining/60:.1f} minutes")
                
                # Small delay between batches
                await asyncio.sleep(0.5)
            
            # Final network statistics
            elapsed_time = time.time() - network_stats['start_time']
            network_stats['elapsed_time'] = elapsed_time
            network_stats['blocks_per_second'] = network_stats['blocks_processed'] / elapsed_time if elapsed_time > 0 else 0
            
            logger.info(f"🎉 {network.name} collection completed!")
            logger.info(f"📊 {network.name} Final Statistics:")
            logger.info(f"  Total blocks processed: {network_stats['blocks_processed']:,}")
            logger.info(f"  Total transactions: {network_stats['transactions']:,}")
            logger.info(f"  Total receipts: {network_stats['receipts']:,}")
            logger.info(f"  Total time: {elapsed_time/60:.1f} minutes")
            logger.info(f"  Average speed: {network_stats['blocks_per_second']:.1f} blocks/sec")
            
            return network_stats
            
        except Exception as e:
            logger.error(f"❌ {network.name} collection failed: {e}")
            network_stats['errors'] += 1
            return network_stats
    
    async def collect_all_networks_data(self):
        """Collect data for all enabled networks"""
        logger.info("🚀 Starting QuickNode 3-Day Data Collection")
        logger.info("=" * 80)
        
        # Connect to database
        if not await self.connect_database():
            return
        
        try:
            # Create tables if they don't exist
            await self.create_tables_if_not_exist()
            
            # Sort networks by priority
            sorted_networks = sorted(self.networks.values(), key=lambda x: x.priority)
            
            # Confirm collection
            logger.info(f"📋 Networks to collect: {', '.join([n.name for n in sorted_networks])}")
            logger.info(f"📊 Total networks: {len(sorted_networks)}")
            
            # Start collection
            self.stats['start_time'] = time.time()
            
            # Create HTTP session
            connector = aiohttp.TCPConnector(ssl=False, limit=100)
            timeout = aiohttp.ClientTimeout(total=60)
            
            async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
                # Process networks sequentially to avoid overwhelming the API
                for network in sorted_networks:
                    if not network.enabled:
                        logger.info(f"⏭️ Skipping disabled network: {network.name}")
                        continue
                    
                    logger.info(f"\n{'='*60}")
                    logger.info(f"🌐 Processing Network: {network.name}")
                    logger.info(f"{'='*60}")
                    
                    # Collect data for this network
                    network_stats = await self.collect_network_data(session, network)
                    
                    # Update global statistics
                    self.stats['total_blocks'] += network_stats['blocks_processed']
                    self.stats['total_transactions'] += network_stats['transactions']
                    self.stats['total_receipts'] += network_stats['receipts']
                    self.stats['errors'] += network_stats['errors']
                    self.stats['network_stats'][network.name] = network_stats
                    
                    # Delay between networks
                    await asyncio.sleep(2)
            
            # Final statistics
            self._print_final_statistics()
            
        except Exception as e:
            logger.error(f"❌ Collection failed: {e}")
        
        finally:
            await self.conn.close()
            logger.info("✅ Database connection closed")
    
    def _print_final_statistics(self):
        """Print final collection statistics"""
        elapsed_time = time.time() - self.stats['start_time']
        
        logger.info(f"\n{'='*80}")
        logger.info("🎉 QUICKNODE 3-DAY DATA COLLECTION COMPLETED!")
        logger.info(f"{'='*80}")
        logger.info(f"📊 GLOBAL STATISTICS:")
        logger.info(f"  Total networks processed: {len(self.stats['network_stats'])}")
        logger.info(f"  Total blocks processed: {self.stats['total_blocks']:,}")
        logger.info(f"  Total transactions: {self.stats['total_transactions']:,}")
        logger.info(f"  Total receipts: {self.stats['total_receipts']:,}")
        logger.info(f"  Total errors: {self.stats['errors']}")
        logger.info(f"  Total time: {elapsed_time/60:.1f} minutes")
        logger.info(f"  Average speed: {self.stats['total_blocks']/elapsed_time:.1f} blocks/sec")
        
        logger.info(f"\n📈 NETWORK BREAKDOWN:")
        for network_name, stats in self.stats['network_stats'].items():
            logger.info(f"  {network_name}:")
            logger.info(f"    Blocks: {stats['blocks_processed']:,}")
            logger.info(f"    Transactions: {stats['transactions']:,}")
            logger.info(f"    Receipts: {stats['receipts']:,}")
            logger.info(f"    Time: {stats['elapsed_time']/60:.1f} minutes")
            logger.info(f"    Speed: {stats['blocks_per_second']:.1f} blocks/sec")
            if stats['errors'] > 0:
                logger.info(f"    Errors: {stats['errors']}")
        
        # Save statistics to file
        stats_file = f"quicknode_3days_stats_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(stats_file, 'w') as f:
            json.dump(self.stats, f, indent=2, default=str)
        
        logger.info(f"\n💾 Statistics saved to: {stats_file}")

async def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='QuickNode 3-Day Data Collector')
    parser.add_argument('--networks', nargs='+', help='Specific networks to collect (e.g., ethereum polygon)')
    parser.add_argument('--batch-size', type=int, default=200, help='Batch size for block processing')
    parser.add_argument('--max-concurrent', type=int, default=15, help='Maximum concurrent requests')
    parser.add_argument('--rate-limit', type=float, default=0.05, help='Rate limit delay between requests')
    
    args = parser.parse_args()
    
    # Create collector
    collector = QuickNode3DaysCollector(networks=args.networks)
    
    # Override settings if provided
    if args.batch_size:
        collector.batch_size = args.batch_size
    if args.max_concurrent:
        collector.max_concurrent_requests = args.max_concurrent
    if args.rate_limit:
        collector.rate_limit_delay = args.rate_limit
    
    # Start collection
    await collector.collect_all_networks_data()

if __name__ == "__main__":
    asyncio.run(main())
