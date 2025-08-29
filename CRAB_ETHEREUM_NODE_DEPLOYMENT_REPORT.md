# 🚀 CRAB SERVER ETHEREUM FULL NODE DEPLOYMENT REPORT

## 📋 Deployment Summary

**Date:** August 28, 2025  
**Server:** Crab (Debian Linux)  
**Status:** ✅ **SUCCESSFULLY DEPLOYED**

## 🎯 What Was Accomplished

### 1. **System Preparation**
- ✅ Added 24GB swap file to increase virtual memory to 39GB total
- ✅ Verified system requirements (15GB RAM + 24GB swap, 397GB storage)
- ✅ Configured data directories on dedicated storage disks

### 2. **Ethereum Client Installation**
- ✅ **Geth v1.16.3** (Execution Client) - Built from source
- ✅ **Lighthouse v7.1.0** (Consensus Client) - Built from source
- ✅ Both clients installed in `/usr/local/bin/`

### 3. **Systemd Services Setup**
- ✅ Geth service configured and running
- ✅ Lighthouse service configured and running
- ✅ Services set to auto-start on boot
- ✅ Proper dependency chain (Lighthouse depends on Geth)

### 4. **Network Configuration**
- ✅ Geth HTTP API: `http://localhost:8545`
- ✅ Geth WebSocket: `ws://localhost:8546`
- ✅ Geth Auth RPC: `http://localhost:8551`
- ✅ Lighthouse HTTP API: `http://localhost:5052`
- ✅ Lighthouse Metrics: `http://localhost:5054`

## 📊 Current System Status

### **Memory Usage**
```
Total RAM: 15GB
Total Swap: 24GB
Available Memory: 11GB
```

### **Storage Usage**
```
Geth Data Disk (/mnt/sda1): 869GB available
Lighthouse Data Disk (/mnt/sdb1): 445GB available
```

### **Service Status**
```
✅ Geth: ACTIVE (PID: 66065)
✅ Lighthouse: ACTIVE (PID: 66126)
```

## 🔧 Configuration Details

### **Geth Configuration**
- **Data Directory:** `/mnt/sda1/geth`
- **Sync Mode:** Snap sync
- **Cache Size:** 8GB
- **Max Peers:** 50
- **JWT Secret:** `/home/vovkes/ethereum/jwtsecret`

### **Lighthouse Configuration**
- **Data Directory:** `/mnt/sdb1/lighthouse`
- **Network:** Mainnet
- **Checkpoint Sync:** Enabled (beaconcha.in)
- **Execution Endpoint:** `http://localhost:8551`

## 🌐 API Endpoints

### **Geth RPC Endpoints**
```bash
# Check sync status
curl http://localhost:8545 -X POST -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'

# Get latest block
curl http://localhost:8545 -X POST -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

### **Lighthouse API Endpoints**
```bash
# Get beacon chain head
curl http://localhost:5052/eth/v1/beacon/headers/head

# Get sync status
curl http://localhost:5052/eth/v1/node/syncing
```

## 📈 Monitoring & Management

### **Service Management Commands**
```bash
# Check service status
sudo systemctl status geth
sudo systemctl status lighthouse

# View logs
sudo journalctl -u geth -f
sudo journalctl -u lighthouse -f

# Restart services
sudo systemctl restart geth
sudo systemctl restart lighthouse
```

### **System Monitoring**
```bash
# Check memory usage
free -h

# Check disk usage
df -h /mnt/sda1 /mnt/sdb1

# Check network ports
sudo ss -tlnp | grep -E '(8545|8551|5052|5054)'
```

## 🔄 Sync Status

### **Current Status**
- **Geth:** Starting initial sync (snap sync)
- **Lighthouse:** Checkpoint sync in progress
- **Estimated Sync Time:** 24-48 hours for full sync

### **Sync Progress Monitoring**
```bash
# Monitor Geth sync
curl -s http://localhost:8545 -X POST -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' | jq

# Monitor Lighthouse sync
curl -s http://localhost:5052/eth/v1/node/syncing | jq
```

## 🛡️ Security Features

- ✅ JWT authentication between execution and consensus clients
- ✅ HTTP API restricted to localhost
- ✅ Proper file permissions on data directories
- ✅ Systemd service isolation

## 📝 Next Steps

1. **Monitor Sync Progress:** Check sync status regularly
2. **Configure Firewall:** Ensure proper network security
3. **Set Up Monitoring:** Implement comprehensive monitoring
4. **Backup Strategy:** Plan for data backup and recovery
5. **Performance Tuning:** Optimize based on system performance

## 🎉 Deployment Success

The Ethereum full node is now successfully deployed and running on the crab server. The node is configured for mainnet and will provide:

- Full Ethereum blockchain data
- JSON-RPC API access
- WebSocket support
- Metrics and monitoring endpoints
- Automatic restart on system reboot

**Total Deployment Time:** ~2 hours  
**Status:** ✅ **OPERATIONAL**

