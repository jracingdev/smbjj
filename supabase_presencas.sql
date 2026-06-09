-- ============================================================
-- CT SM BJJ — Presença nos treinos
-- Execute após supabase_setup.sql e supabase_turmas.sql
-- ============================================================

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

-- Atualiza nome do aluno nos registros de presença
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

select 'Presenças configuradas!' as status;
