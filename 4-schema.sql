-- GeneVision Hub: database schema with row level security.
-- Run this whole file once in Supabase: SQL Editor > New query > paste > Run.

create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text
);
create table if not exists public.blocked_users (
  user_id uuid primary key,
  reason text
);
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 3 and 200),
  author_name text not null check (char_length(author_name) <= 120),
  author_role text not null default '' check (char_length(author_role) <= 160),
  track text not null,
  abstract text not null check (char_length(abstract) <= 5000),
  methods text not null default '' check (char_length(methods) <= 8000),
  tools jsonb not null default '[]',
  findings jsonb not null default '[]',
  metrics jsonb not null default '[]',
  protocol_notes text not null default '' check (char_length(protocol_notes) <= 5000),
  simulation_ids jsonb not null default '[]',
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  target_type text not null check (target_type in ('project','simulation')),
  target_id text not null,
  category text not null check (category in ('question','methodological','improvement')),
  body text not null check (char_length(body) between 3 and 2000),
  author_name text not null check (char_length(author_name) <= 120),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);

create or replace function public.is_admin() returns boolean
language sql security definer set search_path = public stable as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;
create or replace function public.is_blocked() returns boolean
language sql security definer set search_path = public stable as $$
  select exists (select 1 from public.blocked_users where user_id = auth.uid());
$$;
grant execute on function public.is_admin() to anon, authenticated;
grant execute on function public.is_blocked() to anon, authenticated;

-- API access (needed when the project does not grant it automatically)
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.projects, public.reviews to anon, authenticated;
grant select on public.admins to authenticated;
grant select, insert, update, delete on public.blocked_users to authenticated;

alter table public.admins enable row level security;
alter table public.blocked_users enable row level security;
alter table public.projects enable row level security;
alter table public.reviews enable row level security;

drop policy if exists admins_read on public.admins;
create policy admins_read on public.admins for select using (user_id = auth.uid());

drop policy if exists blocked_admin_all on public.blocked_users;
create policy blocked_admin_all on public.blocked_users for all using (public.is_admin()) with check (public.is_admin());

-- Projects: public sees approved only; owner sees own; admin sees all.
drop policy if exists projects_select on public.projects;
create policy projects_select on public.projects for select
  using (status = 'approved' or owner_id = auth.uid() or public.is_admin());
drop policy if exists projects_insert on public.projects;
create policy projects_insert on public.projects for insert to authenticated
  with check (owner_id = auth.uid() and status = 'pending' and not public.is_blocked());
drop policy if exists projects_update_owner on public.projects;
create policy projects_update_owner on public.projects for update to authenticated
  using (owner_id = auth.uid() and not public.is_blocked())
  with check (owner_id = auth.uid() and status = 'pending');
drop policy if exists projects_update_admin on public.projects;
create policy projects_update_admin on public.projects for update to authenticated
  using (public.is_admin()) with check (public.is_admin());
drop policy if exists projects_delete on public.projects;
create policy projects_delete on public.projects for delete to authenticated
  using (owner_id = auth.uid() or public.is_admin());

-- Reviews (comments): same rules.
drop policy if exists reviews_select on public.reviews;
create policy reviews_select on public.reviews for select
  using (status = 'approved' or owner_id = auth.uid() or public.is_admin());
drop policy if exists reviews_insert on public.reviews;
create policy reviews_insert on public.reviews for insert to authenticated
  with check (owner_id = auth.uid() and status = 'pending' and not public.is_blocked());
drop policy if exists reviews_update_admin on public.reviews;
create policy reviews_update_admin on public.reviews for update to authenticated
  using (public.is_admin()) with check (public.is_admin());
drop policy if exists reviews_delete on public.reviews;
create policy reviews_delete on public.reviews for delete to authenticated
  using (owner_id = auth.uid() or public.is_admin());

-- Make YOURSELF the owner/admin: sign up on the site first, then run (change the email):
--   insert into public.admins (user_id, email)
--   select id, email from auth.users where email = 'YOUR-EMAIL@example.com';
