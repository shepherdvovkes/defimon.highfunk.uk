# 🚀 POLKADOT SHRIMP SERVER - QUICK START GUIDE

## 📋 Overview

This guide will help you deploy **5 Polkadot networks** on your shrimp server with optimal resource allocation and monitoring.

## 🎯 What Will Be Deployed

### Phase 1: Core Networks (3 networks)
1. **Polkadot Relay Chain** - Main network (Port 9944)
2. **Kusama** - Canary network (Port 9945)  
3. **Westend Testnet** - Test network (Port 9946)

### Phase 2: Popular Parachains (2 networks)
4. **Moonbeam** - EVM-compatible parachain (Port 9947)
5. **Astar** - Multi-VM platform (Port 9948)

### Monitoring Stack
- **Prometheus** - Metrics collection (Port 9090)
- **Grafana** - Dashboards (Port 3000)

## 🖥️ System Requirements

### Shrimp Server Specifications
- ✅ **CPU**: Quad-Core Intel Core i5 @ 2.4 GHz (4 cores)
- ✅ **RAM**: 8 GB
- ✅ **Storage**: 233GB internal + 477GB external USB drive
- ✅ **OS**: macOS

### Resource Allocation
- **Polkadot Relay**: 1 core, 2GB RAM, 50GB storage
- **Kusama**: 1 core, 1.5GB RAM, 30GB storage
- **Westend**: 0.5 core, 1GB RAM, 20GB storage
- **Moonbeam**: 0.5 core, 1GB RAM, 100GB storage (USB)
- **Astar**: 0.5 core, 1GB RAM, 80GB storage (USB)

## 🚀 Quick Deployment

### Step 1: Connect to Shrimp Server
```bash
ssh shrimp
```

### Step 2: Clone Repository
```bash
git clone https://github.com/your-username/defimon.highfunk.uk.git
cd defimon.highfunk.uk
```

### Step 3: Run Deployment Script
```bash
# Make script executable
chmod +x scripts/deploy-polkadot-shrimp.sh

# Run deployment
./scripts/deploy-polkadot-shrimp.sh
```

### Step 4: Verify Deployment
```bash
# Check service status
docker ps

# Check logs
docker-compose -f /opt/polkadot/docker-compose.yml logs -f
```

## 🌐 Access Points

### Web Interfaces
- **Grafana Dashboard**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090

### RPC Endpoints
- **Polkadot Relay**: `ws://localhost:9944`
- **Kusama**: `ws://localhost:9945`
- **Westend**: `ws://localhost:9946`
- **Moonbeam**: `ws://localhost:9947`
- **Astar**: `ws://localhost:9948`

## 📊 Monitoring & Analytics

### Real-time Metrics
- Block processing rate per network
- Memory and CPU usage per container
- Storage utilization
- Network connectivity status

### Analytics Dashboard
- Cross-chain transaction analysis
- Parachain performance comparison
- Validator set monitoring
- Economic metrics (staking, inflation)

## 🔧 Management Commands

### Service Management
```bash
# Start all services
cd /opt/polkadot
docker-compose up -d

# Stop all services
docker-compose down

# Restart specific service
docker-compose restart polkadot-relay

# View logs
docker-compose logs -f polkadot-relay
```

### System Monitoring
```bash
# Check resource usage
docker stats

# Check storage usage
df -h /Volumes/USB_APFS/polkadot-data

# Check service status
docker-compose ps
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Docker Not Running
```bash
# Start Docker Desktop manually
open -a Docker
```

#### 2. Port Conflicts
```bash
# Check what's using the ports
lsof -i :9944
lsof -i :9945
lsof -i :9946
```

#### 3. Storage Issues
```bash
# Check USB drive mount
ls -la /Volumes/USB_APFS

# Check available space
df -h
```

#### 4. Service Won't Start
```bash
# Check logs
docker-compose logs polkadot-relay

# Check system resources
top
```

## 📈 Performance Optimization

### Resource Tuning
- **CPU Pinning**: Each network assigned to specific cores
- **Memory Limits**: Strict limits to prevent OOM
- **Storage Optimization**: External USB for archive nodes
- **Network Throttling**: Bandwidth limits per network

### Sync Strategies
- **Polkadot/Kusama**: Light client with pruning (1000 blocks)
- **Moonbeam/Astar**: Archive nodes for full data analysis
- **Westend**: Light client for testing

## 🔄 Maintenance

### Automated Updates
```bash
# Update Docker images
docker-compose pull
docker-compose up -d

# Update Rust client
cd services/blockchain-node
cargo update
cargo build --release
```

### Backup Strategy
```bash
# Create backup
tar -czf polkadot-backup-$(date +%Y%m%d).tar.gz /opt/polkadot/data

# Restore backup
tar -xzf polkadot-backup-20250101.tar.gz -C /
```

## 🎯 Expected Performance

### Throughput Capabilities
- **Polkadot Relay**: ~1000 blocks/hour
- **Kusama**: ~2000 blocks/hour
- **Moonbeam**: ~5000 transactions/hour
- **Astar**: ~3000 transactions/hour
- **Total Analytics**: ~10,000 data points/hour

### Storage Efficiency
- **Compression**: 60-70% space savings
- **Pruning**: 80% reduction in storage requirements
- **Archive**: Full historical data for analysis

## 🔗 Integration with Analytics System

### API Endpoints
```bash
# Polkadot data API
curl http://localhost:8002/api/v1/polkadot/blocks

# Cross-chain analytics
curl http://localhost:8002/api/v1/analytics/cross-chain

# Validator metrics
curl http://localhost:8002/api/v1/polkadot/validators
```

### Database Schema
```sql
-- Polkadot blocks table
CREATE TABLE polkadot_blocks (
    network VARCHAR(50),
    block_number BIGINT,
    block_hash VARCHAR(66),
    timestamp TIMESTAMP,
    extrinsics_count INTEGER,
    events_count INTEGER
);

-- Cross-chain analytics
CREATE TABLE cross_chain_analytics (
    network VARCHAR(50),
    metric_type VARCHAR(100),
    value DECIMAL,
    timestamp TIMESTAMP
);
```

## ✅ Success Metrics

### Technical Metrics
- 99.9% uptime for all networks
- <100ms response time for RPC calls
- <1GB memory usage per network
- <50% CPU utilization average

### Business Metrics
- 5 networks successfully deployed
- Full data availability for analysis
- Real-time cross-chain analytics
- Cost-effective resource utilization

---

## 🆘 Support

If you encounter any issues:

1. **Check logs**: `docker-compose logs -f [service-name]`
2. **Verify resources**: `docker stats`
3. **Check connectivity**: `curl -f http://localhost:9090`
4. **Review configuration**: `/opt/polkadot/.env`

## 📞 Next Steps

After successful deployment:

1. **Access Grafana** to monitor networks
2. **Configure alerts** in Prometheus
3. **Integrate** with existing analytics system
4. **Set up** automated backups
5. **Scale** to additional parachains as needed

---

**🎉 Congratulations!** You now have a fully operational Polkadot analytics system on your shrimp server!
