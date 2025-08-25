#!/bin/bash

# Startup script for Telegram Bot VM
set -e

# Update system and install dependencies
echo "Updating system packages..."
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common unzip wget

# Install Docker
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install Docker Compose
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create docker group and add user
usermod -aG docker $USER

# Start and enable Docker service
systemctl start docker
systemctl enable docker

# Create application directory
mkdir -p /home/$USER/telegram-bot
chown -R $USER:$USER /home/$USER/telegram-bot

# Install monitoring tools
echo "Installing monitoring tools..."
apt-get install -y htop iotop nethogs

# Create log directory
mkdir -p /home/$USER/telegram-bot/logs
chown -R $USER:$USER /home/$USER/telegram-bot/logs

echo "Startup script completed successfully!"
echo "System is ready for Telegram bot deployment"
