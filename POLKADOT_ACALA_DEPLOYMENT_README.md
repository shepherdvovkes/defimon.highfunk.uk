# Polkadot & Acala Google Cloud Deployment

## 🚀 Quick Start

Deploy Polkadot and Acala nodes on Google Cloud Platform with a single command:

```bash
# Quick deployment (recommended)
./scripts/quick-deploy-polkadot-acala.sh

# Or full deployment with detailed output
./scripts/deploy-polkadot-acala-gcp.sh
```

## 📋 Prerequisites

- Google Cloud account with billing enabled
- Google Cloud SDK installed (`gcloud`)
- Properly configured `gcp.env` file
- Sufficient quota for Compute Engine instances

## 🏗️ Architecture

The deployment creates a robust infrastructure with:

### Polkadot Node
- **Instance**: `defimon-polkadot-node` (us-central1-a)
- **Machine Type**: e2-standard-4 (4 vCPU, 16GB RAM)
- **Storage**: 100GB SSD persistent disk
- **Port**: 9944 (RPC/WebSocket)
- **Monitoring**: Prometheus on port 9090

### Acala Node
- **Instance**: `defimon-acala-node` (us-central1-b)
- **Machine Type**: e2-standard-4 (4 vCPU, 16GB RAM)
- **Storage**: 100GB SSD persistent disk
- **Port**: 9949 (RPC/WebSocket)
- **Monitoring**: Prometheus on port 9091

### Infrastructure Components
- Firewall rules for secure access
- Load balancer for high availability
- Cloud Monitoring and logging
- Automated backups and snapshots

## 📁 Scripts Overview

### Deployment Scripts
- `scripts/deploy-polkadot-acala-gcp.sh` - Full deployment script
- `scripts/quick-deploy-polkadot-acala.sh` - Streamlined deployment
- `scripts/manage-polkadot-acala.sh` - Management and operations

### Configuration Files
- `gcp.env` - Google Cloud configuration
- `POLKADOT_ACALA_DEPLOYMENT_SUMMARY.md` - Deployment details (generated)
- `POLKADOT_ACALA_GCP_DEPLOYMENT_GUIDE.md` - Comprehensive guide

## 🛠️ Management Commands

After deployment, use the management script for ongoing operations:

```bash
# Check status
./scripts/manage-polkadot-acala.sh status

# Start/stop instances
./scripts/manage-polkadot-acala.sh start
./scripts/manage-polkadot-acala.sh stop

# View logs
./scripts/manage-polkadot-acala.sh logs polkadot
./scripts/manage-polkadot-acala.sh logs acala

# Check sync status
./scripts/manage-polkadot-acala.sh sync

# Monitor resources
./scripts/manage-polkadot-acala.sh resources

# Create backups
./scripts/manage-polkadot-acala.sh backup

# Test connectivity
./scripts/manage-polkadot-acala.sh test

# Show endpoints
./scripts/manage-polkadot-acala.sh endpoints
```

## 💰 Cost Estimation

**Monthly Costs:**
- Polkadot Instance: ~$150-200
- Acala Instance: ~$150-200
- Storage (200GB SSD): ~$20-40
- Network: ~$10-20
- **Total: ~$330-460/month**

## 🔧 Configuration

### Environment Variables (gcp.env)
```bash
GOOGLE_CLOUD_PROJECT_ID=your-project-id
GOOGLE_CLOUD_REGION=us-central1
GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL=your-service-account@your-project.iam.gserviceaccount.com
GOOGLE_CLOUD_STORAGE_BUCKET=your-storage-bucket
```

### Node Configuration
- **Polkadot**: Archive node with full RPC/WebSocket access
- **Acala**: Archive node with full RPC/WebSocket access
- **Pruning**: Archive mode (keeps all historical data)
- **CORS**: All origins allowed for development

## 📊 Monitoring

### Available Metrics
- Node sync status and progress
- Resource usage (CPU, memory, disk)
- Network connectivity
- Container health and logs

### Access Points
- **Polkadot Prometheus**: `http://[POLKADOT_IP]:9090`
- **Acala Prometheus**: `http://[ACALA_IP]:9091`
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
./scripts/manage-polkadot-acala.sh status
```

#### Node Not Syncing
```bash
# Check logs
./scripts/manage-polkadot-acala.sh logs polkadot
./scripts/manage-polkadot-acala.sh logs acala

# Check disk space
./scripts/manage-polkadot-acala.sh resources
```

#### Connectivity Issues
```bash
# Test RPC endpoints
./scripts/manage-polkadot-acala.sh test

# Check firewall rules
gcloud compute firewall-rules list --filter="name~polkadot|name~acala"
```

## 🔄 Integration

### API Integration Examples

#### JavaScript (Polkadot.js)
```javascript
const { ApiPromise, WsProvider } = require('@polkadot/api');

// Connect to Polkadot
const polkadotProvider = new WsProvider('ws://[POLKADOT_IP]:9944');
const polkadotApi = await ApiPromise.create({ provider: polkadotProvider });

// Connect to Acala
const acalaProvider = new WsProvider('ws://[ACALA_IP]:9949');
const acalaApi = await ApiPromise.create({ provider: acalaProvider });
```

#### Python
```python
import requests

def get_polkadot_data():
    url = f"http://[POLKADOT_IP]:9944"
    payload = {
        "jsonrpc": "2.0",
        "method": "chain_getBlock",
        "params": [],
        "id": 1
    }
    response = requests.post(url, json=payload)
    return response.json()
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
- **Weekly**: Check disk usage and logs
- **Monthly**: Review costs and performance
- **Quarterly**: Update node software versions
- **Annually**: Review security policies

### Backup Strategy
- Automated disk snapshots
- Manual backup creation
- Cross-region backup replication
- Regular backup testing

## 📚 Documentation

- [Polkadot Documentation](https://wiki.polkadot.network/)
- [Acala Documentation](https://wiki.acala.network/)
- [Google Cloud Documentation](https://cloud.google.com/docs)
- [Deployment Guide](POLKADOT_ACALA_GCP_DEPLOYMENT_GUIDE.md)

## 🆘 Support

### Emergency Procedures
1. **Node Failure**: Restart instance and check logs
2. **Data Corruption**: Restore from latest snapshot
3. **Network Issues**: Check firewall rules and connectivity
4. **High Costs**: Review resource usage and optimize

### Contact Information
- **Google Cloud Support**: Available through Google Cloud Console
- **Polkadot Community**: [Discord](https://discord.gg/polkadot)
- **Acala Community**: [Discord](https://discord.gg/acala)

## 🎯 Next Steps

After successful deployment:

1. **Wait for Sync**: Nodes take 24-48 hours to fully sync
2. **Configure Applications**: Update your apps to use the RPC endpoints
3. **Set Up Alerts**: Configure Cloud Monitoring alerts
4. **Implement Backups**: Set up automated backup schedules
5. **Monitor Performance**: Track resource usage and optimize
6. **Security Hardening**: Implement VPN and access controls for production

## 📝 License

This deployment is part of the DEFIMON project. Please refer to the project's main license for usage terms.

---

**Note**: This deployment is designed for development and testing. For production use, implement additional security measures and backup strategies as outlined in the security considerations section.
