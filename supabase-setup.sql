-- Workout and Calorie Tracker: database setup for Supabase.
-- Paste all of this into Supabase's SQL Editor and press Run, once.

-- 1. Each person's private log. Only the owner can read or change it.
create table if not exists public.logs (
  user_id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.logs enable row level security;

create policy "Read own log" on public.logs
  for select using (auth.uid() = user_id);
create policy "Create own log" on public.logs
  for insert with check (auth.uid() = user_id);
create policy "Update own log" on public.logs
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Delete own log" on public.logs
  for delete using (auth.uid() = user_id);

-- 2. Co-op summaries. You see your own, plus those of people who joined your invite code.
create table if not exists public.coop (
  user_id uuid primary key references auth.users(id) on delete cascade,
  team text,
  summary jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.coop enable row level security;

-- Looks up the signed-in person's invite code without the policy checking itself in a loop.
create or replace function public.my_team() returns text
language sql stable security definer set search_path = public as $$
  select team from public.coop where user_id = auth.uid()
$$;

create policy "Read own and team summaries" on public.coop
  for select using (user_id = auth.uid() or (team is not null and team = public.my_team()));
create policy "Create own summary" on public.coop
  for insert with check (auth.uid() = user_id);
create policy "Update own summary" on public.coop
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Delete own summary" on public.coop
  for delete using (auth.uid() = user_id);
