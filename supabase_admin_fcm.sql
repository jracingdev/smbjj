-- ============================================================
-- CT SM BJJ — Tokens FCM dos admins + helpers de push
-- Execute no SQL Editor do Supabase (após supabase_setup.sql)
-- ============================================================

create table if not exists public.admin_fcm_tokens (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references public.usuarios(id) on delete cascade,
  token text not null,
  platform text default 'android',
  updated_at timestamptz default now(),
  constraint admin_fcm_tokens_user_token_unique unique (user_id, token)
);

create index if not exists admin_fcm_tokens_user_id_idx
  on public.admin_fcm_tokens (user_id);

create index if not exists admin_fcm_tokens_updated_at_idx
  on public.admin_fcm_tokens (updated_at desc);

alter table public.admin_fcm_tokens enable row level security;

drop policy if exists "Admin gerencia próprio token" on public.admin_fcm_tokens;
drop policy if exists "Admin lê próprios tokens" on public.admin_fcm_tokens;
drop policy if exists "Admin insere próprio token" on public.admin_fcm_tokens;
drop policy if exists "Admin atualiza próprio token" on public.admin_fcm_tokens;
drop policy if exists "Admin remove próprio token" on public.admin_fcm_tokens;

-- Só o próprio admin autenticado gerencia o token dele.
-- Edge Function usa service role (bypassa RLS) para ler todos e enviar FCM.
create policy "Admin lê próprios tokens" on public.admin_fcm_tokens
  for select using (auth.uid() = user_id and public.is_admin());

create policy "Admin insere próprio token" on public.admin_fcm_tokens
  for insert with check (auth.uid() = user_id and public.is_admin());

create policy "Admin atualiza próprio token" on public.admin_fcm_tokens
  for update using (auth.uid() = user_id and public.is_admin())
  with check (auth.uid() = user_id and public.is_admin());

create policy "Admin remove próprio token" on public.admin_fcm_tokens
  for delete using (auth.uid() = user_id and public.is_admin());

-- View auxiliar (service role / SQL Editor): tokens de quem ainda é admin
create or replace view public.admin_fcm_tokens_ativos as
select t.*
from public.admin_fcm_tokens t
join public.usuarios u on u.id = t.user_id
where u.role = 'admin';

select 'admin_fcm_tokens OK — configure Database Webhooks + Edge Function notify-admin' as status;
