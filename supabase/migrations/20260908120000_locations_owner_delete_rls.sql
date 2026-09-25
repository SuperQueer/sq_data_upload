-- RLS: allow the owner of a location (business or resource) to delete their
-- own row, in addition to the existing admin/super_admin delete policies.
--
-- Why: lib/shared/services/locations_service.dart's deleteLocation() scopes
-- its DELETE by owner_id, but `locations` has only ever had DELETE policies
-- for the admin/super_admin roles — see "admins_can_delete_locations"
-- (sprint_1_production.sql) and "super_admins_can_delete_locations"
-- (deployment_sprint1.sql). No owner-based DELETE policy ever existed.
-- Supabase does not throw on a blocked DELETE, it just returns [] affected
-- rows, so an owner deleting their own business/resource from the mobile
-- app (My Business / My Resources, and the pre-existing draft-delete flow
-- in location_drafts_screen.dart) silently did nothing.
--
-- This mirrors the existing "owner can update own location" UPDATE policy
-- (uncast owner_id = auth.uid(), consistent with this table's other
-- policies — locations.owner_id is typed uuid, unlike prides.owner_id which
-- needed a ::text cast elsewhere).
--
-- Policy is permissive and combines via OR with the existing admin
-- policies (different names), so it only ever grants additional access —
-- it can't revoke the admin delete paths already working.

drop policy if exists "owner can delete own location" on locations;
create policy "owner can delete own location"
on locations for delete
to authenticated
using (owner_id = auth.uid());
