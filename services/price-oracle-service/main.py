import asyncio
import aiohttp
import os
import json
import time
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from decimal import Decimal
import asyncpg
from dotenv import load_dotenv
from prometheus_client import start_http_server, Counter, Histogram, Gauge
import redis
from kafka import KafkaProducer

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Prometheus metrics
ORACLE_REQUESTS = Counter('oracle_requests_total', 'Total oracle requests', ['oracle', 'asset'])
ORACLE_ERRORS = Counter('oracle_errors_total', 'Total oracle errors', ['oracle', 'asset'])
ORACLE_RESPONSE_TIME = Histogram('oracle_response_time_seconds', 'Oracle response time', ['oracle'])
PRICE_UPDATES = Counter('price_updates_total', 'Total price updates', ['asset', 'oracle'])
ACTIVE_ORACLES = Gauge('active_oracles', 'Number of active oracles')

@dataclass
class OracleConfig:
    name: str
    endpoint: str
    api_key: Optional[str] = None
    rate_limit_per_minute: int = 60
    timeout: int = 30
    headers: Dict[str, str] = None

@dataclass
class PriceData:
    symbol: str
    price_usd: Decimal
    volume_24h_usd: Optional[Decimal] = None
    market_cap_usd: Optional[Decimal] = None
    price_change_24h_percent: Optional[Decimal] = None
    price_change_7d_percent: Optional[Decimal] = None
    price_change_30d_percent: Optional[Decimal] = None
    high_24h_usd: Optional[Decimal] = None
    low_24h_usd: Optional[Decimal] = None
    circulating_supply: Optional[Decimal] = None
    total_supply: Optional[Decimal] = None
    max_supply: Optional[Decimal] = None

class PriceOracleService:
    def __init__(self):
        self.db_pool = None
        self.redis_client = None
        self.kafka_producer = None
        self.oracles = self._load_oracles()
        self.assets = self._load_assets()
        self.session = None
        
    def _load_oracles(self) -> Dict[str, OracleConfig]:
        """Load oracle configurations"""
        return {
            'coingecko': OracleConfig(
                name='CoinGecko',
                endpoint='https://api.coingecko.com/api/v3',
                rate_limit_per_minute=50,
                timeout=30
            ),
            'binance': OracleConfig(
                name='Binance',
                endpoint='https://api.binance.com/api/v3',
                rate_limit_per_minute=1200,
                timeout=10
            ),
            'kraken': OracleConfig(
                name='Kraken',
                endpoint='https://api.kraken.com/0',
                rate_limit_per_minute=15,
                timeout=30
            ),
            'coinbase': OracleConfig(
                name='Coinbase',
                endpoint='https://api.coinbase.com/v2',
                rate_limit_per_minute=30,
                timeout=30
            )
        }
    
    def _load_assets(self) -> List[Dict]:
        """Load assets to track"""
        return [
            {'symbol': 'ETH', 'coingecko_id': 'ethereum', 'network': 'ethereum'},
            {'symbol': 'BTC', 'coingecko_id': 'bitcoin', 'network': 'bitcoin'},
            {'symbol': 'USDC', 'coingecko_id': 'usd-coin', 'network': 'ethereum'},
            {'symbol': 'USDT', 'coingecko_id': 'tether', 'network': 'ethereum'},
            {'symbol': 'MATIC', 'coingecko_id': 'matic-network', 'network': 'polygon'},
            {'symbol': 'ARB', 'coingecko_id': 'arbitrum', 'network': 'arbitrum'},
            {'symbol': 'OP', 'coingecko_id': 'optimism', 'network': 'optimism'},
            {'symbol': 'LINK', 'coingecko_id': 'chainlink', 'network': 'ethereum'},
            {'symbol': 'UNI', 'coingecko_id': 'uniswap', 'network': 'ethereum'},
            {'symbol': 'AAVE', 'coingecko_id': 'aave', 'network': 'ethereum'},
            {'symbol': 'CRV', 'coingecko_id': 'curve-dao-token', 'network': 'ethereum'},
            {'symbol': 'SNX', 'coingecko_id': 'havven', 'network': 'ethereum'}
        ]
    
    async def initialize(self):
        """Initialize database connections and services"""
        # Database connection
        self.db_pool = await asyncpg.create_pool(
            host=os.getenv('DB_HOST', 'localhost'),
            port=int(os.getenv('DB_PORT', '5432')),
            user=os.getenv('DB_USER', 'postgres'),
            password=os.getenv('DB_PASSWORD', ''),
            database=os.getenv('DB_NAME', 'defimon'),
            min_size=5,
            max_size=20
        )
        
        # Redis connection
        self.redis_client = redis.Redis(
            host=os.getenv('REDIS_HOST', 'localhost'),
            port=int(os.getenv('REDIS_PORT', '6379')),
            decode_responses=True
        )
        
        # Kafka producer
        self.kafka_producer = KafkaProducer(
            bootstrap_servers=os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092').split(','),
            value_serializer=lambda v: json.dumps(v).encode('utf-8'),
            key_serializer=lambda k: k.encode('utf-8') if k else None
        )
        
        # HTTP session
        self.session = aiohttp.ClientSession()
        
        logger.info("Price Oracle Service initialized successfully")
    
    async def start_service(self):
        """Start the price oracle service"""
        logger.info("Starting Price Oracle Service...")
        
        # Start Prometheus metrics server
        start_http_server(8081)
        
        # Start continuous data collection
        tasks = []
        for oracle_name, oracle_config in self.oracles.items():
            tasks.append(self._collect_from_oracle(oracle_name, oracle_config))
        
        # Start L2 network data collection
        tasks.append(self._collect_l2_network_data())
        
        # Start price aggregation task
        tasks.append(self._aggregate_prices())
        
        await asyncio.gather(*tasks)
    
    async def _collect_from_oracle(self, oracle_name: str, oracle_config: OracleConfig):
        """Collect price data from a specific oracle"""
        logger.info(f"Starting data collection from {oracle_name}")
        
        while True:
            try:
                start_time = time.time()
                
                for asset in self.assets:
                    try:
                        price_data = await self._fetch_price_data(oracle_name, oracle_config, asset)
                        if price_data:
                            await self._store_price_data(oracle_name, asset, price_data)
                            await self._publish_price_update(oracle_name, asset, price_data)
                        
                        # Rate limiting
                        await asyncio.sleep(60 / oracle_config.rate_limit_per_minute)
                        
                    except Exception as e:
                        logger.error(f"Error fetching {asset['symbol']} from {oracle_name}: {e}")
                        ORACLE_ERRORS.labels(oracle=oracle_name, asset=asset['symbol']).inc()
                
                # Wait before next cycle
                await asyncio.sleep(60)  # Update every minute
                
            except Exception as e:
                logger.error(f"Error in {oracle_name} collection loop: {e}")
                await asyncio.sleep(60)
    
    async def _fetch_price_data(self, oracle_name: str, oracle_config: OracleConfig, asset: Dict) -> Optional[PriceData]:
        """Fetch price data from oracle"""
        try:
            if oracle_name == 'coingecko':
                return await self._fetch_coingecko_data(oracle_config, asset)
            elif oracle_name == 'binance':
                return await self._fetch_binance_data(oracle_config, asset)
            elif oracle_name == 'kraken':
                return await self._fetch_kraken_data(oracle_config, asset)
            elif oracle_name == 'coinbase':
                return await self._fetch_coinbase_data(oracle_config, asset)
            
        except Exception as e:
            logger.error(f"Error fetching from {oracle_name}: {e}")
            return None
    
    async def _fetch_coingecko_data(self, oracle_config: OracleConfig, asset: Dict) -> Optional[PriceData]:
        """Fetch data from CoinGecko"""
        start_time = time.time()
        
        url = f"{oracle_config.endpoint}/simple/price"
        params = {
            'ids': asset['coingecko_id'],
            'vs_currencies': 'usd',
            'include_24hr_change': 'true',
            'include_24hr_vol': 'true',
            'include_market_cap': 'true',
            'include_last_updated_at': 'true'
        }
        
        async with self.session.get(url, params=params, timeout=oracle_config.timeout) as response:
            if response.status == 200:
                data = await response.json()
                
                if asset['coingecko_id'] in data:
                    asset_data = data[asset['coingecko_id']]
                    
                    return PriceData(
                        symbol=asset['symbol'],
                        price_usd=Decimal(str(asset_data.get('usd', 0))),
                        volume_24h_usd=Decimal(str(asset_data.get('usd_24h_vol', 0))),
                        market_cap_usd=Decimal(str(asset_data.get('usd_market_cap', 0))),
                        price_change_24h_percent=Decimal(str(asset_data.get('usd_24h_change', 0)))
                    )
        
        ORACLE_RESPONSE_TIME.labels(oracle='coingecko').observe(time.time() - start_time)
        return None
    
    async def _fetch_binance_data(self, oracle_config: OracleConfig, asset: Dict) -> Optional[PriceData]:
        """Fetch data from Binance"""
        start_time = time.time()
        
        # Map symbols to Binance trading pairs
        symbol_mapping = {
            'ETH': 'ETHUSDT',
            'BTC': 'BTCUSDT',
            'USDC': 'USDCUSDT',
            'USDT': 'USDTUSDT',
            'MATIC': 'MATICUSDT',
            'ARB': 'ARBUSDT',
            'OP': 'OPUSDT',
            'LINK': 'LINKUSDT',
            'UNI': 'UNIUSDT',
            'AAVE': 'AAVEUSDT',
            'CRV': 'CRVUSDT',
            'SNX': 'SNXUSDT'
        }
        
        trading_pair = symbol_mapping.get(asset['symbol'])
        if not trading_pair:
            return None
        
        url = f"{oracle_config.endpoint}/ticker/24hr"
        params = {'symbol': trading_pair}
        
        async with self.session.get(url, params=params, timeout=oracle_config.timeout) as response:
            if response.status == 200:
                data = await response.json()
                
                return PriceData(
                    symbol=asset['symbol'],
                    price_usd=Decimal(str(data.get('lastPrice', 0))),
                    volume_24h_usd=Decimal(str(data.get('quoteVolume', 0))),
                    price_change_24h_percent=Decimal(str(data.get('priceChangePercent', 0))),
                    high_24h_usd=Decimal(str(data.get('highPrice', 0))),
                    low_24h_usd=Decimal(str(data.get('lowPrice', 0)))
                )
        
        ORACLE_RESPONSE_TIME.labels(oracle='binance').observe(time.time() - start_time)
        return None
    
    async def _fetch_kraken_data(self, oracle_config: OracleConfig, asset: Dict) -> Optional[PriceData]:
        """Fetch data from Kraken"""
        start_time = time.time()
        
        # Map symbols to Kraken trading pairs
        symbol_mapping = {
            'ETH': 'XETHZUSD',
            'BTC': 'XXBTZUSD',
            'USDC': 'USDCUSD',
            'USDT': 'USDTZUSD',
            'MATIC': 'MATICUSD',
            'ARB': 'ARBUSD',
            'OP': 'OPUSD',
            'LINK': 'LINKUSD',
            'UNI': 'UNIUSD',
            'AAVE': 'AAVEUSD',
            'CRV': 'CRVUSD',
            'SNX': 'SNXUSD'
        }
        
        trading_pair = symbol_mapping.get(asset['symbol'])
        if not trading_pair:
            return None
        
        url = f"{oracle_config.endpoint}/public/Ticker"
        params = {'pair': trading_pair}
        
        async with self.session.get(url, params=params, timeout=oracle_config.timeout) as response:
            if response.status == 200:
                data = await response.json()
                
                if 'result' in data and trading_pair in data['result']:
                    ticker_data = data['result'][trading_pair]
                    
                    return PriceData(
                        symbol=asset['symbol'],
                        price_usd=Decimal(str(ticker_data.get('c', [0])[0])),
                        volume_24h_usd=Decimal(str(ticker_data.get('v', [0])[1])),
                        price_change_24h_percent=Decimal(str(ticker_data.get('p', [0])[1])),
                        high_24h_usd=Decimal(str(ticker_data.get('h', [0])[1])),
                        low_24h_usd=Decimal(str(ticker_data.get('l', [0])[1]))
                    )
        
        ORACLE_RESPONSE_TIME.labels(oracle='kraken').observe(time.time() - start_time)
        return None
    
    async def _fetch_coinbase_data(self, oracle_config: OracleConfig, asset: Dict) -> Optional[PriceData]:
        """Fetch data from Coinbase"""
        start_time = time.time()
        
        # Map symbols to Coinbase trading pairs
        symbol_mapping = {
            'ETH': 'ETH-USD',
            'BTC': 'BTC-USD',
            'USDC': 'USDC-USD',
            'USDT': 'USDT-USD',
            'MATIC': 'MATIC-USD',
            'ARB': 'ARB-USD',
            'OP': 'OP-USD',
            'LINK': 'LINK-USD',
            'UNI': 'UNI-USD',
            'AAVE': 'AAVE-USD',
            'CRV': 'CRV-USD',
            'SNX': 'SNX-USD'
        }
        
        trading_pair = symbol_mapping.get(asset['symbol'])
        if not trading_pair:
            return None
        
        url = f"{oracle_config.endpoint}/products/{trading_pair}/ticker"
        
        async with self.session.get(url, timeout=oracle_config.timeout) as response:
            if response.status == 200:
                data = await response.json()
                
                return PriceData(
                    symbol=asset['symbol'],
                    price_usd=Decimal(str(data.get('price', 0))),
                    volume_24h_usd=Decimal(str(data.get('volume', 0))),
                    price_change_24h_percent=Decimal(str(data.get('change_24h', 0)))
                )
        
        ORACLE_RESPONSE_TIME.labels(oracle='coinbase').observe(time.time() - start_time)
        return None
    
    async def _store_price_data(self, oracle_name: str, asset: Dict, price_data: PriceData):
        """Store price data in database"""
        try:
            async with self.db_pool.acquire() as conn:
                # Get oracle source ID
                oracle_id = await conn.fetchval(
                    "SELECT id FROM oracle_sources WHERE name = $1",
                    oracle_name
                )
                
                if not oracle_id:
                    logger.error(f"Oracle {oracle_name} not found in database")
                    return
                
                # Get asset ID
                asset_id = await conn.fetchval(
                    "SELECT id FROM crypto_assets WHERE symbol = $1",
                    asset['symbol']
                )
                
                if not asset_id:
                    logger.error(f"Asset {asset['symbol']} not found in database")
                    return
                
                # Insert price feed
                await conn.execute("""
                    INSERT INTO price_feeds (
                        asset_id, oracle_source_id, price_usd, volume_24h_usd,
                        market_cap_usd, price_change_24h_percent, price_change_7d_percent,
                        price_change_30d_percent, high_24h_usd, low_24h_usd,
                        circulating_supply, total_supply, max_supply, last_updated
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
                    ON CONFLICT (asset_id, oracle_source_id, last_updated) DO NOTHING
                """, asset_id, oracle_id, price_data.price_usd, price_data.volume_24h_usd,
                     price_data.market_cap_usd, price_data.price_change_24h_percent,
                     price_data.price_change_7d_percent, price_data.price_change_30d_percent,
                     price_data.high_24h_usd, price_data.low_24h_usd,
                     price_data.circulating_supply, price_data.total_supply,
                     price_data.max_supply, datetime.utcnow())
                
                # Also store in history
                await conn.execute("""
                    INSERT INTO oracle_feed_history (
                        asset_id, oracle_source_id, price_usd, volume_24h_usd,
                        market_cap_usd, timestamp
                    ) VALUES ($1, $2, $3, $4, $5, $6)
                """, asset_id, oracle_id, price_data.price_usd, price_data.volume_24h_usd,
                     price_data.market_cap_usd, datetime.utcnow())
                
                PRICE_UPDATES.labels(asset=asset['symbol'], oracle=oracle_name).inc()
                logger.info(f"Stored price data for {asset['symbol']} from {oracle_name}")
                
        except Exception as e:
            logger.error(f"Error storing price data: {e}")
    
    async def _collect_l2_network_data(self):
        """Collect L2 network specific data"""
        logger.info("Starting L2 network data collection")
        
        l2_networks = [
            {'name': 'Polygon', 'token': 'MATIC', 'coingecko_id': 'matic-network'},
            {'name': 'Arbitrum', 'token': 'ARB', 'coingecko_id': 'arbitrum'},
            {'name': 'Optimism', 'token': 'OP', 'coingecko_id': 'optimism'},
            {'name': 'Base', 'token': 'ETH', 'coingecko_id': 'ethereum'},
            {'name': 'zkSync Era', 'token': 'ETH', 'coingecko_id': 'ethereum'},
            {'name': 'Starknet', 'token': 'ETH', 'coingecko_id': 'ethereum'},
            {'name': 'Linea', 'token': 'ETH', 'coingecko_id': 'ethereum'},
            {'name': 'Scroll', 'token': 'ETH', 'coingecko_id': 'ethereum'},
            {'name': 'Mantle', 'token': 'MNT', 'coingecko_id': 'mantle'},
            {'name': 'Blast', 'token': 'ETH', 'coingecko_id': 'ethereum'}
        ]
        
        while True:
            try:
                for network in l2_networks:
                    # Get price data
                    price_data = await self._fetch_coingecko_data(
                        self.oracles['coingecko'],
                        {'symbol': network['token'], 'coingecko_id': network['coingecko_id']}
                    )
                    
                    if price_data:
                        # Get TVL data from DeFiLlama
                        tvl_data = await self._fetch_l2_tvl_data(network['name'])
                        
                        # Store L2 network data
                        await self._store_l2_network_data(network, price_data, tvl_data)
                
                # Update every 5 minutes
                await asyncio.sleep(300)
                
            except Exception as e:
                logger.error(f"Error in L2 network data collection: {e}")
                await asyncio.sleep(60)
    
    async def _fetch_l2_tvl_data(self, network_name: str) -> Optional[Dict]:
        """Fetch TVL data for L2 networks from DeFiLlama"""
        try:
            # Map network names to DeFiLlama IDs
            network_mapping = {
                'Polygon': 'polygon',
                'Arbitrum': 'arbitrum',
                'Optimism': 'optimism',
                'Base': 'base',
                'zkSync Era': 'zksync-era',
                'Starknet': 'starknet',
                'Linea': 'linea',
                'Scroll': 'scroll',
                'Mantle': 'mantle',
                'Blast': 'blast'
            }
            
            defillama_id = network_mapping.get(network_name)
            if not defillama_id:
                return None
            
            url = f"https://api.llama.fi/protocol/{defillama_id}"
            
            async with self.session.get(url, timeout=30) as response:
                if response.status == 200:
                    data = await response.json()
                    return {
                        'tvl_usd': data.get('tvl', 0),
                        'total_transactions_24h': data.get('dailyTransactions', 0)
                    }
            
        except Exception as e:
            logger.error(f"Error fetching TVL data for {network_name}: {e}")
            return None
    
    async def _store_l2_network_data(self, network: Dict, price_data: PriceData, tvl_data: Optional[Dict]):
        """Store L2 network data"""
        try:
            async with self.db_pool.acquire() as conn:
                await conn.execute("""
                    INSERT INTO l2_network_prices (
                        network, network_token_symbol, price_usd, volume_24h_usd,
                        market_cap_usd, price_change_24h_percent, tvl_usd,
                        total_transactions_24h, last_updated
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
                    ON CONFLICT (network, last_updated) DO UPDATE SET
                        price_usd = EXCLUDED.price_usd,
                        volume_24h_usd = EXCLUDED.volume_24h_usd,
                        market_cap_usd = EXCLUDED.market_cap_usd,
                        price_change_24h_percent = EXCLUDED.price_change_24h_percent,
                        tvl_usd = EXCLUDED.tvl_usd,
                        total_transactions_24h = EXCLUDED.total_transactions_24h
                """, network['name'], network['token'], price_data.price_usd,
                     price_data.volume_24h_usd, price_data.market_cap_usd,
                     price_data.price_change_24h_percent, tvl_data.get('tvl_usd') if tvl_data else None,
                     tvl_data.get('total_transactions_24h') if tvl_data else None,
                     datetime.utcnow())
                
                logger.info(f"Stored L2 network data for {network['name']}")
                
        except Exception as e:
            logger.error(f"Error storing L2 network data: {e}")
    
    async def _aggregate_prices(self):
        """Aggregate prices from multiple oracles"""
        logger.info("Starting price aggregation service")
        
        while True:
            try:
                async with self.db_pool.acquire() as conn:
                    # Get all active assets
                    assets = await conn.fetch("SELECT id, symbol FROM crypto_assets WHERE is_active = true")
                    
                    for asset in assets:
                        # Calculate price aggregation
                        await conn.execute("SELECT calculate_price_aggregation($1)", asset['id'])
                
                # Update every 10 minutes
                await asyncio.sleep(600)
                
            except Exception as e:
                logger.error(f"Error in price aggregation: {e}")
                await asyncio.sleep(60)
    
    async def _publish_price_update(self, oracle_name: str, asset: Dict, price_data: PriceData):
        """Publish price update to Kafka"""
        try:
            message = {
                'oracle': oracle_name,
                'asset': asset['symbol'],
                'price_usd': float(price_data.price_usd),
                'volume_24h_usd': float(price_data.volume_24h_usd) if price_data.volume_24h_usd else None,
                'market_cap_usd': float(price_data.market_cap_usd) if price_data.market_cap_usd else None,
                'price_change_24h_percent': float(price_data.price_change_24h_percent) if price_data.price_change_24h_percent else None,
                'timestamp': datetime.utcnow().isoformat()
            }
            
            self.kafka_producer.send('price_updates', value=message, key=asset['symbol'].encode())
            logger.debug(f"Published price update for {asset['symbol']} from {oracle_name}")
            
        except Exception as e:
            logger.error(f"Error publishing to Kafka: {e}")
    
    async def cleanup(self):
        """Cleanup resources"""
        if self.db_pool:
            await self.db_pool.close()
        
        if self.session:
            await self.session.close()
        
        if self.kafka_producer:
            self.kafka_producer.close()

async def main():
    service = PriceOracleService()
    
    try:
        await service.initialize()
        await service.start_service()
    except KeyboardInterrupt:
        logger.info("Shutting down Price Oracle Service...")
    finally:
        await service.cleanup()

if __name__ == "__main__":
    asyncio.run(main())
