#!/usr/bin/env python3
"""
Test Enhanced External APIs
Tests the expanded QuickNode and Alchemy APIs with all networks
"""

import requests
import json
import time
from datetime import datetime

# Configuration
BASE_URL = "http://localhost:8002"
ENHANCED_API_BASE = f"{BASE_URL}/enhanced-external-apis"

def test_enhanced_health_check():
    """Test enhanced health check endpoint"""
    print("🔍 Testing Enhanced Health Check...")
    
    try:
        response = requests.get(f"{ENHANCED_API_BASE}/health", timeout=10)
        response.raise_for_status()
        data = response.json()
        
        print(f"✅ Health Check: {data['status']}")
        print(f"   Total Networks: {data['total_networks']}")
        print(f"   QuickNode Networks: {data['providers']['quicknode']['networks']}")
        print(f"   Alchemy Networks: {data['providers']['alchemy']['networks']}")
        
        return data
    except Exception as e:
        print(f"❌ Health Check Failed: {e}")
        return None

def test_quicknode_networks():
    """Test QuickNode networks endpoint"""
    print("\n🔍 Testing QuickNode Networks...")
    
    try:
        response = requests.get(f"{ENHANCED_API_BASE}/quicknode/networks", timeout=10)
        response.raise_for_status()
        data = response.json()
        
        print(f"✅ QuickNode Networks: {data['total']} networks")
        print(f"   High Priority: {len(data['by_priority']['high'])}")
        print(f"   Medium Priority: {len(data['by_priority']['medium'])}")
        print(f"   Low Priority: {len(data['by_priority']['low'])}")
        
        return data
    except Exception as e:
        print(f"❌ QuickNode Networks Failed: {e}")
        return None

def test_alchemy_networks():
    """Test Alchemy networks endpoint"""
    print("\n🔍 Testing Alchemy Networks...")
    
    try:
        response = requests.get(f"{ENHANCED_API_BASE}/alchemy/networks", timeout=10)
        response.raise_for_status()
        data = response.json()
        
        print(f"✅ Alchemy Networks: {data['total']} networks")
        print(f"   High Priority: {len(data['by_priority']['high'])}")
        print(f"   Medium Priority: {len(data['by_priority']['medium'])}")
        print(f"   Low Priority: {len(data['by_priority']['low'])}")
        
        return data
    except Exception as e:
        print(f"❌ Alchemy Networks Failed: {e}")
        return None

def test_quicknode_network_status():
    """Test QuickNode network status for all networks"""
    print("\n🔍 Testing QuickNode Network Status...")
    
    try:
        response = requests.get(f"{ENHANCED_API_BASE}/quicknode/all-networks/status", timeout=30)
        response.raise_for_status()
        data = response.json()
        
        print(f"✅ QuickNode Status: {data['working_networks']}/{data['total_networks']} working")
        
        # Show working networks
        working_networks = []
        for network, status in data['network_statuses'].items():
            if status.get('success'):
                working_networks.append(network)
        
        print(f"   Working Networks: {', '.join(working_networks[:5])}{'...' if len(working_networks) > 5 else ''}")
        
        return data
    except Exception as e:
        print(f"❌ QuickNode Status Failed: {e}")
        return None

def test_alchemy_network_status():
    """Test Alchemy network status for all networks"""
    print("\n🔍 Testing Alchemy Network Status...")
    
    try:
        response = requests.get(f"{ENHANCED_API_BASE}/alchemy/all-networks/status", timeout=30)
        response.raise_for_status()
        data = response.json()
        
        print(f"✅ Alchemy Status: {data['working_networks']}/{data['total_networks']} working")
        
        # Show working networks
        working_networks = []
        for network, status in data['network_statuses'].items():
            if status.get('success'):
                working_networks.append(network)
        
        print(f"   Working Networks: {', '.join(working_networks[:5])}{'...' if len(working_networks) > 5 else ''}")
        
        return data
    except Exception as e:
        print(f"❌ Alchemy Status Failed: {e}")
        return None

def test_comprehensive_summary():
    """Test comprehensive summary endpoint"""
    print("\n🔍 Testing Comprehensive Summary...")
    
    try:
        response = requests.get(f"{ENHANCED_API_BASE}/comprehensive-summary", timeout=60)
        response.raise_for_status()
        data = response.json()
        
        print(f"✅ Comprehensive Summary:")
        print(f"   Total Networks: {data['total_networks']}")
        print(f"   QuickNode: {data['providers']['quicknode']['working_networks']}/{data['providers']['quicknode']['total_networks']} working")
        print(f"   Alchemy: {data['providers']['alchemy']['working_networks']}/{data['providers']['alchemy']['total_networks']} working")
        print(f"   Total TVL: ${data['statistics']['total_tvl']/1e9:.2f}B")
        print(f"   Total 24h Volume: ${data['statistics']['total_volume_24h']/1e6:.2f}M")
        
        return data
    except Exception as e:
        print(f"❌ Comprehensive Summary Failed: {e}")
        return None

def test_individual_network_endpoints():
    """Test individual network endpoints"""
    print("\n🔍 Testing Individual Network Endpoints...")
    
    # Test a few high-priority networks
    test_networks = [
        ("quicknode", "ethereum"),
        ("quicknode", "arbitrum"),
        ("quicknode", "polygon"),
        ("alchemy", "ethereum"),
        ("alchemy", "polygon")
    ]
    
    for provider, network in test_networks:
        try:
            # Test block number
            response = requests.get(f"{ENHANCED_API_BASE}/{provider}/{network}/block-number", timeout=10)
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    print(f"✅ {provider}/{network}: Block {data['block_number']}")
                else:
                    print(f"⚠️  {provider}/{network}: {data.get('error', 'Unknown error')}")
            else:
                print(f"❌ {provider}/{network}: HTTP {response.status_code}")
        except Exception as e:
            print(f"❌ {provider}/{network}: {e}")

def test_advanced_alchemy_features():
    """Test advanced Alchemy features"""
    print("\n🔍 Testing Advanced Alchemy Features...")
    
    # Test NFT metadata (using CryptoPunks as example)
    try:
        response = requests.get(
            f"{ENHANCED_API_BASE}/alchemy/ethereum/nft/0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB/1",
            timeout=10
        )
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                print(f"✅ NFT API: Working (CryptoPunks)")
            else:
                print(f"⚠️  NFT API: {data.get('error', 'Unknown error')}")
        else:
            print(f"❌ NFT API: HTTP {response.status_code}")
    except Exception as e:
        print(f"❌ NFT API: {e}")
    
    # Test token metadata (using USDC as example)
    try:
        response = requests.get(
            f"{ENHANCED_API_BASE}/alchemy/ethereum/token/0xA0b86a33E6441b8C4C8C8C8C8C8C8C8C8C8C8C8",
            timeout=10
        )
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                print(f"✅ Token API: Working")
            else:
                print(f"⚠️  Token API: {data.get('error', 'Unknown error')}")
        else:
            print(f"❌ Token API: HTTP {response.status_code}")
    except Exception as e:
        print(f"❌ Token API: {e}")

def main():
    """Run all tests"""
    print("🚀 Enhanced External APIs Test Suite")
    print("=" * 50)
    print(f"Timestamp: {datetime.now().isoformat()}")
    print(f"Base URL: {BASE_URL}")
    print()
    
    # Run tests
    health_data = test_enhanced_health_check()
    quicknode_networks = test_quicknode_networks()
    alchemy_networks = test_alchemy_networks()
    quicknode_status = test_quicknode_network_status()
    alchemy_status = test_alchemy_network_status()
    comprehensive_summary = test_comprehensive_summary()
    test_individual_network_endpoints()
    test_advanced_alchemy_features()
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Summary")
    print("=" * 50)
    
    if health_data:
        print(f"✅ Health Check: PASSED")
        print(f"   Total Networks: {health_data['total_networks']}")
    else:
        print(f"❌ Health Check: FAILED")
    
    if quicknode_networks:
        print(f"✅ QuickNode Networks: PASSED ({quicknode_networks['total']} networks)")
    else:
        print(f"❌ QuickNode Networks: FAILED")
    
    if alchemy_networks:
        print(f"✅ Alchemy Networks: PASSED ({alchemy_networks['total']} networks)")
    else:
        print(f"❌ Alchemy Networks: FAILED")
    
    if comprehensive_summary:
        total_working = (comprehensive_summary['providers']['quicknode']['working_networks'] + 
                        comprehensive_summary['providers']['alchemy']['working_networks'])
        total_networks = comprehensive_summary['total_networks']
        success_rate = (total_working / total_networks) * 100 if total_networks > 0 else 0
        
        print(f"✅ Comprehensive Summary: PASSED")
        print(f"   Success Rate: {success_rate:.1f}% ({total_working}/{total_networks})")
        print(f"   Total TVL: ${comprehensive_summary['statistics']['total_tvl']/1e9:.2f}B")
    else:
        print(f"❌ Comprehensive Summary: FAILED")
    
    print(f"\n🎯 Enhanced API Dashboard available at: http://localhost:3000/enhanced-api-dashboard")

if __name__ == "__main__":
    main()
