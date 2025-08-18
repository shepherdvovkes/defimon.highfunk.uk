#!/bin/bash

# Startup script for Telegram Bot VM
# This script runs when the VM instance starts up

set -e

# Update system and install dependencies
echo "Updating system packages..."
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    unzip \
    wget

# Install Docker
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install Docker Compose (standalone version for compatibility)
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create docker group and add user
usermod -aG docker $USER

# Start and enable Docker service
systemctl start docker
systemctl enable docker

# Install Google Cloud SDK (for authentication and monitoring)
echo "Installing Google Cloud SDK..."
curl https://sdk.cloud.google.com | bash
echo 'source /etc/profile.d/google-cloud-sdk.sh' >> /home/$USER/.bashrc

# Create application directory
mkdir -p /home/$USER/telegram-bot
chown -R $USER:$USER /home/$USER/telegram-bot

# Install monitoring tools
echo "Installing monitoring tools..."
apt-get install -y htop iotop nethogs

# Configure system for better performance
echo "Configuring system for better performance..."

# Increase file descriptor limits
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

# Optimize swap usage
echo "vm.swappiness=10" >> /etc/sysctl.conf

# Create log rotation for Docker
cat > /etc/logrotate.d/docker << EOF
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    size=1M
    missingok
    delaycompress
    copytruncate
}
EOF

# Create systemd service for Telegram bot (optional, for auto-restart)
cat > /etc/systemd/system/telegram-bot.service << EOF
[Unit]
Description=Telegram Bot Service
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/$USER/telegram-bot
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
User=$USER
Group=$USER

[Install]
WantedBy=multi-user.target
EOF

# Enable the service (but don't start it yet - will be started by deployment script)
systemctl enable telegram-bot.service

# Create health check script
cat > /home/$USER/health-check.sh << 'EOF'
#!/bin/bash
# Health check script for Telegram bot

BOT_DIR="/home/$USER/telegram-bot"
LOG_FILE="/home/$USER/telegram-bot/health-check.log"

cd "$BOT_DIR"

# Check if Docker is running
if ! systemctl is-active --quiet docker; then
    echo "$(date): Docker service is not running" >> "$LOG_FILE"
    systemctl restart docker
    exit 1
fi

# Check if Telegram bot container is running
if ! docker ps --format "table {{.Names}}" | grep -q "gcloud-telegram-bot"; then
    echo "$(date): Telegram bot container is not running, restarting..." >> "$LOG_FILE"
    docker-compose up -d
    exit 1
fi

# Check container health
if ! docker inspect gcloud-telegram-bot --format='{{.State.Health.Status}}' | grep -q "healthy"; then
    echo "$(date): Telegram bot container is unhealthy, restarting..." >> "$LOG_FILE"
    docker-compose restart
    exit 1
fi

echo "$(date): Health check passed" >> "$LOG_FILE"
exit 0
EOF

chmod +x /home/$USER/health-check.sh
chown $USER:$USER /home/$USER/health-check.sh

# Set up cron job for health checks
echo "*/5 * * * * /home/$USER/health-check.sh" | crontab -u $USER -

# Create log directory
mkdir -p /home/$USER/telegram-bot/logs
chown -R $USER:$USER /home/$USER/telegram-bot/logs

# Set up log rotation for application logs
cat > /etc/logrotate.d/telegram-bot << EOF
/home/$USER/telegram-bot/logs/*.log {
    rotate 7
    daily
    compress
    size=10M
    missingok
    delaycompress
    copytruncate
    create 644 $USER $USER
}
EOF

echo "Startup script completed successfully!"
echo "System is ready for Telegram bot deployment"
