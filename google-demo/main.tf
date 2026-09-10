# ============================================================
# CDC Demo: Cloud SQL (PostgreSQL) -> Datastream -> BigQuery
# One `terraform apply` provisions everything except the
# Looker Studio tile (manual, one time) and the in-database
# setup (sql/setup_source.sql, run once after apply).
# ============================================================

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ------------------------------------------------------------
# APIs
# ------------------------------------------------------------
resource "google_project_service" "apis" {
  for_each = toset([
    "sqladmin.googleapis.com",
    "datastream.googleapis.com",
    "bigquery.googleapis.com",
    "compute.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false
}

# ------------------------------------------------------------
# Cloud SQL: PostgreSQL (the "modernized core")
# ------------------------------------------------------------
resource "google_sql_database_instance" "core" {
  name             = "mfi-core-demo"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = "db-g1-small" # cheap; demo scale

    ip_configuration {
      ipv4_enabled = true

      # Throwaway demo project: open to any IP so Datastream and a
      # moving laptop IP both just work, no allowlist maintenance.
      authorized_networks {
        value = "0.0.0.0/0"
      }
    }

    database_flags {
      name  = "cloudsql.logical_decoding"
      value = "on"
    }
  }

  deletion_protection = false # demo project; terraform destroy must work
  depends_on          = [google_project_service.apis]
}

resource "google_sql_database" "lender" {
  name     = "lender"
  instance = google_sql_database_instance.core.name
}

# App user (used by the demo insert) and Datastream user.
resource "google_sql_user" "app" {
  name     = "demo_app"
  instance = google_sql_database_instance.core.name
  password = var.db_password
}

resource "google_sql_user" "datastream" {
  name     = "datastream"
  instance = google_sql_database_instance.core.name
  password = var.datastream_db_password
}

# ------------------------------------------------------------
# BigQuery destination
# ------------------------------------------------------------
resource "google_bigquery_dataset" "analytics" {
  dataset_id    = "lender_analytics"
  friendly_name = "MFI demo analytics"
  location      = var.bq_location
  depends_on    = [google_project_service.apis]
}

# ------------------------------------------------------------
# Datastream: source profile, destination profile, stream
# ------------------------------------------------------------
resource "google_datastream_connection_profile" "postgres_source" {
  display_name          = "mfi-core-postgres"
  location              = var.region
  connection_profile_id = "mfi-core-postgres"

  postgresql_profile {
    hostname = google_sql_database_instance.core.public_ip_address
    port     = 5432
    database = google_sql_database.lender.name
    username = google_sql_user.datastream.name
    password = var.datastream_db_password
  }

  depends_on = [google_project_service.apis]
}

resource "google_datastream_connection_profile" "bq_destination" {
  display_name          = "mfi-analytics-bq"
  location              = var.region
  connection_profile_id = "mfi-analytics-bq"

  bigquery_profile {}

  depends_on = [google_project_service.apis]
}

resource "google_datastream_stream" "loans_cdc" {
  stream_id    = "loans-cdc"
  location     = var.region
  display_name = "loans-cdc"

  source_config {
    source_connection_profile = google_datastream_connection_profile.postgres_source.id

    postgresql_source_config {
      publication      = "loans_stream"      # created by sql/setup_source.sql
      replication_slot = "loans_stream_slot" # created by sql/setup_source.sql

      include_objects {
        postgresql_schemas {
          schema = "public"
          postgresql_tables {
            table = "loans"
          }
        }
      }
    }
  }

  destination_config {
    destination_connection_profile = google_datastream_connection_profile.bq_destination.id

    bigquery_destination_config {
      # Lowest allowed staleness: BigQuery applies CDC upserts as fast
      # as it can and queries always read fresh. This is the setting
      # that makes the live tick-up viable.
      data_freshness = "0s"

      single_target_dataset {
        dataset_id = "${var.project_id}:${google_bigquery_dataset.analytics.dataset_id}"
      }
    }
  }

  backfill_all {}

  # Create paused; start it AFTER running setup_source.sql
  # (the publication/slot must exist first). Flip to RUNNING
  # with scripts/start_stream.sh or in the console.
  desired_state = "NOT_STARTED"
}
