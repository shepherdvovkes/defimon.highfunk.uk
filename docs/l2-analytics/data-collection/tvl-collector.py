#!/usr/bin/env python3
"""
TVL Data Collector for L2 Analytics

This module collects Total Value Locked (TVL) data from various L2 protocols
and external APIs to calculate growth rates and other TVL-related metrics.
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
class TVLData:
    """Data structure for TVL information"""
    protocol: str
    chain: str
    tvl: float
    timestamp: datetime
    currency: str = "USD"
    source: str = "defillama"

@dataclass
class TVLGrowthMetrics:
    """Calculated TVL growth metrics"""
    protocol: str
    current_tvl: float
    previous_tvl: float
    growth_rate: float
    compound_growth_rate: float
    absolute_change: float
    period_days: int
    timestamp: datetime

class TVLCollector:
    """Collects TVL data from various sources"""
    
    def __init__(self):
        self.session: Optional[aiohttp.ClientSession] = None
        self.base_urls = {
            "defillama": "https://api.llama.fi",
            "defipulse": "https://api.defipulse.com/v1/defipulse/api",
            "l2beat": "https://api.l2beat.com"
        }
        
        # L2 Protocols to track
        self.l2_protocols = {
            "arbitrum": {
                "name": "Arbitrum One",
                "chain_id": 42161,
                "defillama_id": "arbitrum"
            },
            "optimism": {
                "name": "Optimism",
                "chain_id": 10,
                "defillama_id": "optimism"
            },
            "polygon": {
                "name": "Polygon",
                "chain_id": 137,
                "defillama_id": "polygon"
            },
            "base": {
                "name": "Base",
                "chain_id": 8453,
                "defillama_id": "base"
            },
            "zksync": {
                "name": "zkSync Era",
                "chain_id": 324,
                "defillama_id": "zksync-era"
            },
            "starknet": {
                "name": "Starknet",
                "chain_id": 0x534e5f474f45524c49,  # SN_GOERLI
                "defillama_id": "starknet"
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

    async def get_defillama_tvl(self, protocol_id: str) -> Optional[float]:
        """Get TVL from DeFiLlama API"""
        try:
            url = f"{self.base_urls['defillama']}/protocols"
            async with self.session.get(url) as response:
                if response.status == 200:
                    data = await response.json()
                    
                    # Find protocol by ID
                    for protocol in data:
                        if protocol.get("slug") == protocol_id:
                            return float(protocol.get("tvl", 0))
                    
                    logger.warning(f"Protocol {protocol_id} not found in DeFiLlama")
                    return None
                else:
                    logger.error(f"DeFiLlama API error: {response.status}")
                    return None
                    
        except Exception as e:
            logger.error(f"Error fetching DeFiLlama TVL for {protocol_id}: {e}")
            return None

    async def get_l2beat_tvl(self, chain_id: int) -> Optional[float]:
        """Get TVL from L2Beat API"""
        try:
            url = f"{self.base_urls['l2beat']}/api/tvl"
            async with self.session.get(url) as response:
                if response.status == 200:
                    data = await response.json()
                    
                    # Find chain by ID
                    for chain in data.get("chains", []):
                        if chain.get("id") == chain_id:
                            return float(chain.get("tvl", 0))
                    
                    logger.warning(f"Chain {chain_id} not found in L2Beat")
                    return None
                else:
                    logger.error(f"L2Beat API error: {response.status}")
                    return None
                    
        except Exception as e:
            logger.error(f"Error fetching L2Beat TVL for chain {chain_id}: {e}")
            return None

    async def collect_all_tvl(self) -> List[TVLData]:
        """Collect TVL data from all sources for all protocols"""
        tvl_data = []
        timestamp = datetime.now()
        
        for protocol_key, protocol_info in self.l2_protocols.items():
            logger.info(f"Collecting TVL for {protocol_info['name']}")
            
            # Try DeFiLlama first
            defillama_tvl = await self.get_defillama_tvl(protocol_info['defillama_id'])
            
            if defillama_tvl is not None:
                tvl_data.append(TVLData(
                    protocol=protocol_key,
                    chain=protocol_info['name'],
                    tvl=defillama_tvl,
                    timestamp=timestamp,
                    source="defillama"
                ))
                logger.info(f"DeFiLlama TVL for {protocol_info['name']}: ${defillama_tvl:,.2f}")
            
            # Try L2Beat as backup
            else:
                l2beat_tvl = await self.get_l2beat_tvl(protocol_info['chain_id'])
                if l2beat_tvl is not None:
                    tvl_data.append(TVLData(
                        protocol=protocol_key,
                        chain=protocol_info['name'],
                        tvl=l2beat_tvl,
                        timestamp=timestamp,
                        source="l2beat"
                    ))
                    logger.info(f"L2Beat TVL for {protocol_info['name']}: ${l2beat_tvl:,.2f}")
        
        return tvl_data

    def calculate_growth_metrics(self, current_data: List[TVLData], 
                                historical_data: List[TVLData], 
                                period_days: int = 30) -> List[TVLGrowthMetrics]:
        """Calculate TVL growth metrics"""
        growth_metrics = []
        
        # Convert to DataFrame for easier processing
        current_df = pd.DataFrame([
            {
                'protocol': d.protocol,
                'tvl': d.tvl,
                'timestamp': d.timestamp
            } for d in current_data
        ])
        
        historical_df = pd.DataFrame([
            {
                'protocol': d.protocol,
                'tvl': d.tvl,
                'timestamp': d.timestamp
            } for d in historical_data
        ])
        
        for protocol in current_df['protocol'].unique():
            current_tvl = current_df[current_df['protocol'] == protocol]['tvl'].iloc[0]
            
            # Find historical data for this protocol
            protocol_historical = historical_df[
                (historical_df['protocol'] == protocol) & 
                (historical_df['timestamp'] <= current_df['timestamp'].iloc[0] - timedelta(days=period_days))
            ]
            
            if not protocol_historical.empty:
                previous_tvl = protocol_historical['tvl'].iloc[-1]  # Most recent historical data
                
                # Calculate metrics
                absolute_change = current_tvl - previous_tvl
                growth_rate = ((current_tvl - previous_tvl) / previous_tvl) * 100 if previous_tvl > 0 else 0
                
                # Compound growth rate (assuming daily compounding)
                compound_growth_rate = ((current_tvl / previous_tvl) ** (1/period_days) - 1) * 100 if previous_tvl > 0 else 0
                
                growth_metrics.append(TVLGrowthMetrics(
                    protocol=protocol,
                    current_tvl=current_tvl,
                    previous_tvl=previous_tvl,
                    growth_rate=growth_rate,
                    compound_growth_rate=compound_growth_rate,
                    absolute_change=absolute_change,
                    period_days=period_days,
                    timestamp=datetime.now()
                ))
                
                logger.info(f"Growth metrics for {protocol}: {growth_rate:.2f}% over {period_days} days")
        
        return growth_metrics

    async def save_tvl_data(self, tvl_data: List[TVLData], filename: str = None):
        """Save TVL data to JSON file"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"tvl_data_{timestamp}.json"
        
        data_to_save = []
        for data in tvl_data:
            data_to_save.append({
                "protocol": data.protocol,
                "chain": data.chain,
                "tvl": data.tvl,
                "timestamp": data.timestamp.isoformat(),
                "currency": data.currency,
                "source": data.source
            })
        
        try:
            with open(filename, 'w') as f:
                json.dump(data_to_save, f, indent=2)
            logger.info(f"TVL data saved to {filename}")
        except Exception as e:
            logger.error(f"Error saving TVL data: {e}")

    async def load_historical_data(self, filename: str) -> List[TVLData]:
        """Load historical TVL data from JSON file"""
        try:
            with open(filename, 'r') as f:
                data = json.load(f)
            
            historical_data = []
            for item in data:
                historical_data.append(TVLData(
                    protocol=item['protocol'],
                    chain=item['chain'],
                    tvl=item['tvl'],
                    timestamp=datetime.fromisoformat(item['timestamp']),
                    currency=item.get('currency', 'USD'),
                    source=item.get('source', 'unknown')
                ))
            
            logger.info(f"Loaded {len(historical_data)} historical TVL records")
            return historical_data
            
        except FileNotFoundError:
            logger.warning(f"Historical data file {filename} not found")
            return []
        except Exception as e:
            logger.error(f"Error loading historical data: {e}")
            return []

async def main():
    """Main function for testing the TVL collector"""
    async with TVLCollector() as collector:
        logger.info("Starting TVL data collection...")
        
        # Collect current TVL data
        current_tvl = await collector.collect_all_tvl()
        
        if current_tvl:
            # Save current data
            await collector.save_tvl_data(current_tvl)
            
            # Load historical data (if available)
            historical_data = await collector.load_historical_data("tvl_data_historical.json")
            
            if historical_data:
                # Calculate growth metrics
                growth_metrics = collector.calculate_growth_metrics(
                    current_tvl, historical_data, period_days=30
                )
                
                # Save growth metrics
                growth_data = []
                for metric in growth_metrics:
                    growth_data.append({
                        "protocol": metric.protocol,
                        "current_tvl": metric.current_tvl,
                        "previous_tvl": metric.previous_tvl,
                        "growth_rate": metric.growth_rate,
                        "compound_growth_rate": metric.compound_growth_rate,
                        "absolute_change": metric.absolute_change,
                        "period_days": metric.period_days,
                        "timestamp": metric.timestamp.isoformat()
                    })
                
                with open("tvl_growth_metrics.json", 'w') as f:
                    json.dump(growth_data, f, indent=2)
                
                logger.info("TVL growth metrics calculated and saved")
            else:
                logger.info("No historical data available for growth calculation")
        else:
            logger.error("Failed to collect TVL data")

if __name__ == "__main__":
    asyncio.run(main())
