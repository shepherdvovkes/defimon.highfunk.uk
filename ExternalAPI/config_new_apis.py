"""
Configuration file for new API services testing
"""

import os
from dataclasses import dataclass
from typing import Optional, Dict, Any

@dataclass
class APIConfig:
    """Base API configuration"""
    api_key: str
    base_url: str
    timeout: int = 30
    max_retries: int = 3
    headers: Optional[Dict[str, str]] = None

@dataclass
class QuickNodeConfig:
    """QuickNode API configuration"""
    api_key: str
    http_url: str
    ws_url: str
    name: str = "QuickNode Multinet"
    timeout: int = 30
    max_retries: int = 3
    headers: Optional[Dict[str, str]] = None



@dataclass
class BlastConfig(APIConfig):
    """Blast API configuration"""
    base_url: str = "https://api.blast.io"

@dataclass
class CoinGeckoConfig(APIConfig):
    """CoinGecko API configuration"""
    base_url: str = "https://api.coingecko.com/api/v3"

@dataclass
class CoinCapConfig(APIConfig):
    """CoinCap API configuration"""
    base_url: str = "https://api.coincap.io/v2"

@dataclass
class GitHubConfig(APIConfig):
    """GitHub API configuration"""
    base_url: str = "https://api.github.com"
    username: str = ""

# Environment variable configuration
def get_quicknode_config() -> QuickNodeConfig:
    """Get QuickNode configuration from environment variables"""
    api_key = os.getenv("QUICKNODE_API_KEY", "")
    return QuickNodeConfig(
        api_key=api_key,
        http_url=os.getenv("QUICKNODE_HTTP_URL", "https://hidden-holy-seed.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b"),
        ws_url=os.getenv("QUICKNODE_WS_URL", "wss://hidden-holy-seed.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b"),
        name="QuickNode Multinet",
        timeout=int(os.getenv("QUICKNODE_TIMEOUT", "30")),
        max_retries=int(os.getenv("QUICKNODE_MAX_RETRIES", "3")),
        headers={"Content-Type": "application/json"}
    )

def get_blast_config() -> BlastConfig:
    """Get Blast API configuration from environment variables"""
    api_key = os.getenv("BLAST_API_KEY", "")
    # Blast API provides personalized endpoints after registration
    # This is a placeholder URL - users need to get their actual endpoint from https://blastapi.io
    base_url = os.getenv("BLAST_API_URL", f"https://{api_key}.blastapi.io" if api_key else "https://blastapi.io")
    return BlastConfig(
        api_key=api_key,
        base_url=base_url,
        timeout=int(os.getenv("BLAST_TIMEOUT", "30")),
        max_retries=int(os.getenv("BLAST_MAX_RETRIES", "3")),
        headers={"Content-Type": "application/json"}
    )

def get_coingecko_config() -> CoinGeckoConfig:
    """Get CoinGecko API configuration from environment variables"""
    api_key = os.getenv("COINGECKO_API_KEY", "")
    return CoinGeckoConfig(
        api_key=api_key,
        base_url="https://api.coingecko.com/api/v3",
        timeout=int(os.getenv("COINGECKO_TIMEOUT", "30")),
        max_retries=int(os.getenv("COINGECKO_MAX_RETRIES", "3")),
        headers={"X-CG-API-KEY": api_key} if api_key else None
    )

def get_coincap_config() -> CoinCapConfig:
    """Get CoinCap API configuration from environment variables"""
    api_key = os.getenv("COINCAP_API_KEY", "")
    return CoinCapConfig(
        api_key=api_key,
        base_url="https://pro.coincap.io",
        timeout=int(os.getenv("COINCAP_TIMEOUT", "30")),
        max_retries=int(os.getenv("COINCAP_MAX_RETRIES", "3")),
        headers={"Authorization": f"Bearer {api_key}"} if api_key else None
    )

def get_github_config() -> GitHubConfig:
    """Get GitHub API configuration from environment variables"""
    api_key = os.getenv("GITHUB_API_TOKEN", "")
    username = os.getenv("GITHUB_USERNAME", "")
    return GitHubConfig(
        api_key=api_key,
        base_url="https://api.github.com",
        username=username,
        timeout=int(os.getenv("GITHUB_TIMEOUT", "30")),
        max_retries=int(os.getenv("GITHUB_MAX_RETRIES", "3")),
        headers={
            "Authorization": f"token {api_key}",
            "Accept": "application/vnd.github.v3+json"
        } if api_key else None
    )

# Test configuration
TEST_CONFIG = {
    "enable_quicknode_tests": True,
    "enable_blast_tests": True,
    "enable_coingecko_tests": True,
    "enable_coincap_tests": False,  # Disabled - requires valid API key
    "enable_github_tests": True,
    "log_level": "INFO",
    "save_results": True,
    "generate_report": True,
    "test_account": "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6"
}

# QuickNode RPC methods to test
QUICKNODE_RPC_METHODS = [
    {
        "method": "eth_blockNumber",
        "params": [],
        "description": "Get latest block number"
    },
    {
        "method": "eth_getBlockByNumber",
        "params": ["latest", False],
        "description": "Get latest block info"
    },
    {
        "method": "eth_chainId",
        "params": [],
        "description": "Get chain ID"
    },
    {
        "method": "eth_gasPrice",
        "params": [],
        "description": "Get current gas price"
    },
    {
        "method": "eth_getBalance",
        "params": ["0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6", "latest"],
        "description": "Get account balance"
    },
    {
        "method": "net_version",
        "params": [],
        "description": "Get network version"
    },
    {
        "method": "web3_clientVersion",
        "params": [],
        "description": "Get client version"
    }
]

# Blast API RPC methods to test (similar to QuickNode)
BLAST_RPC_METHODS = [
    {
        "method": "eth_blockNumber",
        "params": [],
        "description": "Get latest block number"
    },
    {
        "method": "eth_getBlockByNumber",
        "params": ["latest", False],
        "description": "Get latest block info"
    },
    {
        "method": "eth_chainId",
        "params": [],
        "description": "Get chain ID"
    },
    {
        "method": "eth_gasPrice",
        "params": [],
        "description": "Get current gas price"
    },
    {
        "method": "net_version",
        "params": [],
        "description": "Get network version"
    }
]

# CoinGecko API endpoints to test
COINGECKO_API_ENDPOINTS = [
    {
        "endpoint": "/ping",
        "method": "GET",
        "description": "Test API connectivity"
    },
    {
        "endpoint": "/simple/price",
        "method": "GET",
        "description": "Get simple price data",
        "params": {"ids": "bitcoin,ethereum", "vs_currencies": "usd,eur"}
    },
    {
        "endpoint": "/coins/markets",
        "method": "GET",
        "description": "Get market data",
        "params": {"vs_currency": "usd", "order": "market_cap_desc", "per_page": "10", "page": "1"}
    },
    {
        "endpoint": "/coins/bitcoin",
        "method": "GET",
        "description": "Get Bitcoin detailed data"
    }
]

# CoinCap API endpoints to test
COINCAP_API_ENDPOINTS = [
    {
        "endpoint": "/assets",
        "method": "GET",
        "description": "Get all assets"
    },
    {
        "endpoint": "/assets/bitcoin",
        "method": "GET",
        "description": "Get Bitcoin asset data"
    },
    {
        "endpoint": "/rates",
        "method": "GET",
        "description": "Get exchange rates"
    },
    {
        "endpoint": "/exchanges",
        "method": "GET",
        "description": "Get exchange data"
    }
]

# GitHub API endpoints to test
GITHUB_API_ENDPOINTS = [
    {
        "endpoint": "/user",
        "method": "GET",
        "description": "Get authenticated user information"
    },
    {
        "endpoint": "/user/repos",
        "method": "GET",
        "description": "Get user repositories"
    },
    {
        "endpoint": "/rate_limit",
        "method": "GET",
        "description": "Check API rate limits"
    },
    {
        "endpoint": "/search/repositories",
        "method": "GET",
        "description": "Search repositories",
        "params": {"q": "defi blockchain", "sort": "stars", "order": "desc"}
    }
]
