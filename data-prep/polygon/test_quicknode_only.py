#!/usr/bin/env python3
"""
Simple QuickNode connection test
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

async def test_quicknode_only():
    """Test only QuickNode connection"""
    print("🔗 Testing QuickNode Connection Only...")
    
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

async def main():
    """Main test function"""
    print("🚀 QuickNode Connection Test")
    print("=" * 40)
    
    # Test QuickNode connection
    quicknode_ok = await test_quicknode_only()
    
    print("\n" + "=" * 40)
    if quicknode_ok:
        print("🎉 QuickNode connection successful!")
        print("\nNext steps:")
        print("1. Test database connection separately")
        print("2. Start data collection")
    else:
        print("⚠️ QuickNode connection failed. Please check:")
        print("  - QuickNode credentials")
        print("  - Network connectivity")
        print("  - SSL configuration")

if __name__ == "__main__":
    asyncio.run(main())
