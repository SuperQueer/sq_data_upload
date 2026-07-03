-- Migration: Notification System
-- Date: 2026-06-25
-- Description: Adds cms_notifications (real-time bell for super-admins) and
--              user_fcm_tokens (mobile push delivery for FCM), plus a Postgres
--              trigger that fans out a CMS notification to every super-admin
--              whenever a user submits content for review.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. cms_notifications table
--    One row per (super-admin × submission). read_at = null means unread.
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists cms_notifications (
  id               uuid        primary key default gen_random_uuid(),
  recipient_id     uuid        not null references auth.users(id) on delete cascade,
  reference_type   text        not null check (reference_type in ('event', 'location')),
  reference_id     uuid        not null,
  title            text        not null,
  message          text        not null,
  created_at       timestamptz not null default now(),
  read_at          timestamptz           -- null = unread
);

-- Partial index: fast unread count per recipient (the hot query).
create index if not exists idx_cms_notif_recipient_unread
  on cms_notifications (recipient_id, created_at desc)
  where read_at is null;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. RLS for cms_notifications
-- ─────────────────────────────────────────────────────────────────────────────
alter table cms_notifications enable row level security;

-- Super-admin can read only their own notifications.
create policy "recipient reads own notifications"
  on cms_notifications for select
  using (auth.uid() = recipient_id);

-- Super-admin can mark only their own notifications as read.
-- The check prevents tampering with any other field via the update path.
create policy "recipient marks own as read"
  on cms_notifications for update
  using  (auth.uid() = recipient_id)
  with check (auth.uid() = recipient_id);

-- Inserts come exclusively from the trigger (SECURITY DEFINER, runs as
-- postgres which bypasses RLS). No INSERT policy needed for clients.

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. user_fcm_tokens table
--    One row per user. Upserted on login; deleted on logout.
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists user_fcm_tokens (
  user_id    uuid        primary key references auth.users(id) on delete cascade,
  token      text        not null,
  platform   text        not null check (platform in ('ios', 'android')),
  updated_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. RLS for user_fcm_tokens
-- ─────────────────────────────────────────────────────────────────────────────
alter table user_fcm_tokens enable row level security;

-- Users manage only their own token (insert + update + delete).
create policy "user manages own fcm token"
  on user_fcm_tokens for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Edge Function (service_role key) reads any token to send push.
-- auth.role() = 'service_role' is true when called with the service key.
create policy "service role reads fcm tokens"
  on user_fcm_tokens for select
  using (auth.role() = 'service_role');

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Trigger function — fan out CMS notification to all super-admins
--
--    Fires AFTER INSERT on events or locations when approval_status = 'pending'.
--    Skips rows submitted by super-admins themselves (they are auto-approved
--    upstream in EventService/LocationService, so this is a safety guard).
--    SECURITY DEFINER runs as the function owner (postgres), which bypasses
--    RLS and lets us SELECT from public.users and INSERT into cms_notifications.
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function notify_admins_on_submission()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  admin_row  record;
  ref_title  text;
  ref_type   text;
begin
  -- Only act on pending submissions.
  if new.approval_status <> 'pending' then
    return new;
  end if;

  -- events table exposes event_name; locations table exposes name.
  ref_title := coalesce(
    nullif(new.event_name, ''),   -- populated on events rows
    nullif(new.name,       ''),   -- populated on locations rows
    'Untitled'
  );

  -- TG_TABLE_NAME is 'events' or 'locations'; map to the reference_type enum.
  ref_type := case tg_table_name
    when 'events'    then 'event'
    when 'locations' then 'location'
  end;

  -- Insert one notification row per super-admin.
  -- public.users.user_id is the auth UID, same UUID as auth.users.id.
  for admin_row in
    select user_id from public.users where role = 'super_admin'
  loop
    insert into public.cms_notifications
      (recipient_id, reference_type, reference_id, title, message)
    values (
      admin_row.user_id,
      ref_type,
      new.id,
      'New submission awaiting review',
      ref_title || ' was submitted and needs approval.'
    );
  end loop;

  return new;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Attach trigger to events and locations
-- ─────────────────────────────────────────────────────────────────────────────
create trigger trg_event_submission
  after insert on events
  for each row execute function notify_admins_on_submission();

create trigger trg_location_submission
  after insert on locations
  for each row execute function notify_admins_on_submission();


-- Re-create notify_admins_on_submission with RAISE LOG so you can
-- see exactly why the trigger fires or skips in Supabase → Logs → Postgres.
--
-- Run this in the Supabase SQL editor to apply.

create or replace function notify_admins_on_submission()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  admin_row  record;
  ref_title  text;
  ref_type   text;
  admin_count int := 0;
begin
  raise log '[notify_admins_on_submission] fired: table=% op=% id=% approval_status=%',
    tg_table_name, tg_op, new.id, new.approval_status;

  -- Only act on pending submissions.
  if new.approval_status <> 'pending' then
    raise log '[notify_admins_on_submission] SKIPPED — approval_status=% is not pending', new.approval_status;
    return new;
  end if;

  ref_title := coalesce(
    nullif(new.event_name, ''),
    nullif(new.name,       ''),
    'Untitled'
  );

  ref_type := case tg_table_name
    when 'events'    then 'event'
    when 'locations' then 'location'
    else tg_table_name
  end;

  raise log '[notify_admins_on_submission] ref_type=% ref_title="%"', ref_type, ref_title;

  for admin_row in
    select user_id from public.users where role = 'super_admin'
  loop
    raise log '[notify_admins_on_submission] inserting notification for admin=%', admin_row.user_id;

    insert into public.cms_notifications
      (recipient_id, reference_type, reference_id, title, message)
    values (
      admin_row.user_id,
      ref_type,
      new.id,
      'New submission awaiting review',
      ref_title || ' was submitted and needs approval.'
    );

    admin_count := admin_count + 1;
  end loop;

  raise log '[notify_admins_on_submission] done — inserted % notification(s)', admin_count;

  return new;
end;
$$;


create or replace function notify_admins_on_submission()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  admin_row  record;
  ref_title  text;
  ref_type   text;
  notif_title text;
  notif_msg   text;
begin
  -- Skip drafts, rejections and cancellations — only notify on real submissions.
  if new.approval_status in ('draft', 'rejected', 'cancelled') then
    return new;
  end if;

  ref_title := coalesce(
    nullif(new.event_name, ''),
    nullif(new.name,       ''),
    'Untitled'
  );

  ref_type := case tg_table_name
    when 'events'    then 'event'
    when 'locations' then 'location'
    else tg_table_name
  end;

  if new.approval_status = 'pending' then
    notif_title := 'New submission awaiting review';
    notif_msg   := ref_title || ' was submitted and needs approval.';
  else
    -- approved — CMS admin created it directly
    notif_title := 'New ' || ref_type || ' published';
    notif_msg   := ref_title || ' was added and is now live.';
  end if;

  for admin_row in
    select user_id from public.users where role = 'super_admin'
  loop
    insert into public.cms_notifications
      (recipient_id, reference_type, reference_id, title, message)
    values (
      admin_row.user_id,
      ref_type,
      new.id,
      notif_title,
      notif_msg
    );
  end loop;

  return new;
end;
$$;


-- Migration: User Notification System
-- Date: 2026-06-26
-- Description: Adds user_notifications (in-app bell for regular users) so that
--              when a CMS admin approves or rejects an event/location submission
--              the original submitter is notified in the app.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. user_notifications table
--    One row per (submitter × approval decision). read_at = null means unread.
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists user_notifications (
  id               uuid        primary key default gen_random_uuid(),
  recipient_id     uuid        not null references auth.users(id) on delete cascade,
  reference_type   text        not null check (reference_type in ('event', 'location')),
  reference_id     uuid        not null,
  title            text        not null,
  message          text        not null,
  created_at       timestamptz not null default now(),
  read_at          timestamptz           -- null = unread
);

-- Fast unread count per recipient.
create index if not exists idx_user_notif_recipient_unread
  on user_notifications (recipient_id, created_at desc)
  where read_at is null;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. RLS for user_notifications
-- ─────────────────────────────────────────────────────────────────────────────
alter table user_notifications enable row level security;

-- Users can read only their own notifications.
create policy "recipient reads own user notifications"
  on user_notifications for select
  using (auth.uid() = recipient_id);

-- Users can mark only their own notifications as read.
create policy "recipient marks own user notification as read"
  on user_notifications for update
  using  (auth.uid() = recipient_id)
  with check (auth.uid() = recipient_id);

-- Inserts come exclusively from the trigger (SECURITY DEFINER). No client INSERT policy needed.

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Trigger function — notify the submitter when their event/location is
--    approved or rejected by a CMS admin.
--
--    Fires AFTER UPDATE on events or locations when approval_status changes.
--    Skips rows with no owner (CMS-created without a submitter).
--    SECURITY DEFINER runs as postgres, bypassing RLS.
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function notify_user_on_approval()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  ref_title  text;
  ref_type   text;
  notif_title text;
  notif_msg   text;
begin
  raise log '[notify_user_on_approval] fired on table=% id=% old_status=% new_status=% owner_id=%',
    tg_table_name, new.id, old.approval_status, new.approval_status, new.owner_id;

  -- Only act when approval_status actually changed to approved or rejected.
  if old.approval_status = new.approval_status then
    raise log '[notify_user_on_approval] skipped — status unchanged';
    return new;
  end if;

  if new.approval_status not in ('approved', 'rejected') then
    raise log '[notify_user_on_approval] skipped — new status is % (not approved/rejected)', new.approval_status;
    return new;
  end if;

  -- Must have an owner to notify.
  if new.owner_id is null then
    raise log '[notify_user_on_approval] skipped — owner_id is null';
    return new;
  end if;

  -- events table exposes event_name; locations table exposes name.
  ref_title := coalesce(
    nullif(new.event_name, ''),
    nullif(new.name,       ''),
    'Your submission'
  );

  ref_type := case tg_table_name
    when 'events'    then 'event'
    when 'locations' then 'location'
  end;

  if new.approval_status = 'approved' then
    notif_title := ref_title || ' was approved!';
    notif_msg   := 'Your ' || ref_type || ' is now live and visible to users.';
  else
    notif_title := ref_title || ' was not approved';
    notif_msg   := 'Your ' || ref_type || ' submission was reviewed and rejected.';
  end if;

  raise log '[notify_user_on_approval] inserting user_notification for owner_id=% title="%"', new.owner_id, notif_title;

  insert into public.user_notifications
    (recipient_id, reference_type, reference_id, title, message)
  values (
    new.owner_id,
    ref_type,
    new.id,
    notif_title,
    notif_msg
  );

  raise log '[notify_user_on_approval] insert ok';

  return new;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Attach triggers to events and locations
-- ─────────────────────────────────────────────────────────────────────────────
create trigger trg_event_approval_notify
  after update on events
  for each row execute function notify_user_on_approval();

create trigger trg_location_approval_notify
  after update on locations
  for each row execute function notify_user_on_approval();



-- Fix: "record new has no field event_name" on both INSERT and UPDATE triggers for locations.
--
-- Two triggers share the same bug:
--   notify_admins_on_submission  (AFTER INSERT  on events + locations)
--   notify_user_on_approval      (AFTER UPDATE  on events + locations)
--
-- Both directly access new.event_name, which only exists on the events table.
-- On a locations row (which uses the column `name`) PostgreSQL throws:
--   ERROR 42703: record "new" has no field "event_name"
--
-- Fix: replace direct field access with row_to_json(new) ->> 'field', which
-- returns NULL for missing columns instead of erroring.
--
-- Also creates user_notifications table + RLS + triggers if they don't exist yet
-- (handles the case where 20260626_user_notifications.sql was never applied).
--
-- Run this entire script in the Supabase SQL Editor to apply everything.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Ensure user_notifications table exists
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists user_notifications (
  id               uuid        primary key default gen_random_uuid(),
  recipient_id     uuid        not null references auth.users(id) on delete cascade,
  reference_type   text        not null check (reference_type in ('event', 'location')),
  reference_id     uuid        not null,
  title            text        not null,
  message          text        not null,
  created_at       timestamptz not null default now(),
  read_at          timestamptz
);

create index if not exists idx_user_notif_recipient_unread
  on user_notifications (recipient_id, created_at desc)
  where read_at is null;

alter table user_notifications enable row level security;

do $$ begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'user_notifications'
      and policyname = 'recipient reads own user notifications'
  ) then
    create policy "recipient reads own user notifications"
      on user_notifications for select
      using (auth.uid() = recipient_id);
  end if;
end $$;

do $$ begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'user_notifications'
      and policyname = 'recipient marks own user notification as read'
  ) then
    create policy "recipient marks own user notification as read"
      on user_notifications for update
      using  (auth.uid() = recipient_id)
      with check (auth.uid() = recipient_id);
  end if;
end $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Fixed notify_admins_on_submission (AFTER INSERT on events + locations)
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function notify_admins_on_submission()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  admin_row   record;
  ref_title   text;
  ref_type    text;
  notif_title text;
  notif_msg   text;
  new_json    json;
begin
  -- Skip drafts, rejections and cancellations — only notify on real submissions.
  if new.approval_status in ('draft', 'rejected', 'cancelled') then
    return new;
  end if;

  -- Use json extraction so missing columns (e.g. event_name on locations) return
  -- NULL instead of throwing "record new has no field event_name".
  new_json := row_to_json(new);

  ref_title := coalesce(
    nullif(new_json ->> 'event_name', ''),
    nullif(new_json ->> 'name',       ''),
    'Untitled'
  );

  ref_type := case tg_table_name
    when 'events'    then 'event'
    when 'locations' then 'location'
    else tg_table_name
  end;

  if new.approval_status = 'pending' then
    notif_title := 'New submission awaiting review';
    notif_msg   := ref_title || ' was submitted and needs approval.';
  else
    -- approved — CMS admin created it directly
    notif_title := 'New ' || ref_type || ' published';
    notif_msg   := ref_title || ' was added and is now live.';
  end if;

  for admin_row in
    select user_id from public.users where role = 'super_admin'
  loop
    insert into public.cms_notifications
      (recipient_id, reference_type, reference_id, title, message)
    values (
      admin_row.user_id,
      ref_type,
      new.id,
      notif_title,
      notif_msg
    );
  end loop;

  return new;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Fixed notify_user_on_approval (AFTER UPDATE on events + locations)
--    Triggered when a CMS admin publishes a draft location (draft → approved).
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function notify_user_on_approval()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  ref_title   text;
  ref_type    text;
  notif_title text;
  notif_msg   text;
  new_json    json;
begin
  -- Only act when approval_status actually changed to approved or rejected.
  if old.approval_status = new.approval_status then
    return new;
  end if;

  if new.approval_status not in ('approved', 'rejected') then
    return new;
  end if;

  -- Must have an owner to notify.
  if new.owner_id is null then
    return new;
  end if;

  -- Use json extraction so missing columns return NULL instead of erroring.
  new_json := row_to_json(new);

  ref_title := coalesce(
    nullif(new_json ->> 'event_name', ''),
    nullif(new_json ->> 'name',       ''),
    'Your submission'
  );

  ref_type := case tg_table_name
    when 'events'    then 'event'
    when 'locations' then 'location'
    else tg_table_name
  end;

  if new.approval_status = 'approved' then
    notif_title := ref_title || ' was approved!';
    notif_msg   := 'Your ' || ref_type || ' is now live and visible to users.';
  else
    notif_title := ref_title || ' was not approved';
    notif_msg   := 'Your ' || ref_type || ' submission was reviewed and rejected.';
  end if;

  insert into public.user_notifications
    (recipient_id, reference_type, reference_id, title, message)
  values (
    new.owner_id,
    ref_type,
    new.id,
    notif_title,
    notif_msg
  );

  return new;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Attach update trigger to events and locations (skip if already exists)
-- ─────────────────────────────────────────────────────────────────────────────
do $$ begin
  if not exists (
    select 1 from pg_trigger where tgname = 'trg_event_approval_notify'
  ) then
    create trigger trg_event_approval_notify
      after update on events
      for each row execute function notify_user_on_approval();
  end if;
end $$;

do $$ begin
  if not exists (
    select 1 from pg_trigger where tgname = 'trg_location_approval_notify'
  ) then
    create trigger trg_location_approval_notify
      after update on locations
      for each row execute function notify_user_on_approval();
  end if;
end $$;

-- Fix: guard pg_net call so a missing extension never rolls back the approval UPDATE.
-- If pg_net is not enabled, the approval is saved and the push is skipped (logged as warning).
-- Once pg_net is enabled via Dashboard → Database → Extensions, push notifications
-- will fire automatically without any further code change.

create or replace function notify_user_on_approval()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  ref_title   text;
  ref_type    text;
  notif_title text;
  notif_msg   text;
  new_json    json;
begin
  -- Only act when approval_status actually changed to approved or rejected.
  if old.approval_status = new.approval_status then
    return new;
  end if;

  if new.approval_status not in ('approved', 'rejected') then
    return new;
  end if;

  -- Must have an owner to notify.
  if new.owner_id is null then
    return new;
  end if;

  new_json := row_to_json(new);

  ref_title := coalesce(
    nullif(new_json ->> 'event_name', ''),
    nullif(new_json ->> 'name',       ''),
    'Your submission'
  );

  ref_type := case tg_table_name
    when 'events'    then 'event'
    when 'locations' then 'location'
    else tg_table_name
  end;

  if new.approval_status = 'approved' then
    notif_title := ref_title || ' was approved!';
    notif_msg   := 'Your ' || ref_type || ' is now live and visible to users.';
  else
    notif_title := ref_title || ' was not approved';
    notif_msg   := 'Your ' || ref_type || ' submission was reviewed and rejected.';
  end if;

  -- Insert in-app notification row (always runs).
  insert into public.user_notifications
    (recipient_id, reference_type, reference_id, title, message)
  values (
    new.owner_id,
    ref_type,
    new.id,
    notif_title,
    notif_msg
  );

  -- Fire push notification via pg_net (fire-and-forget).
  -- Wrapped in its own block so a missing pg_net extension never aborts the
  -- approval UPDATE — the in-app notification is already saved above.
  begin
    perform net.http_post(
      url     := 'https://xoqohyzwzbdxfyhwcbdd.supabase.co/functions/v1/send-push-notification',
      headers := jsonb_build_object(
        'Content-Type',  'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhvcW9oeXp3emJkeGZ5aHdjYmRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzNzQwNjMsImV4cCI6MjA2Mzk1MDA2M30.V2CIBQ9oVoaGzXWtIL_Bq0wp3P--gYb3fA-qLxqTke0'
      ),
      body    := jsonb_build_object(
        'recipient_id', new.owner_id,
        'title',        notif_title,
        'message',      notif_msg
      )
    );
  exception when others then
    raise warning '[notify_user_on_approval] pg_net call skipped: %', sqlerrm;
  end;

  return new;
end;
$$;

  SELECT tablename, policyname, cmd, qual
  FROM pg_policies
  WHERE tablename = 'user_fcm_tokens';
-- Migration: Fire push notification from approval trigger via pg_net
-- Date: 2026-06-30
-- Description: Extends notify_user_on_approval to call the send-push-notification
--              Edge Function (pg_net HTTP POST) immediately after inserting the
--              user_notification row.  pg_net is enabled by default on Supabase.
--
-- The anon key is safe to embed here — it is the same public key already shipped
-- in the Flutter client bundle.  The Edge Function uses its own SUPABASE_SERVICE_ROLE_KEY
-- environment variable internally, so no elevated secret is stored in SQL.

create or replace function notify_user_on_approval()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  ref_title   text;
  ref_type    text;
  notif_title text;
  notif_msg   text;
  new_json    json;
begin
  -- Only act when approval_status actually changed to approved or rejected.
  if old.approval_status = new.approval_status then
    return new;
  end if;

  if new.approval_status not in ('approved', 'rejected') then
    return new;
  end if;

  -- Must have an owner to notify.
  if new.owner_id is null then
    return new;
  end if;

  -- Use json extraction so missing columns (e.g. event_name on locations) return
  -- NULL instead of throwing "record new has no field event_name".
  new_json := row_to_json(new);

  ref_title := coalesce(
    nullif(new_json ->> 'event_name', ''),
    nullif(new_json ->> 'name',       ''),
    'Your submission'
  );

  ref_type := case tg_table_name
    when 'events'    then 'event'
    when 'locations' then 'location'
    else tg_table_name
  end;

  if new.approval_status = 'approved' then
    notif_title := ref_title || ' was approved!';
    notif_msg   := 'Your ' || ref_type || ' is now live and visible to users.';
  else
    notif_title := ref_title || ' was not approved';
    notif_msg   := 'Your ' || ref_type || ' submission was reviewed and rejected.';
  end if;

  -- Insert in-app notification row.
  insert into public.user_notifications
    (recipient_id, reference_type, reference_id, title, message)
  values (
    new.owner_id,
    ref_type,
    new.id,
    notif_title,
    notif_msg
  );

  -- Fire push notification via Edge Function (fire-and-forget via pg_net).
  perform net.http_post(
    url     := 'https://xoqohyzwzbdxfyhwcbdd.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhvcW9oeXp3emJkeGZ5aHdjYmRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzNzQwNjMsImV4cCI6MjA2Mzk1MDA2M30.V2CIBQ9oVoaGzXWtIL_Bq0wp3P--gYb3fA-qLxqTke0'
    ),
    body    := jsonb_build_object(
      'recipient_id', new.owner_id,
      'title',        notif_title,
      'message',      notif_msg
    )
  );

  return new;
end;
$$;

-- Recreate the triggers if they were dropped (idempotent).
do $$ begin
  if not exists (
    select 1 from pg_trigger where tgname = 'trg_event_approval_notify'
  ) then
    create trigger trg_event_approval_notify
      after update on events
      for each row execute function notify_user_on_approval();
  end if;
end $$;

do $$ begin
  if not exists (
    select 1 from pg_trigger where tgname = 'trg_location_approval_notify'
  ) then
    create trigger trg_location_approval_notify
      after update on locations
      for each row execute function notify_user_on_approval();
  end if;
end $$;
