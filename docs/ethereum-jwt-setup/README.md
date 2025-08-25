# Ethereum JWT Setup Documentation

This directory contains comprehensive documentation and scripts for properly configuring JWT authentication between Ethereum execution (Geth) and consensus (Lighthouse) clients in Docker containers.

## Quick Start

### 1. Generate JWT Secrets

```bash
# Run the JWT generation script
./scripts/generate-jwt-secrets.sh
```

This script will:
- Generate proper JWT files for both services
- Set correct file permissions (600)
- Update docker-compose.yml automatically
- Create backups of existing files

### 2. Verify JWT Setup

```bash
# Verify the JWT configuration
./scripts/verify-jwt-setup.sh
```

This script will:
- Check if containers are running
- Verify JWT file sizes and permissions
- Check container logs for errors
- Test connectivity

## File Structure

```
infrastructure/ethereum-node/
├── jwtsecret.raw          # Geth JWT (32 bytes, RAW format)
├── jwtsecret.hex          # Lighthouse JWT (64 chars, HEX format)
├── docker-compose.yml     # Updated with proper JWT mounts
└── ...
```

## JWT Requirements

| Service | Format | Size | File |
|---------|--------|------|------|
| Geth | RAW binary | 32 bytes | `jwtsecret.raw` |
| Lighthouse | HEX string | 64 characters | `jwtsecret.hex` |

## Docker Compose Configuration

The updated `docker-compose.yml` includes:

- **Geth**: `./jwtsecret.raw:/root/.ethereum/jwtsecret:ro`
- **Lighthouse**: `./jwtsecret.hex:/root/.lighthouse/jwtsecret:ro`

Note the `:ro` flag for read-only access.

## Troubleshooting

### Common Issues

1. **JWT File Size Mismatch**
   ```bash
   # Check file sizes
   wc -c jwtsecret.raw    # Should be 32
   wc -c jwtsecret.hex    # Should be 65 (64 chars + newline)
   ```

2. **Permission Denied**
   ```bash
   # Fix permissions
   chmod 600 jwtsecret.raw jwtsecret.hex
   ```

3. **Container Authentication Failures**
   ```bash
   # Check container logs
   docker logs ethereum-geth | grep -i jwt
   docker logs ethereum-lighthouse | grep -i jwt
   ```

### Debug Commands

```bash
# Check JWT files inside containers
docker exec ethereum-geth wc -c /root/.ethereum/jwtsecret
docker exec ethereum-lighthouse wc -c /root/.lighthouse/jwtsecret

# View JWT content (for debugging)
docker exec ethereum-geth cat /root/.ethereum/jwtsecret
docker exec ethereum-lighthouse cat /root/.lighthouse/jwtsecret

# Check container status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

## Security Best Practices

1. **File Permissions**: Always use 600 permissions for JWT files
2. **Read-Only Mounts**: Use `:ro` flag in Docker volume mounts
3. **Secret Rotation**: Rotate JWT secrets periodically
4. **Access Control**: Limit access to JWT files to necessary users only
5. **Monitoring**: Monitor authentication failures and container logs

## Google Cloud Considerations

When deploying to Google Cloud:

1. **Secret Management**: Store JWT secrets in Google Secret Manager
2. **File Permissions**: Ensure proper file permissions on GCP instances
3. **Container Security**: Use non-root users when possible
4. **Network Policies**: Implement proper network policies for container communication

## Scripts Overview

### `generate-jwt-secrets.sh`
- Generates proper JWT files for both services
- Sets correct file permissions
- Updates docker-compose.yml
- Creates backups of existing files

### `verify-jwt-setup.sh`
- Verifies JWT configuration
- Checks container status
- Validates file sizes and permissions
- Tests connectivity
- Reviews container logs

### `GKE/deploy-gke-ethereum.sh`
- Deploys Ethereum nodes to Google Kubernetes Engine
- Creates GKE cluster with auto-scaling
- Sets up dedicated node pool for Ethereum workloads
- Configures JWT authentication secrets
- Enables monitoring and auto-scaling

## Manual JWT Generation

If you prefer to generate JWT secrets manually:

```bash
# Generate Geth JWT (RAW format)
openssl rand -out jwtsecret.raw 32

# Generate Lighthouse JWT (HEX format)
openssl rand -hex 32 > jwtsecret.hex

# Set permissions
chmod 600 jwtsecret.raw jwtsecret.hex
```

## References

- [JWT Setup Guide](JWT_SETUP_GUIDE.md) - Comprehensive setup guide
- [GKE Deployment Guide](GKE/GKE_DEPLOYMENT_README.md) - GKE deployment guide
- [Geth JWT Authentication](geth-jwt-authentication.md) - Official Geth documentation
- [Lighthouse Execution Client](lighthouse-execution-client.md) - Official Lighthouse documentation
- [Ethereum.js JWT](ethereum-js-jwt.md) - JavaScript client documentation
- [Docker Compose v3 Reference](docker-compose-v3-reference.html) - Docker Compose documentation

## Support

For issues or questions:

1. Run the verification script: `./scripts/verify-jwt-setup.sh`
2. Check container logs: `docker logs [container-name]`
3. Review this documentation
4. Check the troubleshooting section above
