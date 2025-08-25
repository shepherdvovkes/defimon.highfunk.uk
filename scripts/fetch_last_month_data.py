#!/usr/bin/env python3
"""
DeFi Data Ingestion Script
Fetches last month of data from external APIs and stores in PostgreSQL
"""

import asyncio
import aiohttp
import os
import json
import time
from datetime import datetime, timedelta
from typing import Dict, List, Any
import psycopg2
from psycopg2.extras import RealDictCursor
import logging
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DeFiDataIngestion:
    def __init__(self):
        self.db_config = {
            'host': os.getenv('POSTGRES_HOST', 'localhost'),
            'port': os.getenv('POSTGRES_PORT', '5432'),
            'database': os.getenv('POSTGRES_DB', 'defi_analytics'),
            'user': os.getenv('POSTGRES_USER', 'postgres'),
            'password': os.getenv('POSTGRES_PASSWORD', 'password')
        }
        
        # API configurations
        self.coingecko_api_key = os.getenv('COINGECKO_API_KEY', '')
        self.defillama_api_key = os.getenv('DEFILLAMA_API_KEY', '')
        self.the_graph_api_key = os.getenv('THE_GRAPH_API_KEY', '')
        
        # Calculate date range (last month)
        self.end_date = datetime.now()
        self.start_date = self.end_date - timedelta(days=30)
        
    async def get_db_connection(self):
        """Get database connection"""
        try:
            conn = psycopg2.connect(**self.db_config)
            return conn
        except Exception as e:
            logger.error(f"Database connection failed: {e}")
            raise
    
    async def fetch_coingecko_data(self, session: aiohttp.ClientSession) -> List[Dict]:
        """Fetch token price data from CoinGecko"""
        logger.info("Fetching CoinGecko data...")
        
        # Top DeFi tokens
        token_ids = [
            'ethereum', 'uniswap', 'aave', 'compound', 'maker', 'curve-dao-token',
            'synthetix-network-token', 'yearn-finance', 'balancer', 'sushi',
            '1inch', 'pancakeswap-token', 'dydx', 'gmx', 'arbitrum', 'optimism'
        ]
        
        all_data = []
        
        for token_id in token_ids:
            try:
                # Get historical data for last month
                url = f"https://api.coingecko.com/api/v3/coins/{token_id}/market_chart/range"
                params = {
                    'vs_currency': 'usd',
                    'from': int(self.start_date.timestamp()),
                    'to': int(self.end_date.timestamp())
                }
                
                if self.coingecko_api_key:
                    params['x_cg_api_key'] = self.coingecko_api_key
                
                async with session.get(url, params=params) as response:
                    if response.status == 200:
                        data = await response.json()
                        
                        # Process price data
                        for price_point in data.get('prices', []):
                            timestamp = datetime.fromtimestamp(price_point[0] / 1000)
                            price = price_point[1]
                            
                            all_data.append({
                                'token_id': token_id,
                                'timestamp': timestamp,
                                'price_usd': price,
                                'source': 'coingecko'
                            })
                        
                        logger.info(f"Fetched {len(data.get('prices', []))} price points for {token_id}")
                        
                        # Rate limiting
                        await asyncio.sleep(1.2)  # CoinGecko free tier limit
                        
                    else:
                        logger.warning(f"Failed to fetch data for {token_id}: {response.status}")
                        
            except Exception as e:
                logger.error(f"Error fetching CoinGecko data for {token_id}: {e}")
                continue
        
        return all_data
    
    async def fetch_defillama_data(self, session: aiohttp.ClientSession) -> List[Dict]:
        """Fetch TVL data from DeFiLlama"""
        logger.info("Fetching DeFiLlama data...")
        
        # Top DeFi protocols
        protocols = [
            'uniswap-v3', 'aave-v3', 'compound-v3', 'curve', 'makerdao',
            'synthetix', 'yearn-finance', 'balancer-v2', 'sushi', '1inch',
            'pancakeswap', 'dydx', 'gmx', 'arbitrum', 'optimism'
        ]
        
        all_data = []
        
        for protocol in protocols:
            try:
                # Get historical TVL data
                url = f"https://api.llama.fi/protocol/{protocol}"
                
                headers = {}
                if self.defillama_api_key:
                    headers['Authorization'] = f'Bearer {self.defillama_api_key}'
                
                async with session.get(url, headers=headers) as response:
                    if response.status == 200:
                        data = await response.json()
                        
                        # Process TVL data
                        for tvl_point in data.get('tvl', []):
                            timestamp = datetime.fromtimestamp(tvl_point['date'])
                            
                            # Only include data from last month
                            if self.start_date <= timestamp <= self.end_date:
                                all_data.append({
                                    'protocol_name': protocol,
                                    'timestamp': timestamp,
                                    'tvl_usd': tvl_point['totalLiquidityUSD'],
                                    'source': 'defillama'
                                })
                        
                        logger.info(f"Fetched {len(data.get('tvl', []))} TVL points for {protocol}")
                        
                        # Rate limiting
                        await asyncio.sleep(0.5)
                        
                    else:
                        logger.warning(f"Failed to fetch data for {protocol}: {response.status}")
                        
            except Exception as e:
                logger.error(f"Error fetching DeFiLlama data for {protocol}: {e}")
                continue
        
        return all_data
    
    async def fetch_uniswap_data(self, session: aiohttp.ClientSession) -> List[Dict]:
        """Fetch Uniswap V3 data from The Graph"""
        logger.info("Fetching Uniswap V3 data...")
        
        # GraphQL query for Uniswap V3 pools
        query = """
        query($startTime: Int!, $endTime: Int!) {
            pools(first: 100, orderBy: totalValueLockedUSD, orderDirection: desc) {
                id
                token0 { symbol, name, decimals }
                token1 { symbol, name, decimals }
                feeTier
                totalValueLockedUSD
                volumeUSD
                feesUSD
                poolDayData(
                    first: 30,
                    orderBy: date,
                    orderDirection: desc,
                    where: { date_gte: $startTime, date_lte: $endTime }
                ) {
                    date
                    tvlUSD
                    volumeUSD
                    feesUSD
                }
            }
        }
        """
        
        variables = {
            'startTime': int(self.start_date.timestamp()),
            'endTime': int(self.end_date.timestamp())
        }
        
        headers = {
            'Content-Type': 'application/json'
        }
        
        if self.the_graph_api_key:
            headers['Authorization'] = f'Bearer {self.the_graph_api_key}'
        
        try:
            url = "https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v3"
            
            async with session.post(url, json={'query': query, 'variables': variables}, headers=headers) as response:
                if response.status == 200:
                    data = await response.json()
                    
                    all_data = []
                    
                    for pool in data.get('data', {}).get('pools', []):
                        pool_id = pool['id']
                        token0_symbol = pool['token0']['symbol']
                        token1_symbol = pool['token1']['symbol']
                        fee_tier = pool['feeTier']
                        
                        for day_data in pool.get('poolDayData', []):
                            timestamp = datetime.fromtimestamp(day_data['date'])
                            
                            all_data.append({
                                'pool_id': pool_id,
                                'pair_name': f"{token0_symbol}/{token1_symbol}",
                                'token0_symbol': token0_symbol,
                                'token1_symbol': token1_symbol,
                                'fee_tier': fee_tier,
                                'timestamp': timestamp,
                                'tvl_usd': float(day_data['tvlUSD']),
                                'volume_24h_usd': float(day_data['volumeUSD']),
                                'fees_24h_usd': float(day_data['feesUSD']),
                                'source': 'uniswap_v3'
                            })
                    
                    logger.info(f"Fetched {len(all_data)} Uniswap V3 data points")
                    return all_data
                    
                else:
                    logger.warning(f"Failed to fetch Uniswap data: {response.status}")
                    return []
                    
        except Exception as e:
            logger.error(f"Error fetching Uniswap data: {e}")
            return []
    
    async def store_token_prices(self, conn, data: List[Dict]):
        """Store token price data in database"""
        logger.info(f"Storing {len(data)} token price records...")
        
        cursor = conn.cursor()
        
        try:
            for record in data:
                cursor.execute("""
                    INSERT INTO token_prices (token_id, symbol, price_usd, timestamp, created_at)
                    VALUES (%s, %s, %s, %s, NOW())
                    ON CONFLICT (token_id, timestamp) DO UPDATE SET
                        price_usd = EXCLUDED.price_usd,
                        created_at = NOW()
                """, (
                    record['token_id'],
                    record['token_id'].upper(),
                    record['price_usd'],
                    record['timestamp']
                ))
            
            conn.commit()
            logger.info("Token prices stored successfully")
            
        except Exception as e:
            conn.rollback()
            logger.error(f"Error storing token prices: {e}")
            raise
        finally:
            cursor.close()
    
    async def store_protocol_data(self, conn, data: List[Dict]):
        """Store protocol TVL data in database"""
        logger.info(f"Storing {len(data)} protocol data records...")
        
        cursor = conn.cursor()
        
        try:
            for record in data:
                # First ensure protocol exists
                cursor.execute("""
                    INSERT INTO protocols (name, display_name, category, chain, created_at)
                    VALUES (%s, %s, %s, %s, NOW())
                    ON CONFLICT (name) DO NOTHING
                """, (
                    record['protocol_name'],
                    record['protocol_name'].replace('-', ' ').title(),
                    'defi',
                    'ethereum'
                ))
                
                # Get protocol ID
                cursor.execute("SELECT id FROM protocols WHERE name = %s", (record['protocol_name'],))
                protocol_id = cursor.fetchone()[0]
                
                # Store protocol data
                cursor.execute("""
                    INSERT INTO protocol_data (protocol_id, timestamp, total_value_locked, created_at)
                    VALUES (%s, %s, %s, NOW())
                    ON CONFLICT (protocol_id, timestamp) DO UPDATE SET
                        total_value_locked = EXCLUDED.total_value_locked,
                        created_at = NOW()
                """, (
                    protocol_id,
                    record['timestamp'],
                    record['tvl_usd']
                ))
            
            conn.commit()
            logger.info("Protocol data stored successfully")
            
        except Exception as e:
            conn.rollback()
            logger.error(f"Error storing protocol data: {e}")
            raise
        finally:
            cursor.close()
    
    async def store_uniswap_data(self, conn, data: List[Dict]):
        """Store Uniswap pool data in database"""
        logger.info(f"Storing {len(data)} Uniswap pool records...")
        
        cursor = conn.cursor()
        
        try:
            for record in data:
                cursor.execute("""
                    INSERT INTO uniswap_pools (
                        pool_id, pair_name, token0_symbol, token1_symbol, fee_tier,
                        tvl_usd, volume_24h_usd, fees_24h_usd, timestamp, created_at
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
                    ON CONFLICT (pool_id, timestamp) DO UPDATE SET
                        tvl_usd = EXCLUDED.tvl_usd,
                        volume_24h_usd = EXCLUDED.volume_24h_usd,
                        fees_24h_usd = EXCLUDED.fees_24h_usd,
                        created_at = NOW()
                """, (
                    record['pool_id'],
                    record['pair_name'],
                    record['token0_symbol'],
                    record['token1_symbol'],
                    record['fee_tier'],
                    record['tvl_usd'],
                    record['volume_24h_usd'],
                    record['fees_24h_usd'],
                    record['timestamp']
                ))
            
            conn.commit()
            logger.info("Uniswap data stored successfully")
            
        except Exception as e:
            conn.rollback()
            logger.error(f"Error storing Uniswap data: {e}")
            raise
        finally:
            cursor.close()
    
    async def run_ingestion(self):
        """Run the complete data ingestion process"""
        logger.info("Starting DeFi data ingestion...")
        logger.info(f"Date range: {self.start_date} to {self.end_date}")
        
        # Get database connection
        conn = await self.get_db_connection()
        
        try:
            # Create aiohttp session
            timeout = aiohttp.ClientTimeout(total=60)
            async with aiohttp.ClientSession(timeout=timeout) as session:
                
                # Fetch data from all sources
                tasks = [
                    self.fetch_coingecko_data(session),
                    self.fetch_defillama_data(session),
                    self.fetch_uniswap_data(session)
                ]
                
                results = await asyncio.gather(*tasks, return_exceptions=True)
                
                # Process results
                coingecko_data = results[0] if not isinstance(results[0], Exception) else []
                defillama_data = results[1] if not isinstance(results[1], Exception) else []
                uniswap_data = results[2] if not isinstance(results[2], Exception) else []
                
                # Store data in database
                if coingecko_data:
                    await self.store_token_prices(conn, coingecko_data)
                
                if defillama_data:
                    await self.store_protocol_data(conn, defillama_data)
                
                if uniswap_data:
                    await self.store_uniswap_data(conn, uniswap_data)
                
                logger.info("Data ingestion completed successfully!")
                logger.info(f"Total records processed:")
                logger.info(f"  - Token prices: {len(coingecko_data)}")
                logger.info(f"  - Protocol TVL: {len(defillama_data)}")
                logger.info(f"  - Uniswap pools: {len(uniswap_data)}")
                
        except Exception as e:
            logger.error(f"Data ingestion failed: {e}")
            raise
        finally:
            conn.close()

async def main():
    """Main function"""
    ingestion = DeFiDataIngestion()
    await ingestion.run_ingestion()

if __name__ == "__main__":
    asyncio.run(main())
