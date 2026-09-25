-- RLS policies for the Prides feature:
--   lib/shared/services/pride_service.dart
--   lib/features/create_pride/  (mobile create/edit/draft flows)
--   lib/app_cms/features/prides/ (CMS admin management)
--
-- prides already exists on the linked Dev project (configured directly via
-- SQL editor, never version-controlled) — this migration only adds/repairs
-- its RLS policies (idempotent: safe to run even if a same-named policy
-- already exists). It does not touch table shape.
--
-- Why: pride_service.dart's updatePride()/deletePride() have NO
-- client-side ownership check at all — they trust RLS entirely to stop one
-- user from editing/deleting another user's pride. Since this table's RLS
-- was never tracked in-repo, that couldn't be verified as actually
-- enforced live. This migration makes it explicit: any authenticated user,
-- of any role, can create and edit their OWN pride in mobile
-- (owner_id = auth.uid()) — this is NOT restricted to a particular role;
-- admins (role in the `users` table) additionally retain full CMS
-- management access to every pride.
--
-- All owner/user-id comparisons are cast to text on both sides
-- (owner_id::text = auth.uid()::text) rather than compared directly —
-- this project's own bulk_upload_prides_drafts policies
-- (admin_user_id = (auth.uid())::text) show id/owner columns aren't
-- consistently typed as uuid across tables here, and a raw type mismatch
-- in a `using`/`with check` clause fails closed for EVERY user, not just
-- the ones it's meant to restrict. Casting to text is safe and correct
-- regardless of whether the underlying column is uuid or text.
--
-- Policies are permissive and combine via OR with any existing policy of a
-- different name, so this can only ever grant additional access — it can't
-- accidentally revoke something already working (e.g. CMS admin access),
-- even though the admin bypass below is included explicitly so this
-- migration is correct on its own regardless of what else may exist.

alter table public.prides enable row level security;

-- Anyone (including anonymous/public) can see published prides; an owner
-- can also see their own drafts; admins can see everything.
drop policy if exists "public can view published prides" on public.prides;
create policy "public can view published prides"
  on public.prides for select
  using (
    is_draft = false
    or owner_id::text = auth.uid()::text
    or exists (
      select 1 from public.users u
      where u.user_id::text = auth.uid()::text
        and u.role in ('super_admin', 'admin')
    )
  );

-- Any authenticated user, any role, may create a pride owned by
-- themselves; admins may additionally create on behalf of anyone (e.g.
-- assigning ownership during CMS setup).
drop policy if exists "owner or admin can insert prides" on public.prides;
create policy "owner or admin can insert prides"
  on public.prides for insert
  to authenticated
  with check (
    owner_id::text = auth.uid()::text
    or exists (
      select 1 from public.users u
      where u.user_id::text = auth.uid()::text
        and u.role in ('super_admin', 'admin')
    )
  );

-- Any authenticated user, any role, may update/delete their OWN pride;
-- admins may manage any pride.
drop policy if exists "owner or admin can update prides" on public.prides;
create policy "owner or admin can update prides"
  on public.prides for update
  to authenticated
  using (
    owner_id::text = auth.uid()::text
    or exists (
      select 1 from public.users u
      where u.user_id::text = auth.uid()::text
        and u.role in ('super_admin', 'admin')
    )
  )
  with check (
    owner_id::text = auth.uid()::text
    or exists (
      select 1 from public.users u
      where u.user_id::text = auth.uid()::text
        and u.role in ('super_admin', 'admin')
    )
  );

drop policy if exists "owner or admin can delete prides" on public.prides;
create policy "owner or admin can delete prides"
  on public.prides for delete
  to authenticated
  using (
    owner_id::text = auth.uid()::text
    or exists (
      select 1 from public.users u
      where u.user_id::text = auth.uid()::text
        and u.role in ('super_admin', 'admin')
    )
  );
