# Telegram Bot Google Cloud Deployment Checklist

## Pre-Deployment Checklist

- [ ] Google Cloud SDK installed and authenticated
- [ ] Google Cloud Project created with billing enabled
- [ ] Required APIs enabled (Compute Engine API)
- [ ] Telegram Bot Token obtained from [@BotFather](https://t.me/botfather)
- [ ] GCP Project ID noted down
- [ ] Sufficient quota for VM instances in selected zone

## Deployment Steps

### 1. Environment Setup
- [ ] Set environment variables:
  ```bash
  export GOOGLE_CLOUD_PROJECT_ID="your-project-id"
  export TELEGRAM_BOT_TOKEN="your-bot-token"
  ```
- [ ] Verify gcloud authentication:
  ```bash
  gcloud auth list
  gcloud config get-value project
  ```

### 2. Initial Deployment
- [ ] Make scripts executable:
  ```bash
  chmod +x deploy-gcp.sh manage-gcp-instance.sh
  ```
- [ ] Run deployment script:
  ```bash
  ./deploy-gcp.sh
  ```
- [ ] Wait for VM creation and startup (5-10 minutes)
- [ ] Verify VM is running:
  ```bash
  ./manage-gcp-instance.sh info
  ```

### 3. Bot Configuration
- [ ] Connect to VM:
  ```bash
  ./manage-gcp-instance.sh connect
  ```
- [ ] Navigate to bot directory:
  ```bash
  cd ~/telegram-bot
  ```
- [ ] Edit environment file:
  ```bash
  nano .env
  ```
- [ ] Set required variables:
  - `TELEGRAM_BOT_TOKEN=your_actual_bot_token`
  - `GOOGLE_CLOUD_PROJECT_ID=your_actual_project_id`
- [ ] Save and exit editor
- [ ] Deploy bot on VM:
  ```bash
  ./deploy-on-vm.sh
  ```

### 4. Verification
- [ ] Check bot status:
  ```bash
  ./manage-gcp-instance.sh status
  ```
- [ ] View bot logs:
  ```bash
  ./manage-gcp-instance.sh logs
  ```
- [ ] Test bot functionality in Telegram
- [ ] Verify Google Cloud monitoring is working

## Post-Deployment Checklist

### Monitoring Setup
- [ ] Health checks are running (every 5 minutes)
- [ ] Log rotation is configured
- [ ] Systemd service is enabled
- [ ] Cron jobs are active

### Security Verification
- [ ] Only SSH port (22) is open
- [ ] Bot runs as non-root user
- [ ] Environment variables are properly set
- [ ] No sensitive data in logs

### Performance Verification
- [ ] VM resources are adequate
- [ ] Docker containers are healthy
- [ ] Bot responds to commands
- [ ] No excessive resource usage

## Troubleshooting Checklist

### Common Issues
- [ ] VM won't start - Check quotas and billing
- [ ] Bot won't connect - Verify token and project ID
- [ ] Authentication fails - Check gcloud auth
- [ ] Container won't start - Check Docker and logs
- [ ] Health checks fail - Verify monitoring setup

### Debug Commands
- [ ] Instance status: `./manage-gcp-instance.sh info`
- [ ] Bot logs: `./manage-gcp-instance.sh logs`
- [ ] Bot status: `./manage-gcp-instance.sh status`
- [ ] Resource monitoring: `./manage-gcp-instance.sh monitor`
- [ ] SSH access: `./manage-gcp-instance.sh connect`

## Maintenance Checklist

### Regular Tasks
- [ ] Check bot logs weekly
- [ ] Monitor resource usage monthly
- [ ] Update system packages quarterly
- [ ] Review security settings annually
- [ ] Backup configuration files

### Updates
- [ ] Bot code updates
- [ ] Docker image updates
- [ ] System security patches
- [ ] Google Cloud SDK updates

## Cost Optimization

### Monitoring
- [ ] Track monthly costs
- [ ] Monitor resource usage
- [ ] Stop VM during off-hours if possible
- [ ] Consider preemptible instances for non-critical workloads

### Scaling
- [ ] Evaluate if current machine type is adequate
- [ ] Consider auto-scaling for production workloads
- [ ] Monitor for resource bottlenecks

## Success Criteria

- [ ] Bot responds to Telegram commands
- [ ] Google Cloud monitoring is functional
- [ ] VM starts and stops correctly
- [ ] Health checks pass consistently
- [ ] Logs are properly rotated
- [ ] No security vulnerabilities
- [ ] Cost is within budget
- [ ] Performance meets requirements

## Rollback Plan

If deployment fails:
1. Stop and delete the VM instance
2. Check error logs and fix issues
3. Re-run deployment script
4. Verify all components are working
5. Test bot functionality thoroughly

## Support Resources

- [ ] Google Cloud documentation
- [ ] Docker documentation
- [ ] Telegram Bot API documentation
- [ ] Project README files
- [ ] Deployment logs and error messages
