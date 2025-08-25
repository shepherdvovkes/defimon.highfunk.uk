# Google Cloud Configuration
project_id = "defimon-ethereum-node"
region     = "europe-west1"
zone       = "europe-west1-b"

# Storage Configuration
storage_bucket_name       = "defimon-ethereum-data-bucket-europe"
storage_backup_bucket_name = "defimon-ethereum-backups-europe"

# Database Configuration
database_name     = "defi_analytics"
database_user     = "defimon_user"
database_password = "defimon_secure_password_2024"

# GKE Configuration
machine_type    = "e2-standard-2"
node_count      = 1
max_node_count  = 3
disk_size_gb    = 100

# Environment
environment = "production"
