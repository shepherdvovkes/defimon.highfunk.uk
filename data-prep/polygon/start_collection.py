#!/usr/bin/env python3
"""
Start Polygon Data Collection
"""

import asyncio
import os
import sys
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Add current directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from config.quicknode_config import PolygonQuickNodeConfig
from collectors.block_collector import PolygonBlockCollector

async def collect_recent_blocks(num_blocks=10):
    """Collect recent blocks and save to file"""
    print(f"🚀 Starting Polygon Data Collection")
    print(f"📦 Collecting {num_blocks} recent blocks...")
    
    # Get credentials
    endpoint_name = os.getenv('QUICKNODE_ENDPOINT_NAME', 'hidden-holy-seed')
    token_id = os.getenv('QUICKNODE_TOKEN_ID', '97d6d8e7659b49b126c43455edc4607949bfb52b')
    
    print(f"📡 Endpoint: {endpoint_name}")
    print(f"🔑 Token: {token_id[:10]}...")
    
    try:
        # Initialize collector
        config = PolygonQuickNodeConfig(endpoint_name, token_id)
        collector = PolygonBlockCollector(config, "polygon_mainnet")
        
        await collector.initialize()
        
        # Get current block
        current_block = await collector.get_current_block_number()
        print(f"📊 Current block: {current_block}")
        
        # Calculate start block
        start_block = max(0, current_block - num_blocks + 1)
        print(f"📊 Collecting blocks from {start_block} to {current_block}")
        
        # Collect blocks
        data = await collector.collect_block_range(start_block, current_block)
        
        # Save to file
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"polygon_data_{start_block}_{current_block}_{timestamp}.json"
        
        collector.save_to_file(data, filename)
        
        print(f"\n✅ Collection completed!")
        print(f"📊 Results:")
        print(f"  Blocks collected: {data['total_blocks']}")
        print(f"  Transactions: {data['total_transactions']}")
        print(f"  Receipts: {data['total_receipts']}")
        print(f"  Errors: {len(data['errors'])}")
        print(f"📁 Data saved to: {filename}")
        
        # Show some sample data
        if data['blocks']:
            print(f"\n📋 Sample Block Data:")
            sample_block = data['blocks'][0]
            print(f"  Block {sample_block['block_number']}:")
            print(f"    Hash: {sample_block['block_hash'][:20]}...")
            print(f"    Timestamp: {datetime.fromtimestamp(sample_block['timestamp'])}")
            print(f"    Transactions: {sample_block['transactions_count']}")
            print(f"    Gas used: {sample_block['gas_used']}")
        
        if data['transactions']:
            print(f"\n📋 Sample Transaction Data:")
            sample_tx = data['transactions'][0]
            print(f"  Transaction {sample_tx['hash'][:20]}...:")
            print(f"    From: {sample_tx['from_address']}")
            print(f"    To: {sample_tx['to_address']}")
            print(f"    Value: {sample_tx['value']}")
            print(f"    Gas: {sample_tx['gas']}")
        
        await collector.cleanup()
        return data
        
    except Exception as e:
        print(f"❌ Collection failed: {e}")
        return None

async def collect_continuous(interval_seconds=60):
    """Collect data continuously"""
    print(f"🔄 Starting continuous collection (interval: {interval_seconds}s)")
    
    # Get credentials
    endpoint_name = os.getenv('QUICKNODE_ENDPOINT_NAME', 'hidden-holy-seed')
    token_id = os.getenv('QUICKNODE_TOKEN_ID', '97d6d8e7659b49b126c43455edc4607949bfb52b')
    
    try:
        # Initialize collector
        config = PolygonQuickNodeConfig(endpoint_name, token_id)
        collector = PolygonBlockCollector(config, "polygon_mainnet")
        
        await collector.initialize()
        
        last_block = None
        
        while True:
            try:
                current_block = await collector.get_current_block_number()
                
                if last_block is None:
                    print(f"📊 Starting from block {current_block}")
                    last_block = current_block - 1
                
                if current_block > last_block:
                    new_blocks = current_block - last_block
                    print(f"🆕 Found {new_blocks} new blocks (current: {current_block})")
                    
                    # Collect new blocks
                    data = await collector.collect_block_range(last_block + 1, current_block)
                    
                    # Save to file
                    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                    filename = f"polygon_continuous_{last_block+1}_{current_block}_{timestamp}.json"
                    collector.save_to_file(data, filename)
                    
                    print(f"✅ Collected {data['total_blocks']} blocks, {data['total_transactions']} transactions")
                    print(f"📁 Saved to: {filename}")
                    
                    last_block = current_block
                else:
                    print(f"⏳ No new blocks (current: {current_block})")
                
                # Wait for next interval
                await asyncio.sleep(interval_seconds)
                
            except KeyboardInterrupt:
                print("\n⏹️ Continuous collection stopped by user")
                break
            except Exception as e:
                print(f"❌ Error in continuous collection: {e}")
                await asyncio.sleep(interval_seconds)
        
        await collector.cleanup()
        
    except Exception as e:
        print(f"❌ Continuous collection failed: {e}")

async def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Polygon Data Collection")
    parser.add_argument("--mode", choices=["recent", "continuous"], default="recent", 
                       help="Collection mode")
    parser.add_argument("--blocks", type=int, default=10, 
                       help="Number of blocks to collect (recent mode)")
    parser.add_argument("--interval", type=int, default=60, 
                       help="Interval in seconds (continuous mode)")
    
    args = parser.parse_args()
    
    if args.mode == "recent":
        await collect_recent_blocks(args.blocks)
    elif args.mode == "continuous":
        await collect_continuous(args.interval)

if __name__ == "__main__":
    asyncio.run(main())
