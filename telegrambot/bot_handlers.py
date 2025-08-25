#!/usr/bin/env python3
"""
Bot Handlers for Infrastructure Monitoring and Management Commands
"""

import logging
import re
from typing import Dict, List, Any
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import ContextTypes
from gcloud_client import GCloudClient

logger = logging.getLogger(__name__)

class BotHandlers:
    def __init__(self, gcloud_client: GCloudClient):
        self.gcloud_client = gcloud_client
    
    async def handle_infrastructure_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /infrastructure command - show comprehensive infrastructure overview"""
        try:
            message = await update.effective_message.reply_text("Analyzing infrastructure...")
            
            # Get comprehensive infrastructure data
            infrastructure = self.gcloud_client.get_infrastructure_overview()
            
            if 'error' in infrastructure:
                await message.edit_text(f"Error retrieving infrastructure data: {infrastructure['error']}")
                return
            
            # Format infrastructure overview
            infra_text = "**Infrastructure Overview**\n\n"
            
            # Clusters summary
            clusters = infrastructure.get('clusters', [])
            infra_text += f"**GKE Clusters**: {len(clusters)}\n"
            if clusters:
                running_clusters = sum(1 for c in clusters if c.get('status') == 'RUNNING')
                infra_text += f"   Running: {running_clusters}\n"
                infra_text += f"   Other: {len(clusters) - running_clusters}\n"
            
            # Compute instances
            instances = infrastructure.get('compute_instances', [])
            infra_text += f"\n**Compute Instances**: {len(instances)}\n"
            if instances:
                running_instances = sum(1 for i in instances if i.get('status') == 'RUNNING')
                infra_text += f"   Running: {running_instances}\n"
                infra_text += f"   Other: {len(instances) - running_instances}\n"
            
            # Networks
            networks = infrastructure.get('networks', [])
            infra_text += f"\n**Networks**: {len(networks)}\n"
            
            # Storage
            storage = infrastructure.get('storage', {})
            infra_text += f"\n**Storage Buckets**: {storage.get('bucket_count', 0)}\n"
            
            # IAM
            iam = infrastructure.get('iam', {})
            infra_text += f"\n**IAM Bindings**: {iam.get('bindings_count', 0)}\n"
            infra_text += f"   Members: {iam.get('members_count', 0)}\n"
            infra_text += f"   Roles: {len(iam.get('roles', []))}\n"
            
            # Quotas
            quotas = infrastructure.get('quotas', {})
            if quotas:
                infra_text += f"\n**Resource Quotas**\n"
                for metric, quota in quotas.items():
                    usage = quota.get('usage', 0)
                    limit = quota.get('limit', 0)
                    percentage = (usage / limit * 100) if limit > 0 else 0
                    status_symbol = 'OK' if percentage < 80 else 'WARN' if percentage < 95 else 'CRIT'
                    infra_text += f"   {status_symbol} {metric}: {usage}/{limit} ({percentage:.1f}%)\n"
            
            # Add inline buttons
            keyboard = [
                [InlineKeyboardButton("Clusters", callback_data="clusters")],
                [InlineKeyboardButton("Instances", callback_data="instances")],
                [InlineKeyboardButton("Status", callback_data="status")],
                [InlineKeyboardButton("Billing", callback_data="billing")]
            ]
            reply_markup = InlineKeyboardMarkup(keyboard)
            
            await message.edit_text(infra_text, reply_markup=reply_markup, parse_mode='Markdown')
            
        except Exception as e:
            logger.error(f"Error handling infrastructure command: {e}")
            await update.effective_message.reply_text(
                f"Error retrieving infrastructure data: {str(e)}"
            )
    
    async def handle_instances_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /instances command - show compute instances"""
        try:
            message = await update.effective_message.reply_text("Fetching compute instances...")
            
            instances = self.gcloud_client.get_compute_instances()
            
            if not instances:
                await message.edit_text("No compute instances found.")
                return
            
            # Format instances information
            instances_text = "**Compute Instances Overview**\n\n"
            
            for i, instance in enumerate(instances, 1):
                status_symbol = self._get_status_symbol(instance.get('status', 'UNKNOWN'))
                instances_text += (
                    f"{i}. **{instance.get('name', 'Unknown')}** {status_symbol}\n"
                    f"   Zone: `{instance.get('zone', 'Unknown')}`\n"
                    f"   Status: `{instance.get('status', 'Unknown')}`\n"
                    f"   Machine Type: `{instance.get('machine_type', 'Unknown')}`\n"
                    f"   CPU Platform: `{instance.get('cpu_platform', 'Unknown')}`\n"
                )
                
                # Network interfaces
                if instance.get('internal_ip'):
                    instances_text += f"   Internal IP: `{instance.get('internal_ip')}`\n"
                if instance.get('external_ip'):
                    instances_text += f"   External IP: `{instance.get('external_ip')}`\n"
                
                instances_text += "\n"
            
            # Add inline buttons
            keyboard = [
                [InlineKeyboardButton("Infrastructure", callback_data="infrastructure")],
                [InlineKeyboardButton("Clusters", callback_data="clusters")],
                [InlineKeyboardButton("Status", callback_data="status")]
            ]
            reply_markup = InlineKeyboardMarkup(keyboard)
            
            await message.edit_text(instances_text, reply_markup=reply_markup, parse_mode='Markdown')
            
        except Exception as e:
            logger.error(f"Error handling instances command: {e}")
            await update.effective_message.reply_text(
                f"Error retrieving instances: {str(e)}"
            )
    
    async def handle_execute_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /execute command - execute gcloud commands"""
        try:
            # Check if command argument is provided
            if not context.args:
                await update.effective_message.reply_text(
                    "Please provide a command to execute.\n"
                    "Usage: /execute <gcloud_command>\n"
                    "Example: /execute container clusters list"
                )
                return
            
            # Get the command to execute
            command = ' '.join(context.args)
            
            # Security check - only allow safe commands
            if not self._is_command_safe(command):
                await update.effective_message.reply_text(
                    "This command is not allowed for security reasons.\n"
                    "Only read-only and safe management commands are permitted."
                )
                return
            
            # Send initial message
            message = await update.effective_message.reply_text(f"Executing: `{command}`...")
            
            # Execute the command
            success, output = self.gcloud_client.execute_gcloud_command(command)
            
            if success:
                # Truncate output if too long
                if len(output) > 4000:
                    output = output[:4000] + "\n\n... (output truncated)"
                
                await message.edit_text(
                    f"**Command executed successfully**\n\n"
                    f"**Command**: `{command}`\n\n"
                    f"**Output**:\n```\n{output}\n```",
                    parse_mode='Markdown'
                )
            else:
                await message.edit_text(
                    f"**Command failed**\n\n"
                    f"**Command**: `{command}`\n\n"
                    f"**Error**:\n```\n{output}\n```",
                    parse_mode='Markdown'
                )
                
        except Exception as e:
            logger.error(f"Error handling execute command: {e}")
            await update.effective_message.reply_text(
                f"Error executing command: {str(e)}"
            )
    
    async def handle_scale_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /scale command - scale cluster nodes"""
        try:
            # Check if required arguments are provided
            if len(context.args) < 3:
                await update.effective_message.reply_text(
                    "Please provide cluster name, location, and node count.\n"
                    "Usage: /scale <cluster_name> <location> <node_count>\n"
                    "Example: /scale my-cluster us-central1 5"
                )
                return
            
            cluster_name = context.args[0]
            location = context.args[1]
            try:
                node_count = int(context.args[2])
                if node_count < 1 or node_count > 100:
                    raise ValueError("Node count must be between 1 and 100")
            except ValueError:
                await update.effective_message.reply_text(
                    "Invalid node count. Please provide a number between 1 and 100."
                )
                return
            
            # Send initial message
            message = await update.effective_message.reply_text(
                f"Scaling cluster `{cluster_name}` to {node_count} nodes..."
            )
            
            # Execute scaling command
            success, output = self.gcloud_client.scale_cluster(cluster_name, location, node_count)
            
            if success:
                await message.edit_text(
                    f"**Cluster scaled successfully**\n\n"
                    f"**Cluster**: `{cluster_name}`\n"
                    f"**Location**: `{location}`\n"
                    f"**New Node Count**: `{node_count}`\n\n"
                    f"The scaling operation is in progress. "
                    f"Check status with `/status` command."
                )
            else:
                await message.edit_text(
                    f"**Scaling failed**\n\n"
                    f"**Cluster**: `{cluster_name}`\n"
                    f"**Location**: `{location}`\n"
                    f"**Target Node Count**: `{node_count}`\n\n"
                    f"**Error**: {output}"
                )
                
        except Exception as e:
            logger.error(f"Error handling scale command: {e}")
            await update.effective_message.reply_text(
                f"Error scaling cluster: {str(e)}"
            )
    
    async def handle_logs_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /logs command - get cluster logs"""
        try:
            # Check if required arguments are provided
            if len(context.args) < 2:
                await update.effective_message.reply_text(
                    "Please provide cluster name and location.\n"
                    "Usage: /logs <cluster_name> <location> [lines]\n"
                    "Example: /logs my-cluster us-central1 50"
                )
                return
            
            cluster_name = context.args[0]
            location = context.args[1]
            lines = int(context.args[2]) if len(context.args) > 2 else 100
            
            # Send initial message
            message = await update.effective_message.reply_text(
                f"Fetching logs for cluster `{cluster_name}`..."
            )
            
            # Get cluster logs
            success, output = self.gcloud_client.get_cluster_logs(cluster_name, location, lines)
            
            if success:
                # Truncate output if too long
                if len(output) > 4000:
                    output = output[:4000] + "\n\n... (logs truncated)"
                
                await message.edit_text(
                    f"**Cluster Logs**\n\n"
                    f"**Cluster**: `{cluster_name}`\n"
                    f"**Location**: `{location}`\n"
                    f"**Lines**: `{lines}`\n\n"
                    f"**Logs**:\n```\n{output}\n```",
                    parse_mode='Markdown'
                )
            else:
                await message.edit_text(
                    f"**Failed to get logs**\n\n"
                    f"**Cluster**: `{cluster_name}`\n"
                    f"**Location**: `{location}`\n\n"
                    f"**Error**: {output}"
                )
                
        except Exception as e:
            logger.error(f"Error handling logs command: {e}")
            await update.effective_message.reply_text(
                f"Error getting logs: {str(e)}"
            )
    
    async def handle_restart_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /restart command - restart node pool"""
        try:
            # Check if required arguments are provided
            if len(context.args) < 3:
                await update.effective_message.reply_text(
                    "Please provide cluster name, location, and node pool name.\n"
                    "Usage: /restart <cluster_name> <location> <node_pool_name>\n"
                    "Example: /restart my-cluster us-central1 default-pool"
                )
                return
            
            cluster_name = context.args[0]
            location = context.args[1]
            node_pool_name = context.args[2]
            
            # Send initial message
            message = await update.effective_message.reply_text(
                f"Restarting node pool `{node_pool_name}` in cluster `{cluster_name}`..."
            )
            
            # Execute restart command
            success, output = self.gcloud_client.restart_node_pool(cluster_name, location, node_pool_name)
            
            if success:
                await message.edit_text(
                    f"**Node pool restart initiated**\n\n"
                    f"**Cluster**: `{cluster_name}`\n"
                    f"**Location**: `{location}`\n"
                    f"**Node Pool**: `{node_pool_name}`\n\n"
                    f"The rolling update is in progress. "
                    f"Check status with `/status` command."
                )
            else:
                await message.edit_text(
                    f"**Restart failed**\n\n"
                    f"**Cluster**: `{cluster_name}`\n"
                    f"**Location**: `{location}`\n"
                    f"**Node Pool**: `{node_pool_name}`\n\n"
                    f"**Error**: {output}"
                )
                
        except Exception as e:
            logger.error(f"Error handling restart command: {e}")
            await update.effective_message.reply_text(
                f"Error restarting node pool: {str(e)}"
            )
    
    def _is_command_safe(self, command: str) -> bool:
        """Check if a gcloud command is safe to execute"""
        # List of allowed command prefixes
        allowed_prefixes = [
            'container clusters list',
            'container clusters describe',
            'container node-pools list',
            'container node-pools describe',
            'compute instances list',
            'compute instances describe',
            'compute networks list',
            'compute regions list',
            'storage ls',
            'projects describe',
            'projects get-iam-policy',
            'billing accounts list',
            'billing projects describe'
        ]
        
        # Check if command starts with any allowed prefix
        for prefix in allowed_prefixes:
            if command.startswith(prefix):
                return True
        
        # Check for management commands that are safe
        safe_management = [
            'container clusters resize',
            'container node-pools rolling-update'
        ]
        
        for safe_cmd in safe_management:
            if command.startswith(safe_cmd):
                return True
        
        return False

    async def handle_clusters_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /clusters command - show all GKE clusters"""
        try:
            # Send initial message
            message = await update.effective_message.reply_text("Fetching cluster information...")
            
            # Get clusters data
            clusters = self.gcloud_client.get_clusters()
            
            if not clusters:
                await message.edit_text("No clusters found or failed to retrieve cluster information.")
                return
            
            # Format clusters information
            clusters_text = "**GKE Clusters Overview**\n\n"
            
            for i, cluster in enumerate(clusters, 1):
                status_symbol = self._get_status_symbol(cluster.get('status', 'UNKNOWN'))
                clusters_text += (
                    f"{i}. **{cluster.get('name', 'Unknown')}** {status_symbol}\n"
                    f"   Location: `{cluster.get('location', 'Unknown')}`\n"
                    f"   Status: `{cluster.get('status', 'Unknown')}`\n"
                    f"   Version: `{cluster.get('version', 'Unknown')}`\n"
                    f"   Nodes: `{cluster.get('node_count', 'Unknown')}`\n"
                    f"   Network: `{cluster.get('network', 'Unknown')}`\n"
                    f"   Created: `{cluster.get('created_at', 'Unknown')}`\n\n"
                )
            
            # Add inline buttons for detailed views
            keyboard = [
                [InlineKeyboardButton("Node Details", callback_data="nodes")],
                [InlineKeyboardButton("Cluster Status", callback_data="status")],
                [InlineKeyboardButton("Billing Info", callback_data="billing")]
            ]
            reply_markup = InlineKeyboardMarkup(keyboard)
            
            await message.edit_text(clusters_text, reply_markup=reply_markup, parse_mode='Markdown')
            
        except Exception as e:
            logger.error(f"Error handling clusters command: {e}")
            await update.effective_message.reply_text(
                f"Error retrieving cluster information: {str(e)}"
            )
    
    async def handle_billing_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /billing command - show billing information"""
        try:
            # Send initial message
            message = await update.effective_message.reply_text("Fetching billing information...")
            
            # Get billing data
            billing_info = self.gcloud_client.get_billing_info()
            project_info = self.gcloud_client.get_project_info()
            
            if 'error' in billing_info:
                await message.edit_text(f"Error retrieving billing information: {billing_info['error']}")
                return
            
            # Format billing information
            billing_text = "**Google Cloud Billing Overview**\n\n"
            
            # Project information
            if 'error' not in project_info:
                billing_text += (
                    f"**Project Information**\n"
                    f"   Project ID: `{project_info.get('project_id', 'Unknown')}`\n"
                    f"   Display Name: `{project_info.get('name', 'Unknown')}`\n"
                    f"   State: `{project_info.get('state', 'Unknown')}`\n"
                    f"   Created: `{project_info.get('created_at', 'Unknown')}`\n\n"
                )
            
            # Billing information
            billing_text += (
                f"**Billing Details**\n"
                f"   Billing Enabled: `{'Yes' if billing_info.get('billing_enabled') else 'No'}`\n"
                f"   Billing Account: `{billing_info.get('billing_account', 'Unknown')}`\n"
                f"   Current Month Cost: `{billing_info.get('current_month_cost', 'Not available')}`\n\n"
            )
            
            # Add cost optimization tips
            billing_text += (
                "**Cost Optimization Tips**\n"
                "• Use preemptible instances for non-critical workloads\n"
                "• Enable autoscaling to scale down during low usage\n"
                "• Monitor and optimize storage usage\n"
                "• Use committed use discounts for predictable workloads\n"
            )
            
            # Add inline buttons
            keyboard = [
                [InlineKeyboardButton("Clusters", callback_data="clusters")],
                [InlineKeyboardButton("Nodes", callback_data="nodes")],
                [InlineKeyboardButton("Cost Analysis", callback_data="costs")]
            ]
            reply_markup = InlineKeyboardMarkup(keyboard)
            
            await message.edit_text(billing_text, reply_markup=reply_markup, parse_mode='Markdown')
            
        except Exception as e:
            logger.error(f"Error handling billing command: {e}")
            await update.effective_message.reply_text(
                f"Error retrieving billing information: {str(e)}"
            )
    
    async def handle_nodes_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /nodes command - show cluster node information"""
        try:
            # Send initial message
            message = await update.effective_message.reply_text("Fetching node information...")
            
            # Get clusters first to show node pools
            clusters = self.gcloud_client.get_clusters()
            
            if not clusters:
                await message.edit_text("No clusters found to retrieve node information.")
                return
            
            # Format nodes information
            nodes_text = "**Cluster Nodes Overview**\n\n"
            
            for i, cluster in enumerate(clusters, 1):
                nodes_text += f"**Cluster {i}: {cluster.get('name', 'Unknown')}**\n"
                
                # Get node pools for this cluster
                node_pools = self.gcloud_client.get_cluster_nodes(
                    cluster.get('name', ''), 
                    cluster.get('location', '')
                )
                
                if node_pools:
                    for j, node_pool in enumerate(node_pools, 1):
                        status_symbol = self._get_status_symbol(node_pool.get('status', 'UNKNOWN'))
                        nodes_text += (
                            f"  {j}. **{node_pool.get('name', 'Unknown')}** {status_symbol}\n"
                            f"     Version: `{node_pool.get('version', 'Unknown')}`\n"
                            f"     Status: `{node_pool.get('status', 'Unknown')}`\n"
                            f"     Node Count: `{node_pool.get('node_count', 'Unknown')}`\n"
                            f"     Machine Type: `{node_pool.get('machine_type', 'Unknown')}`\n"
                            f"     Disk Size: `{node_pool.get('disk_size_gb', 'Unknown')} GB`\n"
                            f"     Image Type: `{node_pool.get('image_type', 'Unknown')}`\n"
                        )
                        
                        # Autoscaling information
                        autoscaling = node_pool.get('autoscaling', {})
                        if autoscaling.get('enabled'):
                            nodes_text += (
                                f"     Autoscaling: `Enabled` "
                                f"({autoscaling.get('min_node_count', '?')}-{autoscaling.get('max_node_count', '?')})\n"
                            )
                        else:
                            nodes_text += "     Autoscaling: `Disabled`\n"
                        
                        nodes_text += "\n"
                else:
                    nodes_text += "  No node pools found\n\n"
            
            # Add inline buttons
            keyboard = [
                [InlineKeyboardButton("Clusters", callback_data="clusters")],
                [InlineKeyboardButton("Billing", callback_data="billing")],
                [InlineKeyboardButton("Status", callback_data="status")]
            ]
            reply_markup = InlineKeyboardMarkup(keyboard)
            
            await message.edit_text(nodes_text, reply_markup=reply_markup, parse_mode='Markdown')
            
        except Exception as e:
            logger.error(f"Error handling nodes command: {e}")
            await update.effective_message.reply_text(
                f"Error retrieving node information: {str(e)}"
            )
    
    async def handle_costs_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /costs command - show cost analysis"""
        try:
            # Send initial message
            message = await update.effective_message.reply_text("Analyzing costs...")
            
            # Get clusters and billing info for cost analysis
            clusters = self.gcloud_client.get_clusters()
            billing_info = self.gcloud_client.get_billing_info()
            
            # Format cost analysis
            costs_text = "**Cost Analysis & Optimization**\n\n"
            
            # Cluster cost factors
            costs_text += "**Infrastructure Cost Factors**\n"
            total_nodes = sum(cluster.get('node_count', 0) for cluster in clusters)
            costs_text += f"   Total Nodes: `{total_nodes}`\n"
            costs_text += f"   Total Clusters: `{len(clusters)}`\n\n"
            
            # Cost optimization recommendations
            costs_text += "**Cost Optimization Recommendations**\n"
            
            if total_nodes > 10:
                costs_text += "   High node count detected - consider consolidation\n"
            elif total_nodes > 5:
                costs_text += "   Moderate node count - review autoscaling policies\n"
            else:
                costs_text += "   Node count looks reasonable\n"
            
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
                costs_text += "   Autoscaling is enabled - good for cost optimization\n"
            else:
                costs_text += "   Consider enabling autoscaling for cost savings\n"
            
            # Billing status
            if billing_info.get('billing_enabled'):
                costs_text += "   Billing is enabled and monitored\n"
            else:
                costs_text += "   Billing is disabled - enable for cost tracking\n"
            
            costs_text += "\n"
            
            # Cost saving tips
            costs_text += "**Cost Saving Strategies**\n"
            costs_text += "• Use preemptible instances (up to 80% savings)\n"
            "• Enable autoscaling for variable workloads\n"
            "• Use committed use discounts for stable workloads\n"
            "• Monitor and optimize storage usage\n"
            "• Consider regional vs multi-regional storage\n"
            "• Use Cloud Functions for event-driven workloads\n"
            
            # Add inline buttons
            keyboard = [
                [InlineKeyboardButton("Clusters", callback_data="clusters")],
                [InlineKeyboardButton("Billing", callback_data="billing")],
                [InlineKeyboardButton("Nodes", callback_data="nodes")]
            ]
            reply_markup = InlineKeyboardMarkup(keyboard)
            
            await message.edit_text(costs_text, reply_markup=reply_markup, parse_mode='Markdown')
            
        except Exception as e:
            logger.error(f"Error handling costs command: {e}")
            await update.effective_message.reply_text(
                f"Error analyzing costs: {str(e)}"
            )
    
    async def handle_status_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /status command - show overall system status"""
        try:
            # Send initial message
            message = await update.effective_message.reply_text("Checking system status...")
            
            # Test GCloud connection
            connection_status = self.gcloud_client.test_connection()
            
            # Get basic information
            clusters = self.gcloud_client.get_clusters()
            project_info = self.gcloud_client.get_project_info()
            billing_info = self.gcloud_client.get_billing_info()
            
            # Format status information
            status_text = "**System Status Overview**\n\n"
            
            # Connection status
            if connection_status:
                status_text += "**GCloud Connection**: `Connected`\n"
            else:
                status_text += "**GCloud Connection**: `Failed`\n"
            
            # Project status
            if 'error' not in project_info:
                status_text += f"**Project**: `{project_info.get('project_id', 'Unknown')}`\n"
                status_text += f"   State: `{project_info.get('state', 'Unknown')}`\n"
            else:
                status_text += "**Project**: `Error retrieving project info`\n"
            
            # Clusters status
            if clusters:
                status_text += f"**Clusters**: `{len(clusters)} found`\n"
                
                # Count clusters by status
                status_counts = {}
                for cluster in clusters:
                    status = cluster.get('status', 'UNKNOWN')
                    status_counts[status] = status_counts.get(status, 0) + 1
                
                for status, count in status_counts.items():
                    status_symbol = self._get_status_symbol(status)
                    status_text += f"   {status_symbol} {status}: `{count}`\n"
            else:
                status_text += "**Clusters**: `No clusters found`\n"
            
            # Billing status
            if 'error' not in billing_info:
                billing_enabled = billing_info.get('billing_enabled', False)
                status_text += f"**Billing**: `{'Enabled' if billing_enabled else 'Disabled'}`\n"
            else:
                status_text += "**Billing**: `Error retrieving billing info`\n"
            
            status_text += "\n"
            
            # Overall health assessment
            if connection_status and clusters and 'error' not in project_info:
                if any(cluster.get('status') == 'RUNNING' for cluster in clusters):
                    status_text += "**Overall Status**: `Healthy`\n"
                else:
                    status_text += "**Overall Status**: `Warning - No running clusters`\n"
            elif not connection_status:
                status_text += "**Overall Status**: `Critical - Connection failed`\n"
            else:
                status_text += "**Overall Status**: `Warning - Some issues detected`\n"
            
            # Add inline buttons
            keyboard = [
                [InlineKeyboardButton("Clusters", callback_data="clusters")],
                [InlineKeyboardButton("Billing", callback_data="billing")],
                [InlineKeyboardButton("Nodes", callback_data="nodes")]
            ]
            reply_markup = InlineKeyboardMarkup(keyboard)
            
            await message.edit_text(status_text, reply_markup=reply_markup, parse_mode='Markdown')
            
        except Exception as e:
            logger.error(f"Error handling status command: {e}")
            await update.effective_message.reply_text(
                f"Error checking system status: {str(e)}"
            )
    
    async def handle_ethereum_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """Handle /ethereum command - show Ethereum nodes information"""
        try:
            message = await update.effective_message.reply_text("Fetching Ethereum nodes information...")
            
            ethereum_info = self.gcloud_client.get_ethereum_nodes_info()
            
            if 'error' in ethereum_info:
                await message.edit_text(f"Error retrieving Ethereum nodes info: {ethereum_info['error']}")
                return
            
            # Format Ethereum nodes information
            eth_text = "**Ethereum Nodes Status**\n\n"
            
            # Overall status
            status = ethereum_info.get('status', 'unknown')
            status_symbol = '🟢' if status == 'running' else '🔴' if status == 'not_found' else '🟡'
            eth_text += f"**Overall Status**: {status_symbol} {status.upper()}\n\n"
            
            # Lighthouse nodes
            lighthouse_nodes = ethereum_info.get('lighthouse_nodes', [])
            eth_text += f"**Lighthouse Nodes**: {len(lighthouse_nodes)}\n"
            
            if lighthouse_nodes:
                for i, node in enumerate(lighthouse_nodes[:5], 1):  # Show first 5
                    node_type = node.get('type', 'cluster')
                    name = node.get('name', 'Unknown')
                    status = node.get('status', 'Unknown')
                    
                    if node_type == 'cluster':
                        cluster = node.get('cluster', 'Unknown')
                        location = node.get('location', 'Unknown')
                        node_count = node.get('node_count', 0)
                        machine_type = node.get('machine_type', 'Unknown')
                        eth_text += f"   {i}. {name} ({cluster})\n"
                        eth_text += f"      Location: {location}, Nodes: {node_count}\n"
                        eth_text += f"      Machine: {machine_type}, Status: {status}\n"
                    else:
                        zone = node.get('zone', 'Unknown')
                        machine_type = node.get('machine_type', 'Unknown')
                        internal_ip = node.get('internal_ip', 'N/A')
                        eth_text += f"   {i}. {name} (Compute Instance)\n"
                        eth_text += f"      Zone: {zone}, Machine: {machine_type}\n"
                        eth_text += f"      IP: {internal_ip}, Status: {status}\n"
                    
                    if i < len(lighthouse_nodes) and i < 5:
                        eth_text += "\n"
                
                if len(lighthouse_nodes) > 5:
                    eth_text += f"   ... and {len(lighthouse_nodes) - 5} more\n"
            else:
                eth_text += "   No Lighthouse nodes found\n"
            
            eth_text += "\n"
            
            # Geth nodes
            geth_nodes = ethereum_info.get('geth_nodes', [])
            eth_text += f"**Geth Nodes**: {len(geth_nodes)}\n"
            
            if geth_nodes:
                for i, node in enumerate(geth_nodes[:5], 1):  # Show first 5
                    node_type = node.get('type', 'cluster')
                    name = node.get('name', 'Unknown')
                    status = node.get('status', 'Unknown')
                    
                    if node_type == 'cluster':
                        cluster = node.get('cluster', 'Unknown')
                        location = node.get('location', 'Unknown')
                        node_count = node.get('node_count', 0)
                        machine_type = node.get('machine_type', 'Unknown')
                        eth_text += f"   {i}. {name} ({cluster})\n"
                        eth_text += f"      Location: {location}, Nodes: {node_count}\n"
                        eth_text += f"      Machine: {machine_type}, Status: {status}\n"
                    else:
                        zone = node.get('zone', 'Unknown')
                        machine_type = node.get('machine_type', 'Unknown')
                        internal_ip = node.get('internal_ip', 'N/A')
                        eth_text += f"   {i}. {name} (Compute Instance)\n"
                        eth_text += f"      Zone: {zone}, Machine: {machine_type}\n"
                        eth_text += f"      IP: {internal_ip}, Status: {status}\n"
                    
                    if i < len(geth_nodes) and i < 5:
                        eth_text += "\n"
                
                if len(geth_nodes) > 5:
                    eth_text += f"   ... and {len(geth_nodes) - 5} more\n"
            else:
                eth_text += "   No Geth nodes found\n"
            
            # Summary
            total_nodes = ethereum_info.get('total_nodes', 0)
            eth_text += f"\n**Total Ethereum Nodes**: {total_nodes}"
            
            # Add inline buttons
            keyboard = [
                [InlineKeyboardButton("Refresh", callback_data="ethereum")],
                [InlineKeyboardButton("Clusters", callback_data="clusters")],
                [InlineKeyboardButton("Instances", callback_data="instances")],
                [InlineKeyboardButton("Status", callback_data="status")]
            ]
            reply_markup = InlineKeyboardMarkup(keyboard)
            
            await message.edit_text(eth_text, reply_markup=reply_markup, parse_mode='Markdown')
            
        except Exception as e:
            logger.error(f"Error handling ethereum command: {e}")
            await update.effective_message.reply_text(
                f"Error retrieving Ethereum nodes info: {str(e)}"
            )
    
    def _get_status_symbol(self, status: str) -> str:
        """Get appropriate symbol for cluster/node status"""
        status = status.upper()
        if status == 'RUNNING':
            return '[OK]'
        elif status == 'PROVISIONING':
            return '[PROV]'
        elif status == 'STOPPING':
            return '[STOP]'
        elif status == 'ERROR':
            return '[ERR]'
        elif status == 'DEGRADED':
            return '[DEG]'
        else:
            return '[?]'
