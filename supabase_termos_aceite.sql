-- Registro de aceite de termos (LGPD / aptidão física)
-- Execute no SQL Editor do Supabase

create table if not exists public.termos_aceites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  nome text not null,
  email text,
  tipo text not null,
  ip text,
  user_agent text,
  created_at timestamptz not null default now()
);

create index if not exists idx_termos_aceites_user on public.termos_aceites(user_id);
create index if not exists idx_termos_aceites_tipo on public.termos_aceites(tipo);

alter table public.termos_aceites enable row level security;

drop policy if exists "Usuario registra proprio aceite" on public.termos_aceites;
create policy "Usuario registra proprio aceite" on public.termos_aceites
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "Admin le aceites" on public.termos_aceites;
create policy "Admin le aceites" on public.termos_aceites
  for select
  using (
    exists (
      select 1 from public.usuarios u
      where u.id = auth.uid() and u.tipo = 'admin'
    )
  );

select 'Tabela termos_aceites criada!' as status;
