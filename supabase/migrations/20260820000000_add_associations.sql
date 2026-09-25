-- Migration: Add Associations feature
-- Date: 2026-08-20
-- Adds a flat catalog of "Associations" (InterPride, US Prides, EPOA,
-- Fierte Canada Pride, Chambers of Commerce, etc.) that Pride orgs,
-- Businesses, and Resources can be tagged with via a CMS multi-select
-- dropdown, mirroring the existing events.tags / event_tags catalog pattern.
--
-- The table, RLS policy, prides/locations columns, and catalog seed already
-- exist on the linked Dev project (configured directly via SQL editor, never
-- version-controlled, and since extended with an "EPOA" row and a
-- "Fierte Canada Pride" rename) — this migration captures their live shape
-- exactly so it is a safe no-op against Dev, and brings any other
-- environment (e.g. Prod) up to the same state.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Associations catalog table
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS associations (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  label      TEXT NOT NULL UNIQUE,
  sort_order INT  DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE associations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "allow_read_associations" ON associations;
CREATE POLICY "allow_read_associations"
  ON associations FOR SELECT TO authenticated USING (true);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Flat associations array column on prides and locations
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE prides
  ADD COLUMN IF NOT EXISTS associations TEXT[] DEFAULT '{}';

ALTER TABLE locations
  ADD COLUMN IF NOT EXISTS associations TEXT[] DEFAULT '{}';

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Seed initial associations catalog (matches live Dev catalog)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO associations (label, sort_order) VALUES
  ('InterPride', 1),
  ('EPOA', 2),
  ('US Prides', 3),
  ('Fierte Canada Pride', 4),
  ('Chambers of Commerce', 5)
ON CONFLICT (label) DO NOTHING;
