#!/usr/bin/env python3
"""
Enhanced Alchemy Configuration for Multi-Chain Support
Supports Ethereum, Polygon, Arbitrum, Optimism, Base, and StarkNet
Includes NFT API, Token API, and advanced features
"""

import os
import requests
import json
from dataclasses import dataclass
from typing import Dict, Optional, List, Any
from datetime import datetime
import time

@dataclass
class AlchemyEndpoint:
    """Alchemy endpoint configuration for different networks"""
    name: str
    network: str
    http_url: str
    ws_url: str
    chain_id: int
    currency_symbol: str
    enabled: bool = True
    priority: int = 5
    features: List[str] = None
    tvl_usd: Optional[float] = None
    volume_24h: Optional[float] = None

    def __post_init__(self):
        if self.features is None:
            self.features = ["rpc", "nft", "token", "transfers", "webhooks"]

@dataclass
class AlchemyAPIConfig:
    """Alchemy API configuration with multi-chain support"""
    api_key: str
    base_url: str
    headers: Dict[str, str]
    timeout: int = 30
    max_retries: int = 3

class EnhancedAlchemyConfig:
    """Enhanced configuration for Alchemy multi-chain endpoints"""
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.endpoints = self._create_endpoints()
        self.api_configs = self._create_api_configs()
    
    def _create_endpoints(self) -> Dict[str, AlchemyEndpoint]:
        """Create endpoint configurations for all supported networks"""
        
        return {
            "ethereum": AlchemyEndpoint(
                name="Ethereum",
                network="eth-mainnet",
                http_url=f"https://eth-mainnet.g.alchemy.com/v2/{self.api_key}",
                ws_url=f"wss://eth-mainnet.g.alchemy.com/v2/{self.api_key}",
                chain_id=1,
                currency_symbol="ETH",
                enabled=True,
                priority=10,
                features=["rpc", "nft", "token", "transfers", "webhooks", "mempool", "debug"],
                tvl_usd=45000000000.0,  # $45B TVL
                volume_24h=2500000000.0  # $2.5B daily volume
            ),
            "polygon": AlchemyEndpoint(
                name="Polygon",
                network="polygon-mainnet",
                http_url=f"https://polygon-mainnet.g.alchemy.com/v2/{self.api_key}",
                ws_url=f"wss://polygon-mainnet.g.alchemy.com/v2/{self.api_key}",
                chain_id=137,
                currency_symbol="MATIC",
                enabled=True,
                priority=9,
                features=["rpc", "nft", "token", "transfers", "webhooks"],
                tvl_usd=850000000.0,  # $850M TVL
                volume_24h=300000000.0  # $300M daily volume
            ),
            "arbitrum": AlchemyEndpoint(
                name="Arbitrum One",
                network="arb-mainnet",
                http_url=f"https://arb-mainnet.g.alchemy.com/v2/{self.api_key}",
                ws_url=f"wss://arb-mainnet.g.alchemy.com/v2/{self.api_key}",
                chain_id=42161,
                currency_symbol="ETH",
                enabled=True,
                priority=10,
                features=["rpc", "nft", "token", "transfers", "webhooks"],
                tvl_usd=2100000000.0,  # $2.1B TVL
                volume_24h=500000000.0  # $500M daily volume
            ),
            "optimism": AlchemyEndpoint(
                name="Optimism",
                network="opt-mainnet",
                http_url=f"https://opt-mainnet.g.alchemy.com/v2/{self.api_key}",
                ws_url=f"wss://opt-mainnet.g.alchemy.com/v2/{self.api_key}",
                chain_id=10,
                currency_symbol="ETH",
                enabled=True,
                priority=9,
                features=["rpc", "nft", "token", "transfers", "webhooks"],
                tvl_usd=850000000.0,  # $850M TVL
                volume_24h=250000000.0  # $250M daily volume
            ),
            "base": AlchemyEndpoint(
                name="Base",
                network="base-mainnet",
                http_url=f"https://base-mainnet.g.alchemy.com/v2/{self.api_key}",
                ws_url=f"wss://base-mainnet.g.alchemy.com/v2/{self.api_key}",
                chain_id=8453,
                currency_symbol="ETH",
                enabled=True,
                priority=8,
                features=["rpc", "nft", "token", "transfers", "webhooks"],
                tvl_usd=750000000.0,  # $750M TVL
                volume_24h=150000000.0  # $150M daily volume
            ),
            "starknet": AlchemyEndpoint(
                name="StarkNet",
                network="starknet-mainnet",
                http_url=f"https://starknet-mainnet.g.alchemy.com/v2/{self.api_key}",
                ws_url=f"wss://starknet-mainnet.g.alchemy.com/v2/{self.api_key}",
                chain_id=0x534e5f4d41494e,  # SN_MAIN
                currency_symbol="ETH",
                enabled=True,
                priority=7,
                features=["rpc", "nft", "token", "transfers", "webhooks"],
                tvl_usd=180000000.0,  # $180M TVL
                volume_24h=45000000.0  # $45M daily volume
            ),
            # Testnets
            "ethereum_goerli": AlchemyEndpoint(
                name="Ethereum Goerli",
                network="eth-goerli",
                http_url=f"https://eth-goerli.g.alchemy.com/v2/{self.api_key}",
                ws_url=f"wss://eth-goerli.g.alchemy.com/v2/{self.api_key}",
                chain_id=5,
                currency_symbol="ETH",
                enabled=True,
                priority=3,
                features=["rpc", "nft", "token", "transfers"],
                tvl_usd=0.0,
                volume_24h=0.0
            ),
            "polygon_mumbai": AlchemyEndpoint(
                name="Polygon Mumbai",
                network="polygon-mumbai",
                http_url=f"https://polygon-mumbai.g.alchemy.com/v2/{self.api_key}",
                ws_url=f"wss://polygon-mumbai.g.alchemy.com/v2/{self.api_key}",
                chain_id=80001,
                currency_symbol="MATIC",
                enabled=True,
                priority=3,
                features=["rpc", "nft", "token", "transfers"],
                tvl_usd=0.0,
                volume_24h=0.0
            )
        }
    
    def _create_api_configs(self) -> Dict[str, AlchemyAPIConfig]:
        """Create API configurations for different features"""
        
        configs = {}
        for network_name, endpoint in self.endpoints.items():
            if not endpoint.enabled:
                continue
                
            configs[network_name] = AlchemyAPIConfig(
                api_key=self.api_key,
                base_url=endpoint.http_url,
                headers={"Content-Type": "application/json"},
                timeout=30,
                max_retries=3
            )
        
        return configs
    
    def make_rpc_call(self, network: str, method: str, params: list = None) -> Dict:
        """Make RPC call to a specific network"""
        endpoint = self.get_endpoint(network)
        if not endpoint:
            raise ValueError(f"Network {network} not found or not enabled")
        
        payload = {
            "jsonrpc": "2.0",
            "method": method,
            "params": params or [],
            "id": 1
        }
        
        response = requests.post(
            endpoint.http_url,
            json=payload,
            headers={"Content-Type": "application/json"},
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
    
    # Advanced Alchemy APIs
    def get_nft_metadata(self, network: str, contract_address: str, token_id: str) -> Dict:
        """Get NFT metadata using Alchemy NFT API"""
        endpoint = self.get_endpoint(network)
        if not endpoint or "nft" not in endpoint.features:
            raise ValueError(f"NFT API not supported for network {network}")
        
        url = f"{endpoint.http_url}/getNFTMetadata"
        params = {
            "contractAddress": contract_address,
            "tokenId": token_id
        }
        
        response = requests.get(url, params=params, timeout=30)
        
        if response.status_code != 200:
            raise Exception(f"NFT API call failed: {response.status_code} - {response.text}")
        
        return response.json()
    
    def get_nfts_for_owner(self, network: str, owner_address: str, page_size: int = 100) -> Dict:
        """Get NFTs owned by an address"""
        endpoint = self.get_endpoint(network)
        if not endpoint or "nft" not in endpoint.features:
            raise ValueError(f"NFT API not supported for network {network}")
        
        url = f"{endpoint.http_url}/getNFTs"
        params = {
            "owner": owner_address,
            "pageSize": page_size
        }
        
        response = requests.get(url, params=params, timeout=30)
        
        if response.status_code != 200:
            raise Exception(f"NFT API call failed: {response.status_code} - {response.text}")
        
        return response.json()
    
    def get_token_metadata(self, network: str, contract_address: str) -> Dict:
        """Get ERC-20 token metadata"""
        endpoint = self.get_endpoint(network)
        if not endpoint or "token" not in endpoint.features:
            raise ValueError(f"Token API not supported for network {network}")
        
        url = f"{endpoint.http_url}/getTokenMetadata"
        params = {
            "contractAddress": contract_address
        }
        
        response = requests.get(url, params=params, timeout=30)
        
        if response.status_code != 200:
            raise Exception(f"Token API call failed: {response.status_code} - {response.text}")
        
        return response.json()
    
    def get_token_balances(self, network: str, owner_address: str) -> Dict:
        """Get token balances for an address"""
        endpoint = self.get_endpoint(network)
        if not endpoint or "token" not in endpoint.features:
            raise ValueError(f"Token API not supported for network {network}")
        
        url = f"{endpoint.http_url}/getTokenBalances"
        params = {
            "owner": owner_address
        }
        
        response = requests.get(url, params=params, timeout=30)
        
        if response.status_code != 200:
            raise Exception(f"Token API call failed: {response.status_code} - {response.text}")
        
        return response.json()
    
    def get_asset_transfers(self, network: str, from_address: str = None, to_address: str = None, 
                          category: List[str] = None, max_count: int = 100) -> Dict:
        """Get asset transfers for an address"""
        endpoint = self.get_endpoint(network)
        if not endpoint or "transfers" not in endpoint.features:
            raise ValueError(f"Transfers API not supported for network {network}")
        
        url = f"{endpoint.http_url}/getAssetTransfers"
        params = {
            "maxCount": max_count
        }
        
        if from_address:
            params["fromAddress"] = from_address
        if to_address:
            params["toAddress"] = to_address
        if category:
            params["category"] = category
        
        response = requests.get(url, params=params, timeout=30)
        
        if response.status_code != 200:
            raise Exception(f"Transfers API call failed: {response.status_code} - {response.text}")
        
        return response.json()
    
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
                    "currency": endpoint.currency_symbol,
                    "priority": endpoint.priority,
                    "features": endpoint.features,
                    "tvl_usd": endpoint.tvl_usd,
                    "volume_24h": endpoint.volume_24h
                }
                
            except Exception as e:
                results[network_name] = {
                    "status": "error",
                    "error": str(e),
                    "currency": endpoint.currency_symbol,
                    "priority": endpoint.priority,
                    "features": endpoint.features,
                    "tvl_usd": endpoint.tvl_usd,
                    "volume_24h": endpoint.volume_24h
                }
        
        return results
    
    def get_endpoint(self, network: str) -> Optional[AlchemyEndpoint]:
        """Get endpoint configuration for a specific network"""
        return self.endpoints.get(network.lower())
    
    def get_all_endpoints(self) -> Dict[str, AlchemyEndpoint]:
        """Get all endpoint configurations"""
        return self.endpoints
    
    def get_enabled_endpoints(self) -> Dict[str, AlchemyEndpoint]:
        """Get only enabled endpoint configurations"""
        return {k: v for k, v in self.endpoints.items() if v.enabled}
    
    def get_mainnet_endpoints(self) -> Dict[str, AlchemyEndpoint]:
        """Get only mainnet endpoints (exclude testnets)"""
        return {k: v for k, v in self.endpoints.items() if v.enabled and "testnet" not in k and "goerli" not in k and "mumbai" not in k}
    
    def get_testnet_endpoints(self) -> Dict[str, AlchemyEndpoint]:
        """Get only testnet endpoints"""
        return {k: v for k, v in self.endpoints.items() if v.enabled and ("testnet" in k or "goerli" in k or "mumbai" in k)}
    
    def get_networks_by_features(self) -> Dict[str, List[str]]:
        """Get networks grouped by supported features"""
        feature_groups = {}
        
        for network_name, endpoint in self.endpoints.items():
            if not endpoint.enabled:
                continue
                
            for feature in endpoint.features:
                if feature not in feature_groups:
                    feature_groups[feature] = []
                feature_groups[feature].append(network_name)
        
        return feature_groups

# Production configuration instance
def get_enhanced_alchemy_config() -> EnhancedAlchemyConfig:
    """Get enhanced configuration for Alchemy endpoints"""
    api_key = os.getenv("ALCHEMY_API_KEY", "")
    if not api_key:
        raise ValueError("ALCHEMY_API_KEY environment variable is required")
    
    return EnhancedAlchemyConfig(api_key)

# Network mapping for easy access
ALCHEMY_NETWORK_ALIASES = {
    "eth": "ethereum",
    "ethereum": "ethereum",
    "mainnet": "ethereum",
    "matic": "polygon",
    "polygon": "polygon",
    "arb": "arbitrum",
    "arbitrum": "arbitrum",
    "op": "optimism",
    "optimism": "optimism",
    "base": "base",
    "starknet": "starknet",
    "goerli": "ethereum_goerli",
    "mumbai": "polygon_mumbai"
}

def get_alchemy_endpoint_by_alias(alias: str) -> Optional[AlchemyEndpoint]:
    """Get Alchemy endpoint by common alias"""
    config = get_enhanced_alchemy_config()
    network = ALCHEMY_NETWORK_ALIASES.get(alias.lower())
    if network:
        return config.get_endpoint(network)
    return None

# Example usage functions
def test_enhanced_alchemy_endpoints():
    """Test all enhanced Alchemy endpoints"""
    config = get_enhanced_alchemy_config()
    results = config.test_all_networks()
    
    print("🔮 Enhanced Alchemy Endpoints Test Results")
    print("=" * 60)
    
    # Group by priority
    high_priority = []
    medium_priority = []
    low_priority = []
    errors = []
    
    for network, result in results.items():
        if result["status"] == "working":
            priority_emoji = "🔥" if result["priority"] >= 8 else "⚡" if result["priority"] >= 6 else "📊"
            
            network_info = f"{priority_emoji} {network}: Block {result['block_number']} (Chain ID: {result['chain_id']})"
            network_info += f" | Gas: {result['gas_price_gwei']:.2f} Gwei"
            network_info += f" | Features: {', '.join(result['features'])}"
            
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

def test_advanced_alchemy_features():
    """Test advanced Alchemy features"""
    config = get_enhanced_alchemy_config()
    
    print("\n🎯 Testing Advanced Alchemy Features")
    print("=" * 50)
    
    # Test NFT API
    try:
        # Example: Get NFT metadata for CryptoPunks
        nft_result = config.get_nft_metadata(
            "ethereum", 
            "0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB",  # CryptoPunks contract
            "1"  # Token ID
        )
        print("✅ NFT API: Working")
        print(f"   NFT Name: {nft_result.get('title', 'N/A')}")
    except Exception as e:
        print(f"❌ NFT API: {str(e)}")
    
    # Test Token API
    try:
        # Example: Get USDC token metadata
        token_result = config.get_token_metadata(
            "ethereum",
            "0xA0b86a33E6441b8C4C8C8C8C8C8C8C8C8C8C8C8"  # USDC contract (example)
        )
        print("✅ Token API: Working")
        print(f"   Token Name: {token_result.get('name', 'N/A')}")
    except Exception as e:
        print(f"❌ Token API: {str(e)}")
    
    # Test Transfers API
    try:
        # Example: Get transfers for a known address
        transfers_result = config.get_asset_transfers(
            "ethereum",
            from_address="0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6"  # Example address
        )
        print("✅ Transfers API: Working")
        print(f"   Transfers Count: {len(transfers_result.get('result', {}).get('transfers', []))}")
    except Exception as e:
        print(f"❌ Transfers API: {str(e)}")

def get_alchemy_statistics():
    """Get comprehensive Alchemy statistics"""
    config = get_enhanced_alchemy_config()
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
    
    feature_groups = config.get_networks_by_features()
    
    print("\n📊 Alchemy Statistics")
    print("=" * 40)
    print(f"Total Networks: {total_networks}")
    print(f"Working Networks: {working_networks}")
    print(f"Success Rate: {(working_networks/total_networks)*100:.1f}%")
    print(f"Total TVL: ${total_tvl/1e9:.2f}B")
    print(f"Total 24h Volume: ${total_volume/1e6:.2f}M")
    
    print(f"\n🔧 Supported Features:")
    for feature, networks in feature_groups.items():
        print(f"{feature.upper()}: {len(networks)} networks")
    
    mainnet_count = len(config.get_mainnet_endpoints())
    testnet_count = len(config.get_testnet_endpoints())
    print(f"\n🌐 Network Types:")
    print(f"Mainnet: {mainnet_count} networks")
    print(f"Testnet: {testnet_count} networks")

if __name__ == "__main__":
    # Test all endpoints
    results = test_enhanced_alchemy_endpoints()
    
    # Test advanced features
    test_advanced_alchemy_features()
    
    # Get statistics
    get_alchemy_statistics()
    
    # Example RPC calls
    print(f"\n🎯 Example Usage:")
    try:
        config = get_enhanced_alchemy_config()
        
        # Test mainnet networks
        eth_block = config.get_block_number("ethereum")
        poly_block = config.get_block_number("polygon")
        arb_block = config.get_block_number("arbitrum")
        
        print(f"Ethereum Block: {eth_block}")
        print(f"Polygon Block: {poly_block}")
        print(f"Arbitrum Block: {arb_block}")
        
        # Test testnet networks
        goerli_block = config.get_block_number("ethereum_goerli")
        print(f"Ethereum Goerli Block: {goerli_block}")
        
    except Exception as e:
        print(f"Error in example: {e}")
