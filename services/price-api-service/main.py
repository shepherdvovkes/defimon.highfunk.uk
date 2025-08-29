import asyncio
import os
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from decimal import Decimal
import asyncpg
from fastapi import FastAPI, HTTPException, Query, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from dotenv import load_dotenv
from prometheus_client import start_http_server, Counter, Histogram
import redis

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Prometheus metrics
API_REQUESTS = Counter('price_api_requests_total', 'Total API requests', ['endpoint'])
API_ERRORS = Counter('price_api_errors_total', 'Total API errors', ['endpoint'])
API_RESPONSE_TIME = Histogram('price_api_response_time_seconds', 'API response time', ['endpoint'])

# Pydantic models
class PriceData(BaseModel):
    symbol: str
    price_usd: float
    volume_24h_usd: Optional[float] = None
    market_cap_usd: Optional[float] = None
    price_change_24h_percent: Optional[float] = None
    price_change_7d_percent: Optional[float] = None
    price_change_30d_percent: Optional[float] = None
    high_24h_usd: Optional[float] = None
    low_24h_usd: Optional[float] = None
    last_updated: datetime
    oracle_source: str

class L2NetworkData(BaseModel):
    network: str
    network_token_symbol: str
    price_usd: float
    volume_24h_usd: Optional[float] = None
    market_cap_usd: Optional[float] = None
    price_change_24h_percent: Optional[float] = None
    tvl_usd: Optional[float] = None
    total_transactions_24h: Optional[int] = None
    avg_gas_price_gwei: Optional[float] = None
    last_updated: datetime

class PriceAggregation(BaseModel):
    symbol: str
    median_price_usd: float
    mean_price_usd: float
    weighted_price_usd: float
    price_volatility: Optional[float] = None
    oracle_count: int
    confidence_score: float
    timestamp: datetime

class PriceHistory(BaseModel):
    symbol: str
    timestamp: datetime
    price_usd: float
    volume_24h_usd: Optional[float] = None
    market_cap_usd: Optional[float] = None

# FastAPI app
app = FastAPI(
    title="Price Oracle API",
    description="API for cryptocurrency price data from multiple oracles",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class DatabaseManager:
    def __init__(self):
        self.pool = None
    
    async def initialize(self):
        """Initialize database connection pool"""
        self.pool = await asyncpg.create_pool(
            host=os.getenv('DB_HOST', 'localhost'),
            port=int(os.getenv('DB_PORT', '5432')),
            user=os.getenv('DB_USER', 'postgres'),
            password=os.getenv('DB_PASSWORD', ''),
            database=os.getenv('DB_NAME', 'defimon'),
            min_size=5,
            max_size=20
        )
        logger.info("Database connection pool initialized")
    
    async def close(self):
        """Close database connection pool"""
        if self.pool:
            await self.pool.close()
    
    async def get_current_prices(self, symbols: Optional[List[str]] = None) -> List[PriceData]:
        """Get current prices for all assets or specific symbols"""
        async with self.pool.acquire() as conn:
            if symbols:
                placeholders = ','.join(f'${i+1}' for i in range(len(symbols)))
                query = f"""
                    SELECT 
                        ca.symbol,
                        pf.price_usd,
                        pf.volume_24h_usd,
                        pf.market_cap_usd,
                        pf.price_change_24h_percent,
                        pf.price_change_7d_percent,
                        pf.price_change_30d_percent,
                        pf.high_24h_usd,
                        pf.low_24h_usd,
                        pf.last_updated,
                        os.name as oracle_source
                    FROM price_feeds pf
                    JOIN crypto_assets ca ON pf.asset_id = ca.id
                    JOIN oracle_sources os ON pf.oracle_source_id = os.id
                    WHERE ca.symbol = ANY($1)
                    AND pf.last_updated >= NOW() - INTERVAL '1 hour'
                    ORDER BY ca.symbol, pf.last_updated DESC
                """
                rows = await conn.fetch(query, symbols)
            else:
                query = """
                    SELECT 
                        ca.symbol,
                        pf.price_usd,
                        pf.volume_24h_usd,
                        pf.market_cap_usd,
                        pf.price_change_24h_percent,
                        pf.price_change_7d_percent,
                        pf.price_change_30d_percent,
                        pf.high_24h_usd,
                        pf.low_24h_usd,
                        pf.last_updated,
                        os.name as oracle_source
                    FROM price_feeds pf
                    JOIN crypto_assets ca ON pf.asset_id = ca.id
                    JOIN oracle_sources os ON pf.oracle_source_id = os.id
                    WHERE pf.last_updated >= NOW() - INTERVAL '1 hour'
                    ORDER BY ca.symbol, pf.last_updated DESC
                """
                rows = await conn.fetch(query)
            
            return [PriceData(**dict(row)) for row in rows]
    
    async def get_l2_network_data(self) -> List[L2NetworkData]:
        """Get L2 network data"""
        async with self.pool.acquire() as conn:
            query = """
                SELECT 
                    network,
                    network_token_symbol,
                    price_usd,
                    volume_24h_usd,
                    market_cap_usd,
                    price_change_24h_percent,
                    tvl_usd,
                    total_transactions_24h,
                    avg_gas_price_gwei,
                    last_updated
                FROM l2_network_prices
                WHERE last_updated >= NOW() - INTERVAL '1 hour'
                ORDER BY network, last_updated DESC
            """
            rows = await conn.fetch(query)
            return [L2NetworkData(**dict(row)) for row in rows]
    
    async def get_price_aggregations(self, symbols: Optional[List[str]] = None) -> List[PriceAggregation]:
        """Get price aggregations"""
        async with self.pool.acquire() as conn:
            if symbols:
                placeholders = ','.join(f'${i+1}' for i in range(len(symbols)))
                query = f"""
                    SELECT 
                        ca.symbol,
                        pa.median_price_usd,
                        pa.mean_price_usd,
                        pa.weighted_price_usd,
                        pa.price_volatility,
                        pa.oracle_count,
                        pa.confidence_score,
                        pa.timestamp
                    FROM price_aggregations pa
                    JOIN crypto_assets ca ON pa.asset_id = ca.id
                    WHERE ca.symbol = ANY($1)
                    AND pa.timestamp >= NOW() - INTERVAL '1 hour'
                    ORDER BY ca.symbol, pa.timestamp DESC
                """
                rows = await conn.fetch(query, symbols)
            else:
                query = """
                    SELECT 
                        ca.symbol,
                        pa.median_price_usd,
                        pa.mean_price_usd,
                        pa.weighted_price_usd,
                        pa.price_volatility,
                        pa.oracle_count,
                        pa.confidence_score,
                        pa.timestamp
                    FROM price_aggregations pa
                    JOIN crypto_assets ca ON pa.asset_id = ca.id
                    WHERE pa.timestamp >= NOW() - INTERVAL '1 hour'
                    ORDER BY ca.symbol, pa.timestamp DESC
                """
                rows = await conn.fetch(query)
            
            return [PriceAggregation(**dict(row)) for row in rows]
    
    async def get_price_history(self, symbol: str, hours: int = 24) -> List[PriceHistory]:
        """Get price history for a specific symbol"""
        async with self.pool.acquire() as conn:
            query = """
                SELECT 
                    ca.symbol,
                    ofh.timestamp,
                    ofh.price_usd,
                    ofh.volume_24h_usd,
                    ofh.market_cap_usd
                FROM oracle_feed_history ofh
                JOIN crypto_assets ca ON ofh.asset_id = ca.id
                WHERE ca.symbol = $1
                AND ofh.timestamp >= NOW() - INTERVAL '1 hour' * $2
                ORDER BY ofh.timestamp ASC
            """
            rows = await conn.fetch(query, symbol, hours)
            return [PriceHistory(**dict(row)) for row in rows]
    
    async def get_oracle_performance(self) -> List[Dict]:
        """Get oracle performance metrics"""
        async with self.pool.acquire() as conn:
            query = """
                SELECT 
                    os.name as oracle_name,
                    ca.symbol as asset_symbol,
                    op.uptime_percentage,
                    op.response_time_avg_ms,
                    op.price_deviation_avg,
                    op.last_successful_update,
                    op.error_count_24h
                FROM oracle_performance op
                JOIN oracle_sources os ON op.oracle_source_id = os.id
                JOIN crypto_assets ca ON op.asset_id = ca.id
                ORDER BY os.name, ca.symbol
            """
            rows = await conn.fetch(query)
            return [dict(row) for row in rows]

# Global database manager
db_manager = DatabaseManager()

# Dependency
async def get_db():
    return db_manager

# API endpoints
@app.get("/", response_model=Dict)
async def root():
    """Root endpoint with API information"""
    return {
        "name": "Price Oracle API",
        "version": "1.0.0",
        "description": "Cryptocurrency price data from multiple oracles",
        "endpoints": {
            "/prices": "Get current prices",
            "/prices/{symbol}": "Get current price for specific symbol",
            "/l2-networks": "Get L2 network data",
            "/aggregations": "Get price aggregations",
            "/history/{symbol}": "Get price history",
            "/oracles/performance": "Get oracle performance metrics"
        }
    }

@app.get("/prices", response_model=List[PriceData])
async def get_prices(
    symbols: Optional[str] = Query(None, description="Comma-separated list of symbols"),
    db: DatabaseManager = Depends(get_db)
):
    """Get current prices for all assets or specific symbols"""
    start_time = datetime.now()
    
    try:
        symbol_list = None
        if symbols:
            symbol_list = [s.strip().upper() for s in symbols.split(',')]
        
        prices = await db.get_current_prices(symbol_list)
        
        API_REQUESTS.labels(endpoint='/prices').inc()
        API_RESPONSE_TIME.labels(endpoint='/prices').observe(
            (datetime.now() - start_time).total_seconds()
        )
        
        return prices
        
    except Exception as e:
        API_ERRORS.labels(endpoint='/prices').inc()
        logger.error(f"Error getting prices: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/prices/{symbol}", response_model=List[PriceData])
async def get_price_by_symbol(
    symbol: str,
    db: DatabaseManager = Depends(get_db)
):
    """Get current price for a specific symbol from all oracles"""
    start_time = datetime.now()
    
    try:
        prices = await db.get_current_prices([symbol.upper()])
        
        if not prices:
            raise HTTPException(status_code=404, detail=f"Price data not found for {symbol}")
        
        API_REQUESTS.labels(endpoint='/prices/{symbol}').inc()
        API_RESPONSE_TIME.labels(endpoint='/prices/{symbol}').observe(
            (datetime.now() - start_time).total_seconds()
        )
        
        return prices
        
    except HTTPException:
        raise
    except Exception as e:
        API_ERRORS.labels(endpoint='/prices/{symbol}').inc()
        logger.error(f"Error getting price for {symbol}: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/l2-networks", response_model=List[L2NetworkData])
async def get_l2_networks(db: DatabaseManager = Depends(get_db)):
    """Get L2 network data"""
    start_time = datetime.now()
    
    try:
        networks = await db.get_l2_network_data()
        
        API_REQUESTS.labels(endpoint='/l2-networks').inc()
        API_RESPONSE_TIME.labels(endpoint='/l2-networks').observe(
            (datetime.now() - start_time).total_seconds()
        )
        
        return networks
        
    except Exception as e:
        API_ERRORS.labels(endpoint='/l2-networks').inc()
        logger.error(f"Error getting L2 networks: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/aggregations", response_model=List[PriceAggregation])
async def get_aggregations(
    symbols: Optional[str] = Query(None, description="Comma-separated list of symbols"),
    db: DatabaseManager = Depends(get_db)
):
    """Get price aggregations from multiple oracles"""
    start_time = datetime.now()
    
    try:
        symbol_list = None
        if symbols:
            symbol_list = [s.strip().upper() for s in symbols.split(',')]
        
        aggregations = await db.get_price_aggregations(symbol_list)
        
        API_REQUESTS.labels(endpoint='/aggregations').inc()
        API_RESPONSE_TIME.labels(endpoint='/aggregations').observe(
            (datetime.now() - start_time).total_seconds()
        )
        
        return aggregations
        
    except Exception as e:
        API_ERRORS.labels(endpoint='/aggregations').inc()
        logger.error(f"Error getting aggregations: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/history/{symbol}", response_model=List[PriceHistory])
async def get_price_history(
    symbol: str,
    hours: int = Query(24, ge=1, le=168, description="Number of hours to look back"),
    db: DatabaseManager = Depends(get_db)
):
    """Get price history for a specific symbol"""
    start_time = datetime.now()
    
    try:
        history = await db.get_price_history(symbol.upper(), hours)
        
        if not history:
            raise HTTPException(status_code=404, detail=f"Price history not found for {symbol}")
        
        API_REQUESTS.labels(endpoint='/history/{symbol}').inc()
        API_RESPONSE_TIME.labels(endpoint='/history/{symbol}').observe(
            (datetime.now() - start_time).total_seconds()
        )
        
        return history
        
    except HTTPException:
        raise
    except Exception as e:
        API_ERRORS.labels(endpoint='/history/{symbol}').inc()
        logger.error(f"Error getting history for {symbol}: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/oracles/performance")
async def get_oracle_performance(db: DatabaseManager = Depends(get_db)):
    """Get oracle performance metrics"""
    start_time = datetime.now()
    
    try:
        performance = await db.get_oracle_performance()
        
        API_REQUESTS.labels(endpoint='/oracles/performance').inc()
        API_RESPONSE_TIME.labels(endpoint='/oracles/performance').observe(
            (datetime.now() - start_time).total_seconds()
        )
        
        return performance
        
    except Exception as e:
        API_ERRORS.labels(endpoint='/oracles/performance').inc()
        logger.error(f"Error getting oracle performance: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    from prometheus_client import generate_latest
    return Response(generate_latest(), media_type="text/plain")

# Startup and shutdown events
@app.on_event("startup")
async def startup_event():
    """Initialize services on startup"""
    await db_manager.initialize()
    start_http_server(8082)  # Prometheus metrics server
    logger.info("Price API Service started")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    await db_manager.close()
    logger.info("Price API Service stopped")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
