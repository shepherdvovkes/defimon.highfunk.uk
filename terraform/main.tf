terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
  
  backend "gcs" {
    bucket = "defimon-terraform-state-europe"
    prefix = "infrastructure"
  }
}

# Configure the Google Provider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "sqladmin.googleapis.com",
    "storage-component.googleapis.com",
    "pubsub.googleapis.com",
    "redis.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudkms.googleapis.com",
    "artifactregistry.googleapis.com",
    "servicenetworking.googleapis.com"
  ])
  
  service = each.value
  disable_dependent_services = false
  disable_on_destroy = false
}

# Create service account for infrastructure
resource "google_service_account" "defimon_infrastructure" {
  account_id   = "defimon-infrastructure"
  display_name = "DEFIMON Infrastructure Service Account"
  description  = "Service account for DEFIMON infrastructure management"
  
  depends_on = [google_project_service.required_apis]
}

# Grant necessary roles to service account
resource "google_project_iam_member" "defimon_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.defimon_infrastructure.email}"
}

resource "google_project_iam_member" "defimon_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.defimon_infrastructure.email}"
}

resource "google_project_iam_member" "defimon_container_admin" {
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.defimon_infrastructure.email}"
}

# Create Cloud Storage buckets
resource "google_storage_bucket" "defimon_data" {
  name          = var.storage_bucket_name
  location      = var.region
  force_destroy = false
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "defimon_backups" {
  name          = var.storage_backup_bucket_name
  location      = var.region
  force_destroy = false
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 730
    }
    action {
      type = "Delete"
    }
  }
}

# Create VPC network
resource "google_compute_network" "defimon_vpc" {
  name                    = "defimon-vpc"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"
  mtu                    = 1460
}

# Create subnet
resource "google_compute_subnetwork" "defimon_subnet" {
  name          = "defimon-subnet"
  ip_cidr_range = "10.1.0.0/24"
  region        = var.region
  network       = google_compute_network.defimon_vpc.id
  
  # Enable flow logs for monitoring
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling       = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }
}

# Create GKE cluster
resource "google_container_cluster" "ethereum_nodes" {
  name     = "ethereum-nodes-cluster"
  location = var.region
  
  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # Network configuration
  network    = google_compute_network.defimon_vpc.id
  subnetwork = google_compute_subnetwork.defimon_subnet.id
  
  # Enable network policy
  network_policy {
    enabled = true
    provider = "CALICO"
  }
  
  # Enable IP aliasing
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/16"
    services_ipv4_cidr_block = "/22"
  }
  
  # Master authorized networks
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All"
    }
  }
  
  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }
  
  # Workload identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # Release channel
  release_channel {
    channel = "REGULAR"
  }
  
  # Maintenance policy - commented out to avoid validation issues
  # maintenance_policy {
  #   recurring_window {
  #     start_time = "2025-08-19T02:00:00Z"
  #     end_time   = "2025-08-19T06:00:00Z"
  #     recurrence = "FREQ=WEEKLY;BYDAY=SU"
  #   }
  # }
  
  depends_on = [google_project_service.required_apis]
}

  # Create node pool for Ethereum nodes
  resource "google_container_node_pool" "ethereum_nodes_pool" {
    name       = "ethereum-nodes-pool"
    location   = var.region
    cluster    = google_container_cluster.ethereum_nodes.name
    
    # Autoscaling configuration
    autoscaling {
      min_node_count = 1
      max_node_count = 3
    }
    
    # Node configuration
    node_config {
      machine_type = "e2-standard-2"
      disk_size_gb = 50
      disk_type    = "pd-standard"
    
    # OAuth scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/compute"
    ]
    
    # Labels
    labels = {
      app = "ethereum-node"
      env = "production"
    }
    
    # Taints for dedicated nodes
    taint {
      key    = "dedicated"
      value  = "ethereum"
      effect = "NO_SCHEDULE"
    }
    
    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
  
  # Management configuration
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  
  # Update strategy
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

# Create Cloud SQL instance
resource "google_sql_database_instance" "defimon_postgres" {
  name             = "defimon-postgres-instance"
  database_version = "POSTGRES_14"
  region           = var.region
  
        settings {
        tier = "db-f1-micro"
        
        backup_configuration {
          enabled    = true
          start_time = "02:00"
        }
        
        ip_configuration {
          ipv4_enabled    = false
          private_network = google_compute_network.defimon_vpc.id
        }
      }
  
  deletion_protection = false
  
  depends_on = [google_project_service.required_apis]
}

# Create database
resource "google_sql_database" "defimon_db" {
  name     = var.database_name
  instance = google_sql_database_instance.defimon_postgres.name
}

# Create database user
resource "google_sql_user" "defimon_user" {
  name     = var.database_user
  instance = google_sql_database_instance.defimon_postgres.name
  password = var.database_password
}

# Create Memorystore Redis instance
resource "google_redis_instance" "defimon_redis" {
  name           = "defimon-redis-instance"
  tier           = "BASIC"
  memory_size_gb = 1
  region         = var.region
  
  authorized_network = google_compute_network.defimon_vpc.id
  
  depends_on = [google_project_service.required_apis]
}

# Create Pub/Sub topic
resource "google_pubsub_topic" "defimon_events" {
  name = "defimon-ethereum-events"
  
  depends_on = [google_project_service.required_apis]
}

# Create Pub/Sub subscription
resource "google_pubsub_subscription" "defimon_events_sub" {
  name  = "defimon-ethereum-events-sub"
  topic = google_pubsub_topic.defimon_events.name
  
  ack_deadline_seconds = 20
  
  expiration_policy {
    ttl = "2678400s" # 31 days
  }
}

# Create static IP for load balancer
resource "google_compute_address" "defimon_lb_ip" {
  name         = "defimon-lb-ip"
  address_type = "EXTERNAL"
  region       = var.region
}

# Create firewall rules
resource "google_compute_firewall" "defimon_allow_internal" {
  name    = "defimon-allow-internal"
  network = google_compute_network.defimon_vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  
  source_ranges = ["10.1.0.0/24"]
}

resource "google_compute_firewall" "defimon_allow_external" {
  name    = "defimon-allow-external"
  network = google_compute_network.defimon_vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8545", "8546", "9090", "3000", "3001"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["defimon-external"]
}

# Outputs
output "gke_cluster_name" {
  value = google_container_cluster.ethereum_nodes.name
}

output "gke_cluster_endpoint" {
  value = google_container_cluster.ethereum_nodes.endpoint
}

output "postgres_connection_name" {
  value = google_sql_database_instance.defimon_postgres.connection_name
}

output "redis_host" {
  value = google_redis_instance.defimon_redis.host
}

output "load_balancer_ip" {
  value = google_compute_address.defimon_lb_ip.address
}
