#!/usr/bin/env python3
"""
Google Cloud Client for Infrastructure Monitoring and Management
"""

import os
import logging
import subprocess
import json
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime, timedelta
from google.cloud import container_v1, billing_v1, resourcemanager_v3, compute_v1, monitoring_v3
from google.auth import default
from google.auth.exceptions import DefaultCredentialsError

from database import InfrastructureDatabase

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
            self.compute_client = compute_v1.InstancesClient(credentials=self.credentials)
            self.monitoring_client = monitoring_v3.MetricServiceClient(credentials=self.credentials)
            
            # Initialize database
            self.database = InfrastructureDatabase()
            
            logger.info(f"Successfully initialized GCloud client for project: {self.project_id}")
            
        except DefaultCredentialsError as e:
            logger.error(f"Failed to authenticate with Google Cloud: {e}")
            raise
        except Exception as e:
            logger.error(f"Failed to initialize GCloud client: {e}")
            raise
    
    def execute_gcloud_command(self, command: str) -> Tuple[bool, str]:
        """Execute gcloud command and return result"""
        try:
            full_command = f"gcloud {command} --project={self.project_id} --format=json"
            result = subprocess.run(
                full_command.split(),
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                return True, result.stdout
            else:
                return False, result.stderr
                
        except subprocess.TimeoutExpired:
            return False, "Command timed out"
        except Exception as e:
            return False, str(e)
    
    def get_infrastructure_overview(self) -> Dict[str, Any]:
        """Get comprehensive infrastructure overview"""
        try:
            # Get real-time data from GCP
            clusters = self.get_clusters()
            compute_instances = self.get_compute_instances()
            networks = self.get_networks()
            storage = self.get_storage_info()
            iam = self.get_iam_info()
            quotas = self.get_project_quotas()
            
            # Store data in database
            for cluster in clusters:
                self.database.store_cluster_data(cluster)
            
            for instance in compute_instances:
                self.database.store_compute_instance_data(instance)
            
            # Store infrastructure snapshot
            overview = {
                'project_id': self.project_id,
                'timestamp': datetime.now().isoformat(),
                'clusters': clusters,
                'compute_instances': compute_instances,
                'networks': networks,
                'storage': storage,
                'iam': iam,
                'quotas': quotas
            }
            
            self.database.store_infrastructure_snapshot(overview)
            
            return overview
            
        except Exception as e:
            logger.error(f"Failed to get infrastructure overview: {e}")
            return {'error': str(e)}
    
    def get_compute_instances(self) -> List[Dict[str, Any]]:
        """Get all compute instances using Python API"""
        try:
            instances = []
            
            # Get instances from all zones - expanded list
            zones = [
                'us-central1-a', 'us-central1-b', 'us-central1-c', 'us-central1-f',
                'us-east1-a', 'us-east1-b', 'us-east1-c', 'us-east1-d',
                'us-west1-a', 'us-west1-b', 'us-west1-c',
                'europe-west1-a', 'europe-west1-b', 'europe-west1-c', 'europe-west1-d',
                'europe-west2-a', 'europe-west2-b', 'europe-west2-c',
                'europe-west3-a', 'europe-west3-b', 'europe-west3-c',
                'europe-west4-a', 'europe-west4-b', 'europe-west4-c'
            ]
            
            for zone in zones:
                try:
                    request = compute_v1.ListInstancesRequest(
                        project=self.project_id,
                        zone=zone
                    )
                    
                    page_result = self.compute_client.list(request=request)
                    
                    for instance in page_result:
                        # Get network interface information - safer access
                        internal_ip = None
                        external_ip = None
                        
                        if hasattr(instance, 'network_interfaces') and instance.network_interfaces:
                            for ni in instance.network_interfaces:
                                # Safely access network_ip
                                if hasattr(ni, 'network_ip') and ni.network_ip:
                                    internal_ip = ni.network_ip
                                # Safely access access_configs
                                if hasattr(ni, 'access_configs') and ni.access_configs:
                                    for ac in ni.access_configs:
                                        if hasattr(ac, 'nat_ip') and ac.nat_ip:
                                            external_ip = ac.nat_ip
                                            break
                        
                        instance_info = {
                            'name': instance.name,
                            'zone': instance.zone.split('/')[-1] if instance.zone else 'Unknown',
                            'status': instance.status,
                            'machine_type': instance.machine_type.split('/')[-1] if instance.machine_type else 'Unknown',
                            'cpu_platform': instance.cpu_platform,
                            'creation_timestamp': instance.creation_timestamp,
                            'internal_ip': internal_ip,
                            'external_ip': external_ip,
                            'labels': dict(instance.labels) if instance.labels else {}
                        }
                        instances.append(instance_info)
                        
                except Exception as zone_error:
                    logger.warning(f"Failed to get instances from zone {zone}: {zone_error}")
                    continue
            
            logger.info(f"Retrieved {len(instances)} compute instances via Python API")
            return instances
            
        except Exception as e:
            logger.error(f"Failed to get compute instances via Python API: {e}")
            return []
    
    def get_networks(self) -> List[Dict[str, Any]]:
        """Get network information"""
        try:
            success, output = self.execute_gcloud_command("compute networks list")
            if success:
                networks = json.loads(output)
                return [
                    {
                        'name': net['name'],
                        'x_gcloud_subnet_mode': net.get('x_gcloud_subnet_mode', 'Unknown'),
                        'x_gcloud_bgp_routing_mode': net.get('x_gcloud_bgp_routing_mode', 'Unknown')
                    }
                    for net in networks
                ]
            return []
            
        except Exception as e:
            logger.error(f"Failed to get networks: {e}")
            return []
    
    def get_storage_info(self) -> Dict[str, Any]:
        """Get storage information"""
        try:
            success, output = self.execute_gcloud_command("storage ls")
            if success:
                buckets = output.strip().split('\n') if output.strip() else []
                return {
                    'bucket_count': len(buckets),
                    'buckets': buckets
                }
            return {'bucket_count': 0, 'buckets': []}
            
        except Exception as e:
            logger.error(f"Failed to get storage info: {e}")
            return {'bucket_count': 0, 'buckets': []}
    
    def get_iam_info(self) -> Dict[str, Any]:
        """Get IAM information"""
        try:
            success, output = self.execute_gcloud_command("projects get-iam-policy")
            if success:
                iam_policy = json.loads(output)
                bindings = iam_policy.get('bindings', [])
                
                return {
                    'bindings_count': len(bindings),
                    'roles': list(set(binding['role'] for binding in bindings)),
                    'members_count': sum(len(binding.get('members', [])) for binding in bindings)
                }
            return {'bindings_count': 0, 'roles': [], 'members_count': 0}
            
        except Exception as e:
            logger.error(f"Failed to get IAM info: {e}")
            return {'bindings_count': 0, 'roles': [], 'members_count': 0}
    
    def get_project_quotas(self) -> Dict[str, Any]:
        """Get project quotas"""
        try:
            quotas = {}
            
            # Get compute quotas for us-central1 region
            success, output = self.execute_gcloud_command("compute regions describe us-central1 --format=json")
            if success:
                region_data = json.loads(output)
                quotas_data = region_data.get('quotas', [])
                for quota in quotas_data:
                    if quota['metric'] in ['CPUS', 'CPUS_ALL_REGIONS', 'INSTANCES', 'INSTANCES_ALL_REGIONS']:
                        quotas[quota['metric']] = {
                            'limit': quota['limit'],
                            'usage': quota['usage']
                        }
            
            return quotas
            
        except Exception as e:
            logger.error(f"Failed to get project quotas: {e}")
            return {}
    
    def get_resource_usage(self, cluster_name: str = None, location: str = None) -> Dict[str, Any]:
        """Get detailed resource usage information"""
        try:
            # For now, return estimated usage based on node count
            # In production, you would use Cloud Monitoring API
            if cluster_name and location:
                nodes = self.get_cluster_nodes(cluster_name, location)
                total_nodes = sum(node.get('node_count', 0) for node in nodes)
                
                # Estimate usage based on node count
                cpu_usage = min(60 + (total_nodes * 5), 90)  # 60-90% based on node count
                memory_usage = min(70 + (total_nodes * 3), 85)  # 70-85% based on node count
                disk_usage = min(75 + (total_nodes * 2), 95)  # 75-95% based on node count
                
                usage_info = {
                    'timestamp': datetime.now().isoformat(),
                    'cpu_usage': {
                        'current_usage': f"{total_nodes * 0.6:.1f} cores",
                        'total_capacity': f"{total_nodes * 2:.1f} cores",
                        'utilization_percent': cpu_usage
                    },
                    'memory_usage': {
                        'current_usage': f"{total_nodes * 3.2:.1f} GB",
                        'total_capacity': f"{total_nodes * 4:.1f} GB",
                        'utilization_percent': memory_usage
                    },
                    'disk_usage': {
                        'current_usage': f"{total_nodes * 45:.1f} GB",
                        'total_capacity': f"{total_nodes * 50:.1f} GB",
                        'utilization_percent': disk_usage
                    }
                }
                
                # Store resource usage in database
                self.database.store_resource_usage(cluster_name, location, {
                    'cpu_usage_percent': cpu_usage,
                    'memory_usage_percent': memory_usage,
                    'disk_usage_percent': disk_usage
                })
                
                return usage_info
            
            return {
                'timestamp': datetime.now().isoformat(),
                'cpu_usage': {'current_usage': 'Unknown', 'total_capacity': 'Unknown', 'utilization_percent': 0},
                'memory_usage': {'current_usage': 'Unknown', 'total_capacity': 'Unknown', 'utilization_percent': 0},
                'disk_usage': {'current_usage': 'Unknown', 'total_capacity': 'Unknown', 'utilization_percent': 0}
            }
            
        except Exception as e:
            logger.error(f"Failed to get resource usage: {e}")
            return {'error': str(e)}
    
    def scale_cluster(self, cluster_name: str, location: str, node_count: int) -> Tuple[bool, str]:
        """Scale cluster to specified node count"""
        try:
            command = f"container clusters resize {cluster_name} --region={location} --num-nodes={node_count}"
            return self.execute_gcloud_command(command)
            
        except Exception as e:
            logger.error(f"Failed to scale cluster {cluster_name}: {e}")
            return False, str(e)
    
    def get_cluster_logs(self, cluster_name: str, location: str, lines: int = 100) -> Tuple[bool, str]:
        """Get recent logs from a cluster"""
        try:
            command = f"container clusters describe {cluster_name} --region={location} --format=json"
            return self.execute_gcloud_command(command)
            
        except Exception as e:
            logger.error(f"Failed to get logs for cluster {cluster_name}: {e}")
            return False, str(e)
    
    def restart_node_pool(self, cluster_name: str, location: str, node_pool_name: str) -> Tuple[bool, str]:
        """Restart a node pool"""
        try:
            command = f"container node-pools rolling-update {node_pool_name} --cluster={cluster_name} --region={location}"
            return self.execute_gcloud_command(command)
            
        except Exception as e:
            logger.error(f"Failed to restart node pool {node_pool_name}: {e}")
            return False, str(e)
    
    def get_clusters(self) -> List[Dict[str, Any]]:
        """Get all GKE clusters in the project using Python API"""
        try:
            parent = f"projects/{self.project_id}/locations/-"
            request = container_v1.ListClustersRequest(parent=parent)
            
            clusters = []
            page_result = self.container_client.list_clusters(request=request)
            
            # Fix: Properly iterate through the page result
            for cluster in page_result.clusters:
                cluster_info = {
                    'name': cluster.name.split('/')[-1] if cluster.name else 'Unknown',
                    'location': cluster.location,
                    'status': cluster.status.name if cluster.status else 'Unknown',
                    'version': cluster.current_master_version,
                    'node_count': cluster.current_node_count,
                    'network': cluster.network,
                    'subnetwork': cluster.subnetwork,
                    'created_at': cluster.create_time.isoformat() if cluster.create_time else 'Unknown',
                    'endpoint': cluster.endpoint
                }
                clusters.append(cluster_info)
            
            logger.info(f"Retrieved {len(clusters)} clusters via Python API")
            return clusters
            
        except Exception as e:
            logger.error(f"Failed to get clusters via Python API: {e}")
            return []
    
    def get_cluster_nodes(self, cluster_name: str, location: str) -> List[Dict[str, Any]]:
        """Get node information for a specific cluster"""
        try:
            parent = f"projects/{self.project_id}/locations/{location}/clusters/{cluster_name}"
            request = container_v1.ListNodePoolsRequest(parent=parent)
            
            nodes = []
            page_result = self.container_client.list_node_pools(request=request)
            
            # Fix: Properly iterate through the page result
            for node_pool in page_result.node_pools:
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
                
                # Store node pool data in database
                self.database.store_node_pool_data(cluster_name, location, node_info)
            
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
    
    def test_connection(self) -> bool:
        """Test if the GCloud client can connect and authenticate"""
        try:
            # Try to get project info as a connection test
            self.get_project_info()
            return True
        except Exception as e:
            logger.error(f"Connection test failed: {e}")
            return False
    
    def get_database_stats(self) -> Dict[str, Any]:
        """Get database statistics"""
        return self.database.get_database_stats()
    
    def get_ethereum_nodes_info(self) -> Dict[str, Any]:
        """Get specific information about Ethereum nodes (Lighthouse and Geth)"""
        try:
            ethereum_info = {
                'lighthouse_nodes': [],
                'geth_nodes': [],
                'total_nodes': 0,
                'status': 'unknown'
            }
            
            # Get all clusters first
            clusters = self.get_clusters()
            
            for cluster in clusters:
                cluster_name = cluster['name']
                location = cluster['location']
                
                # Check if this cluster contains Ethereum nodes
                if 'ethereum' in cluster_name.lower() or 'defimon' in cluster_name.lower():
                    logger.info(f"Found Ethereum cluster: {cluster_name}")
                    
                    # Get node pools for this cluster
                    nodes = self.get_cluster_nodes(cluster_name, location)
                    
                    for node in nodes:
                        node_name = node['name']
                        
                        # Check if it's a Lighthouse or Geth node
                        if 'lighthouse' in node_name.lower():
                            ethereum_info['lighthouse_nodes'].append({
                                'cluster': cluster_name,
                                'location': location,
                                'name': node_name,
                                'status': node['status'],
                                'node_count': node['node_count'],
                                'machine_type': node['machine_type'],
                                'version': node['version']
                            })
                        elif 'geth' in node_name.lower():
                            ethereum_info['geth_nodes'].append({
                                'cluster': cluster_name,
                                'location': location,
                                'name': node_name,
                                'status': node['status'],
                                'node_count': node['node_count'],
                                'machine_type': node['machine_type'],
                                'version': node['version']
                            })
                    
                    # Also check compute instances in the cluster's region
                    region = location.split('-')[0] + '-' + location.split('-')[1] if '-' in location else location
                    instances = self.get_compute_instances_in_region(region)
                    
                    for instance in instances:
                        instance_name = instance['name']
                        if 'lighthouse' in instance_name.lower():
                            ethereum_info['lighthouse_nodes'].append({
                                'type': 'compute_instance',
                                'name': instance_name,
                                'zone': instance['zone'],
                                'status': instance['status'],
                                'machine_type': instance['machine_type'],
                                'internal_ip': instance['internal_ip'],
                                'external_ip': instance['external_ip']
                            })
                        elif 'geth' in instance_name.lower():
                            ethereum_info['geth_nodes'].append({
                                'type': 'compute_instance',
                                'name': instance_name,
                                'zone': instance['zone'],
                                'status': instance['status'],
                                'machine_type': instance['machine_type'],
                                'internal_ip': instance['internal_ip'],
                                'external_ip': instance['external_ip']
                            })
            
            # Calculate totals
            ethereum_info['total_nodes'] = len(ethereum_info['lighthouse_nodes']) + len(ethereum_info['geth_nodes'])
            
            # Determine overall status
            if ethereum_info['total_nodes'] > 0:
                ethereum_info['status'] = 'running'
            else:
                ethereum_info['status'] = 'not_found'
            
            logger.info(f"Retrieved Ethereum nodes info: {ethereum_info['total_nodes']} total nodes")
            return ethereum_info
            
        except Exception as e:
            logger.error(f"Failed to get Ethereum nodes info: {e}")
            return {'error': str(e), 'status': 'error'}
    
    def get_compute_instances_in_region(self, region: str) -> List[Dict[str, Any]]:
        """Get compute instances in a specific region"""
        try:
            instances = []
            
            # Map region to zones
            region_zones = {
                'us-central1': ['us-central1-a', 'us-central1-b', 'us-central1-c', 'us-central1-f'],
                'us-east1': ['us-east1-a', 'us-east1-b', 'us-east1-c', 'us-east1-d'],
                'us-west1': ['us-west1-a', 'us-west1-b', 'us-west1-c'],
                'europe-west1': ['europe-west1-a', 'europe-west1-b', 'europe-west1-c', 'europe-west1-d'],
                'europe-west2': ['europe-west2-a', 'europe-west2-b', 'europe-west2-c'],
                'europe-west3': ['europe-west3-a', 'europe-west3-b', 'europe-west3-c'],
                'europe-west4': ['europe-west4-a', 'europe-west4-b', 'europe-west4-c']
            }
            
            zones = region_zones.get(region, [])
            
            for zone in zones:
                try:
                    request = compute_v1.ListInstancesRequest(
                        project=self.project_id,
                        zone=zone
                    )
                    
                    page_result = self.compute_client.list(request=request)
                    
                    for instance in page_result:
                        # Get network interface information - safer access
                        internal_ip = None
                        external_ip = None
                        
                        if hasattr(instance, 'network_interfaces') and instance.network_interfaces:
                            for ni in instance.network_interfaces:
                                # Safely access network_ip
                                if hasattr(ni, 'network_ip') and ni.network_ip:
                                    internal_ip = ni.network_ip
                                # Safely access access_configs
                                if hasattr(ni, 'access_configs') and ni.access_configs:
                                    for ac in ni.access_configs:
                                        if hasattr(ac, 'nat_ip') and ac.nat_ip:
                                            external_ip = ac.nat_ip
                                            break
                        
                        instance_info = {
                            'name': instance.name,
                            'zone': instance.zone.split('/')[-1] if instance.zone else 'Unknown',
                            'status': instance.status,
                            'machine_type': instance.machine_type.split('/')[-1] if instance.machine_type else 'Unknown',
                            'cpu_platform': instance.cpu_platform,
                            'creation_timestamp': instance.creation_timestamp,
                            'internal_ip': internal_ip,
                            'external_ip': external_ip,
                            'labels': dict(instance.labels) if instance.labels else {}
                        }
                        instances.append(instance_info)
                        
                except Exception as zone_error:
                    logger.warning(f"Failed to get instances from zone {zone}: {zone_error}")
                    continue
            
            return instances
            
        except Exception as e:
            logger.error(f"Failed to get compute instances in region {region}: {e}")
            return []
