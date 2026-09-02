-- Drafts tables backing the CMS "Bulk upload" table screens:
--   lib/app_cms/features/bulk_upload/            (Events)
--   lib/app_cms/features/bulk_upload_prides/     (Prides)
--   lib/app_cms/features/bulk_upload_locations/  (Businesses/Resources)
--
-- bulk_upload_events_drafts and bulk_upload_prides_drafts already exist on
-- the linked Dev project (configured directly via SQL editor, never
-- version-controlled) — this migration captures their live shape exactly
-- (verified against the Dev DB catalog: columns, defaults, RLS policies) so
-- `create table if not exists` below is a safe no-op against them, and adds
-- bulk_upload_locations_drafts, which does not exist yet.

-- ---------------------------------------------------------------------------
-- bulk_upload_events_drafts (existing — captured, not modified)
-- ---------------------------------------------------------------------------

create table if not exists public.bulk_upload_events_drafts (
  id            uuid primary key default gen_random_uuid(),
  admin_user_id uuid not null,
  draft_data    jsonb not null,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

alter table public.bulk_upload_events_drafts enable row level security;

drop policy if exists "allow_insert_bulk_drafts" on public.bulk_upload_events_drafts;
create policy "allow_insert_bulk_drafts"
  on public.bulk_upload_events_drafts for insert
  to authenticated
  with check (auth.uid() = admin_user_id);

drop policy if exists "allow_update_bulk_drafts" on public.bulk_upload_events_drafts;
create policy "allow_update_bulk_drafts"
  on public.bulk_upload_events_drafts for update
  to authenticated
  using (auth.uid() = admin_user_id);

drop policy if exists "allow_read_bulk_drafts" on public.bulk_upload_events_drafts;
create policy "allow_read_bulk_drafts"
  on public.bulk_upload_events_drafts for select
  to authenticated
  using (auth.uid() = admin_user_id);

drop policy if exists "owner can delete own draft" on public.bulk_upload_events_drafts;
create policy "owner can delete own draft"
  on public.bulk_upload_events_drafts for delete
  using ((admin_user_id)::text = (auth.uid())::text);

-- ---------------------------------------------------------------------------
-- bulk_upload_prides_drafts (existing — captured, not modified)
-- ---------------------------------------------------------------------------

create table if not exists public.bulk_upload_prides_drafts (
  id            uuid primary key default gen_random_uuid(),
  admin_user_id text not null,
  draft_data    jsonb,
  updated_at    timestamptz default now()
);

create index if not exists idx_bulk_upload_prides_drafts_admin_user
  on public.bulk_upload_prides_drafts (admin_user_id);

alter table public.bulk_upload_prides_drafts enable row level security;

drop policy if exists "Users can read own pride drafts" on public.bulk_upload_prides_drafts;
create policy "Users can read own pride drafts"
  on public.bulk_upload_prides_drafts for select
  using (admin_user_id = (auth.uid())::text);

drop policy if exists "Users can insert own pride drafts" on public.bulk_upload_prides_drafts;
create policy "Users can insert own pride drafts"
  on public.bulk_upload_prides_drafts for insert
  with check (admin_user_id = (auth.uid())::text);

drop policy if exists "Users can update own pride drafts" on public.bulk_upload_prides_drafts;
create policy "Users can update own pride drafts"
  on public.bulk_upload_prides_drafts for update
  using (admin_user_id = (auth.uid())::text);

drop policy if exists "Users can delete own pride drafts" on public.bulk_upload_prides_drafts;
create policy "Users can delete own pride drafts"
  on public.bulk_upload_prides_drafts for delete
  using (admin_user_id = (auth.uid())::text);

-- ---------------------------------------------------------------------------
-- bulk_upload_locations_drafts (new)
-- ---------------------------------------------------------------------------

create table if not exists public.bulk_upload_locations_drafts (
  id             uuid primary key default gen_random_uuid(),
  admin_user_id  uuid not null references auth.users(id) on delete cascade,
  draft_data     jsonb not null,
  updated_at     timestamptz not null default now()
);

create index if not exists idx_bulk_upload_locations_drafts_admin_updated
  on public.bulk_upload_locations_drafts (admin_user_id, updated_at desc);

alter table public.bulk_upload_locations_drafts enable row level security;

drop policy if exists "admin manages own bulk upload location drafts" on public.bulk_upload_locations_drafts;
create policy "admin manages own bulk upload location drafts"
  on public.bulk_upload_locations_drafts for all
  using (auth.uid() = admin_user_id)
  with check (auth.uid() = admin_user_id);
