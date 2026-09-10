#!/usr/bin/env bash
# ============================================================
# Drop the public_loans table in BigQuery.
#
# Needed because BigQuery blocks DELETE/UPDATE/MERGE on tables
# written by a Datastream CDC upsert stream, so a stale/duplicated
# table can't be cleaned up with SQL. Dropping the table is a
# resource delete, not DML, so it's allowed.
#
# After this, run scripts/backfill_loans_table.sh to have
# Datastream recreate the table from the current source data.
#
# Usage:
#   PROJECT_ID=<project> ./scripts/rm_loans_table.sh
# ============================================================
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"

if bq show "${PROJECT_ID}:lender_analytics.public_loans" >/dev/null 2>&1; then
  bq rm -f -t "${PROJECT_ID}:lender_analytics.public_loans"
  echo ">>> public_loans table dropped. Run scripts/backfill_loans_table.sh to recreate it."
else
  echo ">>> public_loans table already absent, nothing to drop."
fi
