# Ethereum Tiered Storage Strategy

## Overview
This configuration implements a hybrid storage approach for Ethereum node data, separating recent blocks (hot data) from archive blocks (cold data) to optimize performance and cost.

## Storage Tiers

### 🔥 Hot Storage (SSD)
- **Type**: `pd-ssd` (NVMe equivalent performance)
- **Capacity**: 100Gi
- **Purpose**: Store the last 200,000 blocks
- **Performance**: High I/O for recent blockchain data
- **Use Case**: Active syncing, recent transaction lookups

### ❄️ Cold Storage (HDD)
- **Type**: `pd-standard` (standard persistent disk)
- **Capacity**: 2Ti
- **Purpose**: Store archive blocks beyond 200,000
- **Performance**: Lower I/O, cost-effective for bulk storage
- **Use Case**: Historical data, archive queries, long-term storage

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Ethereum Node                           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │   Hot Storage   │    │        Cold Storage            │ │
│  │   (SSD/100Gi)   │    │       (HDD/2Ti)               │ │
│  │                 │    │                                 │ │
│  │ • Recent blocks │    │ • Archive blocks               │ │
│  │ • Last 200k     │    │ • Historical data              │ │
│  │ • Fast access   │    │ • Bulk storage                 │ │
│  └─────────────────┘    └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Benefits

1. **Performance**: Fast access to recent blocks for active operations
2. **Cost Efficiency**: Archive data on cheaper HDD storage
3. **Scalability**: Easy to expand either tier independently
4. **Flexibility**: Can adjust thresholds based on usage patterns

## Deployment

```bash
# Deploy tiered storage
./deploy-tiered-storage.sh

# Check status
kubectl get pvc -n defimon
kubectl get storageclass
```

## Configuration

The storage paths are configured via ConfigMap:
- Hot storage: `/var/lib/ethereum/hot`
- Cold storage: `/var/lib/ethereum/cold`
- Archive threshold: 200,000 blocks

## Next Steps

1. **Deploy Ethereum nodes** with these PVCs mounted
2. **Configure Geth/Lighthouse** to use tiered paths
3. **Implement data migration** logic between hot/cold storage
4. **Monitor performance** and adjust thresholds as needed

## Cost Estimation

- **Hot Storage (SSD)**: ~$17/month for 100Gi
- **Cold Storage (HDD)**: ~$85/month for 2Ti
- **Total**: ~$102/month for tiered storage

*Note: Prices are approximate and may vary by region*
