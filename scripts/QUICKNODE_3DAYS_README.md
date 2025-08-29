# QuickNode 3-Day Data Collection

This script fetches blockchain data from QuickNode API for the last 3 days across multiple networks and stores it in PostgreSQL.

## Features

- **Multi-Network Support**: Collects data from 7 major networks
  - Ethereum (Mainnet)
  - Polygon (MATIC)
  - Arbitrum One
  - Optimism
  - Base
  - Binance Smart Chain (BSC)
  - Avalanche C-Chain

- **Comprehensive Data Collection**:
  - Block data (headers, transactions, gas usage)
  - Transaction details (from/to addresses, values, gas prices)
  - Transaction receipts (status, gas used, logs)

- **Performance Optimized**:
  - Asynchronous processing with configurable concurrency
  - Batch processing for efficient API usage
  - Rate limiting to respect API limits
  - Retry logic with exponential backoff

- **Database Integration**:
  - Automatic table creation with proper schemas
  - Indexed tables for fast queries
  - Conflict resolution for duplicate data
  - Separate schemas per network

- **Monitoring & Logging**:
  - Real-time progress tracking
  - Detailed statistics per network
  - Comprehensive logging to file and console
  - Performance metrics and ETA calculations

## Prerequisites

### System Requirements
- Python 3.7+
- PostgreSQL database
- QuickNode API access
- 4GB+ RAM (for large datasets)

### Python Dependencies
```bash
pip install -r scripts/requirements_quicknode.txt
```

Or install manually:
```bash
pip install aiohttp asyncpg python-dotenv
```

## Configuration

### Environment Variables

Create a `.env` file in the project root with the following variables:

```bash
# QuickNode Configuration
QUICKNODE_ENDPOINT_NAME=hidden-holy-seed
QUICKNODE_TOKEN_ID=97d6d8e7659b49b126c43455edc4607949bfb52b
QUICKNODE_API_KEY=QN_6a9c24b3a5fc491f88e8c24c3294ef36

# Database Configuration
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=defi_analytics
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_password

# Collection Settings (Optional)
QUICKNODE_BATCH_SIZE=200
QUICKNODE_MAX_CONCURRENT=15
QUICKNODE_RATE_LIMIT=0.05
QUICKNODE_RETRY_ATTEMPTS=3
```

### QuickNode Setup

1. **Get QuickNode Access**:
   - Sign up at [QuickNode](https://www.quicknode.com/)
   - Create a new endpoint
   - Note your endpoint name and token ID

2. **Enable Networks**:
   - In your QuickNode dashboard, enable the networks you want to collect
   - Ensure you have sufficient request limits for your plan

## Usage

### Quick Start

Run the collection for all networks:
```bash
./scripts/run_quicknode_3days_collection.sh
```

### Command Line Options

```bash
# Test connections only
./scripts/run_quicknode_3days_collection.sh -t

# Collect specific networks
./scripts/run_quicknode_3days_collection.sh -n ethereum,polygon

# Custom batch settings
./scripts/run_quicknode_3days_collection.sh -b 100 -c 10 -r 0.1

# Dry run (show what would be executed)
./scripts/run_quicknode_3days_collection.sh -d

# Show help
./scripts/run_quicknode_3days_collection.sh -h
```

### Direct Python Usage

```bash
# Run the Python script directly
python3 scripts/quicknode_3days_data_collector.py

# With command line arguments
python3 scripts/quicknode_3days_data_collector.py \
  --networks ethereum polygon \
  --batch-size 100 \
  --max-concurrent 10 \
  --rate-limit 0.1
```

## Network Configuration

### Supported Networks

| Network | Chain ID | Network Key | Blocks/sec | Priority |
|---------|----------|-------------|------------|----------|
| Ethereum | 1 | ethereum | 12.0 | 1 |
| Polygon | 137 | matic | 2.0 | 2 |
| Arbitrum One | 42161 | arbitrum-one | 0.5 | 3 |
| Optimism | 10 | optimism | 2.0 | 4 |
| Base | 8453 | base | 2.0 | 5 |
| BSC | 56 | bsc-mainnet | 3.0 | 6 |
| Avalanche | 43114 | avalanche-mainnet | 2.0 | 7 |

### Network Selection

You can collect data from specific networks by using the `--networks` option:

```bash
# Collect only Ethereum and Polygon
./scripts/run_quicknode_3days_collection.sh -n ethereum,polygon

# Collect only high-priority networks
./scripts/run_quicknode_3days_collection.sh -n ethereum,arbitrum,optimism
```

## Database Schema

The script creates separate schemas for each network with the following structure:

### Blocks Table
```sql
CREATE TABLE {network}_data.blocks (
    block_number BIGINT PRIMARY KEY,
    block_hash VARCHAR(66) NOT NULL,
    parent_hash VARCHAR(66) NOT NULL,
    timestamp BIGINT NOT NULL,
    gas_limit BIGINT,
    gas_used BIGINT,
    miner VARCHAR(42),
    difficulty VARCHAR(66),
    total_difficulty VARCHAR(66),
    size BIGINT,
    extra_data TEXT,
    nonce VARCHAR(18),
    base_fee_per_gas VARCHAR(66),
    transactions_count INTEGER,
    logs_bloom TEXT,
    state_root VARCHAR(66),
    receipts_root VARCHAR(66),
    transactions_root VARCHAR(66),
    uncle_hash VARCHAR(66),
    mix_hash VARCHAR(66),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Transactions Table
```sql
CREATE TABLE {network}_data.transactions (
    hash VARCHAR(66) PRIMARY KEY,
    block_number BIGINT NOT NULL,
    block_hash VARCHAR(66) NOT NULL,
    from_address VARCHAR(42) NOT NULL,
    to_address VARCHAR(42),
    value VARCHAR(66) NOT NULL,
    gas BIGINT NOT NULL,
    gas_price VARCHAR(66) NOT NULL,
    nonce BIGINT NOT NULL,
    input_data TEXT,
    transaction_index INTEGER NOT NULL,
    timestamp BIGINT,
    max_fee_per_gas VARCHAR(66),
    max_priority_fee_per_gas VARCHAR(66),
    type VARCHAR(4),
    chain_id VARCHAR(66),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Receipts Table
```sql
CREATE TABLE {network}_data.receipts (
    transaction_hash VARCHAR(66) PRIMARY KEY,
    block_number BIGINT NOT NULL,
    block_hash VARCHAR(66) NOT NULL,
    transaction_index INTEGER NOT NULL,
    from_address VARCHAR(42) NOT NULL,
    to_address VARCHAR(42),
    cumulative_gas_used BIGINT NOT NULL,
    gas_used BIGINT NOT NULL,
    contract_address VARCHAR(42),
    logs JSONB,
    status INTEGER NOT NULL,
    effective_gas_price VARCHAR(66),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Performance Tuning

### Batch Size
- **Default**: 200 blocks per batch
- **Range**: 50-500 blocks
- **Recommendation**: 100-200 for most networks

### Concurrency
- **Default**: 15 concurrent requests
- **Range**: 5-50 requests
- **Recommendation**: 10-20 for most setups

### Rate Limiting
- **Default**: 0.05 seconds between requests
- **Range**: 0.01-1.0 seconds
- **Recommendation**: 0.05-0.1 seconds

### Example Optimizations

```bash
# Fast collection (higher resource usage)
./scripts/run_quicknode_3days_collection.sh -b 300 -c 25 -r 0.02

# Conservative collection (lower resource usage)
./scripts/run_quicknode_3days_collection.sh -b 100 -c 8 -r 0.1

# Balanced collection (recommended)
./scripts/run_quicknode_3days_collection.sh -b 200 -c 15 -r 0.05
```

## Monitoring & Logging

### Log Files
- **Main log**: `quicknode_3days_collection_YYYYMMDD_HHMMSS.log`
- **Python log**: `quicknode_3days_collection.log`
- **Statistics**: `quicknode_3days_stats_YYYYMMDD_HHMMSS.json`

### Real-time Monitoring
The script provides real-time progress updates:
```
📦 Ethereum Processing batch: 18,500,000 - 18,500,200
✅ Ethereum Batch completed: 200 blocks, 1,234 transactions, 1,234 receipts
📈 Ethereum Progress: 15,000/518,400 (2.9%)
⏱️ Ethereum Speed: 45.2 blocks/sec, ETA: 18.7 minutes
```

### Final Statistics
```
🎉 QUICKNODE 3-DAY DATA COLLECTION COMPLETED!
================================
📊 GLOBAL STATISTICS:
  Total networks processed: 7
  Total blocks processed: 3,628,800
  Total transactions: 22,345,678
  Total receipts: 22,345,678
  Total errors: 0
  Total time: 45.2 minutes
  Average speed: 1,337.8 blocks/sec

📈 NETWORK BREAKDOWN:
  Ethereum:
    Blocks: 2,073,600
    Transactions: 15,678,901
    Receipts: 15,678,901
    Time: 12.5 minutes
    Speed: 2,765.3 blocks/sec
```

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   ```bash
   # Check PostgreSQL is running
   sudo systemctl status postgresql
   
   # Test connection manually
   psql -h localhost -U postgres -d defi_analytics
   ```

2. **QuickNode API Errors**
   ```bash
   # Test API connection
   ./scripts/run_quicknode_3days_collection.sh -t
   
   # Check API limits in QuickNode dashboard
   ```

3. **Memory Issues**
   ```bash
   # Reduce batch size and concurrency
   ./scripts/run_quicknode_3days_collection.sh -b 50 -c 5
   ```

4. **Rate Limiting**
   ```bash
   # Increase rate limit delay
   ./scripts/run_quicknode_3days_collection.sh -r 0.2
   ```

### Error Recovery

The script includes automatic retry logic, but if it fails:

1. **Check logs** for specific error messages
2. **Verify environment** variables are correct
3. **Test connections** using the `-t` flag
4. **Restart collection** - it will skip already processed blocks

### Performance Issues

1. **Slow Collection**:
   - Increase batch size: `-b 300`
   - Increase concurrency: `-c 25`
   - Decrease rate limit: `-r 0.02`

2. **High Memory Usage**:
   - Decrease batch size: `-b 50`
   - Decrease concurrency: `-c 5`
   - Collect fewer networks at once

3. **API Rate Limits**:
   - Increase rate limit delay: `-r 0.2`
   - Decrease concurrency: `-c 5`
   - Collect networks sequentially

## Data Analysis

### Sample Queries

After collection, you can analyze the data:

```sql
-- Get transaction volume by network
SELECT 
    'ethereum' as network,
    COUNT(*) as transactions,
    SUM(CAST(value AS NUMERIC)) / 1e18 as volume_eth
FROM ethereum_data.transactions 
WHERE timestamp >= EXTRACT(EPOCH FROM NOW() - INTERVAL '3 days');

-- Get gas usage statistics
SELECT 
    network,
    AVG(gas_used) as avg_gas_used,
    MAX(gas_used) as max_gas_used,
    SUM(gas_used) as total_gas_used
FROM (
    SELECT 'ethereum' as network, gas_used FROM ethereum_data.blocks
    UNION ALL
    SELECT 'polygon' as network, gas_used FROM polygon_data.blocks
) stats
GROUP BY network;

-- Get successful vs failed transactions
SELECT 
    network,
    COUNT(*) as total_transactions,
    SUM(CASE WHEN status = 1 THEN 1 ELSE 0 END) as successful,
    SUM(CASE WHEN status = 0 THEN 1 ELSE 0 END) as failed
FROM (
    SELECT 'ethereum' as network, status FROM ethereum_data.receipts
    UNION ALL
    SELECT 'polygon' as network, status FROM polygon_data.receipts
) stats
GROUP BY network;
```

## Integration

### With DeFiMon Analytics

The collected data integrates with the existing DeFiMon analytics infrastructure:

1. **API Integration**: Data is available through the analytics API
2. **Dashboard**: Visualize data in the admin dashboard
3. **Alerts**: Set up monitoring alerts based on collected data
4. **Reports**: Generate automated reports from the data

### Scheduling

To run the collection regularly:

```bash
# Add to crontab for daily collection
0 2 * * * /path/to/defimon.highfunk.uk/scripts/run_quicknode_3days_collection.sh

# Or use systemd timer for more control
```

## Support

For issues and questions:

1. Check the troubleshooting section above
2. Review the log files for detailed error messages
3. Test connections using the `-t` flag
4. Verify your QuickNode API limits and configuration

## License

This script is part of the DeFiMon project and follows the same licensing terms.
