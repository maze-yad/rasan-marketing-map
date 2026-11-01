-- Rasan Marketing Map: shared database setup (Supabase).
-- Paste this whole file into Supabase > SQL Editor > New query, then click Run. Safe to run more than once.

-- 1. The plan: one row per section (its branches are stored inside it), plus the budget settings.
create table if not exists public.layers (
  id         text primary key,
  ord        integer not null default 0,
  name       text not null default 'Untitled layer',
  color      text not null default 'slate',
  branches   jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.settings (
  id         text primary key,
  annual     numeric not null default 0,
  currency   text not null default 'USD',
  updated_at timestamptz not null default now()
);

-- 2. History: before a row is changed or deleted, its previous version is copied here.
--    Visitors to the site cannot read or change this table; only the project owner can, from the dashboard.
create table if not exists public.history (
  hid        bigint generated always as identity primary key,
  tbl        text not null,
  op         text not null,
  row_id     text not null,
  old_row    jsonb,
  changed_at timestamptz not null default now()
);
create index if not exists history_row_idx on public.history (row_id, changed_at desc);

create or replace function public.keep_history() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.history (tbl, op, row_id, old_row) values (tg_table_name, tg_op, old.id, to_jsonb(old));
  -- keep the history table small: drop versions older than 180 days now and then
  if random() < 0.01 then
    delete from public.history where changed_at < now() - interval '180 days';
  end if;
  if tg_op = 'DELETE' then return old; end if;
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists layers_history on public.layers;
create trigger layers_history before update or delete on public.layers
  for each row execute function public.keep_history();
drop trigger if exists settings_history on public.settings;
create trigger settings_history before update or delete on public.settings
  for each row execute function public.keep_history();

-- 3. Access: anyone with the link can read and edit the plan (no sign-in).
alter table public.layers   enable row level security;
alter table public.settings enable row level security;
alter table public.history  enable row level security;   -- no policies: closed to visitors

drop policy if exists "read layers"   on public.layers;
drop policy if exists "add layers"    on public.layers;
drop policy if exists "edit layers"   on public.layers;
drop policy if exists "delete layers" on public.layers;
create policy "read layers"   on public.layers for select to anon, authenticated using (true);
create policy "add layers"    on public.layers for insert to anon, authenticated with check (true);
create policy "edit layers"   on public.layers for update to anon, authenticated using (true) with check (true);
create policy "delete layers" on public.layers for delete to anon, authenticated using (true);

drop policy if exists "read settings" on public.settings;
drop policy if exists "add settings"  on public.settings;
drop policy if exists "edit settings" on public.settings;
create policy "read settings" on public.settings for select to anon, authenticated using (true);
create policy "add settings"  on public.settings for insert to anon, authenticated with check ((id = 'plan'));
create policy "edit settings" on public.settings for update to anon, authenticated using (true) with check ((id = 'plan'));

grant select, insert, update, delete on public.layers   to anon, authenticated;
grant select, insert, update         on public.settings to anon, authenticated;
revoke all on public.history from anon, authenticated;

-- 4. Live updates: tell open pages when the plan changes.
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'layers') then
    alter publication supabase_realtime add table public.layers;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'settings') then
    alter publication supabase_realtime add table public.settings;
  end if;
end $$;

select 'Rasan Marketing Map database is ready' as status;
