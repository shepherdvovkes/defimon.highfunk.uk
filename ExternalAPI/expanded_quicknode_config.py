#!/usr/bin/env python3
"""
Expanded QuickNode Configuration for L2 Networks
Adds 10 new networks to the existing QuickNode setup
"""

import os
import requests
import json
from dataclasses import dataclass
from typing import Dict, Optional, List
import urllib3
from datetime import datetime

# Disable SSL warnings for production use
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

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
    priority: int = 5  # 1-10, higher = more important
    tvl_usd: Optional[float] = None
    volume_24h: Optional[float] = None

class ExpandedQuickNodeConfig:
    """Expanded configuration for QuickNode multichain endpoints with 17 total networks"""
    
    def __init__(self, endpoint_name: str, token_id: str):
        self.endpoint_name = endpoint_name
        self.token_id = token_id
        self.endpoints = self._create_expanded_endpoints()
    
    def _create_expanded_endpoints(self) -> Dict[str, QuickNodeEndpoint]:
        """Create expanded endpoint configurations with 10 new L2 networks"""
        
        base_url = f"https://{self.endpoint_name}.quiknode.pro/{self.token_id}"
        base_ws_url = f"wss://{self.endpoint_name}.quiknode.pro/{self.token_id}"
        
        return {
            # Existing networks (7)
            "ethereum": QuickNodeEndpoint(
                name="Ethereum",
                network_name="mainnet",
                http_url=base_url,
                ws_url=base_ws_url,
                chain_id=1,
                currency_symbol="ETH",
                ssl_verify=True,
                enabled=True,
                priority=10,
                tvl_usd=45000000000.0,  # $45B TVL
                volume_24h=2500000000.0  # $2.5B daily volume
            ),
            "base": QuickNodeEndpoint(
                name="Base",
                network_name="base-mainnet",
                http_url=f"https://{self.endpoint_name}.base-mainnet.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.base-mainnet.quiknode.pro/{self.token_id}",
                chain_id=8453,
                currency_symbol="ETH",
                ssl_verify=True,
                enabled=True,
                priority=9,
                tvl_usd=750000000.0,  # $750M TVL
                volume_24h=150000000.0  # $150M daily volume
            ),
            "bsc": QuickNodeEndpoint(
                name="Binance Smart Chain",
                network_name="bsc",
                http_url=f"https://{self.endpoint_name}.bsc.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.bsc.quiknode.pro/{self.token_id}",
                chain_id=56,
                currency_symbol="BNB",
                ssl_verify=True,
                enabled=True,
                priority=9,
                tvl_usd=5200000000.0,  # $5.2B TVL
                volume_24h=800000000.0  # $800M daily volume
            ),
            "avalanche": QuickNodeEndpoint(
                name="Avalanche C-Chain",
                network_name="avalanche-mainnet",
                http_url=f"https://{self.endpoint_name}.avalanche-mainnet.quiknode.pro/{self.token_id}/ext/bc/C/rpc",
                ws_url=f"wss://{self.endpoint_name}.avalanche-mainnet.quiknode.pro/{self.token_id}/ext/bc/C/ws",
                chain_id=43114,
                currency_symbol="AVAX",
                ssl_verify=True,
                enabled=True,
                priority=8,
                tvl_usd=1100000000.0,  # $1.1B TVL
                volume_24h=200000000.0  # $200M daily volume
            ),
            "polygon": QuickNodeEndpoint(
                name="Polygon",
                network_name="polygon-mainnet",
                http_url=f"https://{self.endpoint_name}.polygon-mainnet.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.polygon-mainnet.quiknode.pro/{self.token_id}",
                chain_id=137,
                currency_symbol="MATIC",
                ssl_verify=False,
                enabled=True,
                priority=9,
                tvl_usd=850000000.0,  # $850M TVL
                volume_24h=300000000.0  # $300M daily volume
            ),
            "arbitrum": QuickNodeEndpoint(
                name="Arbitrum One",
                network_name="arbitrum-one",
                http_url=f"https://{self.endpoint_name}.arbitrum-one.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.arbitrum-one.quiknode.pro/{self.token_id}",
                chain_id=42161,
                currency_symbol="ETH",
                ssl_verify=False,
                enabled=True,
                priority=10,
                tvl_usd=2100000000.0,  # $2.1B TVL
                volume_24h=500000000.0  # $500M daily volume
            ),
            "optimism": QuickNodeEndpoint(
                name="Optimism",
                network_name="optimism-mainnet",
                http_url=f"https://{self.endpoint_name}.optimism-mainnet.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.optimism-mainnet.quiknode.pro/{self.token_id}",
                chain_id=10,
                currency_symbol="ETH",
                ssl_verify=False,
                enabled=True,
                priority=9,
                tvl_usd=850000000.0,  # $850M TVL
                volume_24h=250000000.0  # $250M daily volume
            ),
            
            # NEW L2 Networks (10)
            "polygon_zkevm": QuickNodeEndpoint(
                name="Polygon zkEVM",
                network_name="polygon-zkevm-mainnet",
                http_url=f"https://{self.endpoint_name}.polygon-zkevm-mainnet.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.polygon-zkevm-mainnet.quiknode.pro/{self.token_id}",
                chain_id=1101,
                currency_symbol="ETH",
                ssl_verify=True,
                enabled=True,
                priority=8,
                tvl_usd=45000000.0,  # $45M TVL
                volume_24h=15000000.0  # $15M daily volume
            ),
            "zksync_era": QuickNodeEndpoint(
                name="zkSync Era",
                network_name="zksync-era-mainnet",
                http_url=f"https://{self.endpoint_name}.zksync-era-mainnet.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.zksync-era-mainnet.quiknode.pro/{self.token_id}",
                chain_id=324,
                currency_symbol="ETH",
                ssl_verify=True,
                enabled=True,
                priority=8,
                tvl_usd=650000000.0,  # $650M TVL
                volume_24h=120000000.0  # $120M daily volume
            ),
            "linea": QuickNodeEndpoint(
                name="Linea",
                network_name="linea-mainnet",
                http_url=f"https://{self.endpoint_name}.linea-mainnet.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.linea-mainnet.quiknode.pro/{self.token_id}",
                chain_id=59144,
                currency_symbol="ETH",
                ssl_verify=True,
                enabled=True,
                priority=7,
                tvl_usd=120000000.0,  # $120M TVL
                volume_24h=25000000.0  # $25M daily volume
            ),
            "scroll": QuickNodeEndpoint(
                name="Scroll",
                network_name="scroll-mainnet",
                http_url=f"https://{self.endpoint_name}.scroll-mainnet.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.scroll-mainnet.quiknode.pro/{self.token_id}",
                chain_id=534352,
                currency_symbol="ETH",
                ssl_verify=True,
                enabled=True,
                priority=7,
                tvl_usd=85000000.0,  # $85M TVL
                volume_24h=18000000.0  # $18M daily volume
            ),
            "mantle": QuickNodeEndpoint(
                name="Mantle",
                network_name="mantle-mainnet",
                http_url=f"https://{self.endpoint_name}.mantle-mainnet.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.mantle-mainnet.quiknode.pro/{self.token_id}",
                chain_id=5000,
                currency_symbol="MNT",
                ssl_verify=True,
                enabled=True,
                priority=6,
                tvl_usd=45000000.0,  # $45M TVL
                volume_24h=12000000.0  # $12M daily volume
            ),
            "metis": QuickNodeEndpoint(
                name="Metis",
                network_name="metis-mainnet",
                http_url=f"https://{self.endpoint_name}.metis-mainnet.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.metis-mainnet.quiknode.pro/{self.token_id}",
                chain_id=1088,
                currency_symbol="METIS",
                ssl_verify=True,
                enabled=True,
                priority=6,
                tvl_usd=35000000.0,  # $35M TVL
                volume_24h=8000000.0  # $8M daily volume
            ),
            "cronos": QuickNodeEndpoint(
                name="Cronos",
                network_name="cronos-mainnet",
                http_url=f"https://{self.endpoint_name}.cronos-mainnet.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.cronos-mainnet.quiknode.pro/{self.token_id}",
                chain_id=25,
                currency_symbol="CRO",
                ssl_verify=True,
                enabled=True,
                priority=6,
                tvl_usd=180000000.0,  # $180M TVL
                volume_24h=35000000.0  # $35M daily volume
            ),
            "fantom": QuickNodeEndpoint(
                name="Fantom",
                network_name="fantom-mainnet",
                http_url=f"https://{self.endpoint_name}.fantom-mainnet.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.fantom-mainnet.quiknode.pro/{self.token_id}",
                chain_id=250,
                currency_symbol="FTM",
                ssl_verify=True,
                enabled=True,
                priority=6,
                tvl_usd=85000000.0,  # $85M TVL
                volume_24h=20000000.0  # $20M daily volume
            ),
            "celo": QuickNodeEndpoint(
                name="Celo",
                network_name="celo-mainnet",
                http_url=f"https://{self.endpoint_name}.celo-mainnet.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.celo-mainnet.quiknode.pro/{self.token_id}",
                chain_id=42220,
                currency_symbol="CELO",
                ssl_verify=True,
                enabled=True,
                priority=5,
                tvl_usd=45000000.0,  # $45M TVL
                volume_24h=10000000.0  # $10M daily volume
            ),
            "gnosis": QuickNodeEndpoint(
                name="Gnosis Chain",
                network_name="gnosis-mainnet",
                http_url=f"https://{self.endpoint_name}.gnosis-mainnet.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.gnosis-mainnet.quiknode.pro/{self.token_id}",
                chain_id=100,
                currency_symbol="XDAI",
                ssl_verify=True,
                enabled=True,
                priority=5,
                tvl_usd=35000000.0,  # $35M TVL
                volume_24h=8000000.0  # $8M daily volume
            )
        }
    
    def make_rpc_call(self, network: str, method: str, params: list = None) -> Dict:
        """Make RPC call to a specific network with proper SSL handling"""
        endpoint = self.get_endpoint(network)
        if not endpoint:
            raise ValueError(f"Network {network} not found")
        
        payload = {
            "jsonrpc": "2.0",
            "method": method,
            "params": params or [],
            "id": 1
        }
        
        headers = {
            "Content-Type": "application/json"
        }
        
        response = requests.post(
            endpoint.http_url,
            json=payload,
            headers=headers,
            verify=endpoint.ssl_verify,
            timeout=30
        )
        
        if response.status_code != 200:
            raise Exception(f"RPC call failed: {response.status_code} - {response.text}")
        
        return response.json()
    
    def get_block_number(self, network: str) -> int:
        """Get current block number for a network"""
        result = self.make_rpc_call(network, "eth_blockNumber")
        block_hex = result.get("result", "0x0")
        return int(block_hex, 16)
    
    def get_chain_id(self, network: str) -> int:
        """Get chain ID for a network"""
        result = self.make_rpc_call(network, "eth_chainId")
        chain_id_hex = result.get("result", "0x1")
        return int(chain_id_hex, 16)
    
    def get_gas_price(self, network: str) -> int:
        """Get current gas price for a network"""
        result = self.make_rpc_call(network, "eth_gasPrice")
        gas_hex = result.get("result", "0x0")
        return int(gas_hex, 16)
    
    def get_balance(self, network: str, address: str) -> int:
        """Get balance for an address on a network"""
        result = self.make_rpc_call(network, "eth_getBalance", [address, "latest"])
        balance_hex = result.get("result", "0x0")
        return int(balance_hex, 16)
    
    def test_all_networks(self) -> Dict[str, Dict]:
        """Test all networks and return results"""
        results = {}
        
        for network_name, endpoint in self.endpoints.items():
            if not endpoint.enabled:
                continue
                
            try:
                block_number = self.get_block_number(network_name)
                chain_id = self.get_chain_id(network_name)
                gas_price = self.get_gas_price(network_name)
                
                results[network_name] = {
                    "status": "working",
                    "block_number": block_number,
                    "chain_id": chain_id,
                    "gas_price": gas_price,
                    "gas_price_gwei": gas_price / 1e9,
                    "ssl_verified": endpoint.ssl_verify,
                    "currency": endpoint.currency_symbol,
                    "priority": endpoint.priority,
                    "tvl_usd": endpoint.tvl_usd,
                    "volume_24h": endpoint.volume_24h
                }
                
            except Exception as e:
                results[network_name] = {
                    "status": "error",
                    "error": str(e),
                    "ssl_verified": endpoint.ssl_verify,
                    "currency": endpoint.currency_symbol,
                    "priority": endpoint.priority,
                    "tvl_usd": endpoint.tvl_usd,
                    "volume_24h": endpoint.volume_24h
                }
        
        return results
    
    def get_endpoint(self, network: str) -> Optional[QuickNodeEndpoint]:
        """Get endpoint configuration for a specific network"""
        return self.endpoints.get(network.lower())
    
    def get_all_endpoints(self) -> Dict[str, QuickNodeEndpoint]:
        """Get all endpoint configurations"""
        return self.endpoints
    
    def get_enabled_endpoints(self) -> Dict[str, QuickNodeEndpoint]:
        """Get only enabled endpoint configurations"""
        return {k: v for k, v in self.endpoints.items() if v.enabled}
    
    def get_high_priority_endpoints(self, min_priority: int = 7) -> Dict[str, QuickNodeEndpoint]:
        """Get endpoints with priority >= min_priority"""
        return {k: v for k, v in self.endpoints.items() if v.priority >= min_priority and v.enabled}
    
    def get_networks_by_category(self) -> Dict[str, List[str]]:
        """Get networks grouped by category"""
        categories = {
            "high_priority": [],  # Priority 8-10
            "medium_priority": [],  # Priority 6-7
            "low_priority": [],  # Priority 1-5
            "zk_rollups": [],  # ZK-based networks
            "optimistic_rollups": [],  # Optimistic rollups
            "sidechains": []  # Sidechains
        }
        
        for network_name, endpoint in self.endpoints.items():
            if not endpoint.enabled:
                continue
                
            # Priority categories
            if endpoint.priority >= 8:
                categories["high_priority"].append(network_name)
            elif endpoint.priority >= 6:
                categories["medium_priority"].append(network_name)
            else:
                categories["low_priority"].append(network_name)
            
            # Technology categories
            if network_name in ["polygon_zkevm", "zksync_era", "scroll"]:
                categories["zk_rollups"].append(network_name)
            elif network_name in ["arbitrum", "optimism", "base", "linea", "mantle", "metis"]:
                categories["optimistic_rollups"].append(network_name)
            elif network_name in ["polygon", "bsc", "avalanche", "cronos", "fantom", "celo", "gnosis"]:
                categories["sidechains"].append(network_name)
        
        return categories

# Production configuration instance
def get_expanded_config() -> ExpandedQuickNodeConfig:
    """Get expanded configuration for QuickNode endpoints"""
    endpoint_name = os.getenv("QUICKNODE_ENDPOINT_NAME", "hidden-holy-seed")
    token_id = os.getenv("QUICKNODE_TOKEN_ID", "97d6d8e7659b49b126c43455edc4607949bfb52b")
    
    return ExpandedQuickNodeConfig(endpoint_name, token_id)

# Network mapping for easy access
NETWORK_ALIASES = {
    # Existing aliases
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
    "optimism": "optimism",
    
    # New network aliases
    "zkevm": "polygon_zkevm",
    "polygon_zkevm": "polygon_zkevm",
    "zksync": "zksync_era",
    "zksync_era": "zksync_era",
    "linea": "linea",
    "scroll": "scroll",
    "mantle": "mantle",
    "metis": "metis",
    "cronos": "cronos",
    "fantom": "fantom",
    "celo": "celo",
    "gnosis": "gnosis",
    "xdai": "gnosis"
}

def get_endpoint_by_alias(alias: str) -> Optional[QuickNodeEndpoint]:
    """Get endpoint by common alias"""
    config = get_expanded_config()
    network = NETWORK_ALIASES.get(alias.lower())
    if network:
        return config.get_endpoint(network)
    return None

# Example usage functions
def test_expanded_quicknode_endpoints():
    """Test all expanded QuickNode endpoints"""
    config = get_expanded_config()
    results = config.test_all_networks()
    
    print("🚀 Expanded QuickNode Endpoints Test Results")
    print("=" * 60)
    
    # Group by priority
    high_priority = []
    medium_priority = []
    low_priority = []
    errors = []
    
    for network, result in results.items():
        if result["status"] == "working":
            ssl_status = "🔒" if result["ssl_verified"] else "⚠️"
            priority_emoji = "🔥" if result["priority"] >= 8 else "⚡" if result["priority"] >= 6 else "📊"
            
            network_info = f"{ssl_status} {priority_emoji} {network}: Block {result['block_number']} (Chain ID: {result['chain_id']})"
            network_info += f" | Gas: {result['gas_price_gwei']:.2f} Gwei"
            
            if result["priority"] >= 8:
                high_priority.append(network_info)
            elif result["priority"] >= 6:
                medium_priority.append(network_info)
            else:
                low_priority.append(network_info)
        else:
            errors.append(f"❌ {network}: {result['error']}")
    
    # Print results by priority
    print("\n🔥 High Priority Networks (Priority 8-10):")
    for info in high_priority:
        print(f"  {info}")
    
    print("\n⚡ Medium Priority Networks (Priority 6-7):")
    for info in medium_priority:
        print(f"  {info}")
    
    print("\n📊 Low Priority Networks (Priority 1-5):")
    for info in low_priority:
        print(f"  {info}")
    
    if errors:
        print("\n❌ Errors:")
        for error in errors:
            print(f"  {error}")
    
    return results

def get_network_statistics():
    """Get comprehensive network statistics"""
    config = get_expanded_config()
    results = config.test_all_networks()
    
    total_tvl = 0
    total_volume = 0
    working_networks = 0
    total_networks = len(results)
    
    for network, result in results.items():
        if result["status"] == "working":
            working_networks += 1
            if result.get("tvl_usd"):
                total_tvl += result["tvl_usd"]
            if result.get("volume_24h"):
                total_volume += result["volume_24h"]
    
    categories = config.get_networks_by_category()
    
    print("\n📊 Network Statistics")
    print("=" * 40)
    print(f"Total Networks: {total_networks}")
    print(f"Working Networks: {working_networks}")
    print(f"Success Rate: {(working_networks/total_networks)*100:.1f}%")
    print(f"Total TVL: ${total_tvl/1e9:.2f}B")
    print(f"Total 24h Volume: ${total_volume/1e6:.2f}M")
    
    print(f"\n🔗 Network Categories:")
    print(f"High Priority: {len(categories['high_priority'])} networks")
    print(f"Medium Priority: {len(categories['medium_priority'])} networks")
    print(f"Low Priority: {len(categories['low_priority'])} networks")
    print(f"ZK Rollups: {len(categories['zk_rollups'])} networks")
    print(f"Optimistic Rollups: {len(categories['optimistic_rollups'])} networks")
    print(f"Sidechains: {len(categories['sidechains'])} networks")

if __name__ == "__main__":
    # Test all endpoints
    results = test_expanded_quicknode_endpoints()
    
    # Get statistics
    get_network_statistics()
    
    # Example RPC calls
    print(f"\n🎯 Example Usage:")
    try:
        config = get_expanded_config()
        
        # Test high priority networks
        eth_block = config.get_block_number("ethereum")
        arb_block = config.get_block_number("arbitrum")
        poly_block = config.get_block_number("polygon")
        
        print(f"Ethereum Block: {eth_block}")
        print(f"Arbitrum Block: {arb_block}")
        print(f"Polygon Block: {poly_block}")
        
        # Test new networks
        zkevm_block = config.get_block_number("polygon_zkevm")
        zksync_block = config.get_block_number("zksync_era")
        
        print(f"Polygon zkEVM Block: {zkevm_block}")
        print(f"zkSync Era Block: {zksync_block}")
        
    except Exception as e:
        print(f"Error in example: {e}")
