#!/usr/bin/env python3
"""
Advanced SSL Solutions for QuickNode Endpoints
Tests various approaches to access networks with SSL certificate issues
"""

import requests
import urllib3
import logging
import json
import time
import ssl
import socket
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from datetime import datetime
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Disable SSL warnings for testing
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('advanced_ssl_solutions.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class SSLSolutionResult:
    """Result of SSL solution test"""
    network: str
    solution_name: str
    success: bool
    response_time: float
    response_status: Optional[int] = None
    error_message: Optional[str] = None
    data: Optional[Dict] = None
    timestamp: datetime = None

    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now()

class AdvancedSSLSolutions:
    """Advanced SSL solutions for QuickNode endpoints"""
    
    def __init__(self, endpoint_name: str, token_id: str):
        self.endpoint_name = endpoint_name
        self.token_id = token_id
        self.results: List[SSLSolutionResult] = []
        
        # Problematic networks
        self.problematic_networks = [
            {
                "name": "Polygon",
                "hostname": f"{endpoint_name}.polygon-mainnet.quiknode.pro",
                "endpoint": f"https://{endpoint_name}.polygon-mainnet.quiknode.pro/{token_id}"
            },
            {
                "name": "Arbitrum One",
                "hostname": f"{endpoint_name}.arbitrum-one.quiknode.pro",
                "endpoint": f"https://{endpoint_name}.arbitrum-one.quiknode.pro/{token_id}"
            },
            {
                "name": "Optimism",
                "hostname": f"{endpoint_name}.optimism-mainnet.quiknode.pro",
                "endpoint": f"https://{endpoint_name}.optimism-mainnet.quiknode.pro/{token_id}"
            }
        ]

    def test_solution_1_http_instead_of_https(self, network: Dict) -> SSLSolutionResult:
        """Test 1: Try HTTP instead of HTTPS"""
        start_time = time.time()
        
        try:
            # Convert HTTPS to HTTP
            http_endpoint = network["endpoint"].replace("https://", "http://")
            
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
                http_endpoint,
                json=payload,
                headers=headers,
                timeout=10
            )
            
            response_time = time.time() - start_time
            
            return SSLSolutionResult(
                network=network["name"],
                solution_name="HTTP Instead of HTTPS",
                success=response.status_code == 200,
                response_time=response_time,
                response_status=response.status_code,
                data=response.json() if response.status_code == 200 else None
            )
            
        except Exception as e:
            response_time = time.time() - start_time
            return SSLSolutionResult(
                network=network["name"],
                solution_name="HTTP Instead of HTTPS",
                success=False,
                response_time=response_time,
                error_message=str(e)
            )

    def test_solution_2_custom_ssl_context(self, network: Dict) -> SSLSolutionResult:
        """Test 2: Custom SSL context with specific configurations"""
        start_time = time.time()
        
        try:
            import ssl
            import urllib3.util.ssl_
            
            # Create custom SSL context
            context = ssl.create_default_context()
            context.check_hostname = False
            context.verify_mode = ssl.CERT_NONE
            
            # Create custom session
            session = requests.Session()
            session.verify = False
            
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_blockNumber",
                "params": [],
                "id": 1
            }
            
            headers = {
                "Content-Type": "application/json",
                "Accept": "application/json",
                "User-Agent": "QuickNode-SSL-Test/1.0"
            }
            
            response = session.post(
                network["endpoint"],
                json=payload,
                headers=headers,
                timeout=10
            )
            
            response_time = time.time() - start_time
            
            return SSLSolutionResult(
                network=network["name"],
                solution_name="Custom SSL Context",
                success=response.status_code == 200,
                response_time=response_time,
                response_status=response.status_code,
                data=response.json() if response.status_code == 200 else None
            )
            
        except Exception as e:
            response_time = time.time() - start_time
            return SSLSolutionResult(
                network=network["name"],
                solution_name="Custom SSL Context",
                success=False,
                response_time=response_time,
                error_message=str(e)
            )

    def test_solution_3_proxy_approach(self, network: Dict) -> SSLSolutionResult:
        """Test 3: Try using a proxy or different routing"""
        start_time = time.time()
        
        try:
            # Try with different headers that might bypass SSL issues
            headers = {
                "Content-Type": "application/json",
                "Accept": "application/json",
                "User-Agent": "Mozilla/5.0 (compatible; QuickNode-SSL-Test/1.0)",
                "Accept-Encoding": "gzip, deflate",
                "Connection": "keep-alive"
            }
            
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_blockNumber",
                "params": [],
                "id": 1
            }
            
            response = requests.post(
                network["endpoint"],
                json=payload,
                headers=headers,
                timeout=10,
                verify=False,
                allow_redirects=True
            )
            
            response_time = time.time() - start_time
            
            return SSLSolutionResult(
                network=network["name"],
                solution_name="Enhanced Headers",
                success=response.status_code == 200,
                response_time=response_time,
                response_status=response.status_code,
                data=response.json() if response.status_code == 200 else None
            )
            
        except Exception as e:
            response_time = time.time() - start_time
            return SSLSolutionResult(
                network=network["name"],
                solution_name="Enhanced Headers",
                success=False,
                response_time=response_time,
                error_message=str(e)
            )

    def test_solution_4_alternative_endpoints(self, network: Dict) -> SSLSolutionResult:
        """Test 4: Try alternative endpoint formats"""
        start_time = time.time()
        
        try:
            # Try different endpoint formats
            base_hostname = network["hostname"]
            alternative_endpoints = [
                f"https://{base_hostname}:443/{self.token_id}",
                f"https://{base_hostname}/v1/{self.token_id}",
                f"https://{base_hostname}/api/{self.token_id}",
                f"https://{base_hostname}/rpc/{self.token_id}"
            ]
            
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
            
            for endpoint in alternative_endpoints:
                try:
                    response = requests.post(
                        endpoint,
                        json=payload,
                        headers=headers,
                        timeout=5,
                        verify=False
                    )
                    
                    if response.status_code == 200:
                        response_time = time.time() - start_time
                        return SSLSolutionResult(
                            network=network["name"],
                            solution_name=f"Alternative Endpoint: {endpoint}",
                            success=True,
                            response_time=response_time,
                            response_status=response.status_code,
                            data=response.json()
                        )
                except:
                    continue
            
            response_time = time.time() - start_time
            return SSLSolutionResult(
                network=network["name"],
                solution_name="Alternative Endpoints",
                success=False,
                response_time=response_time,
                error_message="No alternative endpoints worked"
            )
            
        except Exception as e:
            response_time = time.time() - start_time
            return SSLSolutionResult(
                network=network["name"],
                solution_name="Alternative Endpoints",
                success=False,
                response_time=response_time,
                error_message=str(e)
            )

    def test_solution_5_direct_socket_connection(self, network: Dict) -> SSLSolutionResult:
        """Test 5: Direct socket connection to test if the service is reachable"""
        start_time = time.time()
        
        try:
            hostname = network["hostname"]
            port = 443
            
            # Test basic connectivity
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(10)
            result = sock.connect_ex((hostname, port))
            sock.close()
            
            response_time = time.time() - start_time
            
            if result == 0:
                return SSLSolutionResult(
                    network=network["name"],
                    solution_name="Direct Socket Connection",
                    success=True,
                    response_time=response_time,
                    data={"message": f"Port {port} is reachable on {hostname}"}
                )
            else:
                return SSLSolutionResult(
                    network=network["name"],
                    solution_name="Direct Socket Connection",
                    success=False,
                    response_time=response_time,
                    error_message=f"Port {port} is not reachable on {hostname}"
                )
                
        except Exception as e:
            response_time = time.time() - start_time
            return SSLSolutionResult(
                network=network["name"],
                solution_name="Direct Socket Connection",
                success=False,
                response_time=response_time,
                error_message=str(e)
            )

    def test_solution_6_curl_equivalent(self, network: Dict) -> SSLSolutionResult:
        """Test 6: Simulate curl with specific SSL options"""
        start_time = time.time()
        
        try:
            import subprocess
            
            # Try curl equivalent with specific SSL options
            curl_command = [
                "curl", "-s", "-X", "POST",
                "-H", "Content-Type: application/json",
                "-d", '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}',
                "--connect-timeout", "10",
                "--max-time", "30",
                "--insecure",  # Equivalent to verify=False
                network["endpoint"]
            ]
            
            result = subprocess.run(
                curl_command,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            response_time = time.time() - start_time
            
            if result.returncode == 0 and result.stdout:
                try:
                    data = json.loads(result.stdout)
                    return SSLSolutionResult(
                        network=network["name"],
                        solution_name="Curl Equivalent",
                        success=True,
                        response_time=response_time,
                        data=data
                    )
                except json.JSONDecodeError:
                    return SSLSolutionResult(
                        network=network["name"],
                        solution_name="Curl Equivalent",
                        success=False,
                        response_time=response_time,
                        error_message="Invalid JSON response"
                    )
            else:
                return SSLSolutionResult(
                    network=network["name"],
                    solution_name="Curl Equivalent",
                    success=False,
                    response_time=response_time,
                    error_message=f"Curl failed: {result.stderr}"
                )
                
        except Exception as e:
            response_time = time.time() - start_time
            return SSLSolutionResult(
                network=network["name"],
                solution_name="Curl Equivalent",
                success=False,
                response_time=response_time,
                error_message=str(e)
            )

    def test_all_solutions_for_network(self, network: Dict) -> List[SSLSolutionResult]:
        """Test all solutions for a specific network"""
        logger.info(f"Testing all solutions for {network['name']}")
        
        solutions = [
            self.test_solution_1_http_instead_of_https,
            self.test_solution_2_custom_ssl_context,
            self.test_solution_3_proxy_approach,
            self.test_solution_4_alternative_endpoints,
            self.test_solution_5_direct_socket_connection,
            self.test_solution_6_curl_equivalent
        ]
        
        results = []
        for solution_func in solutions:
            try:
                result = solution_func(network)
                results.append(result)
                
                if result.success:
                    logger.info(f"✅ {network['name']} - {result.solution_name}: Success in {result.response_time:.3f}s")
                else:
                    logger.warning(f"❌ {network['name']} - {result.solution_name}: Failed - {result.error_message}")
                    
            except Exception as e:
                logger.error(f"Error testing {solution_func.__name__} for {network['name']}: {e}")
        
        return results

    def test_all_networks(self) -> Dict[str, List[SSLSolutionResult]]:
        """Test all solutions for all problematic networks"""
        logger.info("Starting advanced SSL solutions testing")
        
        all_results = {}
        
        for network in self.problematic_networks:
            logger.info(f"Testing solutions for {network['name']}...")
            results = self.test_all_solutions_for_network(network)
            all_results[network['name']] = results
            self.results.extend(results)
        
        return all_results

    def generate_solutions_report(self) -> str:
        """Generate comprehensive solutions report"""
        if not self.results:
            return "No solution results available"
        
        report = f"""
{'='*80}
ADVANCED SSL SOLUTIONS REPORT
{'='*80}
Test Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
Endpoint Base: {self.endpoint_name}
Token ID: {self.token_id}

SSL Solutions Test Results:
"""
        
        # Group results by network
        network_results = {}
        for result in self.results:
            if result.network not in network_results:
                network_results[result.network] = []
            network_results[result.network].append(result)
        
        for network_name, results in network_results.items():
            report += f"\n{network_name}:\n{'-' * (len(network_name) + 1)}\n"
            
            successful_solutions = [r for r in results if r.success]
            failed_solutions = [r for r in results if not r.success]
            
            if successful_solutions:
                report += f"  ✅ WORKING SOLUTIONS ({len(successful_solutions)}):\n"
                for result in successful_solutions:
                    report += f"    • {result.solution_name}: {result.response_time:.3f}s\n"
                    if result.data:
                        if isinstance(result.data, dict) and "result" in result.data:
                            report += f"      Block: {result.data['result']}\n"
                        else:
                            report += f"      Data: {str(result.data)[:100]}...\n"
            
            if failed_solutions:
                report += f"  ❌ FAILED SOLUTIONS ({len(failed_solutions)}):\n"
                for result in failed_solutions:
                    report += f"    • {result.solution_name}: {result.error_message}\n"
        
        # Summary
        total_tests = len(self.results)
        successful_tests = sum(1 for r in self.results if r.success)
        
        report += f"\nSUMMARY:\n{'-'*20}\n"
        report += f"Total Solutions Tested: {total_tests}\n"
        report += f"Successful Solutions: {successful_tests}\n"
        report += f"Success Rate: {(successful_tests/total_tests)*100:.1f}%\n"
        
        # Recommendations
        report += f"\nRECOMMENDATIONS:\n{'-'*20}\n"
        
        if successful_tests > 0:
            report += "✅ Some solutions are working! Consider using:\n"
            for result in self.results:
                if result.success:
                    report += f"  • {result.network}: {result.solution_name}\n"
        else:
            report += "❌ No SSL solutions worked. This indicates:\n"
            report += "  • The endpoints may not be properly configured\n"
            report += "  • QuickNode may need to fix certificate issues\n"
            report += "  • The networks may not be enabled in your plan\n"
        
        report += f"\n{'='*80}\n"
        return report

    def save_results(self, filename: str = None):
        """Save solution results to JSON file"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"advanced_ssl_solutions_{timestamp}.json"
        
        results_data = {
            "test_time": datetime.now().isoformat(),
            "endpoint_base": self.endpoint_name,
            "token_id": self.token_id,
            "results": [
                {
                    "network": r.network,
                    "solution_name": r.solution_name,
                    "success": r.success,
                    "response_time": r.response_time,
                    "response_status": r.response_status,
                    "error_message": r.error_message,
                    "data": r.data,
                    "timestamp": r.timestamp.isoformat()
                }
                for r in self.results
            ]
        }
        
        with open(filename, 'w') as f:
            json.dump(results_data, f, indent=2)
        
        logger.info(f"Solution results saved to {filename}")

def main():
    """Main function to run advanced SSL solutions"""
    
    endpoint_name = "hidden-holy-seed"
    token_id = "97d6d8e7659b49b126c43455edc4607949bfb52b"
    
    # Create advanced SSL solutions tester
    tester = AdvancedSSLSolutions(endpoint_name, token_id)
    
    # Run all solutions
    results = tester.test_all_networks()
    
    # Generate and print report
    report = tester.generate_solutions_report()
    print(report)
    
    # Save results
    tester.save_results()
    
    return results

if __name__ == "__main__":
    main()
