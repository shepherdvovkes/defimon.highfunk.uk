#!/usr/bin/env python3
"""
SSL Certificate Analyzer for QuickNode Endpoints
Analyzes SSL certificate issues and tests potential solutions
"""

import ssl
import socket
import requests
import urllib3
import logging
import json
import time
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
        logging.FileHandler('ssl_certificate_analysis.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class SSLCertificateInfo:
    """SSL Certificate information"""
    hostname: str
    port: int
    subject: str
    issuer: str
    version: int
    serial_number: str
    not_before: str
    not_after: str
    san_dns: List[str]
    san_ip: List[str]
    signature_algorithm: str
    public_key_algorithm: str
    key_size: int
    is_valid: bool
    error_message: Optional[str] = None

@dataclass
class SSLTestResult:
    """Result of SSL certificate test"""
    network: str
    endpoint: str
    success: bool
    ssl_verified: bool
    certificate_info: Optional[SSLCertificateInfo] = None
    error_message: Optional[str] = None
    response_time: float = 0.0
    timestamp: datetime = None

    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now()

class SSLCertificateAnalyzer:
    """SSL Certificate Analyzer for QuickNode endpoints"""
    
    def __init__(self, endpoint_name: str, token_id: str):
        self.endpoint_name = endpoint_name
        self.token_id = token_id
        self.results: List[SSLTestResult] = []
        
        # Networks with SSL issues
        self.problematic_networks = [
            {
                "name": "Polygon",
                "network_name": "polygon-mainnet",
                "hostname": f"{endpoint_name}.polygon-mainnet.quiknode.pro",
                "port": 443,
                "endpoint": f"https://{endpoint_name}.polygon-mainnet.quiknode.pro/{token_id}"
            },
            {
                "name": "Arbitrum One",
                "network_name": "arbitrum-one",
                "hostname": f"{endpoint_name}.arbitrum-one.quiknode.pro",
                "port": 443,
                "endpoint": f"https://{endpoint_name}.arbitrum-one.quiknode.pro/{token_id}"
            },
            {
                "name": "Optimism",
                "network_name": "optimism-mainnet",
                "hostname": f"{endpoint_name}.optimism-mainnet.quiknode.pro",
                "port": 443,
                "endpoint": f"https://{endpoint_name}.optimism-mainnet.quiknode.pro/{token_id}"
            }
        ]
        
        # Working networks for comparison
        self.working_networks = [
            {
                "name": "Ethereum",
                "network_name": "mainnet",
                "hostname": f"{endpoint_name}.quiknode.pro",
                "port": 443,
                "endpoint": f"https://{endpoint_name}.quiknode.pro/{token_id}"
            },
            {
                "name": "Base",
                "network_name": "base-mainnet",
                "hostname": f"{endpoint_name}.base-mainnet.quiknode.pro",
                "port": 443,
                "endpoint": f"https://{endpoint_name}.base-mainnet.quiknode.pro/{token_id}"
            }
        ]

    def get_certificate_info(self, hostname: str, port: int = 443) -> Optional[SSLCertificateInfo]:
        """Get detailed SSL certificate information"""
        try:
            context = ssl.create_default_context()
            with socket.create_connection((hostname, port), timeout=10) as sock:
                with context.wrap_socket(sock, server_hostname=hostname) as ssock:
                    cert = ssock.getpeercert()
                    
                    # Extract certificate information
                    subject = dict(x[0] for x in cert['subject'])
                    issuer = dict(x[0] for x in cert['issuer'])
                    
                    # Get SAN (Subject Alternative Names)
                    san_dns = []
                    san_ip = []
                    if 'subjectAltName' in cert:
                        for type_name, value in cert['subjectAltName']:
                            if type_name == 'DNS':
                                san_dns.append(value)
                            elif type_name == 'IP Address':
                                san_ip.append(value)
                    
                    return SSLCertificateInfo(
                        hostname=hostname,
                        port=port,
                        subject=f"CN={subject.get('commonName', 'Unknown')}",
                        issuer=f"CN={issuer.get('commonName', 'Unknown')}",
                        version=cert.get('version', 0),
                        serial_number=cert.get('serialNumber', 'Unknown'),
                        not_before=cert.get('notBefore', 'Unknown'),
                        not_after=cert.get('notAfter', 'Unknown'),
                        san_dns=san_dns,
                        san_ip=san_ip,
                        signature_algorithm=cert.get('signatureAlgorithm', 'Unknown'),
                        public_key_algorithm='Unknown',  # Not directly available
                        key_size=0,  # Would need additional parsing
                        is_valid=True
                    )
                    
        except ssl.SSLError as e:
            logger.error(f"SSL Error for {hostname}: {e}")
            return SSLCertificateInfo(
                hostname=hostname,
                port=port,
                subject="Error",
                issuer="Error",
                version=0,
                serial_number="Error",
                not_before="Error",
                not_after="Error",
                san_dns=[],
                san_ip=[],
                signature_algorithm="Error",
                public_key_algorithm="Error",
                key_size=0,
                is_valid=False,
                error_message=str(e)
            )
        except Exception as e:
            logger.error(f"Error getting certificate for {hostname}: {e}")
            return SSLCertificateInfo(
                hostname=hostname,
                port=port,
                subject="Error",
                issuer="Error",
                version=0,
                serial_number="Error",
                not_before="Error",
                not_after="Error",
                san_dns=[],
                san_ip=[],
                signature_algorithm="Error",
                public_key_algorithm="Error",
                key_size=0,
                is_valid=False,
                error_message=str(e)
            )

    def test_ssl_connection(self, network: Dict) -> SSLTestResult:
        """Test SSL connection and certificate for a network"""
        start_time = time.time()
        
        try:
            # Test 1: Get certificate information
            cert_info = self.get_certificate_info(network["hostname"], network["port"])
            
            # Test 2: Try HTTP request with SSL verification
            try:
                response = requests.get(
                    network["endpoint"],
                    timeout=10,
                    verify=True
                )
                ssl_verified = True
                success = response.status_code == 200
            except requests.exceptions.SSLError:
                ssl_verified = False
                success = False
                response = None
            
            response_time = time.time() - start_time
            
            return SSLTestResult(
                network=network["name"],
                endpoint=network["endpoint"],
                success=success,
                ssl_verified=ssl_verified,
                certificate_info=cert_info,
                response_time=response_time
            )
            
        except Exception as e:
            response_time = time.time() - start_time
            return SSLTestResult(
                network=network["name"],
                endpoint=network["endpoint"],
                success=False,
                ssl_verified=False,
                error_message=str(e),
                response_time=response_time
            )

    def test_alternative_ssl_configurations(self, network: Dict) -> List[SSLTestResult]:
        """Test alternative SSL configurations to find working solutions"""
        results = []
        
        # Test 1: Default SSL verification
        logger.info(f"Testing {network['name']} with default SSL verification")
        result1 = self.test_ssl_connection(network)
        results.append(result1)
        
        # Test 2: Custom SSL context with relaxed verification
        logger.info(f"Testing {network['name']} with relaxed SSL verification")
        try:
            start_time = time.time()
            
            # Create custom SSL context
            context = ssl.create_default_context()
            context.check_hostname = False
            context.verify_mode = ssl.CERT_NONE
            
            # Test with custom context
            response = requests.get(
                network["endpoint"],
                timeout=10,
                verify=False
            )
            
            response_time = time.time() - start_time
            
            result2 = SSLTestResult(
                network=network["name"],
                endpoint=network["endpoint"],
                success=response.status_code == 200,
                ssl_verified=False,
                response_time=response_time
            )
            results.append(result2)
            
        except Exception as e:
            response_time = time.time() - start_time
            result2 = SSLTestResult(
                network=network["name"],
                endpoint=network["endpoint"],
                success=False,
                ssl_verified=False,
                error_message=str(e),
                response_time=response_time
            )
            results.append(result2)
        
        # Test 3: Try with different user agents
        logger.info(f"Testing {network['name']} with different user agent")
        try:
            start_time = time.time()
            
            headers = {
                'User-Agent': 'Mozilla/5.0 (compatible; QuickNode-SSL-Test/1.0)'
            }
            
            response = requests.get(
                network["endpoint"],
                headers=headers,
                timeout=10,
                verify=False
            )
            
            response_time = time.time() - start_time
            
            result3 = SSLTestResult(
                network=network["name"],
                endpoint=network["endpoint"],
                success=response.status_code == 200,
                ssl_verified=False,
                response_time=response_time
            )
            results.append(result3)
            
        except Exception as e:
            response_time = time.time() - start_time
            result3 = SSLTestResult(
                network=network["name"],
                endpoint=network["endpoint"],
                success=False,
                ssl_verified=False,
                error_message=str(e),
                response_time=response_time
            )
            results.append(result3)
        
        return results

    def analyze_all_networks(self) -> Dict[str, List[SSLTestResult]]:
        """Analyze SSL certificates for all networks"""
        logger.info("Starting SSL certificate analysis for all networks")
        
        all_results = {}
        
        # Test problematic networks
        logger.info("Testing networks with SSL issues...")
        for network in self.problematic_networks:
            logger.info(f"Analyzing {network['name']}...")
            results = self.test_alternative_ssl_configurations(network)
            all_results[network['name']] = results
        
        # Test working networks for comparison
        logger.info("Testing working networks for comparison...")
        for network in self.working_networks:
            logger.info(f"Analyzing {network['name']}...")
            results = self.test_alternative_ssl_configurations(network)
            all_results[network['name']] = results
        
        self.results = []
        for network_results in all_results.values():
            self.results.extend(network_results)
        
        return all_results

    def generate_analysis_report(self) -> str:
        """Generate comprehensive SSL analysis report"""
        if not self.results:
            return "No analysis results available"
        
        report = f"""
{'='*80}
SSL CERTIFICATE ANALYSIS REPORT
{'='*80}
Analysis Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
Endpoint Base: {self.endpoint_name}
Token ID: {self.token_id}

SSL Certificate Analysis Results:
"""
        
        # Group results by network
        network_results = {}
        for result in self.results:
            if result.network not in network_results:
                network_results[result.network] = []
            network_results[result.network].append(result)
        
        for network_name, results in network_results.items():
            report += f"\n{network_name}:\n{'-' * (len(network_name) + 1)}\n"
            
            for i, result in enumerate(results, 1):
                status = "✅" if result.success else "❌"
                ssl_status = "🔒" if result.ssl_verified else "⚠️"
                
                test_type = "Default SSL" if i == 1 else "Relaxed SSL" if i == 2 else "Custom Headers"
                
                report += f"  {ssl_status} {status} {test_type}: {result.response_time:.3f}s"
                if result.certificate_info:
                    report += f"\n    Certificate: {result.certificate_info.subject}"
                    report += f"\n    Issuer: {result.certificate_info.issuer}"
                    if result.certificate_info.san_dns:
                        report += f"\n    SAN DNS: {', '.join(result.certificate_info.san_dns)}"
                    if result.certificate_info.error_message:
                        report += f"\n    Error: {result.certificate_info.error_message}"
                elif result.error_message:
                    report += f"\n    Error: {result.error_message}"
                report += "\n"
        
        # SSL mitigation recommendations
        report += f"\nSSL MITIGATION RECOMMENDATIONS:\n{'-'*40}\n"
        
        problematic_networks = ["Polygon", "Arbitrum One", "Optimism"]
        for network_name in problematic_networks:
            if network_name in network_results:
                results = network_results[network_name]
                working_configs = [r for r in results if r.success]
                
                if working_configs:
                    report += f"\n✅ {network_name} - WORKING CONFIGURATIONS:\n"
                    for result in working_configs:
                        if not result.ssl_verified:
                            report += f"  • Use verify=False in requests\n"
                            report += f"  • Response time: {result.response_time:.3f}s\n"
                else:
                    report += f"\n❌ {network_name} - NO WORKING CONFIGURATIONS FOUND\n"
        
        # Certificate comparison
        report += f"\nCERTIFICATE COMPARISON:\n{'-'*30}\n"
        for network_name, results in network_results.items():
            if results and results[0].certificate_info:
                cert = results[0].certificate_info
                report += f"\n{network_name}:\n"
                report += f"  Subject: {cert.subject}\n"
                report += f"  Issuer: {cert.issuer}\n"
                report += f"  Valid: {cert.is_valid}\n"
                if cert.san_dns:
                    report += f"  SAN DNS: {', '.join(cert.san_dns)}\n"
                if cert.error_message:
                    report += f"  Error: {cert.error_message}\n"
        
        report += f"\n{'='*80}\n"
        return report

    def save_results(self, filename: str = None):
        """Save analysis results to JSON file"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"ssl_certificate_analysis_{timestamp}.json"
        
        results_data = {
            "analysis_time": datetime.now().isoformat(),
            "endpoint_base": self.endpoint_name,
            "token_id": self.token_id,
            "results": [
                {
                    "network": r.network,
                    "endpoint": r.endpoint,
                    "success": r.success,
                    "ssl_verified": r.ssl_verified,
                    "response_time": r.response_time,
                    "error_message": r.error_message,
                    "certificate_info": {
                        "hostname": r.certificate_info.hostname,
                        "subject": r.certificate_info.subject,
                        "issuer": r.certificate_info.issuer,
                        "san_dns": r.certificate_info.san_dns,
                        "is_valid": r.certificate_info.is_valid,
                        "error_message": r.certificate_info.error_message
                    } if r.certificate_info else None,
                    "timestamp": r.timestamp.isoformat()
                }
                for r in self.results
            ]
        }
        
        with open(filename, 'w') as f:
            json.dump(results_data, f, indent=2)
        
        logger.info(f"Analysis results saved to {filename}")

def main():
    """Main function to run SSL certificate analysis"""
    
    endpoint_name = "hidden-holy-seed"
    token_id = "97d6d8e7659b49b126c43455edc4607949bfb52b"
    
    # Create SSL analyzer
    analyzer = SSLCertificateAnalyzer(endpoint_name, token_id)
    
    # Run analysis
    results = analyzer.analyze_all_networks()
    
    # Generate and print report
    report = analyzer.generate_analysis_report()
    print(report)
    
    # Save results
    analyzer.save_results()
    
    return results

if __name__ == "__main__":
    main()
