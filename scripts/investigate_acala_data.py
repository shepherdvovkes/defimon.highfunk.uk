#!/usr/bin/env python3
"""
Acala Network Data Structure Investigation Script
Uses the shrimp's Acala node container to investigate data structure and create learning datasets
"""

import asyncio
import json
import logging
import time
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
import aiohttp
import pandas as pd
import numpy as np
from dataclasses import dataclass, asdict
import os
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('acala_investigation.log'),
        logging.StreamHandler()
    ]
)

@dataclass
class AcalaBlockData:
    """Data structure for Acala block information"""
    block_number: int
    block_hash: str
    parent_hash: str
    timestamp: int
    extrinsics_count: int
    events_count: int
    total_fee: str
    block_size: int
    validator: str
    era: int
    session: int

@dataclass
class AcalaExtrinsicData:
    """Data structure for Acala extrinsic information"""
    extrinsic_hash: str
    block_number: int
    extrinsic_index: int
    call_module: str
    call_function: str
    signer: str
    nonce: int
    fee: str
    success: bool
    error_message: Optional[str]
    params: Dict[str, Any]

@dataclass
class AcalaEventData:
    """Data structure for Acala event information"""
    event_id: str
    block_number: int
    extrinsic_index: int
    event_index: int
    module: str
    event: str
    params: Dict[str, Any]

@dataclass
class AcalaAccountData:
    """Data structure for Acala account information"""
    address: str
    balance: str
    nonce: int
    locks: List[Dict[str, Any]]
    reserves: List[Dict[str, Any]]

@dataclass
class AcalaTokenData:
    """Data structure for Acala token information"""
    token_id: str
    name: str
    symbol: str
    decimals: int
    total_supply: str
    circulating_supply: str
    price_usd: Optional[float]

class AcalaDataInvestigator:
    """Investigator for Acala network data structure"""
    
    def __init__(self, rpc_url: str = "http://localhost:9949"):
        self.rpc_url = rpc_url
        self.session: Optional[aiohttp.ClientSession] = None
        self.output_dir = Path("acala_data_investigation")
        self.output_dir.mkdir(exist_ok=True)
        
        # Data storage
        self.blocks_data: List[AcalaBlockData] = []
        self.extrinsics_data: List[AcalaExtrinsicData] = []
        self.events_data: List[AcalaEventData] = []
        self.accounts_data: List[AcalaAccountData] = []
        self.tokens_data: List[AcalaTokenData] = []
        
    async def __aenter__(self):
        """Async context manager entry"""
        self.session = aiohttp.ClientSession()
        return self
        
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        if self.session:
            await self.session.close()
    
    async def make_rpc_call(self, method: str, params: List[Any] = None) -> Dict[str, Any]:
        """Make RPC call to Acala node"""
        if not self.session:
            raise RuntimeError("Session not initialized")
            
        payload = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": method,
            "params": params or []
        }
        
        try:
            async with self.session.post(self.rpc_url, json=payload) as response:
                if response.status == 200:
                    result = await response.json()
                    if "error" in result:
                        logging.error(f"RPC Error: {result['error']}")
                        return {}
                    return result.get("result", {})
                else:
                    logging.error(f"HTTP Error: {response.status}")
                    return {}
        except Exception as e:
            logging.error(f"RPC call failed: {e}")
            return {}
    
    async def check_node_health(self) -> bool:
        """Check if Acala node is healthy and synced"""
        logging.info("Checking Acala node health...")
        
        # Check system health
        health = await self.make_rpc_call("system_health")
        if health:
            logging.info(f"Node health: {health}")
        
        # Check chain head
        chain_head = await self.make_rpc_call("chain_getHeader")
        if chain_head:
            logging.info(f"Chain head: {chain_head}")
        
        # Check sync state
        sync_state = await self.make_rpc_call("system_syncState")
        if sync_state:
            logging.info(f"Sync state: {sync_state}")
            # Allow investigation even if syncing, but log the status
            if sync_state.get("isSyncing", True):
                logging.warning("Node is still syncing, but investigation will proceed with available data")
                return True  # Allow investigation to continue
            return True
        
        return False
    
    async def investigate_block_structure(self, block_number: int) -> Optional[AcalaBlockData]:
        """Investigate structure of a specific block"""
        logging.info(f"Investigating block {block_number}")
        
        # Get block hash
        block_hash = await self.make_rpc_call("chain_getBlockHash", [block_number])
        if not block_hash:
            return None
            
        # Get block header
        header = await self.make_rpc_call("chain_getHeader", [block_hash])
        if not header:
            return None
            
        # Get block details
        block = await self.make_rpc_call("chain_getBlock", [block_hash])
        if not block:
            return None
            
        # Get events for this block
        events = await self.make_rpc_call("state_getStorage", [
            f"0x26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da9{block_hash[2:]}"
        ])
        
        # Parse block data
        block_data = AcalaBlockData(
            block_number=block_number,
            block_hash=block_hash,
            parent_hash=header.get("parentHash", ""),
            timestamp=header.get("timestamp", 0),
            extrinsics_count=len(block.get("block", {}).get("extrinsics", [])),
            events_count=len(events) if events else 0,
            total_fee="0",  # Will be calculated from extrinsics
            block_size=len(str(block)),
            validator=header.get("author", ""),
            era=0,  # Will be extracted from events
            session=0  # Will be extracted from events
        )
        
        return block_data
    
    async def investigate_extrinsic_structure(self, block_number: int, extrinsic_index: int) -> Optional[AcalaExtrinsicData]:
        """Investigate structure of a specific extrinsic"""
        logging.info(f"Investigating extrinsic {extrinsic_index} in block {block_number}")
        
        # Get block hash
        block_hash = await self.make_rpc_call("chain_getBlockHash", [block_number])
        if not block_hash:
            return None
            
        # Get block
        block = await self.make_rpc_call("chain_getBlock", [block_hash])
        if not block:
            return None
            
        extrinsics = block.get("block", {}).get("extrinsics", [])
        if extrinsic_index >= len(extrinsics):
            return None
            
        extrinsic = extrinsics[extrinsic_index]
        
        # Decode extrinsic
        decoded = await self.make_rpc_call("state_call", [
            "AccountNonceApi_account_nonce",
            [extrinsic[:66]]  # First 32 bytes for address
        ])
        
        # Parse extrinsic data
        extrinsic_data = AcalaExtrinsicData(
            extrinsic_hash=f"{block_hash}_{extrinsic_index}",
            block_number=block_number,
            extrinsic_index=extrinsic_index,
            call_module="Unknown",
            call_function="Unknown",
            signer=extrinsic[:66] if len(extrinsic) >= 66 else "",
            nonce=decoded if decoded else 0,
            fee="0",
            success=True,
            error_message=None,
            params={}
        )
        
        return extrinsic_data
    
    async def investigate_account_structure(self, address: str) -> Optional[AcalaAccountData]:
        """Investigate structure of a specific account"""
        logging.info(f"Investigating account {address}")
        
        # Get account info
        account_info = await self.make_rpc_call("state_getStorage", [
            f"0x26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da9{address[2:]}"
        ])
        
        # Get account nonce
        nonce = await self.make_rpc_call("state_call", [
            "AccountNonceApi_account_nonce",
            [address]
        ])
        
        # Get locks
        locks = await self.make_rpc_call("state_getStorage", [
            f"0x26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da9{address[2:]}"
        ])
        
        account_data = AcalaAccountData(
            address=address,
            balance="0",
            nonce=nonce if nonce else 0,
            locks=[],
            reserves=[]
        )
        
        return account_data
    
    async def investigate_token_structure(self) -> List[AcalaTokenData]:
        """Investigate Acala token structure"""
        logging.info("Investigating Acala token structure")
        
        tokens = []
        
        # Common Acala tokens
        acala_tokens = [
            {"id": "ACA", "name": "Acala", "symbol": "ACA", "decimals": 12},
            {"id": "AUSD", "name": "Acala Dollar", "symbol": "AUSD", "decimals": 12},
            {"id": "LDOT", "name": "Liquid DOT", "symbol": "LDOT", "decimals": 10},
            {"id": "LCDOT", "name": "Liquid Crowdloan DOT", "symbol": "LCDOT", "decimals": 10},
            {"id": "KAR", "name": "Karura", "symbol": "KAR", "decimals": 12},
            {"id": "KUSD", "name": "Karura Dollar", "symbol": "KUSD", "decimals": 12},
        ]
        
        for token in acala_tokens:
            # Get token info from storage
            token_info = await self.make_rpc_call("state_getStorage", [
                f"0x26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da9{token['id']}"
            ])
            
            token_data = AcalaTokenData(
                token_id=token["id"],
                name=token["name"],
                symbol=token["symbol"],
                decimals=token["decimals"],
                total_supply="0",
                circulating_supply="0",
                price_usd=None
            )
            
            tokens.append(token_data)
        
        return tokens
    
    async def collect_sample_data(self, num_blocks: int = 10) -> None:
        """Collect sample data for analysis"""
        logging.info(f"Collecting sample data from {num_blocks} blocks")
        
        # Get latest block number
        latest_block = await self.make_rpc_call("chain_getHeader")
        if not latest_block:
            logging.error("Could not get latest block")
            return
            
        latest_number = int(latest_block.get("number", "0"), 16)
        logging.info(f"Latest block number: {latest_number}")
        
        # Collect data from recent blocks
        for i in range(num_blocks):
            block_number = latest_number - i
            if block_number < 0:
                break
                
            # Collect block data
            block_data = await self.investigate_block_structure(block_number)
            if block_data:
                self.blocks_data.append(block_data)
                
                # Collect extrinsic data for this block
                for ext_index in range(min(block_data.extrinsics_count, 5)):  # Limit to 5 extrinsics per block
                    ext_data = await self.investigate_extrinsic_structure(block_number, ext_index)
                    if ext_data:
                        self.extrinsics_data.append(ext_data)
            
            # Rate limiting
            await asyncio.sleep(0.1)
        
        # Collect token data
        self.tokens_data = await self.investigate_token_structure()
        
        logging.info(f"Collected {len(self.blocks_data)} blocks, {len(self.extrinsics_data)} extrinsics, {len(self.tokens_data)} tokens")
    
    def save_data_to_files(self) -> None:
        """Save collected data to files"""
        logging.info("Saving data to files...")
        
        # Save blocks data
        if self.blocks_data:
            blocks_df = pd.DataFrame([asdict(block) for block in self.blocks_data])
            blocks_df.to_csv(self.output_dir / "acala_blocks_sample.csv", index=False)
            blocks_df.to_json(self.output_dir / "acala_blocks_sample.json", orient="records", indent=2)
        
        # Save extrinsics data
        if self.extrinsics_data:
            extrinsics_df = pd.DataFrame([asdict(ext) for ext in self.extrinsics_data])
            extrinsics_df.to_csv(self.output_dir / "acala_extrinsics_sample.csv", index=False)
            extrinsics_df.to_json(self.output_dir / "acala_extrinsics_sample.json", orient="records", indent=2)
        
        # Save tokens data
        if self.tokens_data:
            tokens_df = pd.DataFrame([asdict(token) for token in self.tokens_data])
            tokens_df.to_csv(self.output_dir / "acala_tokens_sample.csv", index=False)
            tokens_df.to_json(self.output_dir / "acala_tokens_sample.json", orient="records", indent=2)
        
        # Save summary report
        self.save_summary_report()
        
        logging.info(f"Data saved to {self.output_dir}")
    
    def save_summary_report(self) -> None:
        """Save investigation summary report"""
        report = {
            "investigation_timestamp": datetime.now().isoformat(),
            "acala_node_url": self.rpc_url,
            "data_summary": {
                "blocks_collected": len(self.blocks_data),
                "extrinsics_collected": len(self.extrinsics_data),
                "events_collected": len(self.events_data),
                "accounts_collected": len(self.accounts_data),
                "tokens_collected": len(self.tokens_data)
            },
            "data_structure_analysis": {
                "block_fields": list(asdict(self.blocks_data[0]).keys()) if self.blocks_data else [],
                "extrinsic_fields": list(asdict(self.extrinsics_data[0]).keys()) if self.extrinsics_data else [],
                "token_fields": list(asdict(self.tokens_data[0]).keys()) if self.tokens_data else []
            },
            "recommendations": [
                "Use WebSocket connections for real-time data",
                "Implement proper error handling for RPC calls",
                "Add rate limiting to avoid overwhelming the node",
                "Cache frequently accessed data",
                "Implement data validation and sanitization"
            ]
        }
        
        with open(self.output_dir / "investigation_summary.json", "w") as f:
            json.dump(report, f, indent=2)
    
    async def run_investigation(self, num_blocks: int = 10) -> None:
        """Run complete investigation"""
        logging.info("Starting Acala data structure investigation...")
        
        # Check node health
        if not await self.check_node_health():
            logging.error("Acala node is not healthy or not synced")
            return
        
        # Collect sample data
        await self.collect_sample_data(num_blocks)
        
        # Save data to files
        self.save_data_to_files()
        
        logging.info("Investigation completed successfully!")

async def main():
    """Main function"""
    # Check if Acala node is running
    acala_url = "http://localhost:9949"
    
    async with AcalaDataInvestigator(acala_url) as investigator:
        await investigator.run_investigation(num_blocks=5)  # Reduced for syncing node

if __name__ == "__main__":
    asyncio.run(main())
