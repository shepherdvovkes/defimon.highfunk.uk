#!/usr/bin/env python3
"""
Google Cloud Client for Cluster and Billing Information
"""

import os
import logging
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
from google.cloud import container_v1, billing_v1, resourcemanager_v3
from google.auth import default
from google.auth.exceptions import DefaultCredentialsError

logger = logging.getLogger(__name__)

class GCloudClient:
    def __init__(self):
        """Initialize Google Cloud client with authentication"""
        self.project_id = os.getenv('GOOGLE_CLOUD_PROJECT_ID')
        if not self.project_id:
            raise ValueError("GOOGLE_CLOUD_PROJECT_ID environment variable is required")
        
        try:
            # Initialize credentials
            self.credentials, _ = default()
            
            # Initialize clients
            self.container_client = container_v1.ClusterManagerClient(credentials=self.credentials)
            self.billing_client = billing_v1.CloudBillingClient(credentials=self.credentials)
            self.resource_client = resourcemanager_v3.ProjectsClient(credentials=self.credentials)
            
            logger.info(f"Successfully initialized GCloud client for project: {self.project_id}")
            
        except DefaultCredentialsError as e:
            logger.error(f"Failed to authenticate with Google Cloud: {e}")
            raise
        except Exception as e:
            logger.error(f"Failed to initialize GCloud client: {e}")
            raise
    
    def get_clusters(self) -> List[Dict[str, Any]]:
        """Get all GKE clusters in the project"""
        try:
            parent = f"projects/{self.project_id}/locations/-"
            request = container_v1.ListClustersRequest(parent=parent)
            
            clusters = []
            for cluster in self.container_client.list_clusters(request=request):
                cluster_info = {
                    'name': cluster.name,
                    'location': cluster.location,
                    'status': cluster.status.name,
                    'version': cluster.current_master_version,
                    'node_count': cluster.current_node_count,
                    'machine_type': cluster.default_max_pods_per_node,
                    'network': cluster.network,
                    'subnetwork': cluster.subnetwork,
                    'created_at': cluster.create_time.isoformat() if cluster.create_time else None,
                    'endpoint': cluster.endpoint,
                    'master_auth': {
                        'username': cluster.master_auth.username if cluster.master_auth else None,
                        'client_certificate_config': cluster.master_auth.client_certificate_config.enabled if cluster.master_auth and cluster.master_auth.client_certificate_config else False
                    }
                }
                clusters.append(cluster_info)
            
            logger.info(f"Retrieved {len(clusters)} clusters")
            return clusters
            
        except Exception as e:
            logger.error(f"Failed to get clusters: {e}")
            return []
    
    def get_cluster_nodes(self, cluster_name: str, location: str) -> List[Dict[str, Any]]:
        """Get node information for a specific cluster"""
        try:
            parent = f"projects/{self.project_id}/locations/{location}/clusters/{cluster_name}"
            request = container_v1.ListNodePoolsRequest(parent=parent)
            
            nodes = []
            for node_pool in self.container_client.list_node_pools(request=request):
                node_info = {
                    'name': node_pool.name,
                    'version': node_pool.version,
                    'status': node_pool.status.name,
                    'node_count': node_pool.initial_node_count,
                    'machine_type': node_pool.config.machine_type if node_pool.config else None,
                    'disk_size_gb': node_pool.config.disk_size_gb if node_pool.config else None,
                    'image_type': node_pool.config.image_type if node_pool.config else None,
                    'autoscaling': {
                        'enabled': node_pool.autoscaling.enabled if node_pool.autoscaling else False,
                        'min_node_count': node_pool.autoscaling.min_node_count if node_pool.autoscaling else None,
                        'max_node_count': node_pool.autoscaling.max_node_count if node_pool.autoscaling else None
                    }
                }
                nodes.append(node_info)
            
            logger.info(f"Retrieved {len(nodes)} node pools for cluster {cluster_name}")
            return nodes
            
        except Exception as e:
            logger.error(f"Failed to get nodes for cluster {cluster_name}: {e}")
            return []
    
    def get_billing_info(self) -> Dict[str, Any]:
        """Get current billing information"""
        try:
            # Get project billing info
            project_name = f"projects/{self.project_id}"
            billing_info = self.billing_client.get_project_billing_info(name=project_name)
            
            billing_data = {
                'billing_enabled': billing_info.billing_enabled,
                'billing_account': billing_info.billing_account_name,
                'project_id': self.project_id
            }
            
            # Try to get current month costs (this requires additional setup)
            try:
                # Note: This would require BigQuery billing export to be enabled
                billing_data['current_month_cost'] = "Requires BigQuery billing export"
            except Exception:
                billing_data['current_month_cost'] = "Not available"
            
            logger.info("Retrieved billing information")
            return billing_data
            
        except Exception as e:
            logger.error(f"Failed to get billing info: {e}")
            return {'error': str(e)}
    
    def get_project_info(self) -> Dict[str, Any]:
        """Get project information"""
        try:
            project_name = f"projects/{self.project_id}"
            project = self.resource_client.get_project(name=project_name)
            
            project_info = {
                'project_id': project.project_id,
                'name': project.display_name,
                'state': project.state.name,
                'created_at': project.create_time.isoformat() if project.create_time else None,
                'labels': dict(project.labels) if project.labels else {}
            }
            
            logger.info("Retrieved project information")
            return project_info
            
        except Exception as e:
            logger.error(f"Failed to get project info: {e}")
            return {'error': str(e)}
    
    def get_cluster_status(self, cluster_name: str, location: str) -> Dict[str, Any]:
        """Get detailed status of a specific cluster"""
        try:
            parent = f"projects/{self.project_id}/locations/{location}/clusters/{cluster_name}"
            request = container_v1.GetClusterRequest(name=parent)
            
            cluster = self.container_client.get_cluster(request=request)
            
            status_info = {
                'name': cluster.name,
                'location': cluster.location,
                'status': cluster.status.name,
                'version': cluster.current_master_version,
                'node_count': cluster.current_node_count,
                'endpoint': cluster.endpoint,
                'master_auth': {
                    'username': cluster.master_auth.username if cluster.master_auth else None,
                    'client_certificate_config': cluster.master_auth.client_certificate_config.enabled if cluster.master_auth and cluster.master_auth.client_certificate_config else False
                },
                'network_config': {
                    'network': cluster.network,
                    'subnetwork': cluster.subnetwork,
                    'enable_kubernetes_alpha': cluster.enable_kubernetes_alpha,
                    'enable_legacy_abac': cluster.enable_legacy_abac
                },
                'addons_config': {
                    'http_load_balancing': cluster.addons_config.http_load_balancing.disabled if cluster.addons_config and cluster.addons_config.http_load_balancing else True,
                    'horizontal_pod_autoscaling': cluster.addons_config.horizontal_pod_autoscaling.disabled if cluster.addons_config and cluster.addons_config.horizontal_pod_autoscaling else True,
                    'kubernetes_dashboard': cluster.addons_config.kubernetes_dashboard.disabled if cluster.addons_config and cluster.addons_config.kubernetes_dashboard else True
                }
            }
            
            logger.info(f"Retrieved status for cluster {cluster_name}")
            return status_info
            
        except Exception as e:
            logger.error(f"Failed to get status for cluster {cluster_name}: {e}")
            return {'error': str(e)}
    
    def get_resource_usage(self) -> Dict[str, Any]:
        """Get resource usage information (placeholder for future implementation)"""
        # This would require additional APIs like Cloud Monitoring
        return {
            'cpu_usage': 'Requires Cloud Monitoring API',
            'memory_usage': 'Requires Cloud Monitoring API',
            'disk_usage': 'Requires Cloud Monitoring API',
            'network_usage': 'Requires Cloud Monitoring API'
        }
    
    def test_connection(self) -> bool:
        """Test if the GCloud client can connect and authenticate"""
        try:
            # Try to get project info as a connection test
            self.get_project_info()
            return True
        except Exception as e:
            logger.error(f"Connection test failed: {e}")
            return False
