-- Remove audience_type column from events table
ALTER TABLE public.events DROP COLUMN IF EXISTS audience_type;

-- Drop audience_type lookup table
DROP TABLE IF EXISTS public.audience_type;


ALTER TABLE public.events
    ADD COLUMN admission_type_ids text[];

UPDATE public.events
SET admission_type_ids = ARRAY[admission_type_id]
WHERE admission_type_id IS NOT NULL;

ALTER TABLE public.events
    DROP COLUMN admission_type_id;

-- ============================================================
-- 1. Extend approval_status enum with 'draft'
--    Workflow: draft → pending → approved / rejected
-- ============================================================
ALTER TYPE approval_status ADD VALUE IF NOT EXISTS 'draft';


-- ============================================================
-- 2. Add approval_status to prides
--    Existing prides default to 'approved' so they stay live.
-- ============================================================
ALTER TABLE prides
  ADD COLUMN IF NOT EXISTS approval_status approval_status NOT NULL DEFAULT 'approved';


-- ============================================================
-- 3. RLS: hide drafts from everyone except super_admins
--    Drop first so the migration is safe to re-run.
-- ============================================================

-- Events
DROP POLICY IF EXISTS "drafts_visible_to_super_admins_events" ON events;
CREATE POLICY "drafts_visible_to_super_admins_events"
ON events FOR SELECT
USING (
  approval_status != 'draft'
  OR EXISTS (
    SELECT 1 FROM users
    WHERE user_id = auth.uid() AND role = 'super_admin'
  )
);

-- Locations (covers both resources and businesses)
DROP POLICY IF EXISTS "drafts_visible_to_super_admins_locations" ON locations;
CREATE POLICY "drafts_visible_to_super_admins_locations"
ON locations FOR SELECT
USING (
  approval_status != 'draft'
  OR EXISTS (
    SELECT 1 FROM users
    WHERE user_id = auth.uid() AND role = 'super_admin'
  )
);

-- Prides
DROP POLICY IF EXISTS "drafts_visible_to_super_admins_prides" ON prides;
CREATE POLICY "drafts_visible_to_super_admins_prides"
ON prides FOR SELECT
USING (
  approval_status != 'draft'
  OR EXISTS (
    SELECT 1 FROM users
    WHERE user_id = auth.uid() AND role = 'super_admin'
  )
);


-- ============================================================
-- 4. RLS: allow super_admins and admins to delete locations
-- ============================================================
DROP POLICY IF EXISTS "admins_can_delete_locations" ON locations;
CREATE POLICY "admins_can_delete_locations"
ON locations FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE user_id = auth.uid() AND role IN ('super_admin', 'admin')
  )
);

-- ============================================================
-- 1. Extend approval_status enum with 'cancelled'
-- ============================================================
ALTER TYPE approval_status ADD VALUE IF NOT EXISTS 'cancelled';


-- ============================================================
-- 2. Drop/recreate check constraint if one exists
--    (guards against DB-level rejections of the new value)
-- ============================================================
ALTER TABLE events DROP CONSTRAINT IF EXISTS events_approval_status_check;
ALTER TABLE events ADD CONSTRAINT events_approval_status_check
  CHECK (approval_status IN ('draft', 'pending', 'approved', 'rejected', 'cancelled'));


-- ============================================================
-- 3. RLS SELECT: cancelled events are hidden from regular users
--    but remain visible to admins/super_admins for history.
--    Replaces the earlier draft-only policy on events.
-- ============================================================
DROP POLICY IF EXISTS "drafts_visible_to_super_admins_events" ON events;
DROP POLICY IF EXISTS "filter_events_by_status" ON events;

CREATE POLICY "filter_events_by_status"
ON events FOR SELECT
USING (
  -- Super admins see everything (including drafts + cancelled)
  EXISTS (
    SELECT 1 FROM users
    WHERE user_id = auth.uid() AND role = 'super_admin'
  )
  OR
  -- Admins see all except drafts (can see cancelled for history)
  (
    EXISTS (
      SELECT 1 FROM users
      WHERE user_id = auth.uid() AND role IN ('admin', 'pride_admin')
    )
    AND approval_status != 'draft'
  )
  OR
  -- Everyone else only sees approved events
  approval_status = 'approved'
);


-- ============================================================
-- 4. RPC: owners cancel their own event
--    Using SECURITY DEFINER so the function runs with elevated
--    privileges, but validates ownership inside.
--    Flutter call: supabase.rpc('cancel_event', {'p_event_id': id})
-- ============================================================
CREATE OR REPLACE FUNCTION cancel_event(p_event_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE events
  SET approval_status = 'cancelled',
      updated_at = now()
  WHERE id = p_event_id
    AND owner_id = auth.uid()
    AND approval_status != 'cancelled';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event not found, already cancelled, or you do not own this event';
  END IF;
END;
$$;


-- ============================================================
-- 5. RLS DELETE: admins can delete any user-submitted event
-- ============================================================
DROP POLICY IF EXISTS "admins_can_delete_events" ON events;

CREATE POLICY "admins_can_delete_events"
ON events FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE user_id = auth.uid() AND role IN ('super_admin', 'admin')
  )
);
-- Migration: Pride Bulk Upload Support
-- Date: 2026-06-23
-- Description: Adds social media columns to prides table and creates
--              the bulk_upload_prides_drafts table for draft persistence.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Add social media columns to prides table
-- ─────────────────────────────────────────────────────────────────────────────
alter table prides add column if not exists instagram text;
alter table prides add column if not exists threads  text;
alter table prides add column if not exists facebook text;
alter table prides add column if not exists tiktok   text;
alter table prides add column if not exists linkedin text;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Create bulk_upload_prides_drafts table
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists bulk_upload_prides_drafts (
  id             uuid        primary key default gen_random_uuid(),
  admin_user_id  text        not null,
  draft_data     jsonb,
  updated_at     timestamptz default now()
);

-- Index for fast lookup by admin user
create index if not exists idx_bulk_upload_prides_drafts_admin_user
  on bulk_upload_prides_drafts (admin_user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. RLS policies for bulk_upload_prides_drafts
-- ─────────────────────────────────────────────────────────────────────────────
alter table bulk_upload_prides_drafts enable row level security;

-- Authenticated users can read their own drafts
create policy "Users can read own pride drafts"
  on bulk_upload_prides_drafts for select
  using (admin_user_id = auth.uid()::text);

-- Authenticated users can insert their own drafts
create policy "Users can insert own pride drafts"
  on bulk_upload_prides_drafts for insert
  with check (admin_user_id = auth.uid()::text);

-- Authenticated users can update their own drafts
create policy "Users can update own pride drafts"
  on bulk_upload_prides_drafts for update
  using (admin_user_id = auth.uid()::text);

-- Authenticated users can delete their own drafts
create policy "Users can delete own pride drafts"
  on bulk_upload_prides_drafts for delete
  using (admin_user_id = auth.uid()::text);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. RLS policies for prides table (insert / update / delete for admins)
-- ─────────────────────────────────────────────────────────────────────────────
drop policy if exists "admins_can_insert_prides" on prides;
create policy "admins_can_insert_prides"
  on prides for insert
  with check (
    exists (
      select 1 from users
      where user_id = auth.uid() and role in ('super_admin', 'admin')
    )
  );

drop policy if exists "admins_can_update_prides" on prides;
create policy "admins_can_update_prides"
  on prides for update
  using (
    exists (
      select 1 from users
      where user_id = auth.uid() and role in ('super_admin', 'admin')
    )
  );

drop policy if exists "admins_can_delete_prides" on prides;
create policy "admins_can_delete_prides"
  on prides for delete
  using (
    exists (
      select 1 from users
      where user_id = auth.uid() and role in ('super_admin', 'admin')
    )
  );
ALTER TABLE event_tags
  ADD COLUMN IF NOT EXISTS type_id UUID REFERENCES event_types(id) ON DELETE SET NULL;

ALTER TABLE event_types
  ADD COLUMN IF NOT EXISTS type_id UUID;

ALTER TABLE events
  ADD COLUMN IF NOT EXISTS types TEXT[] DEFAULT '{}';

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Ensure events table has both tags and types columns
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE events
  ADD COLUMN IF NOT EXISTS tags  TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS types TEXT[] DEFAULT '{}';

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Create bulk_upload_events_drafts table
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bulk_upload_events_drafts (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id TEXT        NOT NULL,
  draft_data    JSONB,
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bulk_upload_events_drafts_admin_user
  ON bulk_upload_events_drafts (admin_user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. RLS policies for bulk_upload_events_drafts
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE bulk_upload_events_drafts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own event drafts"
  ON bulk_upload_events_drafts FOR SELECT
  USING (admin_user_id = auth.uid()::text);

CREATE POLICY "Users can insert own event drafts"
  ON bulk_upload_events_drafts FOR INSERT
  WITH CHECK (admin_user_id = auth.uid()::text);

CREATE POLICY "Users can update own event drafts"
  ON bulk_upload_events_drafts FOR UPDATE
  USING (admin_user_id = auth.uid()::text);

CREATE POLICY "Users can delete own event drafts"
  ON bulk_upload_events_drafts FOR DELETE
  USING (admin_user_id = auth.uid()::text);

ALTER TABLE prides
  ADD COLUMN IF NOT EXISTS is_draft BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE events
  ALTER COLUMN tags DROP NOT NULL,
  ALTER COLUMN tags SET DEFAULT '{}';



alter table events alter column start_date drop not null;
alter table events alter column end_date   drop not null;
alter table events alter column start_time drop not null;
alter table events alter column end_time   drop not null;

-- Migration: Super-admin UPDATE policies for events and locations
-- Date: 2026-06-30
-- Problem: updateApprovalStatus was silently updating 0 rows because no RLS
--          UPDATE policy existed for super-admins on these tables.
--          Supabase does not throw on a blocked UPDATE — it just returns [].

-- Events: super-admin can update any row (approval, cancellation, edits)
do $$ begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'events'
      and policyname = 'super_admin can update any event'
  ) then
    create policy "super_admin can update any event"
      on events for update
      using (
        exists (
          select 1 from public.users
          where user_id = auth.uid()
            and role = 'super_admin'
        )
      );
  end if;
end $$;

-- Locations: super-admin can update any row
do $$ begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'locations'
      and policyname = 'super_admin can update any location'
  ) then
    create policy "super_admin can update any location"
      on locations for update
      using (
        exists (
          select 1 from public.users
          where user_id = auth.uid()
            and role = 'super_admin'
        )
      );
  end if;
end $$;

-- Problem: submitLocationEdit()/resubmitLocationEdit()/updateLocation() all
--          filter by `.eq('owner_id', userId)`, but no RLS UPDATE policy
--          exists letting a regular user update their own location row —
--          only "super_admin can update any location" (see
--          20260630_super_admin_update_policies.sql). Supabase does not
--          throw on a blocked UPDATE, it just returns [] affected rows, so
--          owner-submitted edits (business or resource, any approval status)
--          silently do nothing.

do $$ begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'locations'
      and policyname = 'owner can update own location'
  ) then
    create policy "owner can update own location"
      on locations for update
      using (owner_id = auth.uid())
      with check (owner_id = auth.uid());
  end if;
end $$;


  CREATE POLICY "Super admins can delete any location"
  ON locations FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'super_admin'
    )
  );
