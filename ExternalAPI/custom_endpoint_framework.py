#!/usr/bin/env python3
"""
Custom Endpoint Framework for User-Specific API Access
Allows users to create personalized endpoints for different networks
"""

import os
import requests
import json
import hashlib
import time
from dataclasses import dataclass, field
from typing import Dict, Optional, List, Any, Callable
from datetime import datetime, timedelta
from enum import Enum
import asyncio
import aiohttp
from functools import wraps

class ProviderType(Enum):
    """Supported API providers"""
    QUICKNODE = "quicknode"
    ALCHEMY = "alchemy"
    INFURA = "infura"
    CUSTOM = "custom"

class EndpointType(Enum):
    """Types of endpoints"""
    RPC = "rpc"
    NFT = "nft"
    TOKEN = "token"
    TRANSFERS = "transfers"
    ANALYTICS = "analytics"
    CUSTOM = "custom"

@dataclass
class UserAPIConfig:
    """User-specific API configuration"""
    user_id: str
    enabled_networks: List[str] = field(default_factory=list)
    api_keys: Dict[str, str] = field(default_factory=dict)
    custom_endpoints: List[str] = field(default_factory=list)
    rate_limits: Dict[str, int] = field(default_factory=dict)
    webhooks: List[str] = field(default_factory=list)
    preferences: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)
    last_updated: datetime = field(default_factory=datetime.now)

@dataclass
class CustomEndpoint:
    """Custom endpoint configuration"""
    endpoint_id: str
    user_id: str
    network: str
    endpoint_type: EndpointType
    method: str
    provider: ProviderType
    url: str
    headers: Dict[str, str] = field(default_factory=dict)
    params: Dict[str, Any] = field(default_factory=dict)
    rate_limit: int = 100  # requests per minute
    enabled: bool = True
    created_at: datetime = field(default_factory=datetime.now)
    last_used: Optional[datetime] = None
    usage_count: int = 0

@dataclass
class RateLimitInfo:
    """Rate limiting information"""
    user_id: str
    endpoint_id: str
    requests_this_minute: int = 0
    last_request_time: Optional[datetime] = None
    reset_time: Optional[datetime] = None

class CustomEndpointManager:
    """Manager for custom user endpoints"""
    
    def __init__(self):
        self.user_configs: Dict[str, UserAPIConfig] = {}
        self.custom_endpoints: Dict[str, CustomEndpoint] = {}
        self.rate_limits: Dict[str, RateLimitInfo] = {}
        self.endpoint_cache: Dict[str, Any] = {}
        self.provider_configs = self._initialize_providers()
    
    def _initialize_providers(self) -> Dict[ProviderType, Dict]:
        """Initialize provider configurations"""
        return {
            ProviderType.QUICKNODE: {
                "base_url": "https://{endpoint_name}.quiknode.pro/{token_id}",
                "ws_url": "wss://{endpoint_name}.quiknode.pro/{token_id}",
                "api_key_env": "QUICKNODE_API_KEY",
                "endpoint_name_env": "QUICKNODE_ENDPOINT_NAME",
                "token_id_env": "QUICKNODE_TOKEN_ID"
            },
            ProviderType.ALCHEMY: {
                "base_url": "https://{network}.g.alchemy.com/v2/{api_key}",
                "ws_url": "wss://{network}.g.alchemy.com/v2/{api_key}",
                "api_key_env": "ALCHEMY_API_KEY"
            },
            ProviderType.INFURA: {
                "base_url": "https://{network}.infura.io/v3/{project_id}",
                "ws_url": "wss://{network}.infura.io/ws/v3/{project_id}",
                "project_id_env": "INFURA_PROJECT_ID"
            }
        }
    
    def create_user_config(self, user_id: str, enabled_networks: List[str] = None, 
                          api_keys: Dict[str, str] = None) -> UserAPIConfig:
        """Create a new user configuration"""
        config = UserAPIConfig(
            user_id=user_id,
            enabled_networks=enabled_networks or ["ethereum", "polygon", "arbitrum"],
            api_keys=api_keys or {},
            rate_limits={"default": 100}  # 100 requests per minute default
        )
        
        self.user_configs[user_id] = config
        return config
    
    def create_custom_endpoint(self, user_id: str, network: str, endpoint_type: EndpointType,
                              method: str, provider: ProviderType, custom_params: Dict[str, Any] = None) -> CustomEndpoint:
        """Create a custom endpoint for a user"""
        
        # Generate unique endpoint ID
        endpoint_id = self._generate_endpoint_id(user_id, network, method)
        
        # Get provider configuration
        provider_config = self.provider_configs.get(provider)
        if not provider_config:
            raise ValueError(f"Unsupported provider: {provider}")
        
        # Build endpoint URL
        url = self._build_endpoint_url(provider, network, provider_config)
        
        # Create endpoint
        endpoint = CustomEndpoint(
            endpoint_id=endpoint_id,
            user_id=user_id,
            network=network,
            endpoint_type=endpoint_type,
            method=method,
            provider=provider,
            url=url,
            params=custom_params or {},
            rate_limit=self._get_user_rate_limit(user_id)
        )
        
        self.custom_endpoints[endpoint_id] = endpoint
        
        # Initialize rate limiting
        self.rate_limits[endpoint_id] = RateLimitInfo(
            user_id=user_id,
            endpoint_id=endpoint_id
        )
        
        return endpoint
    
    def _generate_endpoint_id(self, user_id: str, network: str, method: str) -> str:
        """Generate unique endpoint ID"""
        unique_string = f"{user_id}:{network}:{method}:{int(time.time())}"
        return hashlib.md5(unique_string.encode()).hexdigest()[:12]
    
    def _build_endpoint_url(self, provider: ProviderType, network: str, provider_config: Dict) -> str:
        """Build endpoint URL based on provider configuration"""
        
        if provider == ProviderType.QUICKNODE:
            endpoint_name = os.getenv(provider_config["endpoint_name_env"], "hidden-holy-seed")
            token_id = os.getenv(provider_config["token_id_env"], "97d6d8e7659b49b126c43455edc4607949bfb52b")
            return provider_config["base_url"].format(endpoint_name=endpoint_name, token_id=token_id)
        
        elif provider == ProviderType.ALCHEMY:
            api_key = os.getenv(provider_config["api_key_env"], "")
            if not api_key:
                raise ValueError("ALCHEMY_API_KEY environment variable is required")
            return provider_config["base_url"].format(network=network, api_key=api_key)
        
        elif provider == ProviderType.INFURA:
            project_id = os.getenv(provider_config["project_id_env"], "")
            if not project_id:
                raise ValueError("INFURA_PROJECT_ID environment variable is required")
            return provider_config["base_url"].format(network=network, project_id=project_id)
        
        else:
            raise ValueError(f"Unsupported provider: {provider}")
    
    def _get_user_rate_limit(self, user_id: str) -> int:
        """Get rate limit for user"""
        user_config = self.user_configs.get(user_id)
        if user_config and user_config.rate_limits:
            return user_config.rate_limits.get("default", 100)
        return 100
    
    def execute_endpoint(self, endpoint_id: str, params: Dict[str, Any] = None) -> Dict[str, Any]:
        """Execute a custom endpoint"""
        
        endpoint = self.custom_endpoints.get(endpoint_id)
        if not endpoint:
            raise ValueError(f"Endpoint {endpoint_id} not found")
        
        if not endpoint.enabled:
            raise ValueError(f"Endpoint {endpoint_id} is disabled")
        
        # Check rate limiting
        if not self._check_rate_limit(endpoint_id):
            raise Exception(f"Rate limit exceeded for endpoint {endpoint_id}")
        
        # Execute based on endpoint type
        if endpoint.endpoint_type == EndpointType.RPC:
            return self._execute_rpc_endpoint(endpoint, params)
        elif endpoint.endpoint_type == EndpointType.NFT:
            return self._execute_nft_endpoint(endpoint, params)
        elif endpoint.endpoint_type == EndpointType.TOKEN:
            return self._execute_token_endpoint(endpoint, params)
        elif endpoint.endpoint_type == EndpointType.TRANSFERS:
            return self._execute_transfers_endpoint(endpoint, params)
        else:
            return self._execute_custom_endpoint(endpoint, params)
    
    def _check_rate_limit(self, endpoint_id: str) -> bool:
        """Check if endpoint is within rate limits"""
        rate_info = self.rate_limits.get(endpoint_id)
        if not rate_info:
            return True
        
        now = datetime.now()
        
        # Reset counter if minute has passed
        if rate_info.reset_time and now > rate_info.reset_time:
            rate_info.requests_this_minute = 0
            rate_info.reset_time = now + timedelta(minutes=1)
        
        # Initialize reset time if not set
        if not rate_info.reset_time:
            rate_info.reset_time = now + timedelta(minutes=1)
        
        # Check if limit exceeded
        endpoint = self.custom_endpoints.get(endpoint_id)
        if endpoint and rate_info.requests_this_minute >= endpoint.rate_limit:
            return False
        
        # Update counter
        rate_info.requests_this_minute += 1
        rate_info.last_request_time = now
        
        return True
    
    def _execute_rpc_endpoint(self, endpoint: CustomEndpoint, params: Dict[str, Any] = None) -> Dict[str, Any]:
        """Execute RPC endpoint"""
        
        # Prepare RPC payload
        rpc_params = params or {}
        payload = {
            "jsonrpc": "2.0",
            "method": endpoint.method,
            "params": rpc_params.get("params", []),
            "id": 1
        }
        
        headers = {
            "Content-Type": "application/json",
            **endpoint.headers
        }
        
        # Make request
        response = requests.post(
            endpoint.url,
            json=payload,
            headers=headers,
            timeout=30
        )
        
        if response.status_code != 200:
            raise Exception(f"RPC call failed: {response.status_code} - {response.text}")
        
        # Update endpoint usage
        self._update_endpoint_usage(endpoint)
        
        return response.json()
    
    def _execute_nft_endpoint(self, endpoint: CustomEndpoint, params: Dict[str, Any] = None) -> Dict[str, Any]:
        """Execute NFT endpoint (Alchemy-specific)"""
        
        if endpoint.provider != ProviderType.ALCHEMY:
            raise ValueError("NFT endpoints are only supported with Alchemy provider")
        
        # Build NFT API URL
        nft_url = f"{endpoint.url}/getNFTMetadata"
        
        # Prepare parameters
        nft_params = {
            "contractAddress": params.get("contractAddress"),
            "tokenId": params.get("tokenId")
        }
        
        # Make request
        response = requests.get(nft_url, params=nft_params, timeout=30)
        
        if response.status_code != 200:
            raise Exception(f"NFT API call failed: {response.status_code} - {response.text}")
        
        # Update endpoint usage
        self._update_endpoint_usage(endpoint)
        
        return response.json()
    
    def _execute_token_endpoint(self, endpoint: CustomEndpoint, params: Dict[str, Any] = None) -> Dict[str, Any]:
        """Execute token endpoint (Alchemy-specific)"""
        
        if endpoint.provider != ProviderType.ALCHEMY:
            raise ValueError("Token endpoints are only supported with Alchemy provider")
        
        # Build token API URL
        token_url = f"{endpoint.url}/getTokenMetadata"
        
        # Prepare parameters
        token_params = {
            "contractAddress": params.get("contractAddress")
        }
        
        # Make request
        response = requests.get(token_url, params=token_params, timeout=30)
        
        if response.status_code != 200:
            raise Exception(f"Token API call failed: {response.status_code} - {response.text}")
        
        # Update endpoint usage
        self._update_endpoint_usage(endpoint)
        
        return response.json()
    
    def _execute_transfers_endpoint(self, endpoint: CustomEndpoint, params: Dict[str, Any] = None) -> Dict[str, Any]:
        """Execute transfers endpoint (Alchemy-specific)"""
        
        if endpoint.provider != ProviderType.ALCHEMY:
            raise ValueError("Transfers endpoints are only supported with Alchemy provider")
        
        # Build transfers API URL
        transfers_url = f"{endpoint.url}/getAssetTransfers"
        
        # Prepare parameters
        transfers_params = {
            "maxCount": params.get("maxCount", 100)
        }
        
        if params.get("fromAddress"):
            transfers_params["fromAddress"] = params["fromAddress"]
        if params.get("toAddress"):
            transfers_params["toAddress"] = params["toAddress"]
        if params.get("category"):
            transfers_params["category"] = params["category"]
        
        # Make request
        response = requests.get(transfers_url, params=transfers_params, timeout=30)
        
        if response.status_code != 200:
            raise Exception(f"Transfers API call failed: {response.status_code} - {response.text}")
        
        # Update endpoint usage
        self._update_endpoint_usage(endpoint)
        
        return response.json()
    
    def _execute_custom_endpoint(self, endpoint: CustomEndpoint, params: Dict[str, Any] = None) -> Dict[str, Any]:
        """Execute custom endpoint"""
        
        # Merge endpoint params with request params
        all_params = {**endpoint.params, **(params or {})}
        
        # Determine HTTP method
        method = endpoint.method.upper()
        
        if method == "GET":
            response = requests.get(endpoint.url, params=all_params, headers=endpoint.headers, timeout=30)
        elif method == "POST":
            response = requests.post(endpoint.url, json=all_params, headers=endpoint.headers, timeout=30)
        else:
            raise ValueError(f"Unsupported HTTP method: {method}")
        
        if response.status_code != 200:
            raise Exception(f"Custom endpoint call failed: {response.status_code} - {response.text}")
        
        # Update endpoint usage
        self._update_endpoint_usage(endpoint)
        
        return response.json()
    
    def _update_endpoint_usage(self, endpoint: CustomEndpoint):
        """Update endpoint usage statistics"""
        endpoint.last_used = datetime.now()
        endpoint.usage_count += 1
    
    def get_user_endpoints(self, user_id: str) -> List[CustomEndpoint]:
        """Get all endpoints for a user"""
        return [ep for ep in self.custom_endpoints.values() if ep.user_id == user_id]
    
    def get_endpoint_by_id(self, endpoint_id: str) -> Optional[CustomEndpoint]:
        """Get endpoint by ID"""
        return self.custom_endpoints.get(endpoint_id)
    
    def delete_endpoint(self, endpoint_id: str) -> bool:
        """Delete an endpoint"""
        if endpoint_id in self.custom_endpoints:
            del self.custom_endpoints[endpoint_id]
            if endpoint_id in self.rate_limits:
                del self.rate_limits[endpoint_id]
            return True
        return False
    
    def update_user_config(self, user_id: str, **kwargs) -> bool:
        """Update user configuration"""
        if user_id in self.user_configs:
            config = self.user_configs[user_id]
            for key, value in kwargs.items():
                if hasattr(config, key):
                    setattr(config, key, value)
            config.last_updated = datetime.now()
            return True
        return False
    
    def get_endpoint_statistics(self, user_id: str = None) -> Dict[str, Any]:
        """Get endpoint statistics"""
        stats = {
            "total_endpoints": len(self.custom_endpoints),
            "active_endpoints": len([ep for ep in self.custom_endpoints.values() if ep.enabled]),
            "total_users": len(self.user_configs),
            "endpoints_by_provider": {},
            "endpoints_by_type": {},
            "usage_statistics": {}
        }
        
        # Provider statistics
        for endpoint in self.custom_endpoints.values():
            provider = endpoint.provider.value
            endpoint_type = endpoint.endpoint_type.value
            
            stats["endpoints_by_provider"][provider] = stats["endpoints_by_provider"].get(provider, 0) + 1
            stats["endpoints_by_type"][endpoint_type] = stats["endpoints_by_type"].get(endpoint_type, 0) + 1
            
            if user_id is None or endpoint.user_id == user_id:
                stats["usage_statistics"][endpoint.endpoint_id] = {
                    "usage_count": endpoint.usage_count,
                    "last_used": endpoint.last_used.isoformat() if endpoint.last_used else None,
                    "rate_limit": endpoint.rate_limit
                }
        
        return stats

# Global endpoint manager instance
endpoint_manager = CustomEndpointManager()

# Decorator for rate limiting
def rate_limit(max_requests: int = 100):
    """Decorator to apply rate limiting to functions"""
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Extract user_id from function arguments
            user_id = kwargs.get('user_id') or (args[0] if args else None)
            
            if user_id:
                # Check rate limit
                rate_info = endpoint_manager.rate_limits.get(f"{user_id}:{func.__name__}")
                if not rate_info:
                    rate_info = RateLimitInfo(user_id=user_id, endpoint_id=f"{user_id}:{func.__name__}")
                    endpoint_manager.rate_limits[f"{user_id}:{func.__name__}"] = rate_info
                
                now = datetime.now()
                if rate_info.reset_time and now > rate_info.reset_time:
                    rate_info.requests_this_minute = 0
                    rate_info.reset_time = now + timedelta(minutes=1)
                
                if not rate_info.reset_time:
                    rate_info.reset_time = now + timedelta(minutes=1)
                
                if rate_info.requests_this_minute >= max_requests:
                    raise Exception(f"Rate limit exceeded: {max_requests} requests per minute")
                
                rate_info.requests_this_minute += 1
                rate_info.last_request_time = now
            
            return func(*args, **kwargs)
        return wrapper
    return decorator

# Example usage functions
def create_user_endpoint_example():
    """Example of creating and using custom endpoints"""
    
    # Create user configuration
    user_config = endpoint_manager.create_user_config(
        user_id="user123",
        enabled_networks=["ethereum", "polygon", "arbitrum"],
        api_keys={"alchemy": "your-alchemy-key"}
    )
    
    # Create RPC endpoint for Ethereum
    eth_endpoint = endpoint_manager.create_custom_endpoint(
        user_id="user123",
        network="ethereum",
        endpoint_type=EndpointType.RPC,
        method="eth_blockNumber",
        provider=ProviderType.ALCHEMY
    )
    
    # Create NFT endpoint
    nft_endpoint = endpoint_manager.create_custom_endpoint(
        user_id="user123",
        network="ethereum",
        endpoint_type=EndpointType.NFT,
        method="getNFTMetadata",
        provider=ProviderType.ALCHEMY
    )
    
    # Execute endpoints
    try:
        # Get block number
        block_result = endpoint_manager.execute_endpoint(eth_endpoint.endpoint_id)
        print(f"Ethereum Block: {block_result}")
        
        # Get NFT metadata
        nft_result = endpoint_manager.execute_endpoint(
            nft_endpoint.endpoint_id,
            params={
                "contractAddress": "0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB",
                "tokenId": "1"
            }
        )
        print(f"NFT Metadata: {nft_result}")
        
    except Exception as e:
        print(f"Error: {e}")
    
    # Get statistics
    stats = endpoint_manager.get_endpoint_statistics("user123")
    print(f"User Statistics: {stats}")

def test_custom_endpoint_framework():
    """Test the custom endpoint framework"""
    
    print("🔧 Testing Custom Endpoint Framework")
    print("=" * 50)
    
    # Test user creation
    user_config = endpoint_manager.create_user_config("test_user")
    print(f"✅ Created user config for: {user_config.user_id}")
    
    # Test endpoint creation
    endpoint = endpoint_manager.create_custom_endpoint(
        user_id="test_user",
        network="ethereum",
        endpoint_type=EndpointType.RPC,
        method="eth_blockNumber",
        provider=ProviderType.ALCHEMY
    )
    print(f"✅ Created endpoint: {endpoint.endpoint_id}")
    
    # Test endpoint execution
    try:
        result = endpoint_manager.execute_endpoint(endpoint.endpoint_id)
        print(f"✅ Endpoint execution successful: {result}")
    except Exception as e:
        print(f"❌ Endpoint execution failed: {e}")
    
    # Test statistics
    stats = endpoint_manager.get_endpoint_statistics()
    print(f"✅ Framework statistics: {stats}")

if __name__ == "__main__":
    # Test the framework
    test_custom_endpoint_framework()
    
    # Example usage
    print("\n🎯 Example Usage:")
    create_user_endpoint_example()
