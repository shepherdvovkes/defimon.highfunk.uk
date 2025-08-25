variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
  default     = "defimon-ethereum-node"
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Google Cloud zone"
  type        = string
  default     = "us-central1-a"
}

variable "storage_bucket_name" {
  description = "Name for the main data storage bucket"
  type        = string
  default     = "defimon-ethereum-data-bucket"
}

variable "storage_backup_bucket_name" {
  description = "Name for the backup storage bucket"
  type        = string
  default     = "defimon-ethereum-backups"
}

variable "database_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "defi_analytics"
}

variable "database_user" {
  description = "PostgreSQL database user"
  type        = string
  default     = "defimon_user"
}

variable "database_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
  default     = "defimon_secure_password_2024"
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "node_count" {
  description = "Number of GKE nodes"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of GKE nodes for autoscaling"
  type        = number
  default     = 3
}

variable "disk_size_gb" {
  description = "Disk size in GB for GKE nodes"
  type        = number
  default     = 100
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}
