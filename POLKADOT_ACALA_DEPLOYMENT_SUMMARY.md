# Polkadot & Acala Google Cloud Deployment Summary

## Deployment Information
- **Project ID**: defimon-analytics-platform
- **Region**: us-central1
- **Deployment Date**: Fri Aug 29 21:50:47 EEST 2025

## Instance Details

### Polkadot Node
- **Instance Name**: defimon-polkadot-node
- **Zone**: us-central1-a
- **Machine Type**: e2-standard-4
- **External IP**: 34.172.250.71
- **RPC Endpoint**: http://34.172.250.71:9944
- **Prometheus**: http://34.172.250.71:9090

### Acala Node
- **Instance Name**: defimon-acala-node
- **Zone**: us-central1-b
- **Machine Type**: e2-standard-4
- **External IP**: 34.136.225.15
- **RPC Endpoint**: http://34.136.225.15:9949
- **Prometheus**: http://34.136.225.15:9091

## Storage
- **Polkadot Data Disk**: 100GB SSD
- **Acala Data Disk**: 100GB SSD

## Network Configuration
- **Polkadot Port**: 9944
- **Acala Port**: 9949
- **Firewall Rules**: polkadot-node-rule, acala-node-rule, monitoring-rule

## Monitoring
- **Cloud Monitoring**: Enabled
- **Log Sinks**: polkadot-acala-logs
- **Storage Bucket**: defimon-ethereum-data-bucket

## Management Commands

### Check Instance Status
```bash
gcloud compute instances list --filter="name~defimon-(polkadot|acala)"
```

### SSH to Instances
```bash
# Polkadot
gcloud compute ssh defimon-polkadot-node --zone=us-central1-a

# Acala
gcloud compute ssh defimon-acala-node --zone=us-central1-b
```

### View Logs
```bash
# Polkadot logs
gcloud logging read "resource.type=gce_instance AND resource.labels.instance_name=defimon-polkadot-node" --limit=50

# Acala logs
gcloud logging read "resource.type=gce_instance AND resource.labels.instance_name=defimon-acala-node" --limit=50
```

### Stop Instances
```bash
gcloud compute instances stop defimon-polkadot-node --zone=us-central1-a
gcloud compute instances stop defimon-acala-node --zone=us-central1-b
```

### Start Instances
```bash
gcloud compute instances start defimon-polkadot-node --zone=us-central1-a
gcloud compute instances start defimon-acala-node --zone=us-central1-b
```

## Cost Estimation
- **Polkadot Instance**: ~50-200/month
- **Acala Instance**: ~50-200/month
- **Storage**: ~0-40/month
- **Network**: ~0-20/month
- **Total Estimated**: ~30-460/month

## Next Steps
1. Wait for nodes to sync (can take 24-48 hours)
2. Configure your application to use the RPC endpoints
3. Set up alerts in Cloud Monitoring
4. Consider setting up automated backups
5. Monitor resource usage and adjust machine types if needed
