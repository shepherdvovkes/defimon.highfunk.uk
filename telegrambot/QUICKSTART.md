# Quick Start Guide

Get your Google Cloud Monitor Telegram Bot running in 5 minutes!

## 🚀 Quick Setup

### 1. Prerequisites Check
```bash
# Make sure you have Python 3.8+
python3 --version

# Make sure you have pip
pip3 --version
```

### 2. One-Command Setup
```bash
# Run the automated setup script
./deploy.sh
```

The script will:
- ✅ Check prerequisites
- ✅ Setup Python environment
- ✅ Configure environment variables
- ✅ Test Google Cloud connection
- ✅ Start the bot

### 3. Manual Setup (Alternative)

If you prefer manual setup:

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp env.example .env
# Edit .env with your values

# Test setup
python test_setup.py

# Run bot
python bot.py
```

## 🔑 Required Configuration

### Telegram Bot Token
1. Message [@BotFather](https://t.me/botfather) on Telegram
2. Use `/newbot` command
3. Follow instructions and copy the token
4. Add to `.env`: `TELEGRAM_BOT_TOKEN=your_token_here`

### Google Cloud Project ID
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Copy your Project ID
3. Add to `.env`: `GOOGLE_CLOUD_PROJECT_ID=your_project_id`

### Google Cloud Authentication
```bash
# Option 1: Login with gcloud (recommended)
gcloud auth application-default login

# Option 2: Service account key
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"
```

## 🎯 Test Your Bot

1. Start the bot: `python bot.py`
2. Find your bot on Telegram
3. Send `/start` command
4. Try `/clusters` to see your GKE clusters
5. Try `/billing` to see billing info

## 🐳 Docker Quick Start

```bash
# Build and run with Docker
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

## ❓ Common Issues

### Bot not responding?
- Check if bot token is correct
- Ensure bot is running (check logs)
- Verify you're messaging the right bot

### Google Cloud connection failed?
- Run: `gcloud auth application-default login`
- Check if project ID is correct
- Ensure APIs are enabled (Kubernetes Engine, Billing, Resource Manager)

### No clusters found?
- Verify GKE clusters exist in your project
- Check project ID in `.env`
- Ensure you have proper permissions

## 📚 Next Steps

- Read the full [README.md](README.md) for detailed information
- Customize bot responses in `bot_handlers.py`
- Add new commands for your specific needs
- Set up monitoring and alerts

## 🆘 Need Help?

1. Check the troubleshooting section in README.md
2. Run `python test_setup.py` to diagnose issues
3. Check logs for error messages
4. Verify all prerequisites are met

---

**Happy Monitoring! 🎉**
