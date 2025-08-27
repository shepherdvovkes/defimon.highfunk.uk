#!/usr/bin/env python3
"""
Direct test using the exact QuickNode endpoint URL
"""

import asyncio
import aiohttp
import json

async def test_direct_endpoint():
    """Test the exact QuickNode endpoint URL"""
    print("🔗 Testing Direct QuickNode Endpoint...")
    
    # Use the exact URL provided
    url = "https://hidden-holy-seed.matic.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b"
    
    print(f"📡 URL: {url}")
    
    try:
        # Try with SSL disabled
        async with aiohttp.ClientSession(connector=aiohttp.TCPConnector(ssl=False)) as session:
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_blockNumber",
                "params": [],
                "id": 1
            }
            
            print("🧪 Testing with SSL disabled...")
            async with session.post(url, json=payload, timeout=aiohttp.ClientTimeout(total=10)) as response:
                print(f"📊 Response status: {response.status}")
                
                if response.status == 200:
                    data = await response.json()
                    print(f"📄 Response data: {data}")
                    
                    if "result" in data:
                        block_number = int(data["result"], 16)
                        print(f"✅ Success! Current block: {block_number}")
                        return True
                    else:
                        print(f"❌ No result in response: {data}")
                        return False
                else:
                    print(f"❌ HTTP {response.status}")
                    return False
                    
    except Exception as e:
        print(f"❌ Error with SSL disabled: {e}")
        
        # Try with SSL enabled
        try:
            print("🧪 Testing with SSL enabled...")
            async with aiohttp.ClientSession() as session:
                payload = {
                    "jsonrpc": "2.0",
                    "method": "eth_blockNumber",
                    "params": [],
                    "id": 1
                }
                
                async with session.post(url, json=payload, timeout=aiohttp.ClientTimeout(total=10)) as response:
                    print(f"📊 Response status: {response.status}")
                    
                    if response.status == 200:
                        data = await response.json()
                        print(f"📄 Response data: {data}")
                        
                        if "result" in data:
                            block_number = int(data["result"], 16)
                            print(f"✅ Success! Current block: {block_number}")
                            return True
                        else:
                            print(f"❌ No result in response: {data}")
                            return False
                    else:
                        print(f"❌ HTTP {response.status}")
                        return False
                        
        except Exception as e2:
            print(f"❌ Error with SSL enabled: {e2}")
            return False

async def test_websocket():
    """Test WebSocket connection"""
    print("\n🔗 Testing WebSocket Connection...")
    
    ws_url = "wss://hidden-holy-seed.matic.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b"
    
    try:
        import websockets
        
        async with websockets.connect(ws_url, ssl=False) as websocket:
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_blockNumber",
                "params": [],
                "id": 1
            }
            
            await websocket.send(json.dumps(payload))
            response = await websocket.recv()
            data = json.loads(response)
            
            print(f"📄 WebSocket response: {data}")
            
            if "result" in data:
                block_number = int(data["result"], 16)
                print(f"✅ WebSocket success! Current block: {block_number}")
                return True
            else:
                print(f"❌ WebSocket no result: {data}")
                return False
                
    except Exception as e:
        print(f"❌ WebSocket error: {e}")
        return False

async def main():
    """Main test function"""
    print("🚀 Direct QuickNode Endpoint Test")
    print("=" * 50)
    
    # Test HTTP endpoint
    http_ok = await test_direct_endpoint()
    
    # Test WebSocket endpoint
    ws_ok = await test_websocket()
    
    print("\n" + "=" * 50)
    print("📋 Test Results:")
    print(f"  HTTP Endpoint: {'✅ PASS' if http_ok else '❌ FAIL'}")
    print(f"  WebSocket: {'✅ PASS' if ws_ok else '❌ FAIL'}")
    
    if http_ok or ws_ok:
        print("\n🎉 QuickNode endpoint is working!")
        print("You can now start data collection.")
    else:
        print("\n⚠️ QuickNode endpoint is not working.")
        print("Please check:")
        print("1. Endpoint URL is correct")
        print("2. Token is valid")
        print("3. Network connectivity")

if __name__ == "__main__":
    asyncio.run(main())
