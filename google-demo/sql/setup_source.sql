-- ============================================================
-- One-time setup. Run as the default `postgres` user against
-- the `lender` database AFTER terraform apply:
--
--   PGPASSWORD='<postgres pw>' psql -h <IP> -U postgres -d lender -f sql/setup_source.sql
--
-- (Set the postgres user's password first:
--   gcloud sql users set-password postgres --instance=mfi-core-demo --password=...)
-- ============================================================

-- The operational table. Deliberately boring: it looks like a
-- core banking table, not a demo prop.
CREATE TABLE IF NOT EXISTS public.loans (
  loan_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  branch         TEXT NOT NULL,
  officer        TEXT NOT NULL,
  customer_name  TEXT NOT NULL,          -- fictional names only
  curp           TEXT NOT NULL,          -- synthetic, clearly fake pattern
  amount_mxn     NUMERIC(12, 2) NOT NULL,
  term_weeks     INT NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Datastream needs full row images for updates/deletes.
ALTER TABLE public.loans REPLICA IDENTITY FULL;

-- Publication + replication slot that the Datastream stream expects.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'loans_stream') THEN
    CREATE PUBLICATION loans_stream FOR TABLE public.loans;
  END IF;
END $$;

-- Cloud SQL's `postgres` user is cloudsqlsuperuser, not a true superuser,
-- so it lacks REPLICATION by default even though it can grant it to others.
ALTER USER postgres WITH REPLICATION;

SELECT PG_CREATE_LOGICAL_REPLICATION_SLOT('loans_stream_slot', 'pgoutput')
WHERE NOT EXISTS (
  SELECT 1 FROM pg_replication_slots WHERE slot_name = 'loans_stream_slot'
);

-- The datastream user (created by Terraform) needs replication + read.
ALTER USER datastream WITH REPLICATION;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO datastream;
GRANT USAGE ON SCHEMA public TO datastream;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO datastream;

-- The app user inserts during the demo.
GRANT INSERT, SELECT ON public.loans TO demo_app;
