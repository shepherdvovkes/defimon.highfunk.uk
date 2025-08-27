#!/usr/bin/env python3
"""
Polygon Network API Client
Comprehensive API client for collecting all Polygon network data via QuickNode
"""

import asyncio
import aiohttp
import json
import time
from typing import Dict, List, Optional, Any, Union
from dataclasses import dataclass
from datetime import datetime, timedelta
import logging
from web3 import Web3
from web3.exceptions import Web3Exception
import backoff

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class APIResponse:
    """Standardized API response"""
    success: bool
    data: Any
    error: Optional[str] = None
    timestamp: datetime = None
    request_id: Optional[str] = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.utcnow()

class PolygonAPIClient:
    """Comprehensive API client for Polygon network data collection"""
    
    def __init__(self, endpoint_url: str, api_key: Optional[str] = None):
        self.endpoint_url = endpoint_url
        self.api_key = api_key
        self.session = None
        self.request_count = 0
        self.rate_limit_delay = 0.02  # 50 requests per second
        self.last_request_time = 0
        
    async def create_session(self):
        """Create aiohttp session"""
        if self.session is None:
            connector = aiohttp.TCPConnector(limit=100, ssl=False)
            timeout = aiohttp.ClientTimeout(total=60)
            self.session = aiohttp.ClientSession(
                connector=connector, 
                timeout=timeout,
                headers={
                    'Content-Type': 'application/json',
                    'User-Agent': 'Polygon-Data-Collector/1.0'
                }
            )
        return self.session
    
    async def close_session(self):
        """Close aiohttp session"""
        if self.session:
            await self.session.close()
            self.session = None
    
    async def _rate_limit(self):
        """Implement rate limiting"""
        current_time = time.time()
        time_since_last = current_time - self.last_request_time
        if time_since_last < self.rate_limit_delay:
            await asyncio.sleep(self.rate_limit_delay - time_since_last)
        self.last_request_time = time.time()
    
    @backoff.on_exception(backoff.expo, Exception, max_tries=3)
    async def _make_request(self, method: str, params: List = None, request_id: str = None) -> APIResponse:
        """Make RPC request with retry logic"""
        await self._rate_limit()
        
        payload = {
            "jsonrpc": "2.0",
            "method": method,
            "params": params or [],
            "id": self.request_count
        }
        
        if request_id:
            payload["request_id"] = request_id
        
        self.request_count += 1
        
        try:
            session = await self.create_session()
            async with session.post(self.endpoint_url, json=payload) as response:
                if response.status == 200:
                    data = await response.json()
                    if "error" in data:
                        return APIResponse(
                            success=False,
                            data=None,
                            error=data["error"].get("message", "Unknown error"),
                            request_id=request_id
                        )
                    return APIResponse(
                        success=True,
                        data=data.get("result"),
                        request_id=request_id
                    )
                else:
                    return APIResponse(
                        success=False,
                        data=None,
                        error=f"HTTP {response.status}",
                        request_id=request_id
                    )
        except Exception as e:
            logger.error(f"Request failed: {e}")
            return APIResponse(
                success=False,
                data=None,
                error=str(e),
                request_id=request_id
            )
    
    # Core Blockchain Data Methods
    
    async def get_block_number(self) -> APIResponse:
        """Get current block number"""
        return await self._make_request("eth_blockNumber")
    
    async def get_block_by_number(self, block_number: Union[int, str], full_transactions: bool = True) -> APIResponse:
        """Get block by number"""
        if isinstance(block_number, int):
            block_number = hex(block_number)
        return await self._make_request("eth_getBlockByNumber", [block_number, full_transactions])
    
    async def get_block_by_hash(self, block_hash: str, full_transactions: bool = True) -> APIResponse:
        """Get block by hash"""
        return await self._make_request("eth_getBlockByHash", [block_hash, full_transactions])
    
    async def get_transaction_by_hash(self, tx_hash: str) -> APIResponse:
        """Get transaction by hash"""
        return await self._make_request("eth_getTransactionByHash", [tx_hash])
    
    async def get_transaction_receipt(self, tx_hash: str) -> APIResponse:
        """Get transaction receipt"""
        return await self._make_request("eth_getTransactionReceipt", [tx_hash])
    
    async def get_logs(self, from_block: Union[int, str], to_block: Union[int, str], 
                      address: Optional[str] = None, topics: Optional[List] = None) -> APIResponse:
        """Get event logs"""
        params = {
            "fromBlock": hex(from_block) if isinstance(from_block, int) else from_block,
            "toBlock": hex(to_block) if isinstance(to_block, int) else to_block
        }
        if address:
            params["address"] = address
        if topics:
            params["topics"] = topics
        return await self._make_request("eth_getLogs", [params])
    
    async def get_balance(self, address: str, block: Optional[Union[int, str]] = None) -> APIResponse:
        """Get address balance"""
        params = [address]
        if block:
            if isinstance(block, int):
                block = hex(block)
            params.append(block)
        return await self._make_request("eth_getBalance", params)
    
    async def get_code(self, address: str, block: Optional[Union[int, str]] = None) -> APIResponse:
        """Get contract code"""
        params = [address]
        if block:
            if isinstance(block, int):
                block = hex(block)
            params.append(block)
        return await self._make_request("eth_getCode", params)
    
    async def get_storage_at(self, address: str, position: str, block: Optional[Union[int, str]] = None) -> APIResponse:
        """Get storage at position"""
        params = [address, position]
        if block:
            if isinstance(block, int):
                block = hex(block)
            params.append(block)
        return await self._make_request("eth_getStorageAt", params)
    
    async def call(self, to: str, data: str, block: Optional[Union[int, str]] = None) -> APIResponse:
        """Call contract method"""
        params = [{"to": to, "data": data}]
        if block:
            if isinstance(block, int):
                block = hex(block)
            params.append(block)
        return await self._make_request("eth_call", params)
    
    # Enhanced QuickNode API Methods
    
    async def get_wallet_token_balance(self, wallet_address: str) -> APIResponse:
        """Get wallet token balances"""
        return await self._make_request("qn_getWalletTokenBalance", [wallet_address])
    
    async def get_wallet_token_transactions(self, wallet_address: str, page: int = 1, per_page: int = 100) -> APIResponse:
        """Get wallet token transactions"""
        return await self._make_request("qn_getWalletTokenTransactions", [wallet_address, page, per_page])
    
    async def get_wallet_nfts(self, wallet_address: str) -> APIResponse:
        """Get wallet NFTs"""
        return await self._make_request("qn_getWalletNFTs", [wallet_address])
    
    async def get_wallet_nft_transactions(self, wallet_address: str, page: int = 1, per_page: int = 100) -> APIResponse:
        """Get wallet NFT transactions"""
        return await self._make_request("qn_getWalletNFTTransactions", [wallet_address, page, per_page])
    
    async def get_wallet_nft_collections(self, wallet_address: str) -> APIResponse:
        """Get wallet NFT collections"""
        return await self._make_request("qn_getWalletNFTCollections", [wallet_address])
    
    async def get_wallet_portfolio(self, wallet_address: str) -> APIResponse:
        """Get wallet portfolio overview"""
        return await self._make_request("qn_getWalletPortfolio", [wallet_address])
    
    async def get_token_metadata(self, contract_address: str) -> APIResponse:
        """Get token metadata"""
        return await self._make_request("qn_getTokenMetadata", [contract_address])
    
    async def get_token_price(self, contract_address: str) -> APIResponse:
        """Get token price"""
        return await self._make_request("qn_getTokenPrice", [contract_address])
    
    async def get_token_holders(self, contract_address: str, page: int = 1, per_page: int = 100) -> APIResponse:
        """Get token holders"""
        return await self._make_request("qn_getTokenHolders", [contract_address, page, per_page])
    
    async def get_token_transfers(self, contract_address: str, page: int = 1, per_page: int = 100) -> APIResponse:
        """Get token transfers"""
        return await self._make_request("qn_getTokenTransfers", [contract_address, page, per_page])
    
    async def get_wallet_analytics(self, wallet_address: str) -> APIResponse:
        """Get wallet analytics"""
        return await self._make_request("qn_getWalletAnalytics", [wallet_address])
    
    async def get_token_analytics(self, contract_address: str) -> APIResponse:
        """Get token analytics"""
        return await self._make_request("qn_getTokenAnalytics", [contract_address])
    
    async def get_nft_analytics(self, contract_address: str) -> APIResponse:
        """Get NFT analytics"""
        return await self._make_request("qn_getNFTAnalytics", [contract_address])
    
    async def get_transaction_analytics(self, tx_hash: str) -> APIResponse:
        """Get transaction analytics"""
        return await self._make_request("qn_getTransactionAnalytics", [tx_hash])
    
    # Network Information Methods
    
    async def get_gas_price(self) -> APIResponse:
        """Get current gas price"""
        return await self._make_request("eth_gasPrice")
    
    async def get_network_version(self) -> APIResponse:
        """Get network version"""
        return await self._make_request("net_version")
    
    async def get_peer_count(self) -> APIResponse:
        """Get peer count"""
        return await self._make_request("net_peerCount")
    
    async def get_syncing(self) -> APIResponse:
        """Get sync status"""
        return await self._make_request("eth_syncing")
    
    # Batch Methods
    
    async def batch_request(self, requests: List[Dict]) -> List[APIResponse]:
        """Make batch RPC requests"""
        await self._rate_limit()
        
        payload = []
        for i, req in enumerate(requests):
            payload.append({
                "jsonrpc": "2.0",
                "method": req["method"],
                "params": req.get("params", []),
                "id": self.request_count + i
            })
        
        self.request_count += len(requests)
        
        try:
            session = await self.create_session()
            async with session.post(self.endpoint_url, json=payload) as response:
                if response.status == 200:
                    data = await response.json()
                    results = []
                    for i, result in enumerate(data):
                        if "error" in result:
                            results.append(APIResponse(
                                success=False,
                                data=None,
                                error=result["error"].get("message", "Unknown error"),
                                request_id=requests[i].get("request_id")
                            ))
                        else:
                            results.append(APIResponse(
                                success=True,
                                data=result.get("result"),
                                request_id=requests[i].get("request_id")
                            ))
                    return results
                else:
                    return [APIResponse(
                        success=False,
                        data=None,
                        error=f"HTTP {response.status}"
                    ) for _ in requests]
        except Exception as e:
            logger.error(f"Batch request failed: {e}")
            return [APIResponse(
                success=False,
                data=None,
                error=str(e)
            ) for _ in requests]
    
    # Utility Methods
    
    def wei_to_ether(self, wei: str) -> float:
        """Convert wei to ether"""
        try:
            return Web3.from_wei(int(wei, 16), 'ether')
        except:
            return 0.0
    
    def hex_to_int(self, hex_value: str) -> int:
        """Convert hex to integer"""
        try:
            return int(hex_value, 16)
        except:
            return 0
    
    def format_address(self, address: str) -> str:
        """Format address to checksum format"""
        try:
            return Web3.to_checksum_address(address)
        except:
            return address
    
    def get_request_stats(self) -> Dict[str, Any]:
        """Get request statistics"""
        return {
            "total_requests": self.request_count,
            "rate_limit_delay": self.rate_limit_delay,
            "requests_per_second": 1 / self.rate_limit_delay if self.rate_limit_delay > 0 else 0
        }

# Example usage
async def main():
    """Example usage of Polygon API client"""
    
    # Initialize client
    client = PolygonAPIClient(
        endpoint_url="https://your-endpoint.polygon-mainnet.quiknode.pro/your-token-id/"
    )
    
    try:
        # Test basic functionality
        print("Testing Polygon API client...")
        
        # Get current block number
        block_response = await client.get_block_number()
        if block_response.success:
            print(f"Current block: {client.hex_to_int(block_response.data)}")
        
        # Get gas price
        gas_response = await client.get_gas_price()
        if gas_response.success:
            gas_price_eth = client.wei_to_ether(gas_response.data)
            print(f"Gas price: {gas_price_eth} ETH")
        
        # Get network info
        version_response = await client.get_network_version()
        if version_response.success:
            print(f"Network version: {version_response.data}")
        
        # Print request stats
        stats = client.get_request_stats()
        print(f"Request stats: {stats}")
        
    finally:
        await client.close_session()

if __name__ == "__main__":
    asyncio.run(main())
