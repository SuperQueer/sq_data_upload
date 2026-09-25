-- Adds a Types/Tags taxonomy for Locations, scoped per category
-- ('business' vs 'resource'), mirroring the existing event_types/event_tags
-- schema and RLS pattern.
--
-- After this runs, seed location_types with your Business types and
-- Resource types (category = 'business' / 'resource' per row), and
-- location_tags with each type's tags via type_id — same shape as
-- event_types_rows.sql / import_tags_type.sql.

CREATE TABLE location_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  name TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('business', 'resource')),
  UNIQUE (name, category)
);

CREATE TABLE location_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  type_id UUID REFERENCES location_types(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  UNIQUE (type_id, label)
);

ALTER TABLE location_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE location_tags ENABLE ROW LEVEL SECURITY;

-- Public read, matching "public read event_types" / "public read event_tags"
-- in sprint_1_production.sql — guest browsing needs this readable with no login.
CREATE POLICY "public read location_types"
  ON location_types FOR SELECT
  USING (true);

CREATE POLICY "public read location_tags"
  ON location_tags FOR SELECT
  USING (true);

-- New column on locations to hold the selected type-name strings,
-- mirroring events.types (see sprint_1_production.sql line ~266).
ALTER TABLE locations
  ADD COLUMN IF NOT EXISTS types TEXT[] DEFAULT '{}';
