#!/bin/bash

set -e

echo "🚀 Setting up DEFIMON MVP website with SSL on port 443..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="defimon.highfunk.uk"
PROJECT_DIR="/opt/defimon-mvp"
NGINX_CONF="/etc/nginx/sites-available/defimon"
LETSENCRYPT_DIR="/etc/letsencrypt"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Update system
print_status "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install required packages
print_status "Installing required packages..."
sudo apt-get install -y \
    nginx \
    certbot \
    python3-certbot-nginx \
    nodejs \
    npm \
    git \
    curl \
    wget \
    unzip \
    build-essential

# Create project directory
print_status "Creating project directory..."
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR

# Clone or copy MVP website
print_status "Setting up MVP website..."
if [ -d "/tmp/mvp-website" ]; then
    cp -r /tmp/mvp-website/* $PROJECT_DIR/
else
    # Create basic Next.js app structure
    cd $PROJECT_DIR
    npm init -y
    npm install next react react-dom
fi

# Build the Next.js application
print_status "Building Next.js application..."
cd $PROJECT_DIR
npm run build

# Create systemd service for the application
print_status "Creating systemd service..."
sudo tee /etc/systemd/system/defimon-mvp.service > /dev/null <<EOF
[Unit]
Description=DEFIMON MVP Website
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$PROJECT_DIR
Environment=NODE_ENV=production
Environment=PORT=3000
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create nginx configuration
print_status "Creating nginx configuration..."
sudo tee $NGINX_CONF > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    
    # SSL configuration will be added by certbot
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript;
    
    # Proxy to Next.js app
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # Static files
    location /_next/static/ {
        alias $PROJECT_DIR/.next/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Public files
    location /public/ {
        alias $PROJECT_DIR/public/;
        expires 1y;
        add_header Cache-Control "public";
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Enable nginx site
print_status "Enabling nginx site..."
sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
print_status "Testing nginx configuration..."
sudo nginx -t

# Start services
print_status "Starting services..."
sudo systemctl enable defimon-mvp.service
sudo systemctl start defimon-mvp.service
sudo systemctl enable nginx
sudo systemctl start nginx

# Wait for services to start
print_status "Waiting for services to start..."
sleep 10

# Check if services are running
if systemctl is-active --quiet defimon-mvp.service; then
    print_success "DEFIMON MVP service started successfully"
else
    print_error "DEFIMON MVP service failed to start"
    sudo systemctl status defimon-mvp.service
fi

if systemctl is-active --quiet nginx; then
    print_success "Nginx started successfully"
else
    print_error "Nginx failed to start"
    sudo systemctl status nginx
fi

# Setup SSL with Let's Encrypt
print_status "Setting up SSL certificate with Let's Encrypt..."
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@defimon.highfunk.uk

# Setup automatic renewal
print_status "Setting up automatic SSL renewal..."
sudo crontab -l 2>/dev/null | { cat; echo "0 12 * * * /usr/bin/certbot renew --quiet"; } | sudo crontab -

# Create firewall rules
print_status "Setting up firewall rules..."
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw --force enable

# Create monitoring script
print_status "Creating monitoring script..."
sudo tee /opt/defimon-mvp/monitor.sh > /dev/null <<'EOF'
#!/bin/bash

# Check if services are running
if ! systemctl is-active --quiet defimon-mvp.service; then
    echo "ERROR: DEFIMON MVP service is not running"
    systemctl restart defimon-mvp.service
fi

if ! systemctl is-active --quiet nginx; then
    echo "ERROR: Nginx is not running"
    systemctl restart nginx
fi

# Check SSL certificate
if [ ! -f /etc/letsencrypt/live/defimon.highfunk.uk/fullchain.pem ]; then
    echo "WARNING: SSL certificate not found"
fi

# Check disk space
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "WARNING: Disk usage is ${DISK_USAGE}%"
fi

echo "All services are running normally"
EOF

sudo chmod +x /opt/defimon-mvp/monitor.sh

# Setup monitoring cron job
print_status "Setting up monitoring..."
sudo crontab -l 2>/dev/null | { cat; echo "*/5 * * * * /opt/defimon-mvp/monitor.sh"; } | sudo crontab -

# Final status check
print_status "Performing final status check..."
sleep 5

if curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN | grep -q "200\|301\|302"; then
    print_success "Website is accessible via HTTPS"
else
    print_warning "Website might not be accessible yet (check DNS propagation)"
fi

print_success "Setup completed successfully!"
echo ""
echo "🌐 DEFIMON MVP Website is now available at:"
echo "   https://$DOMAIN"
echo ""
echo "📊 Monitoring:"
echo "   sudo systemctl status defimon-mvp.service"
echo "   sudo systemctl status nginx"
echo "   sudo certbot certificates"
echo ""
echo "🔧 Management:"
echo "   Restart app: sudo systemctl restart defimon-mvp.service"
echo "   Restart nginx: sudo systemctl restart nginx"
echo "   View logs: sudo journalctl -u defimon-mvp.service -f"
echo ""
echo "🔒 SSL Certificate:"
echo "   Renew manually: sudo certbot renew"
echo "   Auto-renewal: Configured via cron"
