output "postgres_public_ip" {
  value       = google_sql_database_instance.core.public_ip_address
  description = "Host for psql: setup, seed, and the demo insert."
}

output "bigquery_dataset" {
  value       = google_bigquery_dataset.analytics.dataset_id
  description = "Dataset where Datastream lands the loans table."
}

output "stream_name" {
  value       = google_datastream_stream.loans_cdc.id
  description = "Datastream stream resource name (starts PAUSED)."
}

output "psql_hint" {
  value       = "PGPASSWORD='<db_password>' psql -h ${google_sql_database_instance.core.public_ip_address} -U demo_app -d lender"
  description = "Connection one-liner."
}
