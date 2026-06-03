-- ============================================================
-- CT SM BJJ — Supabase Setup (ordem corrigida)
-- Execute TUDO de uma vez no SQL Editor
-- ============================================================

-- ── Tabela: usuarios (precisa existir ANTES da função) ───────
create table if not exists public.usuarios (
  id uuid references auth.users(id) on delete cascade primary key,
  nome text not null,
  email text unique not null,
  role text default 'aluno' check (role in ('admin', 'aluno')),
  foto_url text,
  aluno_id uuid,
  created_at timestamptz default now()
);

-- ── Função is_admin (criada APÓS a tabela) ───────────────────
create or replace function public.is_admin()
returns boolean as $$
  select exists (
    select 1 from public.usuarios
    where id = auth.uid() and role = 'admin'
  )
$$ language sql security definer stable;

-- ── RLS: usuarios ────────────────────────────────────────────
alter table public.usuarios enable row level security;

drop policy if exists "Usuário vê próprio perfil" on public.usuarios;
drop policy if exists "Admin vê todos" on public.usuarios;
drop policy if exists "Usuário atualiza próprio perfil" on public.usuarios;
drop policy if exists "Admin atualiza todos" on public.usuarios;
drop policy if exists "Inserção via trigger" on public.usuarios;

create policy "Usuário vê próprio perfil" on public.usuarios for select using (auth.uid() = id);
create policy "Admin vê todos" on public.usuarios for select using (public.is_admin());
create policy "Usuário atualiza próprio perfil" on public.usuarios for update using (auth.uid() = id);
create policy "Admin atualiza todos" on public.usuarios for update using (public.is_admin());
create policy "Inserção via trigger" on public.usuarios for insert with check (auth.uid() = id);

-- ── Trigger: cria perfil ao registrar ───────────────────────
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.usuarios (id, nome, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.email,
    case when new.email = 'admin@smbj.com' then 'admin' else 'aluno' end
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ── Tabela: alunos ───────────────────────────────────────────
create table if not exists public.alunos (
  id uuid default gen_random_uuid() primary key,
  nome text not null,
  email text,
  data_nascimento text,
  sexo text default 'masculino',
  telefone text,
  nome_responsavel text,
  telefone_responsavel text,
  endereco text,
  cidade text,
  estado text,
  cep text,
  faixa text default 'branca',
  grau integer default 0,
  peso numeric,
  foto_url text,
  ativo boolean default true,
  cadastro_validado boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table public.alunos enable row level security;

drop policy if exists "Admin gerencia alunos" on public.alunos;
drop policy if exists "Aluno vê próprio cadastro" on public.alunos;
drop policy if exists "Aluno insere próprio cadastro" on public.alunos;
drop policy if exists "Aluno atualiza próprio cadastro" on public.alunos;

create policy "Admin gerencia alunos" on public.alunos for all using (public.is_admin());
create policy "Aluno vê próprio cadastro" on public.alunos for select
  using (email = (select email from auth.users where id = auth.uid()));
create policy "Aluno insere próprio cadastro" on public.alunos for insert
  with check (email = (select email from auth.users where id = auth.uid()));
create policy "Aluno atualiza próprio cadastro" on public.alunos for update
  using (email = (select email from auth.users where id = auth.uid()));

-- ── Tabela: mensalidades ─────────────────────────────────────
create table if not exists public.mensalidades (
  id uuid default gen_random_uuid() primary key,
  aluno_id uuid references public.alunos(id) on delete cascade,
  aluno_nome text,
  mes integer not null,
  ano integer not null,
  valor numeric not null,
  status text default 'pendente' check (status in ('pendente', 'pago', 'atrasado')),
  data_pagamento text,
  observacao text,
  created_at timestamptz default now()
);
alter table public.mensalidades enable row level security;

drop policy if exists "Admin gerencia mensalidades" on public.mensalidades;
drop policy if exists "Aluno vê próprias mensalidades" on public.mensalidades;

create policy "Admin gerencia mensalidades" on public.mensalidades for all using (public.is_admin());
create policy "Aluno vê próprias mensalidades" on public.mensalidades for select
  using (aluno_id in (
    select id from public.alunos
    where email = (select email from auth.users where id = auth.uid())
  ));

-- ── Tabela: produtos ─────────────────────────────────────────
create table if not exists public.produtos (
  id uuid default gen_random_uuid() primary key,
  nome text not null,
  categoria text default 'kimono',
  descricao text,
  preco numeric not null,
  foto_url text,
  youtube_url text,
  prazo_entrega text default 'imediato',
  prazo_dias integer default 0,
  prazo_data text,
  ativo boolean default true,
  created_at timestamptz default now()
);
alter table public.produtos enable row level security;

drop policy if exists "Todos veem produtos ativos" on public.produtos;
drop policy if exists "Admin gerencia produtos" on public.produtos;

create policy "Todos veem produtos ativos" on public.produtos for select using (ativo = true or public.is_admin());
create policy "Admin gerencia produtos" on public.produtos for all using (public.is_admin());

-- ── Tabela: produto_variantes ────────────────────────────────
create table if not exists public.produto_variantes (
  id uuid default gen_random_uuid() primary key,
  produto_id uuid references public.produtos(id) on delete cascade,
  cor text,
  tamanho text,
  estoque integer default 0
);
alter table public.produto_variantes enable row level security;

drop policy if exists "Todos veem variantes" on public.produto_variantes;
drop policy if exists "Admin gerencia variantes" on public.produto_variantes;

create policy "Todos veem variantes" on public.produto_variantes for select using (true);
create policy "Admin gerencia variantes" on public.produto_variantes for all using (public.is_admin());

-- ── Tabela: avisos ───────────────────────────────────────────
create table if not exists public.avisos (
  id uuid default gen_random_uuid() primary key,
  titulo text not null,
  conteudo text not null,
  tipo text default 'info',
  link_url text,
  fonte text,
  ativo boolean default true,
  created_at timestamptz default now()
);
alter table public.avisos enable row level security;

drop policy if exists "Todos veem avisos ativos" on public.avisos;
drop policy if exists "Admin gerencia avisos" on public.avisos;

create policy "Todos veem avisos ativos" on public.avisos for select using (ativo = true or public.is_admin());
create policy "Admin gerencia avisos" on public.avisos for all using (public.is_admin());

-- ── Tabela: eventos ──────────────────────────────────────────
create table if not exists public.eventos (
  id uuid default gen_random_uuid() primary key,
  titulo text not null,
  data text not null,
  tipo text default 'campeonato',
  descricao text,
  local text,
  organizador text,
  link_url text,
  created_at timestamptz default now()
);
alter table public.eventos enable row level security;

drop policy if exists "Todos veem eventos" on public.eventos;
drop policy if exists "Admin gerencia eventos" on public.eventos;

create policy "Todos veem eventos" on public.eventos for select using (true);
create policy "Admin gerencia eventos" on public.eventos for all using (public.is_admin());

-- ── Storage: fotos ───────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('fotos', 'fotos', true)
on conflict (id) do nothing;

drop policy if exists "Fotos públicas" on storage.objects;
drop policy if exists "Upload autenticado" on storage.objects;

create policy "Fotos públicas" on storage.objects for select using (bucket_id = 'fotos');
create policy "Upload autenticado" on storage.objects for insert with check (bucket_id = 'fotos' and auth.role() = 'authenticated');

-- ── Confirmação ──────────────────────────────────────────────
select 'Setup concluído! Agora crie o usuário admin em Authentication → Users' as status;
