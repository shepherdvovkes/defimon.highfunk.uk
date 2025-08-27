#!/usr/bin/env python3
"""
Polygon Network QuickNode Configuration
Specialized configuration for comprehensive Polygon data collection
"""

import os
import requests
import json
from dataclasses import dataclass
from typing import Dict, Optional, List, Any
import urllib3
from datetime import datetime
import asyncio
import aiohttp
from web3 import Web3

# Disable SSL warnings for production use
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

@dataclass
class PolygonEndpoint:
    """Polygon-specific endpoint configuration"""
    name: str
    network_name: str
    http_url: str
    ws_url: str
    chain_id: int
    currency_symbol: str
    ssl_verify: bool
    enabled: bool = True
    priority: int = 5
    tvl_usd: Optional[float] = None
    volume_24h: Optional[float] = None
    block_time: Optional[float] = None
    gas_limit: Optional[int] = None

@dataclass
class DataCollectionConfig:
    """Configuration for data collection parameters"""
    batch_size: int = 100
    max_concurrent_requests: int = 10
    retry_attempts: int = 3
    retry_delay: float = 1.0
    rate_limit_per_second: int = 50
    historical_start_block: Optional[int] = None
    data_retention_days: int = 90
    enable_websocket: bool = True
    enable_historical_backfill: bool = True

class PolygonQuickNodeConfig:
    """Comprehensive Polygon network configuration for data collection"""
    
    def __init__(self, endpoint_name: str, token_id: str):
        self.endpoint_name = endpoint_name
        self.token_id = token_id
        self.endpoints = self._create_polygon_endpoints()
        self.collection_config = DataCollectionConfig()
        self.session = None
        
    def _create_polygon_endpoints(self) -> Dict[str, PolygonEndpoint]:
        """Create Polygon network endpoint configurations"""
        
        base_url = f"https://{self.endpoint_name}.quiknode.pro/{self.token_id}"
        base_ws_url = f"wss://{self.endpoint_name}.quiknode.pro/{self.token_id}"
        
        return {
            # Main Polygon Network
            "polygon_mainnet": PolygonEndpoint(
                name="Polygon Mainnet",
                network_name="polygon-mainnet",
                http_url=f"https://{self.endpoint_name}.polygon-mainnet.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.polygon-mainnet.quiknode.pro/{self.token_id}",
                chain_id=137,
                currency_symbol="MATIC",
                ssl_verify=False,
                enabled=True,
                priority=10,
                tvl_usd=850000000.0,  # $850M TVL
                volume_24h=300000000.0,  # $300M daily volume
                block_time=2.0,  # 2 seconds
                gas_limit=30000000
            ),
            
            # Polygon zkEVM
            "polygon_zkevm": PolygonEndpoint(
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
                volume_24h=15000000.0,  # $15M daily volume
                block_time=1.0,  # 1 second
                gas_limit=50000000
            ),
            
            # Polygon Mumbai Testnet
            "polygon_mumbai": PolygonEndpoint(
                name="Polygon Mumbai",
                network_name="polygon-mumbai",
                http_url=f"https://{self.endpoint_name}.polygon-mumbai.quiknode.pro/{self.token_id}",
                ws_url=f"wss://{self.endpoint_name}.polygon-mumbai.quiknode.pro/{self.token_id}",
                chain_id=80001,
                currency_symbol="MATIC",
                ssl_verify=False,
                enabled=True,
                priority=5,
                tvl_usd=0.0,  # Testnet
                volume_24h=0.0,  # Testnet
                block_time=2.0,
                gas_limit=30000000
            )
        }
    
    async def create_session(self):
        """Create aiohttp session for async requests"""
        if self.session is None:
            connector = aiohttp.TCPConnector(limit=self.collection_config.max_concurrent_requests)
            timeout = aiohttp.ClientTimeout(total=30)
            self.session = aiohttp.ClientSession(connector=connector, timeout=timeout)
        return self.session
    
    async def close_session(self):
        """Close aiohttp session"""
        if self.session:
            await self.session.close()
            self.session = None
    
    def get_endpoint(self, network: str) -> Optional[PolygonEndpoint]:
        """Get endpoint configuration for specific network"""
        return self.endpoints.get(network)
    
    def get_all_endpoints(self) -> Dict[str, PolygonEndpoint]:
        """Get all endpoint configurations"""
        return self.endpoints
    
    def get_enabled_endpoints(self) -> Dict[str, PolygonEndpoint]:
        """Get only enabled endpoints"""
        return {k: v for k, v in self.endpoints.items() if v.enabled}
    
    def get_priority_endpoints(self, min_priority: int = 5) -> Dict[str, PolygonEndpoint]:
        """Get endpoints with minimum priority"""
        return {k: v for k, v in self.endpoints.items() 
                if v.enabled and v.priority >= min_priority}
    
    async def test_connection(self, network: str) -> Dict[str, Any]:
        """Test connection to specific network"""
        endpoint = self.get_endpoint(network)
        if not endpoint:
            return {"success": False, "error": f"Network {network} not found"}
        
        try:
            session = await self.create_session()
            
            # Test basic RPC call
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_blockNumber",
                "params": [],
                "id": 1
            }
            
            async with session.post(endpoint.http_url, json=payload) as response:
                if response.status == 200:
                    data = await response.json()
                    return {
                        "success": True,
                        "network": network,
                        "block_number": int(data.get("result", "0x0"), 16),
                        "endpoint": endpoint.http_url
                    }
                else:
                    return {
                        "success": False,
                        "error": f"HTTP {response.status}",
                        "network": network
                    }
                    
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "network": network
            }
    
    async def test_all_connections(self) -> Dict[str, Dict[str, Any]]:
        """Test connections to all enabled networks"""
        results = {}
        enabled_endpoints = self.get_enabled_endpoints()
        
        for network in enabled_endpoints:
            results[network] = await self.test_connection(network)
            await asyncio.sleep(0.1)  # Rate limiting
        
        return results
    
    def get_network_stats(self) -> Dict[str, Dict[str, Any]]:
        """Get statistics for all networks"""
        stats = {}
        for network, endpoint in self.endpoints.items():
            stats[network] = {
                "name": endpoint.name,
                "chain_id": endpoint.chain_id,
                "currency": endpoint.currency_symbol,
                "tvl_usd": endpoint.tvl_usd,
                "volume_24h": endpoint.volume_24h,
                "block_time": endpoint.block_time,
                "gas_limit": endpoint.gas_limit,
                "enabled": endpoint.enabled,
                "priority": endpoint.priority
            }
        return stats
    
    def update_collection_config(self, **kwargs):
        """Update data collection configuration"""
        for key, value in kwargs.items():
            if hasattr(self.collection_config, key):
                setattr(self.collection_config, key, value)
    
    def get_collection_config(self) -> DataCollectionConfig:
        """Get current collection configuration"""
        return self.collection_config

# Example usage and testing
async def main():
    """Example usage of Polygon QuickNode configuration"""
    
    # Initialize configuration
    config = PolygonQuickNodeConfig(
        endpoint_name="your-endpoint-name",
        token_id="your-token-id"
    )
    
    # Test connections
    print("Testing Polygon network connections...")
    results = await config.test_all_connections()
    
    for network, result in results.items():
        status = "✅" if result["success"] else "❌"
        print(f"{status} {network}: {result}")
    
    # Print network statistics
    print("\nNetwork Statistics:")
    stats = config.get_network_stats()
    for network, stat in stats.items():
        print(f"{network}: {stat['name']} (Chain ID: {stat['chain_id']})")
        print(f"  TVL: ${stat['tvl_usd']:,.0f}")
        print(f"  24h Volume: ${stat['volume_24h']:,.0f}")
        print(f"  Block Time: {stat['block_time']}s")
        print()
    
    await config.close_session()

if __name__ == "__main__":
    asyncio.run(main())
