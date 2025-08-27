#!/usr/bin/env python3
"""
Polygon Block Data Collector
Collects comprehensive block data from Polygon network
"""

import asyncio
import json
import logging
from typing import Dict, List, Optional, Any, Union
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict
import sys
import os

# Add parent directory to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils.api_client import PolygonAPIClient, APIResponse
from config.quicknode_config import PolygonQuickNodeConfig

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class BlockData:
    """Block data structure"""
    block_number: int
    block_hash: str
    parent_hash: str
    timestamp: int
    gas_limit: int
    gas_used: int
    miner: str
    difficulty: str
    total_difficulty: str
    size: int
    extra_data: str
    nonce: str
    base_fee_per_gas: Optional[str] = None
    transactions_count: int = 0
    transactions: List[Dict] = None
    logs_bloom: Optional[str] = None
    state_root: Optional[str] = None
    receipts_root: Optional[str] = None
    transactions_root: Optional[str] = None
    uncle_hash: Optional[str] = None
    mix_hash: Optional[str] = None
    
    def __post_init__(self):
        if self.transactions is None:
            self.transactions = []

@dataclass
class TransactionData:
    """Transaction data structure"""
    hash: str
    block_number: int
    block_hash: str
    from_address: str
    to_address: Optional[str]
    value: str
    gas: int
    gas_price: str
    nonce: int
    input_data: str
    transaction_index: int
    timestamp: int
    max_fee_per_gas: Optional[str] = None
    max_priority_fee_per_gas: Optional[str] = None
    type: Optional[int] = None
    access_list: Optional[List] = None
    chain_id: Optional[int] = None

@dataclass
class TransactionReceiptData:
    """Transaction receipt data structure"""
    transaction_hash: str
    block_number: int
    block_hash: str
    transaction_index: int
    from_address: str
    to_address: Optional[str]
    cumulative_gas_used: int
    gas_used: int
    contract_address: Optional[str]
    logs: List[Dict]
    status: int
    effective_gas_price: str
    type: Optional[int] = None
    logs_bloom: Optional[str] = None
    root: Optional[str] = None

class PolygonBlockCollector:
    """Comprehensive block data collector for Polygon network"""
    
    def __init__(self, config: PolygonQuickNodeConfig, network: str = "polygon_mainnet"):
        self.config = config
        self.network = network
        self.endpoint = config.get_endpoint(network)
        self.client = PolygonAPIClient(self.endpoint.http_url)
        self.collection_config = config.get_collection_config()
        
    async def initialize(self):
        """Initialize the collector"""
        await self.client.create_session()
        logger.info(f"Initialized Polygon block collector for {self.network}")
    
    async def cleanup(self):
        """Cleanup resources"""
        await self.client.close_session()
        logger.info("Cleaned up Polygon block collector")
    
    async def get_current_block_number(self) -> int:
        """Get current block number"""
        response = await self.client.get_block_number()
        if response.success:
            return self.client.hex_to_int(response.data)
        else:
            raise Exception(f"Failed to get block number: {response.error}")
    
    async def collect_block_data(self, block_number: Union[int, str]) -> Optional[BlockData]:
        """Collect comprehensive block data"""
        try:
            # Get block with full transaction details
            response = await self.client.get_block_by_number(block_number, full_transactions=True)
            
            if not response.success:
                logger.error(f"Failed to get block {block_number}: {response.error}")
                return None
            
            block_data = response.data
            if not block_data:
                logger.warning(f"Block {block_number} not found")
                return None
            
            # Parse block data
            block = BlockData(
                block_number=self.client.hex_to_int(block_data["number"]),
                block_hash=block_data["hash"],
                parent_hash=block_data["parentHash"],
                timestamp=self.client.hex_to_int(block_data["timestamp"]),
                gas_limit=self.client.hex_to_int(block_data["gasLimit"]),
                gas_used=self.client.hex_to_int(block_data["gasUsed"]),
                miner=block_data["miner"],
                difficulty=block_data["difficulty"],
                total_difficulty=block_data["totalDifficulty"],
                size=self.client.hex_to_int(block_data["size"]),
                extra_data=block_data["extraData"],
                nonce=block_data["nonce"],
                base_fee_per_gas=block_data.get("baseFeePerGas"),
                transactions_count=len(block_data.get("transactions", [])),
                logs_bloom=block_data.get("logsBloom"),
                state_root=block_data.get("stateRoot"),
                receipts_root=block_data.get("receiptsRoot"),
                transactions_root=block_data.get("transactionsRoot"),
                uncle_hash=block_data.get("sha3Uncles"),
                mix_hash=block_data.get("mixHash")
            )
            
            # Parse transactions
            transactions = []
            for tx_data in block_data.get("transactions", []):
                tx = TransactionData(
                    hash=tx_data["hash"],
                    block_number=block.block_number,
                    block_hash=block.block_hash,
                    from_address=tx_data["from"],
                    to_address=tx_data.get("to"),
                    value=tx_data["value"],
                    gas=self.client.hex_to_int(tx_data["gas"]),
                    gas_price=tx_data["gasPrice"],
                    nonce=self.client.hex_to_int(tx_data["nonce"]),
                    input_data=tx_data["input"],
                    transaction_index=self.client.hex_to_int(tx_data["transactionIndex"]),
                    timestamp=block.timestamp,
                    max_fee_per_gas=tx_data.get("maxFeePerGas"),
                    max_priority_fee_per_gas=tx_data.get("maxPriorityFeePerGas"),
                    type=tx_data.get("type"),
                    access_list=tx_data.get("accessList"),
                    chain_id=tx_data.get("chainId")
                )
                transactions.append(tx)
            
            block.transactions = transactions
            
            logger.info(f"Collected block {block.block_number} with {len(transactions)} transactions")
            return block
            
        except Exception as e:
            logger.error(f"Error collecting block {block_number}: {e}")
            return None
    
    async def collect_transaction_receipts(self, transactions: List[TransactionData]) -> List[TransactionReceiptData]:
        """Collect transaction receipts for a list of transactions"""
        receipts = []
        
        # Process in batches
        batch_size = self.collection_config.batch_size
        for i in range(0, len(transactions), batch_size):
            batch = transactions[i:i + batch_size]
            
            # Create batch requests
            requests = []
            for tx in batch:
                requests.append({
                    "method": "eth_getTransactionReceipt",
                    "params": [tx.hash],
                    "request_id": tx.hash
                })
            
            # Make batch request
            responses = await self.client.batch_request(requests)
            
            # Parse responses
            for j, response in enumerate(responses):
                if response.success and response.data:
                    receipt_data = response.data
                    tx = batch[j]
                    
                    receipt = TransactionReceiptData(
                        transaction_hash=tx.hash,
                        block_number=tx.block_number,
                        block_hash=tx.block_hash,
                        transaction_index=tx.transaction_index,
                        from_address=receipt_data["from"],
                        to_address=receipt_data.get("to"),
                        cumulative_gas_used=self.client.hex_to_int(receipt_data["cumulativeGasUsed"]),
                        gas_used=self.client.hex_to_int(receipt_data["gasUsed"]),
                        contract_address=receipt_data.get("contractAddress"),
                        logs=receipt_data.get("logs", []),
                        status=self.client.hex_to_int(receipt_data["status"]),
                        effective_gas_price=receipt_data["effectiveGasPrice"],
                        type=receipt_data.get("type"),
                        logs_bloom=receipt_data.get("logsBloom"),
                        root=receipt_data.get("root")
                    )
                    receipts.append(receipt)
                else:
                    logger.warning(f"Failed to get receipt for {batch[j].hash}: {response.error}")
            
            # Rate limiting between batches
            if i + batch_size < len(transactions):
                await asyncio.sleep(0.1)
        
        logger.info(f"Collected {len(receipts)} transaction receipts")
        return receipts
    
    async def collect_block_range(self, start_block: int, end_block: int) -> Dict[str, Any]:
        """Collect data for a range of blocks"""
        results = {
            "blocks": [],
            "transactions": [],
            "receipts": [],
            "start_block": start_block,
            "end_block": end_block,
            "total_blocks": 0,
            "total_transactions": 0,
            "total_receipts": 0,
            "errors": []
        }
        
        logger.info(f"Starting collection for blocks {start_block} to {end_block}")
        
        for block_number in range(start_block, end_block + 1):
            try:
                # Collect block data
                block = await self.collect_block_data(block_number)
                if block:
                    results["blocks"].append(asdict(block))
                    results["total_blocks"] += 1
                    
                    # Collect transaction receipts
                    if block.transactions:
                        receipts = await self.collect_transaction_receipts(block.transactions)
                        results["receipts"].extend([asdict(receipt) for receipt in receipts])
                        results["total_receipts"] += len(receipts)
                    
                    results["total_transactions"] += len(block.transactions)
                    
                    # Progress logging
                    if block_number % 100 == 0:
                        logger.info(f"Processed {block_number - start_block + 1} blocks")
                
                # Rate limiting
                await asyncio.sleep(0.05)
                
            except Exception as e:
                error_msg = f"Error processing block {block_number}: {e}"
                logger.error(error_msg)
                results["errors"].append(error_msg)
        
        logger.info(f"Completed collection: {results['total_blocks']} blocks, "
                   f"{results['total_transactions']} transactions, "
                   f"{results['total_receipts']} receipts")
        
        return results
    
    async def collect_recent_blocks(self, num_blocks: int = 100) -> Dict[str, Any]:
        """Collect data for recent blocks"""
        current_block = await self.get_current_block_number()
        start_block = max(0, current_block - num_blocks + 1)
        
        logger.info(f"Collecting {num_blocks} recent blocks from {start_block} to {current_block}")
        return await self.collect_block_range(start_block, current_block)
    
    async def collect_blocks_by_time_range(self, start_time: datetime, end_time: datetime) -> Dict[str, Any]:
        """Collect blocks within a time range"""
        # This is a simplified implementation
        # In practice, you'd need to estimate block numbers from timestamps
        # or use a more sophisticated approach
        
        current_block = await self.get_current_block_number()
        estimated_blocks_per_hour = 1800  # ~2 second block time
        
        start_timestamp = int(start_time.timestamp())
        end_timestamp = int(end_time.timestamp())
        
        # Rough estimation
        hours_diff = (end_timestamp - start_timestamp) / 3600
        estimated_blocks = int(hours_diff * estimated_blocks_per_hour)
        
        start_block = max(0, current_block - estimated_blocks)
        
        logger.info(f"Collecting blocks from {start_time} to {end_time} "
                   f"(estimated {estimated_blocks} blocks)")
        
        return await self.collect_block_range(start_block, current_block)
    
    def save_to_file(self, data: Dict[str, Any], filename: str):
        """Save collected data to JSON file"""
        try:
            with open(filename, 'w') as f:
                json.dump(data, f, indent=2, default=str)
            logger.info(f"Saved data to {filename}")
        except Exception as e:
            logger.error(f"Error saving data to {filename}: {e}")

# Example usage
async def main():
    """Example usage of Polygon block collector"""
    
    # Initialize configuration
    config = PolygonQuickNodeConfig(
        endpoint_name="your-endpoint-name",
        token_id="your-token-id"
    )
    
    # Initialize collector
    collector = PolygonBlockCollector(config, "polygon_mainnet")
    
    try:
        await collector.initialize()
        
        # Get current block number
        current_block = await collector.get_current_block_number()
        print(f"Current block: {current_block}")
        
        # Collect recent blocks
        print("Collecting recent blocks...")
        recent_data = await collector.collect_recent_blocks(10)
        
        # Save data
        collector.save_to_file(recent_data, "recent_blocks.json")
        
        print(f"Collected {recent_data['total_blocks']} blocks")
        print(f"Collected {recent_data['total_transactions']} transactions")
        print(f"Collected {recent_data['total_receipts']} receipts")
        
    finally:
        await collector.cleanup()

if __name__ == "__main__":
    asyncio.run(main())
