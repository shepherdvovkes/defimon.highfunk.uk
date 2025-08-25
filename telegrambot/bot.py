#!/usr/bin/env python3
"""
Telegram Bot for Google Cloud Infrastructure Monitoring and Management
"""

import os
import logging
import asyncio
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from dotenv import load_dotenv

from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import (
    Application, CommandHandler, CallbackQueryHandler, 
    MessageHandler, filters, ContextTypes
)

from gcloud_client import GCloudClient
from bot_handlers import BotHandlers

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

class TelegramBot:
    def __init__(self):
        """Initialize the Telegram bot"""
        self.token = os.getenv('TELEGRAM_BOT_TOKEN')
        if not self.token:
            raise ValueError("TELEGRAM_BOT_TOKEN environment variable is required")
        
        # Initialize GCloud client
        try:
            self.gcloud_client = GCloudClient()
            logger.info("GCloud client initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize GCloud client: {e}")
            raise
        
        # Initialize bot handlers
        self.handlers = BotHandlers(self.gcloud_client)
        
        # Initialize bot application
        self.application = Application.builder().token(self.token).build()
        
        # Set up command handlers
        self._setup_handlers()
        
        logger.info("Telegram Bot initialized successfully")
    
    def _setup_handlers(self):
        """Set up command handlers"""
        # Add command handlers
        self.application.add_handler(CommandHandler("start", self._start_command))
        self.application.add_handler(CommandHandler("help", self._help_command))
        
        # Infrastructure commands
        self.application.add_handler(CommandHandler("infrastructure", self._infrastructure_command))
        self.application.add_handler(CommandHandler("clusters", self._clusters_command))
        self.application.add_handler(CommandHandler("instances", self._instances_command))
        self.application.add_handler(CommandHandler("nodes", self._nodes_command))
        self.application.add_handler(CommandHandler("ethereum", self._ethereum_command))
        
        # Management commands
        self.application.add_handler(CommandHandler("execute", self._execute_command))
        self.application.add_handler(CommandHandler("scale", self._scale_command))
        self.application.add_handler(CommandHandler("restart", self._restart_command))
        self.application.add_handler(CommandHandler("logs", self._logs_command))
        
        # Monitoring commands
        self.application.add_handler(CommandHandler("billing", self._billing_command))
        self.application.add_handler(CommandHandler("costs", self._costs_command))
        self.application.add_handler(CommandHandler("status", self._status_command))
        
        # Callback query handler for inline buttons
        self.application.add_handler(CallbackQueryHandler(self._button_callback))
        
        logger.info("Command handlers set up successfully")
    
    async def _start_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /start command"""
        welcome_text = (
            "Welcome to Google Cloud Infrastructure Monitor Bot!\n\n"
            "This bot helps you monitor and manage your Google Cloud infrastructure.\n\n"
            "**Available Commands:**\n"
            "/infrastructure - Overview of all infrastructure\n"
            "/clusters - List GKE clusters\n"
            "/instances - List compute instances\n"
            "/nodes - Show cluster nodes\n"
            "/status - System status\n"
            "/billing - Billing information\n"
            "/costs - Cost analysis\n\n"
            "**Management Commands:**\n"
            "/execute <command> - Execute gcloud command\n"
            "/scale <cluster> <location> <nodes> - Scale cluster\n"
            "/restart <cluster> <location> <pool> - Restart node pool\n"
            "/logs <cluster> <location> - Get cluster logs\n\n"
            "Use the buttons below to get started:"
        )
        
        # Create inline keyboard
        keyboard = [
            [InlineKeyboardButton("Infrastructure Overview", callback_data="infrastructure")],
            [InlineKeyboardButton("Clusters", callback_data="clusters")],
            [InlineKeyboardButton("Compute Instances", callback_data="instances")],
            [InlineKeyboardButton("System Status", callback_data="status")]
        ]
        reply_markup = InlineKeyboardMarkup(keyboard)
        
        await update.effective_message.reply_text(
            welcome_text,
            reply_markup=reply_markup,
            parse_mode='Markdown'
        )
    
    async def _help_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /help command"""
        help_text = (
            "**Google Cloud Infrastructure Monitor Bot - Help**\n\n"
            "**Monitoring Commands:**\n"
            "• `/infrastructure` - Comprehensive infrastructure overview\n"
            "• `/clusters` - List all GKE clusters\n"
            "• `/instances` - List compute instances\n"
            "• `/nodes` - Show cluster node pools\n"
            "• `/ethereum` - Show Ethereum nodes (Lighthouse & Geth) status\n"
            "• `/status` - Overall system status\n\n"
            "**Information Commands:**\n"
            "• `/billing` - Billing account and cost information\n"
            "• `/costs` - Cost analysis and optimization tips\n\n"
            "**Management Commands:**\n"
            "• `/execute <gcloud_command>` - Execute gcloud CLI commands\n"
            "• `/scale <cluster> <location> <nodes>` - Scale cluster nodes\n"
            "• `/restart <cluster> <location> <pool>` - Restart node pool\n"
            "• `/logs <cluster> <location> [lines]` - Get cluster logs\n\n"
            "**Examples:**\n"
            "• `/execute container clusters list`\n"
            "• `/scale my-cluster us-central1 5`\n"
            "• `/logs my-cluster us-central1 100`\n\n"
            "**Security:**\n"
            "Only safe, read-only and approved management commands are allowed.\n"
            "The bot automatically filters dangerous operations."
        )
        
        # Create inline keyboard
        keyboard = [
            [InlineKeyboardButton("Infrastructure", callback_data="infrastructure")],
            [InlineKeyboardButton("Clusters", callback_data="clusters")],
            [InlineKeyboardButton("Status", callback_data="status")]
        ]
        reply_markup = InlineKeyboardMarkup(keyboard)
        
        await update.effective_message.reply_text(
            help_text,
            reply_markup=reply_markup,
            parse_mode='Markdown'
        )
    
    async def _infrastructure_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /infrastructure command"""
        await self.handlers.handle_infrastructure_command(update, context)
    
    async def _clusters_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /clusters command"""
        await self.handlers.handle_clusters_command(update, context)
    
    async def _instances_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /instances command"""
        await self.handlers.handle_instances_command(update, context)
    
    async def _nodes_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /nodes command"""
        await self.handlers.handle_nodes_command(update, context)
    
    async def _ethereum_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /ethereum command"""
        await self.handlers.handle_ethereum_command(update, context)
    
    async def _execute_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /execute command"""
        await self.handlers.handle_execute_command(update, context)
    
    async def _scale_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /scale command"""
        await self.handlers.handle_scale_command(update, context)
    
    async def _restart_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /restart command"""
        await self.handlers.handle_restart_command(update, context)
    
    async def _logs_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /logs command"""
        await self.handlers.handle_logs_command(update, context)
    
    async def _billing_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /billing command"""
        await self.handlers.handle_billing_command(update, context)
    
    async def _costs_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /costs command"""
        await self.handlers.handle_costs_command(update, context)
    
    async def _status_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /status command"""
        await self.handlers.handle_status_command(update, context)
    
    async def _button_callback(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle inline button callbacks"""
        query = update.callback_query
        await query.answer()
        
        # Route callback data to appropriate handler
        if query.data == "infrastructure":
            await self.handlers.handle_infrastructure_command(update, context)
        elif query.data == "clusters":
            await self.handlers.handle_clusters_command(update, context)
        elif query.data == "instances":
            await self.handlers.handle_instances_command(update, context)
        elif query.data == "nodes":
            await self.handlers.handle_nodes_command(update, context)
        elif query.data == "ethereum":
            await self.handlers.handle_ethereum_command(update, context)
        elif query.data == "status":
            await self.handlers.handle_status_command(update, context)
        elif query.data == "billing":
            await self.handlers.handle_billing_command(update, context)
        elif query.data == "costs":
            await self.handlers.handle_costs_command(update, context)
        else:
            await query.edit_message_text("Unknown button action")
    
    async def start(self):
        """Start the bot"""
        try:
            logger.info("Starting Telegram Bot...")
            await self.application.initialize()
            await self.application.start()
            await self.application.updater.start_polling()
            logger.info("Bot started successfully")
            
            # Keep the bot running
            while True:
                await asyncio.sleep(1)
            
        except Exception as e:
            logger.error(f"Failed to start bot: {e}")
            raise
    
    async def stop(self):
        """Stop the bot"""
        try:
            logger.info("Stopping Telegram Bot...")
            await self.application.updater.stop()
            await self.application.stop()
            await self.application.shutdown()
            logger.info("Bot stopped successfully")
            
        except Exception as e:
            logger.error(f"Failed to stop bot: {e}")
            raise

async def main():
    """Main function"""
    try:
        bot = TelegramBot()
        await bot.start()
    except KeyboardInterrupt:
        logger.info("Bot interrupted by user")
    except Exception as e:
        logger.error(f"Failed to start bot: {e}")
        raise

if __name__ == "__main__":
    asyncio.run(main())
