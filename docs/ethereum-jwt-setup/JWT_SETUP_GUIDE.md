# JWT Setup Guide for Ethereum Nodes on Google Cloud

## Overview

This guide explains the correct JWT setup for Ethereum execution (Geth) and consensus (Lighthouse) clients running in Docker containers on Google Cloud Platform.

## JWT File Requirements

### File Format
- **Geth**: Requires RAW binary format (32 bytes)
- **Lighthouse**: Requires HEX format (64 characters)

### Current Issue
The current setup uses the same JWT file for both services, but they require different formats.

## Correct JWT Setup

### 1. Generate JWT Secret

```bash
# Generate 32 random bytes
openssl rand -hex 32
```

### 2. Create Proper JWT Files

```bash
# Create RAW format for Geth (32 bytes)
openssl rand -out jwtsecret.raw 32

# Create HEX format for Lighthouse (64 characters)
openssl rand -hex 32 > jwtsecret.hex
```

### 3. Verify File Sizes

```bash
# Check Geth JWT file (should be exactly 32 bytes)
wc -c jwtsecret.raw

# Check Lighthouse JWT file (should be exactly 64 characters)
wc -c jwtsecret.hex
```

## Docker Compose Configuration

### Correct Volume Mounts

```yaml
services:
  geth:
    volumes:
      - ./jwtsecret.raw:/root/.ethereum/jwtsecret:ro
    command: >
      --authrpc.jwtsecret /root/.ethereum/jwtsecret
      
  lighthouse:
    volumes:
      - ./jwtsecret.hex:/root/.lighthouse/jwtsecret:ro
    command: >
      --execution-jwt /root/.lighthouse/jwtsecret
```

## Google Cloud Specific Considerations

### 1. File Permissions
- Ensure JWT files have correct permissions (600)
- Use read-only mounts in containers

### 2. Secret Management
- Store JWT secrets in Google Secret Manager
- Mount as environment variables or files

### 3. Container Security
- Use non-root users when possible
- Implement proper network policies

## Troubleshooting

### Common Issues

1. **JWT File Size Mismatch**
   - Geth expects 32 bytes
   - Lighthouse expects 64 characters

2. **Permission Denied**
   - Check file permissions (600)
   - Verify container user access

3. **Authentication Failures**
   - Verify JWT file paths
   - Check file format compatibility

### Debug Commands

```bash
# Check JWT file inside container
docker exec ethereum-geth wc -c /root/.ethereum/jwtsecret
docker exec ethereum-lighthouse wc -c /root/.lighthouse/jwtsecret

# View JWT content (for debugging)
docker exec ethereum-geth cat /root/.ethereum/jwtsecret
docker exec ethereum-lighthouse cat /root/.lighthouse/jwtsecret
```

## Best Practices

1. **Separate JWT Files**: Use different JWT files for each service
2. **Secure Storage**: Store JWT secrets securely (not in version control)
3. **Regular Rotation**: Rotate JWT secrets periodically
4. **Monitoring**: Monitor authentication failures
5. **Backup**: Backup JWT secrets securely

## References

- [Geth JWT Authentication](geth-jwt-authentication.md)
- [Lighthouse Execution Client](lighthouse-execution-client.md)
- [Ethereum.js JWT](ethereum-js-jwt.md)
- [Docker Compose v3 Reference](docker-compose-v3-reference.html)
