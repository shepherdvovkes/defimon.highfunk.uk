#!/usr/bin/env python3
"""
Test script for Blast API through Alchemy
"""

import os
import requests
import json
from datetime import datetime

# Test configuration
ALCHEMY_API_KEY = "YOUR_ALCHEMY_API_KEY_HERE"  # Replace with your actual key
ALCHEMY_BASE_URL = "https://eth-mainnet.g.alchemy.com/v2"

def test_alchemy_direct():
    """Test Alchemy API directly"""
    print("🔍 Testing Alchemy API directly...")
    
    if ALCHEMY_API_KEY == "YOUR_ALCHEMY_API_KEY_HERE":
        print("❌ Please set your ALCHEMY_API_KEY in the script")
        return False
    
    url = f"{ALCHEMY_BASE_URL}/{ALCHEMY_API_KEY}"
    headers = {"Content-Type": "application/json"}
    
    # Test 1: Get block number
    print("\n📦 Test 1: Getting block number...")
    payload = {
        "jsonrpc": "2.0",
        "method": "eth_blockNumber",
        "params": [],
        "id": 1
    }
    
    try:
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        if response.status_code == 200:
            result = response.json()
            block_number = int(result.get("result", "0x0"), 16)
            print(f"✅ Block number: {block_number:,} (0x{result.get('result', '0x0')})")
        else:
            print(f"❌ Error: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False
    
    # Test 2: Get gas price
    print("\n⛽ Test 2: Getting gas price...")
    payload = {
        "jsonrpc": "2.0",
        "method": "eth_gasPrice",
        "params": [],
        "id": 1
    }
    
    try:
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        if response.status_code == 200:
            result = response.json()
            gas_price_hex = result.get("result", "0x0")
            gas_price_wei = int(gas_price_hex, 16)
            gas_price_gwei = gas_price_wei / 10**9
            print(f"✅ Gas price: {gas_price_wei:,} Wei ({gas_price_gwei:.2f} Gwei)")
        else:
            print(f"❌ Error: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False
    
    # Test 3: Get balance
    print("\n💰 Test 3: Getting balance...")
    test_address = "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6"  # Vitalik's address
    payload = {
        "jsonrpc": "2.0",
        "method": "eth_getBalance",
        "params": [test_address, "latest"],
        "id": 1
    }
    
    try:
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        if response.status_code == 200:
            result = response.json()
            balance_hex = result.get("result", "0x0")
            balance_wei = int(balance_hex, 16)
            balance_eth = balance_wei / 10**18
            print(f"✅ Balance for {test_address}: {balance_wei:,} Wei ({balance_eth:.4f} ETH)")
        else:
            print(f"❌ Error: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False
    
    return True

def test_blast_via_server():
    """Test Blast API through our server"""
    print("\n🔍 Testing Blast API through server...")
    
    base_url = "http://localhost:8002/api/external-apis"
    
    # Test 1: Blast block number
    print("\n📦 Test 1: Blast block number...")
    try:
        response = requests.get(f"{base_url}/blast/block-number", timeout=30)
        if response.status_code == 200:
            result = response.json()
            if result.get("success"):
                print(f"✅ Block number: {result.get('block_number', 0):,}")
                print(f"   Provider: {result.get('provider', 'Unknown')}")
            else:
                print(f"❌ Error: {result.get('error', 'Unknown error')}")
        else:
            print(f"❌ HTTP Error: {response.status_code}")
    except Exception as e:
        print(f"❌ Exception: {e}")
    
    # Test 2: Blast gas price
    print("\n⛽ Test 2: Blast gas price...")
    try:
        response = requests.get(f"{base_url}/blast/gas-price", timeout=30)
        if response.status_code == 200:
            result = response.json()
            if result.get("success"):
                gas_price_wei = result.get("gas_price_wei", 0)
                gas_price_gwei = result.get("gas_price_gwei", 0)
                print(f"✅ Gas price: {gas_price_wei:,} Wei ({gas_price_gwei:.2f} Gwei)")
                print(f"   Provider: {result.get('provider', 'Unknown')}")
            else:
                print(f"❌ Error: {result.get('error', 'Unknown error')}")
        else:
            print(f"❌ HTTP Error: {response.status_code}")
    except Exception as e:
        print(f"❌ Exception: {e}")
    
    # Test 3: Summary
    print("\n📊 Test 3: API Summary...")
    try:
        response = requests.get(f"{base_url}/summary", timeout=30)
        if response.status_code == 200:
            result = response.json()
            print("✅ Summary retrieved successfully")
            print(f"   Timestamp: {result.get('timestamp', 'Unknown')}")
            
            # Check Blast status
            blast_data = result.get("blast", {})
            if blast_data:
                block_result = blast_data.get("block_number", {})
                gas_result = blast_data.get("gas_price", {})
                
                if block_result.get("success"):
                    print(f"   Blast Block: ✅ {block_result.get('block_number', 0):,}")
                else:
                    print(f"   Blast Block: ❌ {block_result.get('error', 'Unknown error')}")
                
                if gas_result.get("success"):
                    gas_price = gas_result.get("gas_price_gwei", 0)
                    print(f"   Blast Gas: ✅ {gas_price:.2f} Gwei")
                else:
                    print(f"   Blast Gas: ❌ {gas_result.get('error', 'Unknown error')}")
        else:
            print(f"❌ HTTP Error: {response.status_code}")
    except Exception as e:
        print(f"❌ Exception: {e}")

def main():
    """Main test function"""
    print("🚀 Blast API through Alchemy - Test Suite")
    print("=" * 50)
    print(f"Timestamp: {datetime.now().isoformat()}")
    
    # Test 1: Direct Alchemy API
    print("\n" + "=" * 50)
    print("DIRECT ALCHEMY API TEST")
    print("=" * 50)
    
    if test_alchemy_direct():
        print("\n✅ Direct Alchemy API tests passed!")
    else:
        print("\n❌ Direct Alchemy API tests failed!")
    
    # Test 2: Blast via server
    print("\n" + "=" * 50)
    print("BLAST API VIA SERVER TEST")
    print("=" * 50)
    
    test_blast_via_server()
    
    print("\n" + "=" * 50)
    print("TEST COMPLETED")
    print("=" * 50)

if __name__ == "__main__":
    main()
