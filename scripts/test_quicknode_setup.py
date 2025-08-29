#!/usr/bin/env python3
"""
QuickNode Setup Test Script
Tests QuickNode API connection and database setup before running the main collection
"""

import os
import asyncio
import aiohttp
import asyncpg
import json
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class QuickNodeSetupTester:
    """Test QuickNode setup and configuration"""
    
    def __init__(self):
        # QuickNode configuration
        self.endpoint_name = os.getenv('QUICKNODE_ENDPOINT_NAME', 'hidden-holy-seed')
        self.token_id = os.getenv('QUICKNODE_TOKEN_ID', '97d6d8e7659b49b126c43455edc4607949bfb52b')
        self.api_key = os.getenv('QUICKNODE_API_KEY', 'QN_6a9c24b3a5fc491f88e8c24c3294ef36')
        
        # Database configuration
        self.db_config = {
            'host': os.getenv('POSTGRES_HOST', 'localhost'),
            'port': os.getenv('POSTGRES_PORT', '5432'),
            'database': os.getenv('POSTGRES_DB', 'defi_analytics'),
            'user': os.getenv('POSTGRES_USER', 'postgres'),
            'password': os.getenv('POSTGRES_PASSWORD', 'password')
        }
        
        # Test networks
        self.test_networks = {
            'ethereum': 'ethereum',
            'polygon': 'matic',
            'arbitrum': 'arbitrum-one',
            'optimism': 'optimism',
            'base': 'base',
            'bsc': 'bsc-mainnet',
            'avalanche': 'avalanche-mainnet'
        }
        
        self.results = {
            'environment': {},
            'database': {},
            'quicknode': {},
            'networks': {}
        }
    
    def _get_network_url(self, network_key: str) -> str:
        """Get QuickNode URL for specific network"""
        if network_key == 'ethereum':
            return f"https://{self.endpoint_name}.quiknode.pro/{self.token_id}/"
        else:
            return f"https://{self.endpoint_name}.{network_key}.quiknode.pro/{self.token_id}/"
    
    def test_environment(self):
        """Test environment variables"""
        print("🔍 Testing Environment Configuration...")
        
        required_vars = [
            'QUICKNODE_ENDPOINT_NAME',
            'QUICKNODE_TOKEN_ID',
            'QUICKNODE_API_KEY',
            'POSTGRES_HOST',
            'POSTGRES_DB',
            'POSTGRES_USER',
            'POSTGRES_PASSWORD'
        ]
        
        missing_vars = []
        for var in required_vars:
            value = os.getenv(var)
            if value:
                self.results['environment'][var] = '✅ Set'
                print(f"  ✅ {var}: {value[:10]}..." if len(value) > 10 else f"  ✅ {var}: {value}")
            else:
                self.results['environment'][var] = '❌ Missing'
                missing_vars.append(var)
                print(f"  ❌ {var}: Not set")
        
        if missing_vars:
            print(f"\n❌ Missing environment variables: {', '.join(missing_vars)}")
            return False
        
        print("✅ Environment configuration is valid")
        return True
    
    async def test_database_connection(self):
        """Test database connection"""
        print("\n🔍 Testing Database Connection...")
        
        try:
            conn = await asyncpg.connect(**self.db_config)
            
            # Test basic query
            version = await conn.fetchval("SELECT version()")
            print(f"  ✅ Database connected: {version.split()[0]}")
            
            # Test if database exists and is accessible
            db_name = await conn.fetchval("SELECT current_database()")
            print(f"  ✅ Current database: {db_name}")
            
            # Test if we can create schemas
            test_schema = "test_quicknode_setup"
            await conn.execute(f"CREATE SCHEMA IF NOT EXISTS {test_schema}")
            await conn.execute(f"DROP SCHEMA IF EXISTS {test_schema}")
            print("  ✅ Schema creation/ deletion test passed")
            
            await conn.close()
            
            self.results['database']['connection'] = '✅ Success'
            self.results['database']['version'] = version.split()[0]
            self.results['database']['name'] = db_name
            
            return True
            
        except Exception as e:
            print(f"  ❌ Database connection failed: {e}")
            self.results['database']['connection'] = f'❌ Failed: {str(e)}'
            return False
    
    async def test_quicknode_api(self):
        """Test QuickNode API connection"""
        print("\n🔍 Testing QuickNode API Connection...")
        
        try:
            connector = aiohttp.TCPConnector(ssl=False)
            timeout = aiohttp.ClientTimeout(total=30)
            
            async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
                # Test Ethereum endpoint
                url = self._get_network_url('ethereum')
                headers = {
                    'Content-Type': 'application/json',
                    'Authorization': f'Bearer {self.api_key}'
                }
                
                payload = {
                    'jsonrpc': '2.0',
                    'id': 1,
                    'method': 'eth_blockNumber',
                    'params': []
                }
                
                async with session.post(url, json=payload, headers=headers) as response:
                    if response.status == 200:
                        result = await response.json()
                        if 'result' in result:
                            block_number = int(result['result'], 16)
                            print(f"  ✅ QuickNode API connected")
                            print(f"  ✅ Latest Ethereum block: {block_number:,}")
                            
                            self.results['quicknode']['connection'] = '✅ Success'
                            self.results['quicknode']['latest_block'] = block_number
                            return True
                        else:
                            print(f"  ❌ QuickNode API error: {result.get('error', 'Unknown error')}")
                            self.results['quicknode']['connection'] = f"❌ API Error: {result.get('error', 'Unknown error')}"
                            return False
                    else:
                        print(f"  ❌ QuickNode API HTTP error: {response.status}")
                        self.results['quicknode']['connection'] = f"❌ HTTP {response.status}"
                        return False
                        
        except Exception as e:
            print(f"  ❌ QuickNode API connection failed: {e}")
            self.results['quicknode']['connection'] = f"❌ Failed: {str(e)}"
            return False
    
    async def test_network_endpoints(self):
        """Test all network endpoints"""
        print("\n🔍 Testing Network Endpoints...")
        
        connector = aiohttp.TCPConnector(ssl=False)
        timeout = aiohttp.ClientTimeout(total=30)
        
        async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
            for network_name, network_key in self.test_networks.items():
                try:
                    url = self._get_network_url(network_key)
                    headers = {
                        'Content-Type': 'application/json',
                        'Authorization': f'Bearer {self.api_key}'
                    }
                    
                    payload = {
                        'jsonrpc': '2.0',
                        'id': 1,
                        'method': 'eth_blockNumber',
                        'params': []
                    }
                    
                    async with session.post(url, json=payload, headers=headers) as response:
                        if response.status == 200:
                            result = await response.json()
                            if 'result' in result:
                                block_number = int(result['result'], 16)
                                print(f"  ✅ {network_name}: {block_number:,}")
                                self.results['networks'][network_name] = {
                                    'status': '✅ Working',
                                    'latest_block': block_number
                                }
                            else:
                                print(f"  ❌ {network_name}: API Error")
                                self.results['networks'][network_name] = {
                                    'status': '❌ API Error',
                                    'error': result.get('error', 'Unknown error')
                                }
                        else:
                            print(f"  ❌ {network_name}: HTTP {response.status}")
                            self.results['networks'][network_name] = {
                                'status': f'❌ HTTP {response.status}',
                                'error': f'HTTP {response.status}'
                            }
                    
                    # Small delay between requests
                    await asyncio.sleep(0.1)
                    
                except Exception as e:
                    print(f"  ❌ {network_name}: {e}")
                    self.results['networks'][network_name] = {
                        'status': '❌ Failed',
                        'error': str(e)
                    }
    
    def print_summary(self):
        """Print test summary"""
        print("\n" + "="*60)
        print("📊 QUICKNODE SETUP TEST SUMMARY")
        print("="*60)
        
        # Environment
        print("\n🔧 Environment Configuration:")
        env_success = all('✅' in status for status in self.results['environment'].values())
        print(f"  Status: {'✅ All variables set' if env_success else '❌ Missing variables'}")
        
        # Database
        print("\n🗄️ Database Connection:")
        db_success = '✅' in self.results['database'].get('connection', '')
        print(f"  Status: {self.results['database'].get('connection', '❌ Not tested')}")
        if db_success:
            print(f"  Database: {self.results['database'].get('name', 'Unknown')}")
            print(f"  Version: {self.results['database'].get('version', 'Unknown')}")
        
        # QuickNode API
        print("\n🌐 QuickNode API:")
        qn_success = '✅' in self.results['quicknode'].get('connection', '')
        print(f"  Status: {self.results['quicknode'].get('connection', '❌ Not tested')}")
        if qn_success:
            print(f"  Latest Block: {self.results['quicknode'].get('latest_block', 'Unknown'):,}")
        
        # Networks
        print("\n🌍 Network Endpoints:")
        working_networks = [name for name, data in self.results['networks'].items() 
                          if '✅' in data.get('status', '')]
        total_networks = len(self.results['networks'])
        
        print(f"  Working: {len(working_networks)}/{total_networks}")
        for network_name, data in self.results['networks'].items():
            status_icon = "✅" if "✅" in data.get('status', '') else "❌"
            print(f"    {status_icon} {network_name}: {data.get('status', 'Unknown')}")
        
        # Overall status
        print("\n🎯 Overall Status:")
        if env_success and db_success and qn_success and len(working_networks) > 0:
            print("  ✅ Setup is ready for data collection!")
            print(f"  📈 {len(working_networks)} networks available for collection")
        else:
            print("  ❌ Setup needs attention before data collection")
            if not env_success:
                print("    - Fix environment variables")
            if not db_success:
                print("    - Fix database connection")
            if not qn_success:
                print("    - Fix QuickNode API connection")
            if len(working_networks) == 0:
                print("    - No working network endpoints")
        
        # Save results
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        results_file = f"quicknode_setup_test_{timestamp}.json"
        with open(results_file, 'w') as f:
            json.dump(self.results, f, indent=2, default=str)
        
        print(f"\n💾 Test results saved to: {results_file}")
    
    async def run_all_tests(self):
        """Run all tests"""
        print("🚀 QuickNode Setup Test")
        print("="*40)
        
        # Test environment
        if not self.test_environment():
            print("\n❌ Environment test failed. Please fix environment variables.")
            return False
        
        # Test database
        if not await self.test_database_connection():
            print("\n❌ Database test failed. Please check database configuration.")
            return False
        
        # Test QuickNode API
        if not await self.test_quicknode_api():
            print("\n❌ QuickNode API test failed. Please check API configuration.")
            return False
        
        # Test network endpoints
        await self.test_network_endpoints()
        
        # Print summary
        self.print_summary()
        
        return True

async def main():
    """Main function"""
    tester = QuickNodeSetupTester()
    await tester.run_all_tests()

if __name__ == "__main__":
    asyncio.run(main())
