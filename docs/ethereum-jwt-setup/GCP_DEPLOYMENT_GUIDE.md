# Google Cloud Deployment Guide

## 🎯 Overview

This guide explains how to deploy Ethereum nodes (Geth + Lighthouse) on Google Cloud Platform with proper JWT authentication.

## 🚀 Quick Deployment

### 1. Prepare JWT Files Locally

```bash
# Generate JWT secrets
./scripts/generate-jwt-secrets.sh

# Verify JWT setup
./scripts/verify-jwt-setup.sh
```

### 2. Deploy to Google Cloud

```bash
# Update server path in script
vim scripts/deploy-ethereum-nodes-gcp.sh

# Deploy to GCP
./scripts/deploy-ethereum-nodes-gcp.sh
```

## 📋 Prerequisites

- ✅ JWT files generated locally
- ✅ Google Cloud server accessible via SSH
- ✅ Docker and Docker Compose installed on server
- ✅ Proper server path configured in deployment script

## 🔧 Configuration

### Update Server Path

Edit `scripts/deploy-ethereum-nodes-gcp.sh`:

```bash
SERVER_PATH="/path/to/ethereum-node"  # Update this path
```

### JWT Files Structure

| File | Size | Service | Purpose |
|------|------|---------|---------|
| `jwtsecret.raw` | 32 bytes | Geth | Execution client authentication |
| `jwtsecret.hex` | 64 chars | Lighthouse | Consensus client authentication |

## 🚀 Deployment Steps

### Step 1: Local Verification

```bash
# Check JWT files
ls -la infrastructure/ethereum-node/jwtsecret*

# Verify file sizes
wc -c infrastructure/ethereum-node/jwtsecret*

# Check permissions
ls -la infrastructure/ethereum-node/jwtsecret*
```

### Step 2: Deploy to GCP

```bash
# Run deployment script
./scripts/deploy-ethereum-nodes-gcp.sh
```

The script will:
- ✅ Verify JWT files locally
- ✅ Copy files to Google Cloud server
- ✅ Deploy and start services
- ✅ Verify deployment success

### Step 3: Manual Verification (Optional)

```bash
# SSH to server
ssh vovkes-server

# Check container status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Verify JWT files in containers
docker exec ethereum-geth wc -c /root/.ethereum/jwtsecret
docker exec ethereum-lighthouse wc -c /root/.lighthouse/jwtsecret

# Check logs for JWT errors
docker logs ethereum-geth | grep -i jwt
docker logs ethereum-lighthouse | grep -i jwt
```

## 🔍 Troubleshooting

### Common Issues

1. **JWT File Not Found**
   ```bash
   # Check if files exist on server
   ssh vovkes-server "ls -la /path/to/ethereum-node/jwtsecret*"
   ```

2. **Permission Denied**
   ```bash
   # Fix permissions on server
   ssh vovkes-server "chmod 600 /path/to/ethereum-node/jwtsecret*"
   ```

3. **Container Won't Start**
   ```bash
   # Check container logs
   ssh vovkes-server "docker logs ethereum-geth"
   ssh vovkes-server "docker logs ethereum-lighthouse"
   ```

### Debug Commands

```bash
# Check server status
ssh vovkes-server "cd /path/to/ethereum-node && docker-compose ps"

# Restart services
ssh vovkes-server "cd /path/to/ethereum-node && docker-compose restart"

# Full restart
ssh vovkes-server "cd /path/to/ethereum-node && docker-compose down && docker-compose up -d"
```

## 📊 Monitoring

### Health Checks

```bash
# Check Geth sync status
ssh vovkes-server "docker exec ethereum-geth geth attach --exec eth.syncing"

# Check Lighthouse sync status
ssh vovkes-server "docker exec ethereum-lighthouse lighthouse beacon_node --help"

# Monitor logs
ssh vovkes-server "docker logs -f ethereum-geth"
ssh vovkes-server "docker logs -f ethereum-lighthouse"
```

### Performance Monitoring

```bash
# Check resource usage
ssh vovkes-server "docker stats --no-stream"

# Check disk usage
ssh vovkes-server "df -h /path/to/ethereum-node"

# Check memory usage
ssh vovkes-server "free -h"
```

## 🔒 Security Considerations

- ✅ JWT files have 600 permissions
- ✅ Read-only mounts in containers
- ✅ Separate JWT for each service
- ✅ Secure file transfer via SCP
- ✅ Container isolation

## 📝 Post-Deployment Checklist

- [ ] JWT files copied to server
- [ ] File permissions set to 600
- [ ] Services started successfully
- [ ] No JWT errors in logs
- [ ] Containers responding to health checks
- [ ] Sync status verified

## 🆘 Support

### Getting Help

1. **Run verification script**: `./scripts/verify-jwt-setup.sh`
2. **Check deployment logs**: Review script output
3. **SSH to server**: Manual verification
4. **Review this documentation**

### Escalation Path

1. Check local JWT files
2. Verify server connectivity
3. Check container logs
4. Review Docker Compose configuration
5. Check file permissions on server

## 🎉 Success Metrics

- ✅ **JWT authentication working** between services
- ✅ **Containers running** without errors
- ✅ **Services responding** to health checks
- ✅ **Sync status normal** for both clients
- ✅ **No JWT errors** in container logs

---

**Last Updated**: August 17, 2025  
**Version**: 1.0  
**Status**: ✅ Ready for GCP Deployment
