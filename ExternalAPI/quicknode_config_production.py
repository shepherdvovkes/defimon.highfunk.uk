#!/usr/bin/env python3
"""
Production-ready QuickNode Configuration
Provides working endpoints for all networks with SSL handling
"""

import os
from dataclasses import dataclass
from typing import Dict, List, Optional

@dataclass
class QuickNodeEndpoint:
    """Production QuickNode endpoint configuration"""
    name: str
    network_name: str
    http_url: str
    ws_url: str
    chain_id: int
    currency_symbol: str
    ssl_verify: bool
    enabled: bool = True

class QuickNodeProductionConfig:
    """Production configuration for QuickNode multichain endpoints"""
    
    def __init__(self, endpoint_name: str, token_id: str):
        self.endpoint_name = endpoint_name
        self.token_id = token_id
        self.endpoints = self._create_endpoints()
    
    def _create_endpoints(self) -> Dict[str, QuickNodeEndpoint]:
        """Create endpoint configurations based on test results"""
        
        base_url = f"https://{self.endpoint_name}.quiknode.pro/{self.token_id}"
        base_ws_url = f"wss://{self.endpoint_name}.quiknode.pro/{self.token_id}"
        
        return {
            "ethereum": QuickNodeEndpoint(
                name="Ethereum",
                network_name="mainnet",
                http_url=base_url,
                ws_url=base_ws_url,
                chain_id=1,
                currency_symbol="ETH",
                ssl_verify=True,
                enabled=True
            ),
            "base": QuickNodeEndpoint(
                name="Base",
                network_name="base-mainnet",
                http_url=f"https://{self.endpoint_name}.base-mainnet.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.base-mainnet.quiknode.pro/{self.token_id}",
                chain_id=8453,
                currency_symbol="ETH",
                ssl_verify=True,
                enabled=True
            ),
            "bsc": QuickNodeEndpoint(
                name="Binance Smart Chain",
                network_name="bsc",
                http_url=f"https://{self.endpoint_name}.bsc.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.bsc.quiknode.pro/{self.token_id}",
                chain_id=56,
                currency_symbol="BNB",
                ssl_verify=True,
                enabled=True
            ),
            "avalanche": QuickNodeEndpoint(
                name="Avalanche C-Chain",
                network_name="avalanche-mainnet",
                http_url=f"https://{self.endpoint_name}.avalanche-mainnet.quiknode.pro/{self.token_id}/ext/bc/C/rpc",
                ws_url=f"wss://{self.endpoint_name}.avalanche-mainnet.quiknode.pro/{self.token_id}/ext/bc/C/ws",
                chain_id=43114,
                currency_symbol="AVAX",
                ssl_verify=True,
                enabled=True
            ),
            "polygon": QuickNodeEndpoint(
                name="Polygon",
                network_name="polygon-mainnet",
                http_url=f"https://{self.endpoint_name}.polygon-mainnet.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.polygon-mainnet.quiknode.pro/{self.token_id}",
                chain_id=137,
                currency_symbol="MATIC",
                ssl_verify=False,  # SSL certificate issue - working without verification
                enabled=True
            ),
            "arbitrum": QuickNodeEndpoint(
                name="Arbitrum One",
                network_name="arbitrum-one",
                http_url=f"https://{self.endpoint_name}.arbitrum-one.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.arbitrum-one.quiknode.pro/{self.token_id}",
                chain_id=42161,
                currency_symbol="ETH",
                ssl_verify=False,  # SSL certificate issue - working without verification
                enabled=True
            ),
            "optimism": QuickNodeEndpoint(
                name="Optimism",
                network_name="optimism-mainnet",
                http_url=f"https://{self.endpoint_name}.optimism-mainnet.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.optimism-mainnet.quiknode.pro/{self.token_id}",
                chain_id=10,
                currency_symbol="ETH",
                ssl_verify=False,  # SSL certificate issue - working without verification
                enabled=True
            )
        }
    
    def get_endpoint(self, network: str) -> Optional[QuickNodeEndpoint]:
        """Get endpoint configuration for a specific network"""
        return self.endpoints.get(network.lower())
    
    def get_all_endpoints(self) -> Dict[str, QuickNodeEndpoint]:
        """Get all endpoint configurations"""
        return self.endpoints
    
    def get_enabled_endpoints(self) -> Dict[str, QuickNodeEndpoint]:
        """Get only enabled endpoint configurations"""
        return {k: v for k, v in self.endpoints.items() if v.enabled}
    
    def get_ssl_verified_endpoints(self) -> Dict[str, QuickNodeEndpoint]:
        """Get endpoints with SSL verification enabled"""
        return {k: v for k, v in self.endpoints.items() if v.ssl_verify and v.enabled}
    
    def get_ssl_unverified_endpoints(self) -> Dict[str, QuickNodeEndpoint]:
        """Get endpoints without SSL verification (working but with certificate issues)"""
        return {k: v for k, v in self.endpoints.items() if not v.ssl_verify and v.enabled}
    
    def get_network_by_chain_id(self, chain_id: int) -> Optional[QuickNodeEndpoint]:
        """Get endpoint configuration by chain ID"""
        for endpoint in self.endpoints.values():
            if endpoint.chain_id == chain_id and endpoint.enabled:
                return endpoint
        return None
    
    def get_networks_summary(self) -> Dict[str, Dict]:
        """Get a summary of all networks"""
        summary = {}
        for network, endpoint in self.endpoints.items():
            summary[network] = {
                "name": endpoint.name,
                "chain_id": endpoint.chain_id,
                "currency": endpoint.currency_symbol,
                "ssl_verified": endpoint.ssl_verify,
                "enabled": endpoint.enabled,
                "http_url": endpoint.http_url,
                "ws_url": endpoint.ws_url
            }
        return summary

# Production configuration instance
def get_production_config() -> QuickNodeProductionConfig:
    """Get production configuration for QuickNode endpoints"""
    endpoint_name = os.getenv("QUICKNODE_ENDPOINT_NAME", "hidden-holy-seed")
    token_id = os.getenv("QUICKNODE_TOKEN_ID", "97d6d8e7659b49b126c43455edc4607949bfb52b")
    
    return QuickNodeProductionConfig(endpoint_name, token_id)

# Example usage functions
def get_ethereum_endpoint() -> QuickNodeEndpoint:
    """Get Ethereum mainnet endpoint"""
    config = get_production_config()
    return config.get_endpoint("ethereum")

def get_all_working_endpoints() -> Dict[str, QuickNodeEndpoint]:
    """Get all working endpoints (enabled)"""
    config = get_production_config()
    return config.get_enabled_endpoints()

def get_secure_endpoints() -> Dict[str, QuickNodeEndpoint]:
    """Get endpoints with SSL verification (most secure)"""
    config = get_production_config()
    return config.get_ssl_verified_endpoints()

# Network mapping for easy access
NETWORK_ALIASES = {
    "eth": "ethereum",
    "mainnet": "ethereum",
    "base": "base",
    "bsc": "bsc",
    "binance": "bsc",
    "avax": "avalanche",
    "avalanche": "avalanche",
    "matic": "polygon",
    "polygon": "polygon",
    "arb": "arbitrum",
    "arbitrum": "arbitrum",
    "op": "optimism",
    "optimism": "optimism"
}

def get_endpoint_by_alias(alias: str) -> Optional[QuickNodeEndpoint]:
    """Get endpoint by common alias"""
    config = get_production_config()
    network = NETWORK_ALIASES.get(alias.lower())
    if network:
        return config.get_endpoint(network)
    return None

if __name__ == "__main__":
    # Example usage and testing
    config = get_production_config()
    
    print("🚀 QuickNode Production Configuration")
    print("=" * 50)
    
    print(f"\n📊 Network Summary:")
    summary = config.get_networks_summary()
    for network, info in summary.items():
        ssl_status = "🔒" if info["ssl_verified"] else "⚠️"
        enabled_status = "✅" if info["enabled"] else "❌"
        print(f"  {ssl_status} {enabled_status} {info['name']} (Chain ID: {info['chain_id']})")
    
    print(f"\n🔒 SSL Verified Networks ({len(config.get_ssl_verified_endpoints())}):")
    for name, endpoint in config.get_ssl_verified_endpoints().items():
        print(f"  • {endpoint.name} ({endpoint.currency_symbol})")
    
    print(f"\n⚠️  SSL Unverified Networks ({len(config.get_ssl_unverified_endpoints())}):")
    for name, endpoint in config.get_ssl_unverified_endpoints().items():
        print(f"  • {endpoint.name} ({endpoint.currency_symbol}) - Working but with certificate issues")
    
    print(f"\n📡 Example Endpoints:")
    eth_endpoint = get_ethereum_endpoint()
    if eth_endpoint:
        print(f"  Ethereum HTTP: {eth_endpoint.http_url}")
        print(f"  Ethereum WebSocket: {eth_endpoint.ws_url}")
    
    print(f"\n🎯 Quick Access Examples:")
    print(f"  get_endpoint_by_alias('eth'): {get_endpoint_by_alias('eth') is not None}")
    print(f"  get_endpoint_by_alias('matic'): {get_endpoint_by_alias('matic') is not None}")
    print(f"  get_network_by_chain_id(1): {config.get_network_by_chain_id(1) is not None}")
