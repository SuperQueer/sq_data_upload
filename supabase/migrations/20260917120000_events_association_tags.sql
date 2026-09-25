-- Adds an `association_tags` column to `events`, mirroring the free-text
-- association-tags concept that already exists on `prides`
-- (public.prides.association_tags, text[]). Events had no equivalent column,
-- so bulk-uploaded/CMS-entered event association tags had nowhere to land.
--
-- Idempotent (add column if not exists) so it's safe to re-run.

alter table public.events add column if not exists association_tags text[];
alter table public.locations add column if not exists is_lgbt_owned boolean;
