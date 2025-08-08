import asyncio
import json
import os
from datetime import datetime
from typing import Dict, List
from dotenv import load_dotenv
from prometheus_client import start_http_server, Counter, Histogram
import redis
from kafka import KafkaConsumer
import asyncpg
import clickhouse_connect

# Load environment variables
load_dotenv()

# Prometheus metrics
PROCESSED_MESSAGES = Counter('stream_processed_messages_total', 'Total processed messages', ['topic'])
PROCESSING_ERRORS = Counter('stream_processing_errors_total', 'Total processing errors', ['topic'])
PROCESSING_DURATION = Histogram('stream_processing_duration_seconds', 'Processing duration', ['topic'])

class StreamProcessor:
    def __init__(self):
        self.consumer = KafkaConsumer(
            'subgraph_data', 'price_data', 'tvl_data',
            bootstrap_servers=os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092").split(","),
            value_deserializer=lambda x: json.loads(x.decode('utf-8')),
            group_id='stream_processor_group',
            enable_auto_commit=True,
            auto_offset_reset='latest'
        )
        self.redis_client = redis.Redis(
            host=os.getenv("REDIS_HOST", "redis"),
            port=int(os.getenv("REDIS_PORT", "6379")),
            decode_responses=True
        )
        self.db_pool = None
        self.clickhouse_client = None
        self.processors = {
            'subgraph_data': self._process_subgraph_data,
            'price_data': self._process_price_data,
            'tvl_data': self._process_tvl_data
        }
    
    async def start_processing(self):
        """Start consuming and processing messages"""
        print("Starting stream processing service...")
        
        # Start Prometheus metrics server
        start_http_server(8080)
        
        # Initialize database connections
        await self._init_database_connections()
        
        print("Stream processor started. Waiting for messages...")
        
        for message in self.consumer:
            try:
                start_time = datetime.now()
                
                await self.processors[message.topic](message.value)
                
                PROCESSED_MESSAGES.labels(topic=message.topic).inc()
                PROCESSING_DURATION.labels(topic=message.topic).observe(
                    (datetime.now() - start_time).total_seconds()
                )
                
            except Exception as e:
                PROCESSING_ERRORS.labels(topic=message.topic).inc()
                print(f"Error processing message from {message.topic}: {e}")
    
    async def _init_database_connections(self):
        """Initialize database connection pools"""
        # PostgreSQL connection
        self.db_pool = await asyncpg.create_pool(
            os.getenv("POSTGRES_URL", "postgresql://postgres:password@postgres:5432/defi_analytics"),
            min_size=5,
            max_size=20
        )
        
        # ClickHouse connection
        self.clickhouse_client = clickhouse_connect.get_client(
            host=os.getenv("CLICKHOUSE_HOST", "clickhouse"),
            port=int(os.getenv("CLICKHOUSE_PORT", "8123")),
            username=os.getenv("CLICKHOUSE_USER", "default"),
            password=os.getenv("CLICKHOUSE_PASSWORD", "password"),
            database=os.getenv("CLICKHOUSE_DB", "analytics")
        )
        
        print("Database connections initialized")
    
    async def _process_subgraph_data(self, data: Dict):
        """Process subgraph data and update database"""
        protocol = data['protocol']
        timestamp = datetime.fromisoformat(data['timestamp'])
        subgraph_data = data['data']
        
        if protocol == "uniswap_v3":
            await self._process_uniswap_data(subgraph_data, timestamp)
    
    async def _process_uniswap_data(self, pools_data: Dict, timestamp: datetime):
        """Process Uniswap V3 pool data"""
        if 'pools' not in pools_data.get('data', {}):
            return
        
        async with self.db_pool.acquire() as conn:
            for pool in pools_data['data']['pools']:
                # Calculate additional metrics
                token0_symbol = pool['token0']['symbol']
                token1_symbol = pool['token1']['symbol']
                pair_name = f"{token0_symbol}/{token1_symbol}"
                
                # Insert/update pool data
                await conn.execute("""
                    INSERT INTO uniswap_pools (
                        pool_id, pair_name, token0_symbol, token1_symbol,
                        tvl_usd, volume_24h_usd, fee_tier, timestamp
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                    ON CONFLICT (pool_id, timestamp) DO UPDATE SET
                        tvl_usd = EXCLUDED.tvl_usd,
                        volume_24h_usd = EXCLUDED.volume_24h_usd
                """, 
                pool['id'], pair_name, token0_symbol, token1_symbol,
                float(pool['totalValueLockedUSD']), float(pool['volumeUSD']),
                int(pool['feeTier']), timestamp
                )
                
                # Store in ClickHouse for time-series analytics
                await self._store_timeseries_data("pool_metrics", {
                    "timestamp": timestamp,
                    "protocol_name": "uniswap_v3",
                    "pool_id": pool['id'],
                    "pair_name": pair_name,
                    "tvl_usd": float(pool['totalValueLockedUSD']),
                    "volume_24h_usd": float(pool['volumeUSD']),
                    "fee_tier": int(pool['feeTier'])
                })
        
        print(f"Processed {len(pools_data['data']['pools'])} Uniswap pools")
    
    async def _process_price_data(self, data: Dict):
        """Process price data from CoinGecko"""
        timestamp = datetime.fromisoformat(data['timestamp'])
        price_data = data['data']
        
        async with self.db_pool.acquire() as conn:
            for token_id, metrics in price_data.items():
                await conn.execute("""
                    INSERT INTO token_prices (
                        token_id, price_usd, market_cap_usd, volume_24h_usd,
                        price_change_24h, timestamp
                    ) VALUES ($1, $2, $3, $4, $5, $6)
                    ON CONFLICT (token_id, timestamp) DO UPDATE SET
                        price_usd = EXCLUDED.price_usd,
                        market_cap_usd = EXCLUDED.market_cap_usd,
                        volume_24h_usd = EXCLUDED.volume_24h_usd,
                        price_change_24h = EXCLUDED.price_change_24h
                """,
                token_id, metrics['usd'], metrics.get('usd_market_cap'),
                metrics.get('usd_24h_vol'), metrics.get('usd_24h_change'), timestamp
                )
        
        print(f"Processed price data for {len(price_data)} tokens")
    
    async def _process_tvl_data(self, data: Dict):
        """Process TVL data from DeFiLlama"""
        protocol = data['protocol']
        timestamp = datetime.fromisoformat(data['timestamp'])
        tvl_data = data['data']
        
        # Store TVL data in ClickHouse for real-time analytics
        await self._store_timeseries_data("protocol_metrics", {
            "timestamp": timestamp,
            "protocol_name": protocol,
            "tvl_usd": float(tvl_data.get('tvl', 0)),
            "volume_24h_usd": float(tvl_data.get('volume24h', 0)),
            "fees_24h_usd": float(tvl_data.get('fees24h', 0))
        })
        
        print(f"Processed TVL data for {protocol}")
    
    async def _store_timeseries_data(self, table: str, data: Dict):
        """Store data in ClickHouse time-series table"""
        try:
            # Convert data to ClickHouse format
            clickhouse_data = []
            for key, value in data.items():
                if isinstance(value, datetime):
                    clickhouse_data.append(value)
                else:
                    clickhouse_data.append(value)
            
            # Insert into ClickHouse
            self.clickhouse_client.insert(table, [clickhouse_data])
            
        except Exception as e:
            print(f"Error storing data in ClickHouse: {e}")

async def main():
    processor = StreamProcessor()
    await processor.start_processing()

if __name__ == "__main__":
    asyncio.run(main())
