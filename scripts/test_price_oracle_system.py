#!/usr/bin/env python3
"""
Test script for Price Oracle System
This script tests the API endpoints and data collection
"""

import asyncio
import aiohttp
import json
import time
import sys
from datetime import datetime
from typing import Dict, List

class PriceOracleTester:
    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
        self.session = None
    
    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    async def test_health_check(self) -> bool:
        """Test health check endpoint"""
        try:
            async with self.session.get(f"{self.base_url}/health") as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✓ Health check passed: {data}")
                    return True
                else:
                    print(f"✗ Health check failed: {response.status}")
                    return False
        except Exception as e:
            print(f"✗ Health check error: {e}")
            return False
    
    async def test_get_prices(self) -> bool:
        """Test getting all prices"""
        try:
            async with self.session.get(f"{self.base_url}/prices") as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✓ Got {len(data)} price records")
                    
                    # Show some sample data
                    for item in data[:3]:
                        print(f"  - {item['symbol']}: ${item['price_usd']:.2f} ({item['oracle_source']})")
                    
                    return True
                else:
                    print(f"✗ Get prices failed: {response.status}")
                    return False
        except Exception as e:
            print(f"✗ Get prices error: {e}")
            return False
    
    async def test_get_specific_prices(self) -> bool:
        """Test getting specific asset prices"""
        try:
            symbols = ["ETH", "BTC", "MATIC"]
            async with self.session.get(f"{self.base_url}/prices?symbols={','.join(symbols)}") as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✓ Got {len(data)} specific price records")
                    
                    for item in data:
                        print(f"  - {item['symbol']}: ${item['price_usd']:.2f} ({item['oracle_source']})")
                    
                    return True
                else:
                    print(f"✗ Get specific prices failed: {response.status}")
                    return False
        except Exception as e:
            print(f"✗ Get specific prices error: {e}")
            return False
    
    async def test_get_eth_price(self) -> bool:
        """Test getting ETH price specifically"""
        try:
            async with self.session.get(f"{self.base_url}/prices/ETH") as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✓ Got {len(data)} ETH price records")
                    
                    for item in data:
                        print(f"  - ETH: ${item['price_usd']:.2f} ({item['oracle_source']})")
                        if item.get('price_change_24h_percent'):
                            print(f"    24h change: {item['price_change_24h_percent']:.2f}%")
                    
                    return True
                else:
                    print(f"✗ Get ETH price failed: {response.status}")
                    return False
        except Exception as e:
            print(f"✗ Get ETH price error: {e}")
            return False
    
    async def test_get_l2_networks(self) -> bool:
        """Test getting L2 network data"""
        try:
            async with self.session.get(f"{self.base_url}/l2-networks") as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✓ Got {len(data)} L2 network records")
                    
                    for item in data:
                        print(f"  - {item['network']}: ${item['price_usd']:.4f}")
                        if item.get('tvl_usd'):
                            print(f"    TVL: ${item['tvl_usd']:,.0f}")
                        if item.get('total_transactions_24h'):
                            print(f"    Transactions (24h): {item['total_transactions_24h']:,}")
                    
                    return True
                else:
                    print(f"✗ Get L2 networks failed: {response.status}")
                    return False
        except Exception as e:
            print(f"✗ Get L2 networks error: {e}")
            return False
    
    async def test_get_aggregations(self) -> bool:
        """Test getting price aggregations"""
        try:
            async with self.session.get(f"{self.base_url}/aggregations") as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✓ Got {len(data)} aggregation records")
                    
                    for item in data:
                        print(f"  - {item['symbol']}: ${item['weighted_price_usd']:.2f}")
                        print(f"    Confidence: {item['confidence_score']:.2f} ({item['oracle_count']} oracles)")
                        if item.get('price_volatility'):
                            print(f"    Volatility: {item['price_volatility']:.4f}")
                    
                    return True
                else:
                    print(f"✗ Get aggregations failed: {response.status}")
                    return False
        except Exception as e:
            print(f"✗ Get aggregations error: {e}")
            return False
    
    async def test_get_history(self) -> bool:
        """Test getting price history"""
        try:
            async with self.session.get(f"{self.base_url}/history/ETH?hours=6") as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✓ Got {len(data)} ETH history records")
                    
                    if data:
                        latest = data[-1]
                        earliest = data[0]
                        print(f"  - Latest: ${latest['price_usd']:.2f} at {latest['timestamp']}")
                        print(f"  - Earliest: ${earliest['price_usd']:.2f} at {earliest['timestamp']}")
                    
                    return True
                else:
                    print(f"✗ Get history failed: {response.status}")
                    return False
        except Exception as e:
            print(f"✗ Get history error: {e}")
            return False
    
    async def test_oracle_performance(self) -> bool:
        """Test getting oracle performance metrics"""
        try:
            async with self.session.get(f"{self.base_url}/oracles/performance") as response:
                if response.status == 200:
                    data = await response.json()
                    print(f"✓ Got {len(data)} oracle performance records")
                    
                    # Group by oracle
                    oracle_stats = {}
                    for item in data:
                        oracle = item['oracle_name']
                        if oracle not in oracle_stats:
                            oracle_stats[oracle] = []
                        oracle_stats[oracle].append(item)
                    
                    for oracle, stats in oracle_stats.items():
                        print(f"  - {oracle}: {len(stats)} assets tracked")
                        if stats and stats[0].get('response_time_avg_ms'):
                            avg_response = sum(s.get('response_time_avg_ms', 0) for s in stats) / len(stats)
                            print(f"    Avg response time: {avg_response:.0f}ms")
                    
                    return True
                else:
                    print(f"✗ Get oracle performance failed: {response.status}")
                    return False
        except Exception as e:
            print(f"✗ Get oracle performance error: {e}")
            return False
    
    async def run_all_tests(self) -> Dict[str, bool]:
        """Run all tests"""
        print("🚀 Starting Price Oracle System Tests")
        print("=" * 50)
        
        tests = [
            ("Health Check", self.test_health_check),
            ("Get All Prices", self.test_get_prices),
            ("Get Specific Prices", self.test_get_specific_prices),
            ("Get ETH Price", self.test_get_eth_price),
            ("Get L2 Networks", self.test_get_l2_networks),
            ("Get Aggregations", self.test_get_aggregations),
            ("Get History", self.test_get_history),
            ("Oracle Performance", self.test_oracle_performance),
        ]
        
        results = {}
        
        for test_name, test_func in tests:
            print(f"\n📋 Testing: {test_name}")
            print("-" * 30)
            
            try:
                result = await test_func()
                results[test_name] = result
                
                if result:
                    print(f"✅ {test_name}: PASSED")
                else:
                    print(f"❌ {test_name}: FAILED")
                    
            except Exception as e:
                print(f"❌ {test_name}: ERROR - {e}")
                results[test_name] = False
            
            time.sleep(1)  # Small delay between tests
        
        return results
    
    def print_summary(self, results: Dict[str, bool]):
        """Print test summary"""
        print("\n" + "=" * 50)
        print("📊 TEST SUMMARY")
        print("=" * 50)
        
        passed = sum(1 for result in results.values() if result)
        total = len(results)
        
        print(f"Total tests: {total}")
        print(f"Passed: {passed}")
        print(f"Failed: {total - passed}")
        print(f"Success rate: {(passed/total)*100:.1f}%")
        
        print("\nDetailed results:")
        for test_name, result in results.items():
            status = "✅ PASS" if result else "❌ FAIL"
            print(f"  {test_name}: {status}")
        
        if passed == total:
            print("\n🎉 All tests passed! The Price Oracle System is working correctly.")
        else:
            print(f"\n⚠️  {total - passed} test(s) failed. Please check the system configuration.")

async def main():
    """Main test function"""
    # Check if base URL is provided as command line argument
    base_url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000"
    
    print(f"Testing Price Oracle System at: {base_url}")
    
    async with PriceOracleTester(base_url) as tester:
        results = await tester.run_all_tests()
        tester.print_summary(results)
        
        # Exit with appropriate code
        if all(results.values()):
            sys.exit(0)
        else:
            sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
