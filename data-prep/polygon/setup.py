#!/usr/bin/env python3
"""
Setup script for Polygon Network Data Collection Framework
"""

import os
import sys
import subprocess
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def run_command(command: str, description: str = ""):
    """Run a shell command with error handling"""
    try:
        logger.info(f"Running: {description or command}")
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        logger.info(f"✅ {description or command} completed successfully")
        return result.stdout
    except subprocess.CalledProcessError as e:
        logger.error(f"❌ {description or command} failed: {e}")
        logger.error(f"Error output: {e.stderr}")
        return None

def check_python_version():
    """Check if Python version is compatible"""
    if sys.version_info < (3, 8):
        logger.error("❌ Python 3.8 or higher is required")
        sys.exit(1)
    logger.info(f"✅ Python {sys.version_info.major}.{sys.version_info.minor} detected")

def install_dependencies():
    """Install Python dependencies"""
    logger.info("Installing Python dependencies...")
    
    # Check if requirements.txt exists
    requirements_file = Path("requirements.txt")
    if not requirements_file.exists():
        logger.error("❌ requirements.txt not found")
        return False
    
    # Install dependencies
    result = run_command("pip install -r requirements.txt", "Installing Python dependencies")
    return result is not None

def create_directories():
    """Create necessary directories"""
    logger.info("Creating directories...")
    
    directories = [
        "data",
        "logs", 
        "config",
        "exports",
        "backups"
    ]
    
    for directory in directories:
        Path(directory).mkdir(exist_ok=True)
        logger.info(f"✅ Created directory: {directory}")

def create_config_files():
    """Create configuration files if they don't exist"""
    logger.info("Setting up configuration files...")
    
    # Create .env template
    env_template = """# Polygon Network Data Collection Configuration

# QuickNode Configuration
QUICKNODE_ENDPOINT_NAME=your-endpoint-name
QUICKNODE_TOKEN_ID=your-token-id

# Database Configuration (from gcp.env)
# These will be read from the main gcp.env file

# Collection Settings
COLLECTION_BATCH_SIZE=100
COLLECTION_MAX_CONCURRENT_REQUESTS=10
COLLECTION_RETRY_ATTEMPTS=3
COLLECTION_RATE_LIMIT_PER_SECOND=50

# Data Retention
DATA_RETENTION_DAYS=90
HISTORICAL_DATA_ENABLED=true

# Logging
LOG_LEVEL=INFO
LOG_FILE=polygon_collector.log

# Export Settings
EXPORT_FORMAT=json
EXPORT_COMPRESSION=true
"""
    
    env_file = Path(".env")
    if not env_file.exists():
        with open(env_file, "w") as f:
            f.write(env_template)
        logger.info("✅ Created .env template")
    else:
        logger.info("✅ .env file already exists")

def create_database_schema():
    """Create database schema"""
    logger.info("Setting up database schema...")
    
    # This will be handled by the database manager when it initializes
    logger.info("✅ Database schema will be created on first run")

def run_tests():
    """Run basic tests"""
    logger.info("Running basic tests...")
    
    # Test imports
    try:
        import asyncio
        import aiohttp
        import asyncpg
        import web3
        logger.info("✅ All required packages imported successfully")
    except ImportError as e:
        logger.error(f"❌ Import test failed: {e}")
        return False
    
    # Test configuration
    try:
        sys.path.append(os.path.dirname(os.path.abspath(__file__)))
        from config.quicknode_config import PolygonQuickNodeConfig
        from config.polygon_endpoints import PolygonEndpoints
        logger.info("✅ Configuration modules imported successfully")
    except ImportError as e:
        logger.error(f"❌ Configuration import test failed: {e}")
        return False
    
    return True

def main():
    """Main setup function"""
    logger.info("🚀 Setting up Polygon Network Data Collection Framework")
    logger.info("=" * 60)
    
    # Check Python version
    check_python_version()
    
    # Create directories
    create_directories()
    
    # Install dependencies
    if not install_dependencies():
        logger.error("❌ Failed to install dependencies")
        sys.exit(1)
    
    # Create config files
    create_config_files()
    
    # Setup database schema
    create_database_schema()
    
    # Run tests
    if not run_tests():
        logger.error("❌ Tests failed")
        sys.exit(1)
    
    logger.info("=" * 60)
    logger.info("✅ Setup completed successfully!")
    logger.info("")
    logger.info("Next steps:")
    logger.info("1. Update .env file with your QuickNode credentials")
    logger.info("2. Ensure your Google Cloud PostgreSQL instance is running")
    logger.info("3. Run: python main_collector.py --help")
    logger.info("4. Start collecting data with: python main_collector.py --endpoint-name YOUR_ENDPOINT --token-id YOUR_TOKEN")
    logger.info("")

if __name__ == "__main__":
    main()
