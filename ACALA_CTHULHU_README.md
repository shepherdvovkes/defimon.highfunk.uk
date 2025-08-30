# Acala Network on Cthulhu - Full Chain Archive Mode

## 🚀 Quick Start

Deploy Acala network on Cthulhu with full chain archive mode using a single command:

```bash
# Quick deployment (recommended)
./scripts/quick-start-acala-cthulhu.sh

# Or full deployment with detailed output
./scripts/deploy-acala-cthulhu-archive.sh
```

## 📋 Overview

This deployment creates a high-performance Acala network node on Google Cloud Platform (Cthulhu zone) with:

- **Full Chain Archive Mode**: Complete blockchain history preserved
- **High-Performance Infrastructure**: e2-standard-8 machine (8 vCPU, 32GB RAM)
- **Minimal Storage**: 10GB SSD for archive data (quota-constrained)
- **Comprehensive Monitoring**: Prometheus metrics and Node Exporter
- **Production-Ready**: RPC, WebSocket, and monitoring endpoints

## 🏗️ Architecture

### Instance Configuration
- **Instance Name**: `defimon-acala-cthulhu-archive`
- **Zone**: `us-central1-a` (us-central1-a)
- **Machine Type**: `e2-standard-8` (8 vCPU, 32GB RAM)
- **Storage**: 10GB SSD persistent disk (minimal due to quota constraints)
- **Network**: High-speed internet with public IP

### Service Endpoints
- **RPC Port**: 9949 (HTTP/JSON-RPC)
- **WebSocket Port**: 9950 (WebSocket/JSON-RPC)
- **Prometheus**: 9092 (Metrics)
- **Node Exporter**: 9100 (System metrics)

### Archive Mode Features
- **Complete History**: All blocks and transactions preserved
- **Full State Trie**: Complete state history available
- **Analytics Ready**: Perfect for data analysis and research
- **No Pruning**: Historical data never deleted

## 📁 Scripts Overview

### Deployment Scripts
- `scripts/deploy-acala-cthulhu-archive.sh` - Full deployment script
- `scripts/quick-start-acala-cthulhu.sh` - Streamlined deployment
- `scripts/manage-acala-cthulhu.sh` - Management and operations

### Configuration Files
- `gcp.env` - Google Cloud configuration
- `ACALA_CTHULHU_DEPLOYMENT_SUMMARY.md` - Deployment details (generated)

## 🛠️ Management Commands

After deployment, use the management script for ongoing operations:

```bash
# Check status
./scripts/manage-acala-cthulhu.sh status

# Start/stop instances
./scripts/manage-acala-cthulhu.sh start
./scripts/manage-acala-cthulhu.sh stop

# View logs
./scripts/manage-acala-cthulhu.sh logs

# Check sync status
./scripts/manage-acala-cthulhu.sh sync

# Monitor resources
./scripts/manage-acala-cthulhu.sh resources

# Create backups
./scripts/manage-acala-cthulhu.sh backup

# Test connectivity
./scripts/manage-acala-cthulhu.sh test

# Show endpoints
./scripts/manage-acala-cthulhu.sh endpoints
```

## 💰 Cost Estimation

**Monthly Costs:**
- Compute (e2-standard-8): ~$300-400
- Storage (10GB SSD): ~$1-2
- Network: ~$10-20
- **Total: ~$311-422/month**

## 🔧 Configuration

### Environment Variables (gcp.env)
```bash
GOOGLE_CLOUD_PROJECT_ID=your-project-id
GOOGLE_CLOUD_REGION=us-central1
GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL=your-service-account@your-project.iam.gserviceaccount.com
GOOGLE_CLOUD_STORAGE_BUCKET=your-storage-bucket
```

### Acala Node Configuration
- **Chain**: Acala mainnet
- **Mode**: Archive (full historical data)
- **Pruning**: Archive (keeps all historical data)
- **CORS**: All origins allowed for development
- **External Access**: Enabled for RPC and WebSocket

## 📊 Monitoring

### Available Metrics
- Node sync status and progress
- Resource usage (CPU, memory, disk)
- Network connectivity
- Container health and logs

### Access Points
- **Prometheus**: `http://[INSTANCE_IP]:9092`
- **Node Exporter**: `http://[INSTANCE_IP]:9100`
- **Google Cloud Monitoring**: Console → Monitoring
- **Logs**: Google Cloud Logging

## 🔒 Security

### Network Security
- Firewall rules restrict access to necessary ports
- Service accounts with minimal required permissions
- RPC endpoints exposed (consider VPN for production)

### Data Security
- Persistent disks encrypted at rest
- Secure service account key management
- Logs stored with access controls

## 🚨 Troubleshooting

### Common Issues

#### Instance Won't Start
```bash
# Check quotas
gcloud compute regions describe us-central1

# Check instance status
./scripts/manage-acala-cthulhu.sh status
```

#### Node Not Syncing
```bash
# Check logs
./scripts/manage-acala-cthulhu.sh logs

# Check disk space
./scripts/manage-acala-cthulhu.sh resources
```

#### Connectivity Issues
```bash
# Test RPC endpoints
./scripts/manage-acala-cthulhu.sh test

# Check firewall rules
gcloud compute firewall-rules list --filter="name~acala-cthulhu"
```

## 🔄 Integration

### API Integration Examples

#### JavaScript (Polkadot.js)
```javascript
const { ApiPromise, WsProvider } = require('@polkadot/api');

// Connect to Acala Cthulhu
const acalaProvider = new WsProvider('ws://[INSTANCE_IP]:9950');
const acalaApi = await ApiPromise.create({ provider: acalaProvider });

// Get latest block
const latestBlock = await acalaApi.rpc.chain.getBlock();
console.log('Latest block:', latestBlock.block.header.number.toString());
```

#### Python
```python
import requests

def get_acala_data(instance_ip):
    url = f"http://{instance_ip}:9949"
    payload = {
        "jsonrpc": "2.0",
        "method": "chain_getBlock",
        "params": [],
        "id": 1
    }
    response = requests.post(url, json=payload)
    return response.json()

# Usage
data = get_acala_data("YOUR_INSTANCE_IP")
print(data)
```

#### cURL Examples
```bash
# Get system health
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"system_health","params":[],"id":1}' \
  http://[INSTANCE_IP]:9949

# Get sync state
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"system_syncState","params":[],"id":1}' \
  http://[INSTANCE_IP]:9949

# Get latest block
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"chain_getBlock","params":[],"id":1}' \
  http://[INSTANCE_IP]:9949
```

## 📈 Scaling

### Vertical Scaling
- Upgrade machine types for more CPU/memory
- Increase disk sizes for more storage
- Adjust based on monitoring data

### Horizontal Scaling
- Deploy additional nodes in different zones
- Use load balancer for distribution
- Implement failover mechanisms

## 🔄 Maintenance

### Regular Tasks
- **Daily**: Check sync status and logs
- **Weekly**: Monitor disk usage and performance
- **Monthly**: Review costs and optimize resources
- **Quarterly**: Update node software versions

### Backup Strategy
- Automated disk snapshots
- Manual backup creation
- Cross-region backup replication
- Regular backup testing

## 📚 Documentation

- [Acala Documentation](https://wiki.acala.network/)
- [Polkadot Documentation](https://wiki.polkadot.network/)
- [Google Cloud Documentation](https://cloud.google.com/docs)
- [Archive Mode Benefits](https://wiki.polkadot.network/docs/maintain-guides-how-to-validate-polkadot#archive-nodes)

## 🆘 Support

### Emergency Procedures
1. **Node Failure**: Restart instance and check logs
2. **Data Corruption**: Restore from latest snapshot
3. **Network Issues**: Check firewall rules and connectivity
4. **High Costs**: Review resource usage and optimize

### Contact Information
- **Google Cloud Support**: Available through Google Cloud Console
- **Acala Community**: [Discord](https://discord.gg/acala)
- **Polkadot Community**: [Discord](https://discord.gg/polkadot)

## 🎯 Next Steps

After successful deployment:

1. **Wait for Sync**: Archive mode takes 24-48 hours to fully sync
2. **Configure Applications**: Update your apps to use the RPC endpoints
3. **Set Up Alerts**: Configure Cloud Monitoring alerts
4. **Implement Backups**: Set up automated backup schedules
5. **Monitor Performance**: Track resource usage and optimize
6. **Security Hardening**: Implement VPN and access controls for production

## 🔍 Archive Mode Benefits

### For Developers
- Complete transaction history for debugging
- Full state access for complex queries
- Historical data analysis capabilities
- No data loss from pruning

### For Researchers
- Complete blockchain dataset
- Historical trend analysis
- Academic research capabilities
- Long-term data preservation

### For Analytics
- Full transaction history
- Complete state snapshots
- Historical metrics
- Data mining capabilities

## 📝 License

This deployment is part of the DEFIMON project. Please refer to the project's main license for usage terms.

---

**Note**: This deployment is designed for development, testing, and research. For production use, implement additional security measures and backup strategies as outlined in the security considerations section.

**Archive Mode Warning**: Archive mode requires significant storage and processing power. Ensure your infrastructure can handle the requirements before deployment.
