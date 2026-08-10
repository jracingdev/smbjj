-- ============================================================
-- CT SM BJJ — Histórico de graduações
-- Execute no SQL Editor do Supabase (projeto já com is_admin()).
--
-- Visibilidade: qualquer usuário autenticado lê.
-- Gestão: somente admin (INSERT / UPDATE / DELETE).
-- ============================================================

create table if not exists public.graduacoes (
  id uuid default gen_random_uuid() primary key,
  aluno_id uuid not null references public.alunos(id) on delete cascade,
  aluno_nome text not null,
  data_graduacao text not null,
  faixa text not null,
  grau integer not null default 0 check (grau >= 0 and grau <= 4),
  observacao text,
  professor text,
  evento text,
  formada_academia boolean not null default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  constraint graduacoes_faixa_check check (
    faixa in (
      'branca', 'cinza', 'amarela', 'laranja', 'verde',
      'azul', 'roxa', 'marrom', 'preta'
    )
  ),
  constraint graduacoes_formada_preta check (
    not formada_academia or faixa = 'preta'
  )
);

create index if not exists graduacoes_aluno_id_idx
  on public.graduacoes (aluno_id);

create index if not exists graduacoes_data_idx
  on public.graduacoes (data_graduacao desc);

create index if not exists graduacoes_formada_academia_idx
  on public.graduacoes (formada_academia)
  where formada_academia = true;

alter table public.graduacoes enable row level security;

drop policy if exists "Autenticados veem graduacoes" on public.graduacoes;
drop policy if exists "Admin gerencia graduacoes" on public.graduacoes;

create policy "Autenticados veem graduacoes" on public.graduacoes
  for select
  using (auth.uid() is not null);

create policy "Admin gerencia graduacoes" on public.graduacoes
  for all
  using (public.is_admin())
  with check (public.is_admin());
