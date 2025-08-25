"""
Configuration file for QuickNode API testing
"""

import os
from dataclasses import dataclass
from typing import Optional

@dataclass
class QuickNodeEndpoints:
    """QuickNode endpoint configuration"""
    http_url: str
    ws_url: str
    name: str = "QuickNode Multinet"
    timeout: int = 30
    max_retries: int = 3

# Default QuickNode configuration
DEFAULT_QUICKNODE_CONFIG = QuickNodeEndpoints(
    http_url="https://hidden-holy-seed.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b",
    ws_url="wss://hidden-holy-seed.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b",
    name="QuickNode Multinet"
)

# Environment variable overrides
def get_quicknode_config() -> QuickNodeEndpoints:
    """Get QuickNode configuration with environment variable overrides"""
    return QuickNodeEndpoints(
        http_url=os.getenv("QUICKNODE_HTTP_URL", DEFAULT_QUICKNODE_CONFIG.http_url),
        ws_url=os.getenv("QUICKNODE_WS_URL", DEFAULT_QUICKNODE_CONFIG.ws_url),
        name=os.getenv("QUICKNODE_NAME", DEFAULT_QUICKNODE_CONFIG.name),
        timeout=int(os.getenv("QUICKNODE_TIMEOUT", str(DEFAULT_QUICKNODE_CONFIG.timeout))),
        max_retries=int(os.getenv("QUICKNODE_MAX_RETRIES", str(DEFAULT_QUICKNODE_CONFIG.max_retries)))
    )

# Test configuration
TEST_CONFIG = {
    "enable_http_tests": True,
    "enable_websocket_tests": True,
    "enable_subscription_tests": True,
    "test_account": "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
    "log_level": "INFO",
    "save_results": True,
    "generate_report": True
}

# RPC methods to test
RPC_METHODS = [
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

# WebSocket subscription tests
SUBSCRIPTION_TESTS = [
    {
        "method": "eth_subscribe",
        "params": ["newHeads"],
        "description": "Subscribe to new block headers"
    },
    {
        "method": "eth_subscribe",
        "params": ["logs", {"topics": ["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"]}],
        "description": "Subscribe to ERC-20 transfer events"
    }
]
