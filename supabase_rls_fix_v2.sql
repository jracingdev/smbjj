-- ============================================================
-- CT SM BJJ — CORREÇÃO RLS v2 (execute TODO de uma vez)
--
-- A v1 ainda consultava aluno_turmas dentro das políticas → 500.
-- Esta versão usa funções SECURITY DEFINER (sem recursão).
-- NÃO apaga cadastros — só corrige permissões.
-- ============================================================

-- E-mail do usuário logado (sem acessar auth.users)
create or replace function public.auth_user_email()
returns text
language sql
stable
as $$
  select nullif(auth.jwt() ->> 'email', '');
$$;

-- ID do aluno logado (bypass RLS)
create or replace function public.meu_aluno_id()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select id from public.alunos
  where lower(email) = lower(public.auth_user_email())
  limit 1;
$$;

-- IDs dos colegas de turma (bypass RLS — evita recursão)
create or replace function public.ids_colegas_turma()
returns setof uuid
language sql
security definer
stable
set search_path = public
as $$
  select distinct at.aluno_id
  from public.aluno_turmas at
  inner join public.aluno_turmas mine on mine.turma_id = at.turma_id
  where mine.aluno_id = public.meu_aluno_id()
    and at.aluno_id is not null
    and at.aluno_id <> public.meu_aluno_id();
$$;

revoke all on function public.auth_user_email() from public;
revoke all on function public.meu_aluno_id() from public;
revoke all on function public.ids_colegas_turma() from public;
grant execute on function public.auth_user_email() to authenticated, anon;
grant execute on function public.meu_aluno_id() to authenticated;
grant execute on function public.ids_colegas_turma() to authenticated;

-- ── ALUNOS ──────────────────────────────────────────────────
drop policy if exists "Aluno vê colegas de turma" on public.alunos;
drop policy if exists "Aluno vê próprio cadastro" on public.alunos;
drop policy if exists "Aluno insere próprio cadastro" on public.alunos;
drop policy if exists "Aluno atualiza próprio cadastro" on public.alunos;

create policy "Aluno vê próprio cadastro" on public.alunos for select
  using (lower(email) = lower(public.auth_user_email()));

create policy "Aluno vê colegas de turma" on public.alunos for select
  using (
    cadastro_validado = true
    and id in (select public.ids_colegas_turma())
  );

create policy "Aluno insere próprio cadastro" on public.alunos for insert
  with check (lower(email) = lower(public.auth_user_email()));

create policy "Aluno atualiza próprio cadastro" on public.alunos for update
  using (lower(email) = lower(public.auth_user_email()));

-- ── ALUNO_TURMAS (sem subquery na própria tabela dentro da política) ──
drop policy if exists "Aluno vê próprias turmas" on public.aluno_turmas;
drop policy if exists "Alunos veem matrículas de turmas ativas" on public.aluno_turmas;

create policy "Aluno vê turmas e colegas" on public.aluno_turmas for select
  using (
    public.is_admin()
    or aluno_id = public.meu_aluno_id()
    or aluno_id in (select public.ids_colegas_turma())
  );

-- ── Outras tabelas que consultavam alunos diretamente ───────
drop policy if exists "Aluno vê próprias mensalidades" on public.mensalidades;
create policy "Aluno vê próprias mensalidades" on public.mensalidades for select
  using (aluno_id = public.meu_aluno_id());

drop policy if exists "Aluno ve proprias presencas" on public.presencas;
create policy "Aluno ve proprias presencas" on public.presencas for select
  using (aluno_id = public.meu_aluno_id());

drop policy if exists "Aluno vê próprios pedidos" on public.pedidos;
create policy "Aluno vê próprios pedidos" on public.pedidos for select
  using (aluno_id = public.meu_aluno_id());

-- ── Teste rápido (deve retornar sem erro no SQL Editor) ─────
select count(*) as total_alunos from public.alunos;

select 'RLS v2 aplicado — teste o app e a web agora!' as status;
