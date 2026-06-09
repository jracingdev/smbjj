-- Quadro de medalhas
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
