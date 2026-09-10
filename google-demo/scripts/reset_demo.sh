#!/usr/bin/env bash
# ============================================================
# Reset the demo to its opening state: the seeded loans only.
# Run before every rehearsal and on the morning of.
#
# Usage:
#   DB_HOST=<IP> DB_PASS=<postgres_password> PROJECT_ID=<project> \
#     REGION=us-central1 ./scripts/reset_demo.sh
#
# Full reset, not just a source reseed: also drops and
# backfills the BigQuery table, so this is idempotent no matter
# what state BigQuery was left in (stale rows, a botched manual
# DML attempt, a previous partial run). Safe to re-run anytime.
# ============================================================
set -euo pipefail

: "${DB_HOST:?Set DB_HOST to the Cloud SQL public IP}"
: "${DB_PASS:?Set DB_PASS to the postgres password}"
: "${PROJECT_ID:?Set PROJECT_ID}"
REGION="${REGION:-us-central1}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ">>> Reseeding source..."
PGPASSWORD="${DB_PASS}" psql -h "${DB_HOST}" -U postgres -d lender \
  -v ON_ERROR_STOP=1 -f "${SCRIPT_DIR}/../sql/seed.sql"

echo ">>> Dropping BigQuery table so it can't carry over stale rows..."
PROJECT_ID="${PROJECT_ID}" "${SCRIPT_DIR}/rm_loans_table.sh"

echo ">>> Backfilling BigQuery from current source state..."
PROJECT_ID="${PROJECT_ID}" REGION="${REGION}" "${SCRIPT_DIR}/backfill_loans_table.sh"

echo ">>> Reset complete. Run scripts/verify_bq.sh to confirm BigQuery matches."
