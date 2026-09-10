#!/usr/bin/env bash
# ============================================================
# THE demo command. Inserts one loan, so it always succeeds no
# matter how many times you run it.
#
# Usage:
#   DB_HOST=<IP> DB_PASS=<postgres_password> ./scripts/insert_loan.sh
#
# During the demo, say the sentence, hit enter, keep talking.
# ============================================================
set -euo pipefail

: "${DB_HOST:?Set DB_HOST to the Cloud SQL public IP}"
: "${DB_PASS:?Set DB_PASS to the postgres password}"

PGPASSWORD="${DB_PASS}" psql -h "${DB_HOST}" -U postgres -d lender -v ON_ERROR_STOP=1 <<SQL
INSERT INTO public.loans (branch, officer, customer_name, curp, amount_mxn, term_weeks)
VALUES ('Downtown', 'OF-101', 'Live Demo Customer', 'XXXX999999DEMO09', 12500.00, 16);

SELECT loan_id, branch, amount_mxn, created_at
FROM public.loans
ORDER BY loan_id DESC
LIMIT 1;
SQL

echo ""
echo ">>> Loan captured in the core. Watch it land in BigQuery."
