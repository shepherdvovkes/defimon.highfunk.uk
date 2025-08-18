# Ethereum Full Node Setup

This setup provides a complete Ethereum full node using Geth (execution client) and Lighthouse (consensus client) with Docker Compose.

## Prerequisites

- Docker and Docker Compose installed
- Infura API key (free tier available)
- At least 2TB of storage space
- Stable internet connection

## Quick Start

1. **Configure Environment Variables**
   ```bash
   cp .env.example .env
   # Edit .env and add your Infura API key
   ```

2. **Start the Node**
   ```bash
   chmod +x start-node.sh
   ./start-node.sh
   ```

3. **Check Status**
   ```bash
   docker-compose ps
   docker-compose logs -f
   ```

## Services

- **Geth**: Execution client (port 8545)
- **Lighthouse**: Consensus client (port 5052)
- **Prometheus**: Metrics collection (port 9090)
- **Grafana**: Monitoring dashboard (port 3000)

## Ports

- 8545: Geth HTTP RPC
- 8546: Geth WebSocket RPC
- 5052: Lighthouse HTTP API
- 9000: Lighthouse P2P
- 9090: Prometheus
- 3000: Grafana

## Data Directories

- `geth-data/`: Geth blockchain data
- `lighthouse-data/`: Lighthouse beacon chain data
- `jwtsecret`: JWT secret for client communication

## Monitoring

Access monitoring dashboards:
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin123)

## Troubleshooting

- Check logs: `docker-compose logs -f [service]`
- Restart service: `docker-compose restart [service]`
- Full restart: `docker-compose down && docker-compose up -d`
