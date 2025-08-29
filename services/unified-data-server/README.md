# DEFIMON Unified Data Server

A comprehensive data collection and API server that consolidates blockchain data from multiple networks (Ethereum, L2s, Cosmos, Polkadot) and serves it via a unified REST API.

## 🚀 Features

### Data Collection
- **Ethereum Mainnet**: Real-time block and transaction data
- **L2 Networks**: Polygon, Arbitrum, Optimism, Base, zkSync, Linea, Scroll
- **Cosmos Ecosystem**: Cosmos Hub, Osmosis, Injective, Celestia, Sei, Neutron
- **Polkadot Ecosystem**: Polkadot, Kusama, Moonbeam, Moonriver, Astar, Acala
- **Price Data**: Real-time cryptocurrency prices from multiple sources

### API Endpoints
- **Health Check**: `/health`
- **Networks**: `/api/v1/networks`
- **Blocks**: `/api/v1/networks/{network}/blocks`
- **Transactions**: `/api/v1/networks/{network}/transactions`
- **Network Stats**: `/api/v1/networks/{network}/stats`
- **Protocols**: `/api/v1/protocols`
- **Prices**: `/api/v1/prices`
- **Dashboard**: `/api/v1/dashboard`

### Database Schema
- **Unified Blocks Table**: Cross-network block data
- **Unified Transactions Table**: Cross-network transaction data
- **Protocols Table**: DeFi protocol metrics
- **Price Data Table**: Cryptocurrency price feeds
- **Network Statistics Table**: Aggregated network metrics

## 🛠️ Technology Stack

- **Language**: Rust
- **Framework**: Axum (async web framework)
- **Database**: PostgreSQL with SQLx
- **HTTP Client**: Reqwest
- **Logging**: Tracing
- **Serialization**: Serde

## 📦 Installation

### Prerequisites
- Rust (latest stable)
- PostgreSQL
- Systemd (for service management)

### Quick Start

1. **Clone and navigate to the project**:
   ```bash
   cd services/unified-data-server
   ```

2. **Build the server**:
   ```bash
   cargo build --release
   ```

3. **Set up environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Run the server**:
   ```bash
   ./target/release/unified-data-server
   ```

### Automated Deployment

Use the deployment script for automated setup:

```bash
./scripts/deploy-unified-data-server.sh
```

This script will:
- Check system requirements
- Build the server
- Create systemd service
- Configure environment
- Start the service
- Create monitoring scripts

## ⚙️ Configuration

### Environment Variables

```bash
# Database Configuration
DATABASE_URL=postgresql://postgres:password@localhost:5432/defi_analytics

# API Configuration
API_PORT=8002

# Ethereum Configuration
ETHEREUM_SYNC_ENABLED=true
ETHEREUM_NODE_URL=http://localhost:8545
ETHEREUM_SYNC_INTERVAL=12

# L2 Networks Configuration
L2_SYNC_ENABLED=true
L2_NETWORKS=polygon,arbitrum,optimism,base,zksync,linea,scroll
L2_SYNC_INTERVAL=10

# Cosmos Networks Configuration
COSMOS_SYNC_ENABLED=true
COSMOS_NETWORKS=cosmos,osmosis,injective,celestia,sei,neutron
COSMOS_SYNC_INTERVAL=15

# Polkadot Networks Configuration
POLKADOT_SYNC_ENABLED=true
POLKADOT_NETWORKS=polkadot,kusama,moonbeam,moonriver,astar,acala
POLKADOT_SYNC_INTERVAL=10

# Price Oracle Configuration
PRICE_SYNC_ENABLED=true
PRICE_SYNC_INTERVAL=60
PRICE_ORACLE_SOURCES=coingecko,coinmarketcap,binance
```

## 🔧 API Usage

### Health Check
```bash
curl http://localhost:8002/health
```

### Get All Networks
```bash
curl http://localhost:8002/api/v1/networks
```

### Get Blocks for a Network
```bash
curl "http://localhost:8002/api/v1/networks/ethereum/blocks?limit=10&offset=0"
```

### Get Transactions for a Network
```bash
curl "http://localhost:8002/api/v1/networks/polygon/transactions?limit=10&offset=0"
```

### Get Network Statistics
```bash
curl http://localhost:8002/api/v1/networks/ethereum/stats
```

### Get All Protocols
```bash
curl http://localhost:8002/api/v1/protocols
```

### Get Price Data
```bash
curl http://localhost:8002/api/v1/prices
```

### Get Dashboard Data
```bash
curl http://localhost:8002/api/v1/dashboard
```

## 📊 Data Collection

### Supported Networks

#### Ethereum Ecosystem
- **Ethereum Mainnet**: Full block and transaction data
- **Polygon**: L2 scaling solution
- **Arbitrum**: Optimistic rollup
- **Optimism**: Optimistic rollup
- **Base**: Coinbase L2
- **zkSync**: Zero-knowledge rollup
- **Linea**: Consensys L2
- **Scroll**: zkEVM rollup

#### Cosmos Ecosystem
- **Cosmos Hub**: Interoperability hub
- **Osmosis**: DEX protocol
- **Injective**: DeFi protocol
- **Celestia**: Data availability layer
- **Sei**: Trading-focused blockchain
- **Neutron**: Interchain DeFi

#### Polkadot Ecosystem
- **Polkadot**: Relay chain
- **Kusama**: Canary network
- **Moonbeam**: EVM-compatible parachain
- **Moonriver**: Kusama parachain
- **Astar**: Multi-VM parachain
- **Acala**: DeFi parachain

### Data Sources

#### Price Data
- **CoinGecko**: Primary source for most assets
- **CoinMarketCap**: Fallback source (requires API key)
- **Binance**: Exchange data for trading pairs

#### Blockchain Data
- **Public RPC Endpoints**: For most networks
- **QuickNode**: For enhanced Ethereum data
- **Alchemy**: For Ethereum and L2 data

## 🗄️ Database Schema

### Unified Blocks Table
```sql
CREATE TABLE unified_blocks (
    network VARCHAR(50) NOT NULL,
    number BIGINT NOT NULL,
    hash VARCHAR(66) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    transaction_count INTEGER NOT NULL,
    gas_used VARCHAR(100),
    gas_limit VARCHAR(100),
    miner VARCHAR(42),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (network, number)
);
```

### Unified Transactions Table
```sql
CREATE TABLE unified_transactions (
    network VARCHAR(50) NOT NULL,
    hash VARCHAR(66) NOT NULL,
    block_number BIGINT NOT NULL,
    from_address VARCHAR(42) NOT NULL,
    to_address VARCHAR(42),
    value VARCHAR(100) NOT NULL,
    gas_price VARCHAR(100) NOT NULL,
    gas_used VARCHAR(100) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (network, hash)
);
```

### Protocols Table
```sql
CREATE TABLE protocols (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    network VARCHAR(50) NOT NULL,
    tvl VARCHAR(100),
    volume_24h VARCHAR(100),
    fees_24h VARCHAR(100),
    users_24h BIGINT,
    metadata JSONB,
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(name, network)
);
```

### Price Data Table
```sql
CREATE TABLE price_data (
    id SERIAL PRIMARY KEY,
    asset VARCHAR(20) NOT NULL,
    price_usd VARCHAR(100) NOT NULL,
    volume_24h_usd VARCHAR(100),
    market_cap_usd VARCHAR(100),
    price_change_24h_percent VARCHAR(20),
    price_change_7d_percent VARCHAR(20),
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(asset, last_updated)
);
```

## 🔍 Monitoring

### Service Management
```bash
# Check service status
sudo systemctl status defimon-unified-data-server

# View logs
sudo journalctl -u defimon-unified-data-server -f

# Restart service
sudo systemctl restart defimon-unified-data-server

# Stop service
sudo systemctl stop defimon-unified-data-server
```

### Monitoring Script
```bash
# Run the monitoring script
./monitor.sh
```

This script provides:
- Service status check
- API health check
- Database connection status
- Recent logs
- Resource usage
- Network connections

## 🚀 Deployment

### Local Development
```bash
cargo run
```

### Production Deployment
```bash
# Build for production
cargo build --release

# Run with systemd
sudo systemctl start defimon-unified-data-server
```

### Docker Deployment (Future)
```dockerfile
FROM rust:1.70 as builder
WORKDIR /app
COPY . .
RUN cargo build --release

FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/unified-data-server /usr/local/bin/
EXPOSE 8002
CMD ["unified-data-server"]
```

## 🔧 Development

### Project Structure
```
src/
├── main.rs              # Application entry point
├── config.rs            # Configuration management
├── database.rs          # Database operations
├── collectors/          # Data collection modules
│   ├── mod.rs
│   ├── ethereum.rs      # Ethereum data collector
│   ├── l2.rs           # L2 networks collector
│   ├── cosmos.rs       # Cosmos networks collector
│   ├── polkadot.rs     # Polkadot networks collector
│   └── price.rs        # Price data collector
├── api/                # API routes and handlers
└── models/             # Data models
```

### Adding New Networks

1. **Add network configuration** in `config.rs`
2. **Create collector** in `collectors/` directory
3. **Update main.rs** to include new collector
4. **Add RPC endpoints** and data parsing logic
5. **Test with monitoring script**

### Adding New API Endpoints

1. **Add route** in `main.rs`
2. **Create handler function**
3. **Add database methods** if needed
4. **Update documentation**

## 📈 Performance

### Optimization Tips
- **Connection Pooling**: Configured in database setup
- **Batch Processing**: Implemented for data collection
- **Rate Limiting**: Built into collectors
- **Caching**: Can be added for frequently accessed data
- **Indexing**: Database indexes on frequently queried columns

### Scaling Considerations
- **Horizontal Scaling**: Multiple instances behind load balancer
- **Database Sharding**: By network or time period
- **Caching Layer**: Redis for frequently accessed data
- **Message Queue**: Kafka for data processing pipeline

## 🔒 Security

### Best Practices
- **Environment Variables**: Sensitive data in .env files
- **API Rate Limiting**: Implement rate limiting middleware
- **Input Validation**: Validate all API inputs
- **Database Security**: Use connection pooling and prepared statements
- **Logging**: Secure logging without sensitive data

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Check the monitoring script output
- Review the logs: `sudo journalctl -u defimon-unified-data-server -f`

## 🔮 Roadmap

### Phase 1 (Current)
- ✅ Basic data collection from major networks
- ✅ Unified API endpoints
- ✅ Database schema
- ✅ Monitoring and logging

### Phase 2 (Next)
- 🔄 Advanced analytics and metrics
- 🔄 Real-time WebSocket API
- 🔄 Protocol-specific data collection
- 🔄 Machine learning integration

### Phase 3 (Future)
- 📋 Cross-chain analytics
- 📋 Predictive modeling
- 📋 Advanced visualization
- 📋 Mobile API support
