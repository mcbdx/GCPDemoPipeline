#!/usr/bin/env bash
# ============================================================
# Start the Datastream stream (created PAUSED by Terraform,
# because the publication/slot must exist in Postgres first).
# Run once, after sql/setup_source.sql and sql/seed.sql.
#
# Usage:
#   PROJECT_ID=<project> REGION=us-central1 ./scripts/start_stream.sh
# ============================================================
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
REGION="${REGION:-us-central1}"

gcloud datastream streams update loans-cdc \
  --location="${REGION}" \
  --project="${PROJECT_ID}" \
  --state=RUNNING \
  --update-mask=state

echo ">>> Stream starting. Backfill of the 47 seed rows begins now."
echo ">>> Check status: gcloud datastream streams describe loans-cdc --location=${REGION}"
