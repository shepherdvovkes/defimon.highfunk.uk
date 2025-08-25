# Ethereum JWT Authentication Setup

## 🎯 Overview

This directory contains comprehensive documentation and automation scripts for properly configuring JWT authentication between Ethereum execution (Geth) and consensus (Lighthouse) clients in Docker containers, specifically optimized for Google Cloud Platform deployment.

## 🚀 Quick Start

### 1. Generate JWT Secrets
```bash
./scripts/generate-jwt-secrets.sh
```

### 2. Verify Setup
```bash
./scripts/verify-jwt-setup.sh
```

### 3. Deploy to Google Cloud
```bash
# Copy JWT files to server
scp jwtsecret.* vovkes-server:/path/to/ethereum-node/

# Set permissions and restart
ssh vovkes-server "cd /path/to/ethereum-node && chmod 600 jwtsecret.* && docker-compose down && docker-compose up -d"
```

## 📁 Documentation Structure

| File | Purpose | Audience |
|------|---------|----------|
| [**JWT Setup Guide**](JWT_SETUP_GUIDE.md) | Comprehensive setup guide | DevOps Engineers |
| [**Quick Reference**](JWT_QUICK_REFERENCE.md) | Quick commands & troubleshooting | Developers |
| [**Setup Summary**](JWT_SETUP_SUMMARY.md) | Problem solved & solution overview | Project Managers |
| [**README**](README.md) | Detailed usage instructions | System Administrators |
| [**Main README**](MAIN_README.md) | This overview file | All Users |

## 🔧 Scripts

### `generate-jwt-secrets.sh`
- ✅ Generates proper JWT files for both services
- ✅ Sets correct file permissions (600)
- ✅ Updates docker-compose.yml automatically
- ✅ Creates backups of existing files
- ✅ Verifies file sizes and permissions

### `verify-jwt-setup.sh`
- ✅ Checks if containers are running
- ✅ Verifies JWT file sizes and permissions
- ✅ Checks container logs for errors
- ✅ Tests connectivity between services
- ✅ Provides comprehensive status report

## 🎯 Problem Solved

**Previous Issue**: Using the same JWT file for both Geth and Lighthouse services
- **Geth**: Requires RAW binary format (32 bytes)
- **Lighthouse**: Requires HEX string format (64 characters)

**Solution**: Separate JWT files with correct formats and proper Docker volume mounts

## 📊 JWT Requirements

| Service | Format | Size | File | Command |
|---------|--------|------|------|---------|
| **Geth** | RAW binary | 32 bytes | `jwtsecret.raw` | `openssl rand -out jwtsecret.raw 32` |
| **Lighthouse** | HEX string | 64 chars | `jwtsecret.hex` | `openssl rand -hex 32 > jwtsecret.hex` |

## 🐳 Docker Configuration

### Updated Volume Mounts
```yaml
services:
  geth:
    volumes:
      - ./jwtsecret.raw:/root/.ethereum/jwtsecret:ro
      
  lighthouse:
    volumes:
      - ./jwtsecret.hex:/root/.lighthouse/jwtsecret:ro
```

**Key Features**:
- ✅ Separate JWT files for each service
- ✅ Read-only mounts (`:ro`) for security
- ✅ Proper file paths and permissions

## 🔒 Security Features

- **File Permissions**: 600 (owner read/write only)
- **Read-Only Mounts**: Containers cannot modify JWT files
- **Separate Secrets**: Different JWT for each service
- **Secure Generation**: Using OpenSSL for cryptographically secure randomness

## ☁️ Google Cloud Considerations

### Deployment Checklist
- [ ] JWT files copied to server with correct permissions
- [ ] File permissions set to 600 on server
- [ ] Docker Compose configuration updated
- [ ] Services restarted with new configuration
- [ ] JWT setup verified using verification script

### Server Commands
```bash
# On Google Cloud server
cd /path/to/ethereum-node
chmod 600 jwtsecret.*
docker-compose down
docker-compose up -d

# Verify setup
./scripts/verify-jwt-setup.sh
```

## 🧪 Testing & Verification

### Local Testing
```bash
# Generate JWT secrets
./scripts/generate-jwt-secrets.sh

# Verify setup
./scripts/verify-jwt-setup.sh

# Check file sizes
wc -c jwtsecret.*
```

### Container Verification
```bash
# Check JWT files inside containers
docker exec ethereum-geth wc -c /root/.ethereum/jwtsecret
docker exec ethereum-lighthouse wc -c /root/.lighthouse/jwtsecret

# Check container logs
docker logs ethereum-geth | grep -i jwt
docker logs ethereum-lighthouse | grep -i jwt
```

## 🚨 Troubleshooting

### Common Issues

1. **JWT File Size Mismatch**
   ```bash
   # Check file sizes
   wc -c jwtsecret.raw    # Should be 32
   wc -c jwtsecret.hex    # Should be 65
   ```

2. **Permission Denied**
   ```bash
   # Fix permissions
   chmod 600 jwtsecret.*
   ```

3. **Container Authentication Failures**
   ```bash
   # Check container logs
   docker logs ethereum-geth | grep -i jwt
   docker logs ethereum-lighthouse | grep -i jwt
   ```

### Debug Commands
```bash
# Check container status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check JWT files
ls -la jwtsecret.*

# Verify inside containers
docker exec ethereum-geth cat /root/.ethereum/jwtsecret
docker exec ethereum-lighthouse cat /root/.lighthouse/jwtsecret
```

## 📚 References

- [Geth JWT Authentication](geth-jwt-authentication.md) - Official Geth documentation
- [Lighthouse Execution Client](lighthouse-execution-client.md) - Official Lighthouse documentation
- [Ethereum.js JWT](ethereum-js-jwt.md) - JavaScript client documentation
- [Docker Compose v3 Reference](docker-compose-v3-reference.html) - Docker Compose documentation

## 🆘 Support

### Getting Help

1. **Run Verification Script**: `./scripts/verify-jwt-setup.sh`
2. **Check Container Logs**: `docker logs [container-name]`
3. **Review Documentation**: Start with [Quick Reference](JWT_QUICK_REFERENCE.md)
4. **Use Debug Commands**: See troubleshooting section above

### Escalation Path

1. Check this documentation
2. Run verification scripts
3. Review container logs
4. Check file permissions and sizes
5. Verify Docker Compose configuration

## 🎉 Success Metrics

- ✅ **JWT files generated** with correct formats
- ✅ **Docker Compose updated** with proper mounts
- ✅ **File permissions set** to 600
- ✅ **Security improved** with read-only mounts
- ✅ **Google Cloud ready** configuration
- ✅ **Automated scripts** for setup and verification

---

**Last Updated**: August 16, 2025  
**Version**: 1.0  
**Status**: ✅ Complete and Tested
