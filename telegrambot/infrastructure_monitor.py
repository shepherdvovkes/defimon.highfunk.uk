#!/usr/bin/env python3
"""
Infrastructure Monitor for Google Cloud - Automated Monitoring and Alerting
"""

import os
import logging
import asyncio
import time
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
from dotenv import load_dotenv

from telegram import Bot
from gcloud_client import GCloudClient

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

class InfrastructureMonitor:
    def __init__(self):
        """Initialize the infrastructure monitor"""
        self.token = os.getenv('TELEGRAM_BOT_TOKEN')
        if not self.token:
            raise ValueError("TELEGRAM_BOT_TOKEN environment variable is required")
        
        self.chat_id = os.getenv('TELEGRAM_CHAT_ID')
        if not self.chat_id:
            raise ValueError("TELEGRAM_CHAT_ID environment variable is required")
        
        self.additional_chat_ids = os.getenv('ADDITIONAL_CHAT_IDS', '').split(',') if os.getenv('ADDITIONAL_CHAT_IDS') else []
        
        # Initialize clients
        self.bot = Bot(token=self.token)
        self.gcloud_client = GCloudClient()
        
        # Monitoring configuration
        self.enable_cluster_monitoring = os.getenv('ENABLE_CLUSTER_MONITORING', 'true').lower() == 'true'
        self.enable_node_monitoring = os.getenv('ENABLE_NODE_MONITORING', 'true').lower() == 'true'
        self.enable_billing_monitoring = os.getenv('ENABLE_BILLING_MONITORING', 'true').lower() == 'true'
        self.enable_resource_monitoring = os.getenv('ENABLE_RESOURCE_MONITORING', 'true').lower() == 'true'
        self.enable_alerting = os.getenv('ENABLE_ALERTING', 'true').lower() == 'true'
        
        # Monitoring intervals (in seconds)
        self.cluster_check_interval = int(os.getenv('CLUSTER_CHECK_INTERVAL', '300'))
        self.node_check_interval = int(os.getenv('NODE_CHECK_INTERVAL', '600'))
        self.billing_check_interval = int(os.getenv('BILLING_CHECK_INTERVAL', '3600'))
        self.resource_check_interval = int(os.getenv('RESOURCE_CHECK_INTERVAL', '300'))
        
        # Alert thresholds
        self.cpu_usage_threshold = int(os.getenv('CPU_USAGE_THRESHOLD', '80'))
        self.memory_usage_threshold = int(os.getenv('MEMORY_USAGE_THRESHOLD', '85'))
        self.disk_usage_threshold = int(os.getenv('DISK_USAGE_THRESHOLD', '90'))
        self.node_error_threshold = int(os.getenv('NODE_ERROR_THRESHOLD', '3'))
        
        # State tracking
        self.last_cluster_status = {}
        self.last_node_status = {}
        self.last_billing_status = {}
        self.last_resource_status = {}
        self.alert_history = {}
        
        logger.info("Infrastructure Monitor initialized successfully")
    
    async def start_monitoring(self):
        """Start the monitoring loop"""
        logger.info("Starting infrastructure monitoring...")
        
        try:
            # Send startup notification
            await self._send_notification(
                "🚀 **Infrastructure Monitor Started**\n\n"
                "Monitoring your Google Cloud infrastructure for:\n"
                "• Cluster health and status\n"
                "• Node pool performance\n"
                "• Resource usage and quotas\n"
                "• Billing and cost alerts\n\n"
                "Monitoring intervals:\n"
                f"• Clusters: every {self.cluster_check_interval}s\n"
                f"• Nodes: every {self.node_check_interval}s\n"
                f"• Resources: every {self.resource_check_interval}s\n"
                f"• Billing: every {self.billing_check_interval}s"
            )
            
            # Start monitoring tasks
            tasks = []
            
            if self.enable_cluster_monitoring:
                tasks.append(self._cluster_monitoring_loop())
            
            if self.enable_node_monitoring:
                tasks.append(self._node_monitoring_loop())
            
            if self.enable_resource_monitoring:
                tasks.append(self._resource_monitoring_loop())
            
            if self.enable_billing_monitoring:
                tasks.append(self._billing_monitoring_loop())
            
            # Run all monitoring tasks concurrently
            await asyncio.gather(*tasks)
            
        except Exception as e:
            logger.error(f"Monitoring failed: {e}")
            await self._send_notification(f"❌ **Monitoring Failed**: {str(e)}")
            raise
    
    async def _cluster_monitoring_loop(self):
        """Monitor cluster health and status"""
        while True:
            try:
                await self._check_clusters()
                await asyncio.sleep(self.cluster_check_interval)
            except Exception as e:
                logger.error(f"Cluster monitoring error: {e}")
                await asyncio.sleep(60)  # Wait 1 minute before retrying
    
    async def _node_monitoring_loop(self):
        """Monitor node pool health and performance"""
        while True:
            try:
                await self._check_nodes()
                await asyncio.sleep(self.node_check_interval)
            except Exception as e:
                logger.error(f"Node monitoring error: {e}")
                await asyncio.sleep(60)  # Wait 1 minute before retrying
    
    async def _resource_monitoring_loop(self):
        """Monitor resource usage and quotas"""
        while True:
            try:
                await self._check_resources()
                await asyncio.sleep(self.resource_check_interval)
            except Exception as e:
                logger.error(f"Resource monitoring error: {e}")
                await asyncio.sleep(60)  # Wait 1 minute before retrying
    
    async def _billing_monitoring_loop(self):
        """Monitor billing and cost alerts"""
        while True:
            try:
                await self._check_billing()
                await asyncio.sleep(self.billing_check_interval)
            except Exception as e:
                logger.error(f"Billing monitoring error: {e}")
                await asyncio.sleep(60)  # Wait 1 minute before retrying
    
    async def _check_clusters(self):
        """Check cluster health and status"""
        try:
            clusters = self.gcloud_client.get_clusters()
            current_time = datetime.now()
            
            for cluster in clusters:
                cluster_name = cluster.get('name', 'Unknown')
                cluster_location = cluster.get('location', 'Unknown')
                cluster_status = cluster.get('status', 'UNKNOWN')
                
                # Check for status changes
                cluster_key = f"{cluster_name}_{cluster_location}"
                last_status = self.last_cluster_status.get(cluster_key)
                
                if last_status != cluster_status:
                    # Status changed
                    if last_status:  # Not the first check
                        await self._send_cluster_alert(cluster, last_status, cluster_status)
                    
                    self.last_cluster_status[cluster_key] = cluster_status
                
                # Check for critical status
                if cluster_status in ['ERROR', 'DEGRADED']:
                    await self._send_critical_cluster_alert(cluster)
                
                # Check node count changes
                current_node_count = cluster.get('node_count', 0)
                last_node_count = self.last_cluster_status.get(f"{cluster_key}_nodes", current_node_count)
                
                if abs(current_node_count - last_node_count) > 0:
                    if last_node_count != current_node_count:  # Not the first check
                        await self._send_node_count_alert(cluster, last_node_count, current_node_count)
                    
                    self.last_cluster_status[f"{cluster_key}_nodes"] = current_node_count
            
            logger.info(f"Cluster monitoring completed at {current_time}")
            
        except Exception as e:
            logger.error(f"Error checking clusters: {e}")
            await self._send_notification(f"❌ **Cluster Monitoring Error**: {str(e)}")
    
    async def _check_nodes(self):
        """Check node pool health and performance"""
        try:
            clusters = self.gcloud_client.get_clusters()
            current_time = datetime.now()
            
            for cluster in clusters:
                cluster_name = cluster.get('name', 'Unknown')
                cluster_location = cluster.get('location', 'Unknown')
                
                node_pools = self.gcloud_client.get_cluster_nodes(cluster_name, cluster_location)
                
                for node_pool in node_pools:
                    pool_name = node_pool.get('name', 'Unknown')
                    pool_status = node_pool.get('status', 'UNKNOWN')
                    pool_key = f"{cluster_name}_{cluster_location}_{pool_name}"
                    
                    # Check for status changes
                    last_status = self.last_node_status.get(pool_key)
                    
                    if last_status != pool_status:
                        if last_status:  # Not the first check
                            await self._send_node_pool_alert(cluster, node_pool, last_status, pool_status)
                        
                        self.last_node_status[pool_key] = pool_status
                    
                    # Check autoscaling status
                    autoscaling = node_pool.get('autoscaling', {})
                    if autoscaling.get('enabled'):
                        current_count = node_pool.get('node_count', 0)
                        min_count = autoscaling.get('min_node_count', 0)
                        max_count = autoscaling.get('max_node_count', 0)
                        
                        if current_count <= min_count:
                            await self._send_autoscaling_alert(cluster, node_pool, "min_threshold")
                        elif current_count >= max_count:
                            await self._send_autoscaling_alert(cluster, node_pool, "max_threshold")
            
            logger.info(f"Node monitoring completed at {current_time}")
            
        except Exception as e:
            logger.error(f"Error checking nodes: {e}")
            await self._send_notification(f"❌ **Node Monitoring Error**: {str(e)}")
    
    async def _check_resources(self):
        """Check resource usage and quotas"""
        try:
            current_time = datetime.now()
            
            # Get infrastructure overview for resource monitoring
            infrastructure = self.gcloud_client.get_infrastructure_overview()
            
            if 'error' not in infrastructure:
                # Check quotas
                quotas = infrastructure.get('quotas', {})
                for metric, quota in quotas.items():
                    usage = quota.get('usage', 0)
                    limit = quota.get('limit', 0)
                    
                    if limit > 0:
                        percentage = (usage / limit) * 100
                        
                        if percentage >= 90:
                            await self._send_quota_alert(metric, usage, limit, percentage, "critical")
                        elif percentage >= 80:
                            await self._send_quota_alert(metric, usage, limit, percentage, "warning")
                
                # Check resource usage for specific clusters
                clusters = infrastructure.get('clusters', [])
                for cluster in clusters:
                    cluster_name = cluster.get('name', 'Unknown')
                    cluster_location = cluster.get('location', 'Unknown')
                    
                    resource_usage = self.gcloud_client.get_resource_usage(cluster_name, cluster_location)
                    
                    if 'error' not in resource_usage:
                        # Check CPU usage
                        cpu_usage = resource_usage.get('cpu_usage', {})
                        if isinstance(cpu_usage, dict) and 'utilization_percent' in cpu_usage:
                            cpu_percent = cpu_usage['utilization_percent']
                            if cpu_percent >= self.cpu_usage_threshold:
                                await self._send_resource_alert(cluster, "CPU", cpu_percent, "high_usage")
                        
                        # Check memory usage
                        memory_usage = resource_usage.get('memory_usage', {})
                        if isinstance(memory_usage, dict) and 'utilization_percent' in memory_usage:
                            memory_percent = memory_usage['utilization_percent']
                            if memory_percent >= self.memory_usage_threshold:
                                await self._send_resource_alert(cluster, "Memory", memory_percent, "high_usage")
                        
                        # Check disk usage
                        disk_usage = resource_usage.get('disk_usage', {})
                        if isinstance(disk_usage, dict) and 'utilization_percent' in disk_usage:
                            disk_percent = disk_usage['utilization_percent']
                            if disk_percent >= self.disk_usage_threshold:
                                await self._send_resource_alert(cluster, "Disk", disk_percent, "high_usage")
            
            logger.info(f"Resource monitoring completed at {current_time}")
            
        except Exception as e:
            logger.error(f"Error checking resources: {e}")
            await self._send_notification(f"❌ **Resource Monitoring Error**: {str(e)}")
    
    async def _check_billing(self):
        """Check billing and cost alerts"""
        try:
            current_time = datetime.now()
            
            # Get billing information
            billing_info = self.gcloud_client.get_billing_info()
            
            if 'error' not in billing_info:
                # Check if billing is enabled
                if not billing_info.get('billing_enabled'):
                    await self._send_billing_alert("billing_disabled", billing_info)
                
                # Check current month costs (if available)
                current_month_cost = billing_info.get('current_month_cost')
                if current_month_cost and current_month_cost != "Not available":
                    # Here you could implement cost threshold checking
                    # For now, just log the information
                    logger.info(f"Current month cost: {current_month_cost}")
            
            logger.info(f"Billing monitoring completed at {current_time}")
            
        except Exception as e:
            logger.error(f"Error checking billing: {e}")
            await self._send_notification(f"❌ **Billing Monitoring Error**: {str(e)}")
    
    async def _send_cluster_alert(self, cluster: Dict[str, Any], old_status: str, new_status: str):
        """Send cluster status change alert"""
        if not self.enable_alerting:
            return
        
        cluster_name = cluster.get('name', 'Unknown')
        cluster_location = cluster.get('location', 'Unknown')
        
        status_emoji = self._get_status_emoji(new_status)
        old_status_emoji = self._get_status_emoji(old_status)
        
        message = (
            f"🔄 **Cluster Status Changed**\n\n"
            f"📊 **Cluster**: `{cluster_name}`\n"
            f"🗺️ **Location**: `{cluster_location}`\n"
            f"📈 **Status Change**: {old_status_emoji} `{old_status}` → {status_emoji} `{new_status}`\n"
            f"⏰ **Time**: `{datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}`\n\n"
            f"Use `/status` to check current system status."
        )
        
        await self._send_notification(message)
    
    async def _send_critical_cluster_alert(self, cluster: Dict[str, Any]):
        """Send critical cluster alert"""
        if not self.enable_alerting:
            return
        
        cluster_name = cluster.get('name', 'Unknown')
        cluster_location = cluster.get('location', 'Unknown')
        cluster_status = cluster.get('status', 'UNKNOWN')
        
        status_emoji = self._get_status_emoji(cluster_status)
        
        message = (
            f"🚨 **Critical Cluster Alert**\n\n"
            f"📊 **Cluster**: `{cluster_name}`\n"
            f"🗺️ **Location**: `{cluster_location}`\n"
            f"🚨 **Status**: {status_emoji} `{cluster_status}`\n"
            f"⏰ **Time**: `{datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}`\n\n"
            f"⚠️ **Action Required**: This cluster requires immediate attention!\n\n"
            f"Use `/clusters` to view all clusters or `/status` for system overview."
        )
        
        await self._send_notification(message)
    
    async def _send_node_count_alert(self, cluster: Dict[str, Any], old_count: int, new_count: int):
        """Send node count change alert"""
        if not self.enable_alerting:
            return
        
        cluster_name = cluster.get('name', 'Unknown')
        cluster_location = cluster.get('location', 'Unknown')
        
        change_emoji = "📈" if new_count > old_count else "📉"
        
        message = (
            f"{change_emoji} **Cluster Node Count Changed**\n\n"
            f"📊 **Cluster**: `{cluster_name}`\n"
            f"🗺️ **Location**: `{cluster_location}`\n"
            f"🖥️ **Node Count**: `{old_count}` → `{new_count}`\n"
            f"⏰ **Time**: `{datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}`\n\n"
            f"Use `/nodes` to view detailed node information."
        )
        
        await self._send_notification(message)
    
    async def _send_node_pool_alert(self, cluster: Dict[str, Any], node_pool: Dict[str, Any], old_status: str, new_status: str):
        """Send node pool status change alert"""
        if not self.enable_alerting:
            return
        
        cluster_name = cluster.get('name', 'Unknown')
        cluster_location = cluster.get('location', 'Unknown')
        pool_name = node_pool.get('name', 'Unknown')
        
        status_emoji = self._get_status_emoji(new_status)
        old_status_emoji = self._get_status_emoji(old_status)
        
        message = (
            f"🔄 **Node Pool Status Changed**\n\n"
            f"📊 **Cluster**: `{cluster_name}`\n"
            f"🗺️ **Location**: `{cluster_location}`\n"
            f"🖥️ **Node Pool**: `{pool_name}`\n"
            f"📈 **Status Change**: {old_status_emoji} `{old_status}` → {status_emoji} `{new_status}`\n"
            f"⏰ **Time**: `{datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}`\n\n"
            f"Use `/nodes` to view detailed node information."
        )
        
        await self._send_notification(message)
    
    async def _send_autoscaling_alert(self, cluster: Dict[str, Any], node_pool: Dict[str, Any], alert_type: str):
        """Send autoscaling alert"""
        if not self.enable_alerting:
            return
        
        cluster_name = cluster.get('name', 'Unknown')
        cluster_location = cluster.get('location', 'Unknown')
        pool_name = node_pool.get('name', 'Unknown')
        
        if alert_type == "min_threshold":
            message = (
                f"⚠️ **Autoscaling Min Threshold Reached**\n\n"
                f"📊 **Cluster**: `{cluster_name}`\n"
                f"🗺️ **Location**: `{cluster_location}`\n"
                f"🖥️ **Node Pool**: `{pool_name}`\n"
                f"⚠️ **Warning**: Node count at minimum threshold\n"
                f"⏰ **Time**: `{datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}`\n\n"
                f"Consider scaling up if this is unexpected."
            )
        else:  # max_threshold
            message = (
                f"⚠️ **Autoscaling Max Threshold Reached**\n\n"
                f"📊 **Cluster**: `{cluster_name}`\n"
                f"🗺️ **Location**: `{cluster_location}`\n"
                f"🖥️ **Node Pool**: `{pool_name}`\n"
                f"⚠️ **Warning**: Node count at maximum threshold\n"
                f"⏰ **Time**: `{datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}`\n\n"
                f"Consider scaling up the maximum if this is expected."
            )
        
        await self._send_notification(message)
    
    async def _send_quota_alert(self, metric: str, usage: int, limit: int, percentage: float, severity: str):
        """Send quota alert"""
        if not self.enable_alerting:
            return
        
        severity_emoji = "🚨" if severity == "critical" else "⚠️"
        severity_text = "Critical" if severity == "critical" else "Warning"
        
        message = (
            f"{severity_emoji} **Resource Quota {severity_text}**\n\n"
            f"📊 **Metric**: `{metric}`\n"
            f"📈 **Usage**: `{usage}/{limit}` ({percentage:.1f}%)\n"
            f"🚨 **Severity**: `{severity_text}`\n"
            f"⏰ **Time**: `{datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}`\n\n"
            f"Consider optimizing resource usage or requesting quota increases."
        )
        
        await self._send_notification(message)
    
    async def _send_resource_alert(self, cluster: Dict[str, Any], resource_type: str, usage_percent: float, alert_type: str):
        """Send resource usage alert"""
        if not self.enable_alerting:
            return
        
        cluster_name = cluster.get('name', 'Unknown')
        cluster_location = cluster.get('location', 'Unknown')
        
        message = (
            f"⚠️ **High Resource Usage Alert**\n\n"
            f"📊 **Cluster**: `{cluster_name}`\n"
            f"🗺️ **Location**: `{cluster_location}`\n"
            f"💻 **Resource**: `{resource_type}`\n"
            f"📈 **Usage**: `{usage_percent:.1f}%`\n"
            f"⏰ **Time**: `{datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}`\n\n"
            f"Consider scaling up or optimizing workloads."
        )
        
        await self._send_notification(message)
    
    async def _send_billing_alert(self, alert_type: str, billing_info: Dict[str, Any]):
        """Send billing alert"""
        if not self.enable_alerting:
            return
        
        if alert_type == "billing_disabled":
            message = (
                f"⚠️ **Billing Alert**\n\n"
                f"💳 **Issue**: Billing is disabled\n"
                f"📋 **Project ID**: `{billing_info.get('project_id', 'Unknown')}`\n"
                f"⏰ **Time**: `{datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}`\n\n"
                f"⚠️ **Action Required**: Enable billing to avoid service interruptions."
            )
        
        await self._send_notification(message)
    
    async def _send_notification(self, message: str):
        """Send notification to all configured chat IDs"""
        try:
            # Send to main chat ID
            await self.bot.send_message(
                chat_id=self.chat_id,
                text=message,
                parse_mode='Markdown'
            )
            
            # Send to additional chat IDs
            for chat_id in self.additional_chat_ids:
                if chat_id.strip():
                    try:
                        await self.bot.send_message(
                            chat_id=chat_id.strip(),
                            text=message,
                            parse_mode='Markdown'
                        )
                    except Exception as e:
                        logger.error(f"Failed to send to additional chat {chat_id}: {e}")
            
            logger.info("Notification sent successfully")
            
        except Exception as e:
            logger.error(f"Failed to send notification: {e}")
    
    def _get_status_emoji(self, status: str) -> str:
        """Get appropriate emoji for status"""
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

async def main():
    """Main function to run the infrastructure monitor"""
    try:
        monitor = InfrastructureMonitor()
        await monitor.start_monitoring()
    except Exception as e:
        logger.error(f"Failed to start infrastructure monitor: {e}")
        raise

if __name__ == "__main__":
    asyncio.run(main())
