-- RLS: alunos veem colegas da mesma turma e contagem por turma
-- Execute após supabase_setup.sql e supabase_turmas.sql
-- Requer funções meu_aluno_id() e auth_user_email() — ver supabase_rls_fix_v1_6.sql

create or replace function public.meu_aluno_id()
returns uuid language sql security definer stable set search_path = public as $$
  select id from public.alunos
  where email = (select email from auth.users where id = auth.uid()) limit 1;
$$;

create or replace function public.auth_user_email()
returns text language sql security definer stable set search_path = public, auth as $$
  select email from auth.users where id = auth.uid();
$$;

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
