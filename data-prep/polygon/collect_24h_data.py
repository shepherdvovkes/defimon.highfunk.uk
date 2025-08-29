#!/usr/bin/env python3
"""
Collect Polygon network data for the last 24 hours and store in PostgreSQL
"""

import os
import asyncio
import aiohttp
import asyncpg
import json
from datetime import datetime, timedelta
from dotenv import load_dotenv
import time

# Load environment variables
load_dotenv()

class Polygon24hDataCollector:
    def __init__(self):
        self.endpoint_name = os.getenv('QUICKNODE_ENDPOINT_NAME', 'hidden-holy-seed')
        self.token_id = os.getenv('QUICKNODE_TOKEN_ID', '97d6d8e7659b49b126c43455edc4607949bfb52b')
        self.base_url = f"https://{self.endpoint_name}.matic.quiknode.pro/{self.token_id}/"
        
        # Database connection
        self.user = os.getenv('GOOGLE_CLOUD_SQL_USER', 'defimon_user')
        self.password = os.getenv('GOOGLE_CLOUD_SQL_PASSWORD', 'Zd8odJnKfXf0pFAkCoaH')
        self.database = os.getenv('GOOGLE_CLOUD_SQL_DATABASE_NAME', 'defi_analytics')
        self.connection_string = f'postgresql://{self.user}:{self.password}@localhost:5432/{self.database}'
        
        # Collection settings
        self.batch_size = 100  # blocks per batch
        self.max_concurrent_requests = 10
        self.rate_limit_delay = 0.1  # seconds between requests
        
    async def make_request(self, method, params=None):
        """Make request to QuickNode API"""
        try:
            # Create SSL context that doesn't verify certificates
            import ssl
            ssl_context = ssl.create_default_context()
            ssl_context.check_hostname = False
            ssl_context.verify_mode = ssl.CERT_NONE
            
            connector = aiohttp.TCPConnector(ssl=ssl_context)
            
            async with aiohttp.ClientSession(connector=connector) as session:
                payload = {
                    "jsonrpc": "2.0",
                    "method": method,
                    "params": params or [],
                    "id": 1
                }
                
                async with session.post(self.base_url, json=payload) as response:
                    if response.status == 200:
                        return await response.json()
                    else:
                        print(f"❌ API request failed: {response.status}")
                        return None
        except Exception as e:
            print(f"❌ Request error: {e}")
            return None

    async def connect_database(self):
        """Connect to PostgreSQL database"""
        try:
            self.conn = await asyncpg.connect(self.connection_string)
            print("✅ Connected to PostgreSQL database")
            return True
        except Exception as e:
            print(f"❌ Database connection failed: {e}")
            return False

    async def get_latest_block(self):
        """Get latest block number from network"""
        result = await self.make_request('eth_blockNumber')
        if result and 'result' in result:
            block_number = int(result['result'], 16)
            return block_number
        return None

    def calculate_24h_ago_block(self, latest_block):
        """Calculate approximate block number from 24 hours ago"""
        # Polygon produces ~2 blocks per second
        # 24 hours = 24 * 60 * 60 = 86,400 seconds
        # 86,400 * 2 = 172,800 blocks
        blocks_per_24h = 172_800
        twenty_four_hours_ago_block = max(0, latest_block - blocks_per_24h)
        return twenty_four_hours_ago_block

    def hex_to_int(self, hex_value):
        """Convert hex string to integer"""
        if isinstance(hex_value, str) and hex_value.startswith('0x'):
            return int(hex_value, 16)
        return hex_value

    def hex_to_str(self, hex_value):
        """Convert hex string to regular string"""
        if isinstance(hex_value, str) and hex_value.startswith('0x'):
            return hex_value
        return str(hex_value) if hex_value else None

    async def get_block_data(self, block_number):
        """Get block data by number"""
        hex_block = hex(block_number)
        result = await self.make_request('eth_getBlockByNumber', [hex_block, True])
        return result.get('result') if result else None

    async def get_transaction_receipt(self, tx_hash):
        """Get transaction receipt"""
        result = await self.make_request('eth_getTransactionReceipt', [tx_hash])
        return result.get('result') if result else None

    async def import_block_to_db(self, block_data):
        """Import block data to PostgreSQL"""
        try:
            # Convert hex values
            block_number = self.hex_to_int(block_data['number'])
            timestamp = self.hex_to_int(block_data['timestamp'])
            gas_limit = self.hex_to_int(block_data['gasLimit'])
            gas_used = self.hex_to_int(block_data['gasUsed'])
            
            await self.conn.execute("""
                INSERT INTO polygon_data.blocks (
                    block_number, block_hash, parent_hash, timestamp,
                    gas_limit, gas_used, miner, difficulty, total_difficulty,
                    size, extra_data, nonce, base_fee_per_gas, transactions_count,
                    logs_bloom, state_root, receipts_root, transactions_root,
                    uncle_hash, mix_hash
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
                ON CONFLICT (block_number) DO UPDATE SET
                    gas_used = EXCLUDED.gas_used,
                    transactions_count = EXCLUDED.transactions_count
            """, 
                block_number,
                block_data['hash'],
                block_data['parentHash'],
                timestamp,
                gas_limit,
                gas_used,
                block_data['miner'],
                self.hex_to_str(block_data.get('difficulty')),
                self.hex_to_str(block_data.get('totalDifficulty')),
                self.hex_to_int(block_data.get('size')),
                block_data.get('extraData'),
                block_data.get('nonce'),
                self.hex_to_str(block_data.get('baseFeePerGas')),
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
            print(f"❌ Error importing block {block_data.get('number', 'unknown')}: {e}")
            return False

    async def import_transaction_to_db(self, tx_data, receipt_data=None):
        """Import transaction data to PostgreSQL"""
        try:
            # Convert hex values
            block_number = self.hex_to_int(tx_data['blockNumber'])
            gas = self.hex_to_int(tx_data['gas'])
            nonce = self.hex_to_int(tx_data['nonce'])
            transaction_index = self.hex_to_int(tx_data['transactionIndex'])
            timestamp = self.hex_to_int(tx_data.get('timestamp', 0))
            
            # Insert transaction
            await self.conn.execute("""
                INSERT INTO polygon_data.transactions (
                    hash, block_number, block_hash, from_address, to_address,
                    value, gas, gas_price, nonce, input_data, transaction_index,
                    timestamp, max_fee_per_gas, max_priority_fee_per_gas, type, chain_id
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
                ON CONFLICT (hash) DO NOTHING
            """, 
                tx_data['hash'],
                block_number,
                tx_data['blockHash'],
                tx_data['from'],
                tx_data.get('to'),
                str(self.hex_to_int(tx_data['value'])),
                gas,
                str(self.hex_to_int(tx_data['gasPrice'])),
                nonce,
                tx_data.get('input'),
                transaction_index,
                timestamp,
                str(self.hex_to_int(tx_data.get('maxFeePerGas', 0))),
                str(self.hex_to_int(tx_data.get('maxPriorityFeePerGas', 0))),
                str(self.hex_to_int(tx_data.get('type', 0))),
                str(self.hex_to_int(tx_data.get('chainId', 137)))
            )
            
            # Insert receipt if available
            if receipt_data:
                await self.conn.execute("""
                    INSERT INTO polygon_data.receipts (
                        transaction_hash, block_number, block_hash, transaction_index,
                        from_address, to_address, cumulative_gas_used, gas_used,
                        contract_address, logs, status, effective_gas_price
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
                    ON CONFLICT (transaction_hash) DO UPDATE SET
                        gas_used = EXCLUDED.gas_used,
                        status = EXCLUDED.status
                """, 
                    receipt_data['transactionHash'],
                    self.hex_to_int(receipt_data['blockNumber']),
                    receipt_data['blockHash'],
                    self.hex_to_int(receipt_data['transactionIndex']),
                    receipt_data['from'],
                    receipt_data.get('to'),
                    self.hex_to_int(receipt_data['cumulativeGasUsed']),
                    self.hex_to_int(receipt_data['gasUsed']),
                    receipt_data.get('contractAddress'),
                    json.dumps(receipt_data.get('logs', [])),
                    self.hex_to_int(receipt_data.get('status', 1)),
                    str(self.hex_to_int(receipt_data.get('effectiveGasPrice', 0)))
                )
            
            return True
            
        except Exception as e:
            print(f"❌ Error importing transaction {tx_data.get('hash', 'unknown')}: {e}")
            return False

    async def process_block_batch(self, block_numbers):
        """Process a batch of blocks"""
        results = []
        
        for block_number in block_numbers:
            try:
                # Get block data
                block_data = await self.get_block_data(block_number)
                if not block_data:
                    print(f"❌ Failed to get block {block_number}")
                    results.append((0, 0))
                    continue
                
                # Import block
                block_success = await self.import_block_to_db(block_data)
                if not block_success:
                    results.append((0, 0))
                    continue
                
                # Process transactions
                transactions = block_data.get('transactions', [])
                transaction_count = 0
                receipt_count = 0
                
                for tx in transactions:
                    try:
                        # Get receipt
                        receipt = await self.get_transaction_receipt(tx['hash'])
                        
                        # Import transaction and receipt
                        tx_success = await self.import_transaction_to_db(tx, receipt)
                        if tx_success:
                            transaction_count += 1
                            if receipt:
                                receipt_count += 1
                        
                        # Rate limiting
                        await asyncio.sleep(self.rate_limit_delay)
                        
                    except Exception as e:
                        print(f"❌ Error processing transaction in block {block_number}: {e}")
                        continue
                
                results.append((transaction_count, receipt_count))
                print(f"✅ Block {block_number}: {transaction_count} transactions, {receipt_count} receipts")
                
            except Exception as e:
                print(f"❌ Error processing block {block_number}: {e}")
                results.append((0, 0))
        
        # Count results
        total_txs = sum(r[0] for r in results if isinstance(r, tuple))
        total_receipts = sum(r[1] for r in results if isinstance(r, tuple))
        
        return total_txs, total_receipts

    async def collect_24h_data(self):
        """Collect data for the last 24 hours"""
        print("🚀 Starting Polygon 24 Hours Data Collection")
        print("=" * 60)
        
        # Connect to database
        if not await self.connect_database():
            return
        
        try:
            # Get latest block
            latest_block = await self.get_latest_block()
            if not latest_block:
                print("❌ Could not get latest block")
                return
            
            # Calculate 24 hours ago block
            twenty_four_hours_ago_block = self.calculate_24h_ago_block(latest_block)
            total_blocks = latest_block - twenty_four_hours_ago_block
            
            print(f"\n📊 Collection Plan:")
            print(f"  Latest block: {latest_block:,}")
            print(f"  24 hours ago block: {twenty_four_hours_ago_block:,}")
            print(f"  Total blocks to collect: {total_blocks:,}")
            print(f"  Batch size: {self.batch_size}")
            print(f"  Estimated batches: {total_blocks // self.batch_size + 1}")
            print(f"  Estimated time: 5-10 minutes")
            
            # Start collection
            start_time = time.time()
            total_blocks_processed = 0
            total_transactions = 0
            total_receipts = 0
            
            # Process blocks in batches
            for batch_start in range(twenty_four_hours_ago_block, latest_block, self.batch_size):
                batch_end = min(batch_start + self.batch_size, latest_block)
                batch_blocks = list(range(batch_start, batch_end))
                
                print(f"\n📦 Processing batch: {batch_start:,} - {batch_end:,}")
                
                # Process batch
                txs, receipts = await self.process_block_batch(batch_blocks)
                
                total_blocks_processed += len(batch_blocks)
                total_transactions += txs
                total_receipts += receipts
                
                # Progress update
                elapsed_time = time.time() - start_time
                blocks_per_second = total_blocks_processed / elapsed_time
                estimated_remaining = (total_blocks - total_blocks_processed) / blocks_per_second
                
                print(f"✅ Batch completed: {len(batch_blocks)} blocks, {txs} transactions, {receipts} receipts")
                print(f"📈 Progress: {total_blocks_processed:,}/{total_blocks:,} ({total_blocks_processed/total_blocks*100:.1f}%)")
                print(f"⏱️ Speed: {blocks_per_second:.1f} blocks/sec, ETA: {estimated_remaining/60:.1f} minutes")
                
                # Small delay between batches
                await asyncio.sleep(0.5)
            
            # Final statistics
            elapsed_time = time.time() - start_time
            print(f"\n🎉 Collection completed!")
            print(f"📊 Final Statistics:")
            print(f"  Total blocks processed: {total_blocks_processed:,}")
            print(f"  Total transactions: {total_transactions:,}")
            print(f"  Total receipts: {total_receipts:,}")
            print(f"  Total time: {elapsed_time/60:.1f} minutes")
            print(f"  Average speed: {total_blocks_processed/elapsed_time:.1f} blocks/sec")
            
            # Get database statistics
            await self.get_database_stats()
            
        except Exception as e:
            print(f"❌ Collection failed: {e}")
        
        finally:
            await self.conn.close()
            print("✅ Database connection closed")

    async def get_database_stats(self):
        """Get database statistics"""
        print("\n📊 Database Statistics:")
        
        # Count records
        blocks_count = await self.conn.fetchval("SELECT COUNT(*) FROM polygon_data.blocks")
        transactions_count = await self.conn.fetchval("SELECT COUNT(*) FROM polygon_data.transactions")
        receipts_count = await self.conn.fetchval("SELECT COUNT(*) FROM polygon_data.receipts")
        
        print(f"  Blocks: {blocks_count:,}")
        print(f"  Transactions: {transactions_count:,}")
        print(f"  Receipts: {receipts_count:,}")
        
        # Get block range
        if blocks_count > 0:
            min_block = await self.conn.fetchval("SELECT MIN(block_number) FROM polygon_data.blocks")
            max_block = await self.conn.fetchval("SELECT MAX(block_number) FROM polygon_data.blocks")
            print(f"  Block range: {min_block:,} - {max_block:,}")
        
        # Get time range
        if blocks_count > 0:
            min_time = await self.conn.fetchval("SELECT MIN(timestamp) FROM polygon_data.blocks")
            max_time = await self.conn.fetchval("SELECT MAX(timestamp) FROM polygon_data.blocks")
            if min_time and max_time:
                min_date = datetime.fromtimestamp(min_time).strftime('%Y-%m-%d %H:%M:%S')
                max_date = datetime.fromtimestamp(max_time).strftime('%Y-%m-%d %H:%M:%S')
                print(f"  Time range: {min_date} - {max_date}")
        
        # Get success rate
        if receipts_count > 0:
            success_count = await self.conn.fetchval("SELECT COUNT(*) FROM polygon_data.receipts WHERE status = 1")
            success_rate = (success_count / receipts_count) * 100
            print(f"  Success rate: {success_rate:.1f}%")

async def main():
    """Main function"""
    collector = Polygon24hDataCollector()
    await collector.collect_24h_data()

if __name__ == "__main__":
    asyncio.run(main())
