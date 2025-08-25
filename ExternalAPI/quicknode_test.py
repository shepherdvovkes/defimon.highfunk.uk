#!/usr/bin/env python3
"""
QuickNode API Testing Utility
Tests both HTTP and WebSocket endpoints for multinet access
"""

import asyncio
import json
import time
import websockets
import requests
import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from datetime import datetime
import os
from dotenv import load_dotenv
from config import get_quicknode_config, TEST_CONFIG, RPC_METHODS, SUBSCRIPTION_TESTS

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('quicknode_test.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class QuickNodeConfig:
    """Configuration for QuickNode endpoints"""
    http_url: str
    ws_url: str
    name: str = "QuickNode"

@dataclass
class TestResult:
    """Result of an API test"""
    endpoint: str
    method: str
    success: bool
    response_time: float
    error: Optional[str] = None
    data: Optional[Dict] = None
    timestamp: datetime = None

    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now()

class QuickNodeTester:
    """Comprehensive QuickNode API testing utility"""
    
    def __init__(self, config: QuickNodeConfig):
        self.config = config
        self.results: List[TestResult] = []
        
        # Use RPC methods from config
        self.rpc_methods = RPC_METHODS

    def test_http_endpoint(self, method: str, params: List = None) -> TestResult:
        """Test HTTP RPC endpoint"""
        start_time = time.time()
        
        try:
            payload = {
                "jsonrpc": "2.0",
                "method": method,
                "params": params or [],
                "id": 1
            }
            
            headers = {
                "Content-Type": "application/json",
                "Accept": "application/json"
            }
            
            response = requests.post(
                self.config.http_url,
                json=payload,
                headers=headers,
                timeout=30
            )
            
            response_time = time.time() - start_time
            
            if response.status_code == 200:
                data = response.json()
                if "error" in data:
                    return TestResult(
                        endpoint=self.config.http_url,
                        method=method,
                        success=False,
                        response_time=response_time,
                        error=f"RPC Error: {data['error']}",
                        data=data
                    )
                else:
                    return TestResult(
                        endpoint=self.config.http_url,
                        method=method,
                        success=True,
                        response_time=response_time,
                        data=data
                    )
            else:
                return TestResult(
                    endpoint=self.config.http_url,
                    method=method,
                    success=False,
                    response_time=response_time,
                    error=f"HTTP {response.status_code}: {response.text}"
                )
                
        except requests.exceptions.Timeout:
            return TestResult(
                endpoint=self.config.http_url,
                method=method,
                success=False,
                response_time=time.time() - start_time,
                error="Request timeout"
            )
        except requests.exceptions.RequestException as e:
            return TestResult(
                endpoint=self.config.http_url,
                method=method,
                success=False,
                response_time=time.time() - start_time,
                error=f"Request error: {str(e)}"
            )
        except Exception as e:
            return TestResult(
                endpoint=self.config.http_url,
                method=method,
                success=False,
                response_time=time.time() - start_time,
                error=f"Unexpected error: {str(e)}"
            )

    async def test_websocket_endpoint(self, method: str, params: List = None) -> TestResult:
        """Test WebSocket RPC endpoint"""
        start_time = time.time()
        
        try:
            payload = {
                "jsonrpc": "2.0",
                "method": method,
                "params": params or [],
                "id": 1
            }
            
            async with websockets.connect(self.config.ws_url) as websocket:
                await websocket.send(json.dumps(payload))
                response = await asyncio.wait_for(websocket.recv(), timeout=30)
                
                response_time = time.time() - start_time
                data = json.loads(response)
                
                if "error" in data:
                    return TestResult(
                        endpoint=self.config.ws_url,
                        method=method,
                        success=False,
                        response_time=response_time,
                        error=f"RPC Error: {data['error']}",
                        data=data
                    )
                else:
                    return TestResult(
                        endpoint=self.config.ws_url,
                        method=method,
                        success=True,
                        response_time=response_time,
                        data=data
                    )
                    
        except asyncio.TimeoutError:
            return TestResult(
                endpoint=self.config.ws_url,
                method=method,
                success=False,
                response_time=time.time() - start_time,
                error="WebSocket timeout"
            )
        except websockets.exceptions.WebSocketException as e:
            return TestResult(
                endpoint=self.config.ws_url,
                method=method,
                success=False,
                response_time=time.time() - start_time,
                error=f"WebSocket error: {str(e)}"
            )
        except Exception as e:
            return TestResult(
                endpoint=self.config.ws_url,
                method=method,
                success=False,
                response_time=time.time() - start_time,
                error=f"Unexpected error: {str(e)}"
            )

    async def test_websocket_subscription(self, method: str = "eth_subscribe", params: List = None) -> TestResult:
        """Test WebSocket subscription for new blocks"""
        start_time = time.time()
        
        if params is None:
            params = ["newHeads"]
        
        try:
            async with websockets.connect(self.config.ws_url) as websocket:
                # Subscribe to new block headers
                subscribe_payload = {
                    "jsonrpc": "2.0",
                    "method": method,
                    "params": params,
                    "id": 1
                }
                
                await websocket.send(json.dumps(subscribe_payload))
                response = await asyncio.wait_for(websocket.recv(), timeout=30)
                data = json.loads(response)
                
                if "error" in data:
                    return TestResult(
                        endpoint=self.config.ws_url,
                        method=method,
                        success=False,
                        response_time=time.time() - start_time,
                        error=f"Subscription error: {data['error']}",
                        data=data
                    )
                
                # Wait for a subscription confirmation
                subscription_id = data.get("result")
                
                # Wait a bit for potential new block notification
                try:
                    await asyncio.wait_for(websocket.recv(), timeout=5.0)
                except asyncio.TimeoutError:
                    # No new block in 5 seconds, but subscription is working
                    pass
                
                # Unsubscribe
                unsubscribe_payload = {
                    "jsonrpc": "2.0",
                    "method": "eth_unsubscribe",
                    "params": [subscription_id],
                    "id": 2
                }
                
                await websocket.send(json.dumps(unsubscribe_payload))
                
                return TestResult(
                    endpoint=self.config.ws_url,
                    method=method,
                    success=True,
                    response_time=time.time() - start_time,
                    data={"subscription_id": subscription_id}
                )
                
        except Exception as e:
            return TestResult(
                endpoint=self.config.ws_url,
                method=method,
                success=False,
                response_time=time.time() - start_time,
                error=f"Subscription error: {str(e)}"
            )

    def run_http_tests(self) -> List[TestResult]:
        """Run all HTTP endpoint tests"""
        logger.info(f"Testing HTTP endpoint: {self.config.http_url}")
        
        results = []
        for rpc_test in self.rpc_methods:
            logger.info(f"Testing HTTP: {rpc_test['description']}")
            result = self.test_http_endpoint(rpc_test["method"], rpc_test["params"])
            results.append(result)
            
            if result.success:
                logger.info(f"✓ HTTP {rpc_test['method']}: {result.response_time:.3f}s")
            else:
                logger.error(f"✗ HTTP {rpc_test['method']}: {result.error}")
        
        return results

    async def run_websocket_tests(self) -> List[TestResult]:
        """Run all WebSocket endpoint tests"""
        logger.info(f"Testing WebSocket endpoint: {self.config.ws_url}")
        
        results = []
        
        # Test basic RPC methods
        for rpc_test in self.rpc_methods:
            logger.info(f"Testing WS: {rpc_test['description']}")
            result = await self.test_websocket_endpoint(rpc_test["method"], rpc_test["params"])
            results.append(result)
            
            if result.success:
                logger.info(f"✓ WS {rpc_test['method']}: {result.response_time:.3f}s")
            else:
                logger.error(f"✗ WS {rpc_test['method']}: {result.error}")
        
        # Test subscriptions if enabled
        if TEST_CONFIG["enable_subscription_tests"]:
            for sub_test in SUBSCRIPTION_TESTS:
                logger.info(f"Testing WS Subscription: {sub_test['description']}")
                sub_result = await self.test_websocket_subscription(sub_test["method"], sub_test["params"])
                results.append(sub_result)
                
                if sub_result.success:
                    logger.info(f"✓ WS {sub_test['method']}: {sub_result.response_time:.3f}s")
                else:
                    logger.error(f"✗ WS {sub_test['method']}: {sub_result.error}")
        
        return results

    async def run_all_tests(self) -> Dict[str, List[TestResult]]:
        """Run all tests for both HTTP and WebSocket endpoints"""
        logger.info(f"Starting comprehensive tests for {self.config.name}")
        
        # Run HTTP tests
        http_results = self.run_http_tests()
        
        # Run WebSocket tests
        ws_results = await self.run_websocket_tests()
        
        all_results = {
            "http": http_results,
            "websocket": ws_results
        }
        
        self.results = http_results + ws_results
        return all_results

    def generate_report(self) -> str:
        """Generate a comprehensive test report"""
        if not self.results:
            return "No test results available"
        
        total_tests = len(self.results)
        successful_tests = sum(1 for r in self.results if r.success)
        failed_tests = total_tests - successful_tests
        
        avg_response_time = sum(r.response_time for r in self.results) / total_tests
        
        report = f"""
{'='*80}
QUICKNODE API TEST REPORT
{'='*80}
Configuration:
  Name: {self.config.name}
  HTTP URL: {self.config.http_url}
  WebSocket URL: {self.config.ws_url}
  Test Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

Summary:
  Total Tests: {total_tests}
  Successful: {successful_tests}
  Failed: {failed_tests}
  Success Rate: {(successful_tests/total_tests)*100:.1f}%
  Average Response Time: {avg_response_time:.3f}s

Detailed Results:
"""
        
        # Group results by endpoint type
        http_results = [r for r in self.results if r.endpoint == self.config.http_url]
        ws_results = [r for r in self.results if r.endpoint == self.config.ws_url]
        
        if http_results:
            report += f"\nHTTP Endpoint Results:\n{'-'*40}\n"
            for result in http_results:
                status = "✓" if result.success else "✗"
                report += f"{status} {result.method}: {result.response_time:.3f}s"
                if not result.success:
                    report += f" (Error: {result.error})"
                report += "\n"
        
        if ws_results:
            report += f"\nWebSocket Endpoint Results:\n{'-'*40}\n"
            for result in ws_results:
                status = "✓" if result.success else "✗"
                report += f"{status} {result.method}: {result.response_time:.3f}s"
                if not result.success:
                    report += f" (Error: {result.error})"
                report += "\n"
        
        # Failed tests details
        failed_results = [r for r in self.results if not r.success]
        if failed_results:
            report += f"\nFailed Tests Details:\n{'-'*40}\n"
            for result in failed_results:
                report += f"• {result.method} ({result.endpoint}): {result.error}\n"
        
        report += f"\n{'='*80}\n"
        return report

    def save_results(self, filename: str = None):
        """Save test results to JSON file"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"quicknode_test_results_{timestamp}.json"
        
        results_data = {
            "config": {
                "name": self.config.name,
                "http_url": self.config.http_url,
                "ws_url": self.config.ws_url
            },
            "test_time": datetime.now().isoformat(),
            "results": [
                {
                    "endpoint": r.endpoint,
                    "method": r.method,
                    "success": r.success,
                    "response_time": r.response_time,
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
    """Main function to run QuickNode tests"""
    
    # Get QuickNode configuration from config file
    quicknode_config = get_quicknode_config()
    config = QuickNodeConfig(
        http_url=quicknode_config.http_url,
        ws_url=quicknode_config.ws_url,
        name=quicknode_config.name
    )
    
    # Create tester instance
    tester = QuickNodeTester(config)
    
    # Run all tests
    async def run_tests():
        results = await tester.run_all_tests()
        
        # Generate and print report
        report = tester.generate_report()
        print(report)
        
        # Save results
        tester.save_results()
        
        return results
    
    # Run the async tests
    asyncio.run(run_tests())

if __name__ == "__main__":
    main()
