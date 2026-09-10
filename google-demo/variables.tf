variable "project_id" {
  description = "GCP project for the demo (use a throwaway project)."
  type        = string
}

variable "region" {
  description = "Region for Cloud SQL and Datastream. Keep them identical."
  type        = string
  default     = "us-central1"
}

variable "bq_location" {
  description = "BigQuery dataset location. US multi-region pairs fine with us-central1."
  type        = string
  default     = "US"
}

variable "db_password" {
  description = "Password for the demo_app user."
  type        = string
  sensitive   = true
}

variable "datastream_db_password" {
  description = "Password for the datastream replication user."
  type        = string
  sensitive   = true
}

