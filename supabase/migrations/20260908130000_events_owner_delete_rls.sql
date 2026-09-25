-- RLS: allow the owner of an event to hard-delete their own row, in
-- addition to the existing admin/super_admin delete policy.
--
-- Why: "admins_can_delete_events" (sprint_1_production.sql) only ever
-- granted DELETE to admin/super_admin roles — there was a deliberate
-- soft-delete path for owners instead (the cancel_event() RPC, which sets
-- approval_status = 'cancelled'). Product decision on 2026-09-08: a
-- regular user tapping "Delete" on their own event in My Events must
-- actually remove the row from the DB, not just change its status. This
-- policy grants that.
--
-- Mirrors "owner can delete own location"
-- (20260908120000_locations_owner_delete_rls.sql) — uncast owner_id =
-- auth.uid(), consistent with this table's other owner-scoped policies
-- (e.g. "allow_update_events" in deployment_sprint1.sql uses
-- auth.uid() = owner_id uncast; events.owner_id is typed uuid).
--
-- Policy is permissive and combines via OR with the existing admin-only
-- delete policy (different name), so it only ever grants additional
-- access — it can't revoke the admin delete path already working.

drop policy if exists "owner can delete own event" on events;
create policy "owner can delete own event"
on events for delete
to authenticated
using (owner_id = auth.uid());
