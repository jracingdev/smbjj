-- ============================================================
-- CT SM BJJ — Migração v1.6 (execute no SQL Editor do Supabase)
-- Inclui: campos aluno, RLS colegas, quadro de medalhas
-- ============================================================

-- 1) Campos do aluno
alter table public.alunos add column if not exists data_inicio_aulas text;
alter table public.alunos add column if not exists iniciante boolean default false;

-- 2) Funções auxiliares RLS (evitam recursão infinita em políticas de alunos)
create or replace function public.meu_aluno_id()
returns uuid language sql security definer stable set search_path = public as $$
  select id from public.alunos
  where email = (select email from auth.users where id = auth.uid()) limit 1;
$$;

create or replace function public.auth_user_email()
returns text language sql security definer stable set search_path = public, auth as $$
  select email from auth.users where id = auth.uid();
$$;

-- RLS — alunos veem colegas e contagem por turma
drop policy if exists "Aluno vê próprias turmas" on public.aluno_turmas;
drop policy if exists "Alunos veem matrículas de turmas ativas" on public.aluno_turmas;
create policy "Alunos veem matrículas de turmas ativas" on public.aluno_turmas for select
  using (
    turma_id in (select id from public.turmas where ativa = true)
    and (
      public.is_admin()
      or aluno_id = public.meu_aluno_id()
      or aluno_id in (
        select at.aluno_id from public.aluno_turmas at
        where at.turma_id in (
          select at2.turma_id from public.aluno_turmas at2
          where at2.aluno_id = public.meu_aluno_id()
        )
      )
    )
  );

drop policy if exists "Aluno vê colegas de turma" on public.alunos;
create policy "Aluno vê colegas de turma" on public.alunos for select
  using (
    cadastro_validado = true
    and public.meu_aluno_id() is not null
    and id in (
      select at.aluno_id from public.aluno_turmas at
      where at.turma_id in (
        select at2.turma_id from public.aluno_turmas at2
        where at2.aluno_id = public.meu_aluno_id()
      )
    )
  );

-- 3) Quadro de medalhas
create table if not exists public.medalhas (
  id uuid default gen_random_uuid() primary key,
  aluno_id uuid references public.alunos(id) on delete cascade,
  aluno_nome text not null,
  titulo text not null,
  tipo text default 'ouro' check (tipo in ('ouro', 'prata', 'bronze', 'outro')),
  data_conquista text,
  ativo boolean default true,
  created_at timestamptz default now()
);

alter table public.medalhas enable row level security;

drop policy if exists "Admin gerencia medalhas" on public.medalhas;
drop policy if exists "Todos veem medalhas ativas" on public.medalhas;

create policy "Admin gerencia medalhas" on public.medalhas for all using (public.is_admin());
create policy "Todos veem medalhas ativas" on public.medalhas for select using (ativo = true or public.is_admin());

-- 4) Sincroniza nome do aluno nas medalhas ao renomear
create or replace function public.sync_medalhas_aluno_nome()
returns trigger language plpgsql security definer as $$
begin
  if new.nome is distinct from old.nome then
    update public.medalhas set aluno_nome = new.nome where aluno_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_sync_medalhas_aluno_nome on public.alunos;
create trigger trg_sync_medalhas_aluno_nome
  after update of nome on public.alunos
  for each row execute function public.sync_medalhas_aluno_nome();

-- 5) Presença nos treinos
create table if not exists public.presencas (
  id uuid default gen_random_uuid() primary key,
  turma_id uuid not null references public.turmas(id) on delete cascade,
  aluno_id uuid not null references public.alunos(id) on delete cascade,
  aluno_nome text not null,
  data_aula text not null,
  presente boolean not null default true,
  observacao text,
  created_at timestamptz default now(),
  unique (turma_id, aluno_id, data_aula)
);

create index if not exists idx_presencas_turma_data on public.presencas (turma_id, data_aula);
create index if not exists idx_presencas_aluno on public.presencas (aluno_id, data_aula desc);

alter table public.presencas enable row level security;

drop policy if exists "Admin gerencia presencas" on public.presencas;
drop policy if exists "Aluno ve proprias presencas" on public.presencas;

create policy "Admin gerencia presencas" on public.presencas for all using (public.is_admin());
create policy "Aluno ve proprias presencas" on public.presencas for select
  using (aluno_id = public.meu_aluno_id());

create or replace function public.sync_presencas_aluno_nome()
returns trigger language plpgsql security definer as $$
begin
  if new.nome is distinct from old.nome then
    update public.presencas set aluno_nome = new.nome where aluno_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_sync_presencas_aluno_nome on public.alunos;
create trigger trg_sync_presencas_aluno_nome
  after update of nome on public.alunos
  for each row execute function public.sync_presencas_aluno_nome();

select 'Migração v1.6 aplicada!' as status;
