-- Extends the existing approval-notification system (applied to Dev on
-- 2026-09-03 as notification_system.sql, never committed to this repo) to
-- the `prides` table, and formalizes it in version control.
--
-- Today, `notify_user_on_approval()` fires on UPDATE to `events` and
-- `locations` when approval_status flips to 'approved' or 'rejected', and
-- pushes an FCM notification to the submitting owner via the
-- send-push-notification Edge Function. Prides gained an approval workflow
-- later (2026-09-08) and were never wired into this trigger — a rejected
-- Pride submission currently notifies no one.
--
-- This migration is idempotent (create-or-replace + drop-if-exists) so it is
-- safe to re-run even though an equivalent function/triggers for
-- events/locations already exist live on Dev — re-applying it here just
-- keeps that logic (unchanged) in git and adds the missing `prides` case.
--
-- NOTE: the pg_net call below hardcodes the DEV project's function URL +
-- anon key (wsbacfyffzctiiqlnhkq.supabase.co), matching how the rest of this
-- migration set was written. Swap both to Production's values before ever
-- applying this to xoqohyzwzbdxfyhwcbdd.
--
-- Diagnostic logging was later added on top of this function in
-- 20260915120000_notify_user_on_approval_logging.sql — keep this file as the
-- original applied version; edit the newer migration instead.

create extension if not exists pg_net with schema extensions;

-- ---------------------------------------------------------------------------
-- rejection_reason — captured by the CMS reject dialog, surfaced in the
-- notification message built below. `events`/`locations` likely already
-- have this from the 2026-09-03 migration; re-declared here defensively
-- since that migration was never committed. `prides` is new.
-- ---------------------------------------------------------------------------

alter table public.events add column if not exists rejection_reason text;
alter table public.locations add column if not exists rejection_reason text;
alter table public.prides add column if not exists rejection_reason text;

-- ---------------------------------------------------------------------------
-- notify_user_on_approval — fires on UPDATE to events/locations/prides when
-- approval_status changes to approved/rejected. Notifies the submitting
-- owner via push (through send-push-notification). Rejection messages
-- include the admin-provided rejection_reason.
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
    when 'prides'    then 'pride'
    else tg_table_name
  end;

  if new.approval_status = 'approved' then
    notif_title := ref_title || ' was approved!';
    notif_msg   := 'Your ' || ref_type || ' is now live and visible to users.';
  else
    notif_title := ref_title || ' was not approved';
    notif_msg   := 'Your ' || ref_type || ' submission was rejected: '
                   || coalesce(nullif(new.rejection_reason, ''), 'No reason provided.');
  end if;

  -- Fire push notification via pg_net (fire-and-forget). Wrapped in its own
  -- block so a missing pg_net extension, or the Edge Function being
  -- unreachable, never aborts the approval UPDATE itself.
  begin
    perform net.http_post(
      url     := 'https://wsbacfyffzctiiqlnhkq.supabase.co/functions/v1/send-push-notification',
      headers := jsonb_build_object(
        'Content-Type',  'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndzYmFjZnlmZnpjdGlpcWxuaGtxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYwMjY0MzUsImV4cCI6MjA2MTYwMjQzNX0.9kBm-fI2QEnFL0YuolH8HiA2-umx4fnd9N0R5AxIT-g'
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
$function$;

drop trigger if exists trg_event_approval_notify on public.events;
create trigger trg_event_approval_notify
  after update on public.events
  for each row execute function public.notify_user_on_approval();

drop trigger if exists trg_location_approval_notify on public.locations;
create trigger trg_location_approval_notify
  after update on public.locations
  for each row execute function public.notify_user_on_approval();

drop trigger if exists trg_pride_approval_notify on public.prides;
create trigger trg_pride_approval_notify
  after update on public.prides
  for each row execute function public.notify_user_on_approval();
