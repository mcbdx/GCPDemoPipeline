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
6. Seed 47 loans:
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

## Demo script (3 min, section 6)

0. Before the meeting: Looker tab open on the dashboard, terminal open with `DB_HOST` and `DB_PASS` already exported, `verify_bq.sh` already green, dashboard freshly refreshed showing 47.
1. (0:00) "This is the dashboard your operations team would open every morning. 47 loans originated." Point at the scorecard.
2. (0:20) Switch to terminal. "Now a field officer in Ciudad Juárez captures a loan. That's this." Run `./scripts/insert_loan.sh`. The folio prints.
3. (0:35) **Do not stare at the screen waiting.** Talk over propagation: "No export, no report, nobody emailed a spreadsheet. Datastream is reading the database's own change log and applying it to BigQuery as we speak. That's the same CDC pattern I run in production at Shopify at 19 million events a second, and it never touched the core's performance."
4. (1:30–2:00) Switch to Looker, hit refresh. 48. Point at the new folio in the table. "From the street to headquarters, in the time it took me to explain it."
5. (2:00+) One beat of silence, then bridge to section 7: "So why does this hold up beyond a demo?"

## Rehearsal protocol (non-negotiable)

- 3 full runs inside a Google Meet screen share (solo meeting with yourself), camera on, out loud.
- Time the insert→visible gap on each run. If it's consistently under 60s, fire the insert at step 2 as scripted. If it's flaky or >90s, switch to Plan B permanently: fire the insert at the START of section 5 (credit journey), so it has 2+ minutes to land before you reach the dashboard.
- `reset_demo.sh` + `verify_bq.sh` before every run.
- Record the best run in full (screen + narration). This is the backup.

## Failure plans

- **Insert lands slow live:** keep narrating section 7 material; circle back to the tab one more time before Q&A. The tick-up during Q&A is still a win.
- **Anything is broken the morning of:** play the recording, narrating live over it, no apology beyond one clause: "I'll show you yesterday's run of the same pipeline." A CE who ships a recording calmly beats one who debugs live.
- **Meet/screen share issues:** deck has a screenshot of before/after dashboard states as slides 6a/6b, worst-case narration path.

## Costs and teardown

Cloud SQL db-g1-small + Datastream at demo volume + BigQuery at KB scale: a few USD/day. Keep it alive only for rehearsal days + interview day. Afterward: `terraform destroy` (deletion protection is off by design).

## Hygiene

- All names and CURPs are synthetic (`XXXX...DEMO` pattern, not valid CURP structure).
- No lender name anywhere: project, instance, dataset, dashboard title all say "MFI demo" or neutral labels.
- Close every tab except deck, terminal, Looker, BigQuery console before sharing. Notifications off. Bookmarks bar hidden.
