#!/usr/bin/env python3
"""
Explore QuickNode API data for the last month
"""

import os
import asyncio
import aiohttp
import json
from datetime import datetime, timedelta
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class QuickNodeDataExplorer:
    def __init__(self):
        self.endpoint_name = os.getenv('QUICKNODE_ENDPOINT_NAME', 'hidden-holy-seed')
        self.token_id = os.getenv('QUICKNODE_TOKEN_ID', '97d6d8e7659b49b126c43455edc4607949bfb52b')
        self.base_url = f"https://{self.endpoint_name}.matic.quiknode.pro/{self.token_id}/"
        
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

    async def get_latest_block(self):
        """Get latest block number"""
        print("🔍 Getting latest block number...")
        result = await self.make_request('eth_blockNumber')
        if result and 'result' in result:
            block_number = int(result['result'], 16)
            print(f"✅ Latest block: {block_number}")
            return block_number
        return None

    async def get_block_by_number(self, block_number):
        """Get block by number"""
        hex_block = hex(block_number)
        result = await self.make_request('eth_getBlockByNumber', [hex_block, True])
        return result.get('result') if result else None

    async def get_block_by_timestamp(self, timestamp):
        """Get block by timestamp (approximate)"""
        # This is approximate - we'll use a simple calculation
        # Polygon produces ~2 blocks per second
        blocks_per_second = 2
        current_time = datetime.now()
        target_time = datetime.fromtimestamp(timestamp)
        time_diff = (current_time - target_time).total_seconds()
        approximate_blocks = int(time_diff * blocks_per_second)
        
        latest_block = await self.get_latest_block()
        if latest_block:
            target_block = max(0, latest_block - approximate_blocks)
            return await self.get_block_by_number(target_block)
        return None

    async def get_transaction_receipt(self, tx_hash):
        """Get transaction receipt"""
        result = await self.make_request('eth_getTransactionReceipt', [tx_hash])
        return result.get('result') if result else None

    async def get_logs(self, from_block, to_block, address=None, topics=None):
        """Get logs for a range of blocks"""
        params = {
            'fromBlock': hex(from_block),
            'toBlock': hex(to_block)
        }
        if address:
            params['address'] = address
        if topics:
            params['topics'] = topics
            
        result = await self.make_request('eth_getLogs', [params])
        return result.get('result') if result else None

    async def get_gas_price(self):
        """Get current gas price"""
        result = await self.make_request('eth_gasPrice')
        if result and 'result' in result:
            return int(result['result'], 16)
        return None

    async def get_network_stats(self):
        """Get network statistics"""
        print("📊 Getting network statistics...")
        
        latest_block = await self.get_latest_block()
        if not latest_block:
            return None
            
        # Calculate one month ago (30 days)
        one_month_ago = datetime.now() - timedelta(days=30)
        one_month_ago_timestamp = int(one_month_ago.timestamp())
        
        # Get approximate block from one month ago
        month_ago_block = await self.get_block_by_timestamp(one_month_ago_timestamp)
        
        month_ago_block_number = None
        if month_ago_block and 'number' in month_ago_block:
            month_ago_block_number = int(month_ago_block['number'], 16) if isinstance(month_ago_block['number'], str) else month_ago_block['number']
        
        stats = {
            'latest_block': latest_block,
            'month_ago_timestamp': one_month_ago_timestamp,
            'month_ago_block': month_ago_block_number,
            'blocks_in_month': latest_block - (month_ago_block_number if month_ago_block_number else latest_block),
            'current_gas_price': await self.get_gas_price(),
            'month_ago_block_data': month_ago_block
        }
        
        return stats

    async def get_sample_blocks(self, start_block, end_block, sample_size=10):
        """Get sample blocks from a range"""
        print(f"📦 Getting {sample_size} sample blocks from {start_block} to {end_block}...")
        
        blocks = []
        step = max(1, (end_block - start_block) // sample_size)
        
        for i in range(sample_size):
            block_number = start_block + (i * step)
            block = await self.get_block_by_number(block_number)
            if block:
                blocks.append(block)
                print(f"✅ Block {block_number}: {len(block.get('transactions', []))} transactions")
        
        return blocks

    async def get_sample_transactions(self, blocks, max_txs_per_block=5):
        """Get sample transactions from blocks"""
        print(f"💸 Getting sample transactions (max {max_txs_per_block} per block)...")
        
        transactions = []
        receipts = []
        
        for block in blocks:
            block_txs = block.get('transactions', [])[:max_txs_per_block]
            for tx in block_txs:
                transactions.append(tx)
                
                # Get receipt
                receipt = await self.get_transaction_receipt(tx['hash'])
                if receipt:
                    receipts.append(receipt)
                    print(f"✅ TX {tx['hash'][:10]}...: {receipt.get('status', 'unknown')} status")
        
        return transactions, receipts

    async def explore_data(self):
        """Main exploration function"""
        print("🚀 QuickNode Data Explorer - Last Month Analysis")
        print("=" * 60)
        
        # Get network stats
        stats = await self.get_network_stats()
        if not stats:
            print("❌ Could not get network statistics")
            return None
            
        print(f"\n📊 Network Statistics:")
        print(f"  Latest Block: {stats['latest_block']}")
        print(f"  Month Ago Block: {stats['month_ago_block']}")
        print(f"  Blocks in Month: {stats['blocks_in_month']}")
        print(f"  Current Gas Price: {stats['current_gas_price']} wei")
        
        # Get sample blocks from the last month
        if stats['month_ago_block']:
            start_block = stats['month_ago_block']
            end_block = stats['latest_block']
            
            sample_blocks = await self.get_sample_blocks(start_block, end_block, 5)
            
            if sample_blocks:
                # Get sample transactions
                transactions, receipts = await self.get_sample_transactions(sample_blocks, 3)
                
                # Analyze data
                analysis = {
                    'stats': stats,
                    'sample_blocks': sample_blocks,
                    'sample_transactions': transactions,
                    'sample_receipts': receipts,
                    'exploration_date': datetime.now().isoformat()
                }
                
                # Save analysis
                with open('quicknode_data_analysis.json', 'w') as f:
                    json.dump(analysis, f, indent=2, default=str)
                
                print(f"\n💾 Analysis saved to quicknode_data_analysis.json")
                print(f"📊 Summary:")
                print(f"  Sample Blocks: {len(sample_blocks)}")
                print(f"  Sample Transactions: {len(transactions)}")
                print(f"  Sample Receipts: {len(receipts)}")
                
                return analysis
        
        return None

async def main():
    """Main function"""
    explorer = QuickNodeDataExplorer()
    analysis = await explorer.explore_data()
    
    if analysis:
        print("\n🎉 Data exploration completed!")
        print("📊 Next steps:")
        print("1. Check quicknode_data_analysis.json for detailed data")
        print("2. Run: python3 create_data_dashboard.py")
        print("3. View dashboard at: http://localhost:8000")
    else:
        print("\n❌ Data exploration failed")

if __name__ == "__main__":
    asyncio.run(main())
