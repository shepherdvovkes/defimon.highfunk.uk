#!/usr/bin/env python3
"""
Import QuickNode data from JSON to PostgreSQL
"""

import json
import os
import asyncio
import asyncpg
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class PostgresDataImporter:
    def __init__(self):
        self.user = os.getenv('GOOGLE_CLOUD_SQL_USER', 'defimon_user')
        self.password = os.getenv('GOOGLE_CLOUD_SQL_PASSWORD', 'Zd8odJnKfXf0pFAkCoaH')
        self.database = os.getenv('GOOGLE_CLOUD_SQL_DATABASE_NAME', 'defi_analytics')
        self.connection_string = f'postgresql://{self.user}:{self.password}@localhost:5432/{self.database}'
        
    async def connect(self):
        """Connect to PostgreSQL"""
        try:
            self.conn = await asyncpg.connect(self.connection_string)
            print("✅ Connected to PostgreSQL successfully")
            return True
        except Exception as e:
            print(f"❌ Failed to connect to PostgreSQL: {e}")
            return False
    
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
    
    async def import_blocks(self, blocks_data):
        """Import blocks data"""
        print(f"📦 Importing {len(blocks_data)} blocks...")
        
        for block in blocks_data:
            try:
                # Convert hex values
                block_number = self.hex_to_int(block['number'])
                timestamp = self.hex_to_int(block['timestamp'])
                gas_limit = self.hex_to_int(block['gasLimit'])
                gas_used = self.hex_to_int(block['gasUsed'])
                
                await self.conn.execute("""
                    INSERT INTO polygon_data.blocks (
                        block_number, block_hash, parent_hash, timestamp,
                        gas_limit, gas_used, miner, difficulty, total_difficulty,
                        size, extra_data, nonce, base_fee_per_gas, transactions_count,
                        logs_bloom, state_root, receipts_root, transactions_root,
                        uncle_hash, mix_hash
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
                    ON CONFLICT (block_number) DO NOTHING
                """, 
                    block_number,
                    block['hash'],
                    block['parentHash'],
                    timestamp,
                    gas_limit,
                    gas_used,
                    block['miner'],
                    self.hex_to_str(block.get('difficulty')),
                    self.hex_to_str(block.get('totalDifficulty')),
                    self.hex_to_int(block.get('size')),
                    block.get('extraData'),
                    block.get('nonce'),
                    self.hex_to_str(block.get('baseFeePerGas')),
                    len(block.get('transactions', [])),
                    block.get('logsBloom'),
                    block.get('stateRoot'),
                    block.get('receiptsRoot'),
                    block.get('transactionsRoot'),
                    block.get('sha3Uncles'),
                    block.get('mixHash')
                )
                
            except Exception as e:
                print(f"❌ Error importing block {block.get('number', 'unknown')}: {e}")
        
        print(f"✅ Imported {len(blocks_data)} blocks")
    
    async def import_transactions(self, transactions_data, receipts_data):
        """Import transactions and receipts data"""
        print(f"💸 Importing {len(transactions_data)} transactions...")
        
        # Create receipts lookup
        receipts_lookup = {r['transactionHash']: r for r in receipts_data}
        
        for tx in transactions_data:
            try:
                # Convert hex values
                block_number = self.hex_to_int(tx['blockNumber'])
                gas = self.hex_to_int(tx['gas'])
                nonce = self.hex_to_int(tx['nonce'])
                transaction_index = self.hex_to_int(tx['transactionIndex'])
                timestamp = self.hex_to_int(tx.get('timestamp', 0))
                
                # Insert transaction
                await self.conn.execute("""
                    INSERT INTO polygon_data.transactions (
                        hash, block_number, block_hash, from_address, to_address,
                        value, gas, gas_price, nonce, input_data, transaction_index,
                        timestamp, max_fee_per_gas, max_priority_fee_per_gas, type, chain_id
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
                    ON CONFLICT (hash) DO NOTHING
                """,
                    tx['hash'],
                    block_number,
                    tx['blockHash'],
                    tx['from'],
                    tx.get('to'),
                    tx['value'],
                    gas,
                    tx['gasPrice'],
                    nonce,
                    tx.get('input'),
                    transaction_index,
                    timestamp,
                    self.hex_to_str(tx.get('maxFeePerGas')),
                    self.hex_to_str(tx.get('maxPriorityFeePerGas')),
                    self.hex_to_str(tx.get('type')),
                    self.hex_to_str(tx.get('chainId'))
                )
                
                # Insert receipt if available
                receipt = receipts_lookup.get(tx['hash'])
                if receipt:
                    gas_used = self.hex_to_int(receipt['gasUsed'])
                    cumulative_gas_used = self.hex_to_int(receipt['cumulativeGasUsed'])
                    status = self.hex_to_int(receipt.get('status', 0))
                    
                    await self.conn.execute("""
                        INSERT INTO polygon_data.receipts (
                            transaction_hash, block_number, block_hash, transaction_index,
                            from_address, to_address, cumulative_gas_used, gas_used,
                            contract_address, logs, status, effective_gas_price
                        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
                        ON CONFLICT (transaction_hash) DO NOTHING
                    """,
                        receipt['transactionHash'],
                        block_number,
                        receipt['blockHash'],
                        self.hex_to_int(receipt['transactionIndex']),
                        receipt['from'],
                        receipt.get('to'),
                        cumulative_gas_used,
                        gas_used,
                        receipt.get('contractAddress'),
                        json.dumps(receipt.get('logs', [])),
                        status,
                        self.hex_to_str(receipt.get('effectiveGasPrice'))
                    )
                
            except Exception as e:
                print(f"❌ Error importing transaction {tx.get('hash', 'unknown')[:10]}...: {e}")
        
        print(f"✅ Imported {len(transactions_data)} transactions and {len(receipts_data)} receipts")
    
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
    
    async def close(self):
        """Close database connection"""
        if hasattr(self, 'conn'):
            await self.conn.close()
            print("✅ Database connection closed")

async def main():
    """Main function"""
    print("🚀 Importing QuickNode Data to PostgreSQL")
    print("=" * 50)
    
    # Load analysis data
    try:
        with open('quicknode_data_analysis.json', 'r') as f:
            data = json.load(f)
        print("✅ Loaded analysis data")
    except FileNotFoundError:
        print("❌ quicknode_data_analysis.json not found")
        print("Please run: python3 quicknode_data_explorer.py first")
        return
    
    # Initialize importer
    importer = PostgresDataImporter()
    
    # Connect to database
    if not await importer.connect():
        return
    
    try:
        # Import data
        if 'sample_blocks' in data:
            await importer.import_blocks(data['sample_blocks'])
        
        if 'sample_transactions' in data and 'sample_receipts' in data:
            await importer.import_transactions(data['sample_transactions'], data['sample_receipts'])
        
        # Get statistics
        await importer.get_database_stats()
        
        print("\n🎉 Data import completed successfully!")
        print("📊 You can now query the data using:")
        print("   psql -h localhost -U defimon_user -d defi_analytics")
        
    except Exception as e:
        print(f"❌ Import failed: {e}")
    
    finally:
        await importer.close()

if __name__ == "__main__":
    asyncio.run(main())
