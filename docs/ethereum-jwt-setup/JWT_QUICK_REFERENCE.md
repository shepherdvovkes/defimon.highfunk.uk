# JWT Quick Reference

## File Requirements

| Service | Format | Size | Command | File |
|---------|--------|------|---------|------|
| **Geth** | RAW binary | 32 bytes | `openssl rand -out jwtsecret.raw 32` | `jwtsecret.raw` |
| **Lighthouse** | HEX string | 64 chars | `openssl rand -hex 32 > jwtsecret.hex` | `jwtsecret.hex` |

## Docker Compose Mounts

```yaml
services:
  geth:
    volumes:
      - ./jwtsecret.raw:/root/.ethereum/jwtsecret:ro
      
  lighthouse:
    volumes:
      - ./jwtsecret.hex:/root/.lighthouse/jwtsecret:ro
```

## Quick Commands

### Generate JWT Secrets
```bash
./scripts/generate-jwt-secrets.sh
```

### Verify Setup
```bash
./scripts/verify-jwt-setup.sh
```

### Manual Generation
```bash
# Geth
openssl rand -out jwtsecret.raw 32
chmod 600 jwtsecret.raw

# Lighthouse  
openssl rand -hex 32 > jwtsecret.hex
chmod 600 jwtsecret.hex
```

### Debug Commands
```bash
# Check file sizes
wc -c jwtsecret.raw    # Should be 32
wc -c jwtsecret.hex    # Should be 65

# Check container JWT files
docker exec ethereum-geth wc -c /root/.ethereum/jwtsecret
docker exec ethereum-lighthouse wc -c /root/.lighthouse/jwtsecret

# Check permissions
ls -la jwtsecret.*
```

## Common Issues & Solutions

| Issue | Symptom | Solution |
|-------|---------|----------|
| **JWT Size Mismatch** | Authentication failures | Generate correct format files |
| **Permission Denied** | Container can't read JWT | `chmod 600 jwtsecret.*` |
| **Wrong Format** | Service won't start | Use RAW for Geth, HEX for Lighthouse |
| **File Not Found** | Container startup fails | Check file paths in docker-compose.yml |

## Security Checklist

- [ ] JWT files have 600 permissions
- [ ] Files are mounted as read-only (`:ro`)
- [ ] Different JWT files for each service
- [ ] JWT files not committed to version control
- [ ] Regular JWT rotation implemented
