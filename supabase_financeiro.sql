-- ============================================================
-- CT SM BJJ — Financeiro avançado (execute no Supabase)
-- Mensalidades automáticas, bolsas, família, interrupção, pro-rata
-- ============================================================

-- Configuração global (singleton id=1)
create table if not exists public.financeiro_config (
  id integer primary key default 1 check (id = 1),
  valor_adulto numeric not null default 110,
  valor_menor numeric not null default 80,
  desconto_2o_familiar_percent numeric not null default 10,
  desconto_3o_familiar_percent numeric not null default 15,
  desconto_mesmo_pagante_percent numeric not null default 5,
  dia_vencimento integer not null default 10,
  regras_extras jsonb not null default '[]'::jsonb,
  updated_at timestamptz default now()
);

insert into public.financeiro_config (id) values (1)
on conflict (id) do nothing;

alter table public.financeiro_config enable row level security;
drop policy if exists "Admin config financeiro" on public.financeiro_config;
create policy "Admin config financeiro" on public.financeiro_config
  for all using (public.is_admin());

-- Campos financeiros no aluno
alter table public.alunos add column if not exists bolsista boolean default false;
alter table public.alunos add column if not exists percentual_bolsa numeric default 0;
alter table public.alunos add column if not exists grupo_familiar text;
alter table public.alunos add column if not exists cpf_pagante text;
alter table public.alunos add column if not exists cobranca_ativa boolean default true;
alter table public.alunos add column if not exists data_inicio_cobranca text;
alter table public.alunos add column if not exists data_interrupcao_cobranca text;
alter table public.alunos add column if not exists justificativa_interrupcao text;
alter table public.alunos add column if not exists valor_mensalidade_custom numeric;

-- Mensalidades: cancelamento, pro-rata, base
alter table public.mensalidades add column if not exists cancelada boolean default false;
alter table public.mensalidades add column if not exists pro_rata boolean default false;
alter table public.mensalidades add column if not exists valor_base numeric;
alter table public.mensalidades add column if not exists updated_at timestamptz default now();

-- Evita duplicar mês/ano por aluno
create unique index if not exists mensalidades_aluno_mes_ano_uidx
  on public.mensalidades (aluno_id, mes, ano)
  where (cancelada = false or cancelada is null);

select 'Financeiro avançado aplicado!' as status;
