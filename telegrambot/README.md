# Google Cloud Monitor Telegram Bot

A Python-based Telegram bot that provides real-time monitoring and information about your Google Cloud Platform (GCP) clusters, nodes, and billing information.

## Features

- 📊 **Cluster Monitoring**: View all GKE clusters with status, version, and node count
- 🖥️ **Node Information**: Detailed node pool information including machine types and autoscaling
- 💰 **Billing Overview**: Monitor billing status and get cost optimization recommendations
- 📈 **Cost Analysis**: Analyze spending patterns and get optimization suggestions
- 🔍 **System Status**: Overall health check of your GCP infrastructure
- 🎯 **Interactive Interface**: Inline buttons for easy navigation between different views

## Commands

- `/start` - Welcome message and main menu
- `/help` - Detailed help and command reference
- `/clusters` - List all GKE clusters
- `/nodes` - Show cluster node information
- `/billing` - Display billing overview
- `/costs` - Cost analysis and optimization tips
- `/status` - Overall system health status

## Prerequisites

- Python 3.8+
- Google Cloud Platform account with GKE clusters
- Telegram Bot Token (from [@BotFather](https://t.me/botfather))
- Google Cloud SDK or service account credentials

## Installation

### 1. Clone and Setup

```bash
cd telegrambot
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Environment Configuration

Copy the example environment file and configure it:

```bash
cp env.example .env
```

Edit `.env` with your configuration:

```bash
# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here

# Google Cloud Configuration
GOOGLE_CLOUD_PROJECT_ID=your_gcp_project_id_here

# Optional: Restrict access to specific users
ALLOWED_TELEGRAM_USERS=123456789,987654321
```

### 3. Google Cloud Authentication

#### Option A: Application Default Credentials (Recommended)

```bash
gcloud auth application-default login
```

#### Option B: Service Account Key

1. Create a service account in GCP Console
2. Grant necessary roles:
   - `Kubernetes Engine Admin`
   - `Billing Account User`
   - `Project Viewer`
3. Download the JSON key file
4. Set environment variable:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/service-account-key.json"
```

### 4. Create Telegram Bot

1. Message [@BotFather](https://t.me/botfather) on Telegram
2. Use `/newbot` command
3. Follow instructions to create your bot
4. Copy the bot token to your `.env` file

## Usage

### Run Locally

```bash
python bot.py
```

### Run with Docker

```bash
# Build and run
docker-compose up -d

# View logs
docker-compose logs -f telegram-bot

# Stop
docker-compose down
```

### Run with Docker Compose

```bash
# Start the bot
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Stop the bot
docker-compose down
```

## Configuration

### Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `TELEGRAM_BOT_TOKEN` | Your Telegram bot token | Yes | - |
| `GOOGLE_CLOUD_PROJECT_ID` | GCP Project ID | Yes | - |
| `ALLOWED_TELEGRAM_USERS` | Comma-separated list of allowed user IDs | No | All users allowed |
| `LOG_LEVEL` | Logging level | No | INFO |

### Google Cloud APIs Required

The following APIs must be enabled in your GCP project:

- Kubernetes Engine API
- Cloud Billing API
- Cloud Resource Manager API
- Cloud Monitoring API (optional, for enhanced metrics)

## Security Features

- **User Authorization**: Restrict bot access to specific Telegram users
- **Secure Credentials**: Uses Google Cloud's secure authentication methods
- **Non-root Container**: Docker container runs as non-root user
- **Environment Isolation**: Sensitive data stored in environment variables

## Monitoring and Health Checks

The bot includes built-in health checks and monitoring:

- Connection status to Google Cloud APIs
- Cluster health monitoring
- Billing status verification
- Error logging and reporting

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Ensure you're logged in: `gcloud auth application-default login`
   - Check service account permissions
   - Verify project ID is correct

2. **No Clusters Found**
   - Verify GKE clusters exist in the specified project
   - Check if the project ID is correct
   - Ensure Kubernetes Engine API is enabled

3. **Bot Not Responding**
   - Check if the bot token is correct
   - Verify the bot is running
   - Check logs for errors

4. **Permission Denied**
   - Ensure service account has necessary roles
   - Check if billing is enabled for the project

### Logs

View logs to diagnose issues:

```bash
# Local
tail -f bot.log

# Docker
docker-compose logs -f telegram-bot

# Docker container
docker logs gcloud-telegram-bot
```

## Development

### Project Structure

```
telegrambot/
├── bot.py              # Main bot application
├── gcloud_client.py    # Google Cloud API client
├── bot_handlers.py     # Command handlers
├── requirements.txt    # Python dependencies
├── Dockerfile         # Container configuration
├── docker-compose.yml # Docker Compose setup
├── env.example        # Environment configuration template
└── README.md          # This file
```

### Adding New Commands

1. Add command handler in `bot.py`
2. Implement handler logic in `bot_handlers.py`
3. Add corresponding Google Cloud API calls in `gcloud_client.py`
4. Update help text and documentation

### Testing

```bash
# Run basic tests
python -m pytest tests/

# Test Google Cloud connection
python -c "from gcloud_client import GCloudClient; print(GCloudClient().test_connection())"
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:

1. Check the troubleshooting section
2. Review logs for error messages
3. Verify Google Cloud API permissions
4. Ensure all prerequisites are met

## Roadmap

- [ ] Real-time cost alerts
- [ ] Cluster scaling recommendations
- [ ] Performance metrics integration
- [ ] Multi-project support
- [ ] Webhook integration
- [ ] Advanced cost analytics
- [ ] Resource optimization suggestions
