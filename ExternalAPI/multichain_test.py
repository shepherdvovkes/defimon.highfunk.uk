#!/usr/bin/env python3
"""
QuickNode Multichain API Testing Utility
Tests multiple blockchain networks through QuickNode's multichain endpoint structure
Based on QuickNode's multichain documentation
"""

import asyncio
import json
import time
import requests
import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from datetime import datetime
import os
from dotenv import load_dotenv
from config import get_quicknode_config, TEST_CONFIG

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('multichain_test.log'),
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

    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now()

class MultichainTester:
    """Multichain API testing utility for QuickNode endpoints"""
    
    def __init__(self, base_endpoint_name: str, token_id: str):
        self.base_endpoint_name = base_endpoint_name
        self.token_id = token_id
        self.results: List[MultichainTestResult] = []
        
        # Define supported networks based on QuickNode documentation
        self.networks = [
            NetworkConfig(
                name="Ethereum",
                network_name="mainnet",
                http_url=f"https://{base_endpoint_name}.quiknode.pro/{token_id}",
                ws_url=f"wss://{base_endpoint_name}.quiknode.pro/{token_id}",
                chain_id=1,
                currency_symbol="ETH"
            ),
            NetworkConfig(
                name="Base",
                network_name="base-mainnet",
                http_url=f"https://{base_endpoint_name}.base-mainnet.quiknode.pro/{token_id}",
                ws_url=f"wss://{base_endpoint_name}.base-mainnet.quiknode.pro/{token_id}",
                chain_id=8453,
                currency_symbol="ETH"
            ),
            NetworkConfig(
                name="Binance Smart Chain",
                network_name="bsc",
                http_url=f"https://{base_endpoint_name}.bsc.quiknode.pro/{token_id}",
                ws_url=f"wss://{base_endpoint_name}.bsc.quiknode.pro/{token_id}",
                chain_id=56,
                currency_symbol="BNB"
            ),
            NetworkConfig(
                name="Avalanche C-Chain",
                network_name="avalanche-mainnet",
                http_url=f"https://{base_endpoint_name}.avalanche-mainnet.quiknode.pro/{token_id}/ext/bc/C/rpc",
                ws_url=f"wss://{base_endpoint_name}.avalanche-mainnet.quiknode.pro/{token_id}/ext/bc/C/ws",
                chain_id=43114,
                currency_symbol="AVAX"
            ),
            NetworkConfig(
                name="Polygon",
                network_name="polygon-mainnet",
                http_url=f"https://{base_endpoint_name}.polygon-mainnet.quiknode.pro/{token_id}",
                ws_url=f"wss://{base_endpoint_name}.polygon-mainnet.quiknode.pro/{token_id}",
                chain_id=137,
                currency_symbol="MATIC"
            ),
            NetworkConfig(
                name="Arbitrum One",
                network_name="arbitrum-one",
                http_url=f"https://{base_endpoint_name}.arbitrum-one.quiknode.pro/{token_id}",
                ws_url=f"wss://{base_endpoint_name}.arbitrum-one.quiknode.pro/{token_id}",
                chain_id=42161,
                currency_symbol="ETH"
            ),
            NetworkConfig(
                name="Optimism",
                network_name="optimism-mainnet",
                http_url=f"https://{base_endpoint_name}.optimism-mainnet.quiknode.pro/{token_id}",
                ws_url=f"wss://{base_endpoint_name}.optimism-mainnet.quiknode.pro/{token_id}",
                chain_id=10,
                currency_symbol="ETH"
            )
        ]

    def test_network_endpoint(self, network: NetworkConfig) -> MultichainTestResult:
        """Test a single network endpoint"""
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
            
            response = requests.post(
                network.http_url,
                json=payload,
                headers=headers,
                timeout=30
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
                        data=data
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
                        data=data
                    )
            else:
                return MultichainTestResult(
                    network=network.name,
                    endpoint=network.http_url,
                    method="eth_blockNumber",
                    success=False,
                    response_time=response_time,
                    error=f"HTTP {response.status_code}: {response.text}"
                )
                
        except requests.exceptions.Timeout:
            return MultichainTestResult(
                network=network.name,
                endpoint=network.http_url,
                method="eth_blockNumber",
                success=False,
                response_time=time.time() - start_time,
                error="Request timeout"
            )
        except requests.exceptions.RequestException as e:
            return MultichainTestResult(
                network=network.name,
                endpoint=network.http_url,
                method="eth_blockNumber",
                success=False,
                response_time=time.time() - start_time,
                error=f"Request error: {str(e)}"
            )
        except Exception as e:
            return MultichainTestResult(
                network=network.name,
                endpoint=network.http_url,
                method="eth_blockNumber",
                success=False,
                response_time=time.time() - start_time,
                error=f"Unexpected error: {str(e)}"
            )

    def test_network_chain_id(self, network: NetworkConfig) -> MultichainTestResult:
        """Test chain ID for a network"""
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
                timeout=30
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
                        data=data
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
                        data=data
                    )
            else:
                return MultichainTestResult(
                    network=network.name,
                    endpoint=network.http_url,
                    method="eth_chainId",
                    success=False,
                    response_time=response_time,
                    error=f"HTTP {response.status_code}: {response.text}"
                )
                
        except Exception as e:
            return MultichainTestResult(
                network=network.name,
                endpoint=network.http_url,
                method="eth_chainId",
                success=False,
                response_time=time.time() - start_time,
                error=f"Unexpected error: {str(e)}"
            )

    def run_multichain_tests(self) -> List[MultichainTestResult]:
        """Run tests for all configured networks"""
        logger.info(f"Starting multichain tests for {len(self.networks)} networks")
        
        results = []
        
        for network in self.networks:
            logger.info(f"Testing {network.name} ({network.network_name})")
            
            # Test block number
            block_result = self.test_network_endpoint(network)
            results.append(block_result)
            
            if block_result.success:
                logger.info(f"✓ {network.name}: Block {block_result.block_number} in {block_result.response_time:.3f}s")
            else:
                logger.error(f"✗ {network.name}: {block_result.error}")
            
            # Test chain ID
            chain_result = self.test_network_chain_id(network)
            results.append(chain_result)
            
            if chain_result.success:
                logger.info(f"✓ {network.name}: Chain ID verified in {chain_result.response_time:.3f}s")
            else:
                logger.error(f"✗ {network.name} Chain ID: {chain_result.error}")
        
        self.results = results
        return results

    def generate_report(self) -> str:
        """Generate a comprehensive multichain test report"""
        if not self.results:
            return "No test results available"
        
        total_tests = len(self.results)
        successful_tests = sum(1 for r in self.results if r.success)
        failed_tests = total_tests - successful_tests
        
        # Group results by network
        network_results = {}
        for result in self.results:
            if result.network not in network_results:
                network_results[result.network] = []
            network_results[result.network].append(result)
        
        avg_response_time = sum(r.response_time for r in self.results) / total_tests
        
        report = f"""
{'='*80}
QUICKNODE MULTICHAIN API TEST REPORT
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
  Average Response Time: {avg_response_time:.3f}s

Network Results:
"""
        
        for network_name, results in network_results.items():
            network_success = sum(1 for r in results if r.success)
            network_total = len(results)
            network_avg_time = sum(r.response_time for r in results) / network_total
            
            report += f"\n{network_name}:\n{'-' * (len(network_name) + 1)}\n"
            report += f"  Success Rate: {(network_success/network_total)*100:.1f}% ({network_success}/{network_total})\n"
            report += f"  Average Response Time: {network_avg_time:.3f}s\n"
            
            for result in results:
                status = "✓" if result.success else "✗"
                if result.method == "eth_blockNumber" and result.block_number:
                    report += f"  {status} {result.method}: Block {result.block_number} ({result.response_time:.3f}s)\n"
                else:
                    report += f"  {status} {result.method}: {result.response_time:.3f}s"
                    if not result.success:
                        report += f" (Error: {result.error})"
                    report += "\n"
        
        # Failed tests summary
        failed_results = [r for r in self.results if not r.success]
        if failed_results:
            report += f"\nFailed Tests Summary:\n{'-'*40}\n"
            for result in failed_results:
                report += f"• {result.network} - {result.method}: {result.error}\n"
        
        report += f"\n{'='*80}\n"
        return report

    def save_results(self, filename: str = None):
        """Save test results to JSON file"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"multichain_test_results_{timestamp}.json"
        
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
                    "timestamp": r.timestamp.isoformat()
                }
                for r in self.results
            ]
        }
        
        with open(filename, 'w') as f:
            json.dump(results_data, f, indent=2)
        
        logger.info(f"Results saved to {filename}")

def main():
    """Main function to run multichain tests"""
    
    # Extract endpoint name and token from the provided URL
    # Example: https://hidden-holy-seed.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b
    # Endpoint name: hidden-holy-seed
    # Token ID: 97d6d8e7659b49b126c43455edc4607949bfb52b
    
    endpoint_name = "hidden-holy-seed"
    token_id = "97d6d8e7659b49b126c43455edc4607949bfb52b"
    
    # Create multichain tester
    tester = MultichainTester(endpoint_name, token_id)
    
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
