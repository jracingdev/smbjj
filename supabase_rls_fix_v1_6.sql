-- ============================================================
-- CT SM BJJ — CORREÇÃO URGENTE RLS v1.6
-- Execute AGORA no SQL Editor do Supabase
--
-- Problema: política "Aluno vê colegas de turma" consultava
-- public.alunos dentro da própria tabela alunos → recursão → HTTP 500
-- ============================================================

-- Função auxiliar: id do aluno logado (bypass RLS)
create or replace function public.meu_aluno_id()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select id from public.alunos
  where email = (select email from auth.users where id = auth.uid())
  limit 1;
$$;

-- Função auxiliar: e-mail do usuário logado
create or replace function public.auth_user_email()
returns text
language sql
security definer
stable
set search_path = public, auth
as $$
  select email from auth.users where id = auth.uid();
$$;

-- ── Corrigir política de colegas (sem subquery recursiva em alunos) ──
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

-- ── Atualizar outras políticas que consultavam alunos (evita cadeia de erros) ──
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

drop policy if exists "Aluno vê próprio cadastro" on public.alunos;
create policy "Aluno vê próprio cadastro" on public.alunos for select
  using (email = public.auth_user_email());

drop policy if exists "Aluno insere próprio cadastro" on public.alunos;
create policy "Aluno insere próprio cadastro" on public.alunos for insert
  with check (email = public.auth_user_email());

drop policy if exists "Aluno atualiza próprio cadastro" on public.alunos;
create policy "Aluno atualiza próprio cadastro" on public.alunos for update
  using (email = public.auth_user_email());

drop policy if exists "Aluno vê próprias mensalidades" on public.mensalidades;
create policy "Aluno vê próprias mensalidades" on public.mensalidades for select
  using (aluno_id = public.meu_aluno_id());

drop policy if exists "Aluno ve proprias presencas" on public.presencas;
create policy "Aluno ve proprias presencas" on public.presencas for select
  using (aluno_id = public.meu_aluno_id());

drop policy if exists "Aluno vê próprios pedidos" on public.pedidos;
create policy "Aluno vê próprios pedidos" on public.pedidos for select
  using (aluno_id = public.meu_aluno_id());

select 'RLS v1.6 corrigido — app deve voltar a funcionar!' as status;
