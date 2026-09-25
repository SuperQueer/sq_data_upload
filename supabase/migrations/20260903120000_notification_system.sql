-- Notification system: in-app notifications for CMS admins (on new submission)
-- and end users (on approval/rejection), plus FCM push delivery via the
-- send-push-notification Edge Function. Rejections also carry the admin's
-- rejection_reason through to the user-facing notification message.
--
-- Adapted from the notification system already live on the Dev project
-- (configured directly via SQL editor, never version-controlled elsewhere).
--
-- The Edge Function base URL and anon key are read from Supabase Vault
-- (see get_push_notification_config() below) rather than hardcoded here, so
-- no project credentials are committed to this file or its git history.
-- Before the push-notification triggers can call the Edge Function, seed
-- both secrets once per environment via the SQL editor (or `supabase secrets`
-- workflow), e.g. for Dev:
--   select vault.create_secret('https://wsbacfyffzctiiqlnhkq.supabase.co', 'edge_function_base_url');
--   select vault.create_secret('<dev-anon-key>', 'edge_function_anon_key');
-- and the corresponding Production values (xoqohyzwzbdxfyhwcbdd) when applying
-- this migration there. If the secrets are missing, the triggers still save
-- the in-app notification and simply skip the push call (see warning logs).

create extension if not exists pg_net with schema extensions;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.cms_notifications (
  id             uuid primary key default gen_random_uuid(),
  recipient_id   uuid not null references auth.users(id) on delete cascade,
  reference_type text not null check (reference_type in ('event', 'location')),
  reference_id   uuid not null,
  title          text not null,
  message        text not null,
  created_at     timestamptz not null default now(),
  read_at        timestamptz
);

create index if not exists idx_cms_notif_recipient_unread
  on public.cms_notifications (recipient_id, created_at desc)
  where (read_at is null);

create table if not exists public.user_notifications (
  id             uuid primary key default gen_random_uuid(),
  recipient_id   uuid not null references auth.users(id) on delete cascade,
  reference_type text not null check (reference_type in ('event', 'location')),
  reference_id   uuid not null,
  title          text not null,
  message        text not null,
  created_at     timestamptz not null default now(),
  read_at        timestamptz
);

create index if not exists idx_user_notif_recipient_unread
  on public.user_notifications (recipient_id, created_at desc)
  where (read_at is null);

create table if not exists public.user_fcm_tokens (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  token      text not null,
  platform   text not null check (platform in ('ios', 'android')),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- rejection_reason — captured by the CMS reject dialog, surfaced in the
-- user_notifications message built by notify_user_on_approval() below.
-- ---------------------------------------------------------------------------

alter table public.events add column if not exists rejection_reason text;
alter table public.locations add column if not exists rejection_reason text;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table public.cms_notifications enable row level security;
alter table public.user_notifications enable row level security;
alter table public.user_fcm_tokens enable row level security;

drop policy if exists "recipient reads own notifications" on public.cms_notifications;
create policy "recipient reads own notifications"
  on public.cms_notifications for select
  using (auth.uid() = recipient_id);

drop policy if exists "recipient marks own as read" on public.cms_notifications;
create policy "recipient marks own as read"
  on public.cms_notifications for update
  using (auth.uid() = recipient_id)
  with check (auth.uid() = recipient_id);

drop policy if exists "recipient deletes own notifications" on public.cms_notifications;
create policy "recipient deletes own notifications"
  on public.cms_notifications for delete
  using (auth.uid() = recipient_id);

drop policy if exists "recipient reads own user notifications" on public.user_notifications;
create policy "recipient reads own user notifications"
  on public.user_notifications for select
  using (auth.uid() = recipient_id);

drop policy if exists "recipient marks own user notification as read" on public.user_notifications;
create policy "recipient marks own user notification as read"
  on public.user_notifications for update
  using (auth.uid() = recipient_id)
  with check (auth.uid() = recipient_id);

drop policy if exists "user manages own fcm token" on public.user_fcm_tokens;
create policy "user manages own fcm token"
  on public.user_fcm_tokens for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "service role reads fcm tokens" on public.user_fcm_tokens;
create policy "service role reads fcm tokens"
  on public.user_fcm_tokens for select
  using (auth.role() = 'service_role');

-- ---------------------------------------------------------------------------
-- get_push_notification_config — reads the Edge Function base URL and anon
-- key from Supabase Vault. Both notification triggers call this instead of
-- hardcoding credentials. Returns nulls (rather than raising) when a secret
-- hasn't been seeded yet, so callers can skip the push call gracefully.
-- ---------------------------------------------------------------------------

create or replace function public.get_push_notification_config()
returns table(base_url text, anon_key text)
language sql
security definer
set search_path to 'public'
as $function$
  select
    (select decrypted_secret from vault.decrypted_secrets where name = 'edge_function_base_url'),
    (select decrypted_secret from vault.decrypted_secrets where name = 'edge_function_anon_key');
$function$;

-- ---------------------------------------------------------------------------
-- notify_admins_on_submission — fires on INSERT into events/locations.
-- Notifies every super_admin in-app (cms_notifications) and via push.
-- ---------------------------------------------------------------------------

create or replace function public.notify_admins_on_submission()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  admin_row   record;
  ref_title   text;
  ref_type    text;
  notif_title text;
  notif_msg   text;
  new_json    json;
  v_base_url  text;
  v_anon_key  text;
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

  select base_url, anon_key into v_base_url, v_anon_key
  from public.get_push_notification_config();

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

    -- Fire push notification via pg_net (fire-and-forget) per admin.
    -- Wrapped in its own block so a missing pg_net extension, or any single
    -- admin's push failing, never aborts the submission INSERT — the in-app
    -- notification is already saved above. Skipped entirely if the Vault
    -- secrets haven't been seeded for this environment yet.
    if v_base_url is null or v_anon_key is null then
      raise warning '[notify_admins_on_submission] push notification config missing from vault, skipping';
    else
      begin
        perform net.http_post(
          url     := v_base_url || '/functions/v1/send-push-notification',
          headers := jsonb_build_object(
            'Content-Type',  'application/json',
            'Authorization', 'Bearer ' || v_anon_key
          ),
          body    := jsonb_build_object(
            'recipient_id', admin_row.user_id,
            'title',        notif_title,
            'message',      notif_msg
          )
        );
      exception when others then
        raise warning '[notify_admins_on_submission] pg_net call skipped: %', sqlerrm;
      end;
    end if;
  end loop;

  return new;
end;
$function$;

drop trigger if exists trg_event_submission on public.events;
create trigger trg_event_submission
  after insert on public.events
  for each row execute function public.notify_admins_on_submission();

drop trigger if exists trg_location_submission on public.locations;
create trigger trg_location_submission
  after insert on public.locations
  for each row execute function public.notify_admins_on_submission();

-- ---------------------------------------------------------------------------
-- notify_user_on_approval — fires on UPDATE to events/locations when
-- approval_status changes to approved/rejected. Notifies the submitting
-- user in-app (user_notifications) and via push. Rejection messages include
-- the admin-provided rejection_reason.
-- ---------------------------------------------------------------------------

create or replace function public.notify_user_on_approval()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  ref_title   text;
  ref_type    text;
  notif_title text;
  notif_msg   text;
  new_json    json;
  v_base_url  text;
  v_anon_key  text;
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
    notif_msg   := 'Your ' || ref_type || ' submission was rejected: '
                   || coalesce(nullif(new.rejection_reason, ''), 'No reason provided.');

    raise log '[notify_user_on_approval] rejection notification triggered for % % (id=%) owner=% reason=%',
      ref_type, ref_title, new.id, new.owner_id,
      coalesce(nullif(new.rejection_reason, ''), 'No reason provided.');
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

  if new.approval_status = 'rejected' then
    raise log '[notify_user_on_approval] rejection notification saved to user_notifications for owner=% (% id=%)',
      new.owner_id, ref_type, new.id;
  end if;

  -- Fire push notification via pg_net (fire-and-forget).
  -- Wrapped in its own block so a missing pg_net extension never aborts the
  -- approval UPDATE — the in-app notification is already saved above.
  -- Skipped entirely if the Vault secrets haven't been seeded for this
  -- environment yet.
  select base_url, anon_key into v_base_url, v_anon_key
  from public.get_push_notification_config();

  if v_base_url is null or v_anon_key is null then
    raise warning '[notify_user_on_approval] push notification config missing from vault, skipping';
  else
    begin
      perform net.http_post(
        url     := v_base_url || '/functions/v1/send-push-notification',
        headers := jsonb_build_object(
          'Content-Type',  'application/json',
          'Authorization', 'Bearer ' || v_anon_key
        ),
        body    := jsonb_build_object(
          'recipient_id', new.owner_id,
          'title',        notif_title,
          'message',      notif_msg
        )
      );

      if new.approval_status = 'rejected' then
        raise log '[notify_user_on_approval] rejection push notification sent to owner=% (% id=%)',
          new.owner_id, ref_type, new.id;
      end if;
    exception when others then
      raise warning '[notify_user_on_approval] pg_net call skipped: %', sqlerrm;
    end;
  end if;

  return new;
end;
$function$;

drop trigger if exists trg_event_approval_notify on public.events;
create trigger trg_event_approval_notify
  after update on public.events
  for each row execute function public.notify_user_on_approval();

drop trigger if exists trg_location_approval_notify on public.locations;
create trigger trg_location_approval_notify
  after update on public.locations
  for each row execute function public.notify_user_on_approval();
