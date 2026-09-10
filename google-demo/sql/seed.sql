-- ============================================================
-- Seed: a handful of loans across 3 branches so the dashboard
-- opens on a believable number. All names/CURPs synthetic.
--
--   PGPASSWORD='<postgres_password>' psql -h <IP> -U postgres -d lender -f sql/seed.sql
--
-- Idempotent: deletes and reloads. Safe to re-run before any
-- rehearsal.
--
-- Uses DELETE, not TRUNCATE: Postgres logical replication does not
-- replicate TRUNCATE by default, so Datastream/BigQuery would never
-- see the wipe and old rows would pile up instead of resetting.
-- ============================================================

BEGIN;

DELETE FROM public.loans;

INSERT INTO public.loans (branch, officer, customer_name, curp, amount_mxn, term_weeks) VALUES
  ('Downtown', 'OF-101', 'Maria Gonzalez', 'XXXX010101DEMO01', 12500.00, 16),
  ('Downtown', 'OF-102', 'John Ramirez',   'XXXX020202DEMO02',  8000.00, 12),
  ('North',    'OF-103', 'Anna Torres',    'XXXX030303DEMO03', 15000.00, 24),
  ('North',    'OF-101', 'Luis Fernandez', 'XXXX040404DEMO04',  6500.00, 12),
  ('Valley',   'OF-104', 'Carmen Ruiz',    'XXXX050505DEMO05', 20000.00, 52),
  ('Valley',   'OF-102', 'Peter Sanchez',  'XXXX060606DEMO06',  9500.00, 16),
  ('Downtown', 'OF-103', 'Laura Mendez',   'XXXX070707DEMO07', 11000.00, 24),
  ('North',    'OF-104', 'Michael Castillo', 'XXXX080808DEMO08', 17500.00, 52);

COMMIT;

SELECT COUNT(*) AS loans_seeded FROM public.loans;
