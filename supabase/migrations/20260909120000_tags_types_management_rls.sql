-- Allows super_admins to manage the Tags & Types master lists (Manage Tags &
-- Types CMS screen) instead of them being edited only via direct DB access.
--
-- event_types/event_tags and location_types/location_tags already have
-- "public read" SELECT policies (sprint_1_production.sql, 20260907120000_
-- location_types_tags.sql) but no INSERT/UPDATE/DELETE policies at all, so
-- writes have only ever been possible via the Supabase SQL editor. This adds
-- write access for super_admin only, mirroring the super_admin role check
-- used throughout the schema (e.g. sprint_1_production.sql, prides_rls.sql).

CREATE POLICY "super_admins_can_insert_event_types"
  ON event_types FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role = 'super_admin')
  );

CREATE POLICY "super_admins_can_update_event_types"
  ON event_types FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role = 'super_admin')
  );

CREATE POLICY "super_admins_can_delete_event_types"
  ON event_types FOR DELETE
  USING (
    EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role = 'super_admin')
  );

CREATE POLICY "super_admins_can_insert_event_tags"
  ON event_tags FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role = 'super_admin')
  );

CREATE POLICY "super_admins_can_update_event_tags"
  ON event_tags FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role = 'super_admin')
  );

CREATE POLICY "super_admins_can_delete_event_tags"
  ON event_tags FOR DELETE
  USING (
    EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role = 'super_admin')
  );

CREATE POLICY "super_admins_can_insert_location_types"
  ON location_types FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role = 'super_admin')
  );

CREATE POLICY "super_admins_can_update_location_types"
  ON location_types FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role = 'super_admin')
  );

CREATE POLICY "super_admins_can_delete_location_types"
  ON location_types FOR DELETE
  USING (
    EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role = 'super_admin')
  );

CREATE POLICY "super_admins_can_insert_location_tags"
  ON location_tags FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role = 'super_admin')
  );

CREATE POLICY "super_admins_can_update_location_tags"
  ON location_tags FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role = 'super_admin')
  );

CREATE POLICY "super_admins_can_delete_location_tags"
  ON location_tags FOR DELETE
  USING (
    EXISTS (SELECT 1 FROM users WHERE user_id = auth.uid() AND role = 'super_admin')
  );
