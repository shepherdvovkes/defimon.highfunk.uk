#!/usr/bin/env python3
"""
Continuous data synchronization with QuickNode
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

async def get_current_block():
    """Get current block from QuickNode"""
    try:
        endpoint_name = os.getenv('QUICKNODE_ENDPOINT_NAME', 'hidden-holy-seed')
        token_id = os.getenv('QUICKNODE_TOKEN_ID', '97d6d8e7659b49b126c43455edc4607949bfb52b')
        
        config = PolygonQuickNodeConfig(endpoint_name, token_id)
        collector = PolygonBlockCollector(config, "polygon_mainnet")
        
        await collector.initialize()
        current_block = await collector.get_current_block_number()
        await collector.cleanup()
        
        return current_block
    except Exception as e:
        print(f"❌ Error getting current block: {e}")
        return None

async def get_latest_collected_block():
    """Get the latest block from collected data files"""
    import json
    import glob
    
    try:
        # Find all data files
        data_files = glob.glob("polygon_data_*.json")
        if not data_files:
            return None
        
        # Get the most recent file
        latest_file = max(data_files, key=os.path.getmtime)
        
        with open(latest_file, 'r') as f:
            data = json.load(f)
        
        if data.get('blocks'):
            return max([b['block_number'] for b in data['blocks']])
        return None
    except Exception as e:
        print(f"❌ Error getting latest collected block: {e}")
        return None

async def sync_missing_data():
    """Sync missing data from the latest collected block to current"""
    print("🔄 Syncing missing data...")
    
    # Get current network block
    current_block = await get_current_block()
    if not current_block:
        print("❌ Could not get current block")
        return
    
    # Get latest collected block
    latest_collected = await get_latest_collected_block()
    if not latest_collected:
        print("❌ Could not get latest collected block")
        return
    
    print(f"📊 Current network block: {current_block}")
    print(f"📊 Latest collected block: {latest_collected}")
    
    blocks_behind = current_block - latest_collected
    print(f"📊 Blocks behind: {blocks_behind}")
    
    if blocks_behind <= 0:
        print("✅ Data is up to date!")
        return
    
    # Calculate how many blocks to collect (limit to 1000 to avoid rate limits)
    blocks_to_collect = min(blocks_behind, 1000)
    start_block = latest_collected + 1
    end_block = start_block + blocks_to_collect - 1
    
    print(f"🔄 Collecting blocks {start_block} to {end_block} ({blocks_to_collect} blocks)")
    
    try:
        # Get credentials
        endpoint_name = os.getenv('QUICKNODE_ENDPOINT_NAME', 'hidden-holy-seed')
        token_id = os.getenv('QUICKNODE_TOKEN_ID', '97d6d8e7659b49b126c43455edc4607949bfb52b')
        
        # Initialize collector
        config = PolygonQuickNodeConfig(endpoint_name, token_id)
        collector = PolygonBlockCollector(config, "polygon_mainnet")
        
        await collector.initialize()
        
        # Collect blocks
        data = await collector.collect_block_range(start_block, end_block)
        
        # Save to file
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"polygon_sync_{start_block}_{end_block}_{timestamp}.json"
        
        collector.save_to_file(data, filename)
        
        print(f"\n✅ Sync completed!")
        print(f"📊 Results:")
        print(f"  Blocks collected: {data['total_blocks']}")
        print(f"  Transactions: {data['total_transactions']}")
        print(f"  Receipts: {data['total_receipts']}")
        print(f"  Errors: {len(data['errors'])}")
        print(f"📁 Data saved to: {filename}")
        
        await collector.cleanup()
        
    except Exception as e:
        print(f"❌ Sync failed: {e}")

async def continuous_sync(interval_seconds=60):
    """Continuously sync data"""
    print(f"🔄 Starting continuous sync (interval: {interval_seconds}s)")
    
    while True:
        try:
            await sync_missing_data()
            print(f"⏳ Waiting {interval_seconds} seconds before next sync...")
            await asyncio.sleep(interval_seconds)
        except KeyboardInterrupt:
            print("\n⏹️ Continuous sync stopped by user")
            break
        except Exception as e:
            print(f"❌ Error in continuous sync: {e}")
            await asyncio.sleep(interval_seconds)

async def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Polygon Data Synchronization")
    parser.add_argument("--mode", choices=["once", "continuous"], default="once", 
                       help="Sync mode")
    parser.add_argument("--interval", type=int, default=60, 
                       help="Interval in seconds (continuous mode)")
    
    args = parser.parse_args()
    
    if args.mode == "once":
        await sync_missing_data()
    elif args.mode == "continuous":
        await continuous_sync(args.interval)

if __name__ == "__main__":
    asyncio.run(main())
