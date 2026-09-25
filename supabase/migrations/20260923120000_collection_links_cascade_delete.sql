-- Deleting an event/location that still has bookmark rows in
-- collection_event_links / collection_location_links throws a foreign key
-- violation (23503), e.g.:
--   "update or delete on table "events" violates foreign key constraint
--    "collection_event_links_event_id_fkey""
--
-- The Dart code (event_service.dart / locations_service.dart) already tries
-- to clear these link rows before deleting the parent row, but RLS on the
-- link tables only lets a user delete rows for collections they own — so
-- other users' bookmarks of the same event/location survive and the parent
-- delete still fails.
--
-- Making these FKs ON DELETE CASCADE fixes this at the DB level regardless
-- of who owns the link row. Idempotent (only touches FKs that aren't
-- already CASCADE), so it's safe to re-run.

do $$
declare
  fk record;
  target_table text;
begin
  for fk in
    select tc.constraint_name, tc.table_name, kcu.column_name
    from information_schema.table_constraints tc
    join information_schema.key_column_usage kcu
      on tc.constraint_name = kcu.constraint_name and tc.table_schema = kcu.table_schema
    join information_schema.referential_constraints rc
      on tc.constraint_name = rc.constraint_name and tc.table_schema = rc.constraint_schema
    where tc.constraint_type = 'FOREIGN KEY'
      and tc.table_schema = 'public'
      and tc.table_name in ('collection_event_links', 'collection_location_links')
      and kcu.column_name in ('event_id', 'location_id')
      and rc.delete_rule <> 'CASCADE'
  loop
    target_table := case fk.column_name
      when 'event_id' then 'events'
      when 'location_id' then 'locations'
    end;

    execute format('alter table public.%I drop constraint %I', fk.table_name, fk.constraint_name);
    execute format(
      'alter table public.%I add constraint %I foreign key (%I) references public.%I(id) on delete cascade',
      fk.table_name,
      fk.constraint_name,
      fk.column_name,
      target_table
    );
  end loop;
end $$;
