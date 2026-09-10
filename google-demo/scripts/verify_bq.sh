#!/usr/bin/env bash
# ============================================================
# Sanity check: does BigQuery agree with the source?
# Run after reset, after rehearsal inserts, and 30 min before
# the interview.
#
# Usage:
#   PROJECT_ID=<project> ./scripts/verify_bq.sh
# ============================================================
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"

bq query --use_legacy_sql=false --project_id="${PROJECT_ID}" \
  "SELECT COUNT(*) AS loans_in_bq, MAX(created_at) AS latest_loan
   FROM \`${PROJECT_ID}.lender_analytics.public_loans\`"
