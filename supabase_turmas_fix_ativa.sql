-- ============================================================
-- CT SM BJJ — CORREÇÃO turmas invisíveis
-- Execute no SQL Editor do Supabase
--
-- Causa: ao salvar dias da turma o app gravava ativa=false
-- (bug de leitura boolean no Flutter). Reativa todas as turmas.
-- ============================================================

-- Reativar turmas que foram desativadas por engano
update public.turmas set ativa = true where ativa is not true;

-- Garantir políticas de turmas e matrículas (admin pode gerenciar)
drop policy if exists "Todos veem turmas" on public.turmas;
drop policy if exists "Admin gerencia turmas" on public.turmas;

create policy "Todos veem turmas" on public.turmas for select using (true);
create policy "Admin gerencia turmas" on public.turmas for all using (public.is_admin());

drop policy if exists "Admin gerencia aluno_turmas" on public.aluno_turmas;
create policy "Admin gerencia aluno_turmas" on public.aluno_turmas
  for all using (public.is_admin());

-- Aluno: ver matrículas (mantém v2 se já aplicado)
drop policy if exists "Aluno vê turmas e colegas" on public.aluno_turmas;
create policy "Aluno vê turmas e colegas" on public.aluno_turmas for select
  using (
    public.is_admin()
    or aluno_id = public.meu_aluno_id()
    or aluno_id in (select public.ids_colegas_turma())
  );

select count(*) as turmas_ativas from public.turmas where ativa = true;
select 'Turmas corrigidas!' as status;
