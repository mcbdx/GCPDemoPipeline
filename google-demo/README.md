# CDC Demo Kit: Cloud SQL (Postgres) → Datastream → BigQuery → Looker Studio

The demo is one number going up. Everything here exists to make that number go up on cue.

Pipeline: `demo_app` inserts a loan into Cloud SQL for PostgreSQL (the modernized core). Datastream watches the WAL via logical replication and upserts the change into BigQuery (`lender_analytics.loans`) with `data_freshness = 0s`. A Looker Studio scorecard reads that table. Refresh, the number ticks 47 → 48.

Framing during the presentation: this Postgres is the **future-state core** after the app modernization pillar. The spoken line for current state: "today Datastream points at your existing SQL Server the same way; source support is GA, so the pilot starts against the real core without migrating anything."

