CREATE POLICY "super_admins_can_delete_locations"
ON locations FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE user_id = auth.uid() AND role = 'super_admin'
  )
);
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('event_categories', 'admission_types', 'event_tags');

ALTER TYPE approval_status ADD VALUE IF NOT EXISTS 'draft';

ALTER TABLE prides
  ADD COLUMN IF NOT EXISTS approval_status approval_status NOT NULL DEFAULT 'approved';


  CREATE OR REPLACE FUNCTION public.handle_new_user_insert()
  RETURNS trigger
  LANGUAGE plpgsql
  SECURITY DEFINER SET search_path = public
  AS $$
  BEGIN
    INSERT INTO public.users (user_id, email)
    VALUES (NEW.id, NEW.email);
    RETURN NEW;
  END;
  $$;

   SELECT prosrc FROM pg_proc WHERE proname = 'handle_new_user_insert';
SELECT relname, relrowsecurity
  FROM pg_class
  WHERE relname = 'users'
    AND relnamespace = 'public'::regnamespace;

     SELECT trigger_name, event_manipulation, action_statement
  FROM information_schema.triggers
  WHERE event_object_schema = 'auth'
    AND event_object_table = 'users';


    ALTER TABLE locations
    ADD COLUMN IF NOT EXISTS has_pending_edit BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS pending_edit_data JSONB;
-- Check current policies on event_tags
  SELECT * FROM pg_policies WHERE tablename = 'event_tags';

  -- Allow all authenticated users to read event tags
  CREATE POLICY "allow_read_event_tags"
  ON event_tags
  FOR SELECT
  TO authenticated
  USING (true);

  -- Or if you want public read (no login required):
  CREATE POLICY "allow_public_read_event_tags"
  ON event_tags
  FOR SELECT
  TO anon, authenticated
  USING (true);

  -- 1. Check if the tables exist and have data
  SELECT 'event_categories' AS tbl, COUNT(*) FROM event_categories
  UNION ALL
  SELECT 'admission_types', COUNT(*) FROM admission_types
  UNION ALL
  SELECT 'event_tags', COUNT(*) FROM event_tags;

  -- 2. Check the column names (in case they differ from 'label')
  SELECT column_name, data_type
  FROM information_schema.columns
  WHERE table_name = 'event_categories';

  -- 3. Check RLS policies
  SELECT tablename, policyname, cmd, roles
  FROM pg_policies
  WHERE tablename IN ('event_categories', 'admission_types', 'event_tags');


  -- Fix admission types
  CREATE POLICY "allow_read_admission_types"
  ON admission_types
  FOR SELECT
  TO authenticated
  USING (true);

  -- Check existing policies on events table
  SELECT policyname, cmd, roles, qual, with_check
  FROM pg_policies
  WHERE tablename = 'events';

  --Share the output, but most likely you just need to add an INSERT policy. Run this to fix it:

  --If owner_id can also be null at insert time (it gets set after), use:

  CREATE POLICY "allow_insert_events"
  ON events
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

 -- Also make sure SELECT and UPDATE policies exist for events:

  -- Allow reading approved/pending events
  CREATE POLICY "allow_read_events"
  ON events
  FOR SELECT
  TO authenticated
  USING (true);

  -- Allow owners and admins to update
  CREATE POLICY "allow_update_events"
  ON events
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);


   -- Check if locations table has INSERT policy
  SELECT policyname, cmd, roles
  FROM pg_policies
  WHERE tablename = 'locations';

  --If there's no INSERT policy, add it:

  -- Allow authenticated users to insert locations
  CREATE POLICY "allow_insert_locations"
  ON locations
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = owner_id);

  -- Allow authenticated users to read locations
  CREATE POLICY "allow_read_locations"
  ON locations
  FOR SELECT
  TO authenticated
  USING (true);

  -- Allow owners to update their own locations
  CREATE POLICY "allow_update_locations"
  ON locations
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);
SELECT policyname, cmd FROM pg_policies
  WHERE tablename = 'event_categories';

    CREATE POLICY "allow_read_event_categories"
  ON event_categories
  FOR SELECT TO authenticated
  USING (true);


  CREATE POLICY "allow_insert_bulk_drafts"
  ON bulk_upload_events_drafts FOR INSERT TO authenticated WITH CHECK (auth.uid() = admin_user_id);

  CREATE POLICY "allow_update_bulk_drafts"
  ON bulk_upload_events_drafts FOR UPDATE TO authenticated USING (auth.uid() = admin_user_id);

  CREATE POLICY "allow_read_bulk_drafts"
  ON bulk_upload_events_drafts FOR SELECT TO authenticated USING (auth.uid() = admin_user_id);



ALTER TABLE events
  ADD COLUMN IF NOT EXISTS types TEXT[] DEFAULT '{}';


  create policy "public read event_types"
    on public.event_types for select
    using (true);

  create policy "public read event_tags"
    on public.event_tags for select
    using (true);


    ALTER TABLE prides
  ADD COLUMN IF NOT EXISTS is_draft BOOLEAN NOT NULL DEFAULT FALSE;
  ALTER TABLE events
  ALTER COLUMN tags DROP NOT NULL,
  ALTER COLUMN tags SET DEFAULT '{}';


  -- Helper function avoids recursive RLS (querying users table inside a users policy)
  CREATE OR REPLACE FUNCTION public.get_my_role()
  RETURNS text
  LANGUAGE sql
  SECURITY DEFINER
  STABLE
  AS $$
    SELECT role FROM public.users WHERE user_id = auth.uid();
  $$;

  -- Allow super_admins to see all users
  CREATE POLICY "super_admins can read all users"
  ON public.users
  FOR SELECT
  USING (
    auth.uid() = user_id          -- own row (existing behaviour)
    OR public.get_my_role() = 'super_admin'
  );
  alter table events alter column start_date drop not null;
alter table events alter column end_date   drop not null;
alter table events alter column start_time drop not null;
alter table events alter column end_time   drop not null;