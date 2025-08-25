#!/usr/bin/env python3
"""
User Activity Data Collector for L2 Analytics

This module collects daily active users (DAU) data from various L2 protocols
by analyzing transaction logs and user interactions.
"""

import asyncio
import aiohttp
import logging
import json
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Set
from dataclasses import dataclass
import pandas as pd
from collections import defaultdict

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class UserActivityData:
    """Data structure for user activity information"""
    protocol: str
    chain: str
    date: str
    dau: int  # Daily Active Users
    wau: int  # Weekly Active Users
    mau: int  # Monthly Active Users
    new_users: int
    returning_users: int
    total_transactions: int
    unique_addresses: Set[str]
    timestamp: datetime

@dataclass
class UserRetentionMetrics:
    """Calculated user retention metrics"""
    protocol: str
    date: str
    retention_1d: float
    retention_7d: float
    retention_30d: float
    churn_rate: float
    user_growth_rate: float
    timestamp: datetime

class UserActivityCollector:
    """Collects user activity data from various sources"""
    
    def __init__(self):
        self.session: Optional[aiohttp.ClientSession] = None
        
        # RPC endpoints for different L2 protocols
        self.rpc_endpoints = {
            "arbitrum": "https://arb1.arbitrum.io/rpc",
            "optimism": "https://mainnet.optimism.io",
            "polygon": "https://polygon-rpc.com",
            "base": "https://mainnet.base.org",
            "zksync": "https://mainnet.era.zksync.io",
            "starknet": "https://alpha-mainnet.starknet.io"
        }
        
        # Etherscan API keys (you'll need to add your own)
        self.etherscan_api_key = "YOUR_ETHERSCAN_API_KEY"
        
        # L2 Protocol configurations
        self.l2_protocols = {
            "arbitrum": {
                "name": "Arbitrum One",
                "chain_id": 42161,
                "explorer": "https://arbiscan.io",
                "api_url": "https://api.arbiscan.io/api"
            },
            "optimism": {
                "name": "Optimism",
                "chain_id": 10,
                "explorer": "https://optimistic.etherscan.io",
                "api_url": "https://api-optimistic.etherscan.io/api"
            },
            "polygon": {
                "name": "Polygon",
                "chain_id": 137,
                "explorer": "https://polygonscan.com",
                "api_url": "https://api.polygonscan.com/api"
            },
            "base": {
                "name": "Base",
                "chain_id": 8453,
                "explorer": "https://basescan.org",
                "api_url": "https://api.basescan.org/api"
            }
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

    async def get_transactions_by_date(self, protocol: str, date: str) -> List[Dict]:
        """Get transactions for a specific date using RPC"""
        try:
            rpc_url = self.rpc_endpoints.get(protocol)
            if not rpc_url:
                logger.error(f"No RPC endpoint found for protocol {protocol}")
                return []
            
            # Calculate block range for the date
            target_date = datetime.strptime(date, "%Y-%m-%d")
            start_timestamp = int(target_date.timestamp())
            end_timestamp = int((target_date + timedelta(days=1)).timestamp())
            
            # Get block numbers for the date range
            start_block = await self.get_block_by_timestamp(protocol, start_timestamp)
            end_block = await self.get_block_by_timestamp(protocol, end_timestamp)
            
            if start_block is None or end_block is None:
                logger.error(f"Could not determine block range for {date}")
                return []
            
            # Get transaction logs for the block range
            transactions = await self.get_transaction_logs(protocol, start_block, end_block)
            return transactions
            
        except Exception as e:
            logger.error(f"Error getting transactions for {protocol} on {date}: {e}")
            return []

    async def get_block_by_timestamp(self, protocol: str, timestamp: int) -> Optional[int]:
        """Get block number by timestamp using RPC"""
        try:
            rpc_url = self.rpc_endpoints.get(protocol)
            if not rpc_url:
                return None
            
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_getBlockByNumber",
                "params": ["latest", False],
                "id": 1
            }
            
            async with self.session.post(rpc_url, json=payload) as response:
                if response.status == 200:
                    data = await response.json()
                    if "result" in data and data["result"]:
                        return int(data["result"]["number"], 16)
            
            return None
            
        except Exception as e:
            logger.error(f"Error getting block by timestamp for {protocol}: {e}")
            return None

    async def get_transaction_logs(self, protocol: str, start_block: int, end_block: int) -> List[Dict]:
        """Get transaction logs for a block range"""
        try:
            rpc_url = self.rpc_endpoints.get(protocol)
            if not rpc_url:
                return []
            
            # Get logs for the block range
            payload = {
                "jsonrpc": "2.0",
                "method": "eth_getLogs",
                "params": [{
                    "fromBlock": hex(start_block),
                    "toBlock": hex(end_block)
                }],
                "id": 1
            }
            
            async with self.session.post(rpc_url, json=payload) as response:
                if response.status == 200:
                    data = await response.json()
                    if "result" in data:
                        return data["result"]
            
            return []
            
        except Exception as e:
            logger.error(f"Error getting transaction logs for {protocol}: {e}")
            return []

    async def get_etherscan_transactions(self, protocol: str, date: str) -> List[Dict]:
        """Get transactions using Etherscan API"""
        try:
            protocol_config = self.l2_protocols.get(protocol)
            if not protocol_config:
                logger.error(f"No configuration found for protocol {protocol}")
                return []
            
            api_url = protocol_config["api_url"]
            
            # Calculate timestamp for the date
            target_date = datetime.strptime(date, "%Y-%m-%d")
            start_timestamp = int(target_date.timestamp())
            end_timestamp = int((target_date + timedelta(days=1)).timestamp())
            
            # Get transactions for the date
            params = {
                "module": "account",
                "action": "txlist",
                "startblock": 0,
                "endblock": 99999999,
                "starttimestamp": start_timestamp,
                "endtimestamp": end_timestamp,
                "sort": "asc",
                "apikey": self.etherscan_api_key
            }
            
            async with self.session.get(api_url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    if data.get("status") == "1" and "result" in data:
                        return data["result"]
                    else:
                        logger.warning(f"Etherscan API error: {data.get('message', 'Unknown error')}")
            
            return []
            
        except Exception as e:
            logger.error(f"Error getting Etherscan transactions for {protocol}: {e}")
            return []

    def extract_unique_addresses(self, transactions: List[Dict]) -> Set[str]:
        """Extract unique addresses from transactions"""
        addresses = set()
        
        for tx in transactions:
            # Extract from address
            if "from" in tx:
                addresses.add(tx["from"].lower())
            
            # Extract to address
            if "to" in tx:
                addresses.add(tx["to"].lower())
            
            # Extract addresses from logs
            if "logs" in tx:
                for log in tx["logs"]:
                    if "address" in log:
                        addresses.add(log["address"].lower())
        
        return addresses

    async def collect_daily_activity(self, protocol: str, date: str) -> Optional[UserActivityData]:
        """Collect daily activity data for a specific protocol and date"""
        try:
            logger.info(f"Collecting daily activity for {protocol} on {date}")
            
            # Try Etherscan API first
            transactions = await self.get_etherscan_transactions(protocol, date)
            
            # Fallback to RPC if Etherscan fails
            if not transactions:
                transactions = await self.get_transactions_by_date(protocol, date)
            
            if not transactions:
                logger.warning(f"No transactions found for {protocol} on {date}")
                return None
            
            # Extract unique addresses
            unique_addresses = self.extract_unique_addresses(transactions)
            
            # Calculate metrics
            dau = len(unique_addresses)
            total_transactions = len(transactions)
            
            # For now, we'll use the same data for WAU and MAU
            # In a real implementation, you'd collect data for the full week/month
            wau = dau  # Placeholder
            mau = dau  # Placeholder
            new_users = dau  # Placeholder - would need historical data
            returning_users = 0  # Placeholder
            
            return UserActivityData(
                protocol=protocol,
                chain=self.l2_protocols.get(protocol, {}).get("name", protocol),
                date=date,
                dau=dau,
                wau=wau,
                mau=mau,
                new_users=new_users,
                returning_users=returning_users,
                total_transactions=total_transactions,
                unique_addresses=unique_addresses,
                timestamp=datetime.now()
            )
            
        except Exception as e:
            logger.error(f"Error collecting daily activity for {protocol}: {e}")
            return None

    async def collect_all_protocols_activity(self, date: str = None) -> List[UserActivityData]:
        """Collect activity data for all protocols"""
        if date is None:
            date = datetime.now().strftime("%Y-%m-%d")
        
        activity_data = []
        
        for protocol in self.l2_protocols.keys():
            data = await self.collect_daily_activity(protocol, date)
            if data:
                activity_data.append(data)
                logger.info(f"Collected activity for {protocol}: {data.dau} DAU, {data.total_transactions} transactions")
        
        return activity_data

    def calculate_retention_metrics(self, current_data: UserActivityData, 
                                  historical_data: List[UserActivityData]) -> Optional[UserRetentionMetrics]:
        """Calculate user retention metrics"""
        try:
            # Find historical data for this protocol
            protocol_historical = [
                d for d in historical_data 
                if d.protocol == current_data.protocol
            ]
            
            if not protocol_historical:
                logger.warning(f"No historical data found for {current_data.protocol}")
                return None
            
            # Calculate retention rates (simplified)
            retention_1d = 0.0  # Would need daily historical data
            retention_7d = 0.0  # Would need weekly historical data
            retention_30d = 0.0  # Would need monthly historical data
            
            # Calculate churn rate
            churn_rate = 0.0  # Would need historical user data
            
            # Calculate user growth rate
            if protocol_historical:
                previous_dau = protocol_historical[-1].dau
                user_growth_rate = ((current_data.dau - previous_dau) / previous_dau) * 100 if previous_dau > 0 else 0
            else:
                user_growth_rate = 0.0
            
            return UserRetentionMetrics(
                protocol=current_data.protocol,
                date=current_data.date,
                retention_1d=retention_1d,
                retention_7d=retention_7d,
                retention_30d=retention_30d,
                churn_rate=churn_rate,
                user_growth_rate=user_growth_rate,
                timestamp=datetime.now()
            )
            
        except Exception as e:
            logger.error(f"Error calculating retention metrics for {current_data.protocol}: {e}")
            return None

    async def save_activity_data(self, activity_data: List[UserActivityData], filename: str = None):
        """Save activity data to JSON file"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"user_activity_data_{timestamp}.json"
        
        data_to_save = []
        for data in activity_data:
            data_to_save.append({
                "protocol": data.protocol,
                "chain": data.chain,
                "date": data.date,
                "dau": data.dau,
                "wau": data.wau,
                "mau": data.mau,
                "new_users": data.new_users,
                "returning_users": data.returning_users,
                "total_transactions": data.total_transactions,
                "unique_addresses": list(data.unique_addresses),
                "timestamp": data.timestamp.isoformat()
            })
        
        try:
            with open(filename, 'w') as f:
                json.dump(data_to_save, f, indent=2)
            logger.info(f"User activity data saved to {filename}")
        except Exception as e:
            logger.error(f"Error saving user activity data: {e}")

    async def load_historical_activity(self, filename: str) -> List[UserActivityData]:
        """Load historical activity data from JSON file"""
        try:
            with open(filename, 'r') as f:
                data = json.load(f)
            
            historical_data = []
            for item in data:
                historical_data.append(UserActivityData(
                    protocol=item['protocol'],
                    chain=item['chain'],
                    date=item['date'],
                    dau=item['dau'],
                    wau=item['wau'],
                    mau=item['mau'],
                    new_users=item['new_users'],
                    returning_users=item['returning_users'],
                    total_transactions=item['total_transactions'],
                    unique_addresses=set(item['unique_addresses']),
                    timestamp=datetime.fromisoformat(item['timestamp'])
                ))
            
            logger.info(f"Loaded {len(historical_data)} historical activity records")
            return historical_data
            
        except FileNotFoundError:
            logger.warning(f"Historical activity file {filename} not found")
            return []
        except Exception as e:
            logger.error(f"Error loading historical activity data: {e}")
            return []

async def main():
    """Main function for testing the user activity collector"""
    async with UserActivityCollector() as collector:
        logger.info("Starting user activity data collection...")
        
        # Collect current activity data
        current_activity = await collector.collect_all_protocols_activity()
        
        if current_activity:
            # Save current data
            await collector.save_activity_data(current_activity)
            
            # Load historical data (if available)
            historical_data = await collector.load_historical_activity("user_activity_historical.json")
            
            if historical_data:
                # Calculate retention metrics
                retention_metrics = []
                for activity in current_activity:
                    metrics = collector.calculate_retention_metrics(activity, historical_data)
                    if metrics:
                        retention_metrics.append(metrics)
                
                # Save retention metrics
                if retention_metrics:
                    metrics_data = []
                    for metric in retention_metrics:
                        metrics_data.append({
                            "protocol": metric.protocol,
                            "date": metric.date,
                            "retention_1d": metric.retention_1d,
                            "retention_7d": metric.retention_7d,
                            "retention_30d": metric.retention_30d,
                            "churn_rate": metric.churn_rate,
                            "user_growth_rate": metric.user_growth_rate,
                            "timestamp": metric.timestamp.isoformat()
                        })
                    
                    with open("user_retention_metrics.json", 'w') as f:
                        json.dump(metrics_data, f, indent=2)
                    
                    logger.info("User retention metrics calculated and saved")
            else:
                logger.info("No historical data available for retention calculation")
        else:
            logger.error("Failed to collect user activity data")

if __name__ == "__main__":
    asyncio.run(main())
