#!/bin/bash

# Production Setup Script for Ethereum Node with HTTPS
set -e

echo "=== Setting up Production Environment ==="
echo "Domain: defimon.highfunk.uk"
echo "IP: 35.225.128.33"
echo ""

cd /opt/defimon

# Create SSL directory
echo "Creating SSL directory..."
sudo mkdir -p ssl logs
sudo chown ubuntu:ubuntu ssl logs

# Generate self-signed SSL certificate (for testing)
echo "Generating SSL certificate..."
sudo -u ubuntu openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/key.pem \
    -out ssl/cert.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=defimon.highfunk.uk"

sudo chmod 600 ssl/key.pem
sudo chmod 644 ssl/cert.pem

echo "✅ SSL certificate generated"

# Copy production files
echo "Setting up production configuration..."
sudo cp /tmp/docker-compose-production.yml docker-compose.yml
sudo cp /tmp/nginx.conf nginx.conf

# Create .htpasswd for metrics protection
echo "Creating metrics authentication..."
sudo -u ubuntu htpasswd -cb .htpasswd admin defimon2024

# Start production services
echo "Starting production services..."
sudo -u ubuntu docker-compose up -d

echo "✅ Production services started"

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 30

# Check service status
echo "=== Service Status ==="
sudo -u ubuntu docker-compose ps

echo ""
echo "=== Production Setup Complete ==="
echo "🌐 Domain: https://defimon.highfunk.uk"
echo "🔒 SSL: Self-signed certificate (replace with Let's Encrypt for production)"
echo "📊 Dashboard: https://defimon.highfunk.uk (Grafana)"
echo "🔗 Ethereum API: https://defimon.highfunk.uk/eth/"
echo "📡 Beacon API: https://defimon.highfunk.uk/beacon/"
echo "📈 Metrics: https://defimon.highfunk.uk/metrics/ (admin/defimon2024)"
echo "🏥 Health: https://defimon.highfunk.uk/health"
echo "📋 Status: https://defimon.highfunk.uk/status"
echo ""
echo "⚠️  Note: Replace self-signed certificate with Let's Encrypt for production use"
echo "📝 To get Let's Encrypt certificate:"
echo "   certbot certonly --standalone -d defimon.highfunk.uk"
