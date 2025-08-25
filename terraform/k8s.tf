# Kubernetes Provider configuration - temporarily commented out
# provider "kubernetes" {
#   host                   = "https://${google_container_cluster.ethereum_nodes.endpoint}"
#   token                  = data.google_client_config.current.access_token
#   cluster_ca_certificate = base64decode(google_container_cluster.ethereum_nodes.master_auth[0].cluster_ca_certificate)
# }

# Get current Google client configuration
data "google_client_config" "current" {}

# Create namespace - temporarily commented out
# resource "kubernetes_namespace" "defimon" {
#   metadata {
#     name = "defimon"
#     labels = {
#       app       = "defimon"
#       env       = var.environment
#       managed-by = "terraform"
#     }
#   }
#   
#   depends_on = [google_container_cluster.ethereum_nodes]
# }

# Create JWT secret for Ethereum nodes (placeholder - will be populated later) - temporarily commented out
# resource "kubernetes_secret" "ethereum_jwt_secret" {
#   metadata {
#     name      = "ethereum-jwt-secret"
#     namespace = kubernetes_namespace.defimon.metadata[0].name
#   }
#   
#   data = {
#     "jwtsecret.raw" = base64encode("placeholder-jwt-secret-raw-32-bytes-long")
#     "jwtsecret.hex" = base64encode("placeholder-jwt-secret-hex-64-chars-long")
#   }
#   
#   type = "Opaque"
#   
#   depends_on = [kubernetes_namespace.defimon]
# }

# Create ConfigMap for Ethereum node configuration - temporarily commented out
# resource "kubernetes_config_map" "ethereum_config" {
#   metadata {
#     name      = "ethereum-node-config"
#     namespace = kubernetes_namespace.defimon.metadata[0].name
#   }
#   
#   data = {
#     "geth.conf" = jsonencode({
#       network_id = 1
#       sync_mode  = "snap"
#       cache_size = 2048
#       max_peers  = 50
#       rpc_port   = 8545
#       ws_port    = 8546
#       p2p_port   = 30303
#     })
#     
#     "lighthouse.conf" = jsonencode({
#       network = "mainnet"
#       http_port = 5052
#       p2p_port = 9000
#       checkpoint_sync_url = "https://sync-mainnet.beaconcha.in"
#     })
#   }
#   
#   depends_on = [kubernetes_namespace.defimon]
# }

# Create PersistentVolumeClaim for Ethereum data - temporarily commented out
# resource "kubernetes_persistent_volume_claim" "ethereum_data" {
#   metadata {
#     name      = "ethereum-data-pvc"
#     namespace = kubernetes_namespace.defimon.metadata[0].name
#   }
#   
#   spec {
#     access_modes = ["ReadWriteOnce"]
#     resources {
#       requests = {
#         storage = "2Ti"
#       }
#     }
#     storage_class_name = "standard"
#   }
#   
#   depends_on = [kubernetes_namespace.defimon]
# }

# Create PersistentVolumeClaim for Lighthouse data - temporarily commented out
# resource "kubernetes_persistent_volume_claim" "lighthouse_data" {
#   metadata {
#     name      = "lighthouse-data-pvc"
#     namespace = kubernetes_namespace.defimon.metadata[0].name
#   }
#   
#   spec {
#     access_modes = ["ReadWriteOnce"]
#     resources {
#       requests = {
#         storage = "500Gi"
#       }
#     }
#     storage_class_name = "standard"
#   }
#   
#   depends_on = [kubernetes_namespace.defimon]
# }
