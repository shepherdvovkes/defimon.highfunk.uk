from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os
from dotenv import load_dotenv
import requests
import asyncio
from datetime import datetime

# Load environment variables
load_dotenv()

app = FastAPI(
    title="DeFi Analytics API - Test Server",
    description="Test server for external APIs integration",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API Configurations
class APIConfig:
    def __init__(self, api_key: str, base_url: str, headers: dict = None):
        self.api_key = api_key
        self.base_url = base_url
        self.headers = headers or {}
        self.session = requests.Session()
        self.session.timeout = 30
        if self.headers:
            self.session.headers.update(self.headers)

# Initialize API configurations
def get_quicknode_config():
    api_key = os.getenv("QUICKNODE_API_KEY", "")
    return APIConfig(
        api_key=api_key,
        base_url=os.getenv("QUICKNODE_HTTP_URL", "https://hidden-holy-seed.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b"),
        headers={"Content-Type": "application/json"}
    )

def get_coingecko_config():
    api_key = os.getenv("COINGECKO_API_KEY", "")
    return APIConfig(
        api_key=api_key,
        base_url="https://api.coingecko.com/api/v3",
        headers={"X-CG-API-KEY": api_key} if api_key else {}
    )

def get_coincap_config():
    api_key = os.getenv("COINCAP_API_KEY", "")
    return APIConfig(
        api_key=api_key,
        base_url="https://api.coincap.io/v2",
        headers={"Authorization": f"Bearer {api_key}"} if api_key else {}
    )

# API Service Classes
class QuickNodeService:
    def __init__(self):
        self.config = get_quicknode_config()
    
    async def get_block_number(self):
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
            return {"success": False, "error": str(e)}
    
    async def get_gas_price(self):
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
            return {"success": False, "error": str(e)}

class CoinGeckoService:
    def __init__(self):
        self.config = get_coingecko_config()
    
    async def get_bitcoin_price(self):
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
            return {"success": False, "error": str(e)}
    
    async def get_top_coins(self, limit: int = 10):
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
            return {"success": False, "error": str(e)}

class CoinCapService:
    def __init__(self):
        self.config = get_coincap_config()
    
    async def get_assets(self):
        try:
            response = self.config.session.get(f"{self.config.base_url}/assets")
            response.raise_for_status()
            
            data = response.json()
            return {
                "success": True,
                "data": data
            }
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def get_bitcoin_data(self):
        try:
            response = self.config.session.get(f"{self.config.base_url}/assets/bitcoin")
            response.raise_for_status()
            
            data = response.json()
            return {
                "success": True,
                "data": data
            }
        except Exception as e:
            return {"success": False, "error": str(e)}

# API Endpoints
@app.get("/")
async def root():
    return {
        "name": "DeFi Analytics API - Test Server",
        "version": "1.0.0",
        "description": "Test server for external APIs integration",
        "endpoints": [
            "/health",
            "/api/external-apis/health",
            "/api/external-apis/quicknode/block-number",
            "/api/external-apis/quicknode/gas-price",
            "/api/external-apis/coingecko/bitcoin-price",
            "/api/external-apis/coingecko/top-coins",
            "/api/external-apis/coincap/assets",
            "/api/external-apis/coincap/bitcoin",
            "/api/external-apis/summary"
        ]
    }

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "server": "test-server"
    }

@app.get("/api/external-apis/health")
async def external_apis_health():
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "apis": ["quicknode", "coingecko", "coincap"]
    }

@app.get("/api/external-apis/quicknode/block-number")
async def get_quicknode_block_number():
    service = QuickNodeService()
    result = await service.get_block_number()
    return result

@app.get("/api/external-apis/quicknode/gas-price")
async def get_quicknode_gas_price():
    service = QuickNodeService()
    result = await service.get_gas_price()
    return result

@app.get("/api/external-apis/coingecko/bitcoin-price")
async def get_coingecko_bitcoin_price():
    service = CoinGeckoService()
    result = await service.get_bitcoin_price()
    return result

@app.get("/api/external-apis/coingecko/top-coins")
async def get_coingecko_top_coins(limit: int = 10):
    service = CoinGeckoService()
    result = await service.get_top_coins(limit)
    return result

@app.get("/api/external-apis/coincap/assets")
async def get_coincap_assets():
    service = CoinCapService()
    result = await service.get_assets()
    return result

@app.get("/api/external-apis/coincap/bitcoin")
async def get_coincap_bitcoin():
    service = CoinCapService()
    result = await service.get_bitcoin_data()
    return result

@app.get("/api/external-apis/summary")
async def get_all_apis_summary():
    try:
        quicknode_service = QuickNodeService()
        coingecko_service = CoinGeckoService()
        coincap_service = CoinCapService()
        
        tasks = [
            quicknode_service.get_block_number(),
            quicknode_service.get_gas_price(),
            coingecko_service.get_bitcoin_price(),
            coincap_service.get_bitcoin_data()
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
            }
        }
        
        return summary
        
    except Exception as e:
        return {"error": str(e)}

# Mock L2 Networks endpoints for frontend compatibility
@app.get("/api/l2-networks")
async def get_l2_networks(page: int = 1, limit: int = 20, search: str = ""):
    """Mock L2 networks endpoint"""
    # Sample L2 networks data
    networks = [
        {
            "id": "1",
            "name": "Polygon",
            "chain_id": 137,
            "network_type": "L2",
            "rpc_url": "https://polygon-rpc.com",
            "explorer_url": "https://polygonscan.com",
            "native_currency": "MATIC",
            "block_time": 2,
            "is_active": True,
            "last_block_number": 12345678,
            "last_sync_time": datetime.now().isoformat(),
            "source": "manual",
            "created_at": "2025-01-01T00:00:00Z"
        },
        {
            "id": "2",
            "name": "Arbitrum One",
            "chain_id": 42161,
            "network_type": "L2",
            "rpc_url": "https://arb1.arbitrum.io/rpc",
            "explorer_url": "https://arbiscan.io",
            "native_currency": "ETH",
            "block_time": 1,
            "is_active": True,
            "last_block_number": 98765432,
            "last_sync_time": datetime.now().isoformat(),
            "source": "manual",
            "created_at": "2025-01-01T00:00:00Z"
        },
        {
            "id": "3",
            "name": "Optimism",
            "chain_id": 10,
            "network_type": "L2",
            "rpc_url": "https://mainnet.optimism.io",
            "explorer_url": "https://optimistic.etherscan.io",
            "native_currency": "ETH",
            "block_time": 2,
            "is_active": True,
            "last_block_number": 56789012,
            "last_sync_time": datetime.now().isoformat(),
            "source": "manual",
            "created_at": "2025-01-01T00:00:00Z"
        },
        {
            "id": "4",
            "name": "Base",
            "chain_id": 8453,
            "network_type": "L2",
            "rpc_url": "https://mainnet.base.org",
            "explorer_url": "https://basescan.org",
            "native_currency": "ETH",
            "block_time": 2,
            "is_active": True,
            "last_block_number": 34567890,
            "last_sync_time": datetime.now().isoformat(),
            "source": "manual",
            "created_at": "2025-01-01T00:00:00Z"
        },
        {
            "id": "5",
            "name": "BSC",
            "chain_id": 56,
            "network_type": "L1",
            "rpc_url": "https://bsc-dataseed.binance.org",
            "explorer_url": "https://bscscan.com",
            "native_currency": "BNB",
            "block_time": 3,
            "is_active": True,
            "last_block_number": 78901234,
            "last_sync_time": datetime.now().isoformat(),
            "source": "manual",
            "created_at": "2025-01-01T00:00:00Z"
        }
    ]
    
    # Filter by search term if provided
    if search:
        networks = [n for n in networks if search.lower() in n["name"].lower()]
    
    # Pagination
    start_idx = (page - 1) * limit
    end_idx = start_idx + limit
    paginated_networks = networks[start_idx:end_idx]
    
    return {
        "networks": paginated_networks,
        "pagination": {
            "page": page,
            "limit": limit,
            "total": len(networks),
            "pages": (len(networks) + limit - 1) // limit
        }
    }

@app.post("/api/l2-networks/sync")
async def sync_l2_networks(force: bool = False):
    """Mock sync endpoint"""
    return {"message": "Sync completed", "force": force}

@app.post("/api/l2-networks")
async def create_l2_network(network_data: dict):
    """Mock create network endpoint"""
    return {"message": "Network created", "id": "new_id"}

@app.put("/api/l2-networks/{network_id}")
async def update_l2_network(network_id: str, network_data: dict):
    """Mock update network endpoint"""
    return {"message": "Network updated", "id": network_id}

@app.delete("/api/l2-networks/{network_id}")
async def delete_l2_network(network_id: str):
    """Mock delete network endpoint"""
    return {"message": "Network deleted", "id": network_id}

# Mock Protocols endpoints for frontend compatibility
@app.get("/api/protocols")
async def get_protocols(page: int = 1, limit: int = 20, search: str = ""):
    """Mock protocols endpoint"""
    # Sample protocols data
    protocols = [
        {
            "id": "1",
            "name": "uniswap",
            "display_name": "Uniswap",
            "category": "dex",
            "chain": "ethereum",
            "contract_address": "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
            "logo_url": "https://cryptologos.cc/logos/uniswap-uni-logo.png",
            "website_url": "https://uniswap.org",
            "audit_status": True,
            "audit_firm": "Trail of Bits",
            "launch_date": "2020-05-05T00:00:00Z",
            "created_at": "2025-01-01T00:00:00Z"
        },
        {
            "id": "2",
            "name": "aave",
            "display_name": "Aave",
            "category": "lending",
            "chain": "ethereum",
            "contract_address": "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9",
            "logo_url": "https://cryptologos.cc/logos/aave-aave-logo.png",
            "website_url": "https://aave.com",
            "audit_status": True,
            "audit_firm": "OpenZeppelin",
            "launch_date": "2020-01-08T00:00:00Z",
            "created_at": "2025-01-01T00:00:00Z"
        },
        {
            "id": "3",
            "name": "compound",
            "display_name": "Compound",
            "category": "lending",
            "chain": "ethereum",
            "contract_address": "0xc00e94Cb662C3520282E6f5717214004A7f26888",
            "logo_url": "https://cryptologos.cc/logos/compound-comp-logo.png",
            "website_url": "https://compound.finance",
            "audit_status": True,
            "audit_firm": "Trail of Bits",
            "launch_date": "2018-09-18T00:00:00Z",
            "created_at": "2025-01-01T00:00:00Z"
        },
        {
            "id": "4",
            "name": "curve",
            "display_name": "Curve Finance",
            "category": "dex",
            "chain": "ethereum",
            "contract_address": "0xD533a949740bb3306d119CC777fa900bA034cd52",
            "logo_url": "https://cryptologos.cc/logos/curve-dao-token-crv-logo.png",
            "website_url": "https://curve.fi",
            "audit_status": True,
            "audit_firm": "Quantstamp",
            "launch_date": "2020-08-14T00:00:00Z",
            "created_at": "2025-01-01T00:00:00Z"
        },
        {
            "id": "5",
            "name": "yearn",
            "display_name": "Yearn Finance",
            "category": "yield",
            "chain": "ethereum",
            "contract_address": "0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e",
            "logo_url": "https://cryptologos.cc/logos/yearn-finance-yfi-logo.png",
            "website_url": "https://yearn.finance",
            "audit_status": True,
            "audit_firm": "Trail of Bits",
            "launch_date": "2020-07-17T00:00:00Z",
            "created_at": "2025-01-01T00:00:00Z"
        }
    ]
    
    # Filter by search term if provided
    if search:
        protocols = [p for p in protocols if search.lower() in p["display_name"].lower()]
    
    # Pagination
    start_idx = (page - 1) * limit
    end_idx = start_idx + limit
    paginated_protocols = protocols[start_idx:end_idx]
    
    return {
        "protocols": paginated_protocols,
        "pagination": {
            "page": page,
            "limit": limit,
            "total": len(protocols),
            "pages": (len(protocols) + limit - 1) // limit
        }
    }

@app.get("/api/protocols/{protocol_id}")
async def get_protocol(protocol_id: str):
    """Mock get single protocol endpoint"""
    return {
        "id": protocol_id,
        "name": "uniswap",
        "display_name": "Uniswap",
        "category": "dex",
        "chain": "ethereum",
        "contract_address": "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
        "logo_url": "https://cryptologos.cc/logos/uniswap-uni-logo.png",
        "website_url": "https://uniswap.org",
        "audit_status": True,
        "audit_firm": "Trail of Bits",
        "launch_date": "2020-05-05T00:00:00Z",
        "created_at": "2025-01-01T00:00:00Z"
    }

@app.post("/api/protocols")
async def create_protocol(protocol_data: dict):
    """Mock create protocol endpoint"""
    return {"message": "Protocol created", "id": "new_protocol_id"}

@app.put("/api/protocols/{protocol_id}")
async def update_protocol(protocol_id: str, protocol_data: dict):
    """Mock update protocol endpoint"""
    return {"message": "Protocol updated", "id": protocol_id}

@app.delete("/api/protocols/{protocol_id}")
async def delete_protocol(protocol_id: str):
    """Mock delete protocol endpoint"""
    return {"message": "Protocol deleted", "id": protocol_id}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)
