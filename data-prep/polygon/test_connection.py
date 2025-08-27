#!/usr/bin/env python3
"""
Test script for Polygon data collection setup
"""

import asyncio
import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Add current directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from config.quicknode_config import PolygonQuickNodeConfig
from storage.database_manager import PolygonDatabaseManager

async def test_quicknode_connection():
    """Test QuickNode API connection"""
    print("🔗 Testing QuickNode Connection...")
    
    # Get credentials from environment
    endpoint_name = os.getenv('QUICKNODE_ENDPOINT_NAME', 'defimon-polygon')
    token_id = os.getenv('QUICKNODE_API_KEY')
    
    if not token_id:
        print("❌ QUICKNODE_API_KEY not found in environment")
        return False
    
    print(f"📡 Endpoint: {endpoint_name}")
    print(f"🔑 Token ID: {token_id[:10]}...")
    
    try:
        # Initialize configuration
        config = PolygonQuickNodeConfig(endpoint_name, token_id)
        
        # Test connections
        print("\n🧪 Testing network connections...")
        results = await config.test_all_connections()
        
        success_count = 0
        for network, result in results.items():
            status = "✅" if result["success"] else "❌"
            print(f"{status} {network}: {result}")
            if result["success"]:
                success_count += 1
        
        print(f"\n📊 Connection Results: {success_count}/{len(results)} networks connected")
        
        if success_count > 0:
            print("✅ QuickNode connection test successful!")
            return True
        else:
            print("❌ No networks could be connected")
            return False
            
    except Exception as e:
        print(f"❌ QuickNode connection test failed: {e}")
        return False

async def test_database_connection():
    """Test database connection"""
    print("\n🗄️ Testing Database Connection...")
    
    try:
        # Initialize database manager
        db_manager = PolygonDatabaseManager()
        
        # Test connection
        await db_manager.initialize()
        
        # Get basic stats
        block_count = await db_manager.get_block_count()
        tx_count = await db_manager.get_transaction_count()
        latest_block = await db_manager.get_latest_block()
        
        print(f"📊 Database Statistics:")
        print(f"  Total blocks: {block_count}")
        print(f"  Total transactions: {tx_count}")
        print(f"  Latest block: {latest_block}")
        
        print("✅ Database connection test successful!")
        
        await db_manager.cleanup()
        return True
        
    except Exception as e:
        print(f"❌ Database connection test failed: {e}")
        return False

async def test_data_collection():
    """Test basic data collection"""
    print("\n📥 Testing Data Collection...")
    
    try:
        from collectors.block_collector import PolygonBlockCollector
        
        # Get credentials
        endpoint_name = os.getenv('QUICKNODE_ENDPOINT_NAME', 'defimon-polygon')
        token_id = os.getenv('QUICKNODE_API_KEY')
        
        # Initialize collector
        config = PolygonQuickNodeConfig(endpoint_name, token_id)
        collector = PolygonBlockCollector(config, "polygon_mainnet")
        
        await collector.initialize()
        
        # Get current block number
        current_block = await collector.get_current_block_number()
        print(f"📦 Current block: {current_block}")
        
        # Collect a single block for testing
        print("🔍 Collecting test block...")
        test_block = await collector.collect_block_data(current_block - 1)
        
        if test_block:
            print(f"✅ Test block collected successfully!")
            print(f"  Block number: {test_block.block_number}")
            print(f"  Transactions: {len(test_block.transactions)}")
            print(f"  Gas used: {test_block.gas_used}")
        else:
            print("❌ Failed to collect test block")
            return False
        
        await collector.cleanup()
        return True
        
    except Exception as e:
        print(f"❌ Data collection test failed: {e}")
        return False

async def main():
    """Main test function"""
    print("🚀 Polygon Data Collection Setup Test")
    print("=" * 50)
    
    # Test QuickNode connection
    quicknode_ok = await test_quicknode_connection()
    
    # Test database connection
    db_ok = await test_database_connection()
    
    # Test data collection
    collection_ok = await test_data_collection()
    
    print("\n" + "=" * 50)
    print("📋 Test Results Summary:")
    print(f"  QuickNode API: {'✅ PASS' if quicknode_ok else '❌ FAIL'}")
    print(f"  Database: {'✅ PASS' if db_ok else '❌ FAIL'}")
    print(f"  Data Collection: {'✅ PASS' if collection_ok else '❌ FAIL'}")
    
    if quicknode_ok and db_ok and collection_ok:
        print("\n🎉 All tests passed! Ready to start data collection.")
        print("\nNext steps:")
        print("1. Run: python main_collector.py --endpoint-name defimon-polygon --token-id YOUR_TOKEN --mode recent --num-blocks 10")
        print("2. Check the collected data in your database")
        print("3. Start continuous collection for real-time data")
    else:
        print("\n⚠️ Some tests failed. Please check the configuration and try again.")

if __name__ == "__main__":
    asyncio.run(main())
