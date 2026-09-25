-- Adds diagnostic `raise notice` logging to notify_user_on_approval() so a
-- rejection/approval can be traced end-to-end in Postgres Logs: whether the
-- trigger fired at all, why it may have skipped, and the pg_net request id
-- once the push to send-push-notification is queued.
--
-- 20260914120000_pride_rejection_notifications.sql is already applied on
-- Dev (its timestamp is recorded in supabase_migrations.schema_migrations),
-- so editing that file in place would not be re-run by `supabase db push`.
-- This migration re-applies the same create-or-replace function body (logic
-- unchanged) plus the new logging, under a fresh timestamp so it actually
-- deploys.

create or replace function public.notify_user_on_approval()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  ref_title      text;
  ref_type       text;
  notif_title    text;
  notif_msg      text;
  new_json       json;
  net_request_id bigint;
begin
  raise notice '[notify_user_on_approval] trigger fired: table=% id=% old_status=% new_status=% owner_id=%',
    tg_table_name, new.id, old.approval_status, new.approval_status, new.owner_id;

  -- Only act when approval_status actually changed to approved or rejected.
  if old.approval_status = new.approval_status then
    raise notice '[notify_user_on_approval] skipped: approval_status unchanged';
    return new;
  end if;

  if new.approval_status not in ('approved', 'rejected') then
    raise notice '[notify_user_on_approval] skipped: new_status=% is not approved/rejected', new.approval_status;
    return new;
  end if;

  -- Must have an owner to notify.
  if new.owner_id is null then
    raise notice '[notify_user_on_approval] skipped: owner_id is null, nothing to notify';
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
    select net.http_post(
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
    ) into net_request_id;

    raise notice '[notify_user_on_approval] pg_net request queued: request_id=% owner_id=% status=% title=%',
      net_request_id, new.owner_id, new.approval_status, notif_title;
  exception when others then
    raise warning '[notify_user_on_approval] pg_net call skipped: %', sqlerrm;
  end;

  return new;
end;
$function$;
