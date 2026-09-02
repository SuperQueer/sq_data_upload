-- RLS policies for the Collections feature:
--   lib/shared/services/collections_service.dart
--   lib/features/collections/
--
-- collections, collection_event_links, collection_location_links already
-- exist on the linked Dev project (configured directly via SQL editor,
-- never version-controlled) — this migration only adds/repairs their RLS
-- policies (idempotent: safe to run even if a same-named policy already
-- exists). It does not touch table shape.
--
-- Symptom this fixes: PostgrestException 42501 "new row violates row-level
-- security policy for table \"collections\"" when calling createCollection()
-- — the insert already sets owner_id = auth.uid() correctly client-side, so
-- this means either RLS was enabled with no INSERT policy, or the existing
-- policy didn't match on owner_id the way these do.

-- ---------------------------------------------------------------------------
-- collections — a row is owned by the user who created it
-- ---------------------------------------------------------------------------

alter table public.collections enable row level security;

drop policy if exists "owner manages own collections" on public.collections;
create policy "owner manages own collections"
  on public.collections for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

-- ---------------------------------------------------------------------------
-- collection_event_links — ownership is via the parent collection
-- ---------------------------------------------------------------------------

alter table public.collection_event_links enable row level security;

drop policy if exists "owner manages own collection event links" on public.collection_event_links;
create policy "owner manages own collection event links"
  on public.collection_event_links for all
  using (
    exists (
      select 1 from public.collections c
      where c.id = collection_event_links.collection_id
        and c.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.collections c
      where c.id = collection_event_links.collection_id
        and c.owner_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- collection_location_links — ownership is via the parent collection
-- ---------------------------------------------------------------------------

alter table public.collection_location_links enable row level security;

drop policy if exists "owner manages own collection location links" on public.collection_location_links;
create policy "owner manages own collection location links"
  on public.collection_location_links for all
  using (
    exists (
      select 1 from public.collections c
      where c.id = collection_location_links.collection_id
        and c.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.collections c
      where c.id = collection_location_links.collection_id
        and c.owner_id = auth.uid()
    )
  );
