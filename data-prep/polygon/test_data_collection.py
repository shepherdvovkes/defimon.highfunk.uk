#!/usr/bin/env python3
"""
Test script to collect a small sample of Polygon data
"""

import os
import asyncio
import aiohttp
import asyncpg
import json
from datetime import datetime
from dotenv import load_dotenv
import time

# Load environment variables
load_dotenv()

class PolygonTestDataCollector:
    def __init__(self):
        self.endpoint_name = os.getenv('QUICKNODE_ENDPOINT_NAME', 'hidden-holy-seed')
        self.token_id = os.getenv('QUICKNODE_TOKEN_ID', '97d6d8e7659b49b126c43455edc4607949bfb52b')
        self.base_url = f"https://{self.endpoint_name}.matic.quiknode.pro/{self.token_id}/"
        
        # Database connection
        self.user = os.getenv('GOOGLE_CLOUD_SQL_USER', 'defimon_user')
        self.password = os.getenv('GOOGLE_CLOUD_SQL_PASSWORD', 'Zd8odJnKfXf0pFAkCoaH')
        self.database = os.getenv('GOOGLE_CLOUD_SQL_DATABASE_NAME', 'defi_analytics')
        self.connection_string = f'postgresql://{self.user}:{self.password}@localhost:5432/{self.database}'
        
    async def make_request(self, method, params=None):
        """Make request to QuickNode API"""
        headers = {
            'Content-Type': 'application/json',
        }
        
        payload = {
            'jsonrpc': '2.0',
            'id': 1,
            'method': method,
            'params': params or []
        }
        
        try:
            async with aiohttp.ClientSession(connector=aiohttp.TCPConnector(ssl=False)) as session:
                async with session.post(self.base_url, json=payload, headers=headers) as response:
                    if response.status == 200:
                        return await response.json()
                    else:
                        print(f"❌ HTTP {response.status}: {await response.text()}")
                        return None
        except Exception as e:
            print(f"❌ Request failed: {e}")
            return None

    async def connect_database(self):
        """Connect to PostgreSQL"""
        try:
            self.conn = await asyncpg.connect(self.connection_string)
            print("✅ Connected to PostgreSQL successfully")
            return True
        except Exception as e:
            print(f"❌ Failed to connect to PostgreSQL: {e}")
            return False

    async def get_latest_block(self):
        """Get latest block number"""
        print("🔍 Getting latest block number...")
        result = await self.make_request('eth_blockNumber')
        if result and 'result' in result:
            block_number = int(result['result'], 16)
            print(f"✅ Latest block: {block_number:,}")
            return block_number
        return None

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
                tx_data['value'],
                gas,
                tx_data['gasPrice'],
                nonce,
                tx_data.get('input'),
                transaction_index,
                timestamp,
                self.hex_to_str(tx_data.get('maxFeePerGas')),
                self.hex_to_str(tx_data.get('maxPriorityFeePerGas')),
                self.hex_to_str(tx_data.get('type')),
                self.hex_to_str(tx_data.get('chainId'))
            )
            
            # Insert receipt if available
            if receipt_data:
                gas_used = self.hex_to_int(receipt_data['gasUsed'])
                cumulative_gas_used = self.hex_to_int(receipt_data['cumulativeGasUsed'])
                status = self.hex_to_int(receipt_data.get('status', 0))
                
                await self.conn.execute("""
                    INSERT INTO polygon_data.receipts (
                        transaction_hash, block_number, block_hash, transaction_index,
                        from_address, to_address, cumulative_gas_used, gas_used,
                        contract_address, logs, status, effective_gas_price
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
                    ON CONFLICT (transaction_hash) DO NOTHING
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
                    self.hex_to_str(receipt_data.get('effectiveGasPrice'))
                )
            
            return True
            
        except Exception as e:
            print(f"❌ Error importing transaction {tx_data.get('hash', 'unknown')[:10]}...: {e}")
            return False

    async def test_data_collection(self, start_block, end_block, max_transactions_per_block=10):
        """Test data collection on a small range"""
        print(f"🧪 Testing data collection from block {start_block:,} to {end_block:,}")
        
        # Connect to database
        if not await self.connect_database():
            return
        
        try:
            start_time = time.time()
            total_blocks = 0
            total_transactions = 0
            total_receipts = 0
            
            # Process blocks
            for block_number in range(start_block, end_block + 1):
                print(f"📦 Processing block {block_number:,}...")
                
                # Get block data
                block_data = await self.get_block_data(block_number)
                if not block_data:
                    print(f"❌ Could not get block {block_number}")
                    continue
                
                # Import block
                block_success = await self.import_block_to_db(block_data)
                if block_success:
                    total_blocks += 1
                
                # Process transactions (limited)
                transactions = block_data.get('transactions', [])[:max_transactions_per_block]
                tx_count = 0
                receipt_count = 0
                
                for tx in transactions:
                    # Get receipt
                    receipt = await self.get_transaction_receipt(tx['hash'])
                    
                    # Import transaction and receipt
                    tx_success = await self.import_transaction_to_db(tx, receipt)
                    if tx_success:
                        tx_count += 1
                        if receipt:
                            receipt_count += 1
                    
                    # Small delay
                    await asyncio.sleep(0.1)
                
                total_transactions += tx_count
                total_receipts += receipt_count
                
                print(f"✅ Block {block_number:,}: {tx_count} transactions, {receipt_count} receipts")
            
            # Final statistics
            elapsed_time = time.time() - start_time
            print(f"\n🎉 Test collection completed!")
            print(f"📊 Results:")
            print(f"  Blocks processed: {total_blocks}")
            print(f"  Transactions: {total_transactions}")
            print(f"  Receipts: {total_receipts}")
            print(f"  Time: {elapsed_time:.1f} seconds")
            print(f"  Speed: {total_blocks/elapsed_time:.2f} blocks/sec")
            
            # Get database statistics
            await self.get_database_stats()
            
        except Exception as e:
            print(f"❌ Test failed: {e}")
        
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
        
        print(f"  Total blocks: {blocks_count:,}")
        print(f"  Total transactions: {transactions_count:,}")
        print(f"  Total receipts: {receipts_count:,}")
        
        # Get block range
        if blocks_count > 0:
            min_block = await self.conn.fetchval("SELECT MIN(block_number) FROM polygon_data.blocks")
            max_block = await self.conn.fetchval("SELECT MAX(block_number) FROM polygon_data.blocks")
            print(f"  Block range: {min_block:,} - {max_block:,}")

async def main():
    """Main function"""
    print("🧪 Polygon Data Collection Test")
    print("=" * 40)
    
    # Get latest block
    collector = PolygonTestDataCollector()
    latest_block = await collector.get_latest_block()
    
    if not latest_block:
        print("❌ Could not get latest block")
        return
    
    # Test with last 10 blocks
    start_block = latest_block - 9
    end_block = latest_block
    
    print(f"\n📊 Test Configuration:")
    print(f"  Start block: {start_block:,}")
    print(f"  End block: {end_block:,}")
    print(f"  Max transactions per block: 10")
    
    # Confirm test
    response = input("\n🤔 Run test collection? (y/N): ")
    if response.lower() != 'y':
        print("❌ Test cancelled")
        return
    
    # Run test
    await collector.test_data_collection(start_block, end_block, max_transactions_per_block=10)

if __name__ == "__main__":
    asyncio.run(main())
