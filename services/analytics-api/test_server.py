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

def get_blast_config():
    api_key = os.getenv("ALCHEMY_API_KEY", "")
    return APIConfig(
        api_key=api_key,
        base_url="https://eth-mainnet.g.alchemy.com/v2",
        headers={"Content-Type": "application/json"}
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

class BlastService:
    def __init__(self):
        self.config = get_blast_config()
    
    async def get_block_number(self):
        try:
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_blockNumber",
                "params": [],
                "id": 1
            }
            
            url = f"{self.config.base_url}/{self.config.api_key}"
            response = self.config.session.post(url, json=payload)
            response.raise_for_status()
            
            result = response.json()
            return {
                "success": True,
                "block_number": int(result.get("result", "0x0"), 16),
                "hex_block_number": result.get("result", "0x0"),
                "provider": "Alchemy (Blast)"
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
            
            url = f"{self.config.base_url}/{self.config.api_key}"
            response = self.config.session.post(url, json=payload)
            response.raise_for_status()
            
            result = response.json()
            gas_price_hex = result.get("result", "0x0")
            gas_price_int = int(gas_price_hex, 16)
            
            return {
                "success": True,
                "gas_price_wei": gas_price_int,
                "gas_price_gwei": gas_price_int / 10**9,
                "hex_gas_price": gas_price_hex,
                "provider": "Alchemy (Blast)"
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
            "/api/external-apis/blast/block-number",
            "/api/external-apis/blast/gas-price",
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
        "apis": ["quicknode", "blast", "coingecko", "coincap"]
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

@app.get("/api/external-apis/blast/block-number")
async def get_blast_block_number():
    service = BlastService()
    result = await service.get_block_number()
    return result

@app.get("/api/external-apis/blast/gas-price")
async def get_blast_gas_price():
    service = BlastService()
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

# Additional API endpoints for dashboard
@app.get("/api/external-apis/defillama/protocols")
async def get_defillama_protocols():
    """Mock DeFiLlama protocols endpoint"""
    return {
        "success": True,
        "data": {
            "total_tvl": 45000000000,
            "protocols": [
                {"name": "Uniswap", "tvl": 3500000000},
                {"name": "Aave", "tvl": 2800000000},
                {"name": "Compound", "tvl": 2100000000}
            ]
        }
    }

@app.get("/api/external-apis/thegraph/uniswap")
async def get_thegraph_uniswap():
    """Mock The Graph Uniswap endpoint"""
    return {
        "success": True,
        "data": {
            "pools": [
                {"id": "0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8", "tvl": 150000000},
                {"id": "0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640", "tvl": 120000000}
            ]
        }
    }

@app.get("/api/external-apis/etherscan/transactions")
async def get_etherscan_transactions():
    """Mock Etherscan transactions endpoint"""
    return {
        "success": True,
        "data": {
            "status": "1",
            "message": "OK",
            "result": [
                {"hash": "0x123...", "value": "1000000000000000000"}
            ]
        }
    }

@app.get("/api/external-apis/arbiscan/transactions")
async def get_arbiscan_transactions():
    """Mock Arbiscan transactions endpoint"""
    return {
        "success": True,
        "data": {
            "status": "1",
            "message": "OK",
            "result": [
                {"hash": "0x456...", "value": "500000000000000000"}
            ]
        }
    }

@app.get("/api/external-apis/polygonscan/transactions")
async def get_polygonscan_transactions():
    """Mock Polygonscan transactions endpoint"""
    return {
        "success": True,
        "data": {
            "status": "1",
            "message": "OK",
            "result": [
                {"hash": "0x789...", "value": "2000000000000000000"}
            ]
        }
    }

@app.get("/api/external-apis/summary")
async def get_all_apis_summary():
    try:
        quicknode_service = QuickNodeService()
        blast_service = BlastService()
        coingecko_service = CoinGeckoService()
        coincap_service = CoinCapService()
        
        tasks = [
            quicknode_service.get_block_number(),
            quicknode_service.get_gas_price(),
            blast_service.get_block_number(),
            blast_service.get_gas_price(),
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
            "blast": {
                "block_number": results[2] if not isinstance(results[2], Exception) else {"error": str(results[2])},
                "gas_price": results[3] if not isinstance(results[3], Exception) else {"error": str(results[3])}
            },
            "coingecko": {
                "bitcoin_price": results[4] if not isinstance(results[4], Exception) else {"error": str(results[4])}
            },
            "coincap": {
                "bitcoin_data": results[5] if not isinstance(results[5], Exception) else {"error": str(results[5])}
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

@app.get("/api/analytics/overview")
async def get_analytics_overview():
    """Mock analytics overview endpoint"""
    return {
        "total_tvl": 45000000000,  # $45B total TVL
        "top_protocols": [
            {
                "name": "uniswap",
                "display_name": "Uniswap",
                "tvl": 8500000000,  # $8.5B
                "volume_24h": 1200000000  # $1.2B
            },
            {
                "name": "aave",
                "display_name": "Aave",
                "tvl": 6500000000,  # $6.5B
                "volume_24h": 450000000  # $450M
            },
            {
                "name": "compound",
                "display_name": "Compound",
                "tvl": 4200000000,  # $4.2B
                "volume_24h": 320000000  # $320M
            },
            {
                "name": "curve",
                "display_name": "Curve Finance",
                "tvl": 3800000000,  # $3.8B
                "volume_24h": 280000000  # $280M
            },
            {
                "name": "yearn",
                "display_name": "Yearn Finance",
                "tvl": 1200000000,  # $1.2B
                "volume_24h": 150000000  # $150M
            }
        ],
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/api/polygon/data")
async def get_polygon_data():
    """Get Polygon network data from database"""
    try:
        # Import database connection
        import asyncpg
        import os
        from dotenv import load_dotenv
        
        load_dotenv()
        
        # Database connection
        user = os.getenv('GOOGLE_CLOUD_SQL_USER', 'defimon_user')
        password = os.getenv('GOOGLE_CLOUD_SQL_PASSWORD', 'defimon_secure_password_2024')
        database = os.getenv('GOOGLE_CLOUD_SQL_DATABASE_NAME', 'defi_analytics')
        
        # Connect to database
        conn = await asyncpg.connect(
            f"postgresql://{user}:{password}@localhost:5432/{database}"
        )
        
        # Get latest block
        latest_block = await conn.fetchrow("""
            SELECT block_number, timestamp, gas_used, transactions_count 
            FROM polygon_data.blocks 
            ORDER BY block_number DESC 
            LIMIT 1
        """)
        
        # Get total blocks count
        total_blocks = await conn.fetchval("""
            SELECT COUNT(*) FROM polygon_data.blocks
        """)
        
        # Get total transactions count
        total_transactions = await conn.fetchval("""
            SELECT COUNT(*) FROM polygon_data.transactions
        """)
        
        # Get recent transactions (last 10)
        recent_transactions = await conn.fetch("""
            SELECT hash, from_address, to_address, value, gas_used, gas_price
            FROM polygon_data.transactions 
            ORDER BY block_number DESC 
            LIMIT 10
        """)
        
        # Get gas statistics
        gas_stats = await conn.fetchrow("""
            SELECT 
                AVG(CAST(gas_price AS DECIMAL)) as avg_gas_price,
                MAX(CAST(gas_price AS DECIMAL)) as max_gas_price,
                MIN(CAST(gas_price AS DECIMAL)) as min_gas_price
            FROM polygon_data.transactions 
            WHERE block_number >= (SELECT MAX(block_number) - 1000 FROM polygon_data.blocks)
        """)
        
        await conn.close()
        
        return {
            "network": "Polygon",
            "chain_id": 137,
            "latest_block": {
                "number": latest_block['block_number'] if latest_block else 0,
                "timestamp": latest_block['timestamp'] if latest_block else 0,
                "gas_used": latest_block['gas_used'] if latest_block else 0,
                "transactions_count": latest_block['transactions_count'] if latest_block else 0
            },
            "statistics": {
                "total_blocks": total_blocks or 0,
                "total_transactions": total_transactions or 0,
                "avg_gas_price": float(gas_stats['avg_gas_price']) if gas_stats and gas_stats['avg_gas_price'] else 0,
                "max_gas_price": float(gas_stats['max_gas_price']) if gas_stats and gas_stats['max_gas_price'] else 0,
                "min_gas_price": float(gas_stats['min_gas_price']) if gas_stats and gas_stats['min_gas_price'] else 0
            },
            "recent_transactions": [
                {
                    "hash": tx['hash'],
                    "from": tx['from_address'],
                    "to": tx['to_address'],
                    "value": tx['value'],
                    "gas_used": tx['gas_used'],
                    "gas_price": tx['gas_price']
                } for tx in recent_transactions
            ],
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        # Return mock data for demonstration
        return {
            "network": "Polygon",
            "chain_id": 137,
            "latest_block": {
                "number": 12345678,
                "timestamp": int(datetime.utcnow().timestamp()),
                "gas_used": 15000000,
                "transactions_count": 150
            },
            "statistics": {
                "total_blocks": 12345678,
                "total_transactions": 1850000000,
                "avg_gas_price": 30000000000,  # 30 Gwei
                "max_gas_price": 50000000000,  # 50 Gwei
                "min_gas_price": 10000000000   # 10 Gwei
            },
            "recent_transactions": [
                {
                    "hash": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
                    "from": "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
                    "to": "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
                    "value": "1000000000000000000",  # 1 MATIC
                    "gas_used": 21000,
                    "gas_price": "30000000000"
                },
                {
                    "hash": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
                    "from": "0x8ba1f109551bD432803012645Hac136c772c37e0",
                    "to": "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984",
                    "value": "500000000000000000",  # 0.5 MATIC
                    "gas_used": 65000,
                    "gas_price": "35000000000"
                },
                {
                    "hash": "0x9876543210fedcba9876543210fedcba9876543210fedcba9876543210fedcba",
                    "from": "0x1234567890123456789012345678901234567890",
                    "to": "0x9876543210987654321098765432109876543210",
                    "value": "2000000000000000000",  # 2 MATIC
                    "gas_used": 21000,
                    "gas_price": "25000000000"
                }
            ],
            "timestamp": datetime.utcnow().isoformat(),
            "note": "Mock data - database connection not available"
        }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)
