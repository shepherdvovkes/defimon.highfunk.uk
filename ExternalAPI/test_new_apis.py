#!/usr/bin/env python3
"""
Comprehensive test suite for new API services
Tests QuickNode, Blast, CoinGecko, CoinCap, and GitHub APIs
"""

import os
import sys
import json
import time
import logging
import requests
import websocket
from datetime import datetime
from typing import Dict, Any, List, Optional
from dataclasses import asdict

# Add current directory to path for imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from config_new_apis import (
    get_quicknode_config, get_blast_config, get_coingecko_config,
    get_coincap_config, get_github_config, TEST_CONFIG,
    QUICKNODE_RPC_METHODS, BLAST_RPC_METHODS, COINGECKO_API_ENDPOINTS,
    COINCAP_API_ENDPOINTS, GITHUB_API_ENDPOINTS
)

# Configure logging
logging.basicConfig(
    level=getattr(logging, TEST_CONFIG["log_level"]),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class APITester:
    """Base class for API testing"""
    
    def __init__(self, config, service_name: str):
        self.config = config
        self.service_name = service_name
        self.session = requests.Session()
        self.session.timeout = config.timeout
        if config.headers:
            self.session.headers.update(config.headers)
        
    def test_connectivity(self) -> Dict[str, Any]:
        """Test basic connectivity to the API"""
        try:
            start_time = time.time()
            response = self.session.get(f"{self.config.base_url}/ping" if hasattr(self.config, 'base_url') else self.config.http_url)
            end_time = time.time()
            
            return {
                "success": response.status_code == 200,
                "status_code": response.status_code,
                "response_time": round(end_time - start_time, 3),
                "response": response.text[:200] if response.text else None
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "response_time": None
            }

class QuickNodeTester(APITester):
    """QuickNode API tester"""
    
    def __init__(self):
        config = get_quicknode_config()
        super().__init__(config, "QuickNode")
        
    def test_rpc_methods(self) -> List[Dict[str, Any]]:
        """Test QuickNode RPC methods"""
        results = []
        
        for method_config in QUICKNODE_RPC_METHODS:
            try:
                payload = {
                    "jsonrpc": "2.0",
                    "method": method_config["method"],
                    "params": method_config["params"],
                    "id": 1
                }
                
                start_time = time.time()
                response = self.session.post(
                    self.config.http_url,
                    json=payload,
                    headers={"Content-Type": "application/json"}
                )
                end_time = time.time()
                
                result = {
                    "method": method_config["method"],
                    "description": method_config["description"],
                    "success": response.status_code == 200,
                    "status_code": response.status_code,
                    "response_time": round(end_time - start_time, 3),
                    "response": response.json() if response.status_code == 200 else None
                }
                
                if response.status_code != 200:
                    result["error"] = response.text
                    
            except Exception as e:
                result = {
                    "method": method_config["method"],
                    "description": method_config["description"],
                    "success": False,
                    "error": str(e),
                    "response_time": None
                }
            
            results.append(result)
            logger.info(f"QuickNode RPC test: {method_config['method']} - {'SUCCESS' if result['success'] else 'FAILED'}")
            
        return results

class BlastTester(APITester):
    """Blast API tester"""
    
    def __init__(self):
        config = get_blast_config()
        super().__init__(config, "Blast")
        
    def test_rpc_methods(self) -> List[Dict[str, Any]]:
        """Test Blast RPC methods"""
        results = []
        
        for method_config in BLAST_RPC_METHODS:
            try:
                payload = {
                    "jsonrpc": "2.0",
                    "method": method_config["method"],
                    "params": method_config["params"],
                    "id": 1
                }
                
                start_time = time.time()
                response = self.session.post(
                    self.config.base_url,
                    json=payload,
                    headers={"Content-Type": "application/json"}
                )
                end_time = time.time()
                
                result = {
                    "method": method_config["method"],
                    "description": method_config["description"],
                    "success": response.status_code == 200,
                    "status_code": response.status_code,
                    "response_time": round(end_time - start_time, 3),
                    "response": response.json() if response.status_code == 200 else None
                }
                
                if response.status_code != 200:
                    result["error"] = response.text
                    
            except Exception as e:
                result = {
                    "method": method_config["method"],
                    "description": method_config["description"],
                    "success": False,
                    "error": str(e),
                    "response_time": None
                }
            
            results.append(result)
            logger.info(f"Blast RPC test: {method_config['method']} - {'SUCCESS' if result['success'] else 'FAILED'}")
            
        return results

class CoinGeckoTester(APITester):
    """CoinGecko API tester"""
    
    def __init__(self):
        config = get_coingecko_config()
        super().__init__(config, "CoinGecko")
        
    def test_endpoints(self) -> List[Dict[str, Any]]:
        """Test CoinGecko API endpoints"""
        results = []
        
        for endpoint_config in COINGECKO_API_ENDPOINTS:
            try:
                endpoint = endpoint_config["endpoint"]
                method = endpoint_config["method"]
                params = endpoint_config.get("params", {})
                
                url = f"{self.config.base_url}{endpoint}"
                
                start_time = time.time()
                if method == "GET":
                    response = self.session.get(url, params=params)
                else:
                    response = self.session.post(url, json=params)
                end_time = time.time()
                
                result = {
                    "endpoint": endpoint,
                    "method": method,
                    "description": endpoint_config["description"],
                    "success": response.status_code in [200, 201],
                    "status_code": response.status_code,
                    "response_time": round(end_time - start_time, 3),
                    "response": response.json() if response.status_code in [200, 201] else None
                }
                
                if response.status_code not in [200, 201]:
                    result["error"] = response.text
                    
            except Exception as e:
                result = {
                    "endpoint": endpoint_config["endpoint"],
                    "method": endpoint_config["method"],
                    "description": endpoint_config["description"],
                    "success": False,
                    "error": str(e),
                    "response_time": None
                }
            
            results.append(result)
            logger.info(f"CoinGecko API test: {endpoint_config['endpoint']} - {'SUCCESS' if result['success'] else 'FAILED'}")
            
        return results

class CoinCapTester(APITester):
    """CoinCap API tester"""
    
    def __init__(self):
        config = get_coincap_config()
        super().__init__(config, "CoinCap")
        
    def test_endpoints(self) -> List[Dict[str, Any]]:
        """Test CoinCap API endpoints"""
        results = []
        
        for endpoint_config in COINCAP_API_ENDPOINTS:
            try:
                endpoint = endpoint_config["endpoint"]
                method = endpoint_config["method"]
                
                url = f"{self.config.base_url}{endpoint}"
                
                start_time = time.time()
                if method == "GET":
                    response = self.session.get(url)
                else:
                    response = self.session.post(url)
                end_time = time.time()
                
                result = {
                    "endpoint": endpoint,
                    "method": method,
                    "description": endpoint_config["description"],
                    "success": response.status_code in [200, 201],
                    "status_code": response.status_code,
                    "response_time": round(end_time - start_time, 3),
                    "response": response.json() if response.status_code in [200, 201] else None
                }
                
                if response.status_code not in [200, 201]:
                    result["error"] = response.text
                    
            except Exception as e:
                result = {
                    "endpoint": endpoint_config["endpoint"],
                    "method": endpoint_config["method"],
                    "description": endpoint_config["description"],
                    "success": False,
                    "error": str(e),
                    "response_time": None
                }
            
            results.append(result)
            logger.info(f"CoinCap API test: {endpoint_config['endpoint']} - {'SUCCESS' if result['success'] else 'FAILED'}")
            
        return results

class GitHubTester(APITester):
    """GitHub API tester"""
    
    def __init__(self):
        config = get_github_config()
        super().__init__(config, "GitHub")
        
    def test_endpoints(self) -> List[Dict[str, Any]]:
        """Test GitHub API endpoints"""
        results = []
        
        for endpoint_config in GITHUB_API_ENDPOINTS:
            try:
                endpoint = endpoint_config["endpoint"]
                method = endpoint_config["method"]
                params = endpoint_config.get("params", {})
                
                url = f"{self.config.base_url}{endpoint}"
                
                start_time = time.time()
                if method == "GET":
                    response = self.session.get(url, params=params)
                else:
                    response = self.session.post(url, json=params)
                end_time = time.time()
                
                result = {
                    "endpoint": endpoint,
                    "method": method,
                    "description": endpoint_config["description"],
                    "success": response.status_code in [200, 201],
                    "status_code": response.status_code,
                    "response_time": round(end_time - start_time, 3),
                    "response": response.json() if response.status_code in [200, 201] else None
                }
                
                if response.status_code not in [200, 201]:
                    result["error"] = response.text
                    
            except Exception as e:
                result = {
                    "endpoint": endpoint_config["endpoint"],
                    "method": endpoint_config["method"],
                    "description": endpoint_config["description"],
                    "success": False,
                    "error": str(e),
                    "response_time": None
                }
            
            results.append(result)
            logger.info(f"GitHub API test: {endpoint_config['endpoint']} - {'SUCCESS' if result['success'] else 'FAILED'}")
            
        return results

def run_all_tests() -> Dict[str, Any]:
    """Run all API tests"""
    logger.info("Starting comprehensive API testing...")
    
    test_results = {
        "timestamp": datetime.now().isoformat(),
        "test_config": TEST_CONFIG,
        "results": {}
    }
    
    # Test QuickNode
    if TEST_CONFIG["enable_quicknode_tests"]:
        logger.info("Testing QuickNode API...")
        quicknode_tester = QuickNodeTester()
        test_results["results"]["quicknode"] = {
            "connectivity": quicknode_tester.test_connectivity(),
            "rpc_methods": quicknode_tester.test_rpc_methods()
        }
    
    # Test Blast
    if TEST_CONFIG["enable_blast_tests"]:
        logger.info("Testing Blast API...")
        blast_tester = BlastTester()
        test_results["results"]["blast"] = {
            "connectivity": blast_tester.test_connectivity(),
            "rpc_methods": blast_tester.test_rpc_methods()
        }
    
    # Test CoinGecko
    if TEST_CONFIG["enable_coingecko_tests"]:
        logger.info("Testing CoinGecko API...")
        coingecko_tester = CoinGeckoTester()
        test_results["results"]["coingecko"] = {
            "connectivity": coingecko_tester.test_connectivity(),
            "endpoints": coingecko_tester.test_endpoints()
        }
    
    # Test CoinCap
    if TEST_CONFIG["enable_coincap_tests"]:
        logger.info("Testing CoinCap API...")
        coincap_tester = CoinCapTester()
        test_results["results"]["coincap"] = {
            "connectivity": coincap_tester.test_connectivity(),
            "endpoints": coincap_tester.test_endpoints()
        }
    
    # Test GitHub
    if TEST_CONFIG["enable_github_tests"]:
        logger.info("Testing GitHub API...")
        github_tester = GitHubTester()
        test_results["results"]["github"] = {
            "connectivity": github_tester.test_connectivity(),
            "endpoints": github_tester.test_endpoints()
        }
    
    return test_results

def save_results(results: Dict[str, Any], filename: str = None):
    """Save test results to file"""
    if not filename:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"new_apis_test_results_{timestamp}.json"
    
    with open(filename, 'w') as f:
        json.dump(results, f, indent=2, default=str)
    
    logger.info(f"Test results saved to {filename}")
    return filename

def generate_report(results: Dict[str, Any]) -> str:
    """Generate a human-readable test report"""
    report = []
    report.append("=" * 80)
    report.append("NEW APIs TEST REPORT")
    report.append("=" * 80)
    report.append(f"Timestamp: {results['timestamp']}")
    report.append("")
    
    total_tests = 0
    passed_tests = 0
    
    for service_name, service_results in results["results"].items():
        report.append(f"Service: {service_name.upper()}")
        report.append("-" * 40)
        
        # Connectivity test
        if "connectivity" in service_results:
            conn_result = service_results["connectivity"]
            total_tests += 1
            if conn_result["success"]:
                passed_tests += 1
                report.append(f"✓ Connectivity: SUCCESS ({conn_result['response_time']}s)")
            else:
                report.append(f"✗ Connectivity: FAILED - {conn_result.get('error', 'Unknown error')}")
        
        # Endpoint/RPC tests
        if "endpoints" in service_results:
            for endpoint_result in service_results["endpoints"]:
                total_tests += 1
                if endpoint_result["success"]:
                    passed_tests += 1
                    report.append(f"✓ {endpoint_result['description']}: SUCCESS ({endpoint_result['response_time']}s)")
                else:
                    report.append(f"✗ {endpoint_result['description']}: FAILED - {endpoint_result.get('error', 'Unknown error')}")
        
        if "rpc_methods" in service_results:
            for rpc_result in service_results["rpc_methods"]:
                total_tests += 1
                if rpc_result["success"]:
                    passed_tests += 1
                    report.append(f"✓ {rpc_result['description']}: SUCCESS ({rpc_result['response_time']}s)")
                else:
                    report.append(f"✗ {rpc_result['description']}: FAILED - {rpc_result.get('error', 'Unknown error')}")
        
        report.append("")
    
    # Summary
    report.append("=" * 80)
    report.append("SUMMARY")
    report.append("=" * 80)
    report.append(f"Total Tests: {total_tests}")
    report.append(f"Passed: {passed_tests}")
    report.append(f"Failed: {total_tests - passed_tests}")
    report.append(f"Success Rate: {(passed_tests/total_tests*100):.1f}%" if total_tests > 0 else "Success Rate: N/A")
    
    return "\n".join(report)

def main():
    """Main function"""
    try:
        # Run all tests
        results = run_all_tests()
        
        # Save results if configured
        if TEST_CONFIG["save_results"]:
            save_results(results)
        
        # Generate and print report
        if TEST_CONFIG["generate_report"]:
            report = generate_report(results)
            print(report)
            
            # Save report to file
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            report_filename = f"new_apis_test_report_{timestamp}.txt"
            with open(report_filename, 'w') as f:
                f.write(report)
            logger.info(f"Test report saved to {report_filename}")
        
        logger.info("API testing completed successfully!")
        
    except Exception as e:
        logger.error(f"Error during API testing: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
