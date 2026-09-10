#!/usr/bin/env bash
# ============================================================
# Force Datastream to re-backfill the loans object, recreating
# public_loans in BigQuery from the current state of the source
# table (streaming CDC alone won't do this - it only ships
# changes going forward, not full existing state).
#
# Run this after scripts/rm_loans_table.sh, or any time BigQuery
# needs to be resynced from scratch.
#
# Usage:
#   PROJECT_ID=<project> REGION=us-central1 ./scripts/backfill_loans_table.sh
# ============================================================
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
REGION="${REGION:-us-central1}"
STREAM="loans-cdc"

OBJECT_NAME="$(gcloud datastream objects list \
  --stream="${STREAM}" --location="${REGION}" --project="${PROJECT_ID}" \
  --format="value(name)" --filter="displayName:loans")"

: "${OBJECT_NAME:?Could not find the loans object on stream ${STREAM}}"

echo ">>> Starting backfill for: ${OBJECT_NAME}"

gcloud datastream objects start-backfill "${OBJECT_NAME}" \
  --stream="${STREAM}" --location="${REGION}" --project="${PROJECT_ID}"

echo ">>> Backfill started. Check status with:"
echo "    gcloud datastream objects describe ${OBJECT_NAME} --stream=${STREAM} --location=${REGION} --project=${PROJECT_ID}"
echo ">>> Then verify: PROJECT_ID=${PROJECT_ID} ./scripts/verify_bq.sh"
