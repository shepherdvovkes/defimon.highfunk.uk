#!/usr/bin/env python3
"""
Gas Savings Data Collector for L2 Analytics

This module collects gas price data from L1 (Ethereum) and L2 protocols
to calculate gas savings and economic efficiency metrics.
"""

import asyncio
import aiohttp
import logging
import json
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
import pandas as pd
import numpy as np

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class GasPriceData:
    """Data structure for gas price information"""
    protocol: str
    chain: str
    gas_price_gwei: float
    gas_price_usd: float
    eth_price_usd: float
    timestamp: datetime
    source: str

@dataclass
class GasSavingsData:
    """Data structure for gas savings comparison"""
    l2_protocol: str
    l1_gas_price_gwei: float
    l2_gas_price_gwei: float
    l1_gas_price_usd: float
    l2_gas_price_usd: float
    savings_percentage: float
    savings_usd: float
    timestamp: datetime

@dataclass
class TransactionCostData:
    """Data structure for transaction cost analysis"""
    protocol: str
    transaction_type: str
    gas_used: int
    gas_price_gwei: float
    total_cost_usd: float
    timestamp: datetime

class GasSavingsCollector:
    """Collects gas price data and calculates savings"""
    
    def __init__(self):
        self.session: Optional[aiohttp.ClientSession] = None
        
        # RPC endpoints
        self.rpc_endpoints = {
            "ethereum": "https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY",  # L1
            "arbitrum": "https://arb1.arbitrum.io/rpc",
            "optimism": "https://mainnet.optimism.io",
            "polygon": "https://polygon-rpc.com",
            "base": "https://mainnet.base.org",
            "zksync": "https://mainnet.era.zksync.io"
        }
        
        # Gas price APIs
        self.gas_apis = {
            "ethereum": "https://api.etherscan.io/api",
            "arbitrum": "https://api.arbiscan.io/api",
            "optimism": "https://api-optimistic.etherscan.io/api",
            "polygon": "https://api.polygonscan.com/api",
            "base": "https://api.basescan.org/api"
        }
        
        # API keys (you'll need to add your own)
        self.api_keys = {
            "etherscan": "YOUR_ETHERSCAN_API_KEY",
            "arbiscan": "YOUR_ARBISCAN_API_KEY",
            "optimistic_etherscan": "YOUR_OPTIMISTIC_ETHERSCAN_API_KEY",
            "polygonscan": "YOUR_POLYGONSCAN_API_KEY",
            "basescan": "YOUR_BASESCAN_API_KEY"
        }
        
        # L2 Protocol configurations
        self.l2_protocols = {
            "arbitrum": {
                "name": "Arbitrum One",
                "chain_id": 42161,
                "gas_api": "arbiscan",
                "rpc_url": "https://arb1.arbitrum.io/rpc"
            },
            "optimism": {
                "name": "Optimism",
                "chain_id": 10,
                "gas_api": "optimistic_etherscan",
                "rpc_url": "https://mainnet.optimism.io"
            },
            "polygon": {
                "name": "Polygon",
                "chain_id": 137,
                "gas_api": "polygonscan",
                "rpc_url": "https://polygon-rpc.com"
            },
            "base": {
                "name": "Base",
                "chain_id": 8453,
                "gas_api": "basescan",
                "rpc_url": "https://mainnet.base.org"
            }
        }
        
        # Common transaction types and their gas usage
        self.transaction_types = {
            "simple_transfer": 21000,
            "erc20_transfer": 65000,
            "uniswap_swap": 180000,
            "compound_deposit": 120000,
            "aave_borrow": 200000,
            "nft_mint": 150000
        }

    async def __aenter__(self):
        """Async context manager entry"""
        self.session = aiohttp.ClientSession(
            timeout=aiohttp.ClientTimeout(total=30),
            headers={
                "User-Agent": "DefiMon-L2-Analytics/1.0"
            }
        )
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        if self.session:
            await self.session.close()

    async def get_eth_price(self) -> Optional[float]:
        """Get current ETH price in USD"""
        try:
            # Try CoinGecko API first
            url = "https://api.coingecko.com/api/v3/simple/price"
            params = {
                "ids": "ethereum",
                "vs_currencies": "usd"
            }
            
            async with self.session.get(url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    if "ethereum" in data and "usd" in data["ethereum"]:
                        return float(data["ethereum"]["usd"])
            
            # Fallback to CoinMarketCap or other APIs
            logger.warning("Could not get ETH price from CoinGecko")
            return None
            
        except Exception as e:
            logger.error(f"Error getting ETH price: {e}")
            return None

    async def get_gas_price_rpc(self, protocol: str) -> Optional[float]:
        """Get gas price using RPC call"""
        try:
            rpc_url = self.rpc_endpoints.get(protocol)
            if not rpc_url:
                logger.error(f"No RPC endpoint found for protocol {protocol}")
                return None
            
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_gasPrice",
                "params": [],
                "id": 1
            }
            
            async with self.session.post(rpc_url, json=payload) as response:
                if response.status == 200:
                    data = await response.json()
                    if "result" in data:
                        # Convert from hex to decimal and then to gwei
                        gas_price_wei = int(data["result"], 16)
                        gas_price_gwei = gas_price_wei / 1e9
                        return gas_price_gwei
            
            return None
            
        except Exception as e:
            logger.error(f"Error getting gas price via RPC for {protocol}: {e}")
            return None

    async def get_gas_price_api(self, protocol: str) -> Optional[float]:
        """Get gas price using API"""
        try:
            protocol_config = self.l2_protocols.get(protocol)
            if not protocol_config:
                logger.error(f"No configuration found for protocol {protocol}")
                return None
            
            gas_api = protocol_config.get("gas_api")
            if not gas_api:
                logger.error(f"No gas API configured for protocol {protocol}")
                return None
            
            api_key = self.api_keys.get(gas_api)
            if not api_key:
                logger.error(f"No API key found for {gas_api}")
                return None
            
            api_url = self.gas_apis.get(protocol)
            if not api_url:
                logger.error(f"No API URL found for protocol {protocol}")
                return None
            
            params = {
                "module": "proxy",
                "action": "eth_gasPrice",
                "apikey": api_key
            }
            
            async with self.session.get(api_url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    if data.get("status") == "1" and "result" in data:
                        # Convert from hex to decimal and then to gwei
                        gas_price_wei = int(data["result"], 16)
                        gas_price_gwei = gas_price_wei / 1e9
                        return gas_price_gwei
                    else:
                        logger.warning(f"API error for {protocol}: {data.get('message', 'Unknown error')}")
            
            return None
            
        except Exception as e:
            logger.error(f"Error getting gas price via API for {protocol}: {e}")
            return None

    async def collect_gas_prices(self) -> List[GasPriceData]:
        """Collect gas prices from all protocols"""
        gas_data = []
        timestamp = datetime.now()
        
        # Get ETH price for USD conversion
        eth_price = await self.get_eth_price()
        if not eth_price:
            logger.warning("Could not get ETH price, using placeholder value")
            eth_price = 2000.0  # Placeholder
        
        # Collect L1 (Ethereum) gas price
        logger.info("Collecting Ethereum L1 gas price...")
        l1_gas_price = await self.get_gas_price_rpc("ethereum")
        if l1_gas_price:
            gas_data.append(GasPriceData(
                protocol="ethereum",
                chain="Ethereum L1",
                gas_price_gwei=l1_gas_price,
                gas_price_usd=l1_gas_price * eth_price / 1e9,
                eth_price_usd=eth_price,
                timestamp=timestamp,
                source="rpc"
            ))
            logger.info(f"Ethereum L1 gas price: {l1_gas_price:.2f} gwei (${l1_gas_price * eth_price / 1e9:.4f})")
        
        # Collect L2 gas prices
        for protocol_key, protocol_config in self.l2_protocols.items():
            logger.info(f"Collecting gas price for {protocol_config['name']}...")
            
            # Try API first, then RPC
            gas_price = await self.get_gas_price_api(protocol_key)
            if not gas_price:
                gas_price = await self.get_gas_price_rpc(protocol_key)
            
            if gas_price:
                gas_data.append(GasPriceData(
                    protocol=protocol_key,
                    chain=protocol_config['name'],
                    gas_price_gwei=gas_price,
                    gas_price_usd=gas_price * eth_price / 1e9,
                    eth_price_usd=eth_price,
                    timestamp=timestamp,
                    source="api" if gas_price else "rpc"
                ))
                logger.info(f"{protocol_config['name']} gas price: {gas_price:.2f} gwei (${gas_price * eth_price / 1e9:.4f})")
            else:
                logger.warning(f"Could not get gas price for {protocol_config['name']}")
        
        return gas_data

    def calculate_gas_savings(self, gas_data: List[GasPriceData]) -> List[GasSavingsData]:
        """Calculate gas savings between L1 and L2 protocols"""
        savings_data = []
        
        # Find L1 gas price
        l1_data = next((data for data in gas_data if data.protocol == "ethereum"), None)
        if not l1_data:
            logger.error("No L1 gas price data found")
            return []
        
        # Calculate savings for each L2 protocol
        for data in gas_data:
            if data.protocol != "ethereum":  # Skip L1
                savings_percentage = ((l1_data.gas_price_usd - data.gas_price_usd) / l1_data.gas_price_usd) * 100
                savings_usd = l1_data.gas_price_usd - data.gas_price_usd
                
                savings_data.append(GasSavingsData(
                    l2_protocol=data.protocol,
                    l1_gas_price_gwei=l1_data.gas_price_gwei,
                    l2_gas_price_gwei=data.gas_price_gwei,
                    l1_gas_price_usd=l1_data.gas_price_usd,
                    l2_gas_price_usd=data.gas_price_usd,
                    savings_percentage=savings_percentage,
                    savings_usd=savings_usd,
                    timestamp=data.timestamp
                ))
                
                logger.info(f"Gas savings for {data.chain}: {savings_percentage:.2f}% (${savings_usd:.4f})")
        
        return savings_data

    def calculate_transaction_costs(self, gas_data: List[GasPriceData]) -> List[TransactionCostData]:
        """Calculate transaction costs for different transaction types"""
        transaction_costs = []
        timestamp = datetime.now()
        
        for data in gas_data:
            for tx_type, gas_used in self.transaction_types.items():
                total_cost_usd = data.gas_price_usd * gas_used
                
                transaction_costs.append(TransactionCostData(
                    protocol=data.protocol,
                    transaction_type=tx_type,
                    gas_used=gas_used,
                    gas_price_gwei=data.gas_price_gwei,
                    total_cost_usd=total_cost_usd,
                    timestamp=timestamp
                ))
        
        return transaction_costs

    async def get_historical_gas_data(self, protocol: str, days: int = 30) -> List[GasPriceData]:
        """Get historical gas price data"""
        try:
            protocol_config = self.l2_protocols.get(protocol)
            if not protocol_config:
                logger.error(f"No configuration found for protocol {protocol}")
                return []
            
            gas_api = protocol_config.get("gas_api")
            api_key = self.api_keys.get(gas_api)
            api_url = self.gas_apis.get(protocol)
            
            if not all([gas_api, api_key, api_url]):
                logger.error(f"Missing configuration for historical data: {protocol}")
                return []
            
            # Calculate date range
            end_date = datetime.now()
            start_date = end_date - timedelta(days=days)
            
            historical_data = []
            
            # Get daily gas prices for the period
            current_date = start_date
            while current_date <= end_date:
                params = {
                    "module": "stats",
                    "action": "dailyavgnetgasprice",
                    "startdate": current_date.strftime("%Y-%m-%d"),
                    "enddate": current_date.strftime("%Y-%m-%d"),
                    "apikey": api_key
                }
                
                async with self.session.get(api_url, params=params) as response:
                    if response.status == 200:
                        data = await response.json()
                        if data.get("status") == "1" and "result" in data:
                            for result in data["result"]:
                                gas_price_gwei = float(result.get("gasPrice", 0)) / 1e9
                                historical_data.append(GasPriceData(
                                    protocol=protocol,
                                    chain=protocol_config['name'],
                                    gas_price_gwei=gas_price_gwei,
                                    gas_price_usd=0,  # Would need historical ETH price
                                    eth_price_usd=0,
                                    timestamp=datetime.strptime(result.get("date"), "%Y-%m-%d"),
                                    source="historical_api"
                                ))
                
                current_date += timedelta(days=1)
                await asyncio.sleep(0.1)  # Rate limiting
            
            logger.info(f"Collected {len(historical_data)} historical gas price records for {protocol}")
            return historical_data
            
        except Exception as e:
            logger.error(f"Error getting historical gas data for {protocol}: {e}")
            return []

    async def save_gas_data(self, gas_data: List[GasPriceData], filename: str = None):
        """Save gas price data to JSON file"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"gas_price_data_{timestamp}.json"
        
        data_to_save = []
        for data in gas_data:
            data_to_save.append({
                "protocol": data.protocol,
                "chain": data.chain,
                "gas_price_gwei": data.gas_price_gwei,
                "gas_price_usd": data.gas_price_usd,
                "eth_price_usd": data.eth_price_usd,
                "timestamp": data.timestamp.isoformat(),
                "source": data.source
            })
        
        try:
            with open(filename, 'w') as f:
                json.dump(data_to_save, f, indent=2)
            logger.info(f"Gas price data saved to {filename}")
        except Exception as e:
            logger.error(f"Error saving gas price data: {e}")

    async def save_savings_data(self, savings_data: List[GasSavingsData], filename: str = None):
        """Save gas savings data to JSON file"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"gas_savings_data_{timestamp}.json"
        
        data_to_save = []
        for data in savings_data:
            data_to_save.append({
                "l2_protocol": data.l2_protocol,
                "l1_gas_price_gwei": data.l1_gas_price_gwei,
                "l2_gas_price_gwei": data.l2_gas_price_gwei,
                "l1_gas_price_usd": data.l1_gas_price_usd,
                "l2_gas_price_usd": data.l2_gas_price_usd,
                "savings_percentage": data.savings_percentage,
                "savings_usd": data.savings_usd,
                "timestamp": data.timestamp.isoformat()
            })
        
        try:
            with open(filename, 'w') as f:
                json.dump(data_to_save, f, indent=2)
            logger.info(f"Gas savings data saved to {filename}")
        except Exception as e:
            logger.error(f"Error saving gas savings data: {e}")

async def main():
    """Main function for testing the gas savings collector"""
    async with GasSavingsCollector() as collector:
        logger.info("Starting gas savings data collection...")
        
        # Collect current gas prices
        gas_data = await collector.collect_gas_prices()
        
        if gas_data:
            # Save gas price data
            await collector.save_gas_data(gas_data)
            
            # Calculate gas savings
            savings_data = collector.calculate_gas_savings(gas_data)
            
            if savings_data:
                # Save savings data
                await collector.save_savings_data(savings_data)
                
                # Calculate transaction costs
                transaction_costs = collector.calculate_transaction_costs(gas_data)
                
                # Save transaction costs
                costs_data = []
                for cost in transaction_costs:
                    costs_data.append({
                        "protocol": cost.protocol,
                        "transaction_type": cost.transaction_type,
                        "gas_used": cost.gas_used,
                        "gas_price_gwei": cost.gas_price_gwei,
                        "total_cost_usd": cost.total_cost_usd,
                        "timestamp": cost.timestamp.isoformat()
                    })
                
                with open("transaction_costs_data.json", 'w') as f:
                    json.dump(costs_data, f, indent=2)
                
                logger.info("Gas savings analysis completed")
            else:
                logger.error("Failed to calculate gas savings")
        else:
            logger.error("Failed to collect gas price data")

if __name__ == "__main__":
    asyncio.run(main())
