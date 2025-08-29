"""
Enhanced External APIs Router
Integrates expanded QuickNode (17 networks), Alchemy (6 networks), and advanced features
"""

import os
import json
import logging
import requests
from typing import Dict, Any, List, Optional
from fastapi import APIRouter, HTTPException, Depends, Query, Path
from fastapi.responses import JSONResponse
from datetime import datetime, timedelta
import asyncio
from concurrent.futures import ThreadPoolExecutor

# Configure logging
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/enhanced-external-apis", tags=["Enhanced External APIs"])

# Simple test endpoint
@router.get("/test")
async def test_enhanced_api():
    """Test endpoint to verify enhanced API router is working"""
    return {
        "status": "enhanced_api_working",
        "timestamp": datetime.now().isoformat(),
        "message": "Enhanced External APIs router is loaded successfully"
    }

# Enhanced API Configurations
class EnhancedAPIConfig:
    """Enhanced API configuration with multi-network support"""
    def __init__(self, api_key: str, base_url: str, headers: Optional[Dict[str, str]] = None):
        self.api_key = api_key
        self.base_url = base_url
        self.headers = headers or {}
        self.session = requests.Session()
        self.session.timeout = 30
        if self.headers:
            self.session.headers.update(self.headers)

# QuickNode Networks Configuration
QUICKNODE_NETWORKS = {
    "ethereum": {
        "name": "Ethereum",
        "chain_id": 1,
        "currency": "ETH",
        "priority": 10,
        "tvl_usd": 45000000000.0,
        "volume_24h": 2500000000.0
    },
    "base": {
        "name": "Base",
        "chain_id": 8453,
        "currency": "ETH",
        "priority": 9,
        "tvl_usd": 750000000.0,
        "volume_24h": 150000000.0
    },
    "bsc": {
        "name": "Binance Smart Chain",
        "chain_id": 56,
        "currency": "BNB",
        "priority": 9,
        "tvl_usd": 5200000000.0,
        "volume_24h": 800000000.0
    },
    "avalanche": {
        "name": "Avalanche C-Chain",
        "chain_id": 43114,
        "currency": "AVAX",
        "priority": 8,
        "tvl_usd": 1100000000.0,
        "volume_24h": 200000000.0
    },
    "polygon": {
        "name": "Polygon",
        "chain_id": 137,
        "currency": "MATIC",
        "priority": 9,
        "tvl_usd": 850000000.0,
        "volume_24h": 300000000.0
    },
    "arbitrum": {
        "name": "Arbitrum One",
        "chain_id": 42161,
        "currency": "ETH",
        "priority": 10,
        "tvl_usd": 2100000000.0,
        "volume_24h": 500000000.0
    },
    "optimism": {
        "name": "Optimism",
        "chain_id": 10,
        "currency": "ETH",
        "priority": 9,
        "tvl_usd": 850000000.0,
        "volume_24h": 250000000.0
    },
    "polygon_zkevm": {
        "name": "Polygon zkEVM",
        "chain_id": 1101,
        "currency": "ETH",
        "priority": 8,
        "tvl_usd": 45000000.0,
        "volume_24h": 15000000.0
    },
    "zksync_era": {
        "name": "zkSync Era",
        "chain_id": 324,
        "currency": "ETH",
        "priority": 8,
        "tvl_usd": 650000000.0,
        "volume_24h": 120000000.0
    },
    "linea": {
        "name": "Linea",
        "chain_id": 59144,
        "currency": "ETH",
        "priority": 7,
        "tvl_usd": 120000000.0,
        "volume_24h": 25000000.0
    },
    "scroll": {
        "name": "Scroll",
        "chain_id": 534352,
        "currency": "ETH",
        "priority": 7,
        "tvl_usd": 85000000.0,
        "volume_24h": 18000000.0
    },
    "mantle": {
        "name": "Mantle",
        "chain_id": 5000,
        "currency": "MNT",
        "priority": 6,
        "tvl_usd": 45000000.0,
        "volume_24h": 12000000.0
    },
    "metis": {
        "name": "Metis",
        "chain_id": 1088,
        "currency": "METIS",
        "priority": 6,
        "tvl_usd": 35000000.0,
        "volume_24h": 8000000.0
    },
    "cronos": {
        "name": "Cronos",
        "chain_id": 25,
        "currency": "CRO",
        "priority": 6,
        "tvl_usd": 180000000.0,
        "volume_24h": 35000000.0
    },
    "fantom": {
        "name": "Fantom",
        "chain_id": 250,
        "currency": "FTM",
        "priority": 6,
        "tvl_usd": 85000000.0,
        "volume_24h": 20000000.0
    },
    "celo": {
        "name": "Celo",
        "chain_id": 42220,
        "currency": "CELO",
        "priority": 5,
        "tvl_usd": 45000000.0,
        "volume_24h": 10000000.0
    },
    "gnosis": {
        "name": "Gnosis Chain",
        "chain_id": 100,
        "currency": "XDAI",
        "priority": 5,
        "tvl_usd": 35000000.0,
        "volume_24h": 8000000.0
    }
}

# Alchemy Networks Configuration
ALCHEMY_NETWORKS = {
    "ethereum": {
        "name": "Ethereum",
        "network": "eth-mainnet",
        "chain_id": 1,
        "currency": "ETH",
        "priority": 10,
        "features": ["rpc", "nft", "token", "transfers", "webhooks", "mempool", "debug"],
        "tvl_usd": 45000000000.0,
        "volume_24h": 2500000000.0
    },
    "polygon": {
        "name": "Polygon",
        "network": "polygon-mainnet",
        "chain_id": 137,
        "currency": "MATIC",
        "priority": 9,
        "features": ["rpc", "nft", "token", "transfers", "webhooks"],
        "tvl_usd": 850000000.0,
        "volume_24h": 300000000.0
    },
    "arbitrum": {
        "name": "Arbitrum One",
        "network": "arb-mainnet",
        "chain_id": 42161,
        "currency": "ETH",
        "priority": 10,
        "features": ["rpc", "nft", "token", "transfers", "webhooks"],
        "tvl_usd": 2100000000.0,
        "volume_24h": 500000000.0
    },
    "optimism": {
        "name": "Optimism",
        "network": "opt-mainnet",
        "chain_id": 10,
        "currency": "ETH",
        "priority": 9,
        "features": ["rpc", "nft", "token", "transfers", "webhooks"],
        "tvl_usd": 850000000.0,
        "volume_24h": 250000000.0
    },
    "base": {
        "name": "Base",
        "network": "base-mainnet",
        "chain_id": 8453,
        "currency": "ETH",
        "priority": 8,
        "features": ["rpc", "nft", "token", "transfers", "webhooks"],
        "tvl_usd": 750000000.0,
        "volume_24h": 150000000.0
    },
    "starknet": {
        "name": "StarkNet",
        "network": "starknet-mainnet",
        "chain_id": 0x534e5f4d41494e,
        "currency": "ETH",
        "priority": 7,
        "features": ["rpc", "nft", "token", "transfers", "webhooks"],
        "tvl_usd": 180000000.0,
        "volume_24h": 45000000.0
    }
}

# Initialize API configurations
def get_quicknode_config() -> EnhancedAPIConfig:
    """Get QuickNode configuration"""
    endpoint_name = os.getenv("QUICKNODE_ENDPOINT_NAME", "hidden-holy-seed")
    token_id = os.getenv("QUICKNODE_TOKEN_ID", "97d6d8e7659b49b126c43455edc4607949bfb52b")
    return EnhancedAPIConfig(
        api_key="",
        base_url=f"https://{endpoint_name}.quiknode.pro/{token_id}",
        headers={"Content-Type": "application/json"}
    )

def get_alchemy_config() -> EnhancedAPIConfig:
    """Get Alchemy configuration"""
    api_key = os.getenv("ALCHEMY_API_KEY", "")
    return EnhancedAPIConfig(
        api_key=api_key,
        base_url="https://eth-mainnet.g.alchemy.com/v2",
        headers={"Content-Type": "application/json"}
    )

# Enhanced Service Classes
class EnhancedQuickNodeService:
    """Enhanced QuickNode API service with multi-network support"""
    
    def __init__(self):
        self.config = get_quicknode_config()
        self.endpoint_name = os.getenv("QUICKNODE_ENDPOINT_NAME", "hidden-holy-seed")
        self.token_id = os.getenv("QUICKNODE_TOKEN_ID", "97d6d8e7659b49b126c43455edc4607949bfb52b")
    
    def _get_network_url(self, network: str) -> str:
        """Get URL for specific network"""
        if network == "ethereum":
            return self.config.base_url
        
        # For other networks, construct the URL
        return f"https://{self.endpoint_name}.{network}-mainnet.quiknode.pro/{self.token_id}"
    
    async def get_block_number(self, network: str = "ethereum") -> Dict[str, Any]:
        """Get latest block number for specific network"""
        try:
            if network not in QUICKNODE_NETWORKS:
                return {"success": False, "error": f"Network {network} not supported"}
            
            network_info = QUICKNODE_NETWORKS[network]
            url = self._get_network_url(network)
            
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_blockNumber",
                "params": [],
                "id": 1
            }
            
            response = self.config.session.post(url, json=payload)
            response.raise_for_status()
            
            result = response.json()
            block_number = int(result.get("result", "0x0"), 16)
            
            return {
                "success": True,
                "network": network,
                "network_name": network_info["name"],
                "chain_id": network_info["chain_id"],
                "block_number": block_number,
                "hex_block_number": result.get("result", "0x0"),
                "currency": network_info["currency"],
                "priority": network_info["priority"],
                "tvl_usd": network_info["tvl_usd"],
                "volume_24h": network_info["volume_24h"]
            }
        except Exception as e:
            logger.error(f"QuickNode get_block_number error for {network}: {e}")
            return {"success": False, "error": str(e), "network": network}
    
    async def get_gas_price(self, network: str = "ethereum") -> Dict[str, Any]:
        """Get current gas price for specific network"""
        try:
            if network not in QUICKNODE_NETWORKS:
                return {"success": False, "error": f"Network {network} not supported"}
            
            network_info = QUICKNODE_NETWORKS[network]
            url = self._get_network_url(network)
            
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_gasPrice",
                "params": [],
                "id": 1
            }
            
            response = self.config.session.post(url, json=payload)
            response.raise_for_status()
            
            result = response.json()
            gas_price_hex = result.get("result", "0x0")
            gas_price_int = int(gas_price_hex, 16)
            
            return {
                "success": True,
                "network": network,
                "network_name": network_info["name"],
                "chain_id": network_info["chain_id"],
                "gas_price_wei": gas_price_int,
                "gas_price_gwei": gas_price_int / 10**9,
                "hex_gas_price": gas_price_hex,
                "currency": network_info["currency"],
                "priority": network_info["priority"]
            }
        except Exception as e:
            logger.error(f"QuickNode get_gas_price error for {network}: {e}")
            return {"success": False, "error": str(e), "network": network}
    
    async def get_balance(self, address: str, network: str = "ethereum") -> Dict[str, Any]:
        """Get account balance for specific network"""
        try:
            if network not in QUICKNODE_NETWORKS:
                return {"success": False, "error": f"Network {network} not supported"}
            
            network_info = QUICKNODE_NETWORKS[network]
            url = self._get_network_url(network)
            
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_getBalance",
                "params": [address, "latest"],
                "id": 1
            }
            
            response = self.config.session.post(url, json=payload)
            response.raise_for_status()
            
            result = response.json()
            balance_hex = result.get("result", "0x0")
            balance_int = int(balance_hex, 16)
            
            return {
                "success": True,
                "network": network,
                "network_name": network_info["name"],
                "chain_id": network_info["chain_id"],
                "address": address,
                "balance_wei": balance_int,
                "balance_eth": balance_int / 10**18,
                "hex_balance": balance_hex,
                "currency": network_info["currency"],
                "priority": network_info["priority"]
            }
        except Exception as e:
            logger.error(f"QuickNode get_balance error for {network}: {e}")
            return {"success": False, "error": str(e), "network": network}
    
    async def get_chain_id(self, network: str = "ethereum") -> Dict[str, Any]:
        """Get chain ID for specific network"""
        try:
            if network not in QUICKNODE_NETWORKS:
                return {"success": False, "error": f"Network {network} not supported"}
            
            network_info = QUICKNODE_NETWORKS[network]
            url = self._get_network_url(network)
            
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_chainId",
                "params": [],
                "id": 1
            }
            
            response = self.config.session.post(url, json=payload)
            response.raise_for_status()
            
            result = response.json()
            chain_id_hex = result.get("result", "0x1")
            chain_id_int = int(chain_id_hex, 16)
            
            return {
                "success": True,
                "network": network,
                "network_name": network_info["name"],
                "chain_id": chain_id_int,
                "hex_chain_id": chain_id_hex,
                "currency": network_info["currency"],
                "priority": network_info["priority"]
            }
        except Exception as e:
            logger.error(f"QuickNode get_chain_id error for {network}: {e}")
            return {"success": False, "error": str(e), "network": network}

class EnhancedAlchemyService:
    """Enhanced Alchemy API service with multi-network and advanced features"""
    
    def __init__(self):
        self.config = get_alchemy_config()
    
    def _get_network_url(self, network: str) -> str:
        """Get URL for specific network"""
        if network not in ALCHEMY_NETWORKS:
            raise ValueError(f"Network {network} not supported by Alchemy")
        
        network_config = ALCHEMY_NETWORKS[network]
        return f"https://{network_config['network']}.g.alchemy.com/v2/{self.config.api_key}"
    
    async def get_block_number(self, network: str = "ethereum") -> Dict[str, Any]:
        """Get latest block number for specific network"""
        try:
            if network not in ALCHEMY_NETWORKS:
                return {"success": False, "error": f"Network {network} not supported"}
            
            network_info = ALCHEMY_NETWORKS[network]
            url = self._get_network_url(network)
            
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_blockNumber",
                "params": [],
                "id": 1
            }
            
            response = self.config.session.post(url, json=payload)
            response.raise_for_status()
            
            result = response.json()
            block_number = int(result.get("result", "0x0"), 16)
            
            return {
                "success": True,
                "network": network,
                "network_name": network_info["name"],
                "chain_id": network_info["chain_id"],
                "block_number": block_number,
                "hex_block_number": result.get("result", "0x0"),
                "currency": network_info["currency"],
                "priority": network_info["priority"],
                "features": network_info["features"],
                "tvl_usd": network_info["tvl_usd"],
                "volume_24h": network_info["volume_24h"],
                "provider": "Alchemy"
            }
        except Exception as e:
            logger.error(f"Alchemy get_block_number error for {network}: {e}")
            return {"success": False, "error": str(e), "network": network}
    
    async def get_nft_metadata(self, network: str, contract_address: str, token_id: str) -> Dict[str, Any]:
        """Get NFT metadata using Alchemy NFT API"""
        try:
            if network not in ALCHEMY_NETWORKS:
                return {"success": False, "error": f"Network {network} not supported"}
            
            network_info = ALCHEMY_NETWORKS[network]
            if "nft" not in network_info["features"]:
                return {"success": False, "error": f"NFT API not supported for {network}"}
            
            url = self._get_network_url(network)
            nft_url = f"{url}/getNFTMetadata"
            
            params = {
                "contractAddress": contract_address,
                "tokenId": token_id
            }
            
            response = self.config.session.get(nft_url, params=params)
            response.raise_for_status()
            
            data = response.json()
            
            return {
                "success": True,
                "network": network,
                "network_name": network_info["name"],
                "contract_address": contract_address,
                "token_id": token_id,
                "metadata": data,
                "provider": "Alchemy"
            }
        except Exception as e:
            logger.error(f"Alchemy get_nft_metadata error for {network}: {e}")
            return {"success": False, "error": str(e), "network": network}
    
    async def get_token_metadata(self, network: str, contract_address: str) -> Dict[str, Any]:
        """Get ERC-20 token metadata"""
        try:
            if network not in ALCHEMY_NETWORKS:
                return {"success": False, "error": f"Network {network} not supported"}
            
            network_info = ALCHEMY_NETWORKS[network]
            if "token" not in network_info["features"]:
                return {"success": False, "error": f"Token API not supported for {network}"}
            
            url = self._get_network_url(network)
            token_url = f"{url}/getTokenMetadata"
            
            params = {
                "contractAddress": contract_address
            }
            
            response = self.config.session.get(token_url, params=params)
            response.raise_for_status()
            
            data = response.json()
            
            return {
                "success": True,
                "network": network,
                "network_name": network_info["name"],
                "contract_address": contract_address,
                "metadata": data,
                "provider": "Alchemy"
            }
        except Exception as e:
            logger.error(f"Alchemy get_token_metadata error for {network}: {e}")
            return {"success": False, "error": str(e), "network": network}
    
    async def get_asset_transfers(self, network: str, from_address: str = None, to_address: str = None, 
                                max_count: int = 100) -> Dict[str, Any]:
        """Get asset transfers for an address"""
        try:
            if network not in ALCHEMY_NETWORKS:
                return {"success": False, "error": f"Network {network} not supported"}
            
            network_info = ALCHEMY_NETWORKS[network]
            if "transfers" not in network_info["features"]:
                return {"success": False, "error": f"Transfers API not supported for {network}"}
            
            url = self._get_network_url(network)
            transfers_url = f"{url}/getAssetTransfers"
            
            params = {
                "maxCount": max_count
            }
            
            if from_address:
                params["fromAddress"] = from_address
            if to_address:
                params["toAddress"] = to_address
            
            response = self.config.session.get(transfers_url, params=params)
            response.raise_for_status()
            
            data = response.json()
            
            return {
                "success": True,
                "network": network,
                "network_name": network_info["name"],
                "from_address": from_address,
                "to_address": to_address,
                "transfers": data,
                "provider": "Alchemy"
            }
        except Exception as e:
            logger.error(f"Alchemy get_asset_transfers error for {network}: {e}")
            return {"success": False, "error": str(e), "network": network}

# API Endpoints
@router.get("/health")
async def enhanced_health_check():
    """Enhanced health check for external APIs"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "providers": {
            "quicknode": {
                "networks": len(QUICKNODE_NETWORKS),
                "supported_networks": list(QUICKNODE_NETWORKS.keys())
            },
            "alchemy": {
                "networks": len(ALCHEMY_NETWORKS),
                "supported_networks": list(ALCHEMY_NETWORKS.keys())
            }
        },
        "total_networks": len(QUICKNODE_NETWORKS) + len(ALCHEMY_NETWORKS)
    }

@router.get("/quicknode/networks")
async def get_quicknode_networks():
    """Get all supported QuickNode networks"""
    return {
        "networks": QUICKNODE_NETWORKS,
        "total": len(QUICKNODE_NETWORKS),
        "by_priority": {
            "high": [k for k, v in QUICKNODE_NETWORKS.items() if v["priority"] >= 8],
            "medium": [k for k, v in QUICKNODE_NETWORKS.items() if 6 <= v["priority"] < 8],
            "low": [k for k, v in QUICKNODE_NETWORKS.items() if v["priority"] < 6]
        }
    }

@router.get("/alchemy/networks")
async def get_alchemy_networks():
    """Get all supported Alchemy networks"""
    return {
        "networks": ALCHEMY_NETWORKS,
        "total": len(ALCHEMY_NETWORKS),
        "by_priority": {
            "high": [k for k, v in ALCHEMY_NETWORKS.items() if v["priority"] >= 8],
            "medium": [k for k, v in ALCHEMY_NETWORKS.items() if 6 <= v["priority"] < 8],
            "low": [k for k, v in ALCHEMY_NETWORKS.items() if v["priority"] < 6]
        }
    }

@router.get("/quicknode/{network}/block-number")
async def get_quicknode_network_block_number(network: str = Path(..., description="Network name")):
    """Get latest block number for specific QuickNode network"""
    service = EnhancedQuickNodeService()
    result = await service.get_block_number(network)
    
    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])
    
    return result

@router.get("/quicknode/{network}/gas-price")
async def get_quicknode_network_gas_price(network: str = Path(..., description="Network name")):
    """Get current gas price for specific QuickNode network"""
    service = EnhancedQuickNodeService()
    result = await service.get_gas_price(network)
    
    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])
    
    return result

@router.get("/quicknode/{network}/balance/{address}")
async def get_quicknode_network_balance(
    network: str = Path(..., description="Network name"),
    address: str = Path(..., description="Wallet address")
):
    """Get account balance for specific QuickNode network"""
    service = EnhancedQuickNodeService()
    result = await service.get_balance(address, network)
    
    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])
    
    return result

@router.get("/quicknode/{network}/chain-id")
async def get_quicknode_network_chain_id(network: str = Path(..., description="Network name")):
    """Get chain ID for specific QuickNode network"""
    service = EnhancedQuickNodeService()
    result = await service.get_chain_id(network)
    
    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])
    
    return result

@router.get("/alchemy/{network}/block-number")
async def get_alchemy_network_block_number(network: str = Path(..., description="Network name")):
    """Get latest block number for specific Alchemy network"""
    service = EnhancedAlchemyService()
    result = await service.get_block_number(network)
    
    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])
    
    return result

@router.get("/alchemy/{network}/nft/{contract_address}/{token_id}")
async def get_alchemy_nft_metadata(
    network: str = Path(..., description="Network name"),
    contract_address: str = Path(..., description="NFT contract address"),
    token_id: str = Path(..., description="Token ID")
):
    """Get NFT metadata for specific network"""
    service = EnhancedAlchemyService()
    result = await service.get_nft_metadata(network, contract_address, token_id)
    
    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])
    
    return result

@router.get("/alchemy/{network}/token/{contract_address}")
async def get_alchemy_token_metadata(
    network: str = Path(..., description="Network name"),
    contract_address: str = Path(..., description="Token contract address")
):
    """Get token metadata for specific network"""
    service = EnhancedAlchemyService()
    result = await service.get_token_metadata(network, contract_address)
    
    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])
    
    return result

@router.get("/alchemy/{network}/transfers")
async def get_alchemy_asset_transfers(
    network: str = Path(..., description="Network name"),
    from_address: str = Query(None, description="From address"),
    to_address: str = Query(None, description="To address"),
    max_count: int = Query(100, ge=1, le=1000, description="Maximum number of transfers")
):
    """Get asset transfers for specific network"""
    service = EnhancedAlchemyService()
    result = await service.get_asset_transfers(network, from_address, to_address, max_count)
    
    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])
    
    return result

@router.get("/quicknode/all-networks/status")
async def get_all_quicknode_networks_status():
    """Get status for all QuickNode networks"""
    service = EnhancedQuickNodeService()
    
    tasks = []
    for network in QUICKNODE_NETWORKS.keys():
        tasks.append(service.get_block_number(network))
    
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    network_statuses = {}
    for i, (network, result) in enumerate(zip(QUICKNODE_NETWORKS.keys(), results)):
        if isinstance(result, Exception):
            network_statuses[network] = {"success": False, "error": str(result)}
        else:
            network_statuses[network] = result
    
    return {
        "timestamp": datetime.now().isoformat(),
        "total_networks": len(QUICKNODE_NETWORKS),
        "working_networks": len([r for r in results if not isinstance(r, Exception) and r.get("success")]),
        "network_statuses": network_statuses
    }

@router.get("/alchemy/all-networks/status")
async def get_all_alchemy_networks_status():
    """Get status for all Alchemy networks"""
    service = EnhancedAlchemyService()
    
    tasks = []
    for network in ALCHEMY_NETWORKS.keys():
        tasks.append(service.get_block_number(network))
    
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    network_statuses = {}
    for i, (network, result) in enumerate(zip(ALCHEMY_NETWORKS.keys(), results)):
        if isinstance(result, Exception):
            network_statuses[network] = {"success": False, "error": str(result)}
        else:
            network_statuses[network] = result
    
    return {
        "timestamp": datetime.now().isoformat(),
        "total_networks": len(ALCHEMY_NETWORKS),
        "working_networks": len([r for r in results if not isinstance(r, Exception) and r.get("success")]),
        "network_statuses": network_statuses
    }

@router.get("/comprehensive-summary")
async def get_comprehensive_summary():
    """Get comprehensive summary from all enhanced APIs"""
    try:
        quicknode_service = EnhancedQuickNodeService()
        alchemy_service = EnhancedAlchemyService()
        
        # QuickNode tasks
        quicknode_tasks = []
        for network in QUICKNODE_NETWORKS.keys():
            quicknode_tasks.append(quicknode_service.get_block_number(network))
        
        # Alchemy tasks
        alchemy_tasks = []
        for network in ALCHEMY_NETWORKS.keys():
            alchemy_tasks.append(alchemy_service.get_block_number(network))
        
        # Run all tasks concurrently
        all_tasks = quicknode_tasks + alchemy_tasks
        results = await asyncio.gather(*all_tasks, return_exceptions=True)
        
        # Process results
        quicknode_results = results[:len(quicknode_tasks)]
        alchemy_results = results[len(quicknode_tasks):]
        
        summary = {
            "timestamp": datetime.now().isoformat(),
            "total_networks": len(QUICKNODE_NETWORKS) + len(ALCHEMY_NETWORKS),
            "providers": {
                "quicknode": {
                    "total_networks": len(QUICKNODE_NETWORKS),
                    "working_networks": len([r for r in quicknode_results if not isinstance(r, Exception) and r.get("success")]),
                    "networks": {}
                },
                "alchemy": {
                    "total_networks": len(ALCHEMY_NETWORKS),
                    "working_networks": len([r for r in alchemy_results if not isinstance(r, Exception) and r.get("success")]),
                    "networks": {}
                }
            },
            "statistics": {
                "total_tvl": sum(network["tvl_usd"] for network in QUICKNODE_NETWORKS.values()) + 
                           sum(network["tvl_usd"] for network in ALCHEMY_NETWORKS.values()),
                "total_volume_24h": sum(network["volume_24h"] for network in QUICKNODE_NETWORKS.values()) + 
                                  sum(network["volume_24h"] for network in ALCHEMY_NETWORKS.values())
            }
        }
        
        # Add QuickNode results
        for i, (network, result) in enumerate(zip(QUICKNODE_NETWORKS.keys(), quicknode_results)):
            if isinstance(result, Exception):
                summary["providers"]["quicknode"]["networks"][network] = {"success": False, "error": str(result)}
            else:
                summary["providers"]["quicknode"]["networks"][network] = result
        
        # Add Alchemy results
        for i, (network, result) in enumerate(zip(ALCHEMY_NETWORKS.keys(), alchemy_results)):
            if isinstance(result, Exception):
                summary["providers"]["alchemy"]["networks"][network] = {"success": False, "error": str(result)}
            else:
                summary["providers"]["alchemy"]["networks"][network] = result
        
        return summary
        
    except Exception as e:
        logger.error(f"Error getting comprehensive summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))
