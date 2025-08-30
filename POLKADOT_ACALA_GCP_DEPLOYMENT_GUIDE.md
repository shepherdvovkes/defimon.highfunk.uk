# Polkadot & Acala Google Cloud Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying Polkadot and Acala nodes on Google Cloud Platform (GCP) using the automated deployment script.

## Prerequisites

### 1. Google Cloud Account
- Active Google Cloud account with billing enabled
- Google Cloud SDK installed and configured
- Sufficient quota for Compute Engine instances

### 2. Local Requirements
- Google Cloud SDK (`gcloud`)
- Docker (for local testing)
- Bash shell

### 3. Project Configuration
Ensure your `gcp.env` file is properly configured with:
- `GOOGLE_CLOUD_PROJECT_ID`
- `GOOGLE_CLOUD_REGION`
- `GOOGLE_CLOUD_SERVICE_ACCOUNT_EMAIL`
- `GOOGLE_CLOUD_STORAGE_BUCKET`

## Quick Deployment

### Step 1: Verify Configuration
```bash
# Check if gcp.env exists and is properly configured
cat gcp.env

# Verify Google Cloud SDK is installed
gcloud --version
```

### Step 2: Run Deployment Script
```bash
# Navigate to project root
cd /Users/vovkes/defimon.highfunk.uk

# Run the deployment script
./scripts/deploy-polkadot-acala-gcp.sh
```

### Step 3: Monitor Deployment
The script will:
1. Authenticate with Google Cloud
2. Enable required APIs
3. Create service accounts and permissions
4. Set up firewall rules
5. Create persistent disks
6. Deploy Polkadot and Acala instances
7. Configure monitoring and logging
8. Generate deployment summary

## Architecture

### Network Layout
```
Google Cloud Project
├── Polkadot Node (us-central1-a)
│   ├── Instance: defimon-polkadot-node
│   ├── Port: 9944
│   ├── Storage: 100GB SSD
│   └── Monitoring: Prometheus on port 9090
├── Acala Node (us-central1-b)
│   ├── Instance: defimon-acala-node
│   ├── Port: 9949
│   ├── Storage: 100GB SSD
│   └── Monitoring: Prometheus on port 9091
└── Load Balancer
    ├── Health checks
    ├── Backend services
    └── Global forwarding rules
```

### Resource Specifications

#### Polkadot Node
- **Machine Type**: e2-standard-4 (4 vCPU, 16GB RAM)
- **Zone**: us-central1-a
- **Storage**: 100GB SSD persistent disk
- **Network**: Dedicated firewall rules
- **Monitoring**: Prometheus + Cloud Monitoring

#### Acala Node
- **Machine Type**: e2-standard-4 (4 vCPU, 16GB RAM)
- **Zone**: us-central1-b
- **Storage**: 100GB SSD persistent disk
- **Network**: Dedicated firewall rules
- **Monitoring**: Prometheus + Cloud Monitoring

## Post-Deployment

### 1. Verify Deployment
```bash
# Check instance status
gcloud compute instances list --filter="name~defimon-(polkadot|acala)"

# Check firewall rules
gcloud compute firewall-rules list --filter="name~polkadot|name~acala"
```

### 2. Access Nodes
```bash
# Get external IPs
POLKADOT_IP=$(gcloud compute instances describe defimon-polkadot-node \
    --zone=us-central1-a \
    --format="value(networkInterfaces[0].accessConfigs[0].natIP)")

ACALA_IP=$(gcloud compute instances describe defimon-acala-node \
    --zone=us-central1-b \
    --format="value(networkInterfaces[0].accessConfigs[0].natIP)")

echo "Polkadot RPC: http://$POLKADOT_IP:9944"
echo "Acala RPC: http://$ACALA_IP:9949"
```

### 3. Monitor Sync Progress
```bash
# SSH to Polkadot node
gcloud compute ssh defimon-polkadot-node --zone=us-central1-a

# Check sync status
docker logs polkadot-node --tail 50

# SSH to Acala node
gcloud compute ssh defimon-acala-node --zone=us-central1-b

# Check sync status
docker logs acala-node --tail 50
```

### 4. Access Monitoring
- **Polkadot Prometheus**: http://[POLKADOT_IP]:9090
- **Acala Prometheus**: http://[ACALA_IP]:9091
- **Google Cloud Monitoring**: Console → Monitoring

## Management Commands

### Instance Management
```bash
# Start instances
gcloud compute instances start defimon-polkadot-node --zone=us-central1-a
gcloud compute instances start defimon-acala-node --zone=us-central1-b

# Stop instances
gcloud compute instances stop defimon-polkadot-node --zone=us-central1-a
gcloud compute instances stop defimon-acala-node --zone=us-central1-b

# Restart instances
gcloud compute instances reset defimon-polkadot-node --zone=us-central1-a
gcloud compute instances reset defimon-acala-node --zone=us-central1-b
```

### Log Management
```bash
# View instance logs
gcloud logging read "resource.type=gce_instance AND resource.labels.instance_name=defimon-polkadot-node" --limit=50
gcloud logging read "resource.type=gce_instance AND resource.labels.instance_name=defimon-acala-node" --limit=50

# View Docker container logs
gcloud compute ssh defimon-polkadot-node --zone=us-central1-a --command="docker logs polkadot-node --tail 100"
gcloud compute ssh defimon-acala-node --zone=us-central1-b --command="docker logs acala-node --tail 100"
```

### Storage Management
```bash
# Check disk usage
gcloud compute ssh defimon-polkadot-node --zone=us-central1-a --command="df -h"
gcloud compute ssh defimon-acala-node --zone=us-central1-b --command="df -h"

# Create disk snapshots
gcloud compute disks snapshot polkadot-data-disk --snapshot-names=polkadot-backup-$(date +%Y%m%d) --zone=us-central1-a
gcloud compute disks snapshot acala-data-disk --snapshot-names=acala-backup-$(date +%Y%m%d) --zone=us-central1-b
```

## Cost Optimization

### Current Cost Estimation
- **Polkadot Instance**: ~$150-200/month
- **Acala Instance**: ~$150-200/month
- **Storage**: ~$20-40/month
- **Network**: ~$10-20/month
- **Total**: ~$330-460/month

### Cost Reduction Strategies
1. **Use Preemptible Instances**: 60-80% cost reduction (not recommended for production)
2. **Commitment Discounts**: 1-3 year commitments for 20-55% savings
3. **Right-size Instances**: Monitor usage and adjust machine types
4. **Storage Optimization**: Use standard persistent disks instead of SSD for non-critical data

## Troubleshooting

### Common Issues

#### 1. Instance Won't Start
```bash
# Check instance status
gcloud compute instances describe defimon-polkadot-node --zone=us-central1-a

# Check quotas
gcloud compute regions describe us-central1
```

#### 2. Node Not Syncing
```bash
# SSH to instance and check logs
gcloud compute ssh defimon-polkadot-node --zone=us-central1-a
docker logs polkadot-node --tail 100

# Check disk space
df -h
```

#### 3. Network Connectivity Issues
```bash
# Check firewall rules
gcloud compute firewall-rules list --filter="name~polkadot|name~acala"

# Test connectivity
curl -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"system_health","params":[],"id":1}' \
    http://[POLKADOT_IP]:9944
```

#### 4. High Resource Usage
```bash
# Monitor resource usage
gcloud compute ssh defimon-polkadot-node --zone=us-central1-a --command="htop"
gcloud compute ssh defimon-acala-node --zone=us-central1-b --command="htop"
```

## Security Considerations

### Network Security
- Firewall rules restrict access to necessary ports only
- Instances use service accounts with minimal required permissions
- RPC endpoints are exposed but should be protected in production

### Data Security
- Persistent disks are encrypted at rest
- Service account keys are managed securely
- Logs are stored in Google Cloud Storage with access controls

### Recommendations for Production
1. **VPN Access**: Set up Cloud VPN for secure access
2. **Private Network**: Use VPC with private subnets
3. **SSL/TLS**: Configure HTTPS for RPC endpoints
4. **Access Control**: Implement IAM policies for team access
5. **Backup Strategy**: Regular automated backups
6. **Monitoring Alerts**: Set up Cloud Monitoring alerts

## Integration with DEFIMON

### API Integration
```javascript
// Example: Connect to Polkadot node
const { ApiPromise, WsProvider } = require('@polkadot/api');

const provider = new WsProvider('ws://[POLKADOT_IP]:9944');
const api = await ApiPromise.create({ provider });

// Example: Connect to Acala node
const acalaProvider = new WsProvider('ws://[ACALA_IP]:9949');
const acalaApi = await ApiPromise.create({ provider: acalaProvider });
```

### Data Collection
```python
# Example: Collect Polkadot data
import requests

def get_polkadot_data():
    url = f"http://{POLKADOT_IP}:9944"
    payload = {
        "jsonrpc": "2.0",
        "method": "chain_getBlock",
        "params": [],
        "id": 1
    }
    response = requests.post(url, json=payload)
    return response.json()
```

## Support and Maintenance

### Regular Maintenance Tasks
1. **Weekly**: Check disk usage and logs
2. **Monthly**: Review costs and performance
3. **Quarterly**: Update node software versions
4. **Annually**: Review security policies

### Emergency Procedures
1. **Node Failure**: Restart instance and check logs
2. **Data Corruption**: Restore from latest snapshot
3. **Network Issues**: Check firewall rules and connectivity
4. **High Costs**: Review resource usage and optimize

### Contact Information
- **Google Cloud Support**: Available through Google Cloud Console
- **Polkadot Documentation**: https://wiki.polkadot.network/
- **Acala Documentation**: https://wiki.acala.network/

## Conclusion

This deployment provides a robust, scalable infrastructure for running Polkadot and Acala nodes on Google Cloud Platform. The automated script handles the complex setup process, while the monitoring and management tools ensure reliable operation.

For production use, consider implementing additional security measures and backup strategies as outlined in the security considerations section.
