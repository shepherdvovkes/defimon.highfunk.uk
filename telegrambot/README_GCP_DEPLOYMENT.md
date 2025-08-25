# Telegram Bot Google Cloud Deployment Guide

This guide explains how to deploy the Telegram bot to Google Cloud Platform using Compute Engine VMs instead of Kubernetes (GKE).

## Architecture Overview

The new architecture uses:
- **Google Compute Engine VM** - A lightweight Debian 11 instance
- **Docker Containers** - For easy deployment and management
- **Systemd Services** - For automatic startup and health monitoring
- **Cron Jobs** - For automated health checks and monitoring

## Prerequisites

1. **Google Cloud SDK** installed and authenticated
2. **Google Cloud Project** with billing enabled
3. **Telegram Bot Token** from [@BotFather](https://t.me/botfather)
4. **GCP Project ID** where you want to deploy

## Quick Start

### 1. Set Environment Variables

```bash
export GOOGLE_CLOUD_PROJECT_ID="your-project-id"
export TELEGRAM_BOT_TOKEN="your-bot-token"
```

### 2. Deploy to Google Cloud

```bash
# Make scripts executable
chmod +x deploy-gcp.sh
chmod +x manage-gcp-instance.sh

# Deploy the bot
./deploy-gcp.sh
```

### 3. Configure the Bot

After deployment, you'll need to configure the bot:

```bash
# Connect to the VM
./manage-gcp-instance.sh connect

# Edit the environment file
nano ~/telegram-bot/.env

# Set your bot token and project ID
TELEGRAM_BOT_TOKEN=your_actual_bot_token
GOOGLE_CLOUD_PROJECT_ID=your_actual_project_id

# Deploy the bot on the VM
cd ~/telegram-bot
./deploy-on-vm.sh
```

## Management Commands

The `manage-gcp-instance.sh` script provides easy management:

```bash
# Start the VM
./manage-gcp-instance.sh start

# Stop the VM
./manage-gcp-instance.sh stop

# Restart the VM
./manage-gcp-instance.sh restart

# Connect via SSH
./manage-gcp-instance.sh connect

# View bot logs
./manage-gcp-instance.sh logs

# Check bot status
./manage-gcp-instance.sh status

# Restart the bot
./manage-gcp-instance.sh restart-bot

# Show instance info
./manage-gcp-instance.sh info

# Monitor resources
./manage-gcp-instance.sh monitor

# Delete the instance (permanent)
./manage-gcp-instance.sh delete
```

## Architecture Details

### VM Configuration
- **Instance Type**: e2-micro (cost-optimized)
- **OS**: Debian 11 (Debian Cloud)
- **Disk**: 20GB standard persistent disk
- **Zone**: us-central1-a (configurable)
- **Network**: Default VPC with SSH access

### Startup Process
1. **System Update** - Updates packages and installs dependencies
2. **Docker Installation** - Installs Docker CE and Docker Compose
3. **Google Cloud SDK** - Installs gcloud CLI tools
4. **Monitoring Setup** - Configures health checks and log rotation
5. **Service Configuration** - Sets up systemd services and cron jobs

### Container Management
- **Docker Compose** - For easy container orchestration
- **Health Checks** - Built-in Docker health checks
- **Log Rotation** - Automatic log management
- **Auto-restart** - Systemd service for automatic recovery

## Cost Optimization

### Instance Sizing
- **e2-micro**: ~$6-8/month (recommended for development)
- **e2-small**: ~$12-15/month (for production workloads)
- **e2-medium**: ~$24-30/month (for high-traffic bots)

### Cost Saving Tips
1. **Stop when not in use**: Use `./manage-gcp-instance.sh stop` during off-hours
2. **Use preemptible instances**: For non-critical workloads (not implemented in this setup)
3. **Monitor usage**: Use `./manage-gcp-instance.sh monitor` to track resource usage

## Security Features

### Network Security
- **SSH-only access** - No public HTTP/HTTPS ports
- **Firewall rules** - Restricted to SSH (port 22)
- **Private networking** - Uses default VPC

### Container Security
- **Non-root user** - Bot runs as non-privileged user
- **Read-only mounts** - Minimal file system access
- **Health checks** - Prevents compromised containers from running

### Authentication
- **Google Cloud ADC** - Uses application default credentials
- **Service accounts** - Can be configured for production use
- **Environment variables** - Sensitive data stored securely

## Monitoring and Health Checks

### Automated Monitoring
- **Health checks every 5 minutes** - Via cron job
- **Docker health checks** - Built-in container health monitoring
- **System resource monitoring** - CPU, memory, disk usage

### Log Management
- **Structured logging** - JSON format for easy parsing
- **Log rotation** - Automatic cleanup of old logs
- **Centralized logs** - All logs in `~/telegram-bot/logs/`

### Alerting
- **Health check failures** - Logged to health-check.log
- **Container restarts** - Automatically handled by monitoring scripts
- **Resource exhaustion** - Monitored via resource monitoring

## Troubleshooting

### Common Issues

#### VM Won't Start
```bash
# Check instance status
./manage-gcp-instance.sh info

# Check quotas and billing
gcloud compute instances list --filter="status:TERMINATED"
```

#### Bot Won't Connect
```bash
# Check bot logs
./manage-gcp-instance.sh logs

# Check environment configuration
./manage-gcp-instance.sh connect
cd ~/telegram-bot
cat .env
```

#### Authentication Issues
```bash
# Check Google Cloud authentication
./manage-gcp-instance.sh connect
gcloud auth list
gcloud config get-value project
```

### Debugging Commands

```bash
# View system logs
./manage-gcp-instance.sh connect
sudo journalctl -u docker.service
sudo journalctl -u telegram-bot.service

# Check Docker status
docker system info
docker ps -a
docker logs gcloud-telegram-bot

# Monitor system resources
htop
df -h
free -h
```

## Backup and Recovery

### Data Backup
- **Environment configuration** - Backup `.env` file
- **Log files** - Backup `logs/` directory
- **Docker images** - Can be rebuilt from source

### Recovery Process
1. **Recreate VM** - Use `deploy-gcp.sh` script
2. **Restore configuration** - Copy back `.env` file
3. **Redeploy bot** - Run `deploy-on-vm.sh` on the new VM

## Production Considerations

### Scaling
- **Vertical scaling** - Increase machine type for more resources
- **Horizontal scaling** - Deploy multiple instances behind a load balancer
- **Auto-scaling** - Use Google Cloud managed instance groups

### High Availability
- **Multi-zone deployment** - Deploy across multiple zones
- **Load balancing** - Use Google Cloud Load Balancer
- **Health checks** - Configure external health checks

### Monitoring
- **Google Cloud Monitoring** - Integrate with Cloud Monitoring
- **Logging** - Use Cloud Logging for centralized log management
- **Alerting** - Set up Cloud Monitoring alerts

## Migration from Kubernetes

If you're migrating from a Kubernetes deployment:

1. **Export configuration** - Save your current environment variables
2. **Deploy new VM** - Use `deploy-gcp.sh` script
3. **Migrate data** - Copy configuration and logs
4. **Test functionality** - Verify bot works correctly
5. **Update DNS/load balancers** - Point traffic to new VM
6. **Clean up old resources** - Remove Kubernetes deployments

## Support and Maintenance

### Regular Maintenance
- **System updates** - Run `sudo apt update && sudo apt upgrade` monthly
- **Docker cleanup** - Run `docker system prune` weekly
- **Log rotation** - Automatic via logrotate

### Updates and Upgrades
- **Bot updates** - Pull latest code and redeploy
- **Docker updates** - Update Docker packages as needed
- **Security patches** - Apply security updates promptly

## Conclusion

This deployment approach provides a simple, cost-effective alternative to Kubernetes while maintaining:
- **Easy management** - Simple scripts for common operations
- **Reliability** - Health checks and auto-restart capabilities
- **Security** - Minimal attack surface and secure defaults
- **Scalability** - Easy to scale vertically or horizontally
- **Monitoring** - Built-in health checks and resource monitoring

For most use cases, this VM-based approach will be more than sufficient and significantly easier to manage than a full Kubernetes deployment.
