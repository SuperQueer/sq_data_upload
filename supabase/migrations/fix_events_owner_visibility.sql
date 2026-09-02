-- ============================================================
-- Fix: event creators cannot see their own pending/rejected
-- events anywhere in the app (mobile Prides tab, "my events", etc.)
--
-- The "filter_events_by_status" policy introduced in
-- sprint_1_production.sql only allows regular (non-admin) users
-- to see approval_status = 'approved' rows. It has no exception
-- for the event's own owner, so a newly created event (which
-- defaults to 'pending' for non-super-admin creators) is silently
-- hidden from the creator by RLS until an admin approves it.
-- ============================================================
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
  OR
  -- Owners can always see their own events, regardless of status
  owner_id = auth.uid()
);