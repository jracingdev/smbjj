-- Loja pública: visitantes (sem login) podem criar pedidos
-- Execute no SQL Editor do Supabase

drop policy if exists "Visitante cria pedido loja publica" on public.pedidos;
create policy "Visitante cria pedido loja publica" on public.pedidos
  for insert
  with check (aluno_id is null);

select 'Política loja pública aplicada!' as status;
