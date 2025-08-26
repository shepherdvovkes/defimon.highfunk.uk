#!/usr/bin/env python3
"""
Script to test external API connections and provide better error handling
"""

import asyncio
import aiohttp
import ssl
import certifi
from datetime import datetime

async def test_api_connections():
    """Test connections to external APIs"""
    print("🔍 Testing external API connections...")
    
    # Create SSL context with proper certificates
    ssl_context = ssl.create_default_context(cafile=certifi.where())
    
    # Test URLs
    test_urls = {
        'CoinGecko': 'https://api.coingecko.com/api/v3/ping',
        'DeFiLlama': 'https://api.llama.fi/protocols',
        'Etherscan': 'https://api.etherscan.io/api?module=proxy&action=eth_blockNumber'
    }
    
    async with aiohttp.ClientSession(connector=aiohttp.TCPConnector(ssl=ssl_context)) as session:
        for name, url in test_urls.items():
            try:
                print(f"Testing {name}...")
                async with session.get(url, timeout=aiohttp.ClientTimeout(total=10)) as response:
                    if response.status == 200:
                        print(f"✅ {name}: Connection successful")
                    else:
                        print(f"⚠️  {name}: HTTP {response.status}")
            except asyncio.TimeoutError:
                print(f"⏰ {name}: Connection timeout")
            except Exception as e:
                print(f"❌ {name}: {str(e)}")
    
    print("\n📊 API Connection Test Complete")

if __name__ == "__main__":
    asyncio.run(test_api_connections())
