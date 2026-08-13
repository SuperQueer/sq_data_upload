-- Remove unused Category field to simplify event management.
-- Categories were superseded by the tags (event_tags) and types (event_types)
-- systems; the category columns and lookup table are no longer written to or
-- read by the application.

ALTER TABLE events DROP COLUMN IF EXISTS categories;
ALTER TABLE locations DROP COLUMN IF EXISTS categories;

DROP POLICY IF EXISTS "allow_read_event_categories" ON event_categories;

DROP TABLE IF EXISTS event_categories;
