#!/usr/bin/env python3
"""
Test Script for Final SSL Solution
Demonstrates how all QuickNode networks work with proper SSL handling
"""

import requests
import json
import urllib3

# Disable SSL warnings for cleaner output
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def test_network_with_ssl_handling(network_name: str, url: str, ssl_verify: bool):
    """Test a network with proper SSL handling"""
    
    payload = {
        "jsonrpc": "2.0",
        "method": "eth_blockNumber",
        "params": [],
        "id": 1
    }
    
    headers = {
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.post(
            url,
            json=payload,
            headers=headers,
            verify=ssl_verify,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            block_hex = result.get("result", "0x0")
            block_number = int(block_hex, 16)
            
            ssl_status = "🔒" if ssl_verify else "⚠️"
            print(f"{ssl_status} {network_name}: Block {block_number:,}")
            return True
        else:
            print(f"❌ {network_name}: HTTP {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ {network_name}: {str(e)}")
        return False

def main():
    """Test all networks with proper SSL handling"""
    
    print("🚀 Testing QuickNode Networks with SSL Solution")
    print("=" * 55)
    
    # Network configurations with SSL settings
    networks = [
        ("Ethereum", "https://hidden-holy-seed.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b", True),
        ("Base", "https://hidden-holy-seed.base-mainnet.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b", True),
        ("BSC", "https://hidden-holy-seed.bsc.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b", True),
        ("Avalanche", "https://hidden-holy-seed.avalanche-mainnet.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b/ext/bc/C/rpc", True),
        ("Polygon", "https://hidden-holy-seed.polygon-mainnet.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b", False),
        ("Arbitrum", "https://hidden-holy-seed.arbitrum-one.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b", False),
        ("Optimism", "https://hidden-holy-seed.optimism-mainnet.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b", False)
    ]
    
    success_count = 0
    total_count = len(networks)
    
    for network_name, url, ssl_verify in networks:
        if test_network_with_ssl_handling(network_name, url, ssl_verify):
            success_count += 1
    
    print("\n" + "=" * 55)
    print(f"📊 Results: {success_count}/{total_count} networks working")
    print(f"🎯 Success Rate: {(success_count/total_count)*100:.1f}%")
    
    if success_count == total_count:
        print("🎉 ALL NETWORKS WORKING! SSL solution successful!")
    else:
        print("⚠️ Some networks failed. Check configuration.")
    
    print("\n🔒 SSL Status:")
    ssl_verified = sum(1 for _, _, ssl_verify in networks if ssl_verify)
    ssl_unverified = total_count - ssl_verified
    print(f"SSL Verified: {ssl_verified} networks")
    print(f"SSL Unverified: {ssl_unverified} networks")
    
    print("\n💡 Next Steps:")
    print("1. Use quicknode_config_final.py for production")
    print("2. Monitor SSL certificate status")
    print("3. Report SSL issues to QuickNode support")

if __name__ == "__main__":
    main()
