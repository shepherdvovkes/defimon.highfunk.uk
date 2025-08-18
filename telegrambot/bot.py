#!/usr/bin/env python3
"""
Telegram Bot for Google Cloud Cluster and Billing Information
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
        self.token = os.getenv('TELEGRAM_BOT_TOKEN')
        if not self.token:
            raise ValueError("TELEGRAM_BOT_TOKEN environment variable is required")
        
        self.allowed_users = os.getenv('ALLOWED_TELEGRAM_USERS', '').split(',')
        self.gcloud_client = GCloudClient()
        self.handlers = BotHandlers(self.gcloud_client)
        
        # Initialize bot application
        self.application = Application.builder().token(self.token).build()
        self._setup_handlers()
    
    def _setup_handlers(self):
        """Setup all bot command and callback handlers"""
        # Command handlers
        self.application.add_handler(CommandHandler("start", self._start_command))
        self.application.add_handler(CommandHandler("help", self._help_command))
        self.application.add_handler(CommandHandler("clusters", self._clusters_command))
        self.application.add_handler(CommandHandler("billing", self._billing_command))
        self.application.add_handler(CommandHandler("nodes", self._nodes_command))
        self.application.add_handler(CommandHandler("costs", self._costs_command))
        self.application.add_handler(CommandHandler("status", self._status_command))
        
        # Callback query handler for inline buttons
        self.application.add_handler(CallbackQueryHandler(self._button_callback))
        
        # Error handler
        self.application.add_error_handler(self._error_handler)
    
    async def _start_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /start command"""
        if not self._is_user_authorized(update.effective_user.id):
            await update.message.reply_text("❌ Access denied. You are not authorized to use this bot.")
            return
        
        welcome_text = (
            "🚀 **Welcome to the Google Cloud Monitor Bot!**\n\n"
            "I can help you monitor your GCP clusters and billing information.\n\n"
            "**Available Commands:**\n"
            "/clusters - List all GKE clusters\n"
            "/billing - Show billing overview\n"
            "/nodes - Show cluster node information\n"
            "/costs - Show cost analysis\n"
            "/status - Show overall system status\n"
            "/help - Show this help message\n\n"
            "Use /help for more detailed information."
        )
        
        keyboard = [
            [InlineKeyboardButton("📊 Clusters", callback_data="clusters")],
            [InlineKeyboardButton("💰 Billing", callback_data="billing")],
            [InlineKeyboardButton("🖥️ Nodes", callback_data="nodes")],
            [InlineKeyboardButton("📈 Costs", callback_data="costs")],
            [InlineKeyboardButton("🔍 Status", callback_data="status")]
        ]
        reply_markup = InlineKeyboardMarkup(keyboard)
        
        await update.message.reply_text(welcome_text, reply_markup=reply_markup, parse_mode='Markdown')
    
    async def _help_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /help command"""
        if not self._is_user_authorized(update.effective_user.id):
            await update.message.reply_text("❌ Access denied.")
            return
        
        help_text = (
            "🔧 **Bot Help & Commands**\n\n"
            "**Cluster Management:**\n"
            "• `/clusters` - List all GKE clusters with status\n"
            "• `/nodes` - Show detailed node information\n"
            "• `/status` - Overall system health status\n\n"
            "**Billing & Costs:**\n"
            "• `/billing` - Current billing overview\n"
            "• `/costs` - Detailed cost analysis and trends\n\n"
            "**Interactive Features:**\n"
            "• Use inline buttons for quick access\n"
            "• Get real-time cluster status updates\n"
            "• Monitor billing alerts and thresholds\n\n"
            "**Examples:**\n"
            "• `/clusters` - See all your clusters\n"
            "• `/billing` - Check current month costs\n"
            "• `/costs` - Analyze spending patterns"
        )
        
        await update.message.reply_text(help_text, parse_mode='Markdown')
    
    async def _clusters_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /clusters command"""
        if not self._is_user_authorized(update.effective_user.id):
            await update.message.reply_text("❌ Access denied.")
            return
        
        await self.handlers.handle_clusters_command(update, context)
    
    async def _billing_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /billing command"""
        if not self._is_user_authorized(update.effective_user.id):
            await update.message.reply_text("❌ Access denied.")
            return
        
        await self.handlers.handle_billing_command(update, context)
    
    async def _nodes_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /nodes command"""
        if not self._is_user_authorized(update.effective_user.id):
            await update.message.reply_text("❌ Access denied.")
            return
        
        await self.handlers.handle_nodes_command(update, context)
    
    async def _costs_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /costs command"""
        if not self._is_user_authorized(update.effective_user.id):
            await update.message.reply_text("❌ Access denied.")
            return
        
        await self.handlers.handle_costs_command(update, context)
    
    async def _status_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /status command"""
        if not self._is_user_authorized(update.effective_user.id):
            await update.message.reply_text("❌ Access denied.")
            return
        
        await self.handlers.handle_status_command(update, context)
    
    async def _button_callback(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle inline button callbacks"""
        if not self._is_user_authorized(update.effective_user.id):
            await update.callback_query.answer("❌ Access denied.")
            return
        
        query = update.callback_query
        await query.answer()
        
        if query.data == "clusters":
            await self.handlers.handle_clusters_command(update, context)
        elif query.data == "billing":
            await self.handlers.handle_billing_command(update, context)
        elif query.data == "nodes":
            await self.handlers.handle_nodes_command(update, context)
        elif query.data == "costs":
            await self.handlers.handle_costs_command(update, context)
        elif query.data == "status":
            await self.handlers.handle_status_command(update, context)
    
    def _is_user_authorized(self, user_id: int) -> bool:
        """Check if user is authorized to use the bot"""
        if not self.allowed_users or self.allowed_users == ['']:
            return True  # Allow all users if no restrictions set
        return str(user_id) in self.allowed_users
    
    async def _error_handler(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle errors in bot operations"""
        logger.error(f"Exception while handling an update: {context.error}")
        
        if update and update.effective_message:
            await update.effective_message.reply_text(
                "❌ An error occurred while processing your request. Please try again later."
            )
    
    def run(self):
        """Start the bot"""
        logger.info("Starting Telegram Bot...")
        self.application.run_polling(allowed_updates=Update.ALL_TYPES)

def main():
    """Main function to run the bot"""
    try:
        bot = TelegramBot()
        bot.run()
    except Exception as e:
        logger.error(f"Failed to start bot: {e}")
        raise

if __name__ == "__main__":
    main()
