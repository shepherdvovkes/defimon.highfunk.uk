#!/usr/bin/env python3
"""
Test script for external APIs integration in analytics-api service
"""

import os
import sys
import json
import time
import requests
import asyncio
from datetime import datetime
from typing import Dict, Any, List

# Add the service directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Set environment variables for testing
os.environ.update({
    "QUICKNODE_API_KEY": "QN_6a9c24b3a5fc491f88e8c24c3294ef36",
    "BLAST_API_KEY": "azoNgu3Cle2YBWFElUzVWNCXw-g_F31RvQjQKJmfVcg",
    "COINGECKO_API_KEY": "CG-32UZHngR3w1V7u2vQ76tP3Fi",
    "COINCAP_API_KEY": "dbdbfe12346bb92d9dac28504e5fee49ee721659429345b8a8fd8da5bab9c715",
    "GITHUB_API_TOKEN": "[GITHUB_TOKEN_PLACEHOLDER]",
    "GITHUB_USERNAME": "shepherdvovkes"
})

class AnalyticsAPITester:
    """Test class for analytics-api external APIs integration"""
    
    def __init__(self, base_url: str = "http://localhost:8002"):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.timeout = 30
        
    def test_health_endpoint(self) -> Dict[str, Any]:
        """Test the health endpoint"""
        try:
            url = f"{self.base_url}/api/external-apis/health"
            response = self.session.get(url)
            
            return {
                "endpoint": "/api/external-apis/health",
                "success": response.status_code == 200,
                "status_code": response.status_code,
                "response": response.json() if response.status_code == 200 else response.text
            }
        except Exception as e:
            return {
                "endpoint": "/api/external-apis/health",
                "success": False,
                "error": str(e)
            }
    
    def test_quicknode_endpoints(self) -> List[Dict[str, Any]]:
        """Test QuickNode endpoints"""
        endpoints = [
            "/api/external-apis/quicknode/block-number",
            "/api/external-apis/quicknode/gas-price",
            "/api/external-apis/quicknode/balance/0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6"
        ]
        
        results = []
        for endpoint in endpoints:
            try:
                url = f"{self.base_url}{endpoint}"
                response = self.session.get(url)
                
                result = {
                    "endpoint": endpoint,
                    "success": response.status_code == 200,
                    "status_code": response.status_code,
                    "response": response.json() if response.status_code == 200 else response.text
                }
                
            except Exception as e:
                result = {
                    "endpoint": endpoint,
                    "success": False,
                    "error": str(e)
                }
            
            results.append(result)
        
        return results
    
    def test_coingecko_endpoints(self) -> List[Dict[str, Any]]:
        """Test CoinGecko endpoints"""
        endpoints = [
            "/api/external-apis/coingecko/bitcoin-price",
            "/api/external-apis/coingecko/top-coins?limit=5"
        ]
        
        results = []
        for endpoint in endpoints:
            try:
                url = f"{self.base_url}{endpoint}"
                response = self.session.get(url)
                
                result = {
                    "endpoint": endpoint,
                    "success": response.status_code == 200,
                    "status_code": response.status_code,
                    "response": response.json() if response.status_code == 200 else response.text
                }
                
            except Exception as e:
                result = {
                    "endpoint": endpoint,
                    "success": False,
                    "error": str(e)
                }
            
            results.append(result)
        
        return results
    
    def test_coincap_endpoints(self) -> List[Dict[str, Any]]:
        """Test CoinCap endpoints"""
        endpoints = [
            "/api/external-apis/coincap/assets",
            "/api/external-apis/coincap/bitcoin"
        ]
        
        results = []
        for endpoint in endpoints:
            try:
                url = f"{self.base_url}{endpoint}"
                response = self.session.get(url)
                
                result = {
                    "endpoint": endpoint,
                    "success": response.status_code == 200,
                    "status_code": response.status_code,
                    "response": response.json() if response.status_code == 200 else response.text
                }
                
            except Exception as e:
                result = {
                    "endpoint": endpoint,
                    "success": False,
                    "error": str(e)
                }
            
            results.append(result)
        
        return results
    
    def test_github_endpoints(self) -> List[Dict[str, Any]]:
        """Test GitHub endpoints"""
        endpoints = [
            "/api/external-apis/github/user",
            "/api/external-apis/github/repos"
        ]
        
        results = []
        for endpoint in endpoints:
            try:
                url = f"{self.base_url}{endpoint}"
                response = self.session.get(url)
                
                result = {
                    "endpoint": endpoint,
                    "success": response.status_code == 200,
                    "status_code": response.status_code,
                    "response": response.json() if response.status_code == 200 else response.text
                }
                
            except Exception as e:
                result = {
                    "endpoint": endpoint,
                    "success": False,
                    "error": str(e)
                }
            
            results.append(result)
        
        return results
    
    def test_summary_endpoint(self) -> Dict[str, Any]:
        """Test the summary endpoint"""
        try:
            url = f"{self.base_url}/api/external-apis/summary"
            response = self.session.get(url)
            
            return {
                "endpoint": "/api/external-apis/summary",
                "success": response.status_code == 200,
                "status_code": response.status_code,
                "response": response.json() if response.status_code == 200 else response.text
            }
        except Exception as e:
            return {
                "endpoint": "/api/external-apis/summary",
                "success": False,
                "error": str(e)
            }
    
    def run_all_tests(self) -> Dict[str, Any]:
        """Run all integration tests"""
        print("Starting analytics-api external APIs integration tests...")
        
        results = {
            "timestamp": datetime.now().isoformat(),
            "base_url": self.base_url,
            "tests": {}
        }
        
        # Test health endpoint
        print("Testing health endpoint...")
        results["tests"]["health"] = self.test_health_endpoint()
        
        # Test QuickNode endpoints
        print("Testing QuickNode endpoints...")
        results["tests"]["quicknode"] = self.test_quicknode_endpoints()
        
        # Test CoinGecko endpoints
        print("Testing CoinGecko endpoints...")
        results["tests"]["coingecko"] = self.test_coingecko_endpoints()
        
        # Test CoinCap endpoints
        print("Testing CoinCap endpoints...")
        results["tests"]["coincap"] = self.test_coincap_endpoints()
        
        # Test GitHub endpoints
        print("Testing GitHub endpoints...")
        results["tests"]["github"] = self.test_github_endpoints()
        
        # Test summary endpoint
        print("Testing summary endpoint...")
        results["tests"]["summary"] = self.test_summary_endpoint()
        
        return results

def generate_report(results: Dict[str, Any]) -> str:
    """Generate a test report"""
    report = []
    report.append("=" * 80)
    report.append("ANALYTICS-API EXTERNAL APIs INTEGRATION TEST REPORT")
    report.append("=" * 80)
    report.append(f"Timestamp: {results['timestamp']}")
    report.append(f"Base URL: {results['base_url']}")
    report.append("")
    
    total_tests = 0
    passed_tests = 0
    
    for test_category, test_results in results["tests"].items():
        report.append(f"Category: {test_category.upper()}")
        report.append("-" * 40)
        
        if isinstance(test_results, list):
            for test_result in test_results:
                total_tests += 1
                if test_result["success"]:
                    passed_tests += 1
                    report.append(f"✓ {test_result['endpoint']}: SUCCESS")
                else:
                    report.append(f"✗ {test_result['endpoint']}: FAILED - {test_result.get('error', 'Unknown error')}")
        else:
            total_tests += 1
            if test_results["success"]:
                passed_tests += 1
                report.append(f"✓ {test_results['endpoint']}: SUCCESS")
            else:
                report.append(f"✗ {test_results['endpoint']}: FAILED - {test_results.get('error', 'Unknown error')}")
        
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

def save_results(results: Dict[str, Any], filename: str = None):
    """Save test results to file"""
    if not filename:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"analytics_api_integration_test_results_{timestamp}.json"
    
    with open(filename, 'w') as f:
        json.dump(results, f, indent=2, default=str)
    
    print(f"Test results saved to {filename}")
    return filename

def main():
    """Main function"""
    try:
        # Create tester
        tester = AnalyticsAPITester()
        
        # Run tests
        results = tester.run_all_tests()
        
        # Save results
        save_results(results)
        
        # Generate and print report
        report = generate_report(results)
        print(report)
        
        # Save report to file
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_filename = f"analytics_api_integration_test_report_{timestamp}.txt"
        with open(report_filename, 'w') as f:
            f.write(report)
        print(f"Test report saved to {report_filename}")
        
        print("Integration testing completed successfully!")
        
    except Exception as e:
        print(f"Error during integration testing: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
