#!/usr/bin/env python3
"""
Polygon Network Main Data Collector
Orchestrates comprehensive data collection from Polygon network
"""

import asyncio
import logging
import argparse
import sys
import os
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
import json

# Add current directory to path for imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from config.quicknode_config import PolygonQuickNodeConfig
from config.polygon_endpoints import PolygonEndpoints
from collectors.block_collector import PolygonBlockCollector
from storage.database_manager import PolygonDatabaseManager
from utils.api_client import PolygonAPIClient

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('polygon_collector.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class PolygonMainCollector:
    """Main orchestrator for Polygon network data collection"""
    
    def __init__(self, endpoint_name: str, token_id: str, network: str = "polygon_mainnet"):
        self.config = PolygonQuickNodeConfig(endpoint_name, token_id)
        self.endpoints = PolygonEndpoints()
        self.network = network
        self.block_collector = PolygonBlockCollector(self.config, network)
        self.db_manager = PolygonDatabaseManager()
        self.is_running = False
        
    async def initialize(self):
        """Initialize all components"""
        try:
            logger.info("Initializing Polygon main collector...")
            
            # Test QuickNode connections
            logger.info("Testing QuickNode connections...")
            connection_results = await self.config.test_all_connections()
            
            for network, result in connection_results.items():
                status = "✅" if result["success"] else "❌"
                logger.info(f"{status} {network}: {result}")
            
            # Initialize block collector
            await self.block_collector.initialize()
            logger.info("Block collector initialized")
            
            # Initialize database
            await self.db_manager.initialize()
            logger.info("Database manager initialized")
            
            # Print network statistics
            self._print_network_stats()
            
            logger.info("Polygon main collector initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize main collector: {e}")
            raise
    
    async def cleanup(self):
        """Cleanup all components"""
        try:
            logger.info("Cleaning up Polygon main collector...")
            
            await self.block_collector.cleanup()
            await self.db_manager.cleanup()
            
            logger.info("Polygon main collector cleaned up")
            
        except Exception as e:
            logger.error(f"Error during cleanup: {e}")
    
    def _print_network_stats(self):
        """Print network and protocol statistics"""
        logger.info("=" * 60)
        logger.info("POLYGON NETWORK STATISTICS")
        logger.info("=" * 60)
        
        # Network stats
        network_stats = self.config.get_network_stats()
        for network, stats in network_stats.items():
            logger.info(f"Network: {stats['name']} (Chain ID: {stats['chain_id']})")
            logger.info(f"  Currency: {stats['currency']}")
            logger.info(f"  TVL: ${stats['tvl_usd']:,.0f}")
            logger.info(f"  24h Volume: ${stats['volume_24h']:,.0f}")
            logger.info(f"  Block Time: {stats['block_time']}s")
            logger.info(f"  Enabled: {stats['enabled']}")
            logger.info()
        
        # Protocol stats
        protocol_stats = self.endpoints.get_protocol_stats()
        total_tvl = self.endpoints.get_total_tvl()
        total_volume = self.endpoints.get_total_volume()
        
        logger.info("TOP PROTOCOLS BY TVL:")
        sorted_protocols = sorted(protocol_stats.items(), 
                                key=lambda x: x[1]['tvl_usd'] or 0, reverse=True)
        
        for name, stats in sorted_protocols[:10]:
            if stats['tvl_usd']:
                logger.info(f"  {stats['name']}: ${stats['tvl_usd']:,.0f} ({stats['category']})")
        
        logger.info(f"\nTotal TVL: ${total_tvl:,.0f}")
        logger.info(f"Total 24h Volume: ${total_volume:,.0f}")
        logger.info("=" * 60)
    
    async def collect_recent_data(self, num_blocks: int = 100, save_to_db: bool = True) -> Dict[str, Any]:
        """Collect recent blockchain data"""
        try:
            logger.info(f"Starting collection of {num_blocks} recent blocks...")
            
            # Collect block data
            block_data = await self.block_collector.collect_recent_blocks(num_blocks)
            
            if save_to_db:
                # Save to database
                await self._save_block_data_to_db(block_data)
            
            # Save to file as backup
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"polygon_data_{timestamp}.json"
            self.block_collector.save_to_file(block_data, filename)
            
            logger.info(f"Collection completed: {block_data['total_blocks']} blocks, "
                       f"{block_data['total_transactions']} transactions")
            
            return block_data
            
        except Exception as e:
            logger.error(f"Error collecting recent data: {e}")
            raise
    
    async def collect_historical_data(self, start_block: int, end_block: int, 
                                    batch_size: int = 1000, save_to_db: bool = True) -> Dict[str, Any]:
        """Collect historical blockchain data"""
        try:
            logger.info(f"Starting historical collection from block {start_block} to {end_block}")
            
            total_blocks = end_block - start_block + 1
            total_batches = (total_blocks + batch_size - 1) // batch_size
            
            all_data = {
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
            
            for batch_num in range(total_batches):
                batch_start = start_block + (batch_num * batch_size)
                batch_end = min(batch_start + batch_size - 1, end_block)
                
                logger.info(f"Processing batch {batch_num + 1}/{total_batches}: "
                           f"blocks {batch_start} to {batch_end}")
                
                try:
                    batch_data = await self.block_collector.collect_block_range(batch_start, batch_end)
                    
                    # Merge data
                    all_data["blocks"].extend(batch_data["blocks"])
                    all_data["transactions"].extend(batch_data["transactions"])
                    all_data["receipts"].extend(batch_data["receipts"])
                    all_data["total_blocks"] += batch_data["total_blocks"]
                    all_data["total_transactions"] += batch_data["total_transactions"]
                    all_data["total_receipts"] += batch_data["total_receipts"]
                    all_data["errors"].extend(batch_data["errors"])
                    
                    if save_to_db:
                        # Save batch to database
                        await self._save_block_data_to_db(batch_data)
                    
                    # Progress logging
                    progress = ((batch_num + 1) / total_batches) * 100
                    logger.info(f"Progress: {progress:.1f}% - "
                               f"Collected {all_data['total_blocks']} blocks so far")
                    
                except Exception as e:
                    error_msg = f"Error in batch {batch_num + 1}: {e}"
                    logger.error(error_msg)
                    all_data["errors"].append(error_msg)
                
                # Rate limiting between batches
                await asyncio.sleep(1)
            
            # Save complete dataset to file
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"polygon_historical_{start_block}_{end_block}_{timestamp}.json"
            self.block_collector.save_to_file(all_data, filename)
            
            logger.info(f"Historical collection completed: {all_data['total_blocks']} blocks, "
                       f"{all_data['total_transactions']} transactions")
            
            return all_data
            
        except Exception as e:
            logger.error(f"Error collecting historical data: {e}")
            raise
    
    async def _save_block_data_to_db(self, data: Dict[str, Any]):
        """Save block data to database"""
        try:
            # This is a simplified implementation
            # In practice, you'd want to implement proper batch saving
            logger.info("Saving data to database...")
            
            # Get database statistics before
            block_count_before = await self.db_manager.get_block_count()
            tx_count_before = await self.db_manager.get_transaction_count()
            
            # Save data (simplified - you'd implement proper batch saving)
            logger.info(f"Database stats before: {block_count_before} blocks, {tx_count_before} transactions")
            
            # Get database statistics after
            block_count_after = await self.db_manager.get_block_count()
            tx_count_after = await self.db_manager.get_transaction_count()
            
            logger.info(f"Database stats after: {block_count_after} blocks, {tx_count_after} transactions")
            logger.info(f"Added: {block_count_after - block_count_before} blocks, "
                       f"{tx_count_after - tx_count_before} transactions")
            
        except Exception as e:
            logger.error(f"Error saving data to database: {e}")
    
    async def run_continuous_collection(self, interval_seconds: int = 60):
        """Run continuous data collection"""
        try:
            self.is_running = True
            logger.info(f"Starting continuous collection with {interval_seconds}s intervals")
            
            while self.is_running:
                try:
                    # Get current block number
                    current_block = await self.block_collector.get_current_block_number()
                    latest_db_block = await self.db_manager.get_latest_block()
                    
                    if latest_db_block is None:
                        # First run - collect recent blocks
                        logger.info("First run - collecting recent blocks")
                        await self.collect_recent_data(100)
                    else:
                        # Collect new blocks since last run
                        new_blocks = current_block - latest_db_block
                        if new_blocks > 0:
                            logger.info(f"Found {new_blocks} new blocks, collecting...")
                            await self.collect_historical_data(latest_db_block + 1, current_block)
                        else:
                            logger.info("No new blocks to collect")
                    
                    # Wait for next interval
                    await asyncio.sleep(interval_seconds)
                    
                except Exception as e:
                    logger.error(f"Error in continuous collection cycle: {e}")
                    await asyncio.sleep(interval_seconds)
            
        except KeyboardInterrupt:
            logger.info("Continuous collection stopped by user")
        except Exception as e:
            logger.error(f"Error in continuous collection: {e}")
        finally:
            self.is_running = False
    
    def stop_continuous_collection(self):
        """Stop continuous collection"""
        self.is_running = False
        logger.info("Stopping continuous collection...")

async def main():
    """Main function"""
    parser = argparse.ArgumentParser(description="Polygon Network Data Collector")
    parser.add_argument("--endpoint-name", required=True, help="QuickNode endpoint name")
    parser.add_argument("--token-id", required=True, help="QuickNode token ID")
    parser.add_argument("--network", default="polygon_mainnet", help="Network to collect from")
    parser.add_argument("--mode", choices=["recent", "historical", "continuous"], 
                       default="recent", help="Collection mode")
    parser.add_argument("--num-blocks", type=int, default=100, help="Number of blocks to collect")
    parser.add_argument("--start-block", type=int, help="Start block for historical collection")
    parser.add_argument("--end-block", type=int, help="End block for historical collection")
    parser.add_argument("--interval", type=int, default=60, help="Interval for continuous collection (seconds)")
    parser.add_argument("--no-db", action="store_true", help="Don't save to database")
    
    args = parser.parse_args()
    
    # Initialize collector
    collector = PolygonMainCollector(args.endpoint_name, args.token_id, args.network)
    
    try:
        await collector.initialize()
        
        if args.mode == "recent":
            await collector.collect_recent_data(args.num_blocks, not args.no_db)
            
        elif args.mode == "historical":
            if not args.start_block or not args.end_block:
                logger.error("Start and end blocks required for historical mode")
                return
            await collector.collect_historical_data(args.start_block, args.end_block, save_to_db=not args.no_db)
            
        elif args.mode == "continuous":
            await collector.run_continuous_collection(args.interval)
            
    except KeyboardInterrupt:
        logger.info("Collection stopped by user")
    except Exception as e:
        logger.error(f"Error in main collection: {e}")
    finally:
        await collector.cleanup()

if __name__ == "__main__":
    asyncio.run(main())
