# External API Testing Utilities

This folder contains utilities for testing external APIs, specifically QuickNode endpoints for multinet access.

## QuickNode API Testing Utilities

### 1. Basic QuickNode API Testing Utility

The `quicknode_test.py` utility provides comprehensive testing for QuickNode API endpoints, including both HTTP and WebSocket connections.

### Features

- **HTTP RPC Testing**: Tests common Ethereum RPC methods via HTTP
- **WebSocket RPC Testing**: Tests RPC methods via WebSocket connection
- **Subscription Testing**: Tests WebSocket subscription capabilities
- **Performance Metrics**: Measures response times for all requests
- **Comprehensive Reporting**: Generates detailed test reports
- **Result Export**: Saves test results to JSON files
- **Logging**: Detailed logging to both console and file

### Supported RPC Methods

The utility tests the following Ethereum RPC methods:

- `eth_blockNumber` - Get latest block number
- `eth_getBlockByNumber` - Get latest block information
- `eth_chainId` - Get chain ID
- `eth_gasPrice` - Get current gas price
- `eth_getBalance` - Get account balance
- `net_version` - Get network version
- `web3_clientVersion` - Get client version
- `eth_subscribe` - WebSocket subscription (new blocks)

### Quick Start

1. **Using the shell script (recommended):**
   ```bash
   cd ExternalAPI
   ./run_quicknode_test.sh
   ```

2. **Manual setup:**
   ```bash
   cd ExternalAPI
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   python3 quicknode_test.py
   ```

### Configuration

The utility is configured with the following QuickNode endpoints:

- **HTTP URL**: `https://hidden-holy-seed.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b`
- **WebSocket URL**: `wss://hidden-holy-seed.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b`

### Output Files

After running the tests, the following files will be generated:

- `quicknode_test.log` - Detailed execution log
- `quicknode_test_results_YYYYMMDD_HHMMSS.json` - Test results in JSON format
- Console output with a comprehensive test report

### Test Report Example

```
================================================================================
QUICKNODE API TEST REPORT
================================================================================
Configuration:
  Name: QuickNode Multinet
  HTTP URL: https://hidden-holy-seed.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b
  WebSocket URL: wss://hidden-holy-seed.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b
  Test Time: 2024-01-15 14:30:25

Summary:
  Total Tests: 15
  Successful: 15
  Failed: 0
  Success Rate: 100.0%
  Average Response Time: 0.245s

Detailed Results:
  HTTP Endpoint Results:
  ✓ eth_blockNumber: 0.123s
  ✓ eth_getBlockByNumber: 0.156s
  ✓ eth_chainId: 0.098s
  ...

  WebSocket Endpoint Results:
  ✓ eth_blockNumber: 0.134s
  ✓ eth_subscribe: 0.189s
  ...
```

### Dependencies

- `requests` - HTTP client for API requests
- `websockets` - WebSocket client for real-time connections
- `python-dotenv` - Environment variable management
- `asyncio` - Asynchronous programming support

### Customization

To test different QuickNode endpoints, modify the configuration in the `main()` function:

```python
config = QuickNodeConfig(
    http_url="YOUR_HTTP_ENDPOINT",
    ws_url="YOUR_WEBSOCKET_ENDPOINT",
    name="Your QuickNode Instance"
)
```

### Error Handling

The utility includes comprehensive error handling for:

- Network timeouts
- Connection failures
- RPC errors
- WebSocket connection issues
- Invalid responses

### Performance Monitoring

The utility tracks:

- Response times for each request
- Success/failure rates
- Average response times
- Detailed error messages

### Security Notes

- API keys and endpoints are hardcoded in the script for testing purposes
- For production use, consider using environment variables
- The utility does not store sensitive data beyond the test session

### Troubleshooting

**Common Issues:**

1. **Connection timeout**: Check your internet connection and firewall settings
2. **WebSocket connection failed**: Verify the WebSocket URL is correct
3. **RPC method not supported**: Some methods may not be available on all networks
4. **Rate limiting**: QuickNode may have rate limits; add delays between requests if needed

**Debug Mode:**

Enable debug logging by modifying the logging level in the script:

```python
logging.basicConfig(level=logging.DEBUG, ...)
```

### Integration

This utility can be integrated into:

- CI/CD pipelines for API health checks
- Monitoring systems for endpoint availability
- Development workflows for API testing
- Automated testing suites

### 2. Multichain API Testing Utility

The `multichain_test.py` utility tests multiple blockchain networks through QuickNode's multichain endpoint structure, as described in the [QuickNode multichain documentation](https://www.quicknode.com/guides/quicknode-products/how-to-use-multichain-endpoint).

#### Features

- **Multi-Network Testing**: Tests multiple blockchain networks through a single QuickNode endpoint
- **Network Coverage**: Supports Ethereum, Base, BSC, Avalanche, Polygon, Arbitrum, and Optimism
- **Block Number Verification**: Gets current block numbers for each network
- **Chain ID Validation**: Verifies chain IDs for each network
- **Performance Metrics**: Measures response times across all networks
- **Comprehensive Reporting**: Generates detailed reports for all networks

#### Supported Networks

Based on QuickNode's multichain structure, the utility tests:

- **Ethereum Mainnet**: `https://{endpoint}.quiknode.pro/{token}`
- **Base Mainnet**: `https://{endpoint}.base-mainnet.quiknode.pro/{token}`
- **Binance Smart Chain**: `https://{endpoint}.bsc.quiknode.pro/{token}`
- **Avalanche C-Chain**: `https://{endpoint}.avalanche-mainnet.quiknode.pro/{token}/ext/bc/C/rpc`
- **Polygon**: `https://{endpoint}.polygon-mainnet.quiknode.pro/{token}`
- **Arbitrum One**: `https://{endpoint}.arbitrum-one.quiknode.pro/{token}`
- **Optimism**: `https://{endpoint}.optimism-mainnet.quiknode.pro/{token}`

#### Quick Start

1. **Using the shell script:**
   ```bash
   cd ExternalAPI
   ./run_multichain_test.sh
   ```

2. **Manual execution:**
   ```bash
   cd ExternalAPI
   source venv/bin/activate
   python3 multichain_test.py
   ```

#### Configuration

The multichain utility automatically constructs URLs based on QuickNode's multichain structure:

```python
# Example configuration
endpoint_name = "hidden-holy-seed"
token_id = "97d6d8e7659b49b126c43455edc4607949bfb52b"

# This creates URLs like:
# Ethereum: https://hidden-holy-seed.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b
# Base: https://hidden-holy-seed.base-mainnet.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b
# etc.
```

#### Output Example

```
================================================================================
QUICKNODE MULTICHAIN API TEST REPORT
================================================================================
Configuration:
  Base Endpoint: hidden-holy-seed
  Token ID: 97d6d8e7659b49b126c43455edc4607949bfb52b
  Networks Tested: 7
  Test Time: 2024-01-15 14:30:25

Summary:
  Total Tests: 14
  Successful: 14
  Failed: 0
  Success Rate: 100.0%
  Average Response Time: 0.245s

Network Results:

Ethereum:
  Success Rate: 100.0% (2/2)
  Average Response Time: 0.123s
  ✓ eth_blockNumber: Block 19234567 (0.098s)
  ✓ eth_chainId: 0.145s

Base:
  Success Rate: 100.0% (2/2)
  Average Response Time: 0.156s
  ✓ eth_blockNumber: Block 45678901 (0.134s)
  ✓ eth_chainId: 0.178s
...
```

### 3. Configuration Management

The `config.py` file provides centralized configuration management for both utilities:

- **Environment Variable Support**: Override settings via environment variables
- **QuickNode Endpoint Configuration**: Manage HTTP and WebSocket URLs
- **Test Configuration**: Control which tests to run
- **RPC Method Definitions**: Define which RPC methods to test

#### Environment Variables

```bash
# QuickNode Configuration
export QUICKNODE_HTTP_URL="https://your-endpoint.quiknode.pro/your-token"
export QUICKNODE_WS_URL="wss://your-endpoint.quiknode.pro/your-token"
export QUICKNODE_NAME="Your QuickNode Instance"
export QUICKNODE_TIMEOUT=30
export QUICKNODE_MAX_RETRIES=3
```

### License

This utility is part of the DefiMon project and follows the same licensing terms.
