#!/usr/bin/env python3
"""
Data Collector for ML Learning Pipeline
Uses QuickNode API to collect blockchain data for the 5 popular questions
Optimized for Apple M4 Neural Engine processing
"""

import asyncio
import aiohttp
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
import pandas as pd
import numpy as np
from web3 import Web3
from web3.middleware import geth_poa_middleware
import redis
import structlog

from config import config, NETWORK_CONFIGS, DEFI_PROTOCOLS

# Configure logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

class QuickNodeDataCollector:
    """Data collector using QuickNode API with M4 optimization"""
    
    def __init__(self):
        self.quicknode_config = config.quicknode
        self.redis_client = redis.from_url(config.redis_url)
        self.session = None
        self.w3_instances = {}
        
        # Initialize Web3 instances for each network
        self._setup_web3_instances()
        
        # Data storage
        self.collected_data = {
            "price_data": {},
            "gas_data": {},
            "defi_data": {},
            "network_data": {},
            "contract_data": {}
        }
    
    def _setup_web3_instances(self):
        """Setup Web3 instances for each network"""
        for network, network_config in NETWORK_CONFIGS.items():
            if network == "ethereum":
                url = self.quicknode_config.http_url
            else:
                url = f"https://{self.quicknode_config.endpoint_name}.{network}.quiknode.pro/{self.quicknode_config.token_id}/"
            
            w3 = Web3(Web3.HTTPProvider(url))
            
            # Add POA middleware for non-Ethereum networks
            if network != "ethereum":
                w3.middleware_onion.inject(geth_poa_middleware, layer=0)
            
            self.w3_instances[network] = w3
            logger.info(f"Initialized Web3 for {network}", url=url)
    
    async def __aenter__(self):
        """Async context manager entry"""
        self.session = aiohttp.ClientSession(
            timeout=aiohttp.ClientTimeout(total=self.quicknode_config.timeout),
            headers={"Content-Type": "application/json"}
        )
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        if self.session:
            await self.session.close()
    
    async def _make_rpc_request(self, network: str, method: str, params: List = None) -> Dict:
        """Make RPC request to QuickNode"""
        if network == "ethereum":
            url = self.quicknode_config.http_url
        else:
            url = f"https://{self.quicknode_config.endpoint_name}.{network}.quiknode.pro/{self.quicknode_config.token_id}/"
        
        payload = {
            "jsonrpc": "2.0",
            "method": method,
            "params": params or [],
            "id": 1
        }
        
        try:
            async with self.session.post(url, json=payload) as response:
                if response.status == 200:
                    result = await response.json()
                    return result.get("result")
                else:
                    logger.error(f"RPC request failed", network=network, method=method, status=response.status)
                    return None
        except Exception as e:
            logger.error(f"RPC request error", network=network, method=method, error=str(e))
            return None
    
    async def collect_price_data(self, network: str = "ethereum") -> Dict:
        """Collect price and market data for prediction models"""
        logger.info("Collecting price data", network=network)
        
        # Get latest block
        latest_block = await self._make_rpc_request(network, "eth_blockNumber")
        if not latest_block:
            return {}
        
        block_number = int(latest_block, 16)
        
        # Get block data
        block_data = await self._make_rpc_request(network, "eth_getBlockByNumber", [hex(block_number), True])
        if not block_data:
            return {}
        
        # Get gas price
        gas_price = await self._make_rpc_request(network, "eth_gasPrice")
        
        # Get network metrics
        network_data = {
            "block_number": block_number,
            "timestamp": int(block_data.get("timestamp", "0"), 16),
            "gas_price": int(gas_price, 16) if gas_price else 0,
            "transaction_count": len(block_data.get("transactions", [])),
            "block_size": len(json.dumps(block_data)),
            "network": network,
            "currency": NETWORK_CONFIGS[network]["currency"]
        }
        
        # Store in Redis for caching
        cache_key = f"price_data:{network}:{block_number}"
        self.redis_client.setex(cache_key, 300, json.dumps(network_data))  # 5 minutes cache
        
        return network_data
    
    async def collect_gas_data(self, network: str = "ethereum") -> Dict:
        """Collect gas price data for optimization models"""
        logger.info("Collecting gas data", network=network)
        
        # Get current gas price
        gas_price = await self._make_rpc_request(network, "eth_gasPrice")
        
        # Get gas price history (last 100 blocks)
        gas_history = []
        latest_block = await self._make_rpc_request(network, "eth_blockNumber")
        if latest_block:
            current_block = int(latest_block, 16)
            
            for i in range(100):
                block_number = current_block - i
                if block_number < 0:
                    break
                
                block_data = await self._make_rpc_request(
                    network, 
                    "eth_getBlockByNumber", 
                    [hex(block_number), False]
                )
                
                if block_data:
                    gas_history.append({
                        "block_number": block_number,
                        "gas_used": int(block_data.get("gasUsed", "0"), 16),
                        "gas_limit": int(block_data.get("gasLimit", "0"), 16),
                        "timestamp": int(block_data.get("timestamp", "0"), 16)
                    })
        
        # Get mempool data (pending transactions)
        pending_txs = await self._make_rpc_request(network, "txpool_status")
        
        gas_data = {
            "current_gas_price": int(gas_price, 16) if gas_price else 0,
            "gas_history": gas_history,
            "pending_transactions": pending_txs.get("pending", 0) if pending_txs else 0,
            "queued_transactions": pending_txs.get("queued", 0) if pending_txs else 0,
            "network": network,
            "timestamp": datetime.now().isoformat()
        }
        
        # Store in Redis
        cache_key = f"gas_data:{network}"
        self.redis_client.setex(cache_key, 60, json.dumps(gas_data))  # 1 minute cache
        
        return gas_data
    
    async def collect_defi_data(self, protocol: str = "uniswap_v3") -> Dict:
        """Collect DeFi protocol data for risk assessment"""
        logger.info("Collecting DeFi data", protocol=protocol)
        
        if protocol not in DEFI_PROTOCOLS:
            logger.error(f"Unknown protocol", protocol=protocol)
            return {}
        
        protocol_config = DEFI_PROTOCOLS[protocol]
        contract_address = protocol_config["address"]
        
        # Get contract data
        contract_code = await self._make_rpc_request("ethereum", "eth_getCode", [contract_address, "latest"])
        
        # Get contract balance
        contract_balance = await self._make_rpc_request("ethereum", "eth_getBalance", [contract_address, "latest"])
        
        # Get recent transactions involving the contract
        latest_block = await self._make_rpc_request("ethereum", "eth_blockNumber")
        if latest_block:
            current_block = int(latest_block, 16)
            
            # Get last 10 blocks for contract interactions
            contract_txs = []
            for i in range(10):
                block_number = current_block - i
                if block_number < 0:
                    break
                
                block_data = await self._make_rpc_request(
                    "ethereum",
                    "eth_getBlockByNumber",
                    [hex(block_number), True]
                )
                
                if block_data:
                    for tx in block_data.get("transactions", []):
                        if tx.get("to", "").lower() == contract_address.lower():
                            contract_txs.append({
                                "hash": tx.get("hash"),
                                "from": tx.get("from"),
                                "value": int(tx.get("value", "0"), 16),
                                "gas_price": int(tx.get("gasPrice", "0"), 16),
                                "gas_used": int(tx.get("gas", "0"), 16)
                            })
        
        defi_data = {
            "protocol": protocol,
            "contract_address": contract_address,
            "category": protocol_config["category"],
            "risk_factors": protocol_config["risk_factors"],
            "contract_code_size": len(contract_code) if contract_code else 0,
            "contract_balance": int(contract_balance, 16) if contract_balance else 0,
            "recent_transactions": contract_txs,
            "transaction_count": len(contract_txs),
            "timestamp": datetime.now().isoformat()
        }
        
        # Store in Redis
        cache_key = f"defi_data:{protocol}"
        self.redis_client.setex(cache_key, 300, json.dumps(defi_data))  # 5 minutes cache
        
        return defi_data
    
    async def collect_network_congestion_data(self, network: str = "ethereum") -> Dict:
        """Collect network congestion data for prediction models"""
        logger.info("Collecting network congestion data", network=network)
        
        # Get current network status
        latest_block = await self._make_rpc_request(network, "eth_blockNumber")
        if not latest_block:
            return {}
        
        current_block = int(latest_block, 16)
        
        # Get block time data (last 100 blocks)
        block_times = []
        for i in range(100):
            block_number = current_block - i
            if block_number < 0:
                break
            
            block_data = await self._make_rpc_request(
                network,
                "eth_getBlockByNumber",
                [hex(block_number), False]
            )
            
            if block_data:
                block_times.append({
                    "block_number": block_number,
                    "timestamp": int(block_data.get("timestamp", "0"), 16),
                    "gas_used": int(block_data.get("gasUsed", "0"), 16),
                    "gas_limit": int(block_data.get("gasLimit", "0"), 16)
                })
        
        # Calculate congestion metrics
        if len(block_times) >= 2:
            avg_block_time = np.mean([
                block_times[i]["timestamp"] - block_times[i+1]["timestamp"]
                for i in range(len(block_times) - 1)
            ])
            
            avg_gas_usage = np.mean([b["gas_used"] for b in block_times])
            avg_gas_limit = np.mean([b["gas_limit"] for b in block_times])
            gas_utilization = avg_gas_usage / avg_gas_limit if avg_gas_limit > 0 else 0
        else:
            avg_block_time = 0
            gas_utilization = 0
        
        # Get mempool status
        mempool_status = await self._make_rpc_request(network, "txpool_status")
        
        congestion_data = {
            "network": network,
            "current_block": current_block,
            "avg_block_time": avg_block_time,
            "gas_utilization": gas_utilization,
            "pending_transactions": mempool_status.get("pending", 0) if mempool_status else 0,
            "queued_transactions": mempool_status.get("queued", 0) if mempool_status else 0,
            "block_times": block_times,
            "timestamp": datetime.now().isoformat()
        }
        
        # Store in Redis
        cache_key = f"congestion_data:{network}"
        self.redis_client.setex(cache_key, 120, json.dumps(congestion_data))  # 2 minutes cache
        
        return congestion_data
    
    async def collect_smart_contract_data(self, contract_address: str) -> Dict:
        """Collect smart contract data for security analysis"""
        logger.info("Collecting smart contract data", contract_address=contract_address)
        
        # Get contract code
        contract_code = await self._make_rpc_request("ethereum", "eth_getCode", [contract_address, "latest"])
        
        # Get contract balance
        contract_balance = await self._make_rpc_request("ethereum", "eth_getBalance", [contract_address, "latest"])
        
        # Get recent transactions
        latest_block = await self._make_rpc_request("ethereum", "eth_blockNumber")
        if not latest_block:
            return {}
        
        current_block = int(latest_block, 16)
        
        # Get last 50 transactions involving the contract
        contract_txs = []
        for i in range(50):
            block_number = current_block - i
            if block_number < 0:
                break
            
            block_data = await self._make_rpc_request(
                "ethereum",
                "eth_getBlockByNumber",
                [hex(block_number), True]
            )
            
            if block_data:
                for tx in block_data.get("transactions", []):
                    if (tx.get("to", "").lower() == contract_address.lower() or
                        tx.get("from", "").lower() == contract_address.lower()):
                        contract_txs.append({
                            "hash": tx.get("hash"),
                            "from": tx.get("from"),
                            "to": tx.get("to"),
                            "value": int(tx.get("value", "0"), 16),
                            "gas_price": int(tx.get("gasPrice", "0"), 16),
                            "gas_used": int(tx.get("gas", "0"), 16),
                            "block_number": block_number
                        })
        
        # Basic security analysis
        security_metrics = {
            "code_size": len(contract_code) if contract_code else 0,
            "has_code": bool(contract_code and contract_code != "0x"),
            "balance": int(contract_balance, 16) if contract_balance else 0,
            "transaction_count": len(contract_txs),
            "unique_interactors": len(set([tx["from"] for tx in contract_txs] + [tx["to"] for tx in contract_txs if tx["to"]])),
            "avg_transaction_value": np.mean([tx["value"] for tx in contract_txs]) if contract_txs else 0,
            "max_transaction_value": max([tx["value"] for tx in contract_txs]) if contract_txs else 0
        }
        
        contract_data = {
            "contract_address": contract_address,
            "contract_code": contract_code,
            "security_metrics": security_metrics,
            "recent_transactions": contract_txs,
            "timestamp": datetime.now().isoformat()
        }
        
        # Store in Redis
        cache_key = f"contract_data:{contract_address}"
        self.redis_client.setex(cache_key, 600, json.dumps(contract_data))  # 10 minutes cache
        
        return contract_data
    
    async def collect_all_data(self) -> Dict:
        """Collect all data for the 5 popular questions"""
        logger.info("Starting comprehensive data collection")
        
        all_data = {
            "price_data": {},
            "gas_data": {},
            "defi_data": {},
            "network_data": {},
            "contract_data": {}
        }
        
        # Collect price data for all networks
        for network in config.networks:
            try:
                all_data["price_data"][network] = await self.collect_price_data(network)
                all_data["gas_data"][network] = await self.collect_gas_data(network)
                all_data["network_data"][network] = await self.collect_network_congestion_data(network)
            except Exception as e:
                logger.error(f"Error collecting data for {network}", error=str(e))
        
        # Collect DeFi data for all protocols
        for protocol in DEFI_PROTOCOLS.keys():
            try:
                all_data["defi_data"][protocol] = await self.collect_defi_data(protocol)
            except Exception as e:
                logger.error(f"Error collecting DeFi data for {protocol}", error=str(e))
        
        # Collect contract data for major protocols
        for protocol, protocol_config in DEFI_PROTOCOLS.items():
            try:
                all_data["contract_data"][protocol] = await self.collect_smart_contract_data(
                    protocol_config["address"]
                )
            except Exception as e:
                logger.error(f"Error collecting contract data for {protocol}", error=str(e))
        
        # Store comprehensive data in Redis
        self.redis_client.setex(
            "ml_pipeline_data",
            300,  # 5 minutes cache
            json.dumps(all_data)
        )
        
        logger.info("Data collection completed", 
                   networks=len(all_data["price_data"]),
                   protocols=len(all_data["defi_data"]))
        
        return all_data

# Example usage
async def main():
    """Example usage of the data collector"""
    async with QuickNodeDataCollector() as collector:
        # Collect all data
        data = await collector.collect_all_data()
        
        # Print summary
        print(f"Collected data for {len(data['price_data'])} networks")
        print(f"Collected data for {len(data['defi_data'])} protocols")
        print(f"Data timestamp: {datetime.now().isoformat()}")

if __name__ == "__main__":
    asyncio.run(main())
