# CDC Demo Kit: Cloud SQL (Postgres) → Datastream → BigQuery → Looker Studio

The demo is one number going up. Everything here exists to make that number go up on cue.

Pipeline: `demo_app` inserts a loan into Cloud SQL for PostgreSQL (the modernized core). Datastream watches the WAL via logical replication and upserts the change into BigQuery (`lender_analytics.loans`) with `data_freshness = 0s`. A Looker Studio scorecard reads that table. Refresh, the number ticks 47 → 48.

Framing during the presentation: this Postgres is the **future-state core** after the app modernization pillar. The spoken line for current state: "today Datastream points at your existing SQL Server the same way; source support is GA, so the pilot starts against the real core without migrating anything."

## Setup order (once, ~45 min including waiting)

1. Create a throwaway project, enable billing.
2. `cp terraform.tfvars.example terraform.tfvars`, fill in:
   - your IP: `curl -s ifconfig.me`
   - Datastream regional IPs from https://cloud.google.com/datastream/docs/ip-allowlists-and-regions
3. `terraform init && terraform apply` (Cloud SQL creation is the slow part, ~10 min).
4. Set the postgres superuser password:
   `gcloud sql users set-password postgres --instance=mfi-core-demo --password='...'`
5. Run in-database setup (table, publication, slot, grants):
   `PGPASSWORD='<postgres pw>' psql -h <IP> -U postgres -d lender -f sql/setup_source.sql`
6. Seed N loans:
   `PGPASSWORD='<db pw>' psql -h <IP> -U demo_app -d lender -f sql/seed.sql`
7. Start the stream: `PROJECT_ID=<p> ./scripts/start_stream.sh`
   Wait for backfill; confirm with `PROJECT_ID=<p> ./scripts/verify_bq.sh` → 47.
8. Build the Looker Studio page (manual, once):
   - Data source: BigQuery → `lender_analytics.loans`
   - **Data freshness: set to 1 minute (minimum)** in the data source settings, and rely on the manual refresh button (⟳ / View → Refresh data) during the demo.
   - Tile 1: Scorecard, `COUNT(loan_id)`, label "Créditos originados"
   - Tile 2: Table, folio / branch / amount_mxn / created_at, sorted by created_at desc
   - Tile 3 (optional): bar chart, loans by branch
9. Full dry run. Then `./scripts/reset_demo.sh`.
