"""
External APIs Router
Integrates QuickNode, Blast, CoinGecko, CoinCap, and GitHub APIs
"""

import os
import json
import logging
import requests
from typing import Dict, Any, List, Optional
from fastapi import APIRouter, HTTPException, Depends, Query
from fastapi.responses import JSONResponse
from datetime import datetime, timedelta
import asyncio
from concurrent.futures import ThreadPoolExecutor

# Configure logging
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/external-apis", tags=["External APIs"])

# API Configurations
class APIConfig:
    """Base API configuration"""
    def __init__(self, api_key: str, base_url: str, headers: Optional[Dict[str, str]] = None):
        self.api_key = api_key
        self.base_url = base_url
        self.headers = headers or {}
        self.session = requests.Session()
        self.session.timeout = 30
        if self.headers:
            self.session.headers.update(self.headers)

# Initialize API configurations
def get_quicknode_config() -> APIConfig:
    """Get QuickNode configuration"""
    api_key = os.getenv("QUICKNODE_API_KEY", "")
    return APIConfig(
        api_key=api_key,
        base_url=os.getenv("QUICKNODE_HTTP_URL", "https://hidden-holy-seed.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b"),
        headers={"Content-Type": "application/json"}
    )

def get_blast_config() -> APIConfig:
    """Get Blast configuration"""
    api_key = os.getenv("BLAST_API_KEY", "")
    return APIConfig(
        api_key=api_key,
        base_url="https://api.blast.io",
        headers={"Authorization": f"Bearer {api_key}"} if api_key else {}
    )

def get_coingecko_config() -> APIConfig:
    """Get CoinGecko configuration"""
    api_key = os.getenv("COINGECKO_API_KEY", "")
    return APIConfig(
        api_key=api_key,
        base_url="https://api.coingecko.com/api/v3",
        headers={"X-CG-API-KEY": api_key} if api_key else {}
    )

def get_coincap_config() -> APIConfig:
    """Get CoinCap configuration"""
    api_key = os.getenv("COINCAP_API_KEY", "")
    return APIConfig(
        api_key=api_key,
        base_url="https://api.coincap.io/v2",
        headers={"Authorization": f"Bearer {api_key}"} if api_key else {}
    )

def get_github_config() -> APIConfig:
    """Get GitHub configuration"""
    api_key = os.getenv("GITHUB_API_TOKEN", "")
    return APIConfig(
        api_key=api_key,
        base_url="https://api.github.com",
        headers={
            "Authorization": f"token {api_key}",
            "Accept": "application/vnd.github.v3+json"
        } if api_key else {}
    )

# API Service Classes
class QuickNodeService:
    """QuickNode API service"""
    
    def __init__(self):
        self.config = get_quicknode_config()
    
    async def get_block_number(self) -> Dict[str, Any]:
        """Get latest block number"""
        try:
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_blockNumber",
                "params": [],
                "id": 1
            }
            
            response = self.config.session.post(self.config.base_url, json=payload)
            response.raise_for_status()
            
            result = response.json()
            return {
                "success": True,
                "block_number": int(result.get("result", "0x0"), 16),
                "hex_block_number": result.get("result", "0x0")
            }
        except Exception as e:
            logger.error(f"QuickNode get_block_number error: {e}")
            return {"success": False, "error": str(e)}
    
    async def get_gas_price(self) -> Dict[str, Any]:
        """Get current gas price"""
        try:
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_gasPrice",
                "params": [],
                "id": 1
            }
            
            response = self.config.session.post(self.config.base_url, json=payload)
            response.raise_for_status()
            
            result = response.json()
            gas_price_hex = result.get("result", "0x0")
            gas_price_int = int(gas_price_hex, 16)
            
            return {
                "success": True,
                "gas_price_wei": gas_price_int,
                "gas_price_gwei": gas_price_int / 10**9,
                "hex_gas_price": gas_price_hex
            }
        except Exception as e:
            logger.error(f"QuickNode get_gas_price error: {e}")
            return {"success": False, "error": str(e)}
    
    async def get_balance(self, address: str) -> Dict[str, Any]:
        """Get account balance"""
        try:
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_getBalance",
                "params": [address, "latest"],
                "id": 1
            }
            
            response = self.config.session.post(self.config.base_url, json=payload)
            response.raise_for_status()
            
            result = response.json()
            balance_hex = result.get("result", "0x0")
            balance_int = int(balance_hex, 16)
            
            return {
                "success": True,
                "address": address,
                "balance_wei": balance_int,
                "balance_eth": balance_int / 10**18,
                "hex_balance": balance_hex
            }
        except Exception as e:
            logger.error(f"QuickNode get_balance error: {e}")
            return {"success": False, "error": str(e)}

class CoinGeckoService:
    """CoinGecko API service"""
    
    def __init__(self):
        self.config = get_coingecko_config()
    
    async def get_bitcoin_price(self) -> Dict[str, Any]:
        """Get Bitcoin price data"""
        try:
            params = {
                "ids": "bitcoin",
                "vs_currencies": "usd,eur,btc",
                "include_24hr_change": "true",
                "include_market_cap": "true"
            }
            
            response = self.config.session.get(f"{self.config.base_url}/simple/price", params=params)
            response.raise_for_status()
            
            data = response.json()
            return {
                "success": True,
                "data": data
            }
        except Exception as e:
            logger.error(f"CoinGecko get_bitcoin_price error: {e}")
            return {"success": False, "error": str(e)}
    
    async def get_top_coins(self, limit: int = 10) -> Dict[str, Any]:
        """Get top coins by market cap"""
        try:
            params = {
                "vs_currency": "usd",
                "order": "market_cap_desc",
                "per_page": str(limit),
                "page": "1",
                "sparkline": "false"
            }
            
            response = self.config.session.get(f"{self.config.base_url}/coins/markets", params=params)
            response.raise_for_status()
            
            data = response.json()
            return {
                "success": True,
                "data": data
            }
        except Exception as e:
            logger.error(f"CoinGecko get_top_coins error: {e}")
            return {"success": False, "error": str(e)}

class CoinCapService:
    """CoinCap API service"""
    
    def __init__(self):
        self.config = get_coincap_config()
    
    async def get_assets(self) -> Dict[str, Any]:
        """Get all assets"""
        try:
            response = self.config.session.get(f"{self.config.base_url}/assets")
            response.raise_for_status()
            
            data = response.json()
            return {
                "success": True,
                "data": data
            }
        except Exception as e:
            logger.error(f"CoinCap get_assets error: {e}")
            return {"success": False, "error": str(e)}
    
    async def get_bitcoin_data(self) -> Dict[str, Any]:
        """Get Bitcoin specific data"""
        try:
            response = self.config.session.get(f"{self.config.base_url}/assets/bitcoin")
            response.raise_for_status()
            
            data = response.json()
            return {
                "success": True,
                "data": data
            }
        except Exception as e:
            logger.error(f"CoinCap get_bitcoin_data error: {e}")
            return {"success": False, "error": str(e)}

class GitHubService:
    """GitHub API service"""
    
    def __init__(self):
        self.config = get_github_config()
        self.username = os.getenv("GITHUB_USERNAME", "")
    
    async def get_user_info(self) -> Dict[str, Any]:
        """Get authenticated user information"""
        try:
            response = self.config.session.get(f"{self.config.base_url}/user")
            response.raise_for_status()
            
            data = response.json()
            return {
                "success": True,
                "data": data
            }
        except Exception as e:
            logger.error(f"GitHub get_user_info error: {e}")
            return {"success": False, "error": str(e)}
    
    async def get_user_repos(self) -> Dict[str, Any]:
        """Get user repositories"""
        try:
            response = self.config.session.get(f"{self.config.base_url}/user/repos")
            response.raise_for_status()
            
            data = response.json()
            return {
                "success": True,
                "data": data
            }
        except Exception as e:
            logger.error(f"GitHub get_user_repos error: {e}")
            return {"success": False, "error": str(e)}

# API Endpoints
@router.get("/health")
async def health_check():
    """Health check for external APIs"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "apis": ["quicknode", "coingecko", "coincap", "github"]
    }

@router.get("/quicknode/block-number")
async def get_quicknode_block_number():
    """Get latest block number from QuickNode"""
    service = QuickNodeService()
    result = await service.get_block_number()
    
    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])
    
    return result

@router.get("/quicknode/gas-price")
async def get_quicknode_gas_price():
    """Get current gas price from QuickNode"""
    service = QuickNodeService()
    result = await service.get_gas_price()
    
    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])
    
    return result

@router.get("/quicknode/balance/{address}")
async def get_quicknode_balance(address: str):
    """Get account balance from QuickNode"""
    service = QuickNodeService()
    result = await service.get_balance(address)
    
    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])
    
    return result

@router.get("/coingecko/bitcoin-price")
async def get_coingecko_bitcoin_price():
    """Get Bitcoin price from CoinGecko"""
    service = CoinGeckoService()
    result = await service.get_bitcoin_price()
    
    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])
    
    return result

@router.get("/coingecko/top-coins")
async def get_coingecko_top_coins(limit: int = Query(10, ge=1, le=100)):
    """Get top coins from CoinGecko"""
    service = CoinGeckoService()
    result = await service.get_top_coins(limit)
    
    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])
    
    return result

@router.get("/coincap/assets")
async def get_coincap_assets():
    """Get all assets from CoinCap"""
    service = CoinCapService()
    result = await service.get_assets()
    
    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])
    
    return result

@router.get("/coincap/bitcoin")
async def get_coincap_bitcoin():
    """Get Bitcoin data from CoinCap"""
    service = CoinCapService()
    result = await service.get_bitcoin_data()
    
    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])
    
    return result

@router.get("/github/user")
async def get_github_user():
    """Get GitHub user information"""
    service = GitHubService()
    result = await service.get_user_info()
    
    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])
    
    return result

@router.get("/github/repos")
async def get_github_repos():
    """Get GitHub user repositories"""
    service = GitHubService()
    result = await service.get_user_repos()
    
    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])
    
    return result

@router.get("/summary")
async def get_all_apis_summary():
    """Get summary from all external APIs"""
    try:
        # Create services
        quicknode_service = QuickNodeService()
        coingecko_service = CoinGeckoService()
        coincap_service = CoinCapService()
        github_service = GitHubService()
        
        # Run all requests concurrently
        tasks = [
            quicknode_service.get_block_number(),
            quicknode_service.get_gas_price(),
            coingecko_service.get_bitcoin_price(),
            coincap_service.get_bitcoin_data(),
            github_service.get_user_info()
        ]
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        summary = {
            "timestamp": datetime.now().isoformat(),
            "quicknode": {
                "block_number": results[0] if not isinstance(results[0], Exception) else {"error": str(results[0])},
                "gas_price": results[1] if not isinstance(results[1], Exception) else {"error": str(results[1])}
            },
            "coingecko": {
                "bitcoin_price": results[2] if not isinstance(results[2], Exception) else {"error": str(results[2])}
            },
            "coincap": {
                "bitcoin_data": results[3] if not isinstance(results[3], Exception) else {"error": str(results[3])}
            },
            "github": {
                "user_info": results[4] if not isinstance(results[4], Exception) else {"error": str(results[4])}
            }
        }
        
        return summary
        
    except Exception as e:
        logger.error(f"Error getting API summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))
