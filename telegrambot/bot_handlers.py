#!/usr/bin/env python3
"""
Bot Handlers for Processing User Commands and Formatting Responses
"""

import logging
from typing import Dict, List, Any
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import ContextTypes
from gcloud_client import GCloudClient

logger = logging.getLogger(__name__)

class BotHandlers:
    def __init__(self, gcloud_client: GCloudClient):
        self.gcloud_client = gcloud_client
    
    async def handle_clusters_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /clusters command - show all GKE clusters"""
        try:
            # Send initial message
            message = await update.effective_message.reply_text("🔍 Fetching cluster information...")
            
            # Get clusters data
            clusters = self.gcloud_client.get_clusters()
            
            if not clusters:
                await message.edit_text("❌ No clusters found or failed to retrieve cluster information.")
                return
            
            # Format clusters information
            clusters_text = "📊 **GKE Clusters Overview**\n\n"
            
            for i, cluster in enumerate(clusters, 1):
                status_emoji = self._get_status_emoji(cluster.get('status', 'UNKNOWN'))
                clusters_text += (
                    f"{i}. **{cluster.get('name', 'Unknown')}** {status_emoji}\n"
                    f"   📍 Location: `{cluster.get('location', 'Unknown')}`\n"
                    f"   🚀 Status: `{cluster.get('status', 'Unknown')}`\n"
                    f"   🔢 Version: `{cluster.get('version', 'Unknown')}`\n"
                    f"   🖥️ Nodes: `{cluster.get('node_count', 'Unknown')}`\n"
                    f"   🌐 Network: `{cluster.get('network', 'Unknown')}`\n"
                    f"   📅 Created: `{cluster.get('created_at', 'Unknown')}`\n\n"
                )
            
            # Add inline buttons for detailed views
            keyboard = [
                [InlineKeyboardButton("🖥️ Node Details", callback_data="nodes")],
                [InlineKeyboardButton("🔍 Cluster Status", callback_data="status")],
                [InlineKeyboardButton("💰 Billing Info", callback_data="billing")]
            ]
            reply_markup = InlineKeyboardMarkup(keyboard)
            
            await message.edit_text(clusters_text, reply_markup=reply_markup, parse_mode='Markdown')
            
        except Exception as e:
            logger.error(f"Error handling clusters command: {e}")
            await update.effective_message.reply_text(
                f"❌ Error retrieving cluster information: {str(e)}"
            )
    
    async def handle_billing_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /billing command - show billing information"""
        try:
            # Send initial message
            message = await update.effective_message.reply_text("💰 Fetching billing information...")
            
            # Get billing data
            billing_info = self.gcloud_client.get_billing_info()
            project_info = self.gcloud_client.get_project_info()
            
            if 'error' in billing_info:
                await message.edit_text(f"❌ Error retrieving billing information: {billing_info['error']}")
                return
            
            # Format billing information
            billing_text = "💰 **Google Cloud Billing Overview**\n\n"
            
            # Project information
            if 'error' not in project_info:
                billing_text += (
                    f"🏢 **Project Information**\n"
                    f"   📋 Project ID: `{project_info.get('project_id', 'Unknown')}`\n"
                    f"   📝 Display Name: `{project_info.get('name', 'Unknown')}`\n"
                    f"   🚦 State: `{project_info.get('state', 'Unknown')}`\n"
                    f"   📅 Created: `{project_info.get('created_at', 'Unknown')}`\n\n"
                )
            
            # Billing information
            billing_text += (
                f"💳 **Billing Details**\n"
                f"   🔌 Billing Enabled: `{'Yes' if billing_info.get('billing_enabled') else 'No'}`\n"
                f"   🏦 Billing Account: `{billing_info.get('billing_account', 'Unknown')}`\n"
                f"   💰 Current Month Cost: `{billing_info.get('current_month_cost', 'Not available')}`\n\n"
            )
            
            # Add cost optimization tips
            billing_text += (
                "💡 **Cost Optimization Tips**\n"
                "• Use preemptible instances for non-critical workloads\n"
                "• Enable autoscaling to scale down during low usage\n"
                "• Monitor and optimize storage usage\n"
                "• Use committed use discounts for predictable workloads\n"
            )
            
            # Add inline buttons
            keyboard = [
                [InlineKeyboardButton("📊 Clusters", callback_data="clusters")],
                [InlineKeyboardButton("🖥️ Nodes", callback_data="nodes")],
                [InlineKeyboardButton("📈 Cost Analysis", callback_data="costs")]
            ]
            reply_markup = InlineKeyboardMarkup(keyboard)
            
            await message.edit_text(billing_text, reply_markup=reply_markup, parse_mode='Markdown')
            
        except Exception as e:
            logger.error(f"Error handling billing command: {e}")
            await update.effective_message.reply_text(
                f"❌ Error retrieving billing information: {str(e)}"
            )
    
    async def handle_nodes_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /nodes command - show cluster node information"""
        try:
            # Send initial message
            message = await update.effective_message.reply_text("🖥️ Fetching node information...")
            
            # Get clusters first to show node pools
            clusters = self.gcloud_client.get_clusters()
            
            if not clusters:
                await message.edit_text("❌ No clusters found to retrieve node information.")
                return
            
            # Format nodes information
            nodes_text = "🖥️ **Cluster Nodes Overview**\n\n"
            
            for i, cluster in enumerate(clusters, 1):
                nodes_text += f"**Cluster {i}: {cluster.get('name', 'Unknown')}**\n"
                
                # Get node pools for this cluster
                node_pools = self.gcloud_client.get_cluster_nodes(
                    cluster.get('name', ''), 
                    cluster.get('location', '')
                )
                
                if node_pools:
                    for j, node_pool in enumerate(node_pools, 1):
                        status_emoji = self._get_status_emoji(node_pool.get('status', 'UNKNOWN'))
                        nodes_text += (
                            f"  {j}. **{node_pool.get('name', 'Unknown')}** {status_emoji}\n"
                            f"     🔢 Version: `{node_pool.get('version', 'Unknown')}`\n"
                            f"     🚦 Status: `{node_pool.get('status', 'Unknown')}`\n"
                            f"     🖥️ Node Count: `{node_pool.get('node_count', 'Unknown')}`\n"
                            f"     💻 Machine Type: `{node_pool.get('machine_type', 'Unknown')}`\n"
                            f"     💾 Disk Size: `{node_pool.get('disk_size_gb', 'Unknown')} GB`\n"
                            f"     🖼️ Image Type: `{node_pool.get('image_type', 'Unknown')}`\n"
                        )
                        
                        # Autoscaling information
                        autoscaling = node_pool.get('autoscaling', {})
                        if autoscaling.get('enabled'):
                            nodes_text += (
                                f"     📈 Autoscaling: `Enabled` "
                                f"({autoscaling.get('min_node_count', '?')}-{autoscaling.get('max_node_count', '?')})\n"
                            )
                        else:
                            nodes_text += "     📈 Autoscaling: `Disabled`\n"
                        
                        nodes_text += "\n"
                else:
                    nodes_text += "  ❌ No node pools found\n\n"
            
            # Add inline buttons
            keyboard = [
                [InlineKeyboardButton("📊 Clusters", callback_data="clusters")],
                [InlineKeyboardButton("💰 Billing", callback_data="billing")],
                [InlineKeyboardButton("🔍 Status", callback_data="status")]
            ]
            reply_markup = InlineKeyboardMarkup(keyboard)
            
            await message.edit_text(nodes_text, reply_markup=reply_markup, parse_mode='Markdown')
            
        except Exception as e:
            logger.error(f"Error handling nodes command: {e}")
            await update.effective_message.reply_text(
                f"❌ Error retrieving node information: {str(e)}"
            )
    
    async def handle_costs_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /costs command - show cost analysis"""
        try:
            # Send initial message
            message = await update.effective_message.reply_text("📈 Analyzing costs...")
            
            # Get clusters and billing info for cost analysis
            clusters = self.gcloud_client.get_clusters()
            billing_info = self.gcloud_client.get_billing_info()
            
            # Format cost analysis
            costs_text = "📈 **Cost Analysis & Optimization**\n\n"
            
            # Cluster cost factors
            costs_text += "🏗️ **Infrastructure Cost Factors**\n"
            total_nodes = sum(cluster.get('node_count', 0) for cluster in clusters)
            costs_text += f"   🖥️ Total Nodes: `{total_nodes}`\n"
            costs_text += f"   📊 Total Clusters: `{len(clusters)}`\n\n"
            
            # Cost optimization recommendations
            costs_text += "💡 **Cost Optimization Recommendations**\n"
            
            if total_nodes > 10:
                costs_text += "   ⚠️ High node count detected - consider consolidation\n"
            elif total_nodes > 5:
                costs_text += "   ⚠️ Moderate node count - review autoscaling policies\n"
            else:
                costs_text += "   ✅ Node count looks reasonable\n"
            
            # Check for autoscaling
            autoscaling_enabled = False
            for cluster in clusters:
                node_pools = self.gcloud_client.get_cluster_nodes(
                    cluster.get('name', ''), 
                    cluster.get('location', '')
                )
                for node_pool in node_pools:
                    if node_pool.get('autoscaling', {}).get('enabled'):
                        autoscaling_enabled = True
                        break
                if autoscaling_enabled:
                    break
            
            if autoscaling_enabled:
                costs_text += "   ✅ Autoscaling is enabled - good for cost optimization\n"
            else:
                costs_text += "   ⚠️ Consider enabling autoscaling for cost savings\n"
            
            # Billing status
            if billing_info.get('billing_enabled'):
                costs_text += "   ✅ Billing is enabled and monitored\n"
            else:
                costs_text += "   ⚠️ Billing is disabled - enable for cost tracking\n"
            
            costs_text += "\n"
            
            # Cost saving tips
            costs_text += "💰 **Cost Saving Strategies**\n"
            costs_text += "• Use preemptible instances (up to 80% savings)\n"
            "• Enable autoscaling for variable workloads\n"
            "• Use committed use discounts for stable workloads\n"
            "• Monitor and optimize storage usage\n"
            "• Consider regional vs multi-regional storage\n"
            "• Use Cloud Functions for event-driven workloads\n"
            
            # Add inline buttons
            keyboard = [
                [InlineKeyboardButton("📊 Clusters", callback_data="clusters")],
                [InlineKeyboardButton("💰 Billing", callback_data="billing")],
                [InlineKeyboardButton("🖥️ Nodes", callback_data="nodes")]
            ]
            reply_markup = InlineKeyboardMarkup(keyboard)
            
            await message.edit_text(costs_text, reply_markup=reply_markup, parse_mode='Markdown')
            
        except Exception as e:
            logger.error(f"Error handling costs command: {e}")
            await update.effective_message.reply_text(
                f"❌ Error analyzing costs: {str(e)}"
            )
    
    async def handle_status_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /status command - show overall system status"""
        try:
            # Send initial message
            message = await update.effective_message.reply_text("🔍 Checking system status...")
            
            # Test GCloud connection
            connection_status = self.gcloud_client.test_connection()
            
            # Get basic information
            clusters = self.gcloud_client.get_clusters()
            project_info = self.gcloud_client.get_project_info()
            billing_info = self.gcloud_client.get_billing_info()
            
            # Format status information
            status_text = "🔍 **System Status Overview**\n\n"
            
            # Connection status
            if connection_status:
                status_text += "✅ **GCloud Connection**: `Connected`\n"
            else:
                status_text += "❌ **GCloud Connection**: `Failed`\n"
            
            # Project status
            if 'error' not in project_info:
                status_text += f"✅ **Project**: `{project_info.get('project_id', 'Unknown')}`\n"
                status_text += f"   🚦 State: `{project_info.get('state', 'Unknown')}`\n"
            else:
                status_text += "❌ **Project**: `Error retrieving project info`\n"
            
            # Clusters status
            if clusters:
                status_text += f"✅ **Clusters**: `{len(clusters)} found`\n"
                
                # Count clusters by status
                status_counts = {}
                for cluster in clusters:
                    status = cluster.get('status', 'UNKNOWN')
                    status_counts[status] = status_counts.get(status, 0) + 1
                
                for status, count in status_counts.items():
                    status_emoji = self._get_status_emoji(status)
                    status_text += f"   {status_emoji} {status}: `{count}`\n"
            else:
                status_text += "⚠️ **Clusters**: `No clusters found`\n"
            
            # Billing status
            if 'error' not in billing_info:
                billing_enabled = billing_info.get('billing_enabled', False)
                status_text += f"{'✅' if billing_enabled else '⚠️'} **Billing**: `{'Enabled' if billing_enabled else 'Disabled'}`\n"
            else:
                status_text += "❌ **Billing**: `Error retrieving billing info`\n"
            
            status_text += "\n"
            
            # Overall health assessment
            if connection_status and clusters and 'error' not in project_info:
                if any(cluster.get('status') == 'RUNNING' for cluster in clusters):
                    status_text += "🟢 **Overall Status**: `Healthy`\n"
                else:
                    status_text += "🟡 **Overall Status**: `Warning - No running clusters`\n"
            elif not connection_status:
                status_text += "🔴 **Overall Status**: `Critical - Connection failed`\n"
            else:
                status_text += "🟡 **Overall Status**: `Warning - Some issues detected`\n"
            
            # Add inline buttons
            keyboard = [
                [InlineKeyboardButton("📊 Clusters", callback_data="clusters")],
                [InlineKeyboardButton("💰 Billing", callback_data="billing")],
                [InlineKeyboardButton("🖥️ Nodes", callback_data="nodes")]
            ]
            reply_markup = InlineKeyboardMarkup(keyboard)
            
            await message.edit_text(status_text, reply_markup=reply_markup, parse_mode='Markdown')
            
        except Exception as e:
            logger.error(f"Error handling status command: {e}")
            await update.effective_message.reply_text(
                f"❌ Error checking system status: {str(e)}"
            )
    
    def _get_status_emoji(self, status: str) -> str:
        """Get appropriate emoji for cluster/node status"""
        status = status.upper()
        if status == 'RUNNING':
            return '🟢'
        elif status == 'PROVISIONING':
            return '🟡'
        elif status == 'STOPPING':
            return '🟠'
        elif status == 'ERROR':
            return '🔴'
        elif status == 'DEGRADED':
            return '🟡'
        else:
            return '⚪'
