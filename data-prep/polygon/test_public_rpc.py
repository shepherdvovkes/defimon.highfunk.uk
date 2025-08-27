#!/usr/bin/env python3
"""
Test using public Polygon RPC endpoints
"""

import asyncio
import aiohttp
import json

async def test_public_polygon_rpc():
    """Test using public Polygon RPC endpoints"""
    print("🔗 Testing Public Polygon RPC Endpoints...")
    
    # Public Polygon RPC endpoints
    endpoints = {
        "Polygon RPC": "https://polygon-rpc.com",
        "PolygonScan": "https://api.polygonscan.com/api",
        "Alchemy": "https://polygon-mainnet.g.alchemy.com/v2/demo"
    }
    
    for name, url in endpoints.items():
        print(f"\n🧪 Testing {name}: {url}")
        
        try:
            async with aiohttp.ClientSession(connector=aiohttp.TCPConnector(ssl=False)) as session:
                # Test basic RPC call
                payload = {
                    "jsonrpc": "2.0",
                    "method": "eth_blockNumber",
                    "params": [],
                    "id": 1
                }
                
                async with session.post(url, json=payload, timeout=aiohttp.ClientTimeout(total=10)) as response:
                    if response.status == 200:
                        data = await response.json()
                        if "result" in data:
                            block_number = int(data["result"], 16)
                            print(f"✅ {name}: Block {block_number}")
                        else:
                            print(f"❌ {name}: No result in response")
                    else:
                        print(f"❌ {name}: HTTP {response.status}")
                        
        except Exception as e:
            print(f"❌ {name}: {e}")

async def test_quicknode_endpoint():
    """Test QuickNode endpoint with different configurations"""
    print("\n🔗 Testing QuickNode Endpoint...")
    
    # Try different endpoint configurations
    endpoint_configs = [
        "defimon-polygon",
        "defimon",
        "polygon",
        "mainnet"
    ]
    
    token_id = "QN_6a9c24b3a5fc491f88e8c24c3294ef36"
    
    for endpoint_name in endpoint_configs:
        print(f"\n🧪 Testing endpoint: {endpoint_name}")
        
        url = f"https://{endpoint_name}.polygon-mainnet.quiknode.pro/{token_id}"
        
        try:
            async with aiohttp.ClientSession(connector=aiohttp.TCPConnector(ssl=False)) as session:
                payload = {
                    "jsonrpc": "2.0",
                    "method": "eth_blockNumber",
                    "params": [],
                    "id": 1
                }
                
                async with session.post(url, json=payload, timeout=aiohttp.ClientTimeout(total=10)) as response:
                    if response.status == 200:
                        data = await response.json()
                        if "result" in data:
                            block_number = int(data["result"], 16)
                            print(f"✅ {endpoint_name}: Block {block_number}")
                            return endpoint_name
                        else:
                            print(f"❌ {endpoint_name}: No result in response")
                    else:
                        print(f"❌ {endpoint_name}: HTTP {response.status}")
                        
        except Exception as e:
            print(f"❌ {endpoint_name}: {e}")
    
    return None

async def main():
    """Main test function"""
    print("🚀 Polygon RPC Endpoint Test")
    print("=" * 50)
    
    # Test public endpoints
    await test_public_polygon_rpc()
    
    # Test QuickNode endpoints
    working_endpoint = await test_quicknode_endpoint()
    
    print("\n" + "=" * 50)
    if working_endpoint:
        print(f"🎉 Found working QuickNode endpoint: {working_endpoint}")
        print(f"Update your .env file with: QUICKNODE_ENDPOINT_NAME={working_endpoint}")
    else:
        print("⚠️ No working QuickNode endpoint found")
        print("You may need to:")
        print("1. Create a new QuickNode endpoint")
        print("2. Check your QuickNode dashboard")
        print("3. Use a different endpoint name")

if __name__ == "__main__":
    asyncio.run(main())
