import asyncio
import aiohttp
import os
import json
import time
from datetime import datetime
from typing import Dict, List
from dataclasses import dataclass
from dotenv import load_dotenv
from prometheus_client import start_http_server, Counter, Histogram
import redis
from kafka import KafkaProducer

# Load environment variables
load_dotenv()

# Prometheus metrics
INGESTION_REQUESTS = Counter('data_ingestion_requests_total', 'Total ingestion requests', ['source'])
INGESTION_ERRORS = Counter('data_ingestion_errors_total', 'Total ingestion errors', ['source'])
INGESTION_DURATION = Histogram('data_ingestion_duration_seconds', 'Ingestion duration', ['source'])

@dataclass
class DataSource:
    name: str
    endpoint: str
    api_key: str
    rate_limit: int  # requests per minute
    priority: int    # 1-5, higher = more important

class DataIngestionService:
    def __init__(self):
        self.sources = self._load_data_sources()
        self.redis_client = redis.Redis(
            host=os.getenv("REDIS_HOST", "redis"),
            port=int(os.getenv("REDIS_PORT", "6379")),
            decode_responses=True
        )
        self.kafka_producer = KafkaProducer(
            bootstrap_servers=os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092").split(","),
            value_serializer=lambda v: json.dumps(v).encode('utf-8'),
            key_serializer=lambda k: k.encode('utf-8') if k else None
        )
    
    def _load_data_sources(self) -> List[DataSource]:
        """Load data sources configuration"""
        # Note: External API keys are commented out as we use our own nodes
        # These data sources are optional and can be enabled if needed
        return [
            # DataSource(
            #     name="the_graph",
            #     endpoint="https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v3",
            #     api_key=os.getenv("THE_GRAPH_API_KEY", ""),
            #     rate_limit=60,
            #     priority=1
            # ),
            # DataSource(
            #     name="coingecko",
            #     endpoint="https://api.coingecko.com/api/v3",
            #     api_key=os.getenv("COINGECKO_API_KEY", ""),
            #     rate_limit=50,
            #     priority=2
            # ),
            # DataSource(
            #     name="defillama",
            #     endpoint="https://api.llama.fi",
            #     api_key=os.getenv("DEFILLAMA_API_KEY", ""),
            #     rate_limit=100,
            #     priority=3
            # )
        ]
    
    async def start_ingestion(self):
        """Start continuous data ingestion from all sources"""
        print("Starting data ingestion service...")
        
        # Start Prometheus metrics server
        start_http_server(8080)
        
        tasks = []
        for source in self.sources:
            if source.name == "the_graph":
                tasks.append(self._ingest_subgraph_data(source))
            elif source.name == "coingecko":
                tasks.append(self._ingest_price_data(source))
            elif source.name == "defillama":
                tasks.append(self._ingest_tvl_data(source))
        
        await asyncio.gather(*tasks)
    
    async def _ingest_subgraph_data(self, source: DataSource):
        """Ingest data from The Graph subgraphs"""
        queries = {
            "uniswap_v3": """
                query {
                    pools(first: 10, orderBy: totalValueLockedUSD, orderDirection: desc) {
                        id
                        token0 { symbol, name }
                        token1 { symbol, name }
                        totalValueLockedUSD
                        volumeUSD
                        feeTier
                    }
                }
            """
        }
        
        while True:
            try:
                start_time = time.time()
                
                for protocol, query in queries.items():
                    data = await self._execute_graphql_query(source, query)
                    await self._publish_to_kafka("subgraph_data", {
                        "protocol": protocol,
                        "data": data,
                        "timestamp": datetime.utcnow().isoformat()
                    })
                
                INGESTION_REQUESTS.labels(source=source.name).inc()
                INGESTION_DURATION.labels(source=source.name).observe(time.time() - start_time)
                
                # Rate limiting
                await asyncio.sleep(60 / source.rate_limit)
                
            except Exception as e:
                INGESTION_ERRORS.labels(source=source.name).inc()
                print(f"Error ingesting {source.name} data: {e}")
                await asyncio.sleep(60)
    
    async def _ingest_price_data(self, source: DataSource):
        """Ingest price data from CoinGecko"""
        tokens_to_track = ["bitcoin", "ethereum", "uniswap", "aave"]
        
        while True:
            try:
                start_time = time.time()
                
                async with aiohttp.ClientSession() as session:
                    url = f"{source.endpoint}/simple/price"
                    params = {
                        "ids": ",".join(tokens_to_track),
                        "vs_currencies": "usd",
                        "include_24hr_change": "true",
                        "include_24hr_vol": "true",
                        "include_market_cap": "true"
                    }
                    
                    async with session.get(url, params=params) as response:
                        price_data = await response.json()
                        
                        await self._publish_to_kafka("price_data", {
                            "data": price_data,
                            "timestamp": datetime.utcnow().isoformat()
                        })
                
                INGESTION_REQUESTS.labels(source=source.name).inc()
                INGESTION_DURATION.labels(source=source.name).observe(time.time() - start_time)
                
                await asyncio.sleep(30)  # Update every 30 seconds
                
            except Exception as e:
                INGESTION_ERRORS.labels(source=source.name).inc()
                print(f"Error ingesting {source.name} data: {e}")
                await asyncio.sleep(60)
    
    async def _ingest_tvl_data(self, source: DataSource):
        """Ingest TVL data from DeFiLlama"""
        protocols = ["uniswap-v3", "aave-v3", "compound-v3"]
        
        while True:
            try:
                start_time = time.time()
                
                async with aiohttp.ClientSession() as session:
                    for protocol in protocols:
                        url = f"{source.endpoint}/protocol/{protocol}"
                        async with session.get(url) as response:
                            tvl_data = await response.json()
                            
                            await self._publish_to_kafka("tvl_data", {
                                "protocol": protocol,
                                "data": tvl_data,
                                "timestamp": datetime.utcnow().isoformat()
                            })
                
                INGESTION_REQUESTS.labels(source=source.name).inc()
                INGESTION_DURATION.labels(source=source.name).observe(time.time() - start_time)
                
                await asyncio.sleep(300)  # Update every 5 minutes
                
            except Exception as e:
                INGESTION_ERRORS.labels(source=source.name).inc()
                print(f"Error ingesting {source.name} data: {e}")
                await asyncio.sleep(60)
    
    async def _execute_graphql_query(self, source: DataSource, query: str) -> Dict:
        """Execute GraphQL query"""
        async with aiohttp.ClientSession() as session:
            async with session.post(
                source.endpoint,
                json={"query": query},
                headers={"Content-Type": "application/json"}
            ) as response:
                return await response.json()
    
    async def _publish_to_kafka(self, topic: str, data: Dict):
        """Publish message to Kafka topic"""
        try:
            future = self.kafka_producer.send(topic, value=data)
            record_metadata = future.get(timeout=10)
            print(f"Published to Kafka topic {topic}: {record_metadata}")
        except Exception as e:
            print(f"Error publishing to Kafka: {e}")
            raise

async def main():
    service = DataIngestionService()
    await service.start_ingestion()

if __name__ == "__main__":
    asyncio.run(main())
