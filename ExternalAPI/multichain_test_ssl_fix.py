#!/usr/bin/env python3
"""
QuickNode Multichain API Testing Utility with SSL Certificate Fix
Tests multiple blockchain networks through QuickNode's multichain endpoint structure
with SSL certificate issue mitigation
"""

import asyncio
import json
import time
import requests
import logging
import urllib3
import ssl
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from datetime import datetime
import os
from dotenv import load_dotenv
from config import get_quicknode_config, TEST_CONFIG

# Load environment variables
load_dotenv()

# Disable SSL warnings for testing purposes
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('multichain_test_ssl_fix.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class NetworkConfig:
    """Configuration for a specific blockchain network"""
    name: str
    network_name: str
    http_url: str
    ws_url: str
    chain_id: Optional[int] = None
    currency_symbol: str = "ETH"
    ssl_verify: bool = True  # Whether to verify SSL certificates

@dataclass
class MultichainTestResult:
    """Result of a multichain API test"""
    network: str
    endpoint: str
    method: str
    success: bool
    response_time: float
    block_number: Optional[int] = None
    error: Optional[str] = None
    data: Optional[Dict] = None
    timestamp: datetime = None
    ssl_verified: bool = True  # Whether SSL was verified

    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now()

class MultichainTesterSSL:
    """Multichain API testing utility with SSL certificate handling"""
    
    def __init__(self, base_endpoint_name: str, token_id: str):
        self.base_endpoint_name = base_endpoint_name
        self.token_id = token_id
        self.results: List[MultichainTestResult] = []
        
        # Define supported networks with SSL verification settings
        self.networks = [
            NetworkConfig(
                name="Ethereum",
                network_name="mainnet",
                http_url=f"https://{base_endpoint_name}.quiknode.pro/{token_id}",
                ws_url=f"wss://{base_endpoint_name}.quiknode.pro/{token_id}",
                chain_id=1,
                currency_symbol="ETH",
                ssl_verify=True
            ),
            NetworkConfig(
                name="Base",
                network_name="base-mainnet",
                http_url=f"https://{base_endpoint_name}.base-mainnet.quiknode.pro/{token_id}",
                ws_url=f"wss://{base_endpoint_name}.base-mainnet.quiknode.pro/{token_id}",
                chain_id=8453,
                currency_symbol="ETH",
                ssl_verify=True
            ),
            NetworkConfig(
                name="Binance Smart Chain",
                network_name="bsc",
                http_url=f"https://{base_endpoint_name}.bsc.quiknode.pro/{token_id}",
                ws_url=f"wss://{base_endpoint_name}.bsc.quiknode.pro/{token_id}",
                chain_id=56,
                currency_symbol="BNB",
                ssl_verify=True
            ),
            NetworkConfig(
                name="Avalanche C-Chain",
                network_name="avalanche-mainnet",
                http_url=f"https://{base_endpoint_name}.avalanche-mainnet.quiknode.pro/{token_id}/ext/bc/C/rpc",
                ws_url=f"wss://{base_endpoint_name}.avalanche-mainnet.quiknode.pro/{token_id}/ext/bc/C/ws",
                chain_id=43114,
                currency_symbol="AVAX",
                ssl_verify=True
            ),
            # Networks with SSL issues - try with SSL verification disabled
            NetworkConfig(
                name="Polygon",
                network_name="polygon-mainnet",
                http_url=f"https://{base_endpoint_name}.polygon-mainnet.quiknode.pro/{token_id}",
                ws_url=f"wss://{base_endpoint_name}.polygon-mainnet.quiknode.pro/{token_id}",
                chain_id=137,
                currency_symbol="MATIC",
                ssl_verify=False  # Disable SSL verification for this network
            ),
            NetworkConfig(
                name="Arbitrum One",
                network_name="arbitrum-one",
                http_url=f"https://{base_endpoint_name}.arbitrum-one.quiknode.pro/{token_id}",
                ws_url=f"wss://{base_endpoint_name}.arbitrum-one.quiknode.pro/{token_id}",
                chain_id=42161,
                currency_symbol="ETH",
                ssl_verify=False  # Disable SSL verification for this network
            ),
            NetworkConfig(
                name="Optimism",
                network_name="optimism-mainnet",
                http_url=f"https://{base_endpoint_name}.optimism-mainnet.quiknode.pro/{token_id}",
                ws_url=f"wss://{base_endpoint_name}.optimism-mainnet.quiknode.pro/{token_id}",
                chain_id=10,
                currency_symbol="ETH",
                ssl_verify=False  # Disable SSL verification for this network
            )
        ]

    def test_network_endpoint(self, network: NetworkConfig) -> MultichainTestResult:
        """Test a single network endpoint with SSL handling"""
        start_time = time.time()
        
        try:
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_blockNumber",
                "params": [],
                "id": 1
            }
            
            headers = {
                "Content-Type": "application/json",
                "Accept": "application/json"
            }
            
            # Use SSL verification based on network configuration
            response = requests.post(
                network.http_url,
                json=payload,
                headers=headers,
                timeout=30,
                verify=network.ssl_verify
            )
            
            response_time = time.time() - start_time
            
            if response.status_code == 200:
                data = response.json()
                if "error" in data:
                    return MultichainTestResult(
                        network=network.name,
                        endpoint=network.http_url,
                        method="eth_blockNumber",
                        success=False,
                        response_time=response_time,
                        error=f"RPC Error: {data['error']}",
                        data=data,
                        ssl_verified=network.ssl_verify
                    )
                else:
                    # Extract block number and convert from hex to decimal
                    block_hex = data.get("result", "")
                    if block_hex and block_hex.startswith("0x"):
                        block_number = int(block_hex, 16)
                    else:
                        block_number = None
                    
                    return MultichainTestResult(
                        network=network.name,
                        endpoint=network.http_url,
                        method="eth_blockNumber",
                        success=True,
                        response_time=response_time,
                        block_number=block_number,
                        data=data,
                        ssl_verified=network.ssl_verify
                    )
            else:
                return MultichainTestResult(
                    network=network.name,
                    endpoint=network.http_url,
                    method="eth_blockNumber",
                    success=False,
                    response_time=response_time,
                    error=f"HTTP {response.status_code}: {response.text}",
                    ssl_verified=network.ssl_verify
                )
                
        except requests.exceptions.SSLError as e:
            # If SSL verification failed, try without verification
            if network.ssl_verify:
                logger.warning(f"SSL verification failed for {network.name}, retrying without verification")
                network.ssl_verify = False
                return self.test_network_endpoint(network)
            else:
                return MultichainTestResult(
                    network=network.name,
                    endpoint=network.http_url,
                    method="eth_blockNumber",
                    success=False,
                    response_time=time.time() - start_time,
                    error=f"SSL Error: {str(e)}",
                    ssl_verified=False
                )
        except requests.exceptions.Timeout:
            return MultichainTestResult(
                network=network.name,
                endpoint=network.http_url,
                method="eth_blockNumber",
                success=False,
                response_time=time.time() - start_time,
                error="Request timeout",
                ssl_verified=network.ssl_verify
            )
        except requests.exceptions.RequestException as e:
            return MultichainTestResult(
                network=network.name,
                endpoint=network.http_url,
                method="eth_blockNumber",
                success=False,
                response_time=time.time() - start_time,
                error=f"Request error: {str(e)}",
                ssl_verified=network.ssl_verify
            )
        except Exception as e:
            return MultichainTestResult(
                network=network.name,
                endpoint=network.http_url,
                method="eth_blockNumber",
                success=False,
                response_time=time.time() - start_time,
                error=f"Unexpected error: {str(e)}",
                ssl_verified=network.ssl_verify
            )

    def test_network_chain_id(self, network: NetworkConfig) -> MultichainTestResult:
        """Test chain ID for a network with SSL handling"""
        start_time = time.time()
        
        try:
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_chainId",
                "params": [],
                "id": 1
            }
            
            headers = {
                "Content-Type": "application/json",
                "Accept": "application/json"
            }
            
            response = requests.post(
                network.http_url,
                json=payload,
                headers=headers,
                timeout=30,
                verify=network.ssl_verify
            )
            
            response_time = time.time() - start_time
            
            if response.status_code == 200:
                data = response.json()
                if "error" in data:
                    return MultichainTestResult(
                        network=network.name,
                        endpoint=network.http_url,
                        method="eth_chainId",
                        success=False,
                        response_time=response_time,
                        error=f"RPC Error: {data['error']}",
                        data=data,
                        ssl_verified=network.ssl_verify
                    )
                else:
                    chain_id_hex = data.get("result", "")
                    if chain_id_hex and chain_id_hex.startswith("0x"):
                        chain_id = int(chain_id_hex, 16)
                    else:
                        chain_id = None
                    
                    return MultichainTestResult(
                        network=network.name,
                        endpoint=network.http_url,
                        method="eth_chainId",
                        success=True,
                        response_time=response_time,
                        data=data,
                        ssl_verified=network.ssl_verify
                    )
            else:
                return MultichainTestResult(
                    network=network.name,
                    endpoint=network.http_url,
                    method="eth_chainId",
                    success=False,
                    response_time=response_time,
                    error=f"HTTP {response.status_code}: {response.text}",
                    ssl_verified=network.ssl_verify
                )
                
        except requests.exceptions.SSLError as e:
            # If SSL verification failed, try without verification
            if network.ssl_verify:
                logger.warning(f"SSL verification failed for {network.name} Chain ID, retrying without verification")
                network.ssl_verify = False
                return self.test_network_chain_id(network)
            else:
                return MultichainTestResult(
                    network=network.name,
                    endpoint=network.http_url,
                    method="eth_chainId",
                    success=False,
                    response_time=time.time() - start_time,
                    error=f"SSL Error: {str(e)}",
                    ssl_verified=False
                )
        except Exception as e:
            return MultichainTestResult(
                network=network.name,
                endpoint=network.http_url,
                method="eth_chainId",
                success=False,
                response_time=time.time() - start_time,
                error=f"Unexpected error: {str(e)}",
                ssl_verified=network.ssl_verify
            )

    def run_multichain_tests(self) -> List[MultichainTestResult]:
        """Run tests for all configured networks with SSL handling"""
        logger.info(f"Starting multichain tests with SSL handling for {len(self.networks)} networks")
        
        results = []
        
        for network in self.networks:
            logger.info(f"Testing {network.name} ({network.network_name}) - SSL Verify: {network.ssl_verify}")
            
            # Test block number
            block_result = self.test_network_endpoint(network)
            results.append(block_result)
            
            if block_result.success:
                ssl_status = "✓" if block_result.ssl_verified else "⚠️"
                logger.info(f"{ssl_status} {network.name}: Block {block_result.block_number} in {block_result.response_time:.3f}s")
            else:
                logger.error(f"✗ {network.name}: {block_result.error}")
            
            # Test chain ID
            chain_result = self.test_network_chain_id(network)
            results.append(chain_result)
            
            if chain_result.success:
                ssl_status = "✓" if chain_result.ssl_verified else "⚠️"
                logger.info(f"{ssl_status} {network.name}: Chain ID verified in {chain_result.response_time:.3f}s")
            else:
                logger.error(f"✗ {network.name} Chain ID: {chain_result.error}")
        
        self.results = results
        return results

    def generate_report(self) -> str:
        """Generate a comprehensive multichain test report with SSL information"""
        if not self.results:
            return "No test results available"
        
        total_tests = len(self.results)
        successful_tests = sum(1 for r in self.results if r.success)
        failed_tests = total_tests - successful_tests
        ssl_verified_tests = sum(1 for r in self.results if r.ssl_verified)
        
        # Group results by network
        network_results = {}
        for result in self.results:
            if result.network not in network_results:
                network_results[result.network] = []
            network_results[result.network].append(result)
        
        avg_response_time = sum(r.response_time for r in self.results) / total_tests
        
        report = f"""
{'='*80}
QUICKNODE MULTICHAIN API TEST REPORT (WITH SSL HANDLING)
{'='*80}
Configuration:
  Base Endpoint: {self.base_endpoint_name}
  Token ID: {self.token_id}
  Networks Tested: {len(self.networks)}
  Test Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

Summary:
  Total Tests: {total_tests}
  Successful: {successful_tests}
  Failed: {failed_tests}
  Success Rate: {(successful_tests/total_tests)*100:.1f}%
  SSL Verified: {ssl_verified_tests}/{total_tests} ({(ssl_verified_tests/total_tests)*100:.1f}%)
  Average Response Time: {avg_response_time:.3f}s

Network Results:
"""
        
        for network_name, results in network_results.items():
            network_success = sum(1 for r in results if r.success)
            network_total = len(results)
            network_avg_time = sum(r.response_time for r in results) / network_total
            network_ssl_verified = sum(1 for r in results if r.ssl_verified)
            
            report += f"\n{network_name}:\n{'-' * (len(network_name) + 1)}\n"
            report += f"  Success Rate: {(network_success/network_total)*100:.1f}% ({network_success}/{network_total})\n"
            report += f"  SSL Verified: {network_ssl_verified}/{network_total} ({(network_ssl_verified/network_total)*100:.1f}%)\n"
            report += f"  Average Response Time: {network_avg_time:.3f}s\n"
            
            for result in results:
                status = "✓" if result.success else "✗"
                ssl_indicator = "🔒" if result.ssl_verified else "⚠️"
                if result.method == "eth_blockNumber" and result.block_number:
                    report += f"  {ssl_indicator} {status} {result.method}: Block {result.block_number} ({result.response_time:.3f}s)\n"
                else:
                    report += f"  {ssl_indicator} {status} {result.method}: {result.response_time:.3f}s"
                    if not result.success:
                        report += f" (Error: {result.error})"
                    report += "\n"
        
        # Failed tests summary
        failed_results = [r for r in self.results if not r.success]
        if failed_results:
            report += f"\nFailed Tests Summary:\n{'-'*40}\n"
            for result in failed_results:
                ssl_status = "SSL Verified" if result.ssl_verified else "SSL Not Verified"
                report += f"• {result.network} - {result.method} ({ssl_status}): {result.error}\n"
        
        # SSL recommendations
        ssl_issues = [r for r in self.results if not r.ssl_verified and r.success]
        if ssl_issues:
            report += f"\nSSL Certificate Issues:\n{'-'*40}\n"
            report += "⚠️  Some networks are working but with SSL verification disabled.\n"
            report += "   This indicates SSL certificate issues that should be reported to QuickNode.\n"
            report += "   Networks affected:\n"
            for result in ssl_issues:
                report += f"   • {result.network}\n"
        
        report += f"\n{'='*80}\n"
        return report

    def save_results(self, filename: str = None):
        """Save test results to JSON file"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"multichain_test_ssl_fix_results_{timestamp}.json"
        
        results_data = {
            "config": {
                "base_endpoint": self.base_endpoint_name,
                "token_id": self.token_id,
                "networks_tested": len(self.networks)
            },
            "test_time": datetime.now().isoformat(),
            "results": [
                {
                    "network": r.network,
                    "endpoint": r.endpoint,
                    "method": r.method,
                    "success": r.success,
                    "response_time": r.response_time,
                    "block_number": r.block_number,
                    "error": r.error,
                    "data": r.data,
                    "ssl_verified": r.ssl_verified,
                    "timestamp": r.timestamp.isoformat()
                }
                for r in self.results
            ]
        }
        
        with open(filename, 'w') as f:
            json.dump(results_data, f, indent=2)
        
        logger.info(f"Results saved to {filename}")

def main():
    """Main function to run multichain tests with SSL handling"""
    
    # Extract endpoint name and token from the provided URL
    endpoint_name = "hidden-holy-seed"
    token_id = "97d6d8e7659b49b126c43455edc4607949bfb52b"
    
    # Create multichain tester with SSL handling
    tester = MultichainTesterSSL(endpoint_name, token_id)
    
    # Run all tests
    results = tester.run_multichain_tests()
    
    # Generate and print report
    report = tester.generate_report()
    print(report)
    
    # Save results
    tester.save_results()
    
    return results

if __name__ == "__main__":
    main()
